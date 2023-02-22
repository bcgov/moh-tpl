@isTest
public class HCCCostCCRecordTest {

    @isTest
    static void testHealthcareCostsCCForCase(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
		Healthcare_Cost__c hcc1 = TestDataFactory.continuingcareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.continuingcareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc3 = TestDataFactory.continuingcareCostRecord(acc.Id, c.Id);
        insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3};

        Test.startTest();
        List <Healthcare_Cost__c> hccListforCases = HCCCostCCRecord.getHealthcareCostsCCForCase(c.Id);
        Test.stopTest();
        System.assertEquals(3, hccListforCases.size());
    }
    
    @isTest
    static void testContinuingCareCountonCase(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
		Healthcare_Cost__c hcc1 = TestDataFactory.continuingcareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.continuingcareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc3 = TestDataFactory.continuingcareCostRecord(acc.Id, c.Id);
        insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3};

        Test.startTest();
        Integer count = HCCCostCCRecord.getContinuingCareCountonCase(c.Id);
        Test.stopTest();
        System.assertEquals(3, count);
    }
    
    @isTest
    static void testdeleteContinuingCareRecords(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
		Healthcare_Cost__c hcc1 = TestDataFactory.continuingcareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.continuingcareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc3 = TestDataFactory.continuingcareCostRecord(acc.Id, c.Id);
        insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3};
        List <Healthcare_Cost__c> deletionList = new List<Healthcare_Cost__c>();
        deletionList.add(hcc1);
        Test.startTest();
        String output = HCCCostCCRecord.deleteContinuingCareRecords(deletionList);
        Test.stopTest();
        System.assertEquals('Passed', output);
    }
}