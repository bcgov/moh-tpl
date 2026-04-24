@isTest
public class CaseTriggerHandlerTest {

    @testSetup
    static void setupData() {
        Id individualRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
        Id classActionRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Class_Action').getRecordTypeId();

        // Parent Case (Class_Action)
        Case parentCase = new Case(
            RecordTypeId = classActionRtId,
            Status = 'Open',
            Subject = 'Parent Case'
        );
        insert parentCase;

        // Create Child Cases (Individual)
        List<Case> childCases = new List<Case>{
            new Case(
                RecordTypeId = individualRtId,
                ParentId = parentCase.Id,
                Status = 'Open',
                Subject = 'Child 1',
                Ambulance_Total2__c = 100,
                Hospitalization_Total2__c = 200,
                MSP_Total2__c = 300,
                Pharmacare_Total2__c = 400,
                Continuing_Care_Total2__c = 500,
                Future_Care_Total2__c = 600
            ),
            new Case(
                RecordTypeId = individualRtId,
                ParentId = parentCase.Id,
                Status = 'Open',
                Subject = 'Child 2',
                Ambulance_Total2__c = 10,
                Hospitalization_Total2__c = 20,
                MSP_Total2__c = 30,
                Pharmacare_Total2__c = 40,
                Continuing_Care_Total2__c = 50,
                Future_Care_Total2__c = 60
            )
        };

        insert childCases;
    }

    @isTest
    static void testRollupOnInsert() {
        Case parent = [SELECT Id,
            Ambulance_Total_ClassAction__c,
            Hospitalization_Total_ClassAction__c,
            MSP_Total_ClassAction__c,
            Pharmacare_Total_ClassAction__c,
            Continuing_Care_Total_ClassAction__c,
            Future_Care_Total_ClassAction__c
        FROM Case WHERE Subject = 'Parent Case' LIMIT 1];

        System.assertEquals(110, parent.Ambulance_Total_ClassAction__c);
        System.assertEquals(220, parent.Hospitalization_Total_ClassAction__c);
        System.assertEquals(330, parent.MSP_Total_ClassAction__c);
        System.assertEquals(440, parent.Pharmacare_Total_ClassAction__c);
        System.assertEquals(550, parent.Continuing_Care_Total_ClassAction__c);
        System.assertEquals(660, parent.Future_Care_Total_ClassAction__c);
    }

    @isTest
    static void testRollupOnParentChange() {
        Id individualRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
        Id classActionRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Class_Action').getRecordTypeId();

        // Create second parent
        Case newParent = new Case(
            RecordTypeId = classActionRtId,
            Status = 'Open',
            Subject = 'New Parent'
        );
        insert newParent;

        // Move one child case to the new parent
        Case childToUpdate = [SELECT Id, ParentId FROM Case WHERE Subject = 'Child 1' LIMIT 1];
        childToUpdate.ParentId = newParent.Id;
        update childToUpdate;

        // Check both parents
        Case originalParent = [SELECT Id, Ambulance_Total_ClassAction__c FROM Case WHERE Subject = 'Parent Case' LIMIT 1];
        Case updatedParent = [SELECT Id, Ambulance_Total_ClassAction__c FROM Case WHERE Subject = 'New Parent' LIMIT 1];

        System.assertEquals(10, originalParent.Ambulance_Total_ClassAction__c);
        System.assertEquals(100, updatedParent.Ambulance_Total_ClassAction__c);
    }
}