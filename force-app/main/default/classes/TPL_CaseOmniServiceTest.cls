@IsTest
private class TPL_CaseOmniServiceTest {

    @testSetup
    static void setupData() {
        Case c = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Phone',
            Include_Future_Care__c = true
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
        System.assertEquals(1, (Integer)outMap.get('hcFilterCount'));
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