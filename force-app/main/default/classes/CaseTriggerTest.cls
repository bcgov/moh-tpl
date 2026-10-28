@isTest
private class CaseTriggerTest {

    @testSetup
    static void setupData() {
        // Ensure Individual and Class_Action record types exist
        List<RecordType> recordTypes = [
            SELECT Id, DeveloperName FROM RecordType 
            WHERE SObjectType = 'Case' AND DeveloperName IN ('Individual', 'Class_Action')
        ];

        Map<String, Id> recordTypeMap = new Map<String, Id>();
        for (RecordType rt : recordTypes) {
            recordTypeMap.put(rt.DeveloperName, rt.Id);
        }

        // Create Case with Individual Record Type (all relevant fields null)
        Case individualCase = new Case(
            RecordTypeId = recordTypeMap.get('Individual'),
            Status = 'Open',
            // all individual-specific cost fields are left as null intentionally
            Subject = 'Test Individual Case'
        );
        insert individualCase;

        // Create Case with Class_Action Record Type (all relevant fields null)
        Case classActionCase = new Case(
            RecordTypeId = recordTypeMap.get('Class_Action'),
            Status = 'Open',
            // all class action-specific cost fields are left as null intentionally
            Subject = 'Test Class Action Case'
        );
        insert classActionCase;
    }

    @isTest
    static void testTriggerSetsNullsToZeroOnInsert() {
        // Fetch inserted cases
        List<Case> cases = [SELECT Id, Pharmacare_Total2__c, Continuing_Care_Total2__c, Ambulance_Total2__c,
                            Future_Care_Total2__c, Hospitalization_Total2__c, MSP_Total2__c,
                            Ambulance_Total_ClassAction__c, Continuing_Care_Total_ClassAction__c,
                            Future_Care_Total_ClassAction__c, Hospitalization_Total_ClassAction__c,
                            MSP_Total_ClassAction__c, Pharmacare_Total_ClassAction__c,
                            Related_Cases_Recovery_Amount__c, RecordType.DeveloperName
                            FROM Case WHERE Subject LIKE 'Test%'];

        for (Case c : cases) {
            // All fields should be initialized to 0.00 by the trigger
            if (c.RecordType.DeveloperName == 'Individual') {
                System.assertEquals(0.00, c.Pharmacare_Total2__c);
                System.assertEquals(0.00, c.Continuing_Care_Total2__c);
                System.assertEquals(0.00, c.Ambulance_Total2__c);
                System.assertEquals(0.00, c.Future_Care_Total2__c);
                System.assertEquals(0.00, c.Hospitalization_Total2__c);
                System.assertEquals(0.00, c.MSP_Total2__c);
            }
            if (c.RecordType.DeveloperName == 'Class_Action') {
                System.assertEquals(0.00, c.Ambulance_Total_ClassAction__c);
                System.assertEquals(0.00, c.Continuing_Care_Total_ClassAction__c);
                System.assertEquals(0.00, c.Future_Care_Total_ClassAction__c);
                System.assertEquals(0.00, c.Hospitalization_Total_ClassAction__c);
                System.assertEquals(0.00, c.MSP_Total_ClassAction__c);
                System.assertEquals(0.00, c.Pharmacare_Total_ClassAction__c);
                System.assertEquals(0.00, c.Related_Cases_Recovery_Amount__c);
            }
        }
    }

    @isTest
    static void testTriggerOnUpdateNullFields() {
        // Fetch cases and clear values to null, then update
        List<Case> casesToUpdate = [SELECT Id, RecordType.DeveloperName FROM Case WHERE Subject LIKE 'Test%'];

        for (Case c : casesToUpdate) {
            if (c.RecordType.DeveloperName == 'Individual') {
                c.Pharmacare_Total2__c = null;
                c.Continuing_Care_Total2__c = null;
                c.Ambulance_Total2__c = null;
                c.Future_Care_Total2__c = null;
                c.Hospitalization_Total2__c = null;
                c.MSP_Total2__c = null;
            }
            if (c.RecordType.DeveloperName == 'Class_Action') {
                c.Ambulance_Total_ClassAction__c = null;
                c.Continuing_Care_Total_ClassAction__c = null;
                c.Future_Care_Total_ClassAction__c = null;
                c.Hospitalization_Total_ClassAction__c = null;
                c.MSP_Total_ClassAction__c = null;
                c.Pharmacare_Total_ClassAction__c = null;
                c.Related_Cases_Recovery_Amount__c = null;
            }
        }

        update casesToUpdate;

        // Re-fetch and assert that nulls were reset to 0.00
        List<Case> updatedCases = [SELECT Id, Pharmacare_Total2__c, Continuing_Care_Total2__c, Ambulance_Total2__c,
                                   Future_Care_Total2__c, Hospitalization_Total2__c, MSP_Total2__c,
                                   Ambulance_Total_ClassAction__c, Continuing_Care_Total_ClassAction__c,
                                   Future_Care_Total_ClassAction__c, Hospitalization_Total_ClassAction__c,
                                   MSP_Total_ClassAction__c, Pharmacare_Total_ClassAction__c,
                                   Related_Cases_Recovery_Amount__c, RecordType.DeveloperName
                                   FROM Case WHERE Subject LIKE 'Test%'];

        for (Case c : updatedCases) {
            if (c.RecordType.DeveloperName == 'Individual') {
                System.assertEquals(0.00, c.Pharmacare_Total2__c);
                System.assertEquals(0.00, c.Continuing_Care_Total2__c);
                System.assertEquals(0.00, c.Ambulance_Total2__c);
                System.assertEquals(0.00, c.Future_Care_Total2__c);
                System.assertEquals(0.00, c.Hospitalization_Total2__c);
                System.assertEquals(0.00, c.MSP_Total2__c);
            }
            if (c.RecordType.DeveloperName == 'Class_Action') {
                System.assertEquals(0.00, c.Ambulance_Total_ClassAction__c);
                System.assertEquals(0.00, c.Continuing_Care_Total_ClassAction__c);
                System.assertEquals(0.00, c.Future_Care_Total_ClassAction__c);
                System.assertEquals(0.00, c.Hospitalization_Total_ClassAction__c);
                System.assertEquals(0.00, c.MSP_Total_ClassAction__c);
                System.assertEquals(0.00, c.Pharmacare_Total_ClassAction__c);
                System.assertEquals(0.00, c.Related_Cases_Recovery_Amount__c);
            }
        }
    }
}