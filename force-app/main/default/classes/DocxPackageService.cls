/**
* Author: Nikhil Jeenru
* Company: CGI
* Purpose:
* Creates the internal DOCX package XML parts and ZIP structure.
*/
public class DocxPackageService {
    /**
* Prevents this service class from being instantiated.
*/
    private DocxPackageService() {}
    
    /**
Params: String documentXml, Blob logo, String portraitFooterXml, String landscapeFooterXml, String landscapeHeaderXml, String portraitHeaderXml
* Builds the DOCX ZIP package and returns the generated package Blob.
*/
    public static Blob buildPackage(
        String documentXml,
        Blob logo,
        String portraitFooterXml,
        String landscapeFooterXml,
        String landscapeHeaderXml,
        String portraitHeaderXml
    ) {
        Compression.ZipWriter zip = new Compression.ZipWriter();
        Boolean includeLogo = logo != null;
        
        zip.addEntry('[Content_Types].xml',          Blob.valueOf(contentTypes(includeLogo)));
        zip.addEntry('_rels/.rels',                  Blob.valueOf(rels()));
        zip.addEntry('word/_rels/document.xml.rels', Blob.valueOf(docRels(includeLogo)));
        zip.addEntry('word/document.xml',            Blob.valueOf(documentXml));
        zip.addEntry('word/styles.xml',              Blob.valueOf(styles()));
        zip.addEntry('word/footer1.xml',             Blob.valueOf(portraitFooterXml));
        zip.addEntry('word/footer2.xml',             Blob.valueOf(landscapeFooterXml));
        zip.addEntry('word/header1.xml',             Blob.valueOf(landscapeHeaderXml));
        zip.addEntry('word/header2.xml',             Blob.valueOf(portraitHeaderXml));
        if (includeLogo) {
            zip.addEntry('word/media/image1.png', logo);
        }
        zip.addEntry('docProps/core.xml',            Blob.valueOf(coreProps()));
        return zip.getArchive();
    }
    
    /**
Params: Boolean includeLogo
* Builds DOCX content types XML. Returns the generated XML.
*/
    private static String contentTypes(Boolean includeLogo) {
        String defaults = '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' +
            '<Default Extension="xml" ContentType="application/xml"/>';
        if (includeLogo) {
            defaults += '<Default Extension="png" ContentType="image/png"/>';
        }
        return DocgenConstants.XML_DECLARATION +
            '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' +
            defaults +
            '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>' +
            '<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>' +
            '<Override PartName="/word/footer1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/>' +
            '<Override PartName="/word/footer2.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/>' +
            '<Override PartName="/word/header1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml"/>' +
            '<Override PartName="/word/header2.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml"/>' +
            '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>' +
            '</Types>';
    }
    
    /**
* Builds root relationship XML. Returns the generated XML.
*/
    private static String rels() {
        return DocgenConstants.XML_DECLARATION +
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
            '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>' +
            '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>' +
            '</Relationships>';
    }
    
    /**
Params: Boolean includeLogo
* Builds document relationship XML. Returns the generated XML.
*/
    private static String docRels(Boolean includeLogo) {
        String imageRel = includeLogo
            ? '<Relationship Id="rId6" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/image1.png"/>'
            : '';
        return DocgenConstants.XML_DECLARATION +
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
            '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles"  Target="styles.xml"/>' +
            '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer"  Target="footer1.xml"/>' +
            '<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer"  Target="footer2.xml"/>' +
            '<Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/header"  Target="header1.xml"/>' +
            '<Relationship Id="rId5" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/header"  Target="header2.xml"/>' +
            imageRel +
            '</Relationships>';
    }
    
    /**
* Builds DOCX core properties XML. Returns the generated XML.
*/
    private static String coreProps() {
        String now = Datetime.now().format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        return DocgenConstants.XML_DECLARATION +
            '<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"' +
            ' xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/"' +
            ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' +
            '<dc:title>Minister\'s Certificate</dc:title>' +
            '<dc:creator>Ministry of Health</dc:creator>' +
            '<dcterms:created xsi:type="dcterms:W3CDTF">' + now + '</dcterms:created>' +
            '</cp:coreProperties>';
    }
    
    /**
* Styles: Arial 9pt document default (matches original Normal style).
* Body text runs explicitly override to Times New Roman via DocxBuilder run helpers.
* TableGrid border sz=2 (0.25pt hairline — matches original visual weight).
* Summary tables reference TableGrid but override borders to val=none
* (matches template: borders present in style but suppressed on table).
*/
    private static String styles() {
        return DocgenConstants.XML_DECLARATION +
            '<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">' +
            '<w:docDefaults><w:rPrDefault><w:rPr>' +
            '<w:rFonts w:ascii="' + DocgenConstants.ARIAL_FONT_NAME + '" w:hAnsi="' + DocgenConstants.ARIAL_FONT_NAME + '" w:eastAsia="' + DocgenConstants.ARIAL_FONT_NAME + '" w:cs="' + DocgenConstants.ARIAL_FONT_NAME + '"/>' +
            '<w:lang w:val="en-CA"/>' +
            '</w:rPr></w:rPrDefault></w:docDefaults>' +
            '<w:style w:type="paragraph" w:styleId="Normal" w:default="1">' +
            '<w:name w:val="Normal"/>' +
            '<w:pPr><w:spacing w:after="0" w:line="240" w:lineRule="auto"/></w:pPr>' +
            '<w:rPr>' +
            '<w:rFonts w:ascii="' + DocgenConstants.ARIAL_FONT_NAME + '" w:hAnsi="' + DocgenConstants.ARIAL_FONT_NAME + '" w:cs="' + DocgenConstants.ARIAL_FONT_NAME + '"/>' +
            '<w:sz w:val="18"/><w:szCs w:val="18"/>' +
            '<w:lang w:val="en-CA"/>' +
            '</w:rPr>' +
            '</w:style>' +
            '<w:style w:type="paragraph" w:styleId="Header">' +
            '<w:name w:val="header"/><w:basedOn w:val="Normal"/>' +
            '</w:style>' +
            '<w:style w:type="table" w:styleId="TableGrid">' +
            '<w:name w:val="Table Grid"/>' +
            '<w:tblPr><w:tblBorders>' +
            '<w:top w:val="single" w:sz="2" w:space="0" w:color="auto"/>' +
            '<w:left w:val="single" w:sz="2" w:space="0" w:color="auto"/>' +
            '<w:bottom w:val="single" w:sz="2" w:space="0" w:color="auto"/>' +
            '<w:right w:val="single" w:sz="2" w:space="0" w:color="auto"/>' +
            '<w:insideH w:val="single" w:sz="2" w:space="0" w:color="auto"/>' +
            '<w:insideV w:val="single" w:sz="2" w:space="0" w:color="auto"/>' +
            '</w:tblBorders></w:tblPr>' +
            '</w:style>' +
            '</w:styles>';
    }
}