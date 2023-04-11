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
        Healthcare_Cost__c hcc4 = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc5 = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc6 = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc7 = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc8 = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc9 = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc10 = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc11 = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc12 = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3, hcc4, hcc5, hcc6, hcc7, hcc8, hcc9, hcc10, hcc11, hcc12};
            
        HCCCostAmbulanceRecord.HCCostAmbulanceDetailWrapper accountDetailWrapper1 = new HCCCostAmbulanceRecord.HCCostAmbulanceDetailWrapper();
        HCCCostAmbulanceRecord.HCCostAmbulanceDetailWrapper accountDetailWrapper2 = new HCCCostAmbulanceRecord.HCCostAmbulanceDetailWrapper();
        
        Test.startTest();
        String filterAllRecords = Label.TPL_All_Records;
        String filterUncheckedRecords = Label.TPL_Both_Unchecked;
        Integer pageNumber = 2;
        Integer pageSize = 5;
        accountDetailWrapper1 = HCCCostAmbulanceRecord.getHealthcareCostsAmbulanceForAccount(acc.Id, filterAllRecords, pageNumber, pageSize);
        accountDetailWrapper2 = HCCCostAmbulanceRecord.getHealthcareCostsAmbulanceForAccount(acc.Id, filterUncheckedRecords, pageNumber, pageSize);
        Test.stopTest();
        System.assertNotEquals(accountDetailWrapper1.totalCount, accountDetailWrapper2.totalCount);
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
        String allRecords = Label.TPL_All_Records;
        String manualRecords = Label.TPL_Manual_Records;
        String recordsCreatedtoday = Label.TPL_Records_Created_Today;
        Integer offsetSize = 0;
        Integer limitSize = 5;
        
        List <Healthcare_Cost__c> hccListforAllRecords = HCCCostAmbulanceRecord.getHealthcareCostsAmbulanceForCase(c.Id, allRecords, offsetSize, limitSize);
        List <Healthcare_Cost__c> hccListforManualRecords = HCCCostAmbulanceRecord.getHealthcareCostsAmbulanceForCase(c.Id, manualRecords, offsetSize, limitSize);
        List <Healthcare_Cost__c> hccListforRecordsCreatedToday = HCCCostAmbulanceRecord.getHealthcareCostsAmbulanceForCase(c.Id, recordsCreatedtoday, offsetSize, limitSize);
        Test.stopTest();
        System.assertEquals(hccListforManualRecords.size(), hccListforRecordsCreatedToday.size());
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

        Test.startTest();
        String filterAllRecords = Label.TPL_All_Records;
        String filterUncheckedRecords = Label.TPL_Both_Unchecked;
        Integer pageNumber = 1;
        Integer pageSize = 5;
        
        HCCCostAmbulanceRecord.HCCostAmbulanceDetailWrapper accountDetailWrapper1 = HCCCostAmbulanceRecord.getHealthcareCostsAmbulanceForAccount(acc.Id, filterAllRecords, pageNumber, pageSize);
        HCCCostAmbulanceRecord.HCCostAmbulanceDetailWrapper accountDetailWrapper2 = HCCCostAmbulanceRecord.getHealthcareCostsAmbulanceForAccount(acc.Id, filterUncheckedRecords, pageNumber, pageSize);
        HCCCostAmbulanceRecord.HCCostAccountCaseWrapper accountCaseUpdateWrapper1 = new HCCCostAmbulanceRecord.HCCostAccountCaseWrapper(); 
        HCCCostAmbulanceRecord.HCCostAccountCaseWrapper accountCaseUpdateWrapper2 = new HCCCostAmbulanceRecord.HCCostAccountCaseWrapper();
        List<Healthcare_Cost__c> caseAssociation1 = new List<Healthcare_Cost__c>();
        List<Healthcare_Cost__c> caseAssociation2 = new List<Healthcare_Cost__c>();
        caseAssociation1 = accountDetailWrapper1.hccList;
        caseAssociation2 = accountDetailWrapper2.hccList;
        String caseId = c2.Id;
        
        accountCaseUpdateWrapper1 = HCCCostAmbulanceRecord.updateHCCCaseInformation(caseAssociation1, caseId, caseAssociation1);
        accountCaseUpdateWrapper2 = HCCCostAmbulanceRecord.updateHCCCaseInformation(caseAssociation2, caseId, caseAssociation2);
        HCCCostAmbulanceRecord.updateHCCCaseInformation(caseAssociation2, null, caseAssociation2);
        Test.stopTest(); 
        System.assertNotEquals(accountCaseUpdateWrapper1.passMessage, accountCaseUpdateWrapper2.passMessage);
        
    }
    
    @isTest
    static void testAmbulanceCountonCase(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c1 = TestDataFactory.newCase(acc.Id);
        insert c1;
        Healthcare_Cost__c hcc = TestDataFactory.ambulanceCostRecord(acc.Id, c1.Id);
        insert hcc;
       
        Test.startTest();
        String manualRecords = Label.TPL_Manual_Records;
        String allRecords = Label.TPL_All_Records;
        String recordsCreatedToday = Label.TPL_Records_Created_Today;
        Integer output1 = HCCCostAmbulanceRecord.getAmbulanceCountonCase(c1.Id, allRecords);
        Integer output2 = HCCCostAmbulanceRecord.getAmbulanceCountonCase(c1.Id, manualRecords);
        Integer output3 = HCCCostAmbulanceRecord.getAmbulanceCountonCase(c1.Id, recordsCreatedToday);
        Test.stopTest();
        System.assertEquals(output2, output3);
    }
   
}