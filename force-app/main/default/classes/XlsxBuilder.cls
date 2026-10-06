/**
* Author: Nikhil Jeenru
* Company: CGI
* Builds a multi-sheet SpreadsheetML workbook (Certificate, Summary, and one sheet per
* Healthcare Cost type) and packages it as an XLSX file, matching the Minister's
* Certificate presentation with costs as native numeric cells so totals sum in Excel.
*/
public class XlsxBuilder {
    /**
    * Thrown when a section has more records than one XLSX sheet is allowed to hold.
    */
    public class XlsxRecordLimitException extends Exception {}

    /**
    * Max records allowed per XLSX sheet.
    */
    public static final Integer MAX_ROWS_PER_SHEET = DocgenConstants.MAX_ROWS_PER_DOCX_SECTION_FILE * 5;

    private static final List<String> COLUMN_LETTERS = new List<String>{ 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L' };
    private static final String DEFAULT_LOGO_STATIC_RESOURCE = DocgenConstants.DEFAULT_LOGO_STATIC_RESOURCE;
    private static final Decimal DATA_TAB_ROW_HEIGHT = 18.975;
    private static final Decimal HEADER_BLOCK_ROW_HEIGHT = 21.82125;
    private static final Decimal SUMMARY_ROW_HEIGHT = 19.8;
    private static final Decimal SUMMARY_ROWS_18_TO_22_HEIGHT = 20.9;
    // Target printed width, in inches, for every landscape grid sheet (Summary and each
    // type tab) on landscape Letter paper.
    private static final Decimal PRINT_TARGET_WIDTH_INCHES = 10;
    // Summary sheet prints at this multiple of the shared target width.
    private static final Decimal SUMMARY_PRINT_SCALE_MULTIPLIER = 1.44;

    private String caseNumber     = '';
    private String claimNumber    = '';
    private String contactName    = '';
    private String phn            = '';
    private String birthDate      = '';
    private String incidentDate   = '';
    private Decimal totalCost     = 0;

    private List<List<Object>> ambulanceRecords      = new List<List<Object>>();
    private List<List<Object>> hospitalRecords       = new List<List<Object>>();
    private List<List<Object>> mspRecords            = new List<List<Object>>();
    private List<List<Object>> pharmaRecords         = new List<List<Object>>();
    private List<List<Object>> continuingCareRecords = new List<List<Object>>();
    private List<List<Object>> futureCareRecords     = new List<List<Object>>();

    /**
    * One rich-text run within a cell: text plus its own font/weight.
    */
    private class TextRun {
        String text;
        String fontName;
        Decimal size;
        Boolean bold;
        Boolean italic;

        TextRun(String text, String fontName, Decimal size, Boolean bold, Boolean italic) {
            this.text = text;
            this.fontName = fontName;
            this.size = size;
            this.bold = bold == true;
            this.italic = italic == true;
        }
    }

    public XlsxBuilder setCaseData(Case c) {
        this.caseNumber    = DocxFormatHelper.stringValue(c.CaseNumber);
        this.claimNumber   = DocxFormatHelper.stringValue(c.Claim_Number__c);
        this.contactName   = DocxFormatHelper.stringValue(c.ContactName__c);
        this.phn           = DocxFormatHelper.stringValue(c.PHN__c);
        this.birthDate     = DocxFormatHelper.formatDate(c.Date_of_Birth__c);
        this.incidentDate  = DocxFormatHelper.formatDate(c.Incident_Date__c);
        this.totalCost     = DocxFormatHelper.decimalValue(c.Total_Case_Value__c);
        return this;
    }

    public XlsxBuilder setAmbulanceRecords(List<Healthcare_Cost__c> recs) {
        for (Healthcare_Cost__c r : recs) {
            String dest = String.isNotBlank(r.FacilityName__c)
                ? r.FacilityName__c : DocxFormatHelper.stringValue(r.Facility_Name__c);
            ambulanceRecords.add(new List<Object>{
                DocxFormatHelper.formatDate(r.Date_of_Service__c),
                DocxFormatHelper.stringValue(r.Location_Responded__c),
                dest,
                DocxFormatHelper.decimalValue(r.Total_Cost_Override__c)
            });
        }
        return this;
    }

    public XlsxBuilder setHospitalRecords(List<Healthcare_Cost__c> recs) {
        for (Healthcare_Cost__c r : recs) {
            String facility = String.isNotBlank(r.FacilityName__c)
                ? r.FacilityName__c : DocxFormatHelper.stringValue(r.Facility_Name__c);
            Decimal cost = r.Total_Cost_Override__c != null
                ? r.Total_Cost_Override__c : r.Total_Costs_Standard__c;
            String days = r.Number_of_Days__c != null
                ? String.valueOf(r.Number_of_Days__c.intValue()) : '';
            hospitalRecords.add(new List<Object>{
                DocxFormatHelper.formatDate(r.Date_of_Admission__c),
                DocxFormatHelper.formatDate(r.Date_of_Discharge__c),
                facility,
                DocxFormatHelper.stringValue(r.Service_Type2__c),
                days,
                DocxFormatHelper.decimalValue(cost)
            });
        }
        return this;
    }

    public XlsxBuilder setMSPRecords(List<Healthcare_Cost__c> recs) {
        for (Healthcare_Cost__c r : recs) {
            mspRecords.add(new List<Object>{
                DocxFormatHelper.formatDate(r.Date_of_Service__c),
                DocxFormatHelper.stringValue(r.Location_Type_Description2__c).trim(),
                DocxFormatHelper.stringValue(r.Description_of_Service2__c),
                DocxFormatHelper.stringValue(r.Fee_Item_Title__c),
                DocxFormatHelper.stringValue(r.Diagnostic_Description__c),
                DocxFormatHelper.decimalValue(r.Total_Cost_Override__c),
                DocxFormatHelper.stringValue(r.Practitioner_Name__c)
            });
        }
        return this;
    }

    public XlsxBuilder setPharmaRecords(List<Healthcare_Cost__c> recs) {
        for (Healthcare_Cost__c r : recs) {
            pharmaRecords.add(new List<Object>{
                DocxFormatHelper.formatDate(r.Date_of_Service__c),
                DocxFormatHelper.stringValue(r.Name_of_Drug__c),
                DocxFormatHelper.decimalValue(r.Total_Cost_Override__c),
                DocxFormatHelper.stringValue(r.Practitioner_Name__c)
            });
        }
        return this;
    }

    public XlsxBuilder setContinuingCareRecords(List<Healthcare_Cost__c> recs) {
        for (Healthcare_Cost__c r : recs) {
            continuingCareRecords.add(new List<Object>{
                DocxFormatHelper.stringValue(r.Description__c),
                DocxFormatHelper.decimalValue(r.Cost__c)
            });
        }
        return this;
    }

    public XlsxBuilder setFutureCareRecords(List<Healthcare_Cost__c> recs) {
        for (Healthcare_Cost__c r : recs) {
            futureCareRecords.add(new List<Object>{
                DocxFormatHelper.stringValue(r.Description__c),
                DocxFormatHelper.decimalValue(r.Cost__c)
            });
        }
        return this;
    }

    /**
    * Builds the complete XLSX workbook: Certificate, Summary, and one sheet per
    * populated Healthcare Cost type.
    */
    public Blob build() {
        List<String> sheetNames = new List<String>{ 'Certificate', 'Summary' };
        if (!ambulanceRecords.isEmpty())      sheetNames.add('Ambulance');
        if (!hospitalRecords.isEmpty())       sheetNames.add('Hospital');
        if (!mspRecords.isEmpty())            sheetNames.add('MSP');
        if (!pharmaRecords.isEmpty())         sheetNames.add('Pharmacare');
        if (!continuingCareRecords.isEmpty()) sheetNames.add('Continuing Care');
        if (!futureCareRecords.isEmpty())     sheetNames.add('Future Care');

        Blob logoBody = getLogoBody();
        XlsxPackageService.PackageBuilder pkg = new XlsxPackageService.PackageBuilder(sheetNames, logoBody != null);

        // Each sheet is streamed to the ZipWriter as it's built, so heap scales with
        // the largest single sheet rather than the sum of all sheets.
        pkg.addSheet(buildCertificateSheet(logoBody));
        pkg.addSheet(buildSummarySheet());

        if (!ambulanceRecords.isEmpty()) {
            // Destination in D, Cost in G; B:C and D:E each render as one bordered box.
            // Total row: label in A, value in C.
            pkg.addSheet(buildTypeSheet('Ambulance',
                new List<String>{ 'Date of Service', 'Location Responded', 'Destination', 'Cost' },
                ambulanceRecords, 3, new List<Decimal>{ 16, 4.2, 22, 8, 22, 20, 12.65 }, 'Ambulance',
                new List<Integer>{ 0, 1, 3, 6 }, 'A', 8, null, 'G',
                new Map<Integer, Integer>{ 1 => 43, 2 => 42, 3 => 43, 4 => 44, 5 => 42 },
                new Map<Integer, Integer>{ 1 => 41, 2 => 42, 3 => 41, 4 => 45, 5 => 42 },
                'C', null,
                new Map<String, String>{ 'case' => 'F', 'mvClaim' => 'F', 'phn' => 'D', 'birthDate' => 'F' }));
            ambulanceRecords = null;
        }
        if (!hospitalRecords.isEmpty()) {
            // Data columns A-F contiguous, no spacer columns. Total row label in B, value in C.
            // Facility in C (left edge of the C:D box); D is the blank spacer;
            // Service Type/Days/Cost in E/F/G.
            pkg.addSheet(buildTypeSheet('Hospital',
                new List<String>{ 'Admission Date', 'Discharge Date', 'Facility', 'Service Type', 'Days', 'Cost' },
                hospitalRecords, 5, new List<Decimal>{ 17, 20, 7, 45.15, 28, 10, 15 }, 'Hospital',
                new List<Integer>{ 0, 1, 2, 4, 5, 6 }, 'A', 8, null, 'G',
                new Map<Integer, Integer>{ 2 => 43, 3 => 42 },
                new Map<Integer, Integer>{ 2 => 41, 3 => 42 },
                null, null,
                new Map<String, String>{ 'phn' => 'D' }));
            hospitalRecords = null;
        }
        if (!mspRecords.isEmpty()) {
            // Description of Service/Fee Item/Diagnostic (E/F/G) wrap text; title row
            // merges A2:I2. Data columns A-G contiguous, no spacer columns.
            pkg.addSheet(buildTypeSheet('MSP',
                new List<String>{ 'Date of Service', 'Location Type', 'Description of Service', 'Fee Item', 'Diagnostic', 'Cost', 'Practitioner Name' },
                mspRecords, 5, new List<Decimal>{ 14.4, 31.5, 24, 24, 18, 16, 25 }, 'Medical',
                new List<Integer>{ 0, 1, 2, 3, 4, 5, 6 }, 'A', 8, new Set<String>{ 'B', 'C', 'D', 'E' }, 'G'));
            mspRecords = null;
        }
        if (!pharmaRecords.isEmpty()) {
            // Name of Drug box is B:C:D with the label at B. Cost/Practitioner Name and
            // their spacer columns are E, F:G:H.
            pkg.addSheet(buildTypeSheet('Pharmacare',
                new List<String>{ 'Date of Service', 'Name of Drug', 'Cost', 'Practitioner Name' },
                pharmaRecords, 2, new List<Decimal>{ 15.75, 8, 18.4, 24.5, 14, 0.75, 12, 24.5 }, 'Pharmacy',
                new List<Integer>{ 0, 1, 4, 6 }, 'A', 8, null, 'H',
                new Map<Integer, Integer>{ 1 => 43, 2 => 44, 3 => 42, 5 => 41, 6 => 44, 7 => 42 },
                new Map<Integer, Integer>{ 1 => 41, 2 => 45, 3 => 42, 5 => 41, 6 => 45, 7 => 42 },
                'C', 'H',
                new Map<String, String>{ 'case' => 'G', 'mvClaim' => 'G', 'phn' => 'D', 'birthDate' => 'G' }));
            pharmaRecords = null;
        }
        if (!continuingCareRecords.isEmpty()) {
            // Cost is in column F. A:E form one bordered box (Description in A,
            // B/C/D/E blank spacers); F (Cost) stands alone. Total row value displays in C.
            pkg.addSheet(buildTypeSheet('Continuing Care',
                new List<String>{ 'Description', 'Cost' }, continuingCareRecords, 1,
                new List<Decimal>{ 27, 20, 15, 15, 20, 17 }, 'Continuing Care', new List<Integer>{ 0, 5 },
                'A', 8, null, 'F',
                new Map<Integer, Integer>{ 0 => 43, 1 => 45, 2 => 45, 3 => 45, 4 => 42 },
                new Map<Integer, Integer>{ 0 => 41, 1 => 45, 2 => 45, 3 => 45, 4 => 42 },
                'B', null));
            continuingCareRecords = null;
        }
        if (!futureCareRecords.isEmpty()) {
            // Cost is in column F. A:E form one bordered box (Description in A,
            // B/C/D/E blank spacers); F (Cost) stands alone. Total row value displays in C.
            pkg.addSheet(buildTypeSheet('Future Care',
                new List<String>{ 'Description', 'Cost' }, futureCareRecords, 1, new List<Decimal>{ 22, 20, 15, 15, 20, 17 },
                'Future Care', new List<Integer>{ 0, 5 }, 'A', 8, null, 'F',
                new Map<Integer, Integer>{ 0 => 43, 1 => 45, 2 => 45, 3 => 45, 4 => 42 },
                new Map<Integer, Integer>{ 0 => 41, 1 => 45, 2 => 45, 3 => 45, 4 => 42 },
                'B', null));
            futureCareRecords = null;
        }

        return pkg.finish();
    }

    // ==================== Certificate sheet ====================

    /**
    * Builds the Certificate sheet: native cells matching the Minister's Certificate
    * wording, with inline bold/italic runs and the Ministry logo embedded as an image.
    */
    private XlsxPackageService.Sheet buildCertificateSheet(Blob logoBody) {
        List<String> mergeRefs = new List<String>();
        String rows = '';

        // Rows 1-4 are blank; the logo is anchored at F2. Column C is a blank spacer,
        // so content columns run D-I.
        rows += heightRow(5, 33.6, textCellXml('G', 5, 25, System.Label.TPL_DocGen_Doc_Label_Case_Number) + textCellXml('H', 5, 26, caseNumber));

        rows += mergedRow(7, 'A7:H7', 49, System.Label.TPL_DocGen_Doc_Title_Ministers_Certificate, mergeRefs, 22.5);

        rows += heightRow(8, 19, '');

        rows += mergedRichRow(9, 'B9:H9', 24, mergeRefs, 44.25, new List<TextRun>{
            new TextRun(System.Label.TPL_DocGen_Doc_Cert_Whereas_Prefix + ' ', 'Times New Roman', 11, false, false),
            new TextRun(System.Label.TPL_DocGen_Doc_Cert_Act_Name, 'Times New Roman', 11, false, true),
            new TextRun(System.Label.TPL_DocGen_Doc_Cert_Whereas_Suffix, 'Times New Roman', 11, false, false)
        });

        // The label text includes its own "(a)"/"(b)" prefix; strip it here since the
        // letter renders in its own cell (B10/B11).
        mergeRefs.add('D10:H10');
        rows += heightRow(10, 76.5,
            textCellXml('B', 10, 48, '(a)') +
            textCellXml('D', 10, 24, System.Label.TPL_DocGen_Doc_Cert_Item_A.removeStart('(a) ')));
        mergeRefs.add('D11:H11');
        rows += heightRow(11, 41.5,
            textCellXml('B', 11, 48, '(b)') +
            textCellXml('D', 11, 24, System.Label.TPL_DocGen_Doc_Cert_Item_B.removeStart('(b) ')));

        rows += mergedRichRow(12, 'B12:H12', 24, mergeRefs, 78.7125, new List<TextRun>{
            new TextRun(System.Label.TPL_DocGen_Doc_Cert_Therefore_Prefix + ' ', 'Times New Roman', 11, false, false),
            new TextRun(System.Label.TPL_DocGen_Default_Signing_Name, 'Times New Roman', 11, false, false),
            new TextRun(System.Label.TPL_DocGen_Doc_Cert_Therefore_Claim + ' ', 'Times New Roman', 11, false, false),
            new TextRun(contactName, 'Arial', 11, true, false),
            new TextRun(System.Label.TPL_DocGen_Doc_Cert_PHN_Prefix + ' ', 'Times New Roman', 11, false, false),
            new TextRun(phn, 'Arial', 11, true, false),
            new TextRun(System.Label.TPL_DocGen_Doc_Cert_Incident_Prefix + ' ', 'Times New Roman', 11, false, false),
            new TextRun(incidentDate, 'Times New Roman', 11, true, false),
            new TextRun('.', 'Times New Roman', 11, false, false)
        });

        rows += mergedRichRow(13, 'B13:H13', 24, mergeRefs, 41.75, new List<TextRun>{
            new TextRun(System.Label.TPL_DocGen_Doc_Cert_Total_Past_Costs_Prefix + ' ', 'Times New Roman', 11, false, false),
            new TextRun(DocxFormatHelper.formatCurrency(totalCost) + '.', 'Times New Roman', 11, true, false)
        });

        Date today = Date.today();
        String monthName = Datetime.newInstance(today, Time.newInstance(0, 0, 0, 0)).format('MMMM');
        rows += mergedRow(14, 'B14:H14', 24,
            System.Label.TPL_DocGen_Doc_Cert_Dated_Prefix + ' ' + today.day() + DocxXmlRenderService.daySuffix(today.day()) +
            ' ' + System.Label.TPL_DocGen_Doc_Cert_Day_Of + ' ' + monthName + ', ' + today.year() + '.', mergeRefs, 38);

        rows += heightRow(18, 16.56, textCellXml('F', 18, 22, '____________________________________'));
        rows += heightRow(19, 16.56, textCellXml('F', 19, 27, System.Label.TPL_DocGen_Default_Signing_Name));
        rows += heightRow(20, 16.56, textCellXml('F', 20, 27, System.Label.TPL_DocGen_Default_Signing_Title));
        rows += heightRow(21, 16.56, textCellXml('F', 21, 27, System.Label.TPL_DocGen_Doc_Label_Designate_On_Behalf_Of));
        rows += heightRow(22, 16.56, textCellXml('F', 22, 27, System.Label.TPL_DocGen_Doc_Label_Minister_Of_Health));

        return new XlsxPackageService.Sheet('Certificate', rows)
            .withMergeCells(mergeRefs)
            .withColumnWidths(new List<Decimal>{ 7.625, 5.71875, 1, 7.03125, 12.285, 37, 9.625, 17.85375, 7.625 })
            .withColumnDefaultStyle(22)
            .withLogo(logoBody)
            .withLogoAnchor(5, 1);
    }

    // ==================== Summary sheet (Appendix A layout) ====================

    /**
    * Builds the Summary sheet: title, case-info line, "Past Costs of Healthcare
    * Services" (live formulas summing each type sheet's Cost column), then
    * "Future Costs of Healthcare Services".
    */
    private XlsxPackageService.Sheet buildSummarySheet() {
        List<String> mergeRefs = new List<String>();
        String rows = '';

        rows += mergedRow(2, 'B2:H2', 28, System.Label.TPL_DocGen_Doc_Title_Appendix_A, mergeRefs, null);
        rows += mergedRow(3, 'B3:H3', 28, System.Label.TPL_DocGen_Doc_Title_Healthcare_Services_Claim, mergeRefs, null);

        rows += heightRow(5, 22.77, labelValueCell('F', 5, 'Case #: ', caseNumber));
        rows += heightRow(6, 22.77,
            labelValueCell('B', 6, 'Name: ', contactName) + labelValueCell('F', 6, 'MV Claim #: ', claimNumber));
        rows += heightRow(7, 22.77,
            labelValueCell('B', 7, 'Incident Date: ', incidentDate) +
            labelValueCell('D', 7, 'PHN: ', phn) +
            labelValueCell('F', 7, 'Birth Date: ', birthDate));

        rows += rowXml(10, cellXml('B', 10, 29, System.Label.TPL_DocGen_Doc_Label_Past_Costs, false));

        // Column letters here must match each tab's actual Cost column.
        Integer ambRow = 11; rows += summaryLineItemRow(11, System.Label.TPL_DocGen_Doc_Section_Ambulance, 'Ambulance', 'G', ambulanceRecords.size(), SUMMARY_ROWS_18_TO_22_HEIGHT);
        Integer hospRow = 12; rows += summaryLineItemRow(12, System.Label.TPL_DocGen_Doc_Section_Hospital, 'Hospital', 'G', hospitalRecords.size(), SUMMARY_ROWS_18_TO_22_HEIGHT);
        Integer mspRow = 13; rows += summaryLineItemRow(13, System.Label.TPL_DocGen_Doc_Section_Medical, 'MSP', 'F', mspRecords.size(), SUMMARY_ROWS_18_TO_22_HEIGHT);
        Integer pharmaRow = 14; rows += summaryLineItemRow(14, System.Label.TPL_DocGen_Doc_Section_Pharmacy, 'Pharmacare', 'E', pharmaRecords.size(), SUMMARY_ROWS_18_TO_22_HEIGHT);
        Integer ccRow = 15; rows += summaryLineItemRow(15, System.Label.TPL_DocGen_Doc_Section_Continuing_Care, 'Continuing Care', 'F', continuingCareRecords.size(), SUMMARY_ROWS_18_TO_22_HEIGHT);

        rows += rowXml(16, cellXml('E', 16, 34, '________________', false));
        String pastCostsFormula = 'E' + ambRow + '+E' + hospRow + '+E' + mspRow + '+E' + pharmaRow + '+E' + ccRow;
        Integer pastTotalRow = 17;
        rows += rowXml(17,
            cellXml('B', 17, 32, System.Label.TPL_DocGen_Doc_Label_Total_Past_Cost, false) + formulaCurrencyCell('E', 17, 33, pastCostsFormula));

        rows += heightRow(18, SUMMARY_ROWS_18_TO_22_HEIGHT, '');
        rows += heightRow(19, SUMMARY_ROWS_18_TO_22_HEIGHT, cellXml('B', 19, 29, System.Label.TPL_DocGen_Doc_Label_Future_Costs, false));
        Integer fcRow = 20; rows += summaryLineItemRow(20, System.Label.TPL_DocGen_Doc_Section_Future_Care, 'Future Care', 'F', futureCareRecords.size(), SUMMARY_ROWS_18_TO_22_HEIGHT);
        Integer discountRow = 21;
        rows += heightRow(21, SUMMARY_ROWS_18_TO_22_HEIGHT,
            richTextCellXml('B', 21, 35, new List<TextRun>{
                new TextRun(System.Label.TPL_DocGen_Doc_Label_Discount_Prefix + ' ', 'Arial', 11, false, false),
                new TextRun(System.Label.TPL_DocGen_Doc_Label_Law_And_Equity_Act, 'Arial', 11, false, true)
            }) +
            currencyCellStyled('E', 21, 31, 0));

        rows += heightRow(22, SUMMARY_ROWS_18_TO_22_HEIGHT, cellXml('E', 22, 34, '________________', false));
        String futureCostsFormula = 'E' + fcRow + '-E' + discountRow;
        Integer futureTotalRow = 23;
        rows += rowXml(23,
            cellXml('B', 23, 32, System.Label.TPL_DocGen_Doc_Label_Total_Future_Cost, false) + formulaCurrencyCell('E', 23, 33, futureCostsFormula));

        rows += rowXml(26,
            cellXml('B', 26, 32, System.Label.TPL_DocGen_Doc_Label_Present_Value_Total_Claim, false) +
            formulaCurrencyCell('E', 26, 33, 'E' + pastTotalRow + '+E' + futureTotalRow));

        List<Decimal> summaryColumnWidths = new List<Decimal>{ 4.75, 20.875, 25, 25, 17.875, 15, 8.43, 8.43, 8.43, 8.43, 8.43, 8.43, 8.43, 8.43, 8.43 };
        return new XlsxPackageService.Sheet('Summary', rows)
            .withPageOrientation('landscape')
            .withPrintScale(computePrintScalePercent(summaryColumnWidths, PRINT_TARGET_WIDTH_INCHES * SUMMARY_PRINT_SCALE_MULTIPLIER))
            .withMergeCells(mergeRefs)
            // Every column needs an explicit width, or a <col> with a style but no
            // width renders as zero-width (hidden) in Excel.
            .withColumnWidths(summaryColumnWidths)
            .withColumnDefaultStyle(22)
            .withColumnDefaultStyleLimit(8) // white fill covers A-H only; I-O get no fill
            .withDefaultRowHeight(SUMMARY_ROW_HEIGHT);
    }

    private String summaryLineItemRow(Integer rowNum, String label, String sheetName, String dataColLetter, Integer rowCount) {
        return summaryLineItemRow(rowNum, label, sheetName, dataColLetter, rowCount, null);
    }

    /**
    * Builds one Summary line-item row: label in column B, a live formula (or literal
    * 0 when the section has no sheet) in column E.
    */
    private String summaryLineItemRow(Integer rowNum, String label, String sheetName, String dataColLetter, Integer rowCount, Decimal height) {
        String valueCell;
        if (rowCount == 0) {
            valueCell = currencyCellStyled('E', rowNum, 31, 0);
        } else {
            // Data on every type sheet starts at row 11; the range must match that or
            // the total silently undercounts.
            Integer firstDataRow = 11;
            Integer lastDataRow = firstDataRow + rowCount - 1;
            String formula = 'SUM(\'' + sheetName + '\'!' + dataColLetter + firstDataRow + ':' + dataColLetter + lastDataRow + ')';
            valueCell = '<c r="E' + rowNum + '" s="31"><f>' + formula + '</f></c>';
        }
        String cells = cellXml('B', rowNum, 30, label, false) + valueCell;
        return height == null ? rowXml(rowNum, cells) : heightRow(rowNum, height, cells);
    }

    // ==================== Data-type sheets ====================

    private XlsxPackageService.Sheet buildTypeSheet(String sheetName, List<String> headers, List<List<Object>> dataRows, Integer currencyColIndex, List<Decimal> columnWidths) {
        return buildTypeSheet(sheetName, headers, dataRows, currencyColIndex, columnWidths, sheetName, null);
    }

    private XlsxPackageService.Sheet buildTypeSheet(String sheetName, List<String> headers, List<List<Object>> dataRows, Integer currencyColIndex, List<Decimal> columnWidths, String sectionLabel) {
        return buildTypeSheet(sheetName, headers, dataRows, currencyColIndex, columnWidths, sectionLabel, null);
    }

    private XlsxPackageService.Sheet buildTypeSheet(String sheetName, List<String> headers, List<List<Object>> dataRows, Integer currencyColIndex, List<Decimal> columnWidths, String sectionLabel, List<Integer> columnOverrides) {
        return buildTypeSheet(sheetName, headers, dataRows, currencyColIndex, columnWidths, sectionLabel, columnOverrides, 'A');
    }

    private XlsxPackageService.Sheet buildTypeSheet(String sheetName, List<String> headers, List<List<Object>> dataRows, Integer currencyColIndex, List<Decimal> columnWidths, String sectionLabel, List<Integer> columnOverrides, String totalLabelCol) {
        return buildTypeSheet(sheetName, headers, dataRows, currencyColIndex, columnWidths, sectionLabel, columnOverrides, totalLabelCol, 8);
    }

    private XlsxPackageService.Sheet buildTypeSheet(String sheetName, List<String> headers, List<List<Object>> dataRows, Integer currencyColIndex, List<Decimal> columnWidths, String sectionLabel, List<Integer> columnOverrides, String totalLabelCol, Integer totalLabelStyle) {
        return buildTypeSheet(sheetName, headers, dataRows, currencyColIndex, columnWidths, sectionLabel, columnOverrides, totalLabelCol, totalLabelStyle, null);
    }

    private XlsxPackageService.Sheet buildTypeSheet(String sheetName, List<String> headers, List<List<Object>> dataRows, Integer currencyColIndex, List<Decimal> columnWidths, String sectionLabel, List<Integer> columnOverrides, String totalLabelCol, Integer totalLabelStyle, Set<String> wrapCols) {
        return buildTypeSheet(sheetName, headers, dataRows, currencyColIndex, columnWidths, sectionLabel, columnOverrides, totalLabelCol, totalLabelStyle, wrapCols, 'F');
    }

    private XlsxPackageService.Sheet buildTypeSheet(String sheetName, List<String> headers, List<List<Object>> dataRows, Integer currencyColIndex, List<Decimal> columnWidths, String sectionLabel, List<Integer> columnOverrides, String totalLabelCol, Integer totalLabelStyle, Set<String> wrapCols, String titleEndCol) {
        return buildTypeSheet(sheetName, headers, dataRows, currencyColIndex, columnWidths, sectionLabel, columnOverrides, totalLabelCol, totalLabelStyle, wrapCols, titleEndCol, null, null, null, null);
    }

    private XlsxPackageService.Sheet buildTypeSheet(String sheetName, List<String> headers, List<List<Object>> dataRows, Integer currencyColIndex, List<Decimal> columnWidths, String sectionLabel, List<Integer> columnOverrides, String totalLabelCol, Integer totalLabelStyle, Set<String> wrapCols, String titleEndCol, Map<Integer, Integer> headerStyleOverride, Map<Integer, Integer> dataStyleOverride, String totalValueCol, String tableEndCol) {
        return buildTypeSheet(sheetName, headers, dataRows, currencyColIndex, columnWidths, sectionLabel, columnOverrides, totalLabelCol, totalLabelStyle, wrapCols, titleEndCol, headerStyleOverride, dataStyleOverride, totalValueCol, tableEndCol, null);
    }

    /**
    * Builds one Healthcare Cost type sheet: a case-info header block, the section
    * label, column headers, and data rows.
    */
    private XlsxPackageService.Sheet buildTypeSheet(String sheetName, List<String> headers, List<List<Object>> dataRows, Integer currencyColIndex, List<Decimal> columnWidths, String sectionLabel, List<Integer> columnOverrides, String totalLabelCol, Integer totalLabelStyle, Set<String> wrapCols, String titleEndCol, Map<Integer, Integer> headerStyleOverride, Map<Integer, Integer> dataStyleOverride, String totalValueCol, String tableEndCol, Map<String, String> headerBlockColOverrides) {
        if (dataRows.size() > MAX_ROWS_PER_SHEET) {
            throw new XlsxRecordLimitException(
                'Section has ' + dataRows.size() + ' records, exceeding the ' + MAX_ROWS_PER_SHEET +
                '-row XLSX sheet limit. Split into multiple sheets/files before calling build().'
            );
        }

        Integer forcedMaxPhysicalCol = tableEndCol != null ? COLUMN_LETTERS.indexOf(tableEndCol) : null;
        String caseCol = (headerBlockColOverrides != null && headerBlockColOverrides.containsKey('case')) ? headerBlockColOverrides.get('case') : 'E';
        String mvClaimCol = (headerBlockColOverrides != null && headerBlockColOverrides.containsKey('mvClaim')) ? headerBlockColOverrides.get('mvClaim') : 'E';
        String phnCol = (headerBlockColOverrides != null && headerBlockColOverrides.containsKey('phn')) ? headerBlockColOverrides.get('phn') : 'C';
        String birthDateCol = (headerBlockColOverrides != null && headerBlockColOverrides.containsKey('birthDate')) ? headerBlockColOverrides.get('birthDate') : 'E';

        List<String> mergeRefs = new List<String>();
        String rows = '';
        rows += dataTabTitleRow(2, mergeRefs, titleEndCol);
        rows += heightRow(4, HEADER_BLOCK_ROW_HEIGHT, headerBlockLabelValueCell(caseCol, 4, 'Case #: ', caseNumber));
        rows += heightRow(5, HEADER_BLOCK_ROW_HEIGHT,
            headerBlockLabelValueCell('A', 5, 'Name: ', contactName) +
            headerBlockLabelValueCell(mvClaimCol, 5, 'MV Claim #: ', claimNumber));
        rows += heightRow(6, HEADER_BLOCK_ROW_HEIGHT,
            headerBlockLabelValueCell('A', 6, 'Incident Date: ', incidentDate) +
            headerBlockLabelValueCell(phnCol, 6, 'PHN: ', phn) +
            headerBlockLabelValueCell(birthDateCol, 6, 'Birth Date: ', birthDate));
        rows += headerBlockRow(8, sectionLabel);

        Integer rowNum = 10;
        rows += headerRow(headers, rowNum++, columnOverrides, currencyColIndex, headerStyleOverride, forcedMaxPhysicalCol);
        Integer firstDataRow = rowNum;
        for (List<Object> values : dataRows) {
            rows += dataRow(values, rowNum++, currencyColIndex, columnOverrides, wrapCols, dataStyleOverride, forcedMaxPhysicalCol);
        }
        Integer lastDataRow = rowNum - 1;

        rows += typeSheetTotalRow(lastDataRow + 2, currencyColIndex, firstDataRow, lastDataRow, columnOverrides, sheetName, totalLabelCol, totalLabelStyle, totalValueCol);

        return new XlsxPackageService.Sheet(sheetName, rows)
            .withPageOrientation('landscape')
            .withPrintScale(computePrintScalePercent(columnWidths, PRINT_TARGET_WIDTH_INCHES))
            .withMergeCells(mergeRefs)
            .withColumnWidths(columnWidths)
            .withDefaultRowHeight(DATA_TAB_ROW_HEIGHT);
    }

    /**
    * Maps a logical (query-result) column index to its physical sheet column index.
    * A blank spacer column sits after column B, so index 2+ shifts right by two.
    */
    private Integer physicalCol(Integer logicalIndex) {
        return logicalIndex < 2 ? logicalIndex : logicalIndex + 2;
    }

    /**
    * Resolves a logical column index to physical, preferring an explicit override
    * and falling back to the default post-B-shift mapping.
    */
    private Integer resolveCol(Integer logicalIndex, List<Integer> columnOverrides) {
        if (columnOverrides != null && columnOverrides.size() > logicalIndex && columnOverrides[logicalIndex] != null) {
            return columnOverrides[logicalIndex];
        }
        return physicalCol(logicalIndex);
    }

    /**
    * Builds the data tab's title row, merged and centered in bold Helvetica.
    */
    private String dataTabTitleRow(Integer rowNum, List<String> mergeRefsAccumulator, String endCol) {
        mergeRefsAccumulator.add('A' + rowNum + ':' + endCol + rowNum);
        return rowXml(rowNum, textCellXml('A', rowNum, 36, 'Healthcare Services and Costs Record Part 1'));
    }

    /**
    * Builds the Total row: a "Total {sheetName}" label and a live SUM formula over
    * the currency column's data range.
    */
    private String typeSheetTotalRow(Integer rowNum, Integer currencyColIndex, Integer firstDataRow, Integer lastDataRow, List<Integer> columnOverrides, String sheetName, String labelCol, Integer labelStyle, String totalValueCol) {
        String currencyColLetter = COLUMN_LETTERS[resolveCol(currencyColIndex, columnOverrides)];
        String formula = 'SUM(' + currencyColLetter + firstDataRow + ':' + currencyColLetter + lastDataRow + ')';
        String valueCol = totalValueCol != null ? totalValueCol : COLUMN_LETTERS[COLUMN_LETTERS.indexOf(labelCol) + 1];
        String cells = textCellXml(labelCol, rowNum, labelStyle, 'Total ' + sheetName) +
            '<c r="' + valueCol + rowNum + '" s="39"><f>' + formula + '</f></c>';
        return rowXml(rowNum, cells);
    }

    private String headerBlockRow(Integer rowNum, String text) {
        return rowXml(rowNum, textCellXml('A', rowNum, 19, text));
    }

    /**
    * Builds one case-info cell as two rich-text runs: bold label, regular value.
    */
    private String headerBlockLabelValueCell(String col, Integer rowNum, String label, String value) {
        return richTextCellXml(col, rowNum, 21, new List<TextRun>{
            new TextRun(label, 'Arial', 11, true, false),
            new TextRun(value, 'Arial', 11, false, false)
        });
    }

    /**
    * Builds the bold header row. The Cost column header is right-aligned over its
    * numeric column; every other header is left-aligned.
    */
    private String headerRow(List<String> headers, Integer rowNum, List<Integer> columnOverrides, Integer currencyColIndex, Map<Integer, Integer> headerStyleOverride, Integer forcedMaxPhysicalCol) {
        Map<Integer, String> cellsByPhysicalCol = new Map<Integer, String>();
        Integer maxPhysicalCol = forcedMaxPhysicalCol == null ? 0 : forcedMaxPhysicalCol;
        for (Integer i = 0; i < headers.size(); i++) {
            Integer physCol = resolveCol(i, columnOverrides);
            String col = COLUMN_LETTERS[physCol];
            Integer style = (headerStyleOverride != null && headerStyleOverride.containsKey(physCol))
                ? headerStyleOverride.get(physCol)
                : (i == currencyColIndex ? 37 : 1);
            cellsByPhysicalCol.put(physCol, textCellXml(col, rowNum, style, headers[i]));
            maxPhysicalCol = Math.max(maxPhysicalCol, physCol);
        }
        return rowXml(rowNum, fillPhysicalRow(cellsByPhysicalCol, maxPhysicalCol, rowNum, headerStyleOverride));
    }

    /**
    * Builds one data row: the currency column renders as numeric, everything else as text.
    */
    private String dataRow(List<Object> values, Integer rowNum, Integer currencyColIndex, List<Integer> columnOverrides, Set<String> wrapCols, Map<Integer, Integer> dataStyleOverride, Integer forcedMaxPhysicalCol) {
        Map<Integer, String> cellsByPhysicalCol = new Map<Integer, String>();
        Integer maxPhysicalCol = forcedMaxPhysicalCol == null ? 0 : forcedMaxPhysicalCol;
        for (Integer i = 0; i < values.size(); i++) {
            Integer physCol = resolveCol(i, columnOverrides);
            String col = COLUMN_LETTERS[physCol];
            String cellXml;
            if (dataStyleOverride != null && dataStyleOverride.containsKey(physCol)) {
                cellXml = textCellXml(col, rowNum, dataStyleOverride.get(physCol), String.valueOf(values[i]));
            } else if (i == currencyColIndex) {
                cellXml = currencyCell(col, rowNum, (Decimal) values[i]);
            } else if (wrapCols != null && wrapCols.contains(col)) {
                cellXml = textCellXml(col, rowNum, 5, String.valueOf(values[i]));
            } else {
                cellXml = textCell(col, rowNum, String.valueOf(values[i]));
            }
            cellsByPhysicalCol.put(physCol, cellXml);
            maxPhysicalCol = Math.max(maxPhysicalCol, physCol);
        }
        return rowXml(rowNum, fillPhysicalRow(cellsByPhysicalCol, maxPhysicalCol, rowNum, dataStyleOverride));
    }

    /**
    * Fills blank spacer columns with a bordered blank cell so gridlines stay
    * continuous across the row.
    */
    private String fillPhysicalRow(Map<Integer, String> cellsByPhysicalCol, Integer maxPhysicalCol, Integer rowNum, Map<Integer, Integer> styleOverride) {
        String cells = '';
        for (Integer p = 0; p <= maxPhysicalCol; p++) {
            if (cellsByPhysicalCol.containsKey(p)) {
                cells += cellsByPhysicalCol.get(p);
            } else {
                Integer style = (styleOverride != null && styleOverride.containsKey(p)) ? styleOverride.get(p) : 40;
                cells += blankCellXml(COLUMN_LETTERS[p], rowNum, style);
            }
        }
        return cells;
    }

    // ==================== Low-level row/cell XML builders ====================

    private String rowXml(Integer rowNum, String cellsXml) {
        return '<row r="' + rowNum + '">' + cellsXml + '</row>';
    }

    private String heightRow(Integer rowNum, Decimal height, String cellsXml) {
        return '<row r="' + rowNum + '" ht="' + height + '" customHeight="1">' + cellsXml + '</row>';
    }

    private String mergedRow(Integer rowNum, String mergeRef, Integer styleIdx, String value, List<String> mergeRefsAccumulator, Decimal height) {
        mergeRefsAccumulator.add(mergeRef);
        String col = mergeRef.substringBefore(':').replaceAll('[0-9]', '');
        String cellXml = textCellXml(col, rowNum, styleIdx, value);
        return height == null ? rowXml(rowNum, cellXml) : heightRow(rowNum, height, cellXml);
    }

    private String mergedRichRow(Integer rowNum, String mergeRef, Integer styleIdx, List<String> mergeRefsAccumulator, Decimal height, List<TextRun> runs) {
        mergeRefsAccumulator.add(mergeRef);
        String col = mergeRef.substringBefore(':').replaceAll('[0-9]', '');
        return heightRow(rowNum, height, richTextCellXml(col, rowNum, styleIdx, runs));
    }

    private String labelValueCell(String col, Integer rowNum, String label, String value) {
        return richTextCellXml(col, rowNum, 35, new List<TextRun>{
            new TextRun(label, 'Arial', 11, true, false),
            new TextRun(value, 'Arial', 11, false, false)
        });
    }

    private String richTextCellXml(String col, Integer rowNum, Integer styleIdx, List<TextRun> runs) {
        String runsXml = '';
        for (TextRun run : runs) {
            String rPr = '<rPr>';
            if (run.bold) rPr += '<b/>';
            if (run.italic) rPr += '<i/>';
            rPr += '<sz val="' + run.size + '"/><rFont val="' + run.fontName + '"/></rPr>';
            runsXml += '<r>' + rPr + '<t xml:space="preserve">' + DocxXmlRenderService.escXml(run.text) + '</t></r>';
        }
        return '<c r="' + col + rowNum + '" s="' + styleIdx + '" t="inlineStr"><is>' + runsXml + '</is></c>';
    }

    private String textCellXml(String col, Integer rowNum, Integer styleIdx, String value) {
        return '<c r="' + col + rowNum + '" s="' + styleIdx + '" t="inlineStr"><is><t xml:space="preserve">' +
            DocxXmlRenderService.escXml(value) + '</t></is></c>';
    }

    /**
    * A cell with only a style and no value. Excel only lets a neighboring cell's
    * text overflow into a cell that has no value at all — an empty inline string
    * still counts as occupied and clips the overflow.
    */
    private String blankCellXml(String col, Integer rowNum, Integer styleIdx) {
        return '<c r="' + col + rowNum + '" s="' + styleIdx + '"/>';
    }

    /**
    * The bold flag is informational only — actual weight comes from the styleIdx's font.
    */
    private String cellXml(String col, Integer rowNum, Integer styleIdx, String value, Boolean bold) {
        return textCellXml(col, rowNum, styleIdx, value);
    }

    private String formulaCurrencyCell(String col, Integer rowNum, Integer styleIdx, String formula) {
        return '<c r="' + col + rowNum + '" s="' + styleIdx + '"><f>' + formula + '</f></c>';
    }

    private String currencyCellStyled(String col, Integer rowNum, Integer styleIdx, Decimal value) {
        Decimal v = value == null ? 0 : value;
        return '<c r="' + col + rowNum + '" s="' + styleIdx + '"><v>' + v.setScale(2) + '</v></c>';
    }

    private String textCell(String col, Integer rowNum, String value) {
        return '<c r="' + col + rowNum + '" s="40" t="inlineStr"><is><t xml:space="preserve">' +
            DocxXmlRenderService.escXml(value) + '</t></is></c>';
    }

    private String currencyCell(String col, Integer rowNum, Decimal value) {
        Decimal v = value == null ? 0 : value;
        return '<c r="' + col + rowNum + '" s="2"><v>' + v.setScale(2) + '</v></c>';
    }

    /**
    * Computes a print scale percentage that fits the given column widths into a
    * target physical width, using Excel's column-width-to-pixel approximation
    * (pixels = width*7 + 5 per column, 96 px/inch). Clamped to 10-400.
    */
    private Integer computePrintScalePercent(List<Decimal> widths, Decimal targetInches) {
        Decimal totalWidthUnits = 0;
        Integer columnCount = 0;
        for (Decimal w : widths) {
            if (w != null) {
                totalWidthUnits += w;
                columnCount++;
            }
        }
        Decimal totalPixels = totalWidthUnits * 7 + columnCount * 5;
        Decimal totalInches = totalPixels / 96;
        Integer scale = (targetInches / totalInches * 100).setScale(0, System.RoundingMode.HALF_UP).intValue();
        return Math.max(10, Math.min(400, scale));
    }

    /**
    * Loads the Ministry logo static resource body. Returns null when unavailable.
    */
    private Blob getLogoBody() {
        List<StaticResource> resources = [
            SELECT Body FROM StaticResource WHERE Name = :DEFAULT_LOGO_STATIC_RESOURCE LIMIT 1
        ];
        return resources.isEmpty() ? null : resources[0].Body;
    }
}