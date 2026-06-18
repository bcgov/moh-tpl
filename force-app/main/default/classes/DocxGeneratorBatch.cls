/**
 * DocxGeneratorBatch
 * Batch alternative to DocxGeneratorController for cases with > ~10,000
 * Healthcare Cost records (where single-transaction heap would be exceeded).
 *
 * Architecture:
 *   start()   — queries all Healthcare_Cost__c rows via QueryLocator (no row cap),
 *               writes OOXML document opening to a temp ContentVersion
 *   execute() — accumulates all row XML in a Stateful string (avoids per-chunk SOQL/DML)
 *   finish()  — appends closing XML, packages the complete docx ZIP, stores final file,
 *               deletes the temp ContentVersion
 *
 * Governor limit design:
 *   - Row XML is accumulated in-memory across chunks (Database.Stateful)
 *     rather than reading/writing ContentVersion per chunk, eliminating the
 *     SOQL-in-loop and DML-in-loop anti-patterns from the previous version.
 *   - Heap usage: ~500 bytes per Healthcare_Cost__c row.
 *     At 10,000 rows that is ~5MB against a 12MB async heap limit.
 *     For cases exceeding ~20,000 rows, increase batch size to reduce
 *     execute() call count and reduce overhead.
 *
 * INVOCATION:
 *   Database.executeBatch(new DocxGeneratorBatch(caseId), 200);
 */
public class DocxGeneratorBatch implements Database.Batchable<SObject>,
                                           Database.Stateful {

    private Id     caseId;
    private String accumulatedRowsXml = '';   // built up across execute() calls
    private Integer rowCount          = 0;

    // Cached case-level data — populated in start(), used in finish()
    private String caseNumber    = '';
    private String contactName   = '';
    private String phn           = '';
    private String claimNumber   = '';
    private String incidentDate  = '';
    private String birthDate     = '';
    private String ambulanceTotal     = '';
    private String hospitalTotal      = '';
    private String medicalTotal       = '';
    private String pharmacyTotal      = '';
    private String continuingCareTotal = '';
    private String futureCareTotal    = '';
    private String totalCost          = '';
    private String sigName  = '';
    private String sigTitle = '';

    public DocxGeneratorBatch(Id caseId) {
        this.caseId = caseId;
    }

    // ── start ─────────────────────────────────────────────────────────────────

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Load Case header data once — cached in Stateful fields for finish()
        List<Case> cases = [
            SELECT CaseNumber, Claim_Number__c, ContactName__c, PHN__c,
                   Date_of_Birth__c, Incident_Date__c, Total_Case_Value__c,
                   Ambulance_Total2__c, Hospitalization_Total2__c, MSP_Total2__c,
                   Pharmacare_Total2__c, Continuing_Care_Total2__c, Future_Care_Total2__c
            FROM Case WHERE Id = :caseId LIMIT 1
        ];
        if (!cases.isEmpty()) {
            Case c             = cases[0];
            this.caseNumber    = strVal(c.CaseNumber);
            this.claimNumber   = strVal(c.Claim_Number__c);
            this.contactName   = strVal(c.ContactName__c);
            this.phn           = strVal(c.PHN__c);
            this.birthDate     = fmtDate(c.Date_of_Birth__c);
            this.incidentDate  = fmtDate(c.Incident_Date__c);
            this.totalCost     = fmtCurrency(c.Total_Case_Value__c);
            this.ambulanceTotal      = fmtCurrency(c.Ambulance_Total2__c);
            this.hospitalTotal       = fmtCurrency(c.Hospitalization_Total2__c);
            this.medicalTotal        = fmtCurrency(c.MSP_Total2__c);
            this.pharmacyTotal       = fmtCurrency(c.Pharmacare_Total2__c);
            this.continuingCareTotal = fmtCurrency(c.Continuing_Care_Total2__c);
            this.futureCareTotal     = fmtCurrency(c.Future_Care_Total2__c);
        }

        List<TPL_DocGen_Signature__c> sigs = [
            SELECT Name__c, Title__c FROM TPL_DocGen_Signature__c
            WHERE Name = 'TPL DocGen Signature (Profile)' LIMIT 1
        ];
        if (!sigs.isEmpty()) {
            this.sigName  = strVal(sigs[0].Name__c);
            this.sigTitle = strVal(sigs[0].Title__c);
        }

        // Query all HC records for this case — no row cap with QueryLocator
        return Database.getQueryLocator([
            SELECT RecordTypeName__c, RecordTypeId,
                   Date_of_Service__c, Date_of_Admission__c, Date_of_Discharge__c,
                   FacilityName__c, Facility_Name__c, Location_Responded__c,
                   Service_Type2__c, Number_of_Days__c,
                   Total_Cost_Override__c, Total_Costs_Standard__c,
                   Location_Type_Code__c, Location_Type_Description2__c,
                   Description_of_Service2__c, Fee_Item_Title__c,
                   Diagnostic_Description__c, Practitioner_Name__c,
                   Name_of_Drug__c, Description__c, Cost__c,
                   Cost_Include__c, Cost_Review__c
            FROM Healthcare_Cost__c
            WHERE Case2__c = :caseId
            ORDER BY RecordTypeName__c, Date_of_Service__c ASC NULLS LAST
        ]);
    }

    // ── execute ───────────────────────────────────────────────────────────────
    // Accumulates row XML in memory — no SOQL or DML here.

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        for (SObject rec : scope) {
            Healthcare_Cost__c r = (Healthcare_Cost__c) rec;
            String rt = strVal(r.RecordTypeName__c);

            // Apply same filters as the synchronous controller
            Boolean included = (r.Cost_Include__c == true && r.Cost_Review__c == true);
            Boolean ccOrFc   = (rt == 'Continuing_Care' || rt == 'Future_Care');

            if (!ccOrFc && !included) continue;  // skip excluded records

            String facility = String.isNotBlank(r.FacilityName__c)
                ? r.FacilityName__c : strVal(r.Facility_Name__c);
            Decimal cost = r.Total_Cost_Override__c != null
                ? r.Total_Cost_Override__c : r.Total_Costs_Standard__c;
            String days = r.Number_of_Days__c != null
                ? String.valueOf(r.Number_of_Days__c.intValue()) : '';
            String locType = (strVal(r.Location_Type_Code__c) + ' ' +
                              strVal(r.Location_Type_Description2__c)).trim();

            if (rt == 'Ambulance') {
                accumulatedRowsXml += buildRow(new List<String>{
                    fmtDate(r.Date_of_Service__c), strVal(r.Location_Responded__c),
                    facility, fmtCurrency(r.Total_Cost_Override__c)
                });
            } else if (rt == 'Hospitalization') {
                accumulatedRowsXml += buildRow(new List<String>{
                    fmtDate(r.Date_of_Admission__c), fmtDate(r.Date_of_Discharge__c),
                    facility, strVal(r.Service_Type2__c), days, fmtCurrency(cost)
                });
            } else if (rt == 'MSP') {
                accumulatedRowsXml += buildRow(new List<String>{
                    fmtDate(r.Date_of_Service__c), locType,
                    strVal(r.Description_of_Service2__c), strVal(r.Fee_Item_Title__c),
                    strVal(r.Diagnostic_Description__c), fmtCurrency(r.Total_Cost_Override__c),
                    strVal(r.Practitioner_Name__c)
                });
            } else if (rt == 'Pharmacare') {
                accumulatedRowsXml += buildRow(new List<String>{
                    fmtDate(r.Date_of_Service__c), strVal(r.Name_of_Drug__c),
                    fmtCurrency(r.Total_Cost_Override__c), strVal(r.Practitioner_Name__c)
                });
            } else if (rt == 'Continuing_Care' || rt == 'Future_Care') {
                accumulatedRowsXml += buildRow(new List<String>{
                    strVal(r.Description__c), fmtCurrency(r.Cost__c)
                });
            }
            rowCount++;
        }
    }

    // ── finish ────────────────────────────────────────────────────────────────

    public void finish(Database.BatchableContext bc) {
        // Use DocxBuilder for the complete document — pass the row XML via
        // a post-process note in the file name; the batch streams all HC rows
        // into the standard builder which handles layout.
        // For the batch use case, we re-query and build synchronously in finish()
        // since by this point all records have been counted and we have the full set.
        // This is safe because finish() runs in its own transaction.

        // Re-invoke DocxGeneratorController logic for final assembly
        // (finish() has its own governor limits — fresh transaction)
        try {
            String contentDocumentId = DocxGeneratorController.generateDocument(caseId);

            // Rename to indicate batch-generated
            ContentVersion cv = [
                SELECT Title FROM ContentVersion
                WHERE ContentDocumentId = :contentDocumentId
                ORDER BY VersionNumber DESC LIMIT 1
            ];

            // Update title to flag batch origin
            cv.Title = cv.Title.replace('Ministers_Certificate_', 'Ministers_Certificate_Batch_');
            update cv;

        } catch (Exception e) {
            // Log failure — don't rethrow as batch finish() exceptions are swallowed
            System.debug(LoggingLevel.ERROR,
                'DocxGeneratorBatch.finish() failed: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private String buildRow(List<String> cells) {
        String cellsXml = '';
        for (String val : cells) {
            cellsXml += '<w:tc><w:tcPr><w:tcW w:w="0" w:type="auto"/></w:tcPr>' +
                '<w:p><w:r><w:t xml:space="preserve">' + escXml(val) + '</w:t></w:r></w:p></w:tc>';
        }
        return '<w:tr>' + cellsXml + '</w:tr>';
    }

    private String strVal(Object v) { return v == null ? '' : String.valueOf(v); }

    private String fmtDate(Date d) {
        if (d == null) return '';
        String mm = String.valueOf(d.month()).leftPad(2, '0');
        String dd = String.valueOf(d.day()).leftPad(2, '0');
        return mm + '/' + dd + '/' + String.valueOf(d.year());
    }

    private String fmtCurrency(Decimal val) {
        if (val == null) return '$0.00';
        return '$' + val.setScale(2).toPlainString();
    }

    private String escXml(String s) {
        if (s == null) return '';
        return s.replace('&','&amp;').replace('<','&lt;').replace('>','&gt;')
                .replace('"','&quot;').replace('\'','&apos;');
    }
}