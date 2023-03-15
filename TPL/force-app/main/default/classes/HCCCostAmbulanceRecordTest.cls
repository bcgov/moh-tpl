@isTest
public class HCCCostAmbulanceRecordTest {
	@isTest
    static void testAmbulanceRecordsonAccount(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
		Healthcare_Cost__c hcc1 = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc3 = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        
        insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3};

        Test.startTest();
        String filterLabel = Label.TPL_All_Records;
        List <Healthcare_Cost__c> hccListforAccounts = HCCCostAmbulanceRecord.getHealthcareCostsAmbulanceForAccount(acc.Id, filterLabel);
        Test.stopTest();
        System.assertEquals(3, hccListforAccounts.size());
    }
    
    @isTest
    static void testAmbulanceRecordsonFilteredAccount(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
		Healthcare_Cost__c hcc1 = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc3 = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        hcc2.Cost_Include__c = false;
        hcc3.Cost_Review__c = false;
        insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3};

        String filterLabel1 = Label.TPL_Both_Checked;
        String filterLabel2 = Label.TPL_Both_Unchecked;
        String filterLabel3 = Label.TPL_Cost_Include_Checked;
        String filterLabel4 = Label.TPL_Cost_Review_Checked;
        
        Test.startTest();
        List<Healthcare_Cost__c> result1 = HCCCostAmbulanceRecord.getHealthcareCostsAmbulanceForAccount(acc.Id, filterLabel1);
        List<Healthcare_Cost__c> result2 = HCCCostAmbulanceRecord.getHealthcareCostsAmbulanceForAccount(acc.Id, filterLabel2);
        List<Healthcare_Cost__c> result3 = HCCCostAmbulanceRecord.getHealthcareCostsAmbulanceForAccount(acc.Id, filterLabel3);
        List<Healthcare_Cost__c> result4 = HCCCostAmbulanceRecord.getHealthcareCostsAmbulanceForAccount(acc.Id, filterLabel4);
        Test.stopTest();
		
        System.assertNotEquals(result1.size(), result2.size());
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
        String filterLabel = Label.TPL_All_Records;
        List <Healthcare_Cost__c> hccListforCases = HCCCostAmbulanceRecord.getHealthcareCostsAmbulanceForCase(c.Id, filterLabel);
        Test.stopTest();
        System.assertEquals(3, hccListforCases.size());
    
    }
    
    @isTest
    static void testAmbulanceRecordsCaseManualRecord(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
		Healthcare_Cost__c hcc1 = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc3 = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3};
            
        Test.startTest();
        String filterLabel = Label.TPL_Manual_Records;
        List <Healthcare_Cost__c> hccListforCases = HCCCostAmbulanceRecord.getHealthcareCostsAmbulanceForCase(c.Id, filterLabel);
        Test.stopTest();
        System.assertEquals(3, hccListforCases.size());
    
    }
    @isTest
    static void testAmbulanceRecordsDeleteWhenAll(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
		List<Healthcare_Cost__c> hccListtodelete = new List<Healthcare_Cost__c>();	
        Healthcare_Cost__c hcc1 = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        hccListtodelete.add(hcc1);
        insert hccListtodelete;

        Test.startTest();
        String filterLabel = Label.TPL_All_Records;
        String result = HCCCostAmbulanceRecord.deleteAmbulanceRecords(hccListtodelete, filterLabel);
        Test.stopTest();
        System.assertEquals('Failed', result);
    
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
		insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3}; 
            
        List<Healthcare_Cost__c> hccListtoUpdate1 = new List<Healthcare_Cost__c>();
        List<Healthcare_Cost__c> hccListtoUpdate2 = new List<Healthcare_Cost__c>();

        hccListtoUpdate1.add(hcc1);
        hccListtoUpdate2.add(hcc2);
        String caseId = c2.Id;
        Test.startTest();
        String output1 = HCCCostAmbulanceRecord.updateHCCCaseInformation(hccListtoUpdate1,caseId);
        String output2 = HCCCostAmbulanceRecord.updateHCCCaseInformation(hccListtoUpdate2,caseId);
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
        String output = HCCCostAmbulanceRecord.updateHCCCaseInformation(hccListtoUpdate1, c1.Id);
        Test.stopTest(); 
        System.assertEquals('Empty Selection', output); 
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
 
    @isTest
    static void testDeleteAmbulanceRecords(){
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
 
        List<Healthcare_Cost__c> hccListtodelete = new List<Healthcare_Cost__c>();	
        hccListtodelete.add(hcc1);
        hccListtodelete.add(hcc2);
        hccListtodelete.add(hcc3);

        insert hccListtodelete;

        Test.startTest();
        String filterLabel = Label.TPL_Manual_Records;
        String result = HCCCostAmbulanceRecord.deleteAmbulanceRecords(hccListtodelete, filterLabel);
        Test.stopTest();
        System.assertEquals('Passed', result);
    }
}