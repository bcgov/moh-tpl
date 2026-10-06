@IsTest
private class XlsxBuilderTest {

    @IsTest
    static void buildCreatesXlsxBlobWithOnlySummarySheetWhenNoRows() {
        // No healthcare rows supplied: only the Summary sheet should be built.
        Case c = DocxTestDataFactory.createCaseRecord();

        Test.startTest();
        Blob xlsx = new XlsxBuilder().setCaseData(c).build();
        Test.stopTest();

        System.assertNotEquals(null, xlsx, 'XlsxBuilder should return a non-null XLSX blob.');
        System.assert(xlsx.size() > 0, 'XlsxBuilder should generate a non-empty XLSX blob.');
    }

    @IsTest
    static void buildWithAllHealthcareCostTypesCreatesAllSheets() {
        // Every supported cost type has at least one row, so every optional sheet
        // should be included in the generated package.
        Case c = DocxTestDataFactory.createCaseRecord();

        XlsxBuilder builder = new XlsxBuilder()
            .setCaseData(c)
            .setAmbulanceRecords(ambulanceRows())
            .setHospitalRecords(hospitalRows())
            .setMSPRecords(mspRows())
            .setPharmaRecords(pharmaRows())
            .setContinuingCareRecords(continuingCareRows())
            .setFutureCareRecords(futureCareRows());

        Test.startTest();
        Blob xlsx = builder.build();
        Test.stopTest();

        System.assert(xlsx.size() > 0, 'XLSX with all healthcare cost sections should be generated.');
    }

    @IsTest
    static void nullAndFallbackValuesBuildSuccessfully() {
        // Defensive-input coverage: blank/override-null fields should not break generation.
        Case c = DocxTestDataFactory.createCaseRecord();

        List<Healthcare_Cost__c> fallbackAmbulance = new List<Healthcare_Cost__c>{
            new Healthcare_Cost__c(
                Date_of_Service__c = Date.today(),
                Location_Responded__c = null,
                Facility_Name__c = 'Fallback Destination',
                Total_Cost_Override__c = null
            )
        };

        XlsxBuilder builder = new XlsxBuilder()
            .setCaseData(c)
            .setAmbulanceRecords(fallbackAmbulance)
            .setHospitalRecords(new List<Healthcare_Cost__c>{ new Healthcare_Cost__c() })
            .setMSPRecords(new List<Healthcare_Cost__c>{ new Healthcare_Cost__c(Location_Type_Description2__c = null) })
            .setPharmaRecords(new List<Healthcare_Cost__c>{ new Healthcare_Cost__c() })
            .setContinuingCareRecords(new List<Healthcare_Cost__c>{ new Healthcare_Cost__c() })
            .setFutureCareRecords(new List<Healthcare_Cost__c>{ new Healthcare_Cost__c() });

        Test.startTest();
        Blob xlsx = builder.build();
        Test.stopTest();

        System.assert(xlsx.size() > 0, 'Builder should handle null field values without error.');
    }

    @IsTest
    static void buildThrowsWhenSectionExceedsRowLimit() {
        // A section with more records than XlsxBuilder.MAX_ROWS_PER_SHEET should fail fast
        // rather than silently produce a truncated export.
        Case c = DocxTestDataFactory.createCaseRecord();

        List<Healthcare_Cost__c> tooManyRows = new List<Healthcare_Cost__c>();
        for (Integer i = 0; i < XlsxBuilder.MAX_ROWS_PER_SHEET + 1; i++) {
            tooManyRows.add(new Healthcare_Cost__c(Description__c = 'Row ' + i, Cost__c = 1));
        }

        XlsxBuilder builder = new XlsxBuilder().setCaseData(c).setContinuingCareRecords(tooManyRows);

        Boolean threw = false;
        Test.startTest();
        try {
            builder.build();
        } catch (XlsxBuilder.XlsxRecordLimitException e) {
            threw = true;
        }
        Test.stopTest();

        System.assert(threw, 'Exceeding MAX_ROWS_PER_SHEET should throw XlsxRecordLimitException.');
    }

    private static List<Healthcare_Cost__c> ambulanceRows() {
        return new List<Healthcare_Cost__c>{
            new Healthcare_Cost__c(
                Date_of_Service__c = Date.today(),
                Location_Responded__c = 'Scene & Road',
                Facility_Name__c = 'Fallback Destination',
                Total_Cost_Override__c = 125.50
            )
        };
    }

    private static List<Healthcare_Cost__c> hospitalRows() {
        return new List<Healthcare_Cost__c>{
            new Healthcare_Cost__c(
                Date_of_Admission__c = Date.today().addDays(-2),
                Date_of_Discharge__c = Date.today(),
                Facility_Name__c = 'Facility Text',
                Service_Type2__c = 'Inpatient',
                Total_Cost_Override__c = 2500
            )
        };
    }

    private static List<Healthcare_Cost__c> mspRows() {
        return new List<Healthcare_Cost__c>{
            new Healthcare_Cost__c(
                Date_of_Service__c = Date.today(),
                Location_Type_Description2__c = ' Clinic ',
                Description_of_Service2__c = 'Consultation',
                Fee_Item_Title__c = 'Fee Item',
                Diagnostic_Description__c = 'Diagnosis',
                Total_Cost_Override__c = 44.25,
                Practitioner_Name__c = 'Dr. Test'
            )
        };
    }

    private static List<Healthcare_Cost__c> pharmaRows() {
        return new List<Healthcare_Cost__c>{
            new Healthcare_Cost__c(
                Date_of_Service__c = Date.today(),
                Name_of_Drug__c = 'Drug & A',
                Total_Cost_Override__c = 55.75,
                Practitioner_Name__c = 'Dr. Pharma'
            )
        };
    }

    private static List<Healthcare_Cost__c> continuingCareRows() {
        return new List<Healthcare_Cost__c>{
            new Healthcare_Cost__c(Description__c = 'Home support', Cost__c = 600)
        };
    }

    private static List<Healthcare_Cost__c> futureCareRows() {
        return new List<Healthcare_Cost__c>{
            new Healthcare_Cost__c(Description__c = 'Future rehab', Cost__c = 700)
        };
    }
}