@isTest
public class HCCCostFCRecordTest{
    
    @isTest
    static void testHealthcareCostsFCForCase(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
		Healthcare_Cost__c hcc1 = TestDataFactory.futurecareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.futurecareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc3 = TestDataFactory.futurecareCostRecord(acc.Id, c.Id);
        insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3};

        Test.startTest();
        List <Healthcare_Cost__c> hccListforCases = HCCCostFCRecord.getHealthcareCostsFCForCase(c.Id);
        Test.stopTest();
        System.assertEquals(3, hccListforCases.size());
    }
    
    @isTest
    static void testFutureCareCountonCase(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
		Healthcare_Cost__c hcc1 = TestDataFactory.futurecareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.futurecareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc3 = TestDataFactory.futurecareCostRecord(acc.Id, c.Id);
        insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3};

        Test.startTest();
        Integer count = HCCCostFCRecord.getFutureCareCountonCase(c.Id);
        Test.stopTest();
        System.assertEquals(3, count);
    }
    
    @isTest
    static void testdeleteFutureCareRecords(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
		Healthcare_Cost__c hcc1 = TestDataFactory.futurecareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.futurecareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc3 = TestDataFactory.futurecareCostRecord(acc.Id, c.Id);
        insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3};
        List <Healthcare_Cost__c> deletionList = new List<Healthcare_Cost__c>();
        deletionList.add(hcc1);
        Test.startTest();
        String output = HCCCostFCRecord.deleteFutureCareRecords(deletionList);
        Test.stopTest();
        System.assertEquals('Passed', output);
    }
}