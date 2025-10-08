@isTest
public class HealthcareCostTriggerHandlerTest {
    
    @testSetup
    static void setupData() {
        // Get RecordTypeIds for Healthcare_Cost__c
        Map<String, Id> recordTypeMap = new Map<String, Id>();
        for (RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Healthcare_Cost__c']) {
            recordTypeMap.put(rt.DeveloperName, rt.Id);
        }

        // Get Individual RecordTypeId for Case
        Id individualRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();

        // Create test Case with Individual Record Type
        Case testCase = new Case(
            RecordTypeId = individualRtId,
            Subject = 'Test Case',
            Status = 'Open'
        );
        insert testCase;

        List<Healthcare_Cost__c> costRecords = new List<Healthcare_Cost__c>();

        // Pharmacare (uses Total_Cost_Override__c)
        costRecords.add(new Healthcare_Cost__c(
            Case2__c = testCase.Id,
            RecordTypeId = recordTypeMap.get('Pharmacare'),
            Total_Cost_Override__c = 100.00,
            Cost_Include__c = true,
            Cost_Review__c = true
        ));

        // Continuing Care (uses Cost__c, only needs record type match)
        costRecords.add(new Healthcare_Cost__c(
            Case2__c = testCase.Id,
            RecordTypeId = recordTypeMap.get('Continuing_Care'),
            Cost__c = 200.00
        ));

        // Ambulance
        costRecords.add(new Healthcare_Cost__c(
            Case2__c = testCase.Id,
            RecordTypeId = recordTypeMap.get('Ambulance'),
            Total_Cost_Override__c = 300.00,
            Cost_Include__c = true,
            Cost_Review__c = true
        ));

        // Future Care (uses Cost__c, only needs record type match)
        costRecords.add(new Healthcare_Cost__c(
            Case2__c = testCase.Id,
            RecordTypeId = recordTypeMap.get('Future_Care'),
            Cost__c = 400.00
        ));

        // Hospitalization
        costRecords.add(new Healthcare_Cost__c(
            Case2__c = testCase.Id,
            RecordTypeId = recordTypeMap.get('Hospitalization'),
            Date_of_Admission__c = Date.today(),
            Date_of_Discharge__c = Date.today(),
            Cost_Include__c = true,
            Cost_Review__c = true
        ));

        // MSP
        costRecords.add(new Healthcare_Cost__c(
            Case2__c = testCase.Id,
            RecordTypeId = recordTypeMap.get('MSP'),
            Total_Cost_Override__c = 600.00,
            Cost_Include__c = true,
            Cost_Review__c = true
        ));

        insert costRecords;
    }

    @isTest
    static void testUpdateRollup() {
        // Get the inserted Healthcare_Cost__c records
        List<Healthcare_Cost__c> costs = [SELECT Id, Case2__c FROM Healthcare_Cost__c];
        
        // Call the method
        Test.startTest();
        HealthcareCostTriggerHandler.updateRollup(costs);
        Test.stopTest();

        // Assert updates on Case
        Case updatedCase = [SELECT Id,
            Pharmacare_Total2__c,
            Continuing_Care_Total2__c,
            Ambulance_Total2__c,
            Future_Care_Total2__c,
            Hospitalization_Total2__c,
            MSP_Total2__c,
            Ambulance_Total_ClassAction__c,
            Continuing_Care_Total_ClassAction__c,
            Future_Care_Total_ClassAction__c,
            Hospitalization_Total_ClassAction__c,
            MSP_Total_ClassAction__c,
            Pharmacare_Total_ClassAction__c,
            Related_Cases_Recovery_Amount__c
        FROM Case WHERE Id = :costs[0].Case2__c];

        System.assertEquals(100.00, updatedCase.Pharmacare_Total2__c);
        System.assertEquals(200.00, updatedCase.Continuing_Care_Total2__c);
        System.assertEquals(300.00, updatedCase.Ambulance_Total2__c);
        System.assertEquals(400.00, updatedCase.Future_Care_Total2__c);
        System.assertEquals(600.00, updatedCase.MSP_Total2__c);

        // Confirm other fields defaulted to 0
        System.assertEquals(0.00, updatedCase.Ambulance_Total_ClassAction__c);
        System.assertEquals(0.00, updatedCase.Pharmacare_Total_ClassAction__c);
        System.assertEquals(0.00, updatedCase.Related_Cases_Recovery_Amount__c);
    }
}