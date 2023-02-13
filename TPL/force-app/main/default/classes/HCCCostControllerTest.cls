@isTest
public class HCCCostControllerTest {
    @isTest
    static void testAmbulanceRecordsonAccount(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
		Healthcare_Cost__c hcc1 = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.ambulanceCostRecord(acc.Id, null);
        Healthcare_Cost__c hcc3 = TestDataFactory.ambulanceCostRecord(acc.Id, null);
        
        insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3};
        
        Test.startTest();
        List <Healthcare_Cost__c> hccListforAccounts = HCCCostController.getHealthcareCostsAmbulanceForAccount(acc.Id);
        Test.stopTest();
        System.assertEquals(3, hccListforAccounts.size());
    }
    
	@isTest
    static void testCaseIndividualRecord(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c1 = TestDataFactory.newCase(acc.Id);
        Case c2 = TestDataFactory.newCase(acc.Id);
        Case c3 = TestDataFactory.newCase(acc.Id);
        Case c4 = TestDataFactory.newCase(acc.Id);
    	
        insert  new Case[] {c1, c2, c3, c4};
        
        Test.startTest();
        List<Case> caseList = HCCCostController.getCaseListIndividual();
		Test.stopTest();
        System.assertEquals(4, caseList.size());
        
    }     
    
    @isTest
    static void testAmbulanceRecordsCase(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
		Healthcare_Cost__c hcc1 = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc3 = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3};
            
        Test.startTest();
        List <Healthcare_Cost__c> hccListforCases = HCCCostController.getHealthcareCostsAmbulanceForCase(c.Id);
        Test.stopTest();
        System.assertEquals(3, hccListforCases.size());
    
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
        Healthcare_Cost__c hcc3 = TestDataFactory.ambulanceCostRecord(acc.Id, c1.Id);
		insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3}; 
            
        List<String> hccListtoUpdate = new List<String>();
        hccListtoUpdate.add(hcc1.Id);
        
        Test.startTest();
        List<Healthcare_Cost__c> hccListonCasePrevious = HCCCostController.getHealthcareCostsAmbulanceForCase(c1.Id);
        HCCCostController.updateHCCCaseInformation(hccListtoUpdate, c2.Id);
        List<Healthcare_Cost__c> hccListonCaseAfter = HCCCostController.getHealthcareCostsAmbulanceForCase(c1.Id);
        Test.stopTest(); 
        System.assertNotEquals(hccListonCasePrevious, hccListonCaseAfter);
        
    }
    
}