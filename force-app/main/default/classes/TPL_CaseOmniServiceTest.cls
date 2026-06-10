@IsTest
private class TPL_CaseOmniServiceTest {

    @testSetup
    static void setupData() {
        Case c = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Phone',
            Include_Future_Care__c = true,
            Report_Start__c = Date.today(),
            Report_End__c = Date.today() + 5
        );
        insert c;

        Id futureCareRtId = getRecordTypeId('Healthcare_Cost__c', 'Future_Care');

        insert new List<Healthcare_Cost__c>{
            new Healthcare_Cost__c(
                Case2__c = c.Id,
                Date_of_Service__c = Date.today(),
                Cost_Include__c = true,
                Cost_Review__c = false
            ),
            new Healthcare_Cost__c(
                Case2__c = c.Id,
                Date_of_Service__c = Date.today(),
                Cost_Include__c = true,
                Cost_Review__c = true,
                RecordTypeId = futureCareRtId
            )
        };
    }

    private static Id getRecordTypeId(String sObjectName, String developerName) {
        RecordType rt = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = :sObjectName
            AND DeveloperName = :developerName
            LIMIT 1
        ];
        System.assertNotEquals(null, rt, 'Required record type not found: ' + developerName);
        return rt.Id;
    }

    @IsTest
    static void testGetHealthCareCostRecords() {
        Case c = [SELECT Id FROM Case LIMIT 1];

        Map<String, Object> inputMap = new Map<String, Object>{
            'caseId' => c.Id,
            'birthDate' => String.valueOf(Date.today().addDays(-10))
        };
        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        Boolean result = new TPL_CaseOmniService().invokeMethod(
            'getHealthCareCostRecords',
            inputMap,
            outMap,
            new Map<String, Object>()
        );
        Test.stopTest();

        System.assertEquals(true, result);
        System.assertEquals(2, (Integer)outMap.get('hcCount'));
    }

    @IsTest
    static void testGetHealthCareCostRecords_WithDateTimeInput() {
        Case c = [SELECT Id FROM Case LIMIT 1];

        String birthDateTime = String.valueOf(
            Datetime.newInstance(Date.today().addDays(-10), Time.newInstance(0, 0, 0, 0))
        ); // "yyyy-MM-dd HH:mm:ss"

        Map<String, Object> inputMap = new Map<String, Object>{
            'caseId' => c.Id,
            'birthDate' => birthDateTime
        };
        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        Boolean result = new TPL_CaseOmniService().invokeMethod(
            'getHealthCareCostRecords',
            inputMap,
            outMap,
            new Map<String, Object>()
        );
        Test.stopTest();

        System.assertEquals(true, result);
        System.assertEquals(2, (Integer)outMap.get('hcCount'));
    }

    @IsTest
    static void testGetHealthCareCostRecordsInDateRange() {
        Case c = [SELECT Id FROM Case LIMIT 1];

        Map<String, Object> inputMap = new Map<String, Object>{
            'ContextId' => c.Id,
            'startDate' => String.valueOf(Date.today().addDays(-1)),
            'endDate' => String.valueOf(Date.today().addDays(1)),
            'includeFuture' => false
        };
        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        Boolean result = new TPL_CaseOmniService().invokeMethod(
            'getHealthCareCostRecordsInDateRange',
            inputMap,
            outMap,
            new Map<String, Object>()
        );
        Test.stopTest();

        System.assertEquals(true, result);
        System.assertEquals(0, (Integer)outMap.get('hcFilterCount'));
    }

    @IsTest
    static void testGetHealthCareCostRecordsInDateRange_WithDateTimeInput_AndFutureCare() {
        Case c = [SELECT Id FROM Case LIMIT 1];

        String startDateTime = String.valueOf(
            Datetime.newInstance(Date.today().addDays(-1), Time.newInstance(0, 0, 0, 0))
        ); // "yyyy-MM-dd HH:mm:ss"

        String endDateTime = String.valueOf(
            Datetime.newInstance(Date.today().addDays(1), Time.newInstance(23, 59, 59, 0))
        ); // "yyyy-MM-dd HH:mm:ss"

        Map<String, Object> inputMap = new Map<String, Object>{
            'ContextId' => c.Id,
            'startDate' => startDateTime,
            'endDate' => endDateTime,
            'includeFuture' => true
        };
        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        Boolean result = new TPL_CaseOmniService().invokeMethod(
            'getHealthCareCostRecordsInDateRange',
            inputMap,
            outMap,
            new Map<String, Object>()
        );
        Test.stopTest();

        System.assertEquals(true, result);
        System.assertEquals(1, (Integer)outMap.get('hcFilterCount'));
    }

    @IsTest
    static void testGetHealthCareCostRecordsInDateRange_EmptyInput() {
        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        Boolean result = new TPL_CaseOmniService().invokeMethod(
            'getHealthCareCostRecordsInDateRange',
            new Map<String, Object>(),
            outMap,
            new Map<String, Object>()
        );
        Test.stopTest();

        System.assertEquals(true, result);
        System.assertEquals(0, outMap.size());
    }

    @IsTest
    static void testInvalidMethodThrows() {
        try {
            new TPL_CaseOmniService().invokeMethod(
                'invalidMethod',
                new Map<String, Object>(),
                new Map<String, Object>(),
                new Map<String, Object>()
            );
            System.assert(false, 'Expected an exception.');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Method not implemented'));
        }
    }
}