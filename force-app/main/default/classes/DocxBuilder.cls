/**
 * DocxBuilder — Minister's Certificate
 *
 * Faithfully reproduces Ministry Certificate.docx formatting.
 * All values derived by direct XML inspection of the template file.
 *
 * ── Page Layout — TWO SECTIONS ──────────────────────────────────────────────
 *   Section 1 (certificate page): PORTRAIT
 *     pgSz  : w=12240  h=15840  (no orient attribute)
 *     Margins: top=1440  right=1797  bottom=1440  left=1134  footer=576
 *
 *   Section 2 (Appendix A + all detail pages): LANDSCAPE
 *     pgSz  : w=15840  h=12240  orient="landscape"
 *     Margins: top=1134  right=1440  bottom=1797  left=1440  footer=576
 *
 *   The section break is an inline sectPr inside a blank paragraph placed
 *   immediately before "Appendix A".
 *
 * ── Typography ───────────────────────────────────────────────────────────────
 *   Font        : Times New Roman (all text, no exceptions)
 *   Body text   : 12pt  (sz=24, szCs=24) — "Whereas", "Therefore", body paragraphs
 *   Title/hdrs  : 14pt  (sz=28, szCs=28) — "MINISTER'S CERTIFICATE", "Appendix A",
 *                                           section headers ("Healthcare Services…")
 *   Case # / IF : 11pt  (sz=22, szCs=22) — CaseNumber line, IF_ tokens, total lines
 *   Table cells : inherit from default (no explicit sz in cells — uses doc default 11pt)
 *
 * ── Tables ───────────────────────────────────────────────────────────────────
 *   Case header (Appendix A + detail pages) : no style, w=auto, cols [4322,4318,3780]
 *     (NOTE: detail pages use slightly different cols [4322,3868,4860])
 *   Summary tables (Past/Future costs)      : style=TableGrid, borders val=none sz=0
 *                                             (borders suppressed — plain grid lines)
 *   Detail tables (Ambulance etc.)          : no style, borders val=outset sz=6
 *   No shading/fill on any table in template (2E4057 header fill was NOT in original)
 *   Section type labels ("Ambulance" etc.)  : bold, spacing.before=80, no sz override
 *   Total lines                             : plain paragraph, bold label, 11pt total value
 *
 * ── Signature Block ──────────────────────────────────────────────────────────
 *   ind left=5040  firstLine=720  (NOT right-aligned — left-indented)
 *
 * ── Section-detail page headers ──────────────────────────────────────────────
 *   "Healthcare Services and Costs Record Part N" : Normal style, bold, sz=28
 *   Preceded by a page break paragraph (conditional inclusion handled by isEmpty() guards)
 *   Followed by blank para, then case header table (cols [4322,3868,4860])
 */
public class DocxBuilder {

    // ── Font ──────────────────────────────────────────────────────────────────
    private static final String FONT     = 'Times New Roman';

    // ── Font sizes (half-points) ──────────────────────────────────────────────
    private static final Integer SZ_BODY  = 24;   // 12pt — body/certificate text
    private static final Integer SZ_TITLE = 28;   // 14pt — titles and section headers
    private static final Integer SZ_SMALL = 22;   // 11pt — case#, total values, IF tokens

    // ── Section 1 — Certificate page (PORTRAIT) ─────────────────────────────
    private static final Integer S1_PG_W    = 12240;
    private static final Integer S1_PG_H    = 15840;
    private static final Integer S1_MAR_TOP = 1440;
    private static final Integer S1_MAR_BOT = 1440;
    private static final Integer S1_MAR_L   = 1134;
    private static final Integer S1_MAR_R   = 1797;
    private static final Integer S1_MAR_FTR = 576;

    // ── Section 2 — Appendix + detail pages (LANDSCAPE) ─────────────────────
    private static final Integer S2_PG_W    = 15840;
    private static final Integer S2_PG_H    = 12240;
    private static final Integer S2_MAR_TOP = 1134;
    private static final Integer S2_MAR_BOT = 1797;
    private static final Integer S2_MAR_LR  = 1440;
    private static final Integer S2_MAR_FTR = 576;

    // ── Table column widths (DXA) ─────────────────────────────────────────────
    // Case header on Appendix A summary page (3 cols)
    private static final List<Integer> COLS_CASE_APPX  = new List<Integer>{ 4322, 4318, 3780 };
    // Case header on every detail section page (slightly wider cols)
    private static final List<Integer> COLS_CASE_DETAIL = new List<Integer>{ 4322, 3868, 4860 };
    // Summary tables — auto width, TableGrid style
    private static final List<Integer> COLS_PAST        = new List<Integer>{ 6475, 2700 };
    private static final List<Integer> COLS_FUTURE      = new List<Integer>{ 6475, 2898 };
    // Detail tables — explicit dxa width
    private static final List<Integer> COLS_AMBULANCE   = new List<Integer>{ 1792, 3690, 4320, 2520 };
    private static final List<Integer> COLS_HOSPITAL    = new List<Integer>{ 1522, 1530, 2520, 2880, 1530, 2430 };
    private static final List<Integer> COLS_MSP         = new List<Integer>{ 1792, 2970, 2250, 1350, 1620, 1080, 2160 };
    private static final List<Integer> COLS_PHARMA      = new List<Integer>{ 2152, 4500, 2340, 4410 };
    private static final List<Integer> COLS_CC_FC       = new List<Integer>{ 8902, 3690 };

    // ── Data fields ───────────────────────────────────────────────────────────
    private String caseNumber            = '';
    private String claimNumber           = '';
    private String contactName           = '';
    private String phn                   = '';
    private String birthDate             = '';
    private String incidentDate          = '';
    private String totalCost             = '';
    private String pastServicesTotal     = '';
    private String ambulanceTotal        = '';
    private String hospitalTotal         = '';
    private String medicalTotal          = '';
    private String pharmacyTotal         = '';
    private String continuingCareTotal   = '';
    private String futureCareTotal       = '';
    private String discountFutureCare    = '$0.00';
    private String futureServicesTotal   = '';
    private String signingAuthorityName  = '';
    private String signingAuthorityTitle = '';
    private String day          = '';
    private String daySubscript = '';
    private String month        = '';
    private String year         = '';

    private List<List<String>> ambulanceRecords      = new List<List<String>>();
    private List<List<String>> hospitalRecords       = new List<List<String>>();
    private List<List<String>> mspRecords            = new List<List<String>>();
    private List<List<String>> pharmaRecords         = new List<List<String>>();
    private List<List<String>> continuingCareRecords = new List<List<String>>();
    private List<List<String>> futureCareRecords     = new List<List<String>>();

    // ── Fluent Setters ────────────────────────────────────────────────────────

    /**
     * Populates certificate fields from a Case record.
     * Formula fields (PHN__c, Date_of_Birth__c, ContactName__c, Total_Case_Value__c)
     * are read-only but are readable via SOQL — they resolve at query time.
     * Never attempt to write to these fields in test data or DML.
     */
    public DocxBuilder setCaseData(Case c) {
        this.caseNumber          = strVal(c.CaseNumber);
        this.claimNumber         = strVal(c.Claim_Number__c);
        // ContactName__c is a formula: PersonContact.FirstName + ' ' + PersonContact.LastName
        this.contactName         = strVal(c.ContactName__c);
        // PHN__c is a formula: IF(IsPersonAccount, PersonContact.PHN__c, NULL)
        this.phn                 = strVal(c.PHN__c);
        // Date_of_Birth__c is a formula: PersonContact.Date_of_Birth__c
        this.birthDate           = fmtDate(c.Date_of_Birth__c);
        this.incidentDate        = fmtDate(c.Incident_Date__c);
        // Total_Case_Value__c is a formula: sum of all cost rollup fields
        this.totalCost           = fmtCurrency(c.Total_Case_Value__c);
        this.ambulanceTotal      = fmtCurrency(c.Ambulance_Total2__c);
        this.hospitalTotal       = fmtCurrency(c.Hospitalization_Total2__c);
        this.medicalTotal        = fmtCurrency(c.MSP_Total2__c);
        this.pharmacyTotal       = fmtCurrency(c.Pharmacare_Total2__c);
        this.continuingCareTotal = fmtCurrency(c.Continuing_Care_Total2__c);
        this.futureCareTotal     = fmtCurrency(c.Future_Care_Total2__c);
        this.futureServicesTotal = fmtCurrency(c.Future_Care_Total2__c);
        Decimal past = nvl(c.Total_Case_Value__c) - nvl(c.Future_Care_Total2__c);
        this.pastServicesTotal   = fmtCurrency(past);
        return this;
    }

    /**
     * Ambulance: [ServiceDate, OriginatingPoint, Destination, SingleAmbulanceCost]
     * FacilityName__c is a formula (Facility__r.Facility_Name__c) — readable via SOQL.
     * Falls back to Facility_Name__c (writable) when Facility lookup is unpopulated.
     */
    public DocxBuilder setAmbulanceRecords(List<Healthcare_Cost__c> recs) {
        for (Healthcare_Cost__c r : recs) {
            String dest = String.isNotBlank(r.FacilityName__c)
                ? r.FacilityName__c : strVal(r.Facility_Name__c);
            ambulanceRecords.add(new List<String>{
                fmtDate(r.Date_of_Service__c),
                strVal(r.Location_Responded__c),
                dest,
                fmtCurrency(r.Total_Cost_Override__c)
            });
        }
        return this;
    }

    /**
     * Hospital: [DateOfAdmission, DateOfDischarge, Facility, ServiceType, NumberOfDays, SingleHospitalCost]
     * FacilityName__c  — formula: Facility__r.Facility_Name__c (readable, falls back to Facility_Name__c)
     * Number_of_Days__c — formula: date diff of admission/discharge (readable)
     * Total_Costs_Standard__c — formula: Number_of_Days__c * Standard_Daily_Rate__c (readable)
     * SingleHospitalCost = Total_Cost_Override__c ?? Total_Costs_Standard__c
     */
    public DocxBuilder setHospitalRecords(List<Healthcare_Cost__c> recs) {
        for (Healthcare_Cost__c r : recs) {
            String facility = String.isNotBlank(r.FacilityName__c)
                ? r.FacilityName__c : strVal(r.Facility_Name__c);
            Decimal cost = r.Total_Cost_Override__c != null
                ? r.Total_Cost_Override__c : r.Total_Costs_Standard__c;
            String days = r.Number_of_Days__c != null
                ? String.valueOf(r.Number_of_Days__c.intValue()) : '';
            hospitalRecords.add(new List<String>{
                fmtDate(r.Date_of_Admission__c),
                fmtDate(r.Date_of_Discharge__c),
                facility,
                strVal(r.Service_Type2__c),
                days,
                fmtCurrency(cost)
            });
        }
        return this;
    }

    // MSP: [ServiceDate, LocationType, ServiceDescription, FeeItem, DiagnosticCode, Cost, PractitionerName]
    public DocxBuilder setMSPRecords(List<Healthcare_Cost__c> recs) {
        for (Healthcare_Cost__c r : recs) {
            String locType = (strVal(r.Location_Type_Code__c) + ' ' +
                              strVal(r.Location_Type_Description2__c)).trim();
            mspRecords.add(new List<String>{
                fmtDate(r.Date_of_Service__c),
                locType,
                strVal(r.Description_of_Service2__c),
                strVal(r.Fee_Item_Title__c),
                strVal(r.Diagnostic_Description__c),
                fmtCurrency(r.Total_Cost_Override__c),
                strVal(r.Practitioner_Name__c)
            });
        }
        return this;
    }

    // Pharma: [ServiceDate, Description(drug name), CostPharmacareSingle, PrescribingPractitioner]
    public DocxBuilder setPharmaRecords(List<Healthcare_Cost__c> recs) {
        for (Healthcare_Cost__c r : recs) {
            pharmaRecords.add(new List<String>{
                fmtDate(r.Date_of_Service__c),
                strVal(r.Name_of_Drug__c),
                fmtCurrency(r.Total_Cost_Override__c),
                strVal(r.Practitioner_Name__c)
            });
        }
        return this;
    }

    // CC: [Description, ContinuingCareCost] — NO Cost_Include/Cost_Review filter
    public DocxBuilder setContinuingCareRecords(List<Healthcare_Cost__c> recs) {
        for (Healthcare_Cost__c r : recs) {
            continuingCareRecords.add(new List<String>{
                strVal(r.Description__c), fmtCurrency(r.Cost__c)
            });
        }
        return this;
    }

    // FC: [Description, FutureCareCost] — NO Cost_Include/Cost_Review filter
    public DocxBuilder setFutureCareRecords(List<Healthcare_Cost__c> recs) {
        for (Healthcare_Cost__c r : recs) {
            futureCareRecords.add(new List<String>{
                strVal(r.Description__c), fmtCurrency(r.Cost__c)
            });
        }
        return this;
    }

    public DocxBuilder setSigningAuthority(String name, String title) {
        this.signingAuthorityName  = name  != null ? name  : '';
        this.signingAuthorityTitle = title != null ? title : '';
        return this;
    }

    // ── Build ─────────────────────────────────────────────────────────────────

    public Blob build() {
        computeDateParts();
        Compression.ZipWriter zip = new Compression.ZipWriter();
        zip.addEntry('[Content_Types].xml',          Blob.valueOf(contentTypes()));
        zip.addEntry('_rels/.rels',                  Blob.valueOf(rels()));
        zip.addEntry('word/_rels/document.xml.rels', Blob.valueOf(docRels()));
        zip.addEntry('word/document.xml',            Blob.valueOf(document()));
        zip.addEntry('word/styles.xml',              Blob.valueOf(styles()));
        zip.addEntry('word/footer1.xml',             Blob.valueOf(buildPortraitFooterXml()));
        zip.addEntry('word/footer2.xml',             Blob.valueOf(buildLandscapeFooterXml()));
        zip.addEntry('word/header1.xml',             Blob.valueOf(buildLandscapeHeaderXml()));
        zip.addEntry('docProps/core.xml',            Blob.valueOf(coreProps()));
        return zip.getArchive();
    }

    /**
     * Returns only the opening portion of document.xml — everything up to and
     * including the Appendix A summary tables — WITHOUT closing body/document tags.
     * Used by DocxGeneratorController.enqueueDocument() to seed the temp ContentVersion.
     * The Queueable chain appends detail section XML, then DocxZipSealerQueueable closes.
     *
     * Output starts with: <?xml version...><w:document...><w:body>
     * Output ends with:   ...(last Appendix A summary table)
     * Missing: detail sections + </w:body></w:document>
     */
    public String buildOpeningXml() {
        computeDateParts();

        String b = '';

        // ── Certificate page ──────────────────────────────────────────────────
        b += '<w:p><w:pPr><w:pStyle w:val="Header"/><w:jc w:val="center"/></w:pPr></w:p>';
        b += '<w:p><w:pPr><w:jc w:val="right"/></w:pPr>'
           + r('Case #: ', SZ_SMALL, true, false)
           + r(escXml(caseNumber), SZ_SMALL, false, false) + '</w:p>';
        b += '<w:p><w:pPr><w:jc w:val="center"/></w:pPr>'
           + r('MINISTER\u2019S CERTIFICATE', SZ_TITLE, true, false) + '</w:p>';
        b += blankP();
        b += '<w:p>' + r('Whereas Section 16 of the ', SZ_BODY, false, false)
           + r('Health Care Costs Recovery Act', SZ_BODY, false, true)
           + r(', S.B.C. 2008, c. 27 (the \u201cAct\u201d) permits the Minister, or a person acting on behalf of the Minister, to issue certificates setting out:', SZ_BODY, false, false)
           + '</w:p>';
        b += blankP();
        b += '<w:p>' + r('the health care services that have been received by a beneficiary or class of beneficiaries for personal injuries suffered as a result of the negligence or wrongful act or omission of a wrongdoer; and', SZ_BODY, false, false) + '</w:p>';
        b += '<w:p><w:pPr><w:ind w:left="360"/></w:pPr></w:p>';
        b += '<w:p>' + r('the past cost of health care services, attributable to personal injury suffered by a beneficiary or a class of beneficiaries.', SZ_BODY, false, false) + '</w:p>';
        b += blankP();
        b += '<w:p>' + r('Therefore the undersigned ', SZ_BODY, false, false)
           + r(escXml(signingAuthorityName), SZ_BODY, false, false)
           + r(', acting on behalf of the Minister pursuant to Section 16 of the Act, hereby certifies that the Healthcare Services and Costs Record, attached as Appendix A sets out information relating to a health care services claim for ', SZ_BODY, false, false)
           + r(escXml(contactName), SZ_BODY, false, false)
           + r(', PHN ', SZ_BODY, false, false)
           + r(escXml(phn), SZ_BODY, false, false)
           + r(', for personal injuries suffered as a result of the negligence or wrongful act or omission of a wrongdoer on or about.', SZ_BODY, false, false)
           + '</w:p>';
        b += blankP();
        b += '<w:p>' + r('The Healthcare Services and Costs Record sets out the Health Care Services claim.', SZ_BODY, false, false) + '</w:p>';
        b += blankP();
        b += '<w:p>' + r('The health care services and the past costs of the health care services, as outlined in Appendix A, are complete as of the date of this certificate, and total ', SZ_BODY, false, false)
           + r(escXml(totalCost), SZ_BODY, true, false) + '</w:p>';
        b += blankP();
        b += '<w:p>' + r('Dated at the City of Victoria, in the Province of British Columbia, this ', SZ_BODY, false, false)
           + r(day + daySubscript, SZ_BODY, false, false)
           + r(' day of ', SZ_BODY, false, false)
           + r(month, SZ_BODY, false, false)
           + r(', ', SZ_BODY, false, false)
           + r(year + '.', SZ_BODY, false, false) + '</w:p>';
        b += '<w:p>' + r(' ', SZ_BODY, false, false) + '</w:p>';
        b += blankP(); b += blankP();
        b += '<w:p><w:pPr><w:jc w:val="right"/></w:pPr>' + r('', SZ_BODY, false, false) + '</w:p>';
        b += sigPara(escXml(signingAuthorityName));
        b += sigPara(escXml(signingAuthorityTitle));
        b += sigPara('Designate on behalf of');
        b += sigPara('Minister of Health');
        for (Integer i = 0; i < 4; i++) {
            b += '<w:p><w:pPr><w:jc w:val="right"/><w:ind w:left="4320" w:firstLine="720"/></w:pPr></w:p>';
        }
        b += sectionBreakPara();

        // ── Appendix A ────────────────────────────────────────────────────────
        b += '<w:p><w:pPr><w:jc w:val="center"/></w:pPr>'
           + r('Appendix A', SZ_TITLE, true, false) + '</w:p>';
        b += '<w:p><w:pPr><w:pStyle w:val="Header"/><w:jc w:val="center"/></w:pPr>'
           + r('Healthcare Services Claim', SZ_TITLE, true, false) + '</w:p>';
        b += '<w:p><w:pPr><w:pStyle w:val="Header"/><w:jc w:val="center"/></w:pPr></w:p>';
        b += caseHeaderTbl(COLS_CASE_APPX);
        b += '<w:p><w:pPr><w:pStyle w:val="Header"/></w:pPr></w:p>';
        b += pastCostsTbl();
        b += '<w:p><w:pPr><w:pStyle w:val="Header"/></w:pPr></w:p>';
        b += futureCostsTbl();
        b += '<w:p><w:pPr><w:pStyle w:val="Header"/></w:pPr></w:p>';

        // Return opening XML — NO closing tags, NO detail sections
        // Closing tags and detail sections are appended by the Queueable chain
        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
             + '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
             + '<w:body>' + b;
    }

    // ── Package Parts ─────────────────────────────────────────────────────────

    private String contentTypes() {
        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
            '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' +
            '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' +
            '<Default Extension="xml" ContentType="application/xml"/>' +
            '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>' +
            '<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>' +
            '<Override PartName="/word/footer1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/>' +
            '<Override PartName="/word/footer2.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/>' +
            '<Override PartName="/word/header1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml"/>' +
            '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>' +
            '</Types>';
    }

    private String rels() {
        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
            '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>' +
            '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>' +
            '</Relationships>';
    }

    private String docRels() {
        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
            '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles"  Target="styles.xml"/>' +
            '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer"  Target="footer1.xml"/>' +
            '<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer"  Target="footer2.xml"/>' +
            '<Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/header"  Target="header1.xml"/>' +
            '</Relationships>';
    }

    private String coreProps() {
        String now = Datetime.now().format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
            '<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"' +
            ' xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/"' +
            ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' +
            '<dc:title>Minister\'s Certificate</dc:title>' +
            '<dc:creator>Ministry of Health</dc:creator>' +
            '<dcterms:created xsi:type="dcterms:W3CDTF">' + now + '</dcterms:created>' +
            '</cp:coreProperties>';
    }

    /**
     * Styles: Times New Roman default, TableGrid border definition (single sz=4).
     * Summary tables reference TableGrid but override borders to val=none
     * (matches template: borders present in style but suppressed on table).
     */
    private String styles() {
        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
            '<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">' +
            '<w:docDefaults><w:rPrDefault><w:rPr>' +
            '<w:rFonts w:ascii="' + FONT + '" w:hAnsi="' + FONT + '" w:eastAsia="' + FONT + '" w:cs="' + FONT + '"/>' +
            '<w:sz w:val="' + SZ_SMALL + '"/>' +   // 11pt doc default (matches template)
            '<w:lang w:val="en-US"/>' +
            '</w:rPr></w:rPrDefault></w:docDefaults>' +
            // Normal paragraph style
            '<w:style w:type="paragraph" w:styleId="Normal" w:default="1">' +
            '<w:name w:val="Normal"/>' +
            '<w:pPr><w:spacing w:after="0" w:line="240" w:lineRule="auto"/></w:pPr>' +
            '</w:style>' +
            // Header paragraph style (used on section titles in template)
            '<w:style w:type="paragraph" w:styleId="Header">' +
            '<w:name w:val="header"/><w:basedOn w:val="Normal"/>' +
            '</w:style>' +
            // TableGrid — single border sz=4 (used by summary tables)
            '<w:style w:type="table" w:styleId="TableGrid">' +
            '<w:name w:val="Table Grid"/>' +
            '<w:tblPr><w:tblBorders>' +
            '<w:top w:val="single" w:sz="4" w:space="0" w:color="auto"/>' +
            '<w:left w:val="single" w:sz="4" w:space="0" w:color="auto"/>' +
            '<w:bottom w:val="single" w:sz="4" w:space="0" w:color="auto"/>' +
            '<w:right w:val="single" w:sz="4" w:space="0" w:color="auto"/>' +
            '<w:insideH w:val="single" w:sz="4" w:space="0" w:color="auto"/>' +
            '<w:insideV w:val="single" w:sz="4" w:space="0" w:color="auto"/>' +
            '</w:tblBorders></w:tblPr>' +
            '</w:style>' +
            '</w:styles>';
    }

    // ── Document Body ─────────────────────────────────────────────────────────

    private String document() {
        String b = '';

        // ── Page 1 — Certificate ──────────────────────────────────────────────

        // Blank header-style para (matches template [00])
        b += '<w:p><w:pPr><w:pStyle w:val="Header"/><w:jc w:val="center"/></w:pPr></w:p>';

        // Case # — right-aligned, bold label, 11pt
        b += '<w:p><w:pPr><w:jc w:val="right"/></w:pPr>' +
             r('Case #: ', SZ_SMALL, true, false) +
             r(escXml(caseNumber), SZ_SMALL, false, false) +
             '</w:p>';

        // Title — centered, bold, 14pt
        b += '<w:p><w:pPr><w:jc w:val="center"/></w:pPr>' +
             r('MINISTER\u2019S CERTIFICATE', SZ_TITLE, true, false) +
             '</w:p>';

        // Blank para
        b += blankP();

        // Whereas — body 12pt, Act name italic
        b += '<w:p>' +
             r('Whereas Section 16 of the ', SZ_BODY, false, false) +
             r('Health Care Costs Recovery Act', SZ_BODY, false, true) +
             r(', S.B.C. 2008, c. 27 (the \u201cAct\u201d) permits the Minister, or a person acting on behalf of the Minister, to issue certificates setting out:', SZ_BODY, false, false) +
             '</w:p>';

        b += blankP();

        // Bullet 1 — plain paragraph (template uses no bullets, just plain paras)
        b += '<w:p>' + r('the health care services that have been received by a beneficiary or class of beneficiaries for personal injuries suffered as a result of the negligence or wrongful act or omission of a wrongdoer; and', SZ_BODY, false, false) + '</w:p>';

        // Spacer with left indent (matches template [07] ind left=360)
        b += '<w:p><w:pPr><w:ind w:left="360"/></w:pPr></w:p>';

        // Bullet 2
        b += '<w:p>' + r('the past cost of health care services, attributable to personal injury suffered by a beneficiary or a class of beneficiaries.', SZ_BODY, false, false) + '</w:p>';

        b += blankP();

        // Therefore paragraph — 12pt
        b += '<w:p>' +
             r('Therefore the undersigned ', SZ_BODY, false, false) +
             r(escXml(signingAuthorityName), SZ_BODY, false, false) +
             r(', acting on behalf of the Minister pursuant to Section 16 of the Act, hereby certifies that the Healthcare Services and Costs Record, attached as Appendix A sets out information relating to a health care services claim for ', SZ_BODY, false, false) +
             r(escXml(contactName), SZ_BODY, false, false) +
             r(', PHN ', SZ_BODY, false, false) +
             r(escXml(phn), SZ_BODY, false, false) +
             r(', for personal injuries suffered as a result of the negligence or wrongful act or omission of a wrongdoer on or about.', SZ_BODY, false, false) +
             '</w:p>';

        b += blankP();

        b += '<w:p>' + r('The Healthcare Services and Costs Record sets out the Health Care Services claim.', SZ_BODY, false, false) + '</w:p>';

        b += blankP();

        // Total cost line — bold total value
        b += '<w:p>' +
             r('The health care services and the past costs of the health care services, as outlined in Appendix A, are complete as of the date of this certificate, and total ', SZ_BODY, false, false) +
             r(escXml(totalCost), SZ_BODY, true, false) +
             '</w:p>';

        b += blankP();

        // Dated at — 12pt
        b += '<w:p>' +
             r('Dated at the City of Victoria, in the Province of British Columbia, this ', SZ_BODY, false, false) +
             r(day + daySubscript, SZ_BODY, false, false) +
             r(' day of ', SZ_BODY, false, false) +
             r(month, SZ_BODY, false, false) +
             r(', ', SZ_BODY, false, false) +
             r(year + '.', SZ_BODY, false, false) +
             '</w:p>';

        // Space para with body size (template [17])
        b += '<w:p>' + r(' ', SZ_BODY, false, false) + '</w:p>';
        b += blankP();
        b += blankP();

        // Blank right-aligned para with body-size runs (template [20])
        b += '<w:p><w:pPr><w:jc w:val="right"/></w:pPr>' +
             r('', SZ_BODY, false, false) + '</w:p>';

        // Signature block — ind left=5040 firstLine=720 (NOT right-aligned)
        b += sigPara(escXml(signingAuthorityName));
        b += sigPara(escXml(signingAuthorityTitle));
        b += sigPara('Designate on behalf of');
        b += sigPara('Minister of Health');

        // Empty right-aligned indented paras (template [25-28])
        for (Integer i = 0; i < 4; i++) {
            b += '<w:p><w:pPr><w:jc w:val="right"/><w:ind w:left="4320" w:firstLine="720"/></w:pPr></w:p>';
        }

        // ── Section break: portrait cert ends here, landscape begins ─────────────
        // Inline sectPr paragraph — closes Section 1 (portrait), opens Section 2 (landscape)
        b += sectionBreakPara();

        // ── Appendix A (Section 2 — landscape) ───────────────────────────────

        // "Appendix A" — Normal style, centered, bold, 14pt
        b += '<w:p><w:pPr><w:jc w:val="center"/></w:pPr>' +
             r('Appendix A', SZ_TITLE, true, false) + '</w:p>';

        // "Healthcare Services Claim" — Header style, centered, bold, 14pt
        b += '<w:p><w:pPr><w:pStyle w:val="Header"/><w:jc w:val="center"/></w:pPr>' +
             r('Healthcare Services Claim', SZ_TITLE, true, false) + '</w:p>';

        // Empty Header-style para, centered (template [33])
        b += '<w:p><w:pPr><w:pStyle w:val="Header"/><w:jc w:val="center"/></w:pPr></w:p>';

        // Case header table (Appendix A version — cols [4322,4318,3780], no style, auto width)
        b += caseHeaderTbl(COLS_CASE_APPX);

        // Empty Header para after table
        b += '<w:p><w:pPr><w:pStyle w:val="Header"/></w:pPr></w:p>';

        // Past costs summary table (TableGrid style, borders suppressed)
        b += pastCostsTbl();

        b += '<w:p><w:pPr><w:pStyle w:val="Header"/></w:pPr></w:p>';

        // Future costs summary table
        b += futureCostsTbl();

        b += '<w:p><w:pPr><w:pStyle w:val="Header"/></w:pPr></w:p>';

        // ── Conditional Detail Sections ───────────────────────────────────────
        // Each section: IF token + pagebreak on same para, then header, blank,
        // case header table (detail cols), blank, type label, blank, detail table,
        // blank, total line (total line also carries the closing IF token + next IF token)

        if (!ambulanceRecords.isEmpty()) {
            b += detailSection('Ambulance', ambulanceDetailTbl(), ambulanceTotal, 'Part 1');
        }
        if (!hospitalRecords.isEmpty()) {
            b += detailSection('Hospital', hospitalDetailTbl(), hospitalTotal, 'Part 1');
        }
        if (!mspRecords.isEmpty()) {
            b += detailSection('Medical', mspDetailTbl(), medicalTotal, 'Part 1');
        }
        if (!pharmaRecords.isEmpty()) {
            b += detailSection('Pharmacare', pharmaDetailTbl(), pharmacyTotal, 'Part 1');
        }
        if (!continuingCareRecords.isEmpty()) {
            b += detailSection('Continuing Care', ccFcDetailTbl(continuingCareRecords), continuingCareTotal, 'Part 1');
        }
        if (!futureCareRecords.isEmpty()) {
            b += detailSection('Future Care', ccFcDetailTbl(futureCareRecords), futureCareTotal, 'Part 2');
        }

        // Terminal blank para + body-level landscape section properties (Section 2: landscape)
        b += '<w:p/>';
        b += landscapeSectPr();

        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
               '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">' +
               '<w:body>' + b + '</w:body></w:document>';
    }

    /**
     * Builds one conditional detail section, matching template structure exactly:
     *   Para: page break
     *   Para: "Healthcare Services and Costs Record Part N" (bold, sz=28, Normal style)
     *   Para: blank
     *   Table: case header (detail cols)
     *   Para: blank (jc=center)
     *   Para: type label (bold, spacing.before=80)
     *   Para: blank
     *   Table: detail table
     *   Para: blank
     *   Para: "Total X   <total>" (bold label, 11pt total value)
     */
    private String detailSection(String label, String detailTbl, String total, String part) {
        String s = '';

        // Page break paragraph (section is already conditionally included via isEmpty() guard)
        s += '<w:p><w:r><w:br w:type="page"/></w:r></w:p>';

        // Section title: Header style, centered, bold, 14pt (matches template [40,49,58,67,85])
        // CC section is special: Normal style with indent (handled separately below)
        if (label == 'Continuing Care') {
            s += '<w:p><w:pPr><w:ind w:left="2160" w:firstLine="720"/></w:pPr>' +
                 r('Healthcare Services and Costs Record ' + part, SZ_TITLE, true, false) +
                 '</w:p>';
        } else {
            s += '<w:p><w:pPr><w:pStyle w:val="Header"/><w:jc w:val="center"/></w:pPr>' +
                 r('Healthcare Services and Costs Record ' + part, SZ_TITLE, true, false) +
                 '</w:p>';
        }

        // Empty Header-style bold para (template [41,50,59,68,77,86])
        s += '<w:p><w:pPr><w:pStyle w:val="Header"/></w:pPr>' +
             r('', SZ_SMALL, true, false) + r('', SZ_SMALL, true, false) + '</w:p>';

        // Case header table (detail variant cols) — w=13050 dxa matches template [42]
        s += caseHeaderTblDetail();

        // Empty centered para
        s += '<w:p><w:pPr><w:jc w:val="center"/></w:pPr></w:p>';

        // Service type label — bold, spacing.before=80
        s += '<w:p><w:pPr><w:spacing w:before="80"/></w:pPr>' +
             r(label, 0, true, false) +    // sz=0 = inherit (no explicit sz in template)
             '</w:p>';

        s += blankP();

        // Detail table
        s += detailTbl;

        s += blankP();

        // Total line: bold label then right-aligned total value
        String totalLine = '<w:p>' +
            r('Total ' + label, 0, true, false) +
            r('   ', 0, true, false) +
            r(escXml(total), SZ_SMALL, false, false) +
            '</w:p>';
        s += totalLine;

        return s;
    }

    // ── Table Builders ────────────────────────────────────────────────────────

    /**
     * Case header table for detail section pages — explicit w=13050 dxa (template [42]).
     * Prevents table reflow on landscape pages. Cols [4322,3868,4860].
     */
    private String caseHeaderTblDetail() {
        List<Integer> cols = COLS_CASE_DETAIL;
        String rows =
            tRow(
                tcAuto('', cols[0], true) +
                tcAuto('', cols[1], true) +
                tcAuto('Case #: ' + escXml(caseNumber), cols[2], true),
                false
            ) +
            tRow(
                tcAuto('Name: ' + escXml(contactName), cols[0], true) +
                tcAuto('', cols[1], false) +
                tcAuto('MV Claim #: ' + escXml(claimNumber), cols[2], true),
                false
            ) +
            tRow(
                tcAuto('Incident Date: ' + escXml(incidentDate), cols[0], true) +
                tcAuto('PHN: ' + escXml(phn), cols[1], true) +
                tcAuto('Birth Date: ' + escXml(birthDate), cols[2], true),
                false
            );
        String grid = '';
        for (Integer w : cols) { grid += '<w:gridCol w:w="' + w + '"/>'; }
        // Explicit dxa width (13050) — prevents reflow on landscape page
        return '<w:tbl>' +
               '<w:tblPr><w:tblW w:w="13050" w:type="dxa"/></w:tblPr>' +
               '<w:tblGrid>' + grid + '</w:tblGrid>' +
               rows + '</w:tbl>';
    }

    /**
     * Case header table — no table style, auto width, no borders.
     * Row 1: [blank, blank, Case #: {n}]        — col2 bold
     * Row 2: [Name: {n}, blank, MV Claim #: {n}] — all bold
     * Row 3: [Incident Date: {d}, PHN: {p}, Birth Date: {b}] — all bold
     * All cells: sz=22, bold. Shading: fill=auto (transparent).
     */
    private String caseHeaderTbl(List<Integer> cols) {
        String rows =
            tRow(
                tcAuto('', cols[0], true) +
                tcAuto('', cols[1], true) +
                tcAuto('Case #: ' + escXml(caseNumber), cols[2], true),
                false
            ) +
            tRow(
                tcAuto('Name: ' + escXml(contactName), cols[0], true) +
                tcAuto('', cols[1], false) +
                tcAuto('MV Claim #: ' + escXml(claimNumber), cols[2], true),
                false
            ) +
            tRow(
                tcAuto('Incident Date: ' + escXml(incidentDate), cols[0], true) +
                tcAuto('PHN: ' + escXml(phn), cols[1], true) +
                tcAuto('Birth Date: ' + escXml(birthDate), cols[2], true),
                false
            );

        String grid = '';
        for (Integer w : cols) { grid += '<w:gridCol w:w="' + w + '"/>'; }

        // No style, w=0 auto (matches template table [34])
        return '<w:tbl>' +
               '<w:tblPr><w:tblW w:w="0" w:type="auto"/></w:tblPr>' +
               '<w:tblGrid>' + grid + '</w:tblGrid>' +
               rows + '</w:tbl>';
    }

    /**
     * Past costs summary table — TableGrid style, borders suppressed (val=none sz=0).
     * Header row: "Past Costs of Healthcare Services" spanning col0, bold, sz=inherit.
     * Data rows: label | value, no bold.
     * Divider row: blank | "___________" bold.
     * Total row: label bold | value bold.
     */
    private String pastCostsTbl() {
        List<Integer> cols = COLS_PAST;
        String rows =
            tRow(tcGrid('Past Costs of Healthcare Services', cols[0], true) +
                 tcGrid('', cols[1], true), true) +
            tRow(tcGrid('Ambulance', cols[0], false) + tcGrid(ambulanceTotal, cols[1], false), false) +
            tRow(tcGrid('Hospital', cols[0], false) + tcGrid(hospitalTotal, cols[1], false), false) +
            tRow(tcGrid('Medical', cols[0], false) + tcGrid(medicalTotal, cols[1], false), false) +
            tRow(tcGrid('Pharmacy', cols[0], false) + tcGrid(pharmacyTotal, cols[1], false), false) +
            tRow(tcGrid('Continuing Care', cols[0], false) + tcGrid(continuingCareTotal, cols[1], false), false) +
            tRow(tcGrid('', cols[0], true) + tcGrid('___________', cols[1], true), false) +
            tRow(tcGrid('Total Past Cost of Healthcare Services', cols[0], true) +
                 tcGrid(pastServicesTotal, cols[1], true), false);

        return tblGrid(rows, cols);
    }

    /** Future costs summary table — same pattern as past costs. */
    private String futureCostsTbl() {
        List<Integer> cols = COLS_FUTURE;
        String rows =
            tRow(tcGrid('Future Costs of Healthcare Services', cols[0], true) +
                 tcGrid('', cols[1], true), true) +
            tRow(tcGrid('Future Care', cols[0], false) + tcGrid(futureCareTotal, cols[1], false), false) +
            tRow(tcGrid('Discount at 2% pursuant to s.56(2)(b) of the Law and Equity Act', cols[0], false) +
                 tcGrid('(' + discountFutureCare + ')', cols[1], false), false) +
            tRow(tcGrid('', cols[0], true) + tcGrid('____________', cols[1], true), false) +
            tRow(tcGrid('Total Future Cost of Healthcare Services', cols[0], true) +
                 tcGrid(futureServicesTotal, cols[1], true), false) +
            tRow(tcGrid('', cols[0], false) + tcGrid('', cols[1], false), false) +
            tRow(tcGrid('', cols[0], false) + tcGrid('', cols[1], false), false) +
            tRow(tcGrid('Present Value of Total Healthcare Services Claim', cols[0], true) +
                 tcGrid(totalCost, cols[1], true), false);

        return tblGrid(rows, cols);
    }

    /** Ambulance detail — 4 cols, outset sz=6 borders. Loops over ambulanceRecords. */
    private String ambulanceDetailTbl() {
        List<Integer> cols = COLS_AMBULANCE;
        String rows = tRow(
            tcDetail('Service Date', cols[0], true) + tcDetail('Originating Point', cols[1], true) +
            tcDetail('Destination',  cols[2], true) + tcDetail('Cost',              cols[3], true), true);
        for (List<String> row : ambulanceRecords) {
            rows += tRow(
                tcDetail(row[0], cols[0], false) + tcDetail(row[1], cols[1], false) +
                tcDetail(row[2], cols[2], false) + tcDetail(row[3], cols[3], false), false);
        }
        return tblDetail(rows, cols, 12322);
    }

    /** Hospital detail — 6 cols. Loops over hospitalRecords. */
    private String hospitalDetailTbl() {
        List<Integer> cols = COLS_HOSPITAL;
        String rows = tRow(
            tcDetail('Admit',        cols[0], true) + tcDetail('Discharge',    cols[1], true) +
            tcDetail('Facility',     cols[2], true) + tcDetail('Service Type', cols[3], true) +
            tcDetail('Days',         cols[4], true) + tcDetail('Cost',         cols[5], true), true);
        for (List<String> row : hospitalRecords) {
            rows += tRow(
                tcDetail(row[0], cols[0], false) + tcDetail(row[1], cols[1], false) +
                tcDetail(row[2], cols[2], false) + tcDetail(row[3], cols[3], false) +
                tcDetail(row[4], cols[4], false) + tcDetail(row[5], cols[5], false), false);
        }
        return tblDetail(rows, cols, 12412);
    }

    /** MSP detail — 7 cols. Loops over mspRecords. */
    private String mspDetailTbl() {
        List<Integer> cols = COLS_MSP;
        String rows = tRow(
            tcDetail('Service Date',      cols[0], true) + tcDetail('Location Type', cols[1], true) +
            tcDetail('Service',           cols[2], true) + tcDetail('Fee Item',      cols[3], true) +
            tcDetail('Diagnostic',        cols[4], true) + tcDetail('Cost',          cols[5], true) +
            tcDetail('Practitioner Name', cols[6], true), true);
        for (List<String> row : mspRecords) {
            rows += tRow(
                tcDetail(row[0], cols[0], false) + tcDetail(row[1], cols[1], false) +
                tcDetail(row[2], cols[2], false) + tcDetail(row[3], cols[3], false) +
                tcDetail(row[4], cols[4], false) + tcDetail(row[5], cols[5], false) +
                tcDetail(row[6], cols[6], false), false);
        }
        return tblDetail(rows, cols, 13222);
    }

    /** Pharma detail — 4 cols. Loops over pharmaRecords. */
    private String pharmaDetailTbl() {
        List<Integer> cols = COLS_PHARMA;
        String rows = tRow(
            tcDetail('Service Date', cols[0], true) + tcDetail('Description',             cols[1], true) +
            tcDetail('Cost',         cols[2], true) + tcDetail('Prescribing Practitioner', cols[3], true), true);
        for (List<String> row : pharmaRecords) {
            rows += tRow(
                tcDetail(row[0], cols[0], false) + tcDetail(row[1], cols[1], false) +
                tcDetail(row[2], cols[2], false) + tcDetail(row[3], cols[3], false), false);
        }
        return tblDetail(rows, cols, 13402);
    }

    /**
     * CC / FC detail — 2 cols. Loops over the provided records list.
     * isCC parameter explicitly distinguishes CC from FC (replaces broken == identity check).
     */
    private String ccFcDetailTbl(List<List<String>> records) {
        List<Integer> cols = COLS_CC_FC;
        String rows = tRow(
            tcDetail('Description', cols[0], true) + tcDetail('Cost', cols[1], true), true);
        for (List<String> row : records) {
            rows += tRow(
                tcDetail(row[0], cols[0], false) +
                tcDetail(row[1], cols[1], false), false);
        }
        return tblDetail(rows, cols, 12592);
    }

    // ── XML Primitives ────────────────────────────────────────────────────────

    /**
     * run() — always emits explicit rFonts (Times New Roman) to prevent the
     * document theme's minor font (Calibri) from overriding in some viewers.
     * sz=0 omits the sz element (inherits 11pt doc default), used for table cells.
     */
    private String r(String text, Integer sz, Boolean bold, Boolean italic) {
        String rPr = '<w:rPr>' +
            '<w:rFonts w:ascii="' + FONT + '" w:hAnsi="' + FONT + '" w:cs="' + FONT + '"/>';
        if (bold)   rPr += '<w:b/>';
        if (italic) rPr += '<w:i/>';
        if (sz != null && sz > 0) {
            rPr += '<w:sz w:val="' + sz + '"/><w:szCs w:val="' + sz + '"/>';
        }
        rPr += '</w:rPr>';
        return '<w:r>' + rPr + '<w:t xml:space="preserve">' + text + '</w:t></w:r>';
    }

    private String blankP() {
        return '<w:p/>';
    }

    /** Signature block paragraph — ind left=5040 firstLine=720 */
    private String sigPara(String text) {
        return '<w:p><w:pPr><w:ind w:left="5040" w:firstLine="720"/></w:pPr>' +
               r(text, SZ_BODY, false, false) + '</w:p>';
    }

    private String tRow(String cells, Boolean isHeader) {
        String trPr = isHeader ? '<w:trPr><w:tblHeader/></w:trPr>' : '';
        return '<w:tr>' + trPr + cells + '</w:tr>';
    }

    /**
     * Cell for case header table — fill=auto (transparent), sz=22, bold.
     * No explicit borders (table has no border definition).
     */
    private String tcAuto(String text, Integer width, Boolean bold) {
        return '<w:tc><w:tcPr>' +
               '<w:tcW w:w="' + width + '" w:type="dxa"/>' +
               '<w:shd w:val="clear" w:color="auto" w:fill="auto"/>' +
               '<w:tcMar><w:top w:w="80" w:type="dxa"/><w:bottom w:w="80" w:type="dxa"/>' +
               '<w:left w:w="120" w:type="dxa"/><w:right w:w="120" w:type="dxa"/></w:tcMar>' +
               '</w:tcPr>' +
               '<w:p><w:pPr><w:spacing w:after="0"/></w:pPr>' +
               r(text, SZ_SMALL, bold, false) +
               '</w:p></w:tc>';
    }

    /**
     * Cell for summary tables (TableGrid style, no fill, inherit sz).
     */
    private String tcGrid(String text, Integer width, Boolean bold) {
        return '<w:tc><w:tcPr>' +
               '<w:tcW w:w="' + width + '" w:type="dxa"/>' +
               '<w:tcMar><w:top w:w="80" w:type="dxa"/><w:bottom w:w="80" w:type="dxa"/>' +
               '<w:left w:w="120" w:type="dxa"/><w:right w:w="120" w:type="dxa"/></w:tcMar>' +
               '</w:tcPr>' +
               '<w:p><w:pPr><w:spacing w:after="0"/></w:pPr>' +
               r(text, 0, bold, false) +    // sz=0 = inherit doc default (11pt)
               '</w:p></w:tc>';
    }

    /**
     * Cell for detail tables — outset sz=6 borders on each cell, no fill, inherit sz.
     */
    private String tcDetail(String text, Integer width, Boolean bold) {
        return '<w:tc><w:tcPr>' +
               '<w:tcW w:w="' + width + '" w:type="dxa"/>' +
               outsetBorders() +
               '<w:tcMar><w:top w:w="80" w:type="dxa"/><w:bottom w:w="80" w:type="dxa"/>' +
               '<w:left w:w="120" w:type="dxa"/><w:right w:w="120" w:type="dxa"/></w:tcMar>' +
               '</w:tcPr>' +
               '<w:p><w:pPr><w:spacing w:after="0"/></w:pPr>' +
               r(text, 0, bold, false) +
               '</w:p></w:tc>';
    }

    private String outsetBorders() {
        String b = '<w:tcBorders>';
        for (String side : new List<String>{'top','left','bottom','right'}) {
            b += '<w:' + side + ' w:val="outset" w:sz="6" w:space="0" w:color="auto"/>';
        }
        return b + '</w:tcBorders>';
    }

    /** Summary table wrapper — TableGrid style, w=auto, borders suppressed */
    private String tblGrid(String rows, List<Integer> cols) {
        String grid = '';
        for (Integer w : cols) { grid += '<w:gridCol w:w="' + w + '"/>'; }
        return '<w:tbl>' +
               '<w:tblPr>' +
               '<w:tblStyle w:val="TableGrid"/>' +
               '<w:tblW w:w="0" w:type="auto"/>' +
               '<w:tblBorders>' +
               '<w:top w:val="none" w:sz="0" w:space="0" w:color="auto"/>' +
               '<w:left w:val="none" w:sz="0" w:space="0" w:color="auto"/>' +
               '<w:bottom w:val="none" w:sz="0" w:space="0" w:color="auto"/>' +
               '<w:right w:val="none" w:sz="0" w:space="0" w:color="auto"/>' +
               '<w:insideH w:val="none" w:sz="0" w:space="0" w:color="auto"/>' +
               '<w:insideV w:val="none" w:sz="0" w:space="0" w:color="auto"/>' +
               '</w:tblBorders>' +
               '</w:tblPr>' +
               '<w:tblGrid>' + grid + '</w:tblGrid>' +
               rows + '</w:tbl>';
    }

    /** Detail table wrapper — no style, explicit dxa width, outset table borders */
    private String tblDetail(String rows, List<Integer> cols, Integer width) {
        String grid = '';
        for (Integer w : cols) { grid += '<w:gridCol w:w="' + w + '"/>'; }
        String bdr = '';
        for (String side : new List<String>{'top','left','bottom','right'}) {
            bdr += '<w:' + side + ' w:val="outset" w:sz="6" w:space="0" w:color="auto"/>';
        }
        return '<w:tbl>' +
               '<w:tblPr>' +
               '<w:tblW w:w="' + width + '" w:type="dxa"/>' +
               '<w:tblBorders>' + bdr + '</w:tblBorders>' +
               '</w:tblPr>' +
               '<w:tblGrid>' + grid + '</w:tblGrid>' +
               rows + '</w:tbl>';
    }

    /**
     * Inline section break paragraph — ends Section 1 (portrait cert page).
     * Placed immediately before "Appendix A". No page-break element needed;
     * the sectPr itself triggers the section/page break.
     */
    /**
     * Inline section break — ends Section 1 (portrait certificate page).
     * Portrait section has: Internal footer only. No header. No page numbers.
     */
    private String sectionBreakPara() {
        String r = 'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"';
        return '<w:p><w:pPr><w:sectPr>' +
               '<w:footerReference w:type="default" r:id="rId2" ' + r + '/>' +
               '<w:footerReference w:type="even"    r:id="rId2" ' + r + '/>' +
               '<w:footerReference w:type="first"   r:id="rId2" ' + r + '/>' +
               '<w:pgSz w:w="' + S1_PG_W + '" w:h="' + S1_PG_H + '"/>' +
               '<w:pgMar w:top="' + S1_MAR_TOP + '" w:right="' + S1_MAR_R + '"' +
               ' w:bottom="' + S1_MAR_BOT + '" w:left="' + S1_MAR_L + '"' +
               ' w:header="0" w:footer="' + S1_MAR_FTR + '" w:gutter="0"/>' +
               '</w:sectPr></w:pPr></w:p>';
    }

    /**
     * Body-level section properties — Section 2 landscape (Appendix + detail pages).
     * Landscape section has: "Page X of Y" + Internal footer, "Interim" header.
     */
    private String landscapeSectPr() {
        String r = 'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"';
        return '<w:sectPr>' +
               '<w:footerReference w:type="default" r:id="rId3" ' + r + '/>' +
               '<w:footerReference w:type="even"    r:id="rId3" ' + r + '/>' +
               '<w:footerReference w:type="first"   r:id="rId3" ' + r + '/>' +
               '<w:headerReference w:type="default" r:id="rId4" ' + r + '/>' +
               '<w:headerReference w:type="even"    r:id="rId4" ' + r + '/>' +
               '<w:headerReference w:type="first"   r:id="rId4" ' + r + '/>' +
               '<w:pgSz w:w="' + S2_PG_W + '" w:h="' + S2_PG_H + '" w:orient="landscape"/>' +
               '<w:pgMar w:top="' + S2_MAR_TOP + '" w:right="' + S2_MAR_LR + '"' +
               ' w:bottom="' + S2_MAR_BOT + '" w:left="' + S2_MAR_LR + '"' +
               ' w:header="720" w:footer="' + S2_MAR_FTR + '" w:gutter="0"/>' +
               '</w:sectPr>';
    }

    // ── Footer ───────────────────────────────────────────────────────────────────

    // ── Footer / Header XML ───────────────────────────────────────────────────

    /**
     * Section 1 footer (portrait certificate page): 'Internal' classification label.
     * In the template this is a floating text box anchored bottom-right.
     * We emit a simple centered paragraph — functionally equivalent for classification display.
     */
    private String buildPortraitFooterXml() {
        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
            '<w:ftr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">' +
            '<w:p><w:pPr><w:pStyle w:val="Footer"/><w:jc w:val="right"/></w:pPr>' +
            '<w:r><w:rPr>' +
            '<w:rFonts w:ascii="' + FONT + '" w:hAnsi="' + FONT + '" w:cs="' + FONT + '"/>' +
            '<w:color w:val="000000"/>' +
            '</w:rPr>' +
            '<w:t>Internal</w:t></w:r>' +
            '</w:p></w:ftr>';
    }

    /**
     * Section 2 footer (landscape Appendix + detail pages):
     * Centred "Page X of Y" with Internal classification label on the right.
     * Matches template footer5.xml which has both the PAGE/NUMPAGES field and Internal watermark.
     */
    private String buildLandscapeFooterXml() {
        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
            '<w:ftr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">' +
            // Page X of Y — centered
            '<w:p><w:pPr><w:pStyle w:val="Footer"/><w:jc w:val="center"/></w:pPr>' +
            '<w:r><w:rPr>' +
            '<w:rFonts w:ascii="' + FONT + '" w:hAnsi="' + FONT + '" w:cs="' + FONT + '"/>' +
            '</w:rPr><w:t xml:space="preserve">Page </w:t></w:r>' +
            // PAGE field: begin
            '<w:r><w:fldChar w:fldCharType="begin"/></w:r>' +
            '<w:r><w:instrText xml:space="preserve"> PAGE \\* MERGEFORMAT </w:instrText></w:r>' +
            '<w:r><w:fldChar w:fldCharType="separate"/></w:r>' +
            '<w:r><w:rPr><w:noProof/></w:rPr><w:t>1</w:t></w:r>' +
            '<w:r><w:fldChar w:fldCharType="end"/></w:r>' +
            // " of "
            '<w:r><w:rPr>' +
            '<w:rFonts w:ascii="' + FONT + '" w:hAnsi="' + FONT + '" w:cs="' + FONT + '"/>' +
            '</w:rPr><w:t xml:space="preserve"> of </w:t></w:r>' +
            // NUMPAGES field: begin
            '<w:r><w:fldChar w:fldCharType="begin"/></w:r>' +
            '<w:r><w:instrText xml:space="preserve"> NUMPAGES \\* Arabic \\* MERGEFORMAT </w:instrText></w:r>' +
            '<w:r><w:fldChar w:fldCharType="separate"/></w:r>' +
            '<w:r><w:rPr><w:noProof/></w:rPr><w:t>1</w:t></w:r>' +
            '<w:r><w:fldChar w:fldCharType="end"/></w:r>' +
            '</w:p>' +
            // Internal classification label — right-aligned
            '<w:p><w:pPr><w:pStyle w:val="Footer"/><w:jc w:val="right"/></w:pPr>' +
            '<w:r><w:rPr>' +
            '<w:rFonts w:ascii="' + FONT + '" w:hAnsi="' + FONT + '" w:cs="' + FONT + '"/>' +
            '<w:color w:val="000000"/>' +
            '</w:rPr>' +
            '<w:t>Internal</w:t></w:r>' +
            '</w:p>' +
            '</w:ftr>';
    }

    /**
     * Section 2 header (landscape pages): "Interim" classification label, right-aligned.
     * Matches template header2.xml.
     */
    private String buildLandscapeHeaderXml() {
        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
            '<w:hdr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">' +
            '<w:p><w:pPr><w:pStyle w:val="Header"/><w:jc w:val="right"/></w:pPr>' +
            '<w:r><w:rPr>' +
            '<w:rFonts w:ascii="' + FONT + '" w:hAnsi="' + FONT + '" w:cs="' + FONT + '"/>' +
            '<w:color w:val="000000"/>' +
            '</w:rPr>' +
            '<w:t>Interim</w:t></w:r>' +
            '</w:p></w:hdr>';
    }

    // ── Helpers ───────────────────────────────────────────────────────────────────

    private void computeDateParts() {
        Date today = Date.today();
        Integer d = today.day(), m = today.month();
        this.year  = String.valueOf(today.year());
        this.day   = String.valueOf(d);
        // Fixed month list — corrects the November bug in the original DR formula
        List<String> months = new List<String>{
            'January','February','March','April','May','June',
            'July','August','September','October','November','December'
        };
        this.month = months[m - 1];
        this.daySubscript = (d==1||d==21||d==31) ? 'st'
                          : (d==2||d==22)         ? 'nd'
                          : (d==3||d==23)         ? 'rd' : 'th';
    }

    private String strVal(Object v) { return v == null ? '' : String.valueOf(v); }
    private Decimal nvl(Decimal v)  { return v != null ? v : 0; }

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
