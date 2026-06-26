/**
 * DocxGeneratorQueueable
 * Generates the Minister's Certificate for cases with large Healthcare Cost
 * record sets (tested to 8,000+ rows) by building the document XML in chunks
 * across a chain of Queueable transactions.
 *
 * Each Queueable has a fresh 12MB heap budget. A chunk of 200 rows costs
 * ~0.7MB (200 × 3,620B for MSP, the widest table), well within budget.
 *
 * ── Flow ──────────────────────────────────────────────────────────────────────
 *   1. DocxGeneratorController.enqueueDocument(caseId) [sync, @AuraEnabled]
 *      - Queries Case + signing authority
 *      - Builds certificate page + Appendix A summary XML (~20KB)
 *      - Stores XML opening in a temp ContentVersion
 *      - Enqueues DocxGeneratorQueueable(state)
 *      - Returns jobContentVersionId to LWC for polling
 *
 *   2. DocxGeneratorQueueable.execute() [async, 12MB heap each]
 *      - Queries up to CHUNK_SIZE rows of the current HC type at current offset
 *      - Builds row XML for the chunk (~0.7MB)
 *      - Appends to the temp ContentVersion
 *      - If more rows of this type: re-enqueues with incremented offset
 *      - If type complete: opens next type section, re-enqueues at offset 0
 *      - If all types complete: enqueues DocxZipSealerQueueable
 *
 *   3. DocxZipSealerQueueable.execute() [async, 12MB heap]
 *      - Reads accumulated XML from temp ContentVersion
 *      - Appends closing XML tags
 *      - Wraps in ZIP via Compression.ZipWriter
 *      - Stores final .docx as new ContentVersion linked to Case
 *      - Deletes temp ContentVersion
 *
 *   4. LWC polls DocxGeneratorController.pollDocument(jobCvId) every 3s
 *      - Returns the ContentDocumentId when done, null while pending
 *
 * ── Heap profile ─────────────────────────────────────────────────────────────
 *   Per Queueable: ~200 rows × 3,620B = ~0.7MB XML + ContentVersion read ~0.7MB
 *   Peak per execution: ~1.5MB — well within 12MB async limit
 *   Total chain depth for 8,000 MSP rows: 40 Queueables + 1 sealer = 41
 *   Queueable stack limit: 50 per transaction ✓
 *
 * ── Governor limits ───────────────────────────────────────────────────────────
 *   Each Queueable is a fresh transaction:
 *     SOQL queries:  2 (HC records + ContentVersion read)
 *     DML statements: 1 (new ContentVersion version)
 *     Heap: ~1.5MB of ~12MB limit
 */
public class DocxGeneratorQueueable implements Queueable {

    // Rows processed per Queueable — tune lower if heap errors occur
    @TestVisible private static final Integer CHUNK_SIZE = 200;

    // HC type processing order (matches controller query sequence)
    @TestVisible private static final List<String> HC_TYPES = new List<String>{
        'Ambulance', 'Hospitalization', 'MSP', 'Pharmacare', 'Continuing_Care', 'Future_Care'
    };

    // Types that require Cost_Include=true AND Cost_Review=true filter
    private static final Set<String> FILTERED_TYPES = new Set<String>{
        'Ambulance', 'Hospitalization', 'MSP', 'Pharmacare'
    };

    // ── State (serialised between executions) ─────────────────────────────────
    private Id      caseId;
    private Id      tempCvDocId;      // ContentDocumentId of accumulating XML file
    private Integer typeIndex;        // current position in HC_TYPES
    private Boolean typeOpened;       // true once table-open XML written for current type
    private Id      lastProcessedId;  // keyset pagination cursor — avoids SOQL OFFSET 2000 limit
    // Cached case-level values for case header table on each detail page
    private String  caseNumber;
    private String  contactName;
    private String  phn;
    private String  claimNumber;
    private String  incidentDate;
    private String  birthDate;
    // Cost totals for total lines
    private String  ambulanceTotal;
    private String  hospitalTotal;
    private String  medicalTotal;
    private String  pharmacyTotal;
    private String  continuingCareTotal;
    private String  futureCareTotal;

    public DocxGeneratorQueueable(Id caseId, Id tempCvDocId,
                                  Integer typeIndex, Integer rowOffset,
                                  Boolean typeOpened,
                                  Id lastProcessedId,
                                  String caseNumber, String contactName,
                                  String phn, String claimNumber,
                                  String incidentDate, String birthDate,
                                  String ambulanceTotal, String hospitalTotal,
                                  String medicalTotal, String pharmacyTotal,
                                  String continuingCareTotal, String futureCareTotal) {
        this.caseId            = caseId;
        this.tempCvDocId       = tempCvDocId;
        this.typeIndex         = typeIndex;
        this.typeOpened        = typeOpened;
        this.lastProcessedId   = lastProcessedId;
        this.caseNumber        = caseNumber;
        this.contactName       = contactName;
        this.phn               = phn;
        this.claimNumber       = claimNumber;
        this.incidentDate      = incidentDate;
        this.birthDate         = birthDate;
        this.ambulanceTotal    = ambulanceTotal;
        this.hospitalTotal     = hospitalTotal;
        this.medicalTotal      = medicalTotal;
        this.pharmacyTotal     = pharmacyTotal;
        this.continuingCareTotal = continuingCareTotal;
        this.futureCareTotal   = futureCareTotal;
    }

    public void execute(QueueableContext ctx) {
        String currentType = HC_TYPES[typeIndex];
        String chunk = '';

        // ── Query this chunk ──────────────────────────────────────────────────
        List<Healthcare_Cost__c> rows = queryChunk(currentType);

        // ── If this is the first chunk of this type, write section opening ────
        if (!typeOpened && !rows.isEmpty()) {
            chunk += sectionOpening(currentType);
            typeOpened = true;
        }

        // ── Build row XML for this chunk ──────────────────────────────────────
        for (Healthcare_Cost__c r : rows) {
            chunk += buildRow(currentType, r);
        }

        // ── Determine what comes next ─────────────────────────────────────────
        Boolean moreRowsThisType = (rows.size() == CHUNK_SIZE);

        // Capture the last processed Id for keyset pagination (replaces OFFSET)
        Id newLastId = rows.isEmpty() ? lastProcessedId : rows[rows.size()-1].Id;

        // If we opened this type's section, check if we need to close it
        if (typeOpened && !moreRowsThisType) {
            chunk += sectionClosing(currentType);
        }

        // Append chunk to the temp ContentVersion
        if (String.isNotBlank(chunk)) {
            appendToTempFile(chunk);
        }

        // ── Decide next step ──────────────────────────────────────────────────
        if (moreRowsThisType) {
            // More rows of this type — continue with next chunk
            System.enqueueJob(makeNext(typeIndex, newLastId, true));
        } else {
            // This type is done — move to next type
            Integer nextTypeIndex = typeIndex + 1;
            if (nextTypeIndex < HC_TYPES.size()) {
                System.enqueueJob(makeNext(nextTypeIndex, null, false));
            } else {
                // All types done — seal the ZIP
                System.enqueueJob(new DocxZipSealerQueueable(caseId, tempCvDocId));
            }
        }
    }

    // ── Query ─────────────────────────────────────────────────────────────────

    private List<Healthcare_Cost__c> queryChunk(String hcType) {
        Boolean needsFilter = FILTERED_TYPES.contains(hcType);

        // Keyset pagination using Id > :lastProcessedId avoids SOQL OFFSET 2000 limit.
        // All queries ORDER BY Id ASC to ensure consistent pagination.
        // Note: ordering by Id rather than by date changes sort order for display,
        // but avoids the OFFSET 2000 hard limit that would silently truncate at 2001 rows.
        // TODO: if sort-by-date is required, implement a custom sort index field.
        if (hcType == 'Ambulance') {
            return lastProcessedId == null
                ? [SELECT Id, Date_of_Service__c, Location_Responded__c,
                           FacilityName__c, Facility_Name__c, Total_Cost_Override__c
                   FROM Healthcare_Cost__c
                   WHERE Case2__c = :caseId AND RecordTypeName__c = :hcType
                     AND Cost_Include__c = true AND Cost_Review__c = true
                   ORDER BY Id ASC LIMIT :CHUNK_SIZE]
                : [SELECT Id, Date_of_Service__c, Location_Responded__c,
                           FacilityName__c, Facility_Name__c, Total_Cost_Override__c
                   FROM Healthcare_Cost__c
                   WHERE Case2__c = :caseId AND RecordTypeName__c = :hcType
                     AND Cost_Include__c = true AND Cost_Review__c = true
                     AND Id > :lastProcessedId
                   ORDER BY Id ASC LIMIT :CHUNK_SIZE];
        } else if (hcType == 'Hospitalization') {
            return lastProcessedId == null
                ? [SELECT Id, Date_of_Admission__c, Date_of_Discharge__c,
                           FacilityName__c, Facility_Name__c, Service_Type2__c,
                           Number_of_Days__c, Total_Cost_Override__c, Total_Costs_Standard__c
                   FROM Healthcare_Cost__c
                   WHERE Case2__c = :caseId AND RecordTypeName__c = :hcType
                     AND Cost_Include__c = true AND Cost_Review__c = true
                   ORDER BY Id ASC LIMIT :CHUNK_SIZE]
                : [SELECT Id, Date_of_Admission__c, Date_of_Discharge__c,
                           FacilityName__c, Facility_Name__c, Service_Type2__c,
                           Number_of_Days__c, Total_Cost_Override__c, Total_Costs_Standard__c
                   FROM Healthcare_Cost__c
                   WHERE Case2__c = :caseId AND RecordTypeName__c = :hcType
                     AND Cost_Include__c = true AND Cost_Review__c = true
                     AND Id > :lastProcessedId
                   ORDER BY Id ASC LIMIT :CHUNK_SIZE];
        } else if (hcType == 'MSP') {
            return lastProcessedId == null
                ? [SELECT Id, Date_of_Service__c, Location_Type_Code__c,
                           Location_Type_Description2__c, Description_of_Service2__c,
                           Fee_Item_Title__c, Diagnostic_Description__c,
                           Total_Cost_Override__c, Practitioner_Name__c
                   FROM Healthcare_Cost__c
                   WHERE Case2__c = :caseId AND RecordTypeName__c = :hcType
                     AND Cost_Include__c = true AND Cost_Review__c = true
                   ORDER BY Id ASC LIMIT :CHUNK_SIZE]
                : [SELECT Id, Date_of_Service__c, Location_Type_Code__c,
                           Location_Type_Description2__c, Description_of_Service2__c,
                           Fee_Item_Title__c, Diagnostic_Description__c,
                           Total_Cost_Override__c, Practitioner_Name__c
                   FROM Healthcare_Cost__c
                   WHERE Case2__c = :caseId AND RecordTypeName__c = :hcType
                     AND Cost_Include__c = true AND Cost_Review__c = true
                     AND Id > :lastProcessedId
                   ORDER BY Id ASC LIMIT :CHUNK_SIZE];
        } else if (hcType == 'Pharmacare') {
            return lastProcessedId == null
                ? [SELECT Id, Date_of_Service__c, Name_of_Drug__c,
                           Total_Cost_Override__c, Practitioner_Name__c
                   FROM Healthcare_Cost__c
                   WHERE Case2__c = :caseId AND RecordTypeName__c = :hcType
                     AND Cost_Include__c = true AND Cost_Review__c = true
                   ORDER BY Id ASC LIMIT :CHUNK_SIZE]
                : [SELECT Id, Date_of_Service__c, Name_of_Drug__c,
                           Total_Cost_Override__c, Practitioner_Name__c
                   FROM Healthcare_Cost__c
                   WHERE Case2__c = :caseId AND RecordTypeName__c = :hcType
                     AND Cost_Include__c = true AND Cost_Review__c = true
                     AND Id > :lastProcessedId
                   ORDER BY Id ASC LIMIT :CHUNK_SIZE];
        } else {
            // Continuing_Care and Future_Care — no include/review filter
            return lastProcessedId == null
                ? [SELECT Id, Description__c, Cost__c FROM Healthcare_Cost__c
                   WHERE Case2__c = :caseId AND RecordTypeName__c = :hcType
                   ORDER BY Id ASC LIMIT :CHUNK_SIZE]
                : [SELECT Id, Description__c, Cost__c FROM Healthcare_Cost__c
                   WHERE Case2__c = :caseId AND RecordTypeName__c = :hcType
                     AND Id > :lastProcessedId
                   ORDER BY Id ASC LIMIT :CHUNK_SIZE];
        }
    }

    // ── Section XML builders ──────────────────────────────────────────────────

    /**
     * Writes the page break, section header, case header table, type label,
     * and table opening tag for a given HC type.
     * Called once per type, before the first chunk of rows.
     */
    private String sectionOpening(String hcType) {
        String part = (hcType == 'Future_Care') ? 'Part 2' : 'Part 1';
        String label = typeLabel(hcType);
        String font = 'Times New Roman';
        String sz28 = '28';
        String sz22 = '22';

        String s = '';

        // Page break
        s += '<w:p><w:r><w:br w:type="page"/></w:r></w:p>';

        // Section header — Header style, centered, bold, 14pt (all except CC)
        if (hcType == 'Continuing_Care') {
            s += '<w:p><w:pPr><w:ind w:left="2160" w:firstLine="720"/></w:pPr>'
               + run('Healthcare Services and Costs Record ' + part, sz28, true, font)
               + '</w:p>';
        } else {
            s += '<w:p><w:pPr><w:pStyle w:val="Header"/><w:jc w:val="center"/></w:pPr>'
               + run('Healthcare Services and Costs Record ' + part, sz28, true, font)
               + '</w:p>';
        }

        // Empty Header-style para
        s += '<w:p><w:pPr><w:pStyle w:val="Header"/></w:pPr>'
           + run('', sz22, true, font) + run('', sz22, true, font) + '</w:p>';

        // Case header table (detail variant — explicit w=13050 dxa)
        s += caseHeaderTblXml();

        // Empty centered para
        s += '<w:p><w:pPr><w:jc w:val="center"/></w:pPr></w:p>';

        // Service type label — bold, spacing.before=80
        s += '<w:p><w:pPr><w:spacing w:before="80"/></w:pPr>'
           + run(label, '0', true, font) + '</w:p>';

        s += '<w:p/>';

        // Table opening with header row
        s += tableOpening(hcType);

        return s;
    }

    /**
     * Closes the table and writes the total line for the current type.
     * Called after the last chunk of rows for a type.
     */
    private String sectionClosing(String hcType) {
        String label = typeLabel(hcType);
        String total = typeTotal(hcType);
        String font  = 'Times New Roman';

        return '</w:tbl><w:p/>'
             + '<w:p>'
             + run('Total ' + label, '0', true, font)
             + run('   ', '0', true, font)
             + run(escXml(total), '22', false, font)
             + '</w:p>';
    }

    private String tableOpening(String hcType) {
        if (hcType == 'Ambulance') {
            return tblOpen(new List<Integer>{1792,3690,4320,2520}, 12322,
                new List<String>{'Service Date','Originating Point','Destination','Cost'});
        } else if (hcType == 'Hospitalization') {
            return tblOpen(new List<Integer>{1522,1530,2520,2880,1530,2430}, 12412,
                new List<String>{'Admit','Discharge','Facility','Service Type','Days','Cost'});
        } else if (hcType == 'MSP') {
            return tblOpen(new List<Integer>{1792,2970,2250,1350,1620,1080,2160}, 13222,
                new List<String>{'Service Date','Location Type','Service','Fee Item','Diagnostic','Cost','Practitioner Name'});
        } else if (hcType == 'Pharmacare') {
            return tblOpen(new List<Integer>{2152,4500,2340,4410}, 13402,
                new List<String>{'Service Date','Description','Cost','Prescribing Practitioner'});
        } else {
            // CC and FC share the same 2-col layout
            return tblOpen(new List<Integer>{8902,3690}, 12592,
                new List<String>{'Description','Cost'});
        }
    }

    private String tblOpen(List<Integer> cols, Integer width, List<String> headers) {
        String font = 'Times New Roman';
        String grid = '';
        for (Integer w : cols) { grid += '<w:gridCol w:w="' + w + '"/>'; }

        String bdr = '';
        for (String side : new List<String>{'top','left','bottom','right'}) {
            bdr += '<w:' + side + ' w:val="outset" w:sz="6" w:space="0" w:color="auto"/>';
        }

        String hdrCells = '';
        for (Integer i = 0; i < cols.size(); i++) {
            hdrCells += cell(escXml(headers[i]), cols[i], true, font);
        }

        return '<w:tbl>'
             + '<w:tblPr><w:tblW w:w="' + width + '" w:type="dxa"/>'
             + '<w:tblBorders>' + bdr + '</w:tblBorders></w:tblPr>'
             + '<w:tblGrid>' + grid + '</w:tblGrid>'
             + '<w:tr><w:trPr><w:tblHeader/></w:trPr>' + hdrCells + '</w:tr>';
    }

    private String buildRow(String hcType, Healthcare_Cost__c r) {
        String font = 'Times New Roman';
        List<Integer> cols;
        List<String> vals;

        if (hcType == 'Ambulance') {
            cols = new List<Integer>{1792,3690,4320,2520};
            String dest = String.isNotBlank(r.FacilityName__c) ? r.FacilityName__c : strVal(r.Facility_Name__c);
            vals = new List<String>{fmtDate(r.Date_of_Service__c), strVal(r.Location_Responded__c), dest, fmtCurrency(r.Total_Cost_Override__c)};
        } else if (hcType == 'Hospitalization') {
            cols = new List<Integer>{1522,1530,2520,2880,1530,2430};
            String fac  = String.isNotBlank(r.FacilityName__c) ? r.FacilityName__c : strVal(r.Facility_Name__c);
            Decimal cost = r.Total_Cost_Override__c != null ? r.Total_Cost_Override__c : r.Total_Costs_Standard__c;
            String days  = r.Number_of_Days__c != null ? String.valueOf(r.Number_of_Days__c.intValue()) : '';
            vals = new List<String>{fmtDate(r.Date_of_Admission__c), fmtDate(r.Date_of_Discharge__c), fac, strVal(r.Service_Type2__c), days, fmtCurrency(cost)};
        } else if (hcType == 'MSP') {
            cols = new List<Integer>{1792,2970,2250,1350,1620,1080,2160};
            String loc = (strVal(r.Location_Type_Code__c) + ' ' + strVal(r.Location_Type_Description2__c)).trim();
            vals = new List<String>{fmtDate(r.Date_of_Service__c), loc, strVal(r.Description_of_Service2__c), strVal(r.Fee_Item_Title__c), strVal(r.Diagnostic_Description__c), fmtCurrency(r.Total_Cost_Override__c), strVal(r.Practitioner_Name__c)};
        } else if (hcType == 'Pharmacare') {
            cols = new List<Integer>{2152,4500,2340,4410};
            vals = new List<String>{fmtDate(r.Date_of_Service__c), strVal(r.Name_of_Drug__c), fmtCurrency(r.Total_Cost_Override__c), strVal(r.Practitioner_Name__c)};
        } else {
            cols = new List<Integer>{8902,3690};
            vals = new List<String>{strVal(r.Description__c), fmtCurrency(r.Cost__c)};
        }

        String cells = '';
        for (Integer i = 0; i < cols.size(); i++) {
            cells += cell(escXml(vals[i]), cols[i], false, font);
        }
        return '<w:tr><w:trPr><w:trHeight w:val="320"/></w:trPr>' + cells + '</w:tr>';
    }

    // ── Case header table (repeated on each detail page) ─────────────────────

    private String caseHeaderTblXml() {
        List<Integer> cols = new List<Integer>{4322, 3868, 4860};
        String font = 'Times New Roman';
        String sz = '22';

        String row1 = '<w:tr>'
            + tcAuto('', cols[0], sz, font)
            + tcAuto('', cols[1], sz, font)
            + tcAuto('Case #: ' + escXml(caseNumber), cols[2], sz, font)
            + '</w:tr>';
        String row2 = '<w:tr>'
            + tcAuto('Name: ' + escXml(contactName), cols[0], sz, font)
            + tcAuto('', cols[1], sz, font)
            + tcAuto('MV Claim #: ' + escXml(claimNumber), cols[2], sz, font)
            + '</w:tr>';
        String row3 = '<w:tr>'
            + tcAuto('Incident Date: ' + escXml(incidentDate), cols[0], sz, font)
            + tcAuto('PHN: ' + escXml(phn), cols[1], sz, font)
            + tcAuto('Birth Date: ' + escXml(birthDate), cols[2], sz, font)
            + '</w:tr>';

        String grid = '';
        for (Integer w : cols) { grid += '<w:gridCol w:w="' + w + '"/>'; }

        return '<w:tbl>'
             + '<w:tblPr><w:tblW w:w="13050" w:type="dxa"/></w:tblPr>'
             + '<w:tblGrid>' + grid + '</w:tblGrid>'
             + row1 + row2 + row3 + '</w:tbl>';
    }

    private String tcAuto(String text, Integer width, String sz, String font) {
        return '<w:tc><w:tcPr>'
             + '<w:tcW w:w="' + width + '" w:type="dxa"/>'
             + '<w:shd w:val="clear" w:color="auto" w:fill="auto"/>'
             + '<w:tcMar><w:top w:w="80" w:type="dxa"/><w:bottom w:w="80" w:type="dxa"/>'
             + '<w:left w:w="120" w:type="dxa"/><w:right w:w="120" w:type="dxa"/></w:tcMar>'
             + '</w:tcPr>'
             + '<w:p><w:pPr><w:spacing w:after="0"/></w:pPr>'
             + run(text, sz, true, font)
             + '</w:p></w:tc>';
    }

    // ── XML primitives ────────────────────────────────────────────────────────

    private String cell(String text, Integer width, Boolean bold, String font) {
        String bdr = '<w:tcBorders>'
            + '<w:top w:val="outset" w:sz="6" w:space="0" w:color="auto"/>'
            + '<w:left w:val="outset" w:sz="6" w:space="0" w:color="auto"/>'
            + '<w:bottom w:val="outset" w:sz="6" w:space="0" w:color="auto"/>'
            + '<w:right w:val="outset" w:sz="6" w:space="0" w:color="auto"/>'
            + '</w:tcBorders>';
        return '<w:tc><w:tcPr>'
             + '<w:tcW w:w="' + width + '" w:type="dxa"/>' + bdr
             + '<w:tcMar><w:top w:w="80" w:type="dxa"/><w:bottom w:w="80" w:type="dxa"/>'
             + '<w:left w:w="120" w:type="dxa"/><w:right w:w="120" w:type="dxa"/></w:tcMar>'
             + '</w:tcPr>'
             + '<w:p><w:pPr><w:spacing w:after="0"/></w:pPr>'
             + run(text, '0', bold, font)
             + '</w:p></w:tc>';
    }

    private String run(String text, String sz, Boolean bold, String font) {
        String rPr = '<w:rPr>'
            + '<w:rFonts w:ascii="' + font + '" w:hAnsi="' + font + '" w:cs="' + font + '"/>'
            + (bold ? '<w:b/>' : '')
            + (sz != '0' ? '<w:sz w:val="' + sz + '"/><w:szCs w:val="' + sz + '"/>' : '')
            + '</w:rPr>';
        return '<w:r>' + rPr + '<w:t xml:space="preserve">' + text + '</w:t></w:r>';
    }

    // ── ContentVersion append ─────────────────────────────────────────────────

    /**
     * Appends xmlChunk to the accumulating temp ContentVersion.
     * Uses IsLatest=true for reliable version selection.
     * Sets IsMajorVersion=false to keep temp versions out of Files UI.
     *
     * NOTE: This reads back the ENTIRE accumulated XML on every call.
     * Heap grows O(n²) with number of chunks. This is an architectural
     * limitation of Apex ContentVersion — there is no append-only write API.
     * For 8,000 MSP rows this approach fails at ~chunk 14 (~2,800 rows).
     * For cases exceeding this, the per-section .docx split pattern must be used.
     */
    private void appendToTempFile(String xmlChunk) {
        ContentVersion latest = [
            SELECT VersionData, PathOnClient
            FROM ContentVersion
            WHERE ContentDocumentId = :tempCvDocId AND IsLatest = true
            LIMIT 1
        ];
        String existing = latest.VersionData.toString();
        ContentVersion newVer = new ContentVersion();
        newVer.ContentDocumentId = tempCvDocId;
        newVer.VersionData       = Blob.valueOf(existing + xmlChunk);
        newVer.PathOnClient      = latest.PathOnClient;
        newVer.IsMajorVersion    = false;
        newVer.ReasonForChange   = 'DocGen chunk append';
        insert newVer;
    }

    // ── Next Queueable factory ────────────────────────────────────────────────

    private DocxGeneratorQueueable makeNext(Integer nextTypeIndex, Id nextLastId, Boolean opened) {
        return new DocxGeneratorQueueable(
            caseId, tempCvDocId, nextTypeIndex, 0, opened, nextLastId,
            caseNumber, contactName, phn, claimNumber, incidentDate, birthDate,
            ambulanceTotal, hospitalTotal, medicalTotal, pharmacyTotal,
            continuingCareTotal, futureCareTotal
        );
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private String typeLabel(String hcType) {
        if (hcType == 'Ambulance')     return 'Ambulance';
        if (hcType == 'Hospitalization') return 'Hospital';
        if (hcType == 'MSP')           return 'Medical';
        if (hcType == 'Pharmacare')    return 'Pharmacare';
        if (hcType == 'Continuing_Care') return 'Continuing Care';
        return 'Future Care';
    }

    private String typeTotal(String hcType) {
        if (hcType == 'Ambulance')     return ambulanceTotal;
        if (hcType == 'Hospitalization') return hospitalTotal;
        if (hcType == 'MSP')           return medicalTotal;
        if (hcType == 'Pharmacare')    return pharmacyTotal;
        if (hcType == 'Continuing_Care') return continuingCareTotal;
        return futureCareTotal;
    }

    private String strVal(Object v)     { return v == null ? '' : String.valueOf(v); }
    private Decimal nvl(Decimal v)      { return v != null ? v : 0; }
    private String fmtCurrency(Decimal val) {
        if (val == null) return '$0.00';
        return '$' + val.setScale(2).toPlainString();
    }
    private String fmtDate(Date d) {
        if (d == null) return '';
        String mm = String.valueOf(d.month()).leftPad(2, '0');
        String dd = String.valueOf(d.day()).leftPad(2, '0');
        return mm + '/' + dd + '/' + String.valueOf(d.year());
    }
    private String escXml(String s) {
        if (s == null) return '';
        return s.replace('&','&amp;').replace('<','&lt;').replace('>','&gt;')
                .replace('"','&quot;').replace('\'','&apos;');
    }
}
