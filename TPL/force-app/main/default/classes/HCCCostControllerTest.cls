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
        List<Case> caseList = HCCCostController.getCaseListIndividual(acc.Id);
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
        String caseId = c2.Id;
        Test.startTest();
        String output = HCCCostController.updateHCCCaseInformation(hccListtoUpdate,caseId);
        Test.stopTest(); 
        System.assertEquals('Passed', output);
        
    }
    
    @isTest
    static void testUpdatetoCaseValuesReverseCondition(){
        Test.startTest();
        String output = HCCCostController.updateHCCCaseInformation(null, null);
        Test.stopTest(); 
        System.assertEquals('Failed', output); 
    }
    
    @isTest
    static void testdelinkOfCaseValuesNegative(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c1 = TestDataFactory.newCase(acc.Id);
        Case c2 = TestDataFactory.newCase(acc.Id);
        insert  new Case[] {c1, c2};
        
		Healthcare_Cost__c hcc1 = TestDataFactory.ambulanceCostRecord(acc.Id, c1.Id);
        insert new Healthcare_Cost__c[] {hcc1}; 
        
        List<Healthcare_Cost__c> hccListtoUpdate = new List<Healthcare_Cost__c>();
        hccListtoUpdate.add(hcc1);
        
        Test.startTest();
        String output = HCCCostController.updateHCCRecordInformation(hccListtoUpdate);
        Test.stopTest(); 
        System.assertEquals('Failed', output);
    }
    
    @isTest
    static void testdelinkOfCaseValuesPositive(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c1 = TestDataFactory.newCase(acc.Id);
        Case c2 = TestDataFactory.newCase(acc.Id);
        insert  new Case[] {c1, c2};
        
		Healthcare_Cost__c hcc1 = TestDataFactory.ambulanceCostRecord(acc.Id, c1.Id);
        hcc1.Cost_Include__c = false;
        hcc1.Cost_Review__c = false;
		insert new Healthcare_Cost__c[] {hcc1}; 
        
        List<Healthcare_Cost__c> hccListtoUpdate = new List<Healthcare_Cost__c>();
        hccListtoUpdate.add(hcc1);
     
        Test.startTest();
        String output = HCCCostController.updateHCCRecordInformation(hccListtoUpdate);
        Test.stopTest(); 
        System.assertEquals('Passed', output);
    }
    
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
        hccList.add(hcc1);
        hccList.add(hcc2);
        hccList.add(hcc3);
		insert hccList;
        
        Test.startTest();
        HCCCostController.saveDraftValues(hccList);
        Test.stopTest();
        
    }
    
}