@isTest
public class HCCCostMSPRecordTest {
    @isTest
    static void testMSPRecordsonAccount(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
		Healthcare_Cost__c hcc1 = TestDataFactory.MSPCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.MSPCostRecord(acc.Id, null);
        Healthcare_Cost__c hcc3 = TestDataFactory.MSPCostRecord(acc.Id, null);
        
        insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3};

        Test.startTest();
        List <Healthcare_Cost__c> hccListforAccounts = HCCCostMSPRecord.getHealthcareCostsMSPForAccount(acc.Id);
        Test.stopTest();
        System.assertEquals(3, hccListforAccounts.size());
    }
       
    @isTest
    static void testMSPRecordsCase(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
		Healthcare_Cost__c hcc1 = TestDataFactory.MSPCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.MSPCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc3 = TestDataFactory.MSPCostRecord(acc.Id, c.Id);
        insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3};
            
        Test.startTest();
        List <Healthcare_Cost__c> hccListforCases = HCCCostMSPRecord.getHealthcareCostsMSPForCase(c.Id);
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
        
		Healthcare_Cost__c hcc1 = TestDataFactory.MSPCostRecord(acc.Id, c1.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.MSPCostRecord(acc.Id, c1.Id);
        hcc2.Cost_Include__c = false;
        hcc2.Cost_Review__c = false;
        Healthcare_Cost__c hcc3 = TestDataFactory.MSPCostRecord(acc.Id, c1.Id);
		insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3}; 
            
        List<Healthcare_Cost__c> hccListtoUpdate1 = new List<Healthcare_Cost__c>();
        List<Healthcare_Cost__c> hccListtoUpdate2 = new List<Healthcare_Cost__c>();

        hccListtoUpdate1.add(hcc1);
        hccListtoUpdate2.add(hcc2);
        String caseId = c2.Id;
        Test.startTest();
        String output1 = HCCCostMSPRecord.updateHCCCaseInformation(hccListtoUpdate1,caseId);
        String output2 = HCCCostMSPRecord.updateHCCCaseInformation(hccListtoUpdate2,caseId);
        Test.stopTest(); 
        System.assertEquals('Passed', output2);
        System.assertEquals('Failed', output1);
        
    }
    
    @isTest
    static void testUpdatetoCaseValuesReverseCondition(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c1 = TestDataFactory.newCase(acc.Id);
        insert c1;
        List<Healthcare_Cost__c> hccListtoUpdate1 = new List<Healthcare_Cost__c>();
        Test.startTest();
        String output = HCCCostMSPRecord.updateHCCCaseInformation(hccListtoUpdate1, c1.Id);
        Test.stopTest(); 
        System.assertEquals('Failed', output); 
    }
    
	@isTest
    static void testMSPCountOnAccount(){
        Account acc1 = TestDataFactory.individualAccount();
        Account acc2 = TestDataFactory.individualAccount();
        acc2.FirstName = 'Testing';
        acc2.LastName = 'Account';
        acc2.PHN__pc = '8912781237'; 
        insert new Account[] {acc1, acc2};
            
        Case c1 = TestDataFactory.newCase(acc1.Id);
        Case c2 = TestDataFactory.newCase(acc2.Id);
        insert new Case[] {c1,c2};
		
        Healthcare_Cost__c hcc1 = TestDataFactory.MSPCostRecord(acc1.Id, c1.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.MSPCostRecord(acc1.Id, c1.Id);
        Healthcare_Cost__c hcc3 = TestDataFactory.MSPCostRecord(acc2.Id, c2.Id);
        insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3}; 
        
        Test.startTest();
        Integer countRecords = HCCCostMSPRecord.getMSPCountonAccount(acc1.Id);
        Test.stopTest();
        System.assertEquals(2, countRecords);
    }
    
}