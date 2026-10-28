@IsTest
private class XlsxPackageServiceTest {
    @IsTest
    static void buildPackageCreatesXlsxArchiveWithSingleSheet() {
        List<XlsxPackageService.Sheet> sheets = new List<XlsxPackageService.Sheet>{
            new XlsxPackageService.Sheet('Summary', '<row r="1"><c r="A1" t="inlineStr"><is><t>Hello</t></is></c></row>')
        };

        Blob packageBlob = XlsxPackageService.buildPackage(sheets);

        System.assertNotEquals(null, packageBlob, 'XLSX package should be generated.');
        System.assert(packageBlob.size() > 0, 'XLSX package should not be empty.');
    }

    @IsTest
    static void buildPackageCreatesXlsxArchiveWithMultipleSheets() {
        List<XlsxPackageService.Sheet> sheets = new List<XlsxPackageService.Sheet>{
            new XlsxPackageService.Sheet('Summary', '<row r="1"><c r="A1" t="inlineStr"><is><t>Case</t></is></c></row>'),
            new XlsxPackageService.Sheet('Ambulance', '<row r="1"><c r="A1" t="inlineStr"><is><t>Date</t></is></c></row><row r="2"><c r="A2"><v>10</v></c></row>')
        };

        Blob packageBlob = XlsxPackageService.buildPackage(sheets);

        System.assertNotEquals(null, packageBlob, 'Multi-sheet XLSX package should be generated.');
        System.assert(packageBlob.size() > 0, 'Multi-sheet XLSX package should not be empty.');
    }
}