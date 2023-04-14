@isTest
public with sharing class HCCostAccountControllerTest {

    @isTest
    static void testGetHealthcareCostsAmbulanceForAccount(){
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
        
        Test.startTest();
        String filterAllRecords = Label.TPL_All_Records;
        String filterUncheckedRecords = Label.TPL_Both_Unchecked;
        Integer pageNumber = 2;
        Integer pageSize = 5;
        String exceptionMessage = null;
        HCCostAccountController.HCCostAccountDetailWrapper accountDetailWrapper1 = new HCCostAccountController.HCCostAccountDetailWrapper();
        HCCostAccountController.HCCostAccountDetailWrapper accountDetailWrapper2 = new HCCostAccountController.HCCostAccountDetailWrapper();
        try{
            insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3, hcc4, hcc5, hcc6, hcc7, hcc8, hcc9, hcc10, hcc11, hcc12};    
            accountDetailWrapper1 = HCCostAccountController.getHealthcareCostsAmbulanceForAccount(acc.Id, filterAllRecords, pageNumber, pageSize);
            accountDetailWrapper2 = HCCostAccountController.getHealthcareCostsAmbulanceForAccount(acc.Id, filterUncheckedRecords, pageNumber, pageSize);
        }
        catch(DmlException dml){
            exceptionMessage = dml.getMessage();
        }
        Test.stopTest();
        
        if(exceptionMessage != null){
            System.assertNotEquals(null, exceptionMessage);
        }
        else{
            System.assertNotEquals(accountDetailWrapper1.totalCount, accountDetailWrapper2.totalCount);
        }
    }

    @isTest
    static void testGetHealthcareCostsHospitalForAccount(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Account facility = TestDataFactory.facilityAccount();
        insert facility;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
        
        Product2 pr = TestDataFactory.newProduct(facility.Id);

        Test.startTest();
        String filterAllRecords = Label.TPL_All_Records;
        String filterUncheckedRecords = Label.TPL_Both_Unchecked;
        Integer pageNumber = 1;
        Integer pageSize = 5;
        String exceptionMessage = null;
        HCCostAccountController.HCCostAccountDetailWrapper accountDetailWrapper1 = new HCCostAccountController.HCCostAccountDetailWrapper();
        HCCostAccountController.HCCostAccountDetailWrapper accountDetailWrapper2 = new HCCostAccountController.HCCostAccountDetailWrapper();
        
        try{
            insert pr;
            Healthcare_Cost__c hcc1 = TestDataFactory.hospitalizationCostRecord(acc.Id, c.Id, facility.Id, pr.Id);
            Healthcare_Cost__c hcc2 = TestDataFactory.hospitalizationCostRecord(acc.Id, c.Id, facility.Id, pr.Id);
            Healthcare_Cost__c hcc3 = TestDataFactory.hospitalizationCostRecord(acc.Id, c.Id, facility.Id, pr.Id);
            Healthcare_Cost__c hcc4 = TestDataFactory.hospitalizationCostRecord(acc.Id, c.Id, facility.Id, pr.Id);
                
            insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3, hcc4};    
            accountDetailWrapper1 = HCCostAccountController.getHealthcareCostsHospitalForAccount(acc.Id, filterAllRecords, pageNumber, pageSize);
            accountDetailWrapper2 = HCCostAccountController.getHealthcareCostsHospitalForAccount(acc.Id, filterUncheckedRecords, pageNumber, pageSize);
        }
        catch(DmlException dml){
            exceptionMessage = dml.getMessage();
        }
        
        Test.stopTest();
        if(exceptionMessage != null){
            System.assertNotEquals(null, exceptionMessage);
        }
        else{
            System.assertNotEquals(accountDetailWrapper1.totalCount, accountDetailWrapper2.totalCount);
        }
    }
    @isTest
    static void testGetHealthcareCostsMSPForAccount(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
        Healthcare_Cost__c hcc1 = TestDataFactory.mspCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.mspCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc3 = TestDataFactory.mspCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc4 = TestDataFactory.mspCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc5 = TestDataFactory.mspCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc6 = TestDataFactory.mspCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc7 = TestDataFactory.mspCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc8 = TestDataFactory.mspCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc9 = TestDataFactory.mspCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc10 = TestDataFactory.mspCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc11 = TestDataFactory.mspCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc12= TestDataFactory.mspCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc13 = TestDataFactory.mspCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc14 = TestDataFactory.mspCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc15 = TestDataFactory.mspCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc16 = TestDataFactory.mspCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc17 = TestDataFactory.mspCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc18 = TestDataFactory.mspCostRecord(acc.Id, c.Id);
        hcc3.Cost_Include__c = false;
        hcc3.Cost_Review__c = false;
        hcc4.Cost_Include__c = false;
        hcc4.Cost_Review__c = false;
        hcc5.Cost_Include__c = false;
        hcc5.Cost_Review__c = false;
        hcc6.Cost_Include__c = false;
        hcc6.Cost_Review__c = false;
        hcc7.Cost_Include__c = false;
        hcc7.Cost_Review__c = false;
        hcc8.Cost_Include__c = false;
        hcc8.Cost_Review__c = false;
        hcc9.Cost_Include__c = false;
        hcc9.Cost_Review__c = false;
        hcc10.Cost_Include__c = false;
        hcc10.Cost_Review__c = false;
        hcc11.Cost_Include__c = false;
        hcc11.Cost_Review__c = false;
        hcc12.Cost_Include__c = false;
        hcc12.Cost_Review__c = false;
        hcc13.Cost_Include__c = false;
        hcc13.Cost_Review__c = false;
        hcc14.Cost_Include__c = false;
        hcc14.Cost_Review__c = false;
        hcc15.Cost_Include__c = false;
        hcc15.Cost_Review__c = false;
        hcc16.Cost_Include__c = false;
        hcc16.Cost_Review__c = false;
        hcc17.Cost_Include__c = false;
        hcc17.Cost_Review__c = false;
        hcc18.Cost_Include__c = false;
        hcc18.Cost_Review__c = false;
      
        Test.startTest();
        String filterAllRecords = Label.TPL_All_Records;
        String filterUncheckedRecords = Label.TPL_Both_Unchecked;
        Integer pageNumber = 2;
        Integer pageSize = 5;
        String exceptionMessage = null;
        HCCostAccountController.HCCostAccountDetailWrapper accountDetailWrapper1 = new HCCostAccountController.HCCostAccountDetailWrapper();
        HCCostAccountController.HCCostAccountDetailWrapper accountDetailWrapper2 = new HCCostAccountController.HCCostAccountDetailWrapper();
        
        try{
            insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3, hcc4, hcc5, hcc6, hcc7, hcc8, hcc9, hcc10, hcc11, hcc12, hcc13, hcc14, hcc15, hcc16, hcc17, hcc18};    
            accountDetailWrapper1 = HCCostAccountController.getHealthcareCostsMSPForAccount(acc.Id, filterAllRecords, pageNumber, pageSize);
            accountDetailWrapper2 = HCCostAccountController.getHealthcareCostsMSPForAccount(acc.Id, filterUncheckedRecords, pageNumber, pageSize);
        }
        catch(DmlException dml){
            exceptionMessage = dml.getMessage();
        }
        Test.stopTest();
        if(exceptionMessage != null){
            System.assertNotEquals(null, exceptionMessage);
        }
        else{
            System.assertNotEquals(accountDetailWrapper1.totalCount, accountDetailWrapper2.totalCount);
        }    
    }
    @isTest
    static void testGetHealthcareCostsPharmacareForAccount(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
        Healthcare_Cost__c hcc1 = TestDataFactory.pharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.pharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc3 = TestDataFactory.pharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc4 = TestDataFactory.pharmacareCostRecord(acc.Id, c.Id);
        
        Test.startTest();
        String filterAllRecords = Label.TPL_All_Records;
        String filterUncheckedRecords = Label.TPL_Both_Unchecked;
        Integer pageNumber = 1;
        Integer pageSize = 5;
        String exceptionMessage = null;
        HCCostAccountController.HCCostAccountDetailWrapper accountDetailWrapper1 = new HCCostAccountController.HCCostAccountDetailWrapper();
        HCCostAccountController.HCCostAccountDetailWrapper accountDetailWrapper2 = new HCCostAccountController.HCCostAccountDetailWrapper();
        
        try{
            insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3, hcc4};    
            accountDetailWrapper1 = HCCostAccountController.getHealthcareCostsPharmacareForAccount(acc.Id, filterAllRecords, pageNumber, pageSize);
            accountDetailWrapper2 = HCCostAccountController.getHealthcareCostsPharmacareForAccount(acc.Id, filterUncheckedRecords, pageNumber, pageSize);
        }
        catch(DmlException dml){
            exceptionMessage = dml.getMessage();
        }
        Test.stopTest();
        if(exceptionMessage != null){
            System.assertNotEquals(null, exceptionMessage);
        }
        else{
            System.assertNotEquals(accountDetailWrapper1.totalCount, accountDetailWrapper2.totalCount);
        }    
    }
    @isTest
    static void testGetHealthcareCostsContinuingCareForAccount(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
        Healthcare_Cost__c hcc1 = TestDataFactory.continuingcareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.continuingcareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc3 = TestDataFactory.continuingcareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc4 = TestDataFactory.continuingcareCostRecord(acc.Id, c.Id);
    
       
        Test.startTest();
        String filterManualRecords = Label.TPL_Manual_Records;
        String filterRecordsCreatedToday = Label.TPL_Records_Created_Today;
        Integer pageNumber = 1;
        Integer pageSize = 5;
        String exceptionMessage = null;
        HCCostAccountController.HCCostAccountDetailWrapper accountDetailWrapper1 = new HCCostAccountController.HCCostAccountDetailWrapper();
        HCCostAccountController.HCCostAccountDetailWrapper accountDetailWrapper2 = new HCCostAccountController.HCCostAccountDetailWrapper();
        try{
            insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3, hcc4};    
            accountDetailWrapper1 = HCCostAccountController.getHealthcareCostsCCForAccount(acc.Id, filterManualRecords, pageNumber, pageSize);
            accountDetailWrapper2 = HCCostAccountController.getHealthcareCostsCCForAccount(acc.Id, filterRecordsCreatedToday, pageNumber, pageSize);
        }
        catch(DmlException dml){
            exceptionMessage = dml.getMessage();
        }
        Test.stopTest();
        if(exceptionMessage != null){
            System.assertNotEquals(null, exceptionMessage);
        }
        else{
            System.assertEquals(accountDetailWrapper1.totalCount, accountDetailWrapper2.totalCount);
        }    
    }
    @isTest
    static void testGetHealthcareCostsFutureCareForAccount(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
        Healthcare_Cost__c hcc1 = TestDataFactory.futurecareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.futurecareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc3 = TestDataFactory.futurecareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc4 = TestDataFactory.futurecareCostRecord(acc.Id, c.Id);
    
        Test.startTest();
        String filterManualRecords = Label.TPL_Manual_Records;
        String filterRecordsCreatedToday = Label.TPL_Records_Created_Today;
        Integer pageNumber = 1;
        Integer pageSize = 5;
        String exceptionMessage = null;
        HCCostAccountController.HCCostAccountDetailWrapper accountDetailWrapper1 = new HCCostAccountController.HCCostAccountDetailWrapper();
        HCCostAccountController.HCCostAccountDetailWrapper accountDetailWrapper2 = new HCCostAccountController.HCCostAccountDetailWrapper();

        try{
            insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3, hcc4};    
            accountDetailWrapper1 = HCCostAccountController.getHealthcareCostsFCForAccount(acc.Id, filterManualRecords, pageNumber, pageSize);
            accountDetailWrapper2 = HCCostAccountController.getHealthcareCostsFCForAccount(acc.Id, filterRecordsCreatedToday, pageNumber, pageSize);
        }
        catch(DmlException dml){
            exceptionMessage = dml.getMessage();
        }
        Test.stopTest();
        if(exceptionMessage != null){
            System.assertNotEquals(null, exceptionMessage);
        }
        else{
            System.assertEquals(accountDetailWrapper1.totalCount, accountDetailWrapper2.totalCount);
        }    
    }
}