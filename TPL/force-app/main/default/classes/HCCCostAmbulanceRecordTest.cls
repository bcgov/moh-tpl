@isTest
public class HCCCostAmbulanceRecordTest {
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
        Integer limitValue = 5, offsetValue = 0;
        Test.startTest();
        List <Healthcare_Cost__c> hccListforAccounts = HCCCostAmbulanceRecord.getHealthcareCostsAmbulanceForAccount(acc.Id, limitValue, offsetValue);
        Test.stopTest();
        System.assertEquals(3, hccListforAccounts.size());
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
        List <Healthcare_Cost__c> hccListforCases = HCCCostAmbulanceRecord.getHealthcareCostsAmbulanceForCase(c.Id);
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
        String output = HCCCostAmbulanceRecord.updateHCCCaseInformation(hccListtoUpdate,caseId);
        Test.stopTest(); 
        System.assertEquals('Passed', output);
        
    }
    
    @isTest
    static void testUpdatetoCaseValuesReverseCondition(){
        Test.startTest();
        String output = HCCCostAmbulanceRecord.updateHCCCaseInformation(null, null);
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
        String output = HCCCostAmbulanceRecord.updateHCCRecordInformation(hccListtoUpdate);
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
        String output = HCCCostAmbulanceRecord.updateHCCRecordInformation(hccListtoUpdate);
        Test.stopTest(); 
        System.assertEquals('Passed', output);
    }
    
	@isTest
    static void testAmbulanceCountonAccount(){
        Account acc1 = TestDataFactory.individualAccount();
        Account acc2 = TestDataFactory.individualAccount();
        acc2.FirstName = 'Testing';
        acc2.LastName = 'Account';
        acc2.PHN__pc = '8912781237'; 
        insert new Account[] {acc1, acc2};
            
        Case c1 = TestDataFactory.newCase(acc1.Id);
        Case c2 = TestDataFactory.newCase(acc2.Id);
        insert new Case[] {c1,c2};
		
        Healthcare_Cost__c hcc1 = TestDataFactory.ambulanceCostRecord(acc1.Id, c1.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.ambulanceCostRecord(acc1.Id, c1.Id);
        Healthcare_Cost__c hcc3 = TestDataFactory.ambulanceCostRecord(acc2.Id, c2.Id);
        insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3}; 
        
        Test.startTest();
        Integer countRecords = HCCCostAmbulanceRecord.getAmbulanceCountonAccount(acc1.Id);
        Test.stopTest();
        System.assertEquals(2, countRecords);
    }
    
}