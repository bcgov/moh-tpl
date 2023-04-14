@isTest
public class HCCCostMSPRecordTest {
    @isTest
    static void testMSPRecordsonAccount(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
		Healthcare_Cost__c hcc1 = TestDataFactory.MSPCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.MSPCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc3 = TestDataFactory.MSPCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc4 = TestDataFactory.MSPCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc5 = TestDataFactory.MSPCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc6 = TestDataFactory.MSPCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc7 = TestDataFactory.MSPCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc8 = TestDataFactory.MSPCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc9 = TestDataFactory.MSPCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc10 = TestDataFactory.MSPCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc11 = TestDataFactory.MSPCostRecord(acc.Id, c.Id);
        insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3, hcc4, hcc5, hcc6, hcc7, hcc8, hcc9, hcc10, hcc11};

        Test.startTest();
        String filterAllRecords = Label.TPL_All_Records;
        String filterUncheckedRecords = Label.TPL_Both_Unchecked;
        Integer pageNumber = 2;
        Integer pageSize = 5;
        HCCCostMSPRecord.HCCostMSPDetailWrapper accountDetailWrapper1 = HCCCostMSPRecord.getHealthcareCostsMSPForAccount(acc.Id,filterAllRecords, pageNumber, pageSize);
        HCCCostMSPRecord.HCCostMSPDetailWrapper accountDetailWrapper2 = HCCCostMSPRecord.getHealthcareCostsMSPForAccount(acc.Id, filterUncheckedRecords, pageNumber, pageSize);
        Test.stopTest();
        System.assertNotEquals(accountDetailWrapper1.hccList.size(), accountDetailWrapper2.hccList.size());
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
        Healthcare_Cost__c hcc4 = TestDataFactory.MSPCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc5 = TestDataFactory.MSPCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc6 = TestDataFactory.MSPCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc7 = TestDataFactory.MSPCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc8 = TestDataFactory.MSPCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc9 = TestDataFactory.MSPCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc10 = TestDataFactory.MSPCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc11 = TestDataFactory.MSPCostRecord(acc.Id, c.Id);
        insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3, hcc4, hcc5, hcc6, hcc7, hcc8, hcc9, hcc10, hcc11};
            
        Test.startTest();
        String filterAllRecords = Label.TPL_All_Records;
        String filterManualRecords = Label.TPL_Manual_Records;
        String filterRecordsToday = Label.TPL_Records_Created_Today;
        Integer pageNumber = 1;
        Integer pageSize = 5;
        HCCCostMSPRecord.HCCostMSPDetailWrapper caseDetailWrapper1 = HCCCostMSPRecord.getHealthcareCostsMSPForCase(c.Id,filterAllRecords,pageSize, pageNumber);
        HCCCostMSPRecord.HCCostMSPDetailWrapper caseDetailWrapper2 = HCCCostMSPRecord.getHealthcareCostsMSPForCase(c.Id,filterManualRecords,pageSize, pageNumber);
        HCCCostMSPRecord.HCCostMSPDetailWrapper caseDetailWrapper3 = HCCCostMSPRecord.getHealthcareCostsMSPForCase(c.Id,filterRecordsToday,pageSize, pageNumber);
        Test.stopTest();
        System.assertEquals(caseDetailWrapper2.hccList.size(),caseDetailWrapper3.hccList.size());
    
    }
   
   @isTest
   static void testUpdateHCCCaseInformation (){
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
    
    Test.startTest();
    String filterAllRecords = Label.TPL_All_Records;
    String filterUncheckedRecords = Label.TPL_Both_Unchecked;
    Integer pageNumber = 1;
    Integer pageSize = 5;

    HCCCostMSPRecord.HCCostMSPDetailWrapper accountDetailWrapper1 = HCCCostMSPRecord.getHealthcareCostsMSPForAccount(acc.Id, filterAllRecords, pageNumber, pageSize);
    HCCCostMSPRecord.HCCostMSPDetailWrapper accountDetailWrapper2 = HCCCostMSPRecord.getHealthcareCostsMSPForAccount(acc.Id, filterUncheckedRecords, pageNumber, pageSize);
    HCCCostMSPRecord.HCCostAccountCaseWrapper accountCaseUpdateWrapper1 = new HCCCostMSPRecord.HCCostAccountCaseWrapper(); 
    HCCCostMSPRecord.HCCostAccountCaseWrapper accountCaseUpdateWrapper2 = new HCCCostMSPRecord.HCCostAccountCaseWrapper();
    List<Healthcare_Cost__c> caseAssociation1 = new List<Healthcare_Cost__c>();
    List<Healthcare_Cost__c> caseAssociation2 = new List<Healthcare_Cost__c>();     
    caseAssociation1 = accountDetailWrapper1.hccList;
    caseAssociation2 = accountDetailWrapper2.hccList;
    String caseId = c2.Id;
    try{
        accountCaseUpdateWrapper1 = HCCCostMSPRecord.updateHCCCaseInformation(caseAssociation1, caseId, caseAssociation1);
        accountCaseUpdateWrapper2 = HCCCostMSPRecord.updateHCCCaseInformation(caseAssociation2, caseId, caseAssociation2); 
        HCCCostMSPRecord.updateHCCCaseInformation(caseAssociation2, null, caseAssociation2); 
    }
    catch(DMLException dml){
        String exceptionMessage = dml.getDmlMessage(0);
    }
    Test.stopTest(); 
    System.assertNotEquals(accountCaseUpdateWrapper1.passMessage, accountCaseUpdateWrapper2.passMessage);
   }
}