@IsTest
private class DocxPackageServiceTest {
    @IsTest
    static void buildPackageCreatesDocxArchiveWithoutLogo() {
        Blob packageBlob = DocxPackageService.buildPackage(
            documentXml(),
            null,
            footerXml(),
            footerXml(),
            headerXml(),
            headerXml()
        );

        System.assertNotEquals(null, packageBlob, 'DOCX package should be generated.');
        System.assert(packageBlob.size() > 0, 'DOCX package should not be empty.');
    }

    @IsTest
    static void buildPackageCreatesDocxArchiveWithLogo() {
        Blob packageBlob = DocxPackageService.buildPackage(
            documentXml(),
            Blob.valueOf('fake-logo'),
            footerXml(),
            footerXml(),
            headerXml(),
            headerXml()
        );

        System.assertNotEquals(null, packageBlob, 'DOCX package with logo should be generated.');
        System.assert(packageBlob.size() > 0, 'DOCX package with logo should not be empty.');
    }

    private static String documentXml() {
        return DocgenConstants.XML_DECLARATION +
            '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">' +
            '<w:body><w:p/></w:body></w:document>';
    }

    private static String footerXml() {
        return DocgenConstants.XML_DECLARATION +
            '<w:ftr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:p/></w:ftr>';
    }

    private static String headerXml() {
        return DocgenConstants.XML_DECLARATION +
            '<w:hdr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:p/></w:hdr>';
    }
}