@IsTest
private class DocxXmlRenderServiceTest {
    @IsTest
    static void escXmlEscapesReservedCharactersAndNull() {
        System.assertEquals('', DocxXmlRenderService.escXml(null), 'Null XML text should render as blank text.');
        System.assertEquals(
            'A&amp;B&lt;C&gt;&quot;D&apos;',
            DocxXmlRenderService.escXml('A&B<C>"D\''),
            'XML reserved characters should be escaped exactly once.'
        );
    }

    @IsTest
    static void daySuffixMatchesCertificateDateRules() {
        System.assertEquals('st', DocxXmlRenderService.daySuffix(1));
        System.assertEquals('nd', DocxXmlRenderService.daySuffix(2));
        System.assertEquals('rd', DocxXmlRenderService.daySuffix(3));
        System.assertEquals('th', DocxXmlRenderService.daySuffix(4));
        System.assertEquals('th', DocxXmlRenderService.daySuffix(11));
        System.assertEquals('th', DocxXmlRenderService.daySuffix(12));
        System.assertEquals('th', DocxXmlRenderService.daySuffix(13));
        System.assertEquals('st', DocxXmlRenderService.daySuffix(21));
        System.assertEquals('nd', DocxXmlRenderService.daySuffix(22));
        System.assertEquals('rd', DocxXmlRenderService.daySuffix(23));
        System.assertEquals('st', DocxXmlRenderService.daySuffix(31));
    }

    @IsTest
    static void xmlDeclarationRemainsDocxCompatible() {
        System.assertEquals(
            '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
            DocgenConstants.XML_DECLARATION,
            'DOCX package XML declaration should remain unchanged.'
        );
    }
}