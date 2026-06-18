/**
 * DocxZipSealerQueueable
 * Final step in the async doc gen chain.
 * Reads the accumulated document XML from the temp ContentVersion,
 * appends closing tags, wraps in a .docx ZIP, stores the final file,
 * and cleans up the temp file.
 *
 * Heap: accumulated XML (up to ~30MB for 8,000 MSP rows) + ZipWriter
 * Note: For very large docs (>8,000 rows) the sealer itself may hit heap.
 * In that case the XML should be kept as a raw ContentVersion and the ZIP
 * step done server-side or the requirement re-evaluated.
 */
public class DocxZipSealerQueueable implements Queueable {

    private Id caseId;
    private Id tempCvDocId;

    public DocxZipSealerQueueable(Id caseId, Id tempCvDocId) {
        this.caseId       = caseId;
        this.tempCvDocId  = tempCvDocId;
    }

    public void execute(QueueableContext ctx) {
        try {
            // Read the accumulated XML from the temp ContentVersion
            ContentVersion tempCv = [
                SELECT VersionData, PathOnClient
                FROM ContentVersion
                WHERE ContentDocumentId = :tempCvDocId
                ORDER BY VersionNumber DESC LIMIT 1
            ];

            String fullXml = tempCv.VersionData.toString();

            // Seal the document XML with closing tags and section properties
            fullXml += closingXml();

            // Build the .docx ZIP
            Compression.ZipWriter zip = new Compression.ZipWriter();
            zip.addEntry('[Content_Types].xml', Blob.valueOf(contentTypes()));
            zip.addEntry('_rels/.rels',          Blob.valueOf(pkgRels()));
            zip.addEntry('word/_rels/document.xml.rels', Blob.valueOf(docRels()));
            zip.addEntry('word/document.xml',    Blob.valueOf(fullXml));
            zip.addEntry('word/styles.xml',      Blob.valueOf(styles()));
            zip.addEntry('word/footer1.xml',     Blob.valueOf(portraitFooter()));
            zip.addEntry('word/footer2.xml',     Blob.valueOf(landscapeFooter()));
            zip.addEntry('word/header1.xml',     Blob.valueOf(landscapeHeader()));
            zip.addEntry('docProps/core.xml',    Blob.valueOf(coreProps()));
            Blob docxBlob = zip.getArchive();

            // Get the Case number for the filename
            Case c = [SELECT CaseNumber FROM Case WHERE Id = :caseId LIMIT 1];
            String fileName = 'Ministers_Certificate_' + c.CaseNumber
                + '_' + Datetime.now().format('yyyyMMdd') + '.docx';

            ContentVersion finalCv = new ContentVersion();
            finalCv.Title                  = fileName;
            finalCv.PathOnClient           = fileName;
            finalCv.VersionData            = docxBlob;
            finalCv.FirstPublishLocationId = caseId;
            finalCv.SharingPrivacy         = 'N';
            insert finalCv;

            // Clean up temp file
            delete [SELECT Id FROM ContentDocument WHERE Id = :tempCvDocId];

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'DocxZipSealerQueueable failed: ' + e.getMessage()
                + '\n' + e.getStackTraceString());
        }
    }

    // ── Closing XML appended to the body ──────────────────────────────────────

    private String closingXml() {
        // Terminal blank para + landscape sectPr (Section 2)
        String rNs = 'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"';
        return '<w:p/>'
             + '<w:sectPr>'
             + '<w:footerReference w:type="default" r:id="rId3" ' + rNs + '/>'
             + '<w:footerReference w:type="even"    r:id="rId3" ' + rNs + '/>'
             + '<w:footerReference w:type="first"   r:id="rId3" ' + rNs + '/>'
             + '<w:headerReference w:type="default" r:id="rId4" ' + rNs + '/>'
             + '<w:headerReference w:type="even"    r:id="rId4" ' + rNs + '/>'
             + '<w:headerReference w:type="first"   r:id="rId4" ' + rNs + '/>'
             + '<w:pgSz w:w="15840" w:h="12240" w:orient="landscape"/>'
             + '<w:pgMar w:top="1134" w:right="1440" w:bottom="1797" w:left="1440"'
             + ' w:header="720" w:footer="576" w:gutter="0"/>'
             + '</w:sectPr>'
             + '</w:body></w:document>';
    }

    // ── Package parts (duplicated from DocxBuilder for self-contained sealer) ─

    private String contentTypes() {
        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
             + '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
             + '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
             + '<Default Extension="xml" ContentType="application/xml"/>'
             + '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
             + '<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>'
             + '<Override PartName="/word/footer1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/>'
             + '<Override PartName="/word/footer2.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/>'
             + '<Override PartName="/word/header1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml"/>'
             + '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>'
             + '</Types>';
    }

    private String pkgRels() {
        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
             + '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
             + '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
             + '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>'
             + '</Relationships>';
    }

    private String docRels() {
        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
             + '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
             + '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles"  Target="styles.xml"/>'
             + '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer"  Target="footer1.xml"/>'
             + '<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer"  Target="footer2.xml"/>'
             + '<Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/header"  Target="header1.xml"/>'
             + '</Relationships>';
    }

    private String styles() {
        String f = 'Times New Roman';
        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
             + '<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
             + '<w:docDefaults><w:rPrDefault><w:rPr>'
             + '<w:rFonts w:ascii="' + f + '" w:hAnsi="' + f + '" w:eastAsia="' + f + '" w:cs="' + f + '"/>'
             + '<w:sz w:val="22"/><w:lang w:val="en-US"/>'
             + '</w:rPr></w:rPrDefault></w:docDefaults>'
             + '<w:style w:type="paragraph" w:styleId="Normal" w:default="1"><w:name w:val="Normal"/>'
             + '<w:pPr><w:spacing w:after="0" w:line="240" w:lineRule="auto"/></w:pPr></w:style>'
             + '<w:style w:type="paragraph" w:styleId="Header"><w:name w:val="header"/><w:basedOn w:val="Normal"/></w:style>'
             + '<w:style w:type="paragraph" w:styleId="Footer"><w:name w:val="footer"/><w:basedOn w:val="Normal"/></w:style>'
             + '<w:style w:type="table" w:styleId="TableGrid"><w:name w:val="Table Grid"/>'
             + '<w:tblPr><w:tblBorders>'
             + '<w:top w:val="single" w:sz="4" w:space="0" w:color="auto"/>'
             + '<w:left w:val="single" w:sz="4" w:space="0" w:color="auto"/>'
             + '<w:bottom w:val="single" w:sz="4" w:space="0" w:color="auto"/>'
             + '<w:right w:val="single" w:sz="4" w:space="0" w:color="auto"/>'
             + '<w:insideH w:val="single" w:sz="4" w:space="0" w:color="auto"/>'
             + '<w:insideV w:val="single" w:sz="4" w:space="0" w:color="auto"/>'
             + '</w:tblBorders></w:tblPr></w:style>'
             + '</w:styles>';
    }

    private String coreProps() {
        String now = Datetime.now().format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
             + '<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"'
             + ' xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/"'
             + ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
             + '<dc:title>Minister\'s Certificate</dc:title>'
             + '<dc:creator>Ministry of Health</dc:creator>'
             + '<dcterms:created xsi:type="dcterms:W3CDTF">' + now + '</dcterms:created>'
             + '</cp:coreProperties>';
    }

    private String portraitFooter() {
        String f = 'Times New Roman';
        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
             + '<w:ftr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
             + '<w:p><w:pPr><w:pStyle w:val="Footer"/><w:jc w:val="right"/></w:pPr>'
             + '<w:r><w:rPr><w:rFonts w:ascii="' + f + '" w:hAnsi="' + f + '" w:cs="' + f + '"/>'
             + '<w:color w:val="000000"/></w:rPr><w:t>Internal</w:t></w:r>'
             + '</w:p></w:ftr>';
    }

    private String landscapeFooter() {
        String f = 'Times New Roman';
        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
             + '<w:ftr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
             + '<w:p><w:pPr><w:pStyle w:val="Footer"/><w:jc w:val="center"/></w:pPr>'
             + '<w:r><w:rPr><w:rFonts w:ascii="' + f + '" w:hAnsi="' + f + '" w:cs="' + f + '"/></w:rPr>'
             + '<w:t xml:space="preserve">Page </w:t></w:r>'
             + '<w:r><w:fldChar w:fldCharType="begin"/></w:r>'
             + '<w:r><w:instrText xml:space="preserve"> PAGE \\* MERGEFORMAT </w:instrText></w:r>'
             + '<w:r><w:fldChar w:fldCharType="separate"/></w:r>'
             + '<w:r><w:rPr><w:noProof/></w:rPr><w:t>1</w:t></w:r>'
             + '<w:r><w:fldChar w:fldCharType="end"/></w:r>'
             + '<w:r><w:rPr><w:rFonts w:ascii="' + f + '" w:hAnsi="' + f + '" w:cs="' + f + '"/></w:rPr>'
             + '<w:t xml:space="preserve"> of </w:t></w:r>'
             + '<w:r><w:fldChar w:fldCharType="begin"/></w:r>'
             + '<w:r><w:instrText xml:space="preserve"> NUMPAGES \\* Arabic \\* MERGEFORMAT </w:instrText></w:r>'
             + '<w:r><w:fldChar w:fldCharType="separate"/></w:r>'
             + '<w:r><w:rPr><w:noProof/></w:rPr><w:t>1</w:t></w:r>'
             + '<w:r><w:fldChar w:fldCharType="end"/></w:r>'
             + '</w:p>'
             + '<w:p><w:pPr><w:pStyle w:val="Footer"/><w:jc w:val="right"/></w:pPr>'
             + '<w:r><w:rPr><w:rFonts w:ascii="' + f + '" w:hAnsi="' + f + '" w:cs="' + f + '"/>'
             + '<w:color w:val="000000"/></w:rPr><w:t>Internal</w:t></w:r>'
             + '</w:p></w:ftr>';
    }

    private String landscapeHeader() {
        String f = 'Times New Roman';
        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
             + '<w:hdr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
             + '<w:p><w:pPr><w:pStyle w:val="Header"/><w:jc w:val="right"/></w:pPr>'
             + '<w:r><w:rPr><w:rFonts w:ascii="' + f + '" w:hAnsi="' + f + '" w:cs="' + f + '"/>'
             + '<w:color w:val="000000"/></w:rPr><w:t>Interim</w:t></w:r>'
             + '</w:p></w:hdr>';
    }
}
