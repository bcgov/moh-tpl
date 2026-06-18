/**
 * DocxGeneratorController
 * AuraEnabled controller for the generateDocxButton LWC.
 *
 * ── Routing ───────────────────────────────────────────────────────────────────
 *   The single LWC entry point is generateDocument(caseId).
 *   It counts rows first (6 cheap COUNT queries), estimates peak heap,
 *   and routes automatically:
 *
 *   SYNC path  — total XML estimate ≤ 2 MB (peak heap ≤ 6 MB)
 *     Builds the entire .docx in one synchronous transaction.
 *     Returns ContentDocumentId directly — LWC shows download link immediately.
 *     Typical cases (< ~550 MSP rows, or proportional mix).
 *
 *   ASYNC single-DOCX path — total XML estimate > 2 MB
 *     Enqueues DocxSectionQueueable chain.
 *     Each section is a separate .docx built in its own async transaction.
 *     MSP splits into chunks of 1,000 rows if needed.
 *     DocxAssemblerQueueable wraps all sections into one .zip.
 *     Returns a jobId immediately; LWC polls until the .zip appears.
 *
 * ── Bytes per row estimates (used for threshold calculation) ─────────────────
 *   Ambulance     2,090 B/row   Hospital  3,110 B/row
 *   MSP           3,620 B/row   Pharmacare 2,090 B/row
 *   CC / FC       1,070 B/row
 *   Fixed overhead (cert page + Appendix A tables): ~20,000 B
 *
 * ── Data model ────────────────────────────────────────────────────────────────
 *   CASE formula fields (read-only, queryable):
 *     PHN__c, Date_of_Birth__c, ContactName__c, Total_Case_Value__c
 *   HEALTHCARE_COST__c formula fields (read-only, queryable):
 *     RecordTypeName__c, FacilityName__c, Number_of_Days__c, Total_Costs_Standard__c
 */
public with sharing class DocxGeneratorController {

    // ── Heap-estimation constants ─────────────────────────────────────────────
    private static final Integer BPR_AMBULANCE  = 2090;
    private static final Integer BPR_HOSPITAL   = 3110;
    private static final Integer BPR_MSP        = 3620;
    private static final Integer BPR_PHARMACARE = 2090;
    private static final Integer BPR_CC_FC      = 1070;
    private static final Integer FIXED_OVERHEAD = 20000;
    // Sync heap limit 6 MB; peak = XML × 3; XML budget = 6 MB / 3 = 2 MB
    @TestVisible private static final Integer SYNC_XML_LIMIT = 2000000;

    // ── Single LWC entry point ────────────────────────────────────────────────

    /**
     * Generates the Minister's Certificate for the given Case.
     * Routes to sync or async single-DOCX mode based on row counts.
     *
     * Sync mode:   returns ContentDocumentId (String starting '069')
     * Section mode: returns 'ASYNC:' + a jobId the LWC uses for polling
     */
    @AuraEnabled
    public static String generateDocument(Id caseId) {
        try {
            // ── Step 1: Count rows per type (cheap, no data fetched) ──────────
            Integer cntAmb   = [SELECT COUNT() FROM Healthcare_Cost__c
                                 WHERE Case2__c = :caseId AND RecordTypeName__c = 'Ambulance'
                                   AND Cost_Include__c = true AND Cost_Review__c = true];
            Integer cntHosp  = [SELECT COUNT() FROM Healthcare_Cost__c
                                 WHERE Case2__c = :caseId AND RecordTypeName__c = 'Hospitalization'
                                   AND Cost_Include__c = true AND Cost_Review__c = true];
            Integer cntMsp   = [SELECT COUNT() FROM Healthcare_Cost__c
                                 WHERE Case2__c = :caseId AND RecordTypeName__c = 'MSP'
                                   AND Cost_Include__c = true AND Cost_Review__c = true];
            Integer cntPharm = [SELECT COUNT() FROM Healthcare_Cost__c
                                 WHERE Case2__c = :caseId AND RecordTypeName__c = 'Pharmacare'
                                   AND Cost_Include__c = true AND Cost_Review__c = true];
            Integer cntCC    = [SELECT COUNT() FROM Healthcare_Cost__c
                                 WHERE Case2__c = :caseId AND RecordTypeName__c = 'Continuing_Care'];
            Integer cntFC    = [SELECT COUNT() FROM Healthcare_Cost__c
                                 WHERE Case2__c = :caseId AND RecordTypeName__c = 'Future_Care'];

            Integer estimatedXml = FIXED_OVERHEAD
                + (cntAmb   * BPR_AMBULANCE)
                + (cntHosp  * BPR_HOSPITAL)
                + (cntMsp   * BPR_MSP)
                + (cntPharm * BPR_PHARMACARE)
                + (cntCC    * BPR_CC_FC)
                + (cntFC    * BPR_CC_FC);

            if (estimatedXml <= SYNC_XML_LIMIT) {
                // ── SYNC path ─────────────────────────────────────────────────
                return generateSync(caseId);
            } else {
                // ── ASYNC single-DOCX path ──────────────────────────────────────────
                String jobId = enqueueSections(caseId);
                return 'ASYNC:' + jobId;
            }

        } catch (Exception e) {
            throw new AuraHandledException('Certificate generation failed: ' + e.getMessage());
        }
    }

    /**
     * Polls for completion of an async single-DOCX generation.
     * The LWC calls this when generateDocument returned 'ASYNC:jobId'.
     *
     * Returns the ContentDocumentId of the final .docx when done, null while pending.
     * Completion is detected by the appearance of a generated .docx file linked to the Case.
     */
    @AuraEnabled(cacheable=false)
    public static String pollDocument(Id caseId, String jobId) {
        try {
            // Look for the final .docx file linked to this Case
            List<ContentDocumentLink> links = [
                SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.FileExtension
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :caseId
                  AND ContentDocument.Title LIKE 'Ministers%Certificate%'
                  AND (ContentDocument.FileExtension = 'docx' OR ContentDocument.FileExtension = 'zip')
                  AND ContentDocument.CreatedDate > :Datetime.now().addHours(-2)
                ORDER BY ContentDocument.CreatedDate DESC
                LIMIT 1
            ];
            return links.isEmpty() ? null : links[0].ContentDocumentId;
        } catch (Exception e) {
            throw new AuraHandledException('Poll failed: ' + e.getMessage());
        }
    }

    // ── Sync path ─────────────────────────────────────────────────────────────

    // Shared by the synchronous controller path and the async single-document queueable.
    public static String generateSync(Id recordId) {
        Case caseRecord = [
            SELECT CaseNumber, Claim_Number__c, ContactName__c, PHN__c,
                   Date_of_Birth__c, Incident_Date__c, Total_Case_Value__c,
                   Ambulance_Total2__c, Hospitalization_Total2__c, MSP_Total2__c,
                   Pharmacare_Total2__c, Continuing_Care_Total2__c, Future_Care_Total2__c
            FROM Case WHERE Id = :recordId LIMIT 1
        ];
        List<Healthcare_Cost__c> ambulanceRecs = [
            SELECT Date_of_Service__c, Location_Responded__c,
                   FacilityName__c, Facility_Name__c, Total_Cost_Override__c
            FROM Healthcare_Cost__c
            WHERE Case2__c = :recordId AND RecordTypeName__c = 'Ambulance'
              AND Cost_Include__c = true AND Cost_Review__c = true
            ORDER BY Date_of_Service__c ASC
        ];
        List<Healthcare_Cost__c> hospitalRecs = [
            SELECT Date_of_Admission__c, Date_of_Discharge__c,
                   FacilityName__c, Facility_Name__c, Service_Type2__c,
                   Number_of_Days__c, Total_Cost_Override__c, Total_Costs_Standard__c
            FROM Healthcare_Cost__c
            WHERE Case2__c = :recordId AND RecordTypeName__c = 'Hospitalization'
              AND Cost_Include__c = true AND Cost_Review__c = true
            ORDER BY Date_of_Admission__c ASC
        ];
        List<Healthcare_Cost__c> mspRecs = [
            SELECT Date_of_Service__c, Location_Type_Code__c,
                   Location_Type_Description2__c, Description_of_Service2__c,
                   Fee_Item_Title__c, Diagnostic_Description__c,
                   Total_Cost_Override__c, Practitioner_Name__c
            FROM Healthcare_Cost__c
            WHERE Case2__c = :recordId AND RecordTypeName__c = 'MSP'
              AND Cost_Include__c = true AND Cost_Review__c = true
            ORDER BY Date_of_Service__c ASC
        ];
        List<Healthcare_Cost__c> pharmaRecs = [
            SELECT Date_of_Service__c, Name_of_Drug__c,
                   Total_Cost_Override__c, Practitioner_Name__c
            FROM Healthcare_Cost__c
            WHERE Case2__c = :recordId AND RecordTypeName__c = 'Pharmacare'
              AND Cost_Include__c = true AND Cost_Review__c = true
            ORDER BY Date_of_Service__c ASC
        ];
        List<Healthcare_Cost__c> ccRecs = [
            SELECT Description__c, Cost__c FROM Healthcare_Cost__c
            WHERE Case2__c = :recordId AND RecordTypeName__c = 'Continuing_Care'
        ];
        List<Healthcare_Cost__c> fcRecs = [
            SELECT Description__c, Cost__c FROM Healthcare_Cost__c
            WHERE Case2__c = :recordId AND RecordTypeName__c = 'Future_Care'
        ];
        List<TPL_DocGen_Signature__c> sigs = [
            SELECT Name__c, Title__c FROM TPL_DocGen_Signature__c
            WHERE Name = 'TPL DocGen Signature (Profile)' LIMIT 1
        ];
        String sigName  = sigs.isEmpty() ? '' : sigs[0].Name__c;
        String sigTitle = sigs.isEmpty() ? '' : sigs[0].Title__c;

        Blob docxBlob = new DocxBuilder()
            .setCaseData(caseRecord)
            .setAmbulanceRecords(ambulanceRecs)
            .setHospitalRecords(hospitalRecs)
            .setMSPRecords(mspRecs)
            .setPharmaRecords(pharmaRecs)
            .setContinuingCareRecords(ccRecs)
            .setFutureCareRecords(fcRecs)
            .setSigningAuthority(sigName, sigTitle)
            .build();

        String fileName = 'Ministers_Certificate_' + caseRecord.CaseNumber
            + '_' + Datetime.now().format('yyyyMMdd') + '.docx';
        ContentVersion cv = new ContentVersion();
        cv.Title                  = fileName;
        cv.PathOnClient           = fileName;
        cv.VersionData            = docxBlob;
        cv.FirstPublishLocationId = recordId;
        cv.SharingPrivacy         = 'N';
        insert cv;

        return [SELECT ContentDocumentId FROM ContentVersion
                WHERE Id = :cv.Id LIMIT 1].ContentDocumentId;
    }

    // ── Section-ZIP path ──────────────────────────────────────────────────────

    private static String enqueueSections(Id caseId) {
        // The previous async implementation generated a .zip containing separate
        // section .docx files. That does not match the sync output and is not
        // directly printable by the existing user workflow. Build the same single
        // .docx in an async transaction instead, so the generated document has
        // the same content/layout as the sync path but benefits from async heap.
        Id jobId = System.enqueueJob(new DocxSingleDocumentQueueable(caseId));
        return String.valueOf(jobId);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────
    private static String strVal(Object v)      { return v == null ? '' : String.valueOf(v); }
    private static Decimal nvl(Decimal v)        { return v != null ? v : 0; }
    private static String fmtDate(Date d) {
        if (d == null) return '';
        String mm = String.valueOf(d.month()).leftPad(2, '0');
        String dd = String.valueOf(d.day()).leftPad(2, '0');
        return mm + '/' + dd + '/' + String.valueOf(d.year());
    }
    private static String fmtCurrency(Decimal val) {
        if (val == null) return '$0.00';
        return '$' + val.setScale(2).toPlainString();
    }
}
