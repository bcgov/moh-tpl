/**
* Author: Nikhil Jeenru
* Company: CGI
* Purpose:
* Builds the WordprocessingML document content and packages it as a DOCX file.
*/
public class DocxBuilder {
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
    private String documentType = '';
    private Boolean useWatermark         = true;
    private Boolean includeDetailSectionHeader = true;
    private Boolean includeDetailSectionTotal  = true;
    private Boolean includeDetailSectionLabel  = true;
    private Boolean includeDetailColumnHeader  = true;
    private Boolean isMinistryCert  = true;
    private Boolean isCaseHistoryCert = false;
    private String logoStaticResourceName = DocgenConstants.DEFAULT_LOGO_STATIC_RESOURCE;
    private transient Blob logoBody;
    private transient Boolean logoLoadAttempted = false;
    
    private List<List<String>> ambulanceRecords      = new List<List<String>>();
    private List<List<String>> hospitalRecords       = new List<List<String>>();
    private List<List<String>> mspRecords            = new List<List<String>>();
    private List<List<String>> pharmaRecords         = new List<List<String>>();
    private List<List<String>> continuingCareRecords = new List<List<String>>();
    private List<List<String>> futureCareRecords     = new List<List<String>>();
    
    /**
* Populates certificate fields from a Case record.
* Formula fields (PHN__c, Date_of_Birth__c, ContactName__c, Total_Case_Value__c)
* are read-only but are readable via SOQL — they resolve at query time.
* Never attempt to write to these fields in test data or DML.
*/
    public DocxBuilder setCaseData(Case c) {
        this.caseNumber          = DocxFormatHelper.stringValue(c.CaseNumber);
        this.claimNumber         = DocxFormatHelper.stringValue(c.Claim_Number__c);
        this.contactName         = DocxFormatHelper.stringValue(c.ContactName__c);
        this.phn                 = DocxFormatHelper.stringValue(c.PHN__c);
        this.birthDate           = DocxFormatHelper.formatDate(c.Date_of_Birth__c);
        this.incidentDate        = DocxFormatHelper.formatDate(c.Incident_Date__c);
        this.totalCost           = DocxFormatHelper.formatCurrency(c.Total_Case_Value__c);
        this.ambulanceTotal      = DocxFormatHelper.formatCurrency(c.Ambulance_Total2__c);
        this.hospitalTotal       = DocxFormatHelper.formatCurrency(c.Hospitalization_Total2__c);
        this.medicalTotal        = DocxFormatHelper.formatCurrency(c.MSP_Total2__c);
        this.pharmacyTotal       = DocxFormatHelper.formatCurrency(c.Pharmacare_Total2__c);
        this.continuingCareTotal = DocxFormatHelper.formatCurrency(c.Continuing_Care_Total2__c);
        this.futureCareTotal     = DocxFormatHelper.formatCurrency(c.Future_Care_Total2__c);
        this.futureServicesTotal = DocxFormatHelper.formatCurrency(c.Future_Care_Total2__c);
        Decimal past = DocxFormatHelper.decimalValue(c.Total_Case_Value__c) - DocxFormatHelper.decimalValue(c.Future_Care_Total2__c);
        this.pastServicesTotal   = DocxFormatHelper.formatCurrency(past);
        return this;
    }
    
    /**
Params: List<Healthcare_Cost__c> recs
* Sets the ambulance Healthcare Cost records used for the DOCX. Returns this DocxBuilder instance.
*/
    public DocxBuilder setAmbulanceRecords(List<Healthcare_Cost__c> recs) {
        for (Healthcare_Cost__c r : recs) {
            String dest = String.isNotBlank(r.FacilityName__c)
                ? r.FacilityName__c : DocxFormatHelper.stringValue(r.Facility_Name__c);
            ambulanceRecords.add(new List<String>{
                DocxFormatHelper.formatDate(r.Date_of_Service__c),
                    DocxFormatHelper.stringValue(r.Location_Responded__c),
                    dest,
                    DocxFormatHelper.formatCurrency(r.Total_Cost_Override__c)
                    });
        }
        return this;
    }
    
    /**
Params: List<Healthcare_Cost__c> recs
* Sets the hospital Healthcare Cost records used for the DOCX. Returns this DocxBuilder instance.
*/
    public DocxBuilder setHospitalRecords(List<Healthcare_Cost__c> recs) {
        for (Healthcare_Cost__c r : recs) {
            String facility = String.isNotBlank(r.FacilityName__c)
                ? r.FacilityName__c : DocxFormatHelper.stringValue(r.Facility_Name__c);
            Decimal cost = r.Total_Cost_Override__c != null
                ? r.Total_Cost_Override__c : r.Total_Costs_Standard__c;
            String days = r.Number_of_Days__c != null
                ? String.valueOf(r.Number_of_Days__c.intValue()) : '';
            hospitalRecords.add(new List<String>{
                DocxFormatHelper.formatDate(r.Date_of_Admission__c),
                    DocxFormatHelper.formatDate(r.Date_of_Discharge__c),
                    facility,
                    DocxFormatHelper.stringValue(r.Service_Type2__c),
                    days,
                    DocxFormatHelper.formatCurrency(cost)
                    });
        }
        return this;
    }
    
    /**
Params: List<Healthcare_Cost__c> recs
* Sets the MSP Healthcare Cost records used for the DOCX. Returns this DocxBuilder instance.
*/
    public DocxBuilder setMSPRecords(List<Healthcare_Cost__c> recs) {
        for (Healthcare_Cost__c r : recs) {
            String locType = DocxFormatHelper.stringValue(r.Location_Type_Description2__c).trim();
            mspRecords.add(new List<String>{
                DocxFormatHelper.formatDate(r.Date_of_Service__c),
                    locType,
                    DocxFormatHelper.stringValue(r.Description_of_Service2__c),
                    DocxFormatHelper.stringValue(r.Fee_Item_Title__c),
                    DocxFormatHelper.stringValue(r.Diagnostic_Description__c),
                    DocxFormatHelper.formatCurrency(r.Total_Cost_Override__c),
                    DocxFormatHelper.stringValue(r.Practitioner_Name__c)
                    });
        }
        return this;
    }
    
    /**
Params: List<Healthcare_Cost__c> recs
* Sets the PharmaCare Healthcare Cost records used for the DOCX. Returns this DocxBuilder instance.
*/
    public DocxBuilder setPharmaRecords(List<Healthcare_Cost__c> recs) {
        for (Healthcare_Cost__c r : recs) {
            pharmaRecords.add(new List<String>{
                DocxFormatHelper.formatDate(r.Date_of_Service__c),
                    DocxFormatHelper.stringValue(r.Name_of_Drug__c),
                    DocxFormatHelper.formatCurrency(r.Total_Cost_Override__c),
                    DocxFormatHelper.stringValue(r.Practitioner_Name__c)
                    });
        }
        return this;
    }
    
    /**
Params: List<Healthcare_Cost__c> recs
* Sets the continuing care Healthcare Cost records used for the DOCX. Returns this DocxBuilder instance.
*/
    public DocxBuilder setContinuingCareRecords(List<Healthcare_Cost__c> recs) {
        for (Healthcare_Cost__c r : recs) {
            continuingCareRecords.add(new List<String>{
                DocxFormatHelper.stringValue(r.Description__c), DocxFormatHelper.formatCurrency(r.Cost__c)
                    });
        }
        return this;
    }
    
    /**
Params: List<Healthcare_Cost__c> recs
* Sets the future care Healthcare Cost records used for the DOCX. Returns this DocxBuilder instance.
*/
    public DocxBuilder setFutureCareRecords(List<Healthcare_Cost__c> recs) {
        for (Healthcare_Cost__c r : recs) {
            futureCareRecords.add(new List<String>{
                DocxFormatHelper.stringValue(r.Description__c), DocxFormatHelper.formatCurrency(r.Cost__c)
                    });
        }
        return this;
    }
    
    /**
Params: String name, String title
* Sets the signing authority name and title used in the DOCX. Returns this DocxBuilder instance.
*/
    public DocxBuilder setSigningAuthority(String name, String title) {
        this.signingAuthorityName = System.Label.TPL_DocGen_Default_Signing_Name;
        this.signingAuthorityTitle = System.Label.TPL_DocGen_Default_Signing_Title;
        return this;
    }
    
    /**
Params: String selectedTemplate
* Sets the selected document template type. Returns this DocxBuilder instance.
*/
    public DocxBuilder setDocumentType(String selectedTemplate) {
        this.documentType = selectedTemplate == null ? '' : selectedTemplate;
        this.isCaseHistoryCert = String.isNotBlank(this.documentType) && this.documentType.contains(System.Label.TPL_DocGen_Template_Case_History);
        this.isMinistryCert = !this.isCaseHistoryCert && (String.isBlank(this.documentType) || this.documentType.contains(System.Label.TPL_DocGen_Template_Ministers_Cert));
        return this;
    }
    
    /**
Params: Boolean flag
* Sets whether the generated DOCX should include the watermark. Returns this DocxBuilder instance.
*/
    public DocxBuilder setUseWatermark(Boolean flag) {
        this.useWatermark = (flag == true);
        return this;
    }
    
    /**
Params: Boolean flag
* Sets whether detail section headers are included. Returns this DocxBuilder instance.
*/
    public DocxBuilder setIncludeDetailSectionHeader(Boolean flag) {
        this.includeDetailSectionHeader = flag == null ? true : flag;
        return this;
    }
    
    /**
Params: Boolean flag
* Sets whether detail section totals are included. Returns this DocxBuilder instance.
*/
    public DocxBuilder setIncludeDetailSectionTotal(Boolean flag) {
        this.includeDetailSectionTotal = flag == null ? true : flag;
        return this;
    }
    
    /**
Params: Boolean flag
* Sets whether detail section labels are included. Returns this DocxBuilder instance.
*/
    public DocxBuilder setIncludeDetailSectionLabel(Boolean flag) {
        this.includeDetailSectionLabel = flag == null ? true : flag;
        return this;
    }
    
    /**
Params: Boolean flag
* Sets whether detail column headers are included. Returns this DocxBuilder instance.
*/
    public DocxBuilder setIncludeDetailColumnHeader(Boolean flag) {
        this.includeDetailColumnHeader = flag == null ? true : flag;
        return this;
    }
    
    /**
Params: String resourceName
* Sets the static resource name used for the logo. Returns this DocxBuilder instance.
*/
    public DocxBuilder setLogoStaticResourceName(String resourceName) {
        this.logoStaticResourceName = String.isBlank(resourceName) ? DocgenConstants.DEFAULT_LOGO_STATIC_RESOURCE : resourceName.trim();
        this.logoBody = null;
        this.logoLoadAttempted = false;
        return this;
    }
    
    /**
* Builds the complete DOCX package. Returns the generated DOCX Blob.
*/
    public Blob build() {
        computeDateParts();
        return buildPackage(documentUnified());
    }
    
    /**
* Builds the certificate-only DOCX package. Returns the generated DOCX Blob.
*/
    public Blob buildCertificateOnly() {
        computeDateParts();
        return buildPackage(documentCertificateOnly());
    }
    
    /**
* Builds the totals-only DOCX package. Returns the generated DOCX Blob.
*/
    public Blob buildTotalsOnly() {
        return buildPackage(documentTotalsOnly());
    }
    
    /**
* Builds the details-only DOCX package. Returns the generated DOCX Blob.
*/
    public Blob buildDetailsOnly() {
        return buildPackage(documentDetailsOnly());
    }
    
    /**
* Builds the opening XML content for the document body. Returns the generated XML.
*/
    public String buildOpeningXml() {
        computeDateParts();
        String b = certificatePageXml();
        b += sectionBreakPara();
        b += appendixTotalsXml();
        return openBody(b);
    }
    
    /**
* Builds the ambulance detail section XML. Returns the generated XML.
*/
    public String buildAmbulanceSectionXml() {
        if (ambulanceRecords.isEmpty()) return '';
        return detailSection(System.Label.TPL_DocGen_Doc_Section_Ambulance, ambulanceDetailTbl(), ambulanceTotal, System.Label.TPL_DocGen_Doc_Part_Past);
    }
    
    /**
* Builds the hospital detail section XML. Returns the generated XML.
*/
    public String buildHospitalSectionXml() {
        if (hospitalRecords.isEmpty()) return '';
        return detailSection(System.Label.TPL_DocGen_Doc_Section_Hospital, hospitalDetailTbl(), hospitalTotal, System.Label.TPL_DocGen_Doc_Part_Past);
    }
    
    /**
* Builds the MSP detail section XML. Returns the generated XML.
*/
    public String buildMedicalSectionXml() {
        if (mspRecords.isEmpty()) return '';
        return detailSection(System.Label.TPL_DocGen_Doc_Section_Medical, mspDetailTbl(), medicalTotal, System.Label.TPL_DocGen_Doc_Part_Past);
    }
    
    /**
* Builds the PharmaCare detail section XML. Returns the generated XML.
*/
    public String buildPharmacareSectionXml() {
        if (pharmaRecords.isEmpty()) return '';
        return detailSection(System.Label.TPL_DocGen_Doc_Section_Pharmacare, pharmaDetailTbl(), pharmacyTotal, System.Label.TPL_DocGen_Doc_Part_Past);
    }
    
    /**
* Builds the continuing care detail section XML. Returns the generated XML.
*/
    public String buildContinuingCareSectionXml() {
        if (continuingCareRecords.isEmpty()) return '';
        return detailSection(System.Label.TPL_DocGen_Doc_Section_Continuing_Care, ccFcDetailTbl(continuingCareRecords), continuingCareTotal, System.Label.TPL_DocGen_Doc_Part_Past);
    }
    
    /**
* Builds the future care detail section XML. Returns the generated XML.
*/
    public String buildFutureCareSectionXml() {
        if (futureCareRecords.isEmpty()) return '';
        return detailSection(System.Label.TPL_DocGen_Doc_Section_Future_Care, ccFcDetailTbl(futureCareRecords), futureCareTotal, System.Label.TPL_DocGen_Doc_Part_Future);
    }
    
    /**
* Builds XML for all detail sections. Returns the generated XML.
*/
    public String buildAllDetailSectionsXml() {
        return buildDetailSectionsXml(true);
    }
    
    /**
Params: String documentXml
* Builds the DOCX ZIP package from document XML. Returns the generated DOCX Blob.
*/
    private Blob buildPackage(String documentXml) {
        Blob logo = getLogoBody();
        String portraitFooterXml = buildPortraitFooterXml();
        String landscapeFooterXml = buildLandscapeFooterXml();
        String landscapeHeaderXml = buildLandscapeHeaderXml();
        String portraitHeaderXml = buildPortraitHeaderXml();
        
        return DocxPackageService.buildPackage(
            documentXml,
            logo,
            portraitFooterXml,
            landscapeFooterXml,
            landscapeHeaderXml,
            portraitHeaderXml
        );
    }
    
    /**
Params: String bodyXml
* Wraps body XML with the opening document XML. Returns the generated XML.
*/
    private String openBody(String bodyXml) {
        return DocgenConstants.XML_DECLARATION +
            '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">' +
            '<w:body>' + bodyXml;
    }
    
    /**
* Builds the unified document XML. Returns the generated XML.
*/
    private String documentUnified() {
        String b = '';
        if (isMinistryCert) {
            b += certificatePageXml();
            b += sectionBreakPara();
        }
        b += appendixTotalsXml();
        b += buildDetailSectionsXml(true);
        b += landscapeSectPr();
        return wrapBody(b);
    }
    
    /**
* Builds the certificate-only document XML. Returns the generated XML.
*/
    private String documentCertificateOnly() {
        String b = certificatePageXml();
        b += portraitSectPr();
        return wrapBody(b);
    }
    
    /**
* Builds the totals-only document XML. Returns the generated XML.
*/
    private String documentTotalsOnly() {
        String b = appendixTotalsXml();
        b += landscapeSectPr();
        return wrapBody(b);
    }
    
    /**
* Builds the details-only document XML. Returns the generated XML.
*/
    private String documentDetailsOnly() {
        String b = buildDetailSectionsXml(false);
        b += landscapeSectPr();
        return wrapBody(b);
    }
    
    /**
Params: Boolean includeInitialPageBreak
* Builds the selected detail sections XML. Returns the generated XML.
*/
    private String buildDetailSectionsXml(Boolean includeInitialPageBreak) {
        String b = '';
        if (!ambulanceRecords.isEmpty()) {
            b += detailSection(System.Label.TPL_DocGen_Doc_Section_Ambulance, ambulanceDetailTbl(), ambulanceTotal, System.Label.TPL_DocGen_Doc_Part_Past, includeInitialPageBreak);
        }
        if (!hospitalRecords.isEmpty()) {
            b += detailSection(System.Label.TPL_DocGen_Doc_Section_Hospital, hospitalDetailTbl(), hospitalTotal, System.Label.TPL_DocGen_Doc_Part_Past, includeInitialPageBreak);
        }
        if (!mspRecords.isEmpty()) {
            b += detailSection(System.Label.TPL_DocGen_Doc_Section_Medical, mspDetailTbl(), medicalTotal, System.Label.TPL_DocGen_Doc_Part_Past, includeInitialPageBreak);
        }
        if (!pharmaRecords.isEmpty()) {
            b += detailSection(System.Label.TPL_DocGen_Doc_Section_Pharmacare, pharmaDetailTbl(), pharmacyTotal, System.Label.TPL_DocGen_Doc_Part_Past, includeInitialPageBreak);
        }
        if (!continuingCareRecords.isEmpty()) {
            b += detailSection(System.Label.TPL_DocGen_Doc_Section_Continuing_Care, ccFcDetailTbl(continuingCareRecords), continuingCareTotal, System.Label.TPL_DocGen_Doc_Part_Past, includeInitialPageBreak);
        }
        if (!futureCareRecords.isEmpty()) {
            b += detailSection(System.Label.TPL_DocGen_Doc_Section_Future_Care, ccFcDetailTbl(futureCareRecords), futureCareTotal, System.Label.TPL_DocGen_Doc_Part_Future, includeInitialPageBreak);
        }
        return b;
    }
    
    /**
Params: String bodyXml
* Wraps body XML with document body and section properties. Returns the generated XML.
*/
    private String wrapBody(String bodyXml) {
        return DocgenConstants.XML_DECLARATION +
            '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">' +
            '<w:body>' + bodyXml + '</w:body></w:document>';
    }
    
    /**
* Builds the certificate page XML. Returns the generated XML.
*/
    private String certificatePageXml() {
        String b = '';
        b += '<w:p><w:pPr><w:pStyle w:val="Header"/><w:jc w:val="center"/></w:pPr></w:p>';
        b += logoPara();
        b += '<w:p><w:pPr><w:jc w:val="right"/></w:pPr>' +
            formatFont(System.Label.TPL_DocGen_Doc_Label_Case_Number + ' ', DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS, true, false, DocgenConstants.ARIAL_FONT_NAME) +
            formatFont(DocxXmlRenderService.escXml(caseNumber), DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS, false, false, DocgenConstants.ARIAL_FONT_NAME) +
            '</w:p>';
        b += '<w:p><w:pPr><w:jc w:val="center"/></w:pPr>' +
            formatFont(System.Label.TPL_DocGen_Doc_Title_Ministers_Certificate, DocgenConstants.TITLE_TEXT_SIZE_HALF_POINTS, true, false, DocgenConstants.ARIAL_FONT_NAME) +
            '</w:p>';
        b += blankP();
        b += '<w:p>' +
            formatFont(System.Label.TPL_DocGen_Doc_Cert_Whereas_Prefix + ' ', DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS, false, false, DocgenConstants.TIMES_NEW_ROMAN_FONT_NAME) +
            formatFont(System.Label.TPL_DocGen_Doc_Cert_Act_Name, DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS, false, true, DocgenConstants.TIMES_NEW_ROMAN_FONT_NAME) +
            formatFont(System.Label.TPL_DocGen_Doc_Cert_Whereas_Suffix, DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS, false, false, DocgenConstants.TIMES_NEW_ROMAN_FONT_NAME) +
            '</w:p>';
        b += blankP();
        b += '<w:p><w:pPr><w:ind w:left="720" w:hanging="360"/><w:tabs><w:tab w:val="num" w:pos="720"/></w:tabs></w:pPr>' +
            formatFont(System.Label.TPL_DocGen_Doc_Cert_Item_A, DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS, false, false, DocgenConstants.TIMES_NEW_ROMAN_FONT_NAME) +
            '</w:p>';
        b += '<w:p><w:pPr><w:ind w:left="360"/></w:pPr></w:p>';
        b += '<w:p><w:pPr><w:ind w:left="720" w:hanging="360"/><w:tabs><w:tab w:val="num" w:pos="720"/></w:tabs></w:pPr>' +
            formatFont(System.Label.TPL_DocGen_Doc_Cert_Item_B, DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS, false, false, DocgenConstants.TIMES_NEW_ROMAN_FONT_NAME) +
            '</w:p>';
        b += blankP();
        b += '<w:p>' +
            formatFont(System.Label.TPL_DocGen_Doc_Cert_Therefore_Prefix + ' ', DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS, false, false, DocgenConstants.TIMES_NEW_ROMAN_FONT_NAME) +
            formatFont(DocxXmlRenderService.escXml(signingAuthorityName), DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS, false, false, DocgenConstants.TIMES_NEW_ROMAN_FONT_NAME) +
            formatFont(System.Label.TPL_DocGen_Doc_Cert_Therefore_Claim + ' ', DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS, false, false, DocgenConstants.TIMES_NEW_ROMAN_FONT_NAME) +
            formatFont(DocxXmlRenderService.escXml(contactName), DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS, true, false, DocgenConstants.ARIAL_FONT_NAME) +
            formatFont(System.Label.TPL_DocGen_Doc_Cert_PHN_Prefix + ' ', DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS, false, false, DocgenConstants.TIMES_NEW_ROMAN_FONT_NAME) +
            formatFont(DocxXmlRenderService.escXml(phn), DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS, true, false, DocgenConstants.ARIAL_FONT_NAME) +
            formatFont(System.Label.TPL_DocGen_Doc_Cert_Incident_Prefix + ' ', DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS, false, false, DocgenConstants.TIMES_NEW_ROMAN_FONT_NAME) +
            formatFont(DocxXmlRenderService.escXml(incidentDate), DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS, true, false, DocgenConstants.TIMES_NEW_ROMAN_FONT_NAME) +
            formatFont('.', DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS, false, false, DocgenConstants.TIMES_NEW_ROMAN_FONT_NAME) +
            '</w:p>';
        b += blankP();
        b += '<w:p>' +
            formatFont(System.Label.TPL_DocGen_Doc_Cert_Total_Past_Costs_Prefix + ' ', DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS, false, false, DocgenConstants.TIMES_NEW_ROMAN_FONT_NAME) +
            formatFont(DocxXmlRenderService.escXml(totalCost), DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS, true, false, DocgenConstants.TIMES_NEW_ROMAN_FONT_NAME) +
            formatFont('.', DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS, false, false, DocgenConstants.TIMES_NEW_ROMAN_FONT_NAME);
        b += '</w:p>';
        b += blankP();
        b += '<w:p>' +
            formatFont(System.Label.TPL_DocGen_Doc_Cert_Dated_Prefix, DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS, false, false, DocgenConstants.TIMES_NEW_ROMAN_FONT_NAME) +
            formatFont(' ' + day + daySubscript + ' ', DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS, false, false, DocgenConstants.TIMES_NEW_ROMAN_FONT_NAME) +
            formatFont(System.Label.TPL_DocGen_Doc_Cert_Day_Of + ' ', DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS, false, false, DocgenConstants.TIMES_NEW_ROMAN_FONT_NAME) +
            formatFont(month, DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS, false, false, DocgenConstants.TIMES_NEW_ROMAN_FONT_NAME) +
            formatFont(', ', DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS, false, false, DocgenConstants.TIMES_NEW_ROMAN_FONT_NAME) +
            formatFont(year + '.', DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS, false, false, DocgenConstants.TIMES_NEW_ROMAN_FONT_NAME) +
            '</w:p>';
        b += '<w:p>' + formatFont(' ', DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS, false, false, DocgenConstants.TIMES_NEW_ROMAN_FONT_NAME) + '</w:p>';
        b += blankP(); b += blankP();  b += blankP();
        b += signatureRulePara();
        b += sigPara(DocxXmlRenderService.escXml(signingAuthorityName));
        b += sigPara(DocxXmlRenderService.escXml(signingAuthorityTitle));
        b += sigPara(System.Label.TPL_DocGen_Doc_Label_Designate_On_Behalf_Of);
        b += sigPara(System.Label.TPL_DocGen_Doc_Label_Minister_Of_Health);
        for (Integer i = 0; i < 4; i++) {
            b += '<w:p><w:pPr><w:jc w:val="right"/><w:ind w:left="4320" w:firstLine="720"/></w:pPr></w:p>';
        }
        return b;
    }
    
    /**
* Builds the signature rule paragraph XML. Returns the generated XML.
*/
    private String signatureRulePara() {
        return '<w:p><w:pPr><w:jc w:val="right"/></w:pPr>'
            + '<w:r><w:rPr>'
            + '<w:rFonts w:ascii="' + DocgenConstants.TIMES_NEW_ROMAN_FONT_NAME + '" w:hAnsi="' + DocgenConstants.TIMES_NEW_ROMAN_FONT_NAME + '" w:cs="' + DocgenConstants.TIMES_NEW_ROMAN_FONT_NAME + '"/>'
            + '<w:sz w:val="' + DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS + '"/><w:szCs w:val="' + DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS + '"/>'
            + '</w:rPr><w:tab/><w:tab/><w:tab/><w:tab/><w:tab/><w:tab/><w:tab/></w:r>'
            + '<w:r><w:rPr>'
            + '<w:rFonts w:ascii="' + DocgenConstants.TIMES_NEW_ROMAN_FONT_NAME + '" w:hAnsi="' + DocgenConstants.TIMES_NEW_ROMAN_FONT_NAME + '" w:cs="' + DocgenConstants.TIMES_NEW_ROMAN_FONT_NAME + '"/>'
            + '<w:sz w:val="' + DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS + '"/><w:szCs w:val="' + DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS + '"/>'
            + '<w:u w:val="single"/></w:rPr>'
            + '<w:tab/><w:tab/><w:tab/><w:tab/><w:tab/></w:r></w:p>';
    }
    
    /**
* Builds the appendix totals XML. Returns the generated XML.
*/
    private String appendixTotalsXml() {
        String b = '';
        b += '<w:p><w:pPr><w:jc w:val="center"/></w:pPr>' +
            formatFont(System.Label.TPL_DocGen_Doc_Title_Appendix_A, DocgenConstants.TITLE_TEXT_SIZE_HALF_POINTS, true, false, DocgenConstants.ARIAL_FONT_NAME) + '</w:p>';
        b += '<w:p><w:pPr><w:pStyle w:val="Header"/><w:jc w:val="center"/></w:pPr>' +
            formatFont(System.Label.TPL_DocGen_Doc_Title_Healthcare_Services_Claim, DocgenConstants.TITLE_TEXT_SIZE_HALF_POINTS, true, false, DocgenConstants.ARIAL_FONT_NAME) + '</w:p>';
        b += '<w:p><w:pPr><w:pStyle w:val="Header"/><w:jc w:val="center"/></w:pPr></w:p>';
        if (isMinistryCert) {
            b += '<w:p><w:pPr><w:pStyle w:val="Header"/><w:jc w:val="center"/></w:pPr></w:p>';
        }
        b += caseHeaderTbl(DocgenConstants.CASE_APPENDIX_TABLE_COLUMN_WIDTHS);
        b += '<w:p><w:pPr><w:pStyle w:val="Header"/></w:pPr></w:p>';
        b += '<w:p><w:pPr><w:pStyle w:val="Header"/></w:pPr></w:p>';
        b += '<w:p><w:pPr><w:pStyle w:val="Header"/></w:pPr></w:p>';
        b += pastCostsTbl();
        b += '<w:p><w:pPr><w:pStyle w:val="Header"/></w:pPr></w:p>';
        b += futureCostsTbl();
        b += '<w:p><w:pPr><w:pStyle w:val="Header"/></w:pPr></w:p>';
        if (isCaseHistory()) {
            b += '<w:p><w:pPr>' +
                '<w:jc w:val="right"/>' +
                '<w:spacing w:before="460"/>' +
                '</w:pPr>' +
                formatFont(System.Label.TPL_DocGen_Doc_Label_Date_Printed + ' ', DocgenConstants.DOCX_TABLE_COLUMN_WIDTH_COUNT, true, false, DocgenConstants.ARIAL_FONT_NAME) +
                formatFont(month + ' ' + day + ', ' + year, DocgenConstants.DOCX_TABLE_COLUMN_WIDTH_COUNT, false, false, DocgenConstants.ARIAL_FONT_NAME) +
                '</w:p>';
        }
        return b;
    }
    
    /**
Params: String label, String detailTbl, String total, String part
* Builds a detail section XML block. Returns the generated XML.
*/
    private String detailSection(String label, String detailTbl, String total, String part) {
        return detailSection(label, detailTbl, total, part, true);
    }
    
    /**
Params: String label, String detailTbl, String total, String part, Boolean includeInitialPageBreak
* Builds a detail section XML block. Returns the generated XML.
*/
    private String detailSection(String label, String detailTbl, String total, String part, Boolean includeInitialPageBreak) {
        String s = '';
        if (includeInitialPageBreak) {
            s += '<w:p><w:r><w:br w:type="page"/></w:r></w:p>';
        }
        
        if (includeDetailSectionHeader) {
            s += '<w:p><w:pPr><w:pStyle w:val="Header"/><w:jc w:val="center"/></w:pPr>' +
                formatFont(System.Label.TPL_DocGen_Doc_Title_Healthcare_Services_Costs_Record + ' ' + part, DocgenConstants.TITLE_TEXT_SIZE_HALF_POINTS, true, false, DocgenConstants.ARIAL_FONT_NAME) +
                '</w:p>';
            s += '<w:p><w:pPr><w:pStyle w:val="Header"/></w:pPr></w:p>';
            s += caseHeaderTblDetail();
            s += '<w:p><w:pPr><w:jc w:val="center"/><w:spacing w:before="220" w:after="220"/></w:pPr></w:p>';
        }
        
        if (includeDetailSectionLabel) {
            s += '<w:p><w:pPr><w:spacing w:before="80"/></w:pPr>' +
                formatFont(label, DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS, true, false, DocgenConstants.ARIAL_FONT_NAME) +    // sz=0 = inherit (no explicit sz in template)
                '</w:p>';
            
            s += blankP();
        }
        s += detailTbl;
        
        s += blankP();
        
        if (includeDetailSectionTotal) {
            String totalLabel = label == System.Label.TPL_DocGen_Doc_Section_Medical ? System.Label.TPL_DocGen_Doc_Section_MSP : label;
            String totalLine = '<w:p>' +
                formatFont(System.Label.TPL_DocGen_Doc_Total_Prefix + ' ' + totalLabel, DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS, true, false, DocgenConstants.ARIAL_FONT_NAME) +
                formatFont('   ', 0, true, false, DocgenConstants.ARIAL_FONT_NAME) + 
                formatFont(DocxXmlRenderService.escXml(total), DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS, false, false, DocgenConstants.ARIAL_FONT_NAME) +
                '</w:p>';
            s += totalLine;
        }
        
        if (isCaseHistory()) {
            s += '<w:p/>';
            s += '<w:p>' + formatFont(System.Label.TPL_DocGen_Doc_CH_Section_16_1, DocgenConstants.DOCX_TABLE_TEXT_SIZE_HALF_POINTS, false, true, DocgenConstants.ARIAL_FONT_NAME) + '</w:p>';
            s += '<w:p>' + formatFont(System.Label.TPL_DocGen_Doc_CH_Section_16_2, DocgenConstants.DOCX_TABLE_TEXT_SIZE_HALF_POINTS, false, true, DocgenConstants.ARIAL_FONT_NAME) + '</w:p>';
        }
        
        return s;
    }
    
    /**
* Builds the detail case header table XML. Returns the generated XML.
*/
    private String caseHeaderTblDetail() {
        List<Integer> cols = DocgenConstants.CASE_DETAIL_TABLE_COLUMN_WIDTHS;
        String grid = caseHeaderGrid(cols);
        return '<w:tbl>' +
            '<w:tblPr><w:tblW w:w="13050" w:type="dxa"/>' +
            '<w:tblLook w:val="04A0" w:firstRow="1" w:lastRow="0" w:firstColumn="1" w:lastColumn="0" w:noHBand="0" w:noVBand="1"/></w:tblPr>' +
            '<w:tblGrid>' + grid + '</w:tblGrid>' +
            caseHeaderRows(cols) + '</w:tbl>';
    }
    
    /**
Params: List<Integer> cols
* Builds the case header table XML. Returns the generated XML.
*/
    private String caseHeaderTbl(List<Integer> cols) {
        String grid = caseHeaderGrid(cols);
        return '<w:tbl>' +
            '<w:tblPr><w:tblW w:w="0" w:type="auto"/>' +
            '<w:tblLook w:val="04A0" w:firstRow="1" w:lastRow="0" w:firstColumn="1" w:lastColumn="0" w:noHBand="0" w:noVBand="1"/></w:tblPr>' +
            '<w:tblGrid>' + grid + '</w:tblGrid>' +
            caseHeaderRows(cols) + '</w:tbl>';
    }
    
    /**
Params: List<Integer> cols
* Builds the case header table rows XML. Returns the generated XML.
*/
    private String caseHeaderRows(List<Integer> cols) {
        return formatTableRow(
            tcAuto('', cols[0], false) +
            tcAuto('', cols[1], false) +
            tcAutoLabelValue(System.Label.TPL_DocGen_Doc_Label_Case_Number + ' ', DocxXmlRenderService.escXml(caseNumber), cols[2]),
            false
            , false) +
            formatTableRow(
                tcAutoLabelValue(System.Label.TPL_DocGen_Doc_Label_Name +' ', DocxXmlRenderService.escXml(contactName), cols[0]) +
                tcAuto('', cols[1], false) +
                tcAutoLabelValue(System.Label.TPL_DocGen_Doc_Label_MV_Claim_Number + ' ', DocxXmlRenderService.escXml(claimNumber), cols[2]),
                false
                , false) +
            formatTableRow(
                tcAutoLabelValue(System.Label.TPL_DocGen_Doc_Label_Incident_Date + ' ', DocxXmlRenderService.escXml(incidentDate), cols[0]) +
                tcAutoLabelValue(System.Label.TPL_DocGen_Doc_Label_PHN + ' ', DocxXmlRenderService.escXml(phn), cols[1]) +
                tcAutoLabelValue(System.Label.TPL_DocGen_Doc_Label_Birth_Date + ' ', DocxXmlRenderService.escXml(birthDate), cols[2]),
                false
                , false);
    }
    
    /**
Params: List<Integer> cols
* Builds the case header table grid XML. Returns the generated XML.
*/
    private String caseHeaderGrid(List<Integer> cols) {
        String grid = '';
        for (Integer w : cols) { grid += '<w:gridCol w:w="' + w + '"/>'; }
        return grid;
    }
    
    /**
* Builds the past costs totals table XML. Returns the generated XML.
*/
    private String pastCostsTbl() {
        List<Integer> cols = DocgenConstants.PAST_AND_FUTURE_CARE_TABLE_COLUMN_WIDTHS;
        String rows =
            formatTableRow(formatFixedWidthTableCell(System.Label.TPL_DocGen_Doc_Label_Past_Costs, cols[0], true, DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS) +
                           formatFixedWidthTableCell('', cols[1], true, DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS), true, false) +
            formatTableRow(formatFixedWidthTableCell(System.Label.TPL_DocGen_Doc_Section_Ambulance, cols[0], false, DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS) + formatFixedWidthTableCell(ambulanceTotal, cols[1], false, DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS), false, false) +
            formatTableRow(formatFixedWidthTableCell(System.Label.TPL_DocGen_Doc_Section_Hospital, cols[0], false, DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS) + formatFixedWidthTableCell(hospitalTotal, cols[1], false, DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS), false, false) +
            formatTableRow(formatFixedWidthTableCell(System.Label.TPL_DocGen_Doc_Section_Medical, cols[0], false, DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS) + formatFixedWidthTableCell(medicalTotal, cols[1], false, DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS), false, false) +
            formatTableRow(formatFixedWidthTableCell(System.Label.TPL_DocGen_Doc_Section_Pharmacy, cols[0], false, DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS) + formatFixedWidthTableCell(pharmacyTotal, cols[1], false, DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS), false, false) +
            formatTableRow(formatFixedWidthTableCell(System.Label.TPL_DocGen_Doc_Section_Continuing_Care, cols[0], false, DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS) + formatFixedWidthTableCell(continuingCareTotal, cols[1], false, DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS), false, false) +
            formatTableRow(formatFixedWidthTableCell('', cols[0], true, DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS) + formatFixedWidthTableCell('___________', cols[1], true, DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS), false, false) +
            formatTableRow(formatFixedWidthTableCell(System.Label.TPL_DocGen_Doc_Label_Total_Past_Cost, cols[0], true, DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS) +
                           formatFixedWidthTableCell(pastServicesTotal, cols[1], true, DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS), false, false);
        
        return tblGrid(rows, cols);
    }
    
    /**
* Builds the future costs totals table XML. Returns the generated XML.
*/
    private String futureCostsTbl() {
        List<Integer> cols = DocgenConstants.PAST_AND_FUTURE_CARE_TABLE_COLUMN_WIDTHS;
        String rows =
            formatTableRow(formatFixedWidthTableCell(System.Label.TPL_DocGen_Doc_Label_Future_Costs, cols[0], true, DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS) +
                           formatFixedWidthTableCell('', cols[1], true, DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS), true, false) +
            formatTableRow(formatFixedWidthTableCell(System.Label.TPL_DocGen_Doc_Section_Future_Care, cols[0], false, DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS) + formatFixedWidthTableCell(futureCareTotal, cols[1], false, DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS), false, false) +
            formatTableRow(tcGridItalicAct(cols[0]) +
                           formatFixedWidthTableCell('-' + discountFutureCare, cols[1], false, DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS), false, false) +
            formatTableRow(formatFixedWidthTableCell('', cols[0], true, DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS) + formatFixedWidthTableCell('____________', cols[1], true, DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS), false, false) +
            formatTableRow(formatFixedWidthTableCell(System.Label.TPL_DocGen_Doc_Label_Total_Future_Cost, cols[0], true, DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS) +
                           formatFixedWidthTableCell(futureServicesTotal, cols[1], true, DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS), false, false) +
            formatTableRow(formatFixedWidthTableCell('', cols[0], false, DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS) + formatFixedWidthTableCell('', cols[1], false, DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS), false, false) +
            formatTableRow(formatFixedWidthTableCell('', cols[0], false, DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS) + formatFixedWidthTableCell('', cols[1], false, DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS), false, false) +
            formatTableRow(formatFixedWidthTableCell(System.Label.TPL_DocGen_Doc_Label_Present_Value_Total_Claim, cols[0], true, DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS) +
                           formatFixedWidthTableCell(totalCost, cols[1], true, DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS), false, false);
        
        return tblGrid(rows, cols);
    }
    
    /**
* Builds the ambulance detail table XML. Returns the generated XML.
*/
    private String ambulanceDetailTbl() {
        List<Integer> cols = DocgenConstants.AMBULANCE_TABLE_COLUMN_WIDTHS;
        String rows = '';
        TableDataConfiguration leftTop = tableDataConfiguration(DocgenConstants.TABLE_HORIZONTAL_ALIGN_LEFT, DocgenConstants.DOCX_TABLE_COLUMN_WIDTH_COUNT, DocgenConstants.TABLE_VERTICAL_ALIGN_TOP);
        TableDataConfiguration rightTop = tableDataConfiguration(DocgenConstants.TABLE_HORIZONTAL_ALIGN_RIGHT, DocgenConstants.DOCX_TABLE_COLUMN_WIDTH_COUNT, DocgenConstants.TABLE_VERTICAL_ALIGN_TOP);
        TableDataConfiguration defaultTop = tableDataConfiguration(null, DocgenConstants.DOCX_TABLE_COLUMN_WIDTH_COUNT, DocgenConstants.TABLE_VERTICAL_ALIGN_TOP);
        if (includeDetailColumnHeader) {
            rows += formatTableRow(
                tcDetail(System.Label.TPL_DocGen_Doc_Col_Service_Date, cols[0], true, leftTop) + tcDetail(System.Label.TPL_DocGen_Doc_Col_Originating_Point, cols[1], true, leftTop) +
                tcDetail(System.Label.TPL_DocGen_Doc_Col_Destination,  cols[2], true, leftTop) + tcDetail(System.Label.TPL_DocGen_Doc_Col_Cost,              cols[3], true, rightTop), false, false);
        }
        for (List<String> row : ambulanceRecords) {
            rows += formatTableRow(
                tcDetail(row[0], cols[0], false, defaultTop) + tcDetail(row[1], cols[1], false, defaultTop) +
                tcDetail(row[2], cols[2], false, defaultTop) + tcDetail(row[3], cols[3], false, defaultTop), false, true);
        }
        return tblDetail(rows, cols, 12322);
    }
    
    /**
* Builds the hospital detail table XML. Returns the generated XML.
*/
    private String hospitalDetailTbl() {
        List<Integer> cols = DocgenConstants.HOSPITAL_TABLE_COLUMN_WIDTHS;
        String rows = '';
        TableDataConfiguration leftTop = tableDataConfiguration(DocgenConstants.TABLE_HORIZONTAL_ALIGN_LEFT, DocgenConstants.DOCX_TABLE_COLUMN_WIDTH_COUNT, DocgenConstants.TABLE_VERTICAL_ALIGN_TOP);
        TableDataConfiguration rightTop = tableDataConfiguration(DocgenConstants.TABLE_HORIZONTAL_ALIGN_RIGHT, DocgenConstants.DOCX_TABLE_COLUMN_WIDTH_COUNT, DocgenConstants.TABLE_VERTICAL_ALIGN_TOP);
        TableDataConfiguration leftCenter = tableDataConfiguration(DocgenConstants.TABLE_HORIZONTAL_ALIGN_LEFT, DocgenConstants.DOCX_TABLE_COLUMN_WIDTH_COUNT, DocgenConstants.TABLE_VERTICAL_ALIGN_CENTER);
        TableDataConfiguration rightCenter = tableDataConfiguration(DocgenConstants.TABLE_HORIZONTAL_ALIGN_RIGHT, DocgenConstants.DOCX_TABLE_COLUMN_WIDTH_COUNT, DocgenConstants.TABLE_VERTICAL_ALIGN_CENTER);
        if (includeDetailColumnHeader) {
            rows += formatTableRow(
                tcDetail(System.Label.TPL_DocGen_Doc_Col_Admit,        cols[0], true, leftTop) + tcDetail(System.Label.TPL_DocGen_Doc_Col_Discharge,    cols[1], true, leftTop) +
                tcDetail(System.Label.TPL_DocGen_Doc_Col_Facility,     cols[2], true, leftTop) + tcDetail(System.Label.TPL_DocGen_Doc_Col_Service_Type, cols[3], true, leftTop) +
                tcDetail(System.Label.TPL_DocGen_Doc_Col_Days,         cols[4], true, leftTop) + tcDetail(System.Label.TPL_DocGen_Doc_Col_Cost,         cols[5], true, rightTop), false, false);
        }
        for (List<String> row : hospitalRecords) {
            rows += formatTableRow(
                tcDetail(row[0], cols[0], false, leftCenter) + tcDetail(row[1], cols[1], false, leftCenter) +
                tcDetail(row[2], cols[2], false, leftTop) + tcDetail(row[3], cols[3], false, leftCenter) +
                tcDetail(row[4], cols[4], false, leftCenter) + tcDetail(row[5], cols[5], false, rightCenter), false, true);
        }
        return tblDetail(rows, cols, 12412);
    }
    
    /**
* Builds the MSP detail table XML. Returns the generated XML.
*/
    private String mspDetailTbl() {
        List<Integer> cols = DocgenConstants.MSP_TABLE_COLUMN_WIDTHS;
        String rows = '';
        TableDataConfiguration leftTop = tableDataConfiguration(DocgenConstants.TABLE_HORIZONTAL_ALIGN_LEFT, DocgenConstants.DOCX_TABLE_COLUMN_WIDTH_COUNT, DocgenConstants.TABLE_VERTICAL_ALIGN_TOP);
        TableDataConfiguration rightTop = tableDataConfiguration(DocgenConstants.TABLE_HORIZONTAL_ALIGN_RIGHT, DocgenConstants.DOCX_TABLE_COLUMN_WIDTH_COUNT, DocgenConstants.TABLE_VERTICAL_ALIGN_TOP);
        TableDataConfiguration leftCenter = tableDataConfiguration(DocgenConstants.TABLE_HORIZONTAL_ALIGN_LEFT, DocgenConstants.DOCX_TABLE_COLUMN_WIDTH_COUNT, DocgenConstants.TABLE_VERTICAL_ALIGN_CENTER);
        TableDataConfiguration rightCenter = tableDataConfiguration(DocgenConstants.TABLE_HORIZONTAL_ALIGN_RIGHT, DocgenConstants.DOCX_TABLE_COLUMN_WIDTH_COUNT, DocgenConstants.TABLE_VERTICAL_ALIGN_CENTER);
        if (includeDetailColumnHeader) {
            rows += formatTableRow(
                tcDetail(System.Label.TPL_DocGen_Doc_Col_Service_Date,      cols[0], true, leftTop) + tcDetail(System.Label.TPL_DocGen_Doc_Col_Location_Type, cols[1], true, leftTop) +
                tcDetail(System.Label.TPL_DocGen_Doc_Col_Service,           cols[2], true, leftTop) + tcDetail(System.Label.TPL_DocGen_Doc_Col_Fee_Item,      cols[3], true, leftTop) +
                tcDetail(System.Label.TPL_DocGen_Doc_Col_Diagnostic,        cols[4], true, leftTop) + tcDetail(System.Label.TPL_DocGen_Doc_Col_Cost,          cols[5], true, rightTop) +
                tcDetail(System.Label.TPL_DocGen_Doc_Col_Practitioner_Name, cols[6], true, leftTop), false, false);
        }
        for (List<String> row : mspRecords) {
            rows += formatTableRow(
                tcDetail(row[0], cols[0], false, leftCenter) + tcDetail(row[1], cols[1], false, leftCenter) +
                tcDetail(row[2], cols[2], false, leftCenter) + tcDetail(row[3], cols[3], false, leftCenter) +
                tcDetail(row[4], cols[4], false, leftCenter) + tcDetail(row[5], cols[5], false, rightCenter) +
                tcDetail(row[6], cols[6], false, leftCenter), false, true);
        }
        return tblDetail(rows, cols, 13222);
    }
    
    /**
* Builds the PharmaCare detail table XML. Returns the generated XML.
*/
    private String pharmaDetailTbl() {
        List<Integer> cols = DocgenConstants.PHARMACARE_TABLE_COLUMN_WIDTHS;
        String rows = '';
        TableDataConfiguration leftTop = tableDataConfiguration(DocgenConstants.TABLE_HORIZONTAL_ALIGN_LEFT, DocgenConstants.DOCX_TABLE_COLUMN_WIDTH_COUNT, DocgenConstants.TABLE_VERTICAL_ALIGN_TOP);
        TableDataConfiguration rightTop = tableDataConfiguration(DocgenConstants.TABLE_HORIZONTAL_ALIGN_RIGHT, DocgenConstants.DOCX_TABLE_COLUMN_WIDTH_COUNT, DocgenConstants.TABLE_VERTICAL_ALIGN_TOP);
        if (includeDetailColumnHeader) {
            rows += formatTableRow(
                tcDetail(System.Label.TPL_DocGen_Doc_Col_Service_Date, cols[0], true, leftTop) + tcDetail(System.Label.TPL_DocGen_Doc_Col_Description,             cols[1], true, leftTop) +
                tcDetail(System.Label.TPL_DocGen_Doc_Col_Cost,         cols[2], true, rightTop) + tcDetail(System.Label.TPL_DocGen_Doc_Col_Prescribing_Practitioner, cols[3], true, leftTop), false, false);
        }
        for (List<String> row : pharmaRecords) {
            rows += formatTableRow(
                tcDetail(row[0], cols[0], false, leftTop) + tcDetail(row[1], cols[1], false, leftTop) +
                tcDetail(row[2], cols[2], false, rightTop) + tcDetail(row[3], cols[3], false, leftTop), false, true);
        }
        return tblDetail(rows, cols, 13402);
    }
    
    /**
Params: List<List<String>> records
* Builds the continuing/future care detail table XML. Returns the generated XML.
*/
    private String ccFcDetailTbl(List<List<String>> records) {
        List<Integer> cols = DocgenConstants.CONTINUING_AND_FUTURE_CARE_TABLE_COLUMN_WIDTHS;
        String rows = '';
        TableDataConfiguration leftTop = tableDataConfiguration(DocgenConstants.TABLE_HORIZONTAL_ALIGN_LEFT, DocgenConstants.DOCX_TABLE_COLUMN_WIDTH_COUNT, DocgenConstants.TABLE_VERTICAL_ALIGN_TOP);
        TableDataConfiguration rightTop = tableDataConfiguration(DocgenConstants.TABLE_HORIZONTAL_ALIGN_RIGHT, DocgenConstants.DOCX_TABLE_COLUMN_WIDTH_COUNT, DocgenConstants.TABLE_VERTICAL_ALIGN_TOP);
        TableDataConfiguration defaultTop = tableDataConfiguration(null, DocgenConstants.DOCX_TABLE_COLUMN_WIDTH_COUNT, DocgenConstants.TABLE_VERTICAL_ALIGN_TOP);
        if (includeDetailColumnHeader) {
            rows += formatTableRow(
                tcDetail(System.Label.TPL_DocGen_Doc_Col_Description, cols[0], true, leftTop) + tcDetail(System.Label.TPL_DocGen_Doc_Col_Cost, cols[1], true, rightTop), false, false);
        }
        for (List<String> row : records) {
            rows += formatTableRow(
                tcDetail(row[0], cols[0], false, defaultTop) +
                tcDetail(row[1], cols[1], false, defaultTop), false, true);
        }
        return tblDetail(rows, cols, 12592);
    }
    
    /**
* Loads the configured logo static resource body. Returns the logo Blob, or null when unavailable.
*/
    private Blob getLogoBody() {
        if (logoLoadAttempted) {
            return logoBody;
        }
        logoLoadAttempted = true;
        if (String.isBlank(logoStaticResourceName)) {
            return null;
        }
        List<StaticResource> resources = [
            SELECT Body
            FROM StaticResource
            WHERE Name = :logoStaticResourceName
            LIMIT 1
        ];
        logoBody = resources.isEmpty() ? null : resources[0].Body;
        return logoBody;
    }
    
    /**
* Builds the logo paragraph XML. Returns the generated XML.
*/
    private String logoPara() {
        if (getLogoBody() == null) {
            return '';
        }
        return '<w:p><w:pPr><w:pStyle w:val="Header"/><w:jc w:val="center"/><w:outlineLvl w:val="0"/></w:pPr>' +
            '<w:r><w:rPr><w:noProof/></w:rPr>' +
            '<w:drawing xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:wp14="http://schemas.microsoft.com/office/word/2010/wordprocessingDrawing" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture" xmlns:a14="http://schemas.microsoft.com/office/drawing/2010/main">' +
            '<wp:inline distT="0" distB="0" distL="0" distR="0" wp14:anchorId="618F1C69" wp14:editId="4A41D371">' +
            '<wp:extent cx="1714500" cy="647700"/><wp:effectExtent l="0" t="0" r="0" b="0"/>' +
            '<wp:docPr id="16" name="Picture 16" descr="BC Ministry of Health logo"/>' +
            '<wp:cNvGraphicFramePr><a:graphicFrameLocks noChangeAspect="1"/></wp:cNvGraphicFramePr>' +
            '<a:graphic><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">' +
            '<pic:pic><pic:nvPicPr><pic:cNvPr id="16" name="Picture 16" descr="BC Ministry of Health logo"/>' +
            '<pic:cNvPicPr><a:picLocks noChangeAspect="1" noChangeArrowheads="1"/></pic:cNvPicPr></pic:nvPicPr>' +
            '<pic:blipFill><a:blip r:embed="rId6" cstate="print"><a:grayscl/><a:extLst><a:ext uri="{28A0092B-C50C-407E-A947-70E740481C1C}"><a14:useLocalDpi val="0"/></a:ext></a:extLst></a:blip><a:srcRect/><a:stretch><a:fillRect/></a:stretch></pic:blipFill>' +
            '<pic:spPr bwMode="auto"><a:xfrm><a:off x="0" y="0"/><a:ext cx="1714500" cy="647700"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom><a:noFill/><a:ln><a:noFill/></a:ln></pic:spPr>' +
            '</pic:pic></a:graphicData></a:graphic></wp:inline></w:drawing></w:r></w:p>';
    }
    
    /**
* Builds the portrait footer XML. Returns the generated XML.
*/
    private String buildPortraitFooterXml() {
        return DocgenConstants.XML_DECLARATION +
            '<w:ftr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">' +
            '<w:p><w:pPr><w:pStyle w:val="Footer"/></w:pPr></w:p>' +
            '</w:ftr>';
    }
    
    /**
* Builds the landscape footer XML. Returns the generated XML.
*/
    private String buildLandscapeFooterXml() {
        return DocgenConstants.XML_DECLARATION +
            '<w:ftr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">' +
            '<w:p><w:pPr><w:pStyle w:val="Footer"/><w:jc w:val="center"/></w:pPr>' +
            '<w:r><w:rPr><w:rFonts w:ascii="' + DocgenConstants.ARIAL_FONT_NAME + '" w:hAnsi="' + DocgenConstants.ARIAL_FONT_NAME + '" w:cs="' + DocgenConstants.ARIAL_FONT_NAME + '"/></w:rPr><w:t xml:space="preserve">Page </w:t></w:r>' +
            '<w:r><w:fldChar w:fldCharType="begin"/></w:r>' +
            '<w:r><w:instrText xml:space="preserve"> PAGE \\* MERGEFORMAT </w:instrText></w:r>' +
            '<w:r><w:fldChar w:fldCharType="separate"/></w:r>' +
            '<w:r><w:rPr><w:noProof/></w:rPr><w:t>1</w:t></w:r>' +
            '<w:r><w:fldChar w:fldCharType="end"/></w:r>' +
            '<w:r><w:rPr><w:rFonts w:ascii="' + DocgenConstants.ARIAL_FONT_NAME + '" w:hAnsi="' + DocgenConstants.ARIAL_FONT_NAME + '" w:cs="' + DocgenConstants.ARIAL_FONT_NAME + '"/></w:rPr><w:t xml:space="preserve"> of </w:t></w:r>' +
            '<w:r><w:fldChar w:fldCharType="begin"/></w:r>' +
            '<w:r><w:instrText xml:space="preserve"> NUMPAGES \\* Arabic \\* MERGEFORMAT </w:instrText></w:r>' +
            '<w:r><w:fldChar w:fldCharType="separate"/></w:r>' +
            '<w:r><w:rPr><w:noProof/></w:rPr><w:t>1</w:t></w:r>' +
            '<w:r><w:fldChar w:fldCharType="end"/></w:r>' +
            '</w:p></w:ftr>';
    }
    
    /**
* Builds the landscape header XML. Returns the generated XML.
*/
    private String buildLandscapeHeaderXml() {
        return DocgenConstants.XML_DECLARATION +
            '<w:hdr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:w10="urn:schemas-microsoft-com:office:word">' +
            '<w:p><w:r><w:pict>' +
            '<v:shapetype id="_x0000_t136" coordsize="21600,21600" o:spt="136" adj="10800" path="m@7,l@8,m@5,21600l@6,21600e">' +
            '<v:formulas><v:f eqn="sum #0 0 10800"/><v:f eqn="prod #0 2 1"/><v:f eqn="sum 21600 0 @1"/><v:f eqn="sum 0 0 @2"/><v:f eqn="sum 21600 0 @3"/><v:f eqn="if @0 @3 0"/><v:f eqn="if @0 21600 @1"/><v:f eqn="if @0 0 @2"/><v:f eqn="if @0 @4 21600"/><v:f eqn="mid @5 @6"/><v:f eqn="mid @8 @5"/><v:f eqn="mid @7 @8"/><v:f eqn="mid @6 @7"/><v:f eqn="sum @6 0 @5"/></v:formulas>' +
            '<v:path textpathok="t" o:connecttype="custom" o:connectlocs="@9,0;@10,10800;@11,21600;@12,10800" o:connectangles="270,180,90,0"/><v:textpath on="t" fitshape="t"/><v:handles><v:h position="#0,bottomRight" xrange="6629,14971"/></v:handles><o:lock v:ext="edit" text="t" shapetype="t"/></v:shapetype>' +
            '<v:shape id="PowerPlusWaterMarkObject" o:spid="_x0000_s1025" type="#_x0000_t136" style="position:absolute;margin-left:0;margin-top:0;width:468pt;height:117pt;rotation:315;z-index:-251572224;mso-position-horizontal:center;mso-position-horizontal-relative:margin;mso-position-vertical:center;mso-position-vertical-relative:margin" o:allowincell="f" fillcolor="silver" stroked="f">' +
            '<v:fill opacity=".5"/><v:textpath style="font-family:&quot;Arial&quot;;font-size:72pt" string="Interim"/><w10:wrap anchorx="margin" anchory="margin"/></v:shape>' +
            '</w:pict></w:r></w:p></w:hdr>';
    }
    
    /**
* Builds the portrait header XML. Returns the generated XML.
*/
    private String buildPortraitHeaderXml() {
        return DocgenConstants.XML_DECLARATION +
            '<w:hdr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">' +
            '<w:p><w:pPr><w:pStyle w:val="Header"/></w:pPr></w:p>' +
            '</w:hdr>';
    }
    
    /**
* Inline section break — ends Section 1 (portrait certificate page).
* Portrait section has: Internal footer only. No page numbers.
*/
    private String sectionBreakPara() {
        String r = 'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"';
        return '<w:p><w:pPr><w:sectPr>' +
            '<w:headerReference w:type="default" r:id="rId5" ' + r + '/>' +
            '<w:headerReference w:type="even"    r:id="rId5" ' + r + '/>' +
            '<w:headerReference w:type="first"   r:id="rId5" ' + r + '/>' +
            '<w:footerReference w:type="default" r:id="rId2" ' + r + '/>' +
            '<w:footerReference w:type="even"    r:id="rId2" ' + r + '/>' +
            '<w:footerReference w:type="first"   r:id="rId2" ' + r + '/>' +
            '<w:pgSz w:w="' + DocgenConstants.PAGE1_WIDTH_DXA + '" w:h="' + DocgenConstants.PAGE1_HEIGHT_DXA + '" w:code="1"/>' +
            '<w:pgMar w:top="' + DocgenConstants.PAGE1_MARGIN_TOP_DXA + '" w:right="' + DocgenConstants.PAGE1_MARGIN_RIGHT_DXA + '"' +
            ' w:bottom="' + DocgenConstants.PAGE1_MARGIN_BOTTOM_DXA + '" w:left="' + DocgenConstants.PAGE1_MARGIN_LEFT_DXA + '"' +
            ' w:header="0" w:footer="' + DocgenConstants.PAGE1_FOOTER_MARGIN_DXA + '" w:gutter="0"/>' +
            '<w:cols w:space="' + DocgenConstants.WORD_SECTION_COLUMNS_SPACE_DXA + '"/><w:docGrid w:linePitch="' + DocgenConstants.WORD_DOC_GRID_LINE_PITCH_DXA + '"/>' +
            '</w:sectPr></w:pPr></w:p>';
    }
    
    /**
* Builds portrait section properties XML. Returns the generated XML.
*/
    private String portraitSectPr() {
        String r = 'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"';
        return '<w:sectPr>' +
            '<w:headerReference w:type="default" r:id="rId5" ' + r + '/>' +
            '<w:headerReference w:type="even"    r:id="rId5" ' + r + '/>' +
            '<w:headerReference w:type="first"   r:id="rId5" ' + r + '/>' +
            '<w:footerReference w:type="default" r:id="rId2" ' + r + '/>' +
            '<w:footerReference w:type="even"    r:id="rId2" ' + r + '/>' +
            '<w:footerReference w:type="first"   r:id="rId2" ' + r + '/>' +
            '<w:pgSz w:w="' + DocgenConstants.PAGE1_WIDTH_DXA + '" w:h="' + DocgenConstants.PAGE1_HEIGHT_DXA + '" w:code="1"/>' +
            '<w:pgMar w:top="' + DocgenConstants.PAGE1_MARGIN_TOP_DXA + '" w:right="' + DocgenConstants.PAGE1_MARGIN_RIGHT_DXA + '"' +
            ' w:bottom="' + DocgenConstants.PAGE1_MARGIN_BOTTOM_DXA + '" w:left="' + DocgenConstants.PAGE1_MARGIN_LEFT_DXA + '"' +
            ' w:header="0" w:footer="' + DocgenConstants.PAGE1_FOOTER_MARGIN_DXA + '" w:gutter="0"/>' +
            '<w:cols w:space="' + DocgenConstants.WORD_SECTION_COLUMNS_SPACE_DXA + '"/><w:docGrid w:linePitch="' + DocgenConstants.WORD_DOC_GRID_LINE_PITCH_DXA + '"/>' +
            '</w:sectPr>';
    }
    
    /**
* Builds landscape section properties XML. Returns the generated XML.
*/
    private String landscapeSectPr() {
        String r = 'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"';
        String hdrId = (isCaseHistory() && useWatermark) ? DocgenConstants.LANDSCAPE_WATERMARK_HEADER_REL_ID : DocgenConstants.EMPTY_HEADER_REL_ID;
        return '<w:sectPr>' +
            '<w:footerReference w:type="default" r:id="rId3" ' + r + '/>' +
            '<w:footerReference w:type="even"    r:id="rId3" ' + r + '/>' +
            '<w:footerReference w:type="first"   r:id="rId3" ' + r + '/>' +
            '<w:headerReference w:type="default" r:id="' + hdrId + '" ' + r + '/>' +
            '<w:headerReference w:type="even"    r:id="' + hdrId + '" ' + r + '/>' +
            '<w:headerReference w:type="first"   r:id="' + hdrId + '" ' + r + '/>' +
            '<w:pgSz w:w="' + DocgenConstants.PAGE2_WIDTH_DXA + '" w:h="' + DocgenConstants.PAGE2_HEIGHT_DXA + '" w:orient="landscape" w:code="1"/>' +
            '<w:pgMar w:top="' + DocgenConstants.PAGE2_MARGIN_TOP_DXA + '" w:right="' + DocgenConstants.PAGE2_MARGIN_LEFT_RIGHT_DXA + '"' +
            ' w:bottom="' + DocgenConstants.PAGE2_MARGIN_BOTTOM_DXA + '" w:left="' + DocgenConstants.PAGE2_MARGIN_LEFT_RIGHT_DXA + '"' +
            ' w:header="0" w:footer="' + DocgenConstants.PAGE2_FOOTER_MARGIN_DXA + '" w:gutter="0"/>' +
            '<w:cols w:space="' + DocgenConstants.WORD_SECTION_COLUMNS_SPACE_DXA + '"/><w:docGrid w:linePitch="' + DocgenConstants.WORD_DOC_GRID_LINE_PITCH_DXA + '"/>' +
            '</w:sectPr>';
    }
    
    /**
Params: String text, Integer fontSize, Boolean bold, Boolean italic, String font
* Formats text with font settings into run XML. Returns the generated XML.
*/
    private String formatFont(String text, Integer fontSize, Boolean bold, Boolean italic, String font) {
        String rPr = '<w:rPr>' +
            '<w:rFonts w:ascii="' + font + '" w:hAnsi="' + font + '" w:cs="' + font + '"/>';
        if (bold)   rPr += '<w:b/>';
        if (italic) rPr += '<w:i/>';
        if (fontSize != null && fontSize > 0) {
            rPr += '<w:sz w:val="' + fontSize + '"/><w:szCs w:val="' + fontSize + '"/>';
        }
        rPr += '</w:rPr>';
        return '<w:r>' + rPr + '<w:t xml:space="preserve">' + text + '</w:t></w:r>';
    }
    
    /**
* Builds an empty paragraph XML block. Returns the generated XML.
*/
    private String blankP() {
        return '<w:p/>';
    }
    
    /**
Params: String text
* Builds a signature paragraph XML block. Returns the generated XML.
*/
    private String sigPara(String text) {
        return '<w:p><w:pPr><w:ind w:left="' + DocgenConstants.WORD_SIGNATURE_INDENT_LEFT_DXA + '" w:firstLine="' + DocgenConstants.WORD_INDENT_FIRST_LINE_DXA + '"/></w:pPr>' +
            formatFont(text, DocgenConstants.BODY_TEXT_SIZE_HALF_POINTS, false, false, DocgenConstants.TIMES_NEW_ROMAN_FONT_NAME) + '</w:p>';
    }
    
    /**
Params: String cells, Boolean isHeader, Boolean preventSplit
* Builds a table row XML block. Returns the generated XML.
*/
    private String formatTableRow(String cells, Boolean isHeader, Boolean preventSplit) {
        List<String> trProps = new List<String>();
        if (isHeader) trProps.add('<w:tblHeader/>');
        if (preventSplit) trProps.add('<w:cantSplit/>');
        
        String trPr = trProps.isEmpty() ? '' : '<w:trPr>' + String.join(trProps, '') + '</w:trPr>';
        return '<w:tr>' + trPr + cells + '</w:tr>';
    }
    
    /**
Params: String text, Integer width, Boolean bold
* Builds an auto-width table cell XML block. Returns the generated XML.
*/
    private String tcAuto(String text, Integer width, Boolean bold) {
        return '<w:tc><w:tcPr>' +
            DocxXmlHelper.cellWidth(width) +
            '<w:shd w:val="clear" w:color="auto" w:fill="auto"/>' +
            DocxXmlHelper.summaryCellMargins() +
            '</w:tcPr>' +
            '<w:p><w:pPr>' + DocxXmlHelper.spacingAfterZero() + '</w:pPr>' +
            formatFont(text, DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS, bold, false, DocgenConstants.ARIAL_FONT_NAME) +
            '</w:p></w:tc>';
    }
    
    /**
Params: String label, String value, Integer width
* Builds a label/value table cell XML block. Returns the generated XML.
*/
    private String tcAutoLabelValue(String label, String value, Integer width) {
        return '<w:tc><w:tcPr>' +
            DocxXmlHelper.cellWidth(width) +
            '<w:shd w:val="clear" w:color="auto" w:fill="auto"/>' +
            DocxXmlHelper.summaryCellMargins() +
            '</w:tcPr>' +
            '<w:p><w:pPr>' + DocxXmlHelper.spacingAfterZero() + '</w:pPr>' +
            formatFont(label, DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS, true, false, DocgenConstants.ARIAL_FONT_NAME) + formatFont(value, DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS, false, false, DocgenConstants.ARIAL_FONT_NAME) +
            '</w:p></w:tc>';
    }
    
    /**
Params: String text, Integer width, Boolean bold, Integer fontSize
* Builds a fixed-width table cell XML block. Returns the generated XML.
*/
    private String formatFixedWidthTableCell(String text, Integer width, Boolean bold, Integer fontSize) {
        Boolean right = String.isNotBlank(text) && (text.startsWith('$') || text.startsWith('-$') || text.startsWith('_'));
        String jc = right ? DocxXmlHelper.jc('right') : '';
        return '<w:tc><w:tcPr>' +
            DocxXmlHelper.cellWidth(width) +
            DocxXmlHelper.summaryCellMargins() +
            '</w:tcPr>' +
            '<w:p><w:pPr>' + DocxXmlHelper.spacingSingleLine() + jc + '</w:pPr>' +
            formatFont(text, fontSize, bold, false, DocgenConstants.ARIAL_FONT_NAME) +
            '</w:p></w:tc>';
    }
    
    /**
Params: Integer width
* Builds an italic ACT grid table cell XML block. Returns the generated XML.
*/
    private String tcGridItalicAct(Integer width) {
        return '<w:tc><w:tcPr>' +
            DocxXmlHelper.cellWidth(width) +
            DocxXmlHelper.summaryCellMargins() +
            '</w:tcPr>' +
            '<w:p><w:pPr>' + DocxXmlHelper.spacingSingleLine() + '</w:pPr>' +
            formatFont(System.Label.TPL_DocGen_Doc_Label_Discount_Prefix + ' ', DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS, false, false, DocgenConstants.ARIAL_FONT_NAME) +
            formatFont(System.Label.TPL_DocGen_Doc_Label_Law_And_Equity_Act, DocgenConstants.SMALL_TEXT_SIZE_HALF_POINTS, false, true, DocgenConstants.ARIAL_FONT_NAME) +
            '</w:p></w:tc>';
    }
    
    /**
* Cell for detail tables — outset sz=6 borders on each cell, no fill.
* TableDataConfiguration controls horizontal alignment, font size, and vertical alignment.
*/
    private class TableDataConfiguration {
        String horizontalAlign;
        Integer fontSize;
        String verticalAlign;
        
        TableDataConfiguration(String horizontalAlign, Integer fontSize, String verticalAlign) {
            this.horizontalAlign = horizontalAlign;
            this.fontSize = fontSize;
            this.verticalAlign = verticalAlign;
        }
    }
    
    /**
Params: String horizontalAlign, Integer fontSize, String verticalAlign
* Builds table data formatting configuration. Returns a TableDataConfiguration instance.
*/
    private TableDataConfiguration tableDataConfiguration(String horizontalAlign, Integer fontSize, String verticalAlign) {
        return new TableDataConfiguration(horizontalAlign, fontSize, verticalAlign);
    }
    
    /**
Params: String cellValue, Integer width, Boolean bold, TableDataConfiguration tableDataConfiguration
* Builds a detail table cell XML block. Returns the generated XML.
*/
    private String tcDetail(String cellValue, Integer width, Boolean bold, TableDataConfiguration tableDataConfiguration) {
        Boolean autoRight = String.isNotBlank(cellValue) &&
            (cellValue == System.Label.TPL_DocGen_Doc_Col_Cost || cellValue.startsWith('$') || cellValue.startsWith('-$'));
        
        String resolvedAlign = tableDataConfiguration != null && String.isNotBlank(tableDataConfiguration.horizontalAlign)
            ? tableDataConfiguration.horizontalAlign
            : (autoRight ? DocgenConstants.TABLE_HORIZONTAL_ALIGN_RIGHT : null);
                
                String jc = String.isNotBlank(resolvedAlign)
                ? DocxXmlHelper.jc(resolvedAlign)
                : '';
        
        Integer resolvedFontSize = tableDataConfiguration != null && tableDataConfiguration.fontSize != null
            ? tableDataConfiguration.fontSize
            : DocgenConstants.DOCX_TABLE_COLUMN_WIDTH_COUNT;
        
        String resolvedVerticalAlign = tableDataConfiguration != null && String.isNotBlank(tableDataConfiguration.verticalAlign)
            ? tableDataConfiguration.verticalAlign
            : DocgenConstants.TABLE_VERTICAL_ALIGN_TOP;
        
        return '<w:tc><w:tcPr>' +
            DocxXmlHelper.cellWidth(width) +
            outsetBorders() +
            '<w:vAlign w:val="' + resolvedVerticalAlign + '"/><w:hideMark/>' +
            '</w:tcPr>' +
            '<w:p><w:pPr>' + DocxXmlHelper.spacingAfterZero() + jc + '</w:pPr>' +
            formatFont(DocxXmlRenderService.escXml(cellValue), resolvedFontSize, bold, false, DocgenConstants.ARIAL_FONT_NAME) +
            '</w:p></w:tc>';
    }
    
    /**
* Builds outset border XML. Returns the generated XML.
*/
    private String outsetBorders() {
        return '<w:tcBorders>'
            + DocxXmlHelper.outsideBorders('outset', DocgenConstants.WORD_BORDER_SIZE_OUTSET)
            + '</w:tcBorders>';
    }
    
    /**
Params: String rows, List<Integer> cols
* Builds a table grid XML block. Returns the generated XML.
*/
    private String tblGrid(String rows, List<Integer> cols) {
        String grid = DocxXmlHelper.gridCols(cols);
        return '<w:tbl>' +
            '<w:tblPr>' +
            '<w:tblStyle w:val="TableGrid"/>' +
            '<w:tblW w:w="0" w:type="auto"/>' +
            '<w:tblBorders>' +
            DocxXmlHelper.tableBorders('none', DocgenConstants.WORD_ZERO) +
            '</w:tblBorders>' +
            DocxXmlHelper.tableLook() +
            '</w:tblPr>' +
            '<w:tblGrid>' + grid + '</w:tblGrid>' +
            rows + '</w:tbl>';
    }
    
    /**
Params: String rows, List<Integer> cols, Integer width
* Builds a detail table XML block. Returns the generated XML.
*/
    private String tblDetail(String rows, List<Integer> cols, Integer width) {
        String grid = DocxXmlHelper.gridCols(cols);
        String bdr = DocxXmlHelper.outsideBorders('outset', DocgenConstants.WORD_BORDER_SIZE_OUTSET);
        return '<w:tbl>' +
            '<w:tblPr>' +
            '<w:tblW w:w="' + width + '" w:type="dxa"/>' +
            '<w:tblCellSpacing w:w="0" w:type="dxa"/>' +
            '<w:tblBorders>' + bdr + '</w:tblBorders>' +
            '<w:tblLayout w:type="fixed"/>' +
            '<w:tblCellMar><w:top w:w="' + DocgenConstants.WORD_CELL_MARGIN_DETAIL_DXA + '" w:type="dxa"/><w:left w:w="' + DocgenConstants.WORD_CELL_MARGIN_DETAIL_DXA + '" w:type="dxa"/><w:bottom w:w="' + DocgenConstants.WORD_CELL_MARGIN_DETAIL_DXA + '" w:type="dxa"/><w:right w:w="' + DocgenConstants.WORD_CELL_MARGIN_DETAIL_DXA + '" w:type="dxa"/></w:tblCellMar>' +
            DocxXmlHelper.tableLook() +
            '</w:tblPr>' +
            '<w:tblGrid>' + grid + '</w:tblGrid>' +
            rows + '</w:tbl>';
    }
    
    /**
* Computes the certificate date parts used in the document.
*/
    private void computeDateParts() {
        Date today = Date.today();
        Integer d = today.day();
        this.year  = String.valueOf(today.year());
        this.day   = String.valueOf(d);
        this.month = DocxFormatHelper.currentMonthName();
        this.daySubscript = DocxXmlRenderService.daySuffix(d);
    }
    
    /**
* Checks whether the selected template is the case history document and returns the result.
*/
    private Boolean isCaseHistory() { return isCaseHistoryCert; }
    
}