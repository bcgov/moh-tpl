@isTest
public class HCCCostPharmacareRecordTest {
    @isTest
    static void testHealthcareCostsPharmacareForAccount(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
		Healthcare_Cost__c hcc1 = TestDataFactory.PharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.PharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc3 = TestDataFactory.PharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc4 = TestDataFactory.PharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc5 = TestDataFactory.PharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc6 = TestDataFactory.PharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc7 = TestDataFactory.PharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc8 = TestDataFactory.PharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc9 = TestDataFactory.PharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc10 = TestDataFactory.PharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc11 = TestDataFactory.PharmacareCostRecord(acc.Id, c.Id);
        insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3, hcc4, hcc5, hcc6, hcc7, hcc8, hcc9, hcc10, hcc11};
        
        insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3};

        Test.startTest();
        String filterAllRecords = Label.TPL_All_Records;
        String filterUncheckedRecords = Label.TPL_Both_Unchecked;
        Integer pageNumber = 2;
        Integer pageSize = 5;
        HCCCostPharmacareRecord.HCCostAccountDetailWrapper accountDetailWrapper1 = HCCCostPharmacareRecord.getHealthcareCostsPharmacareForAccount(acc.Id,filterAllRecords, pageNumber, pageSize);
        HCCCostPharmacareRecord.HCCostAccountDetailWrapper accountDetailWrapper2 = HCCCostPharmacareRecord.getHealthcareCostsPharmacareForAccount(acc.Id, filterUncheckedRecords, pageNumber, pageSize);
        Test.stopTest();
        System.assertNotEquals(accountDetailWrapper1.hccList.size(), accountDetailWrapper2.hccList.size());
    }
       
    @isTest
    static void testHealthcareCostsPharmacareForCase(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
		Healthcare_Cost__c hcc1 = TestDataFactory.PharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.PharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc3 = TestDataFactory.PharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc4 = TestDataFactory.PharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc5 = TestDataFactory.PharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc6 = TestDataFactory.PharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc7 = TestDataFactory.PharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc8 = TestDataFactory.PharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc9 = TestDataFactory.PharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc10 = TestDataFactory.PharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc11 = TestDataFactory.PharmacareCostRecord(acc.Id, c.Id);
        insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3, hcc4, hcc5, hcc6, hcc7, hcc8, hcc9, hcc10, hcc11};
            
        Test.startTest();
        String filterAllRecords = Label.TPL_All_Records;
        String filterManualRecords = Label.TPL_Manual_Records;
        String filterRecordsToday = Label.TPL_Records_Created_Today;
        Integer pageNumber = 1;
        Integer pageSize = 5;
        HCCCostPharmacareRecord.PharmacareCaseDetailWrapper caseDetailWrapper1 = HCCCostPharmacareRecord.getHealthcareCostsPharmacareForCase(c.Id,filterAllRecords,pageSize, pageNumber);
        HCCCostPharmacareRecord.PharmacareCaseDetailWrapper caseDetailWrapper2 = HCCCostPharmacareRecord.getHealthcareCostsPharmacareForCase(c.Id,filterManualRecords,pageSize, pageNumber);
        HCCCostPharmacareRecord.PharmacareCaseDetailWrapper caseDetailWrapper3 = HCCCostPharmacareRecord.getHealthcareCostsPharmacareForCase(c.Id,filterRecordsToday,pageSize, pageNumber);
        Test.stopTest();
        System.assertEquals(caseDetailWrapper2.hccList.size(),caseDetailWrapper3.hccList.size());
    
    }
    
    @isTest
    static void testupdateHCCCaseInformation(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c1 = TestDataFactory.newCase(acc.Id);
        Case c2 = TestDataFactory.newCase(acc.Id);
        insert  new Case[] {c1, c2};
        
		Healthcare_Cost__c hcc1 = TestDataFactory.PharmacareCostRecord(acc.Id, c1.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.PharmacareCostRecord(acc.Id, c1.Id);
        hcc2.Cost_Include__c = false;
        hcc2.Cost_Review__c = false;
        Healthcare_Cost__c hcc3 = TestDataFactory.PharmacareCostRecord(acc.Id, c1.Id);
		insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3}; 
        
        Test.startTest();
        String filterAllRecords = Label.TPL_All_Records;
        String filterUncheckedRecords = Label.TPL_Both_Unchecked;
        Integer pageNumber = 1;
        Integer pageSize = 5;

        HCCCostPharmacareRecord.HCCostAccountDetailWrapper accountDetailWrapper1 = HCCCostPharmacareRecord.getHealthcareCostsPharmacareForAccount(acc.Id, filterAllRecords, pageNumber, pageSize);
        HCCCostPharmacareRecord.HCCostAccountDetailWrapper accountDetailWrapper2 = HCCCostPharmacareRecord.getHealthcareCostsPharmacareForAccount(acc.Id, filterUncheckedRecords, pageNumber, pageSize);
        HCCCostPharmacareRecord.HCCostAccountCaseWrapper accountCaseUpdateWrapper1 = new HCCCostPharmacareRecord.HCCostAccountCaseWrapper(); 
        HCCCostPharmacareRecord.HCCostAccountCaseWrapper accountCaseUpdateWrapper2 = new HCCCostPharmacareRecord.HCCostAccountCaseWrapper();
        List<HCCCostPharmacareRecord.HCCCaseAssociationWrapper> caseAssociation1 = accountDetailWrapper1.hccList;  
        List<HCCCostPharmacareRecord.HCCCaseAssociationWrapper> caseAssociation2 = accountDetailWrapper2.hccList;
        String caseId = c2.Id;
        try{
        accountCaseUpdateWrapper1 = HCCCostPharmacareRecord.updateHCCCaseInformation(caseAssociation1, caseId, caseAssociation1);
        accountCaseUpdateWrapper2 = HCCCostPharmacareRecord.updateHCCCaseInformation(caseAssociation2, caseId, caseAssociation2);            
        }
        catch(DMLException dml){
            String exceptionMessage = dml.getDmlMessage(0);
        }
        Test.stopTest(); 
        System.assertNotEquals(accountCaseUpdateWrapper1.passMessage, accountCaseUpdateWrapper2.passMessage);
    }
   
}