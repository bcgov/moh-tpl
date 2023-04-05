@isTest
public class HCCCostControllerTest {
    
    @isTest
    static void testsaveDraftValues(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
		Healthcare_Cost__c hcc1 = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc3 = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        hcc3.Source_System_ID__c = 'abcd'; 
        List<Healthcare_Cost__c> hccList1 = new List <Healthcare_Cost__c>();
        List<Healthcare_Cost__c> hccList2 = new List<Healthcare_Cost__c>();
        hccList1.add(hcc1);
        hccList1.add(hcc2);
        hccList2.add(hcc3);
		
        Test.startTest();
        try{
        	insert hccList1;
        	insert hccList2;
        }
        catch(DmlException dml){
        	String exceptionMessage = dml.getDmlMessage(0);
        }
        HCCCostController.CaseListWrapper caseWrapper1 = HCCCostController.saveDraftValues(hccList1, hccList1);
        HCCCostController.CaseListWrapper caseWrapper2 = HCCCostController.saveDraftValues(hccList2, hccList1);
        Test.stopTest();
        
        System.assertEquals('Passed', caseWrapper1.passedResult);
        System.assertEquals('Failed', caseWrapper2.passedResult);
    }
    
     @isTest
    static void testRecordsDeleteFunctionality(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
		List<Healthcare_Cost__c> hccListtodelete = new List<Healthcare_Cost__c>();	
        Healthcare_Cost__c hcc1 = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        hccListtodelete.add(hcc1);
        insert hccListtodelete;

        Test.startTest();
        String manualRecords = Label.TPL_Manual_Records;
        String allRecords = Label.TPL_All_Records;
        String recordsCreatedToday = Label.TPL_Records_Created_Today;
        String result1 = HCCCostController.deleteHCCRecord(hccListtodelete, allRecords);
        String result2 = HCCCostController.deleteHCCRecord(hccListtodelete, recordsCreatedToday);
        Test.stopTest();
        System.assertNotEquals(result1, result2);
    
    }
    
    @isTest
    static void testCaseNumber(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
        Set<Id> caseId = new Set<Id>();
        caseId.add(c.Id);
        Test.startTest();
        List<Case> caseList = HCCCostController.getCaseNumber(caseId);
        Test.stopTest();
        System.assertEquals(1, caseList.size());
    }
    
}