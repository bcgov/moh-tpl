@isTest
public class HCCCostControllerTest {
    
    @isTest
    static void testsaveDraftValues(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
		Healthcare_Cost__c hcc1 = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.ambulanceCostRecord(acc.Id, null);
        Healthcare_Cost__c hcc3 = TestDataFactory.ambulanceCostRecord(acc.Id, null);
        
       List<Healthcare_Cost__c> hccList = new List <Healthcare_Cost__c>();
       List<Healthcare_Cost__c> hccList2 = new List<Healthcare_Cost__c>();
        hccList.add(hcc1);
        hccList.add(hcc2);
        hccList.add(hcc3);
		insert hccList;
        
        Test.startTest();
        String result1 = HCCCostController.saveDraftValues(hccList);
        String result2 = HCCCostController.saveDraftValues(hccList2);
        Test.stopTest();
        
        System.assertEquals('Passed', result1);
        System.assertEquals('Failed', result2);
    }
    
}