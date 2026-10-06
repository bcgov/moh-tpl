/**
* Author: Nikhil Jeenru
* Company: CGI
* Purpose:
* Creates the internal XLSX package XML parts and ZIP structure.
* Parallel to DocxPackageService, using SpreadsheetML instead of WordprocessingML.
*/
public class XlsxPackageService {
    /**
    * Prevents this service class from being instantiated.
    */
    private XlsxPackageService() {}

    /**
    * One worksheet's name and pre-built <row> XML (without the surrounding <sheetData> wrapper).
    * mergeCellsRefs is an optional list of "A1:F1"-style ranges to merge on this sheet.
    * logoImage is optional; at most one sheet in a package should set it (the logo is
    * anchored top-left on that sheet via a SpreadsheetML drawing part).
    */
    public class Sheet {
        public String name;
        public String sheetDataXml;
        public List<String> mergeCellsRefs;
        public Blob logoImage;
        public Integer logoAnchorCol = 0;
        public Integer logoAnchorRow = 0;
        public List<Decimal> columnWidths;
        public Decimal defaultRowHeight;
        public Integer columnDefaultStyle;
        public Integer columnDefaultStyleLimit;
        public String pageOrientation = 'portrait';
        public Integer printScalePercent;

        public Sheet(String name, String sheetDataXml) {
            this.name = name;
            this.sheetDataXml = sheetDataXml;
            this.mergeCellsRefs = new List<String>();
        }

        public Sheet withMergeCells(List<String> refs) {
            this.mergeCellsRefs = refs;
            return this;
        }

        /**
        Params: String orientation
        * Sets this sheet's print orientation ('portrait' or 'landscape'). Returns this Sheet.
        */
        public Sheet withPageOrientation(String orientation) {
            this.pageOrientation = orientation;
            return this;
        }

        /**
        Params: Integer percent
        * Sets an explicit print zoom percentage (Excel's pageSetup scale, 10-400) instead
        * of fit-to-page scaling — used when the sheet needs a specific physical printed
        * width rather than "shrink to fit however many pages." Returns this Sheet.
        */
        public Sheet withPrintScale(Integer percent) {
            this.printScalePercent = percent;
            return this;
        }

        public Sheet withLogo(Blob image) {
            this.logoImage = image;
            return this;
        }

        /**
        Params: Integer col, Integer row
        * Sets the zero-based cell (col, row) the logo image is anchored at (default A1 / 0,0).
        */
        public Sheet withLogoAnchor(Integer col, Integer row) {
            this.logoAnchorCol = col;
            this.logoAnchorRow = row;
            return this;
        }

        /**
        Params: List<Decimal> widths
        * Sets explicit column widths, indexed from column A (widths[0] = A, widths[1] = B, ...).
        */
        public Sheet withColumnWidths(List<Decimal> widths) {
            this.columnWidths = widths;
            return this;
        }

        /**
        Params: Integer styleIdx
        * Sets a default cell style applied to every column (via <col style="X">). This
        * style is used by any cell in the column that has no <c> element at all (e.g. a
        * blank cell within a filled background range), since cell-level styles always
        * take precedence over the column default.
        */
        public Sheet withColumnDefaultStyle(Integer styleIdx) {
            this.columnDefaultStyle = styleIdx;
            return this;
        }

        /**
        Params: Integer count
        * Limits withColumnDefaultStyle to only the first `count` columns (0-based index
        * < count) in columnWidths; columns beyond that get no default style/fill at all.
        * Null (the default) applies the default style to every column, unchanged.
        */
        public Sheet withColumnDefaultStyleLimit(Integer count) {
            this.columnDefaultStyleLimit = count;
            return this;
        }

        /**
        Params: Decimal height
        * Sets the sheet-wide default row height (rows with no explicit height use this).
        */
        public Sheet withDefaultRowHeight(Decimal height) {
            this.defaultRowHeight = height;
            return this;
        }
    }

    /**
    Params: List<Sheet> sheets
    * Builds the XLSX ZIP package and returns the generated package Blob. Convenience
    * wrapper for callers that already hold every Sheet in memory at once; prefer
    * PackageBuilder (add sheets one at a time) when sheet XML should not all be
    * resident simultaneously.
    */
    public static Blob buildPackage(List<Sheet> sheets) {
        List<String> names = new List<String>();
        Boolean hasLogo = false;
        for (Sheet s : sheets) {
            names.add(s.name);
            if (s.logoImage != null) hasLogo = true;
        }
        PackageBuilder pkg = new PackageBuilder(names, hasLogo);
        for (Sheet s : sheets) {
            pkg.addSheet(s);
        }
        return pkg.finish();
    }

    /**
    * Streams an XLSX package one sheet at a time: each addSheet() call immediately
    * renders and zips that sheet's XML, so only one sheet's full row XML needs to be
    * resident in heap at a time rather than every sheet in the workbook at once. The
    * sheet count and logo presence must be known upfront (for [Content_Types].xml,
    * workbook.xml, and workbook.xml.rels) before any sheet's row XML is built.
    */
    public class PackageBuilder {
        private Compression.ZipWriter zip = new Compression.ZipWriter();
        private Integer nextSheetIndex = 1;

        public PackageBuilder(List<String> sheetNames, Boolean hasLogo) {
            Integer sheetCount = sheetNames.size();
            zip.addEntry('[Content_Types].xml',       Blob.valueOf(contentTypes(sheetCount, hasLogo)));
            zip.addEntry('_rels/.rels',                Blob.valueOf(rootRels()));
            zip.addEntry('xl/workbook.xml',            Blob.valueOf(workbook(sheetNames)));
            zip.addEntry('xl/_rels/workbook.xml.rels', Blob.valueOf(workbookRels(sheetCount)));
            zip.addEntry('xl/styles.xml',               Blob.valueOf(styles()));
        }

        /**
        Params: Sheet sheet
        * Renders and zips one sheet's worksheet XML (plus drawing parts, if this sheet
        * carries the logo). The caller's Sheet reference (and its full row XML string)
        * can be discarded immediately after this call returns.
        */
        public void addSheet(Sheet sheet) {
            Integer sheetIndex = nextSheetIndex++;
            Boolean hasDrawing = sheet.logoImage != null;
            zip.addEntry('xl/worksheets/sheet' + sheetIndex + '.xml', Blob.valueOf(worksheet(sheet, hasDrawing)));
            if (hasDrawing) {
                zip.addEntry('xl/worksheets/_rels/sheet' + sheetIndex + '.xml.rels', Blob.valueOf(worksheetDrawingRels()));
                zip.addEntry('xl/drawings/drawing1.xml',            Blob.valueOf(drawing(sheet.logoAnchorCol, sheet.logoAnchorRow)));
                zip.addEntry('xl/drawings/_rels/drawing1.xml.rels', Blob.valueOf(drawingRels()));
                zip.addEntry('xl/media/image1.png', sheet.logoImage);
            }
        }

        /**
        * Adds the remaining shared parts and returns the finished package Blob.
        */
        public Blob finish() {
            zip.addEntry('docProps/core.xml', Blob.valueOf(coreProps()));
            return zip.getArchive();
        }
    }

    /**
    Params: Integer sheetCount, Boolean includeDrawing
    * Builds XLSX content types XML. Returns the generated XML.
    */
    private static String contentTypes(Integer sheetCount, Boolean includeDrawing) {
        String overrides = '';
        for (Integer i = 1; i <= sheetCount; i++) {
            overrides += '<Override PartName="/xl/worksheets/sheet' + i + '.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>';
        }
        String drawingParts = '';
        if (includeDrawing) {
            drawingParts = '<Default Extension="png" ContentType="image/png"/>' +
                '<Override PartName="/xl/drawings/drawing1.xml" ContentType="application/vnd.openxmlformats-officedocument.drawing+xml"/>';
        }
        return DocgenConstants.XML_DECLARATION +
            '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' +
            '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' +
            '<Default Extension="xml" ContentType="application/xml"/>' +
            '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>' +
            '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>' +
            overrides +
            drawingParts +
            '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>' +
            '</Types>';
    }

    /**
    * Builds root relationship XML. Returns the generated XML.
    */
    private static String rootRels() {
        return DocgenConstants.XML_DECLARATION +
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
            '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>' +
            '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>' +
            '</Relationships>';
    }

    /**
    Params: List<String> sheetNames
    * Builds workbook.xml listing each sheet in order. Returns the generated XML.
    */
    private static String workbook(List<String> sheetNames) {
        String sheetEntries = '';
        for (Integer i = 0; i < sheetNames.size(); i++) {
            sheetEntries += '<sheet name="' + DocxXmlRenderService.escXml(sheetNames[i]) +
                '" sheetId="' + (i + 1) + '" r:id="rId' + (i + 1) + '"/>';
        }
        return DocgenConstants.XML_DECLARATION +
            '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">' +
            '<sheets>' + sheetEntries + '</sheets>' +
            '<calcPr fullCalcOnLoad="1"/>' +
            '</workbook>';
    }

    /**
    Params: Integer sheetCount
    * Builds workbook relationship XML (each sheet plus styles.xml). Returns the generated XML.
    */
    private static String workbookRels(Integer sheetCount) {
        String rels = '';
        for (Integer i = 1; i <= sheetCount; i++) {
            rels += '<Relationship Id="rId' + i + '" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet' + i + '.xml"/>';
        }
        rels += '<Relationship Id="rId' + (sheetCount + 1) + '" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>';
        return DocgenConstants.XML_DECLARATION +
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
            rels +
            '</Relationships>';
    }

    /**
    Params: Sheet sheet, Boolean hasDrawing
    * Wraps sheetData XML with the worksheet root element, optional column widths,
    * default row height, merged-cell ranges, and an optional drawing reference (for the
    * logo). Returns the generated XML.
    */
    private static String worksheet(Sheet sheet, Boolean hasDrawing) {
        String sheetFormatXml = '';
        if (sheet.defaultRowHeight != null) {
            sheetFormatXml = '<sheetFormatPr defaultRowHeight="' + sheet.defaultRowHeight + '" customHeight="1"/>';
        }

        String colsXml = '';
        if (sheet.columnWidths != null && !sheet.columnWidths.isEmpty()) {
            String cols = '';
            for (Integer i = 0; i < sheet.columnWidths.size(); i++) {
                Boolean withinStyleLimit = sheet.columnDefaultStyleLimit == null || i < sheet.columnDefaultStyleLimit;
                String styleAttr = (sheet.columnDefaultStyle != null && withinStyleLimit) ? ' style="' + sheet.columnDefaultStyle + '"' : '';
                if (sheet.columnWidths[i] != null) {
                    cols += '<col min="' + (i + 1) + '" max="' + (i + 1) + '" width="' + sheet.columnWidths[i] + '" customWidth="1"' + styleAttr + '/>';
                } else if (String.isNotBlank(styleAttr)) {
                    cols += '<col min="' + (i + 1) + '" max="' + (i + 1) + '"' + styleAttr + '/>';
                }
            }
            colsXml = '<cols>' + cols + '</cols>';
        }

        String mergeCellsXml = '';
        if (sheet.mergeCellsRefs != null && !sheet.mergeCellsRefs.isEmpty()) {
            String refs = '';
            for (String ref : sheet.mergeCellsRefs) {
                refs += '<mergeCell ref="' + ref + '"/>';
            }
            mergeCellsXml = '<mergeCells count="' + sheet.mergeCellsRefs.size() + '">' + refs + '</mergeCells>';
        }
        String drawingXml = hasDrawing ? '<drawing r:id="rId1"/>' : '';
        // Sheets with an explicit printScalePercent (a computed zoom % that prints the
        // grid at a specific physical width) use a fixed <pageSetup scale>. Sheets
        // without one (the Certificate) instead use sheetPr's pageSetUpPr fitToPage="1"
        // plus pageSetup fitToWidth="1" fitToHeight="0" — "shrink to 1 page wide,
        // however many pages tall" — since there's no target physical width for it.
        String sheetPrXml = sheet.printScalePercent == null ? '<sheetPr><pageSetUpPr fitToPage="1"/></sheetPr>' : '';
        String pageSetupAttrs = sheet.printScalePercent != null
            ? 'scale="' + sheet.printScalePercent + '"'
            : 'fitToWidth="1" fitToHeight="0"';
        String printSetupXml = '<pageMargins left="0.7" right="0.7" top="0.75" bottom="0.75" header="0.3" footer="0.3"/>' +
            '<pageSetup orientation="' + sheet.pageOrientation + '" ' + pageSetupAttrs + '/>';
        // Preset footer matching Excel's built-in "Page 1, [filename]" combo: &P is the
        // page number, &F is the workbook's actual saved file name (which already
        // carries the generation date, e.g. "Minister's Certificate September 10,
        // 2026.xlsx"), centered. The literal "&" in each field code is escaped as
        // "&amp;" here because this is XML text content, not a formatting exemption —
        // Excel's own writer does the same when you inspect a saved file's raw XML.
        String headerFooterXml = '<headerFooter><oddFooter>&amp;CPage &amp;P, &amp;F</oddFooter></headerFooter>';
        return DocgenConstants.XML_DECLARATION +
            '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">' +
            sheetPrXml +
            sheetFormatXml +
            colsXml +
            '<sheetData>' + sheet.sheetDataXml + '</sheetData>' +
            mergeCellsXml +
            printSetupXml +
            headerFooterXml +
            drawingXml +
            '</worksheet>';
    }

    /**
    * Builds the worksheet-to-drawing relationship XML for the sheet that carries the logo.
    * Returns the generated XML.
    */
    private static String worksheetDrawingRels() {
        return DocgenConstants.XML_DECLARATION +
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
            '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/drawing" Target="../drawings/drawing1.xml"/>' +
            '</Relationships>';
    }

    /**
    Params: Integer anchorCol, Integer anchorRow
    * Builds the drawing XML that anchors the logo image at the given zero-based cell.
    * Returns the generated XML.
    */
    private static String drawing(Integer anchorCol, Integer anchorRow) {
        return DocgenConstants.XML_DECLARATION +
            '<xdr:wsDr xmlns:xdr="http://schemas.openxmlformats.org/drawingml/2006/spreadsheetDrawing" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">' +
            '<xdr:oneCellAnchor>' +
            '<xdr:from><xdr:col>' + anchorCol + '</xdr:col><xdr:colOff>0</xdr:colOff><xdr:row>' + anchorRow + '</xdr:row><xdr:rowOff>0</xdr:rowOff></xdr:from>' +
            '<xdr:ext cx="1714500" cy="647700"/>' +
            '<xdr:pic>' +
            '<xdr:nvPicPr><xdr:cNvPr id="1" name="Logo"/><xdr:cNvPicPr/></xdr:nvPicPr>' +
            '<xdr:blipFill><a:blip xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" r:embed="rId1"/><a:stretch><a:fillRect/></a:stretch></xdr:blipFill>' +
            '<xdr:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="1714500" cy="647700"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></xdr:spPr>' +
            '</xdr:pic>' +
            '<xdr:clientData/>' +
            '</xdr:oneCellAnchor>' +
            '</xdr:wsDr>';
    }

    /**
    * Builds the drawing-to-image relationship XML. Returns the generated XML.
    */
    private static String drawingRels() {
        return DocgenConstants.XML_DECLARATION +
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
            '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="../media/image1.png"/>' +
            '</Relationships>';
    }

    /**
    * Builds XLSX core properties XML. Returns the generated XML.
    */
    private static String coreProps() {
        String now = Datetime.now().format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        return DocgenConstants.XML_DECLARATION +
            '<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"' +
            ' xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/"' +
            ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' +
            '<dc:title>Healthcare Cost Export</dc:title>' +
            '<dc:creator>Ministry of Health</dc:creator>' +
            '<dcterms:created xsi:type="dcterms:W3CDTF">' + now + '</dcterms:created>' +
            '</cp:coreProperties>';
    }

    /**
    * Styles referenced by XlsxBuilder via the s="n" attribute. Fonts (0-11):
    * 0=Arial 9, 1=Arial 9 bold, 2=Arial 14 bold, 3=Times New Roman 11,
    * 4=Times New Roman 11 bold, 5=Times New Roman 11 italic, 6=Arial 11 bold,
    * 7=Arial 11 bold, 8=Arial 11, 9=Arial 12 bold, 10=Arial 10, 11=Helvetica 16 bold.
    *
    * cellXfs (0-19):
    * 0 = default body text (Arial 9)
    * 1 = bold header (Arial 9 bold) — data tab column headers
    * 2 = currency (numFmtId 164, Arial 9)
    * 3 = certificate title (Arial 14 bold, centered)
    * 4 = centered plain text (Arial 9, centered)
    * 5 = wrapped body text (Arial 9, left, wrap)
    * 6 = certificate paragraph base (Times 11, left, top, wrap) — run-level overrides apply
    * 7 = certificate (a)/(b) item label (Times 11, center, top)
    * 8 = certificate "Case #:" label (Arial 11 bold, left)
    * 9 = certificate "Case #:" value (Arial 11, left)
    * 10 = certificate signature name/title lines (Times 11, left)
    * 11 = summary title (Arial 14 bold, center + vcenter)
    * 12 = summary section header (Arial 12 bold, vcenter) — "Past Costs of Healthcare Services"
    * 13 = summary case-info label (Arial 11 bold, vcenter)
    * 14 = summary line-item label (Arial 11, vcenter, wrap)
    * 15 = summary line-item currency (Arial 11, right, vcenter, wrap, numFmtId 165)
    * 16 = summary total-row label (Arial 12 bold, vcenter)
    * 17 = summary total-row currency (Arial 12 bold, right, vcenter, numFmtId 165)
    * 18 = summary underline total (Arial 11 bold, right, vcenter)
    * 19 = data tab header block / section label (Arial 11 bold, vcenter)
    * 20 = summary line-item label, no wrap (Arial 11, vcenter) — e.g. the discount line
    * 21 = data tab header block base for rich text (Arial 10, vcenter) — run-level overrides apply
    * 36 = data tab title (Helvetica 16 bold, center + vcenter) — "Healthcare Services and Costs Record Part 1"
    * 37 = data tab "Cost" column header (Arial 9 bold, right-aligned)
    * 38 = data tab total-row label, not bold (Arial 11, left, vcenter)
    * 39 = data tab total-row currency, not bold, left-aligned (Arial 11, numFmtId 165)
    * 40 = data tab bordered plain text / blank gap-fill cell (Arial 9, borderId 1)
    * 41 = data tab plain text, left edge of a grouped-cell box (Arial 9, borderId 2)
    * 42 = data tab plain/blank, right edge of a grouped-cell box (Arial 9, borderId 3)
    * 43 = data tab bold header, left edge of a grouped-cell box (Arial 9 bold, borderId 2)
    * 44 = data tab bold header, middle of a grouped-cell box (Arial 9 bold, borderId 4)
    * 45 = data tab plain/blank, middle of a grouped-cell box (Arial 9, borderId 4)
    * 46 = data tab bold header, right edge of a grouped-cell box (Arial 9 bold, borderId 3)
    *
    * Styles 1 (header), 2 (currency), 5 (wrapped text), and 37 (Cost header) all carry
    * borderId 1 (thin black, ~0.5pt) for the healthcare cost tabs' table gridlines.
    */
    private static String styles() {
        return DocgenConstants.XML_DECLARATION +
            '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">' +
            '<numFmts count="2">' +
            '<numFmt numFmtId="164" formatCode="&quot;$&quot;#,##0.00"/>' +
            '<numFmt numFmtId="165" formatCode="&quot;$&quot;#,##0.00;[Red]\\-&quot;$&quot;#,##0.00"/>' +
            '</numFmts>' +
            '<fonts count="13">' +
            '<font><sz val="9"/><name val="Arial"/></font>' +
            '<font><b/><sz val="9"/><name val="Arial"/></font>' +
            '<font><b/><sz val="14"/><name val="Arial"/></font>' +
            '<font><sz val="11"/><name val="Times New Roman"/></font>' +
            '<font><b/><sz val="11"/><name val="Times New Roman"/></font>' +
            '<font><i/><sz val="11"/><name val="Times New Roman"/></font>' +
            '<font><b/><sz val="11"/><name val="Arial"/></font>' +
            '<font><b/><sz val="11"/><name val="Arial"/></font>' +
            '<font><sz val="11"/><name val="Arial"/></font>' +
            '<font><b/><sz val="12"/><name val="Arial"/></font>' +
            '<font><sz val="10"/><name val="Arial"/></font>' +
            '<font><b/><sz val="16"/><name val="Helvetica"/></font>' +
            '<font><b/><sz val="14.49"/><name val="Arial"/></font>' +
            '</fonts>' +
            '<fills count="3">' +
            '<fill><patternFill patternType="none"/></fill>' +
            '<fill><patternFill patternType="gray125"/></fill>' +
            '<fill><patternFill patternType="solid"><fgColor rgb="FFFFFFFF"/><bgColor indexed="64"/></patternFill></fill>' +
            '</fills>' +
            '<borders count="5">' +
            '<border><left/><right/><top/><bottom/><diagonal/></border>' +
            '<border><left style="thin"><color rgb="FF000000"/></left><right style="thin"><color rgb="FF000000"/></right>' +
            '<top style="thin"><color rgb="FF000000"/></top><bottom style="thin"><color rgb="FF000000"/></bottom><diagonal/></border>' + // 1 (thin black, 0.5pt table gridlines, all 4 sides)
            '<border><left style="thin"><color rgb="FF000000"/></left><right/>' +
            '<top style="thin"><color rgb="FF000000"/></top><bottom style="thin"><color rgb="FF000000"/></bottom><diagonal/></border>' + // 2 (left/top/bottom only — left edge of a grouped-cell box)
            '<border><left/><right style="thin"><color rgb="FF000000"/></right>' +
            '<top style="thin"><color rgb="FF000000"/></top><bottom style="thin"><color rgb="FF000000"/></bottom><diagonal/></border>' + // 3 (right/top/bottom only — right edge of a grouped-cell box)
            '<border><left/><right/>' +
            '<top style="thin"><color rgb="FF000000"/></top><bottom style="thin"><color rgb="FF000000"/></bottom><diagonal/></border>' + // 4 (top/bottom only — middle of a 3+ column grouped-cell box)
            '</borders>' +
            '<cellStyleXfs count="1">' +
            '<xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>' +
            '</cellStyleXfs>' +
            '<cellXfs count="50">' +
            '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>' +                                                          // 0
            '<xf numFmtId="0" fontId="1" fillId="0" borderId="1" xfId="0" applyFont="1" applyBorder="1" applyAlignment="1"><alignment vertical="top"/></xf>' +                            // 1 (data tab header, now bordered, top-aligned)
            '<xf numFmtId="164" fontId="0" fillId="0" borderId="1" xfId="0" applyNumberFormat="1" applyBorder="1" applyAlignment="1"><alignment vertical="top"/></xf>' +                  // 2 (data tab currency, now bordered, top-aligned)
            '<xf numFmtId="0" fontId="2" fillId="0" borderId="0" xfId="0" applyFont="1"><alignment horizontal="center"/></xf>' +       // 3
            '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"><alignment horizontal="center"/></xf>' +                     // 4
            '<xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyBorder="1" applyAlignment="1"><alignment horizontal="left" vertical="top" wrapText="1"/></xf>' + // 5 (data tab wrapped text, now bordered, top-aligned)
            '<xf numFmtId="0" fontId="3" fillId="0" borderId="0" xfId="0" applyFont="1" applyAlignment="1"><alignment horizontal="left" vertical="top" wrapText="1"/></xf>' + // 6
            '<xf numFmtId="0" fontId="3" fillId="0" borderId="0" xfId="0" applyFont="1" applyAlignment="1"><alignment horizontal="center" vertical="top"/></xf>' + // 7
            '<xf numFmtId="0" fontId="7" fillId="0" borderId="0" xfId="0" applyFont="1" applyAlignment="1"><alignment horizontal="left"/></xf>' + // 8
            '<xf numFmtId="0" fontId="8" fillId="0" borderId="0" xfId="0" applyFont="1" applyAlignment="1"><alignment horizontal="left"/></xf>' + // 9
            '<xf numFmtId="0" fontId="3" fillId="0" borderId="0" xfId="0" applyFont="1"/>' +                                           // 10
            '<xf numFmtId="0" fontId="2" fillId="0" borderId="0" xfId="0" applyFont="1" applyAlignment="1"><alignment horizontal="center" vertical="center"/></xf>' + // 11
            '<xf numFmtId="0" fontId="9" fillId="0" borderId="0" xfId="0" applyFont="1" applyAlignment="1"><alignment vertical="center"/></xf>' + // 12
            '<xf numFmtId="0" fontId="7" fillId="0" borderId="0" xfId="0" applyFont="1" applyAlignment="1"><alignment vertical="center"/></xf>' + // 13
            '<xf numFmtId="0" fontId="8" fillId="0" borderId="0" xfId="0" applyFont="1" applyAlignment="1"><alignment vertical="center" wrapText="1"/></xf>' + // 14
            '<xf numFmtId="165" fontId="8" fillId="0" borderId="0" xfId="0" applyFont="1" applyNumberFormat="1" applyAlignment="1"><alignment horizontal="right" vertical="center" wrapText="1"/></xf>' + // 15
            '<xf numFmtId="0" fontId="9" fillId="0" borderId="0" xfId="0" applyFont="1" applyAlignment="1"><alignment vertical="center"/></xf>' + // 16
            '<xf numFmtId="165" fontId="9" fillId="0" borderId="0" xfId="0" applyFont="1" applyNumberFormat="1" applyAlignment="1"><alignment horizontal="right" vertical="center"/></xf>' + // 17
            '<xf numFmtId="0" fontId="7" fillId="0" borderId="0" xfId="0" applyFont="1" applyAlignment="1"><alignment horizontal="right" vertical="center"/></xf>' + // 18
            '<xf numFmtId="0" fontId="6" fillId="0" borderId="0" xfId="0" applyFont="1" applyAlignment="1"><alignment vertical="center"/></xf>' + // 19
            '<xf numFmtId="0" fontId="8" fillId="0" borderId="0" xfId="0" applyFont="1" applyAlignment="1"><alignment vertical="center"/></xf>' + // 20
            '<xf numFmtId="0" fontId="10" fillId="0" borderId="0" xfId="0" applyFont="1" applyAlignment="1"><alignment vertical="center"/></xf>' + // 21
            '<xf numFmtId="0" fontId="0" fillId="2" borderId="0" xfId="0" applyFill="1"/>' + // 22 (white-fill: default)
            '<xf numFmtId="0" fontId="2" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment horizontal="center"/></xf>' + // 23 (white-fill: title)
            '<xf numFmtId="0" fontId="3" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment horizontal="left" vertical="top" wrapText="1"/></xf>' + // 24 (white-fill: cert paragraph)
            '<xf numFmtId="0" fontId="7" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment horizontal="left"/></xf>' + // 25 (white-fill: cert Case# label)
            '<xf numFmtId="0" fontId="8" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment horizontal="left"/></xf>' + // 26 (white-fill: cert Case# value)
            '<xf numFmtId="0" fontId="3" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1"/>' + // 27 (white-fill: cert signature lines)
            '<xf numFmtId="0" fontId="2" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment horizontal="center" vertical="center"/></xf>' + // 28 (white-fill: summary title)
            '<xf numFmtId="0" fontId="9" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment vertical="center"/></xf>' + // 29 (white-fill: summary section header)
            '<xf numFmtId="0" fontId="8" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment vertical="center" wrapText="1"/></xf>' + // 30 (white-fill: summary line-item label)
            '<xf numFmtId="165" fontId="8" fillId="2" borderId="0" xfId="0" applyFont="1" applyNumberFormat="1" applyFill="1" applyAlignment="1"><alignment horizontal="right" vertical="center" wrapText="1"/></xf>' + // 31 (white-fill: summary line-item currency)
            '<xf numFmtId="0" fontId="9" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment vertical="center"/></xf>' + // 32 (white-fill: summary total-row label)
            '<xf numFmtId="165" fontId="9" fillId="2" borderId="0" xfId="0" applyFont="1" applyNumberFormat="1" applyFill="1" applyAlignment="1"><alignment horizontal="right" vertical="center"/></xf>' + // 33 (white-fill: summary total-row currency)
            '<xf numFmtId="0" fontId="7" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment horizontal="right" vertical="center"/></xf>' + // 34 (white-fill: summary underline total)
            '<xf numFmtId="0" fontId="8" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment vertical="center"/></xf>' + // 35 (white-fill: summary label/value base)
            '<xf numFmtId="0" fontId="11" fillId="0" borderId="0" xfId="0" applyFont="1" applyAlignment="1"><alignment horizontal="center" vertical="center"/></xf>' + // 36 (data tab title: 16pt bold Helvetica, centered)
            '<xf numFmtId="0" fontId="1" fillId="0" borderId="1" xfId="0" applyFont="1" applyBorder="1" applyAlignment="1"><alignment horizontal="right" vertical="top"/></xf>' + // 37 (data tab "Cost" header, bold, right-aligned, bordered, top-aligned)
            '<xf numFmtId="0" fontId="8" fillId="0" borderId="0" xfId="0" applyFont="1" applyAlignment="1"><alignment horizontal="left" vertical="center"/></xf>' + // 38 (data tab total-row label, not bold, left-aligned)
            '<xf numFmtId="165" fontId="8" fillId="0" borderId="0" xfId="0" applyFont="1" applyNumberFormat="1" applyAlignment="1"><alignment horizontal="left" vertical="center"/></xf>' + // 39 (data tab total-row currency, not bold, left-aligned)
            '<xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyBorder="1" applyAlignment="1"><alignment vertical="top"/></xf>' + // 40 (data tab bordered plain text / blank gap-fill cell, top-aligned)
            '<xf numFmtId="0" fontId="0" fillId="0" borderId="2" xfId="0" applyBorder="1" applyAlignment="1"><alignment vertical="top"/></xf>' + // 41 (plain text, left edge of a grouped-cell box, top-aligned)
            '<xf numFmtId="0" fontId="0" fillId="0" borderId="3" xfId="0" applyBorder="1" applyAlignment="1"><alignment vertical="top"/></xf>' + // 42 (plain/blank, right edge of a grouped-cell box, top-aligned)
            '<xf numFmtId="0" fontId="1" fillId="0" borderId="2" xfId="0" applyFont="1" applyBorder="1" applyAlignment="1"><alignment vertical="top"/></xf>' + // 43 (bold header, left edge of a grouped-cell box, top-aligned)
            '<xf numFmtId="0" fontId="1" fillId="0" borderId="4" xfId="0" applyFont="1" applyBorder="1" applyAlignment="1"><alignment vertical="top"/></xf>' + // 44 (bold header, middle of a grouped-cell box, top-aligned)
            '<xf numFmtId="0" fontId="0" fillId="0" borderId="4" xfId="0" applyBorder="1" applyAlignment="1"><alignment vertical="top"/></xf>' + // 45 (plain text, middle of a grouped-cell box, top-aligned)
            '<xf numFmtId="0" fontId="1" fillId="0" borderId="3" xfId="0" applyFont="1" applyBorder="1" applyAlignment="1"><alignment vertical="top"/></xf>' + // 46 (bold header, right edge of a grouped-cell box, top-aligned)
            '<xf numFmtId="0" fontId="3" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment horizontal="center" vertical="top"/></xf>' + // 47 (white-fill: cert item-letter label, centered, top-aligned)
            '<xf numFmtId="0" fontId="3" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment horizontal="right" vertical="top"/></xf>' + // 48 (white-fill: cert item-letter label, right-aligned, top-aligned)
            '<xf numFmtId="0" fontId="12" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment horizontal="center"/></xf>' + // 49 (white-fill: cert title, 14.49pt bold: 14pt -10% then +15%)
            '</cellXfs>' +
            '<cellStyles count="1">' +
            '<cellStyle name="Normal" xfId="0" builtinId="0"/>' +
            '</cellStyles>' +
            '</styleSheet>';
    }
}