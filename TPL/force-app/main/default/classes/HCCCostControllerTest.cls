@isTest
public class HCCCostControllerTest {
    
    @isTest
    static void testsaveDraftValues(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
        
        String filterAllRecords = Label.TPL_All_Records;
        String filterManualRecords = Label.TPL_Manual_Records;
        String filterRecordsToday = Label.TPL_Records_Created_Today;
        
        Healthcare_Cost__c hcc1 = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc3 = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        hcc3.Source_System_ID__c = 'abcd';
       
        List<Healthcare_Cost__c> hccList1 = new List <Healthcare_Cost__c>();
        List<Healthcare_Cost__c> hccList2 = new List<Healthcare_Cost__c>();
        List<Healthcare_Cost__c> hccList3 = new List<Healthcare_Cost__c>(); 
        hccList1.add(hcc1);
        hccList1.add(hcc2);
        hccList2.add(hcc3);
		hccList3.add(hcc1);
        hccList3.add(hcc2);
        hccList3.add(hcc3);
        
        Test.startTest();
        String exceptionMessage = null;
        HCCCostController.CaseListWrapper caseWrapper1 = new HCCCostController.CaseListWrapper();
        HCCCostController.CaseListWrapper caseWrapper2 = new HCCCostController.CaseListWrapper();
        try{
        	insert hccList1;
        	insert hccList2;
            for(Healthcare_Cost__c hcc: hccList1){
            	hcc.Cost_Include__c = false;    
            }for(Healthcare_Cost__c hcc: hccList2){
                hcc.Cost_Review__c = false;
            }
            caseWrapper1 = HCCCostController.saveDraftValues(hccList1, hccList3);
            caseWrapper2 = HCCCostController.saveDraftValues(hccList2, hccList3);
        }
        catch(DmlException dml){
        	exceptionMessage = dml.getDmlMessage(0);
        }
        Test.stopTest();

        if(exceptionMessage !=null){
            System.assertNotEquals(null, exceptionMessage);
        }
        else{        
            System.assertEquals(caseWrapper1.passedResult, caseWrapper2.passedResult);
        }
    }
    
     @isTest
    static void testRecordsDeleteFunctionality(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
		List<Healthcare_Cost__c> hccListtodelete1 = new List<Healthcare_Cost__c>();	
        List<Healthcare_Cost__c> hccListtodelete2 = new List<Healthcare_Cost__c>();	
        Healthcare_Cost__c hcc1 = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        hcc2.Source_System_ID__c = 'akgkj-sfj';
        hccListtodelete1.add(hcc1);
        hccListtodelete2.add(hcc2);
        Test.startTest();
        String manualRecords = Label.TPL_Manual_Records;
        String allRecords = Label.TPL_All_Records;
        String recordsCreatedToday = Label.TPL_Records_Created_Today;
        String exceptionMessage = null;
        String result1, result2;
        try{
            insert hccListtodelete1;
            insert hccListtodelete2;
            result1 = HCCCostController.deleteHCCRecord(hccListtodelete1, recordsCreatedToday);
            HCCCostController.deleteHCCRecord(hccListtodelete2, allRecords);
            result2 = HCCCostController.deleteHCCRecord(hccListtodelete2, recordsCreatedToday);
        }
        catch(DmlException dml){
            exceptionMessage = dml.getMessage();
        }
        Test.stopTest();
        if(exceptionMessage !=null){
            System.assertNotEquals(null, exceptionMessage);
        }
        else{        
            System.assertNotEquals(result1, result2);
        }
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
    
    
    @isTest
    static void testUpdatetoCaseValues(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c1 = TestDataFactory.newCase(acc.Id);
        Case c2 = TestDataFactory.newCase(acc.Id);
        insert  new Case[] {c1, c2};
        
		Healthcare_Cost__c hcc1 = TestDataFactory.ambulanceCostRecord(acc.Id, c1.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.ambulanceCostRecord(acc.Id, c1.Id);
        hcc2.Cost_Include__c = false;
        hcc2.Cost_Review__c = false;
        Healthcare_Cost__c hcc3 = TestDataFactory.ambulanceCostRecord(acc.Id, c1.Id);
		
        Test.startTest();
        String filterAllRecords = Label.TPL_All_Records;
        String filterUncheckedRecords = Label.TPL_Both_Unchecked;
        Integer pageNumber = 1;
        Integer pageSize = 5;
        HCCostAccountController.HCCostAccountDetailWrapper accountDetailWrapper1 = new HCCostAccountController.HCCostAccountDetailWrapper();
        HCCostAccountController.HCCostAccountDetailWrapper accountDetailWrapper2 = new HCCostAccountController.HCCostAccountDetailWrapper();
        HCCCostController.HCCostAccountCaseWrapper accountCaseUpdateWrapper1 = new HCCCostController.HCCostAccountCaseWrapper(); 
        HCCCostController.HCCostAccountCaseWrapper accountCaseUpdateWrapper2 = new HCCCostController.HCCostAccountCaseWrapper(); 
        List<Healthcare_Cost__c> caseAssociation1 = new List<Healthcare_Cost__c>();
        List<Healthcare_Cost__c> caseAssociation2 = new List<Healthcare_Cost__c>();
        String caseId = c2.Id;
        String exceptionMessage = null;   
        try{
            insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3}; 
            accountDetailWrapper1 = HCCostAccountController.getHealthcareCostsAmbulanceForAccount(acc.Id, filterAllRecords, pageNumber, pageSize);
            accountDetailWrapper2 = HCCostAccountController.getHealthcareCostsAmbulanceForAccount(acc.Id, filterUncheckedRecords, pageNumber, pageSize);
            caseAssociation1 = accountDetailWrapper1.hccList;
            caseAssociation2 = accountDetailWrapper2.hccList;
            accountCaseUpdateWrapper1 = HCCCostController.updateHCCCaseInformation(caseAssociation1, caseId, caseAssociation1);
            accountCaseUpdateWrapper2 = HCCCostController.updateHCCCaseInformation(caseAssociation2, caseId, caseAssociation2);
            HCCCostController.updateHCCCaseInformation(caseAssociation2, null, caseAssociation2);
     
        }
        catch(DmlException dml){
            exceptionMessage = dml.getMessage();
        }
        Test.stopTest(); 
        if(exceptionMessage != null){
            System.assertNotEquals(null, exceptionMessage);
        }
        else{
            System.assertNotEquals(accountCaseUpdateWrapper1.passMessage, accountCaseUpdateWrapper2.passMessage);
        }
        
    }
      
}