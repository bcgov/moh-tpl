/**
 * DocxSectionQueueable
 * Builds one complete Minister's Certificate section as a standalone .docx and
 * stores it as a ContentVersion linked to the Case. Chains to the next section
 * automatically, and enqueues DocxAssemblerQueueable when all sections are done.
 *
 * ── Section ordering ──────────────────────────────────────────────────────────
 *   Index 0: Certificate summary (cert page + Appendix A tables, no HC rows)
 *   Index 1: Ambulance
 *   Index 2: Hospitalization
 *   Index 3: MSP          ← may spawn multiple chunks if > ROWS_PER_DOC rows
 *   Index 4: Pharmacare
 *   Index 5: Continuing_Care
 *   Index 6: Future_Care
 *
 * ── Heap profile ─────────────────────────────────────────────────────────────
 *   Worst case: 1,000 MSP rows × 3,620 B = 3.6 MB XML
 *   + Blob.valueOf() = 3.6 MB
 *   + ZipWriter     = 3.6 MB compressed (XML compresses ~90% → ~0.4 MB actual)
 *   Peak: ~7.2 MB of 12 MB async limit ✓
 *
 * ── Keyset pagination ────────────────────────────────────────────────────────
 *   Uses Id > :lastId ORDER BY Id ASC to avoid the SOQL OFFSET 2000 hard limit.
 *   Sort order within a section is by Id, not by date. If date-ordering is
 *   required for legal purposes, add a Date_Sort_Index__c rollup field.
 */
public class DocxSectionQueueable implements Queueable {

    // Max HC rows per section .docx — keeps peak heap ≤ ~7 MB
    @TestVisible private static final Integer ROWS_PER_DOC = 1000;

    // Section index constants
    private static final Integer SEC_CERT  = 0;
    private static final Integer SEC_AMB   = 1;
    private static final Integer SEC_HOSP  = 2;
    private static final Integer SEC_MSP   = 3;
    private static final Integer SEC_PHARM = 4;
    private static final Integer SEC_CC    = 5;
    private static final Integer SEC_FC    = 6;
    private static final Integer SEC_DONE  = 7;  // triggers assembler

    // Sections that require Cost_Include + Cost_Review filters
    private static final Set<Integer> FILTERED = new Set<Integer>{
        SEC_AMB, SEC_HOSP, SEC_MSP, SEC_PHARM
    };

    // ── Persistent state ──────────────────────────────────────────────────────
    private Id      caseId;
    private Integer sectionIndex;       // current section being built
    private Id      lastProcessedId;    // keyset cursor within current section
    private Integer chunkWithinSection; // 1-based, for file naming (MSP Part 1, Part 2…)
    // Case header fields passed through every link
    private String caseNumber;
    private String contactName;
    private String phn;
    private String claimNumber;
    private String incidentDate;
    private String birthDate;
    private String sigName;
    private String sigTitle;
    // Totals for section closing lines
    private String ambulanceTotal;
    private String hospitalTotal;
    private String medicalTotal;
    private String pharmacyTotal;
    private String continuingCareTotal;
    private String futureCareTotal;
    private String pastServicesTotal;
    private String futureServicesTotal;
    private String totalCost;
    // Tracks ContentDocumentIds of all produced section files, for the assembler
    private List<Id> sectionDocIds;

    public DocxSectionQueueable(
            Id caseId, Integer sectionIndex, Id lastProcessedId, Integer chunkWithinSection,
            String caseNumber, String contactName, String phn, String claimNumber,
            String incidentDate, String birthDate, String sigName, String sigTitle,
            String ambulanceTotal, String hospitalTotal, String medicalTotal,
            String pharmacyTotal, String continuingCareTotal, String futureCareTotal,
            String pastServicesTotal, String futureServicesTotal, String totalCost,
            List<Id> sectionDocIds) {
        this.caseId             = caseId;
        this.sectionIndex       = sectionIndex;
        this.lastProcessedId    = lastProcessedId;
        this.chunkWithinSection = chunkWithinSection;
        this.caseNumber         = caseNumber;
        this.contactName        = contactName;
        this.phn                = phn;
        this.claimNumber        = claimNumber;
        this.incidentDate       = incidentDate;
        this.birthDate          = birthDate;
        this.sigName            = sigName;
        this.sigTitle           = sigTitle;
        this.ambulanceTotal     = ambulanceTotal;
        this.hospitalTotal      = hospitalTotal;
        this.medicalTotal       = medicalTotal;
        this.pharmacyTotal      = pharmacyTotal;
        this.continuingCareTotal = continuingCareTotal;
        this.futureCareTotal    = futureCareTotal;
        this.pastServicesTotal  = pastServicesTotal;
        this.futureServicesTotal = futureServicesTotal;
        this.totalCost          = totalCost;
        this.sectionDocIds      = sectionDocIds == null ? new List<Id>() : sectionDocIds;
    }

    public void execute(QueueableContext ctx) {

        // ── Section 0: Certificate summary (static, no HC rows) ───────────────
        if (sectionIndex == SEC_CERT) {
            Id docId = buildCertSummaryDoc();
            List<Id> nextIds = new List<Id>(sectionDocIds);
            nextIds.add(docId);
            System.enqueueJob(makeNext(SEC_AMB, null, 1, nextIds));
            return;
        }

        // ── Sections 1-6: HC type sections ────────────────────────────────────
        if (sectionIndex == SEC_DONE) {
            System.enqueueJob(new DocxAssemblerQueueable(caseId, sectionDocIds));
            return;
        }

        String hcType = sectionHcType(sectionIndex);
        List<Healthcare_Cost__c> rows = queryRows(hcType);

        // Skip empty sections entirely (advance to next section, no file produced)
        if (rows.isEmpty() && chunkWithinSection == 1) {
            System.enqueueJob(makeNext(sectionIndex + 1, null, 1, sectionDocIds));
            return;
        }

        // Build this section's .docx
        Boolean isLastChunk = rows.size() < ROWS_PER_DOC;
        Id docId = buildSectionDoc(hcType, rows, isLastChunk);

        List<Id> nextIds = new List<Id>(sectionDocIds);
        nextIds.add(docId);

        if (!isLastChunk) {
            // More rows — continue same section with next chunk
            Id newLastId = rows[rows.size() - 1].Id;
            System.enqueueJob(makeNext(sectionIndex, newLastId, chunkWithinSection + 1, nextIds));
        } else {
            // Section complete — move to next section
            System.enqueueJob(makeNext(sectionIndex + 1, null, 1, nextIds));
        }
    }

    // ── Document builders ─────────────────────────────────────────────────────

    /**
     * Builds the certificate cover + Appendix A summary tables as a standalone
     * .docx. Contains the full cert page, section break, and both summary tables.
     * No HC row data — always fits in sync heap.
     */
    private Id buildCertSummaryDoc() {
        // DocxBuilder with no HC records builds the cert page + summary tables only
        Case c = buildCaseShell();
        List<TPL_DocGen_Signature__c> sigs = [
            SELECT Name__c, Title__c FROM TPL_DocGen_Signature__c
            WHERE Name = 'TPL DocGen Signature (Profile)' LIMIT 1
        ];
        Blob docx = new DocxBuilder()
            .setCaseData(c)
            .setSigningAuthority(sigName, sigTitle)
            .build();

        return saveSection(docx, '01_Certificate_Summary');
    }

    /**
     * Builds one section .docx containing the cert page + Appendix A summary +
     * the section detail for one HC type (up to ROWS_PER_DOC rows).
     * For multi-chunk types (e.g. MSP with 8,000 rows), each chunk becomes a
     * separate .docx named MSP_Part1, MSP_Part2 etc.
     */
    private Id buildSectionDoc(String hcType, List<Healthcare_Cost__c> rows, Boolean isFinalChunk) {
        Case c = buildCaseShell();

        DocxBuilder builder = new DocxBuilder()
            .setCaseData(c)
            .setSigningAuthority(sigName, sigTitle);

        if (hcType == 'Ambulance')       builder.setAmbulanceRecords(rows);
        else if (hcType == 'Hospitalization') builder.setHospitalRecords(rows);
        else if (hcType == 'MSP')        builder.setMSPRecords(rows);
        else if (hcType == 'Pharmacare') builder.setPharmaRecords(rows);
        else if (hcType == 'Continuing_Care') builder.setContinuingCareRecords(rows);
        else if (hcType == 'Future_Care') builder.setFutureCareRecords(rows);

        Blob docx = builder.build();

        String sectionLabel = sectionFileLabel(hcType);
        String chunkSuffix  = chunkWithinSection > 1 || !isFinalChunk
            ? '_Part' + String.valueOf(chunkWithinSection).leftPad(2, '0')
            : '';
        return saveSection(docx, sectionLabel + chunkSuffix);
    }

    /**
     * Constructs a minimal Case shell from the cached state fields so DocxBuilder
     * can be initialised without a SOQL query in every Queueable execution.
     */
    private Case buildCaseShell() {
        return [
            SELECT Id,
                   CaseNumber,
                   Claim_Number__c,
                   ContactName__c,
                   PHN__c,
                   Incident_Date__c,
                   Date_of_Birth__c,
                   Ambulance_Total2__c,
                   Hospitalization_Total2__c,
                   MSP_Total2__c,
                   Pharmacare_Total2__c,
                   Continuing_Care_Total2__c,
                   Future_Care_Total2__c,
                   Total_Case_Value__c
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
    }

    private Id saveSection(Blob docx, String sectionLabel) {
        String prefix   = String.valueOf(sectionIndex).leftPad(2, '0');
        String fileName = prefix + '_' + sectionLabel + '_' + caseNumber + '.docx';
        ContentVersion cv = new ContentVersion();
        cv.Title                  = fileName;
        cv.PathOnClient           = fileName;
        cv.VersionData            = docx;
        cv.FirstPublishLocationId = caseId;
        cv.SharingPrivacy         = 'N';
        cv.IsMajorVersion         = false;  // keep section files out of main Files view
        insert cv;
        return [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
    }

    // ── Queries (keyset pagination — no OFFSET limit) ─────────────────────────

    private List<Healthcare_Cost__c> queryRows(String hcType) {
        if (hcType == 'Ambulance') {
            return lastProcessedId == null
                ? [SELECT Id, Date_of_Service__c, Location_Responded__c,
                          FacilityName__c, Facility_Name__c, Total_Cost_Override__c
                   FROM Healthcare_Cost__c
                   WHERE Case2__c = :caseId AND RecordTypeName__c = :hcType
                     AND Cost_Include__c = true AND Cost_Review__c = true
                   ORDER BY Id ASC LIMIT :ROWS_PER_DOC]
                : [SELECT Id, Date_of_Service__c, Location_Responded__c,
                          FacilityName__c, Facility_Name__c, Total_Cost_Override__c
                   FROM Healthcare_Cost__c
                   WHERE Case2__c = :caseId AND RecordTypeName__c = :hcType
                     AND Cost_Include__c = true AND Cost_Review__c = true
                     AND Id > :lastProcessedId
                   ORDER BY Id ASC LIMIT :ROWS_PER_DOC];
        } else if (hcType == 'Hospitalization') {
            return lastProcessedId == null
                ? [SELECT Id, Date_of_Admission__c, Date_of_Discharge__c,
                          FacilityName__c, Facility_Name__c, Service_Type2__c,
                          Number_of_Days__c, Total_Cost_Override__c, Total_Costs_Standard__c
                   FROM Healthcare_Cost__c
                   WHERE Case2__c = :caseId AND RecordTypeName__c = :hcType
                     AND Cost_Include__c = true AND Cost_Review__c = true
                   ORDER BY Id ASC LIMIT :ROWS_PER_DOC]
                : [SELECT Id, Date_of_Admission__c, Date_of_Discharge__c,
                          FacilityName__c, Facility_Name__c, Service_Type2__c,
                          Number_of_Days__c, Total_Cost_Override__c, Total_Costs_Standard__c
                   FROM Healthcare_Cost__c
                   WHERE Case2__c = :caseId AND RecordTypeName__c = :hcType
                     AND Cost_Include__c = true AND Cost_Review__c = true
                     AND Id > :lastProcessedId
                   ORDER BY Id ASC LIMIT :ROWS_PER_DOC];
        } else if (hcType == 'MSP') {
            return lastProcessedId == null
                ? [SELECT Id, Date_of_Service__c, Location_Type_Code__c,
                          Location_Type_Description2__c, Description_of_Service2__c,
                          Fee_Item_Title__c, Diagnostic_Description__c,
                          Total_Cost_Override__c, Practitioner_Name__c
                   FROM Healthcare_Cost__c
                   WHERE Case2__c = :caseId AND RecordTypeName__c = :hcType
                     AND Cost_Include__c = true AND Cost_Review__c = true
                   ORDER BY Id ASC LIMIT :ROWS_PER_DOC]
                : [SELECT Id, Date_of_Service__c, Location_Type_Code__c,
                          Location_Type_Description2__c, Description_of_Service2__c,
                          Fee_Item_Title__c, Diagnostic_Description__c,
                          Total_Cost_Override__c, Practitioner_Name__c
                   FROM Healthcare_Cost__c
                   WHERE Case2__c = :caseId AND RecordTypeName__c = :hcType
                     AND Cost_Include__c = true AND Cost_Review__c = true
                     AND Id > :lastProcessedId
                   ORDER BY Id ASC LIMIT :ROWS_PER_DOC];
        } else if (hcType == 'Pharmacare') {
            return lastProcessedId == null
                ? [SELECT Id, Date_of_Service__c, Name_of_Drug__c,
                          Total_Cost_Override__c, Practitioner_Name__c
                   FROM Healthcare_Cost__c
                   WHERE Case2__c = :caseId AND RecordTypeName__c = :hcType
                     AND Cost_Include__c = true AND Cost_Review__c = true
                   ORDER BY Id ASC LIMIT :ROWS_PER_DOC]
                : [SELECT Id, Date_of_Service__c, Name_of_Drug__c,
                          Total_Cost_Override__c, Practitioner_Name__c
                   FROM Healthcare_Cost__c
                   WHERE Case2__c = :caseId AND RecordTypeName__c = :hcType
                     AND Cost_Include__c = true AND Cost_Review__c = true
                     AND Id > :lastProcessedId
                   ORDER BY Id ASC LIMIT :ROWS_PER_DOC];
        } else {
            // Continuing_Care, Future_Care — no filter
            return lastProcessedId == null
                ? [SELECT Id, Description__c, Cost__c FROM Healthcare_Cost__c
                   WHERE Case2__c = :caseId AND RecordTypeName__c = :hcType
                   ORDER BY Id ASC LIMIT :ROWS_PER_DOC]
                : [SELECT Id, Description__c, Cost__c FROM Healthcare_Cost__c
                   WHERE Case2__c = :caseId AND RecordTypeName__c = :hcType
                     AND Id > :lastProcessedId
                   ORDER BY Id ASC LIMIT :ROWS_PER_DOC];
        }
    }

    // ── Chain factory ─────────────────────────────────────────────────────────

    private DocxSectionQueueable makeNext(Integer nextIdx, Id nextLastId,
                                          Integer nextChunk, List<Id> nextDocIds) {
        return new DocxSectionQueueable(
            caseId, nextIdx, nextLastId, nextChunk,
            caseNumber, contactName, phn, claimNumber,
            incidentDate, birthDate, sigName, sigTitle,
            ambulanceTotal, hospitalTotal, medicalTotal,
            pharmacyTotal, continuingCareTotal, futureCareTotal,
            pastServicesTotal, futureServicesTotal, totalCost,
            nextDocIds
        );
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private String sectionHcType(Integer idx) {
        if (idx == SEC_AMB)   return 'Ambulance';
        if (idx == SEC_HOSP)  return 'Hospitalization';
        if (idx == SEC_MSP)   return 'MSP';
        if (idx == SEC_PHARM) return 'Pharmacare';
        if (idx == SEC_CC)    return 'Continuing_Care';
        return 'Future_Care';
    }

    private String sectionFileLabel(String hcType) {
        if (hcType == 'Ambulance')       return '02_Ambulance';
        if (hcType == 'Hospitalization') return '03_Hospital';
        if (hcType == 'MSP')             return '04_MSP';
        if (hcType == 'Pharmacare')      return '05_Pharmacare';
        if (hcType == 'Continuing_Care') return '06_Continuing_Care';
        return '07_Future_Care';
    }

    private Date parseDate(String formatted) {
        // Expects MM/DD/YYYY from fmtDate()
        if (String.isBlank(formatted)) return null;
        try {
            List<String> parts = formatted.split('/');
            return Date.newInstance(
                Integer.valueOf(parts[2]),
                Integer.valueOf(parts[0]),
                Integer.valueOf(parts[1])
            );
        } catch (Exception e) { return null; }
    }

    private Decimal parseCurrency(String formatted) {
        // Expects $NNN.NN from fmtCurrency()
        if (String.isBlank(formatted) || formatted == '$0.00') return 0;
        try {
            return Decimal.valueOf(formatted.removeStart('$'));
        } catch (Exception e) { return 0; }
    }
}