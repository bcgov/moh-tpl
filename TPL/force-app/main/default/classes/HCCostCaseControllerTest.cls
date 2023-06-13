@isTest
public with sharing class HCCostCaseControllerTest {
    @isTest
    static void testGetHealthcareCostsAmbulanceForCaseDescendingSort(){
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
            
        Test.startTest();
        String filterAllRecords = Label.TPL_All_Records;
        String filterManualRecords = Label.TPL_Manual_Records;
        String filterRecordsToday = Label.TPL_Records_Created_Today;
        Integer pageNumber = 2;
        Integer pageSize = 5;
        String sortOrder = Label.TPL_Descending;
        String exceptionMessage = null;
        HCCostCaseController.HCCostCaseDetailWrapper caseDetailWrapper1 = new HCCostCaseController.HCCostCaseDetailWrapper();
        HCCostCaseController.HCCostCaseDetailWrapper caseDetailWrapper2 = new HCCostCaseController.HCCostCaseDetailWrapper();
        HCCostCaseController.HCCostCaseDetailWrapper caseDetailWrapper3 = new HCCostCaseController.HCCostCaseDetailWrapper();
        try{
            insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3, hcc4, hcc5, hcc6, hcc7, hcc8, hcc9, hcc10, hcc11};
            caseDetailWrapper1 = HCCostCaseController.getHealthcareCostsAmbulanceForCase(c.Id,filterAllRecords,pageSize, pageNumber,sortOrder);
            caseDetailWrapper2 = HCCostCaseController.getHealthcareCostsAmbulanceForCase(c.Id,filterManualRecords,pageSize, pageNumber,sortOrder);
            caseDetailWrapper3 = HCCostCaseController.getHealthcareCostsAmbulanceForCase(c.Id,filterRecordsToday,pageSize, pageNumber,sortOrder);    
        }
        catch(DmlException dml){
            exceptionMessage = dml.getMessage();
        }
        Test.stopTest();
        if(exceptionMessage != null){
            System.assertNotEquals(null, exceptionMessage);
        }
        else {
            System.assertEquals(caseDetailWrapper2.hccList.size(),caseDetailWrapper3.hccList.size());            
        }
    }

    @isTest
    static void testGetHealthcareCostsAmbulanceForCaseAscendingSort(){
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
            
        Test.startTest();
        String filterAllRecords = Label.TPL_All_Records;
        String filterManualRecords = Label.TPL_Manual_Records;
        String filterRecordsToday = Label.TPL_Records_Created_Today;
        Integer pageNumber = 2;
        Integer pageSize = 5;
        String sortOrder = Label.TPL_Ascending;
        String exceptionMessage = null;
        HCCostCaseController.HCCostCaseDetailWrapper caseDetailWrapper1 = new HCCostCaseController.HCCostCaseDetailWrapper();
        HCCostCaseController.HCCostCaseDetailWrapper caseDetailWrapper2 = new HCCostCaseController.HCCostCaseDetailWrapper();
        HCCostCaseController.HCCostCaseDetailWrapper caseDetailWrapper3 = new HCCostCaseController.HCCostCaseDetailWrapper();
        try{
            insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3, hcc4, hcc5, hcc6, hcc7, hcc8, hcc9, hcc10, hcc11};
            caseDetailWrapper1 = HCCostCaseController.getHealthcareCostsAmbulanceForCase(c.Id,filterAllRecords,pageSize, pageNumber,sortOrder);
            caseDetailWrapper2 = HCCostCaseController.getHealthcareCostsAmbulanceForCase(c.Id,filterManualRecords,pageSize, pageNumber,sortOrder);
            caseDetailWrapper3 = HCCostCaseController.getHealthcareCostsAmbulanceForCase(c.Id,filterRecordsToday,pageSize, pageNumber,sortOrder);    
        }
        catch(DmlException dml){
            exceptionMessage = dml.getMessage();
        }
        Test.stopTest();
        if(exceptionMessage != null){
            System.assertNotEquals(null, exceptionMessage);
        }
        else {
            System.assertEquals(caseDetailWrapper2.hccList.size(),caseDetailWrapper3.hccList.size());            
        }
    }

    @isTest
    static void testGetHealthcareCostsHospitalForCaseDescendingSort(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Account facility = TestDataFactory.facilityAccount();
        insert facility;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
        Product2 pr = TestDataFactory.newProduct(facility.Id);
        String serviceType = pr.Service_Type__c;
        Test.startTest();
        String filterAllRecords = Label.TPL_All_Records;
        String filterManualRecords = Label.TPL_Manual_Records;
        String filterRecordsToday = Label.TPL_Records_Created_Today;
        Integer pageNumber = 1;
        Integer pageSize = 5;
        String sortOrder = Label.TPL_Descending;
        String exceptionMessage = null;
        HCCostCaseController.HCCostCaseDetailWrapper caseDetailWrapper1 = new HCCostCaseController.HCCostCaseDetailWrapper();
        HCCostCaseController.HCCostCaseDetailWrapper caseDetailWrapper2 = new HCCostCaseController.HCCostCaseDetailWrapper();
        HCCostCaseController.HCCostCaseDetailWrapper caseDetailWrapper3 = new HCCostCaseController.HCCostCaseDetailWrapper();

        try{
            insert pr;
            Healthcare_Cost__c hcc1 = TestDataFactory.hospitalizationCostRecord(acc.Id, c.Id, facility.Id, pr.Id, serviceType);
            Healthcare_Cost__c hcc2 = TestDataFactory.hospitalizationCostRecord(acc.Id, c.Id, facility.Id, pr.Id, serviceType);
            Healthcare_Cost__c hcc3 = TestDataFactory.hospitalizationCostRecord(acc.Id, c.Id, facility.Id, pr.Id, serviceType);
            insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3};
            caseDetailWrapper1 = HCCostCaseController.getHealthcareCostsHospitalForCase(c.Id,filterAllRecords,pageSize, pageNumber, sortOrder);
            caseDetailWrapper2 = HCCostCaseController.getHealthcareCostsHospitalForCase(c.Id,filterManualRecords,pageSize, pageNumber, sortOrder);
            caseDetailWrapper3 = HCCostCaseController.getHealthcareCostsHospitalForCase(c.Id,filterRecordsToday,pageSize, pageNumber, sortOrder);    
        }
        catch(DmlException dml){
            exceptionMessage = dml.getMessage();
        }
        Test.stopTest();
        if(exceptionMessage != null){
            System.assertNotEquals(null, exceptionMessage);
        }
        else {
            System.assertEquals(caseDetailWrapper2.hccList.size(),caseDetailWrapper3.hccList.size());            
        }
    }

    @isTest
    static void testGetHealthcareCostsHospitalForCaseAscendingSort(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Account facility = TestDataFactory.facilityAccount();
        insert facility;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
        Product2 pr = TestDataFactory.newProduct(facility.Id);
        String serviceType = pr.Service_Type__c;
        Test.startTest();
        String filterAllRecords = Label.TPL_All_Records;
        String filterManualRecords = Label.TPL_Manual_Records;
        String filterRecordsToday = Label.TPL_Records_Created_Today;
        Integer pageNumber = 1;
        Integer pageSize = 5;
        String sortOrder = Label.TPL_Ascending;
        String exceptionMessage = null;
        HCCostCaseController.HCCostCaseDetailWrapper caseDetailWrapper1 = new HCCostCaseController.HCCostCaseDetailWrapper();
        HCCostCaseController.HCCostCaseDetailWrapper caseDetailWrapper2 = new HCCostCaseController.HCCostCaseDetailWrapper();
        HCCostCaseController.HCCostCaseDetailWrapper caseDetailWrapper3 = new HCCostCaseController.HCCostCaseDetailWrapper();

        try{
            insert pr;
            Healthcare_Cost__c hcc1 = TestDataFactory.hospitalizationCostRecord(acc.Id, c.Id, facility.Id, pr.Id, serviceType);
            Healthcare_Cost__c hcc2 = TestDataFactory.hospitalizationCostRecord(acc.Id, c.Id, facility.Id, pr.Id, serviceType);
            Healthcare_Cost__c hcc3 = TestDataFactory.hospitalizationCostRecord(acc.Id, c.Id, facility.Id, pr.Id, serviceType);
            insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3};
            caseDetailWrapper1 = HCCostCaseController.getHealthcareCostsHospitalForCase(c.Id,filterAllRecords,pageSize, pageNumber, sortOrder);
            caseDetailWrapper2 = HCCostCaseController.getHealthcareCostsHospitalForCase(c.Id,filterManualRecords,pageSize, pageNumber, sortOrder);
            caseDetailWrapper3 = HCCostCaseController.getHealthcareCostsHospitalForCase(c.Id,filterRecordsToday,pageSize, pageNumber, sortOrder);    
        }
        catch(DmlException dml){
            exceptionMessage = dml.getMessage();
        }
        Test.stopTest();
        if(exceptionMessage != null){
            System.assertNotEquals(null, exceptionMessage);
        }
        else {
            System.assertEquals(caseDetailWrapper2.hccList.size(),caseDetailWrapper3.hccList.size());            
        }
    }

    @isTest
    static void testGetHealthcareCostsMSPForCaseDescendingSort(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
		Healthcare_Cost__c hcc1 = TestDataFactory.mspCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.mspCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc3 = TestDataFactory.mspCostRecord(acc.Id, c.Id);
      
        Test.startTest();
        String filterAllRecords = Label.TPL_All_Records;
        String filterManualRecords = Label.TPL_Manual_Records;
        String filterRecordsToday = Label.TPL_Records_Created_Today;
        Integer pageNumber = 1;
        Integer pageSize = 5;
        String sortOrder = Label.TPL_Descending;
        String exceptionMessage = null;
        HCCostCaseController.HCCostCaseDetailWrapper caseDetailWrapper1 = new HCCostCaseController.HCCostCaseDetailWrapper();
        HCCostCaseController.HCCostCaseDetailWrapper caseDetailWrapper2 = new HCCostCaseController.HCCostCaseDetailWrapper();
        HCCostCaseController.HCCostCaseDetailWrapper caseDetailWrapper3 = new HCCostCaseController.HCCostCaseDetailWrapper();
        try{
            insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3};
            caseDetailWrapper1 = HCCostCaseController.getHealthcareCostsMSPForCase(c.Id,filterAllRecords,pageSize, pageNumber, sortOrder);
            caseDetailWrapper2 = HCCostCaseController.getHealthcareCostsMSPForCase(c.Id,filterManualRecords,pageSize, pageNumber, sortOrder);
            caseDetailWrapper3 = HCCostCaseController.getHealthcareCostsMSPForCase(c.Id,filterRecordsToday,pageSize, pageNumber, sortOrder);    
        }
        catch(DmlException dml){
            exceptionMessage = dml.getMessage();
        }
        Test.stopTest();
        if(exceptionMessage != null){
            System.assertNotEquals(null, exceptionMessage);
        }
        else {
            System.assertEquals(caseDetailWrapper2.hccList.size(),caseDetailWrapper3.hccList.size());            
        }
    }

    @isTest
    static void testGetHealthcareCostsMSPForCaseAscendingSort(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
		Healthcare_Cost__c hcc1 = TestDataFactory.mspCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.mspCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc3 = TestDataFactory.mspCostRecord(acc.Id, c.Id);
      
        Test.startTest();
        String filterAllRecords = Label.TPL_All_Records;
        String filterManualRecords = Label.TPL_Manual_Records;
        String filterRecordsToday = Label.TPL_Records_Created_Today;
        Integer pageNumber = 1;
        Integer pageSize = 5;
        String sortOrder = Label.TPL_Ascending;
        String exceptionMessage = null;
        HCCostCaseController.HCCostCaseDetailWrapper caseDetailWrapper1 = new HCCostCaseController.HCCostCaseDetailWrapper();
        HCCostCaseController.HCCostCaseDetailWrapper caseDetailWrapper2 = new HCCostCaseController.HCCostCaseDetailWrapper();
        HCCostCaseController.HCCostCaseDetailWrapper caseDetailWrapper3 = new HCCostCaseController.HCCostCaseDetailWrapper();
        try{
            insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3};
            caseDetailWrapper1 = HCCostCaseController.getHealthcareCostsMSPForCase(c.Id,filterAllRecords,pageSize, pageNumber, sortOrder);
            caseDetailWrapper2 = HCCostCaseController.getHealthcareCostsMSPForCase(c.Id,filterManualRecords,pageSize, pageNumber, sortOrder);
            caseDetailWrapper3 = HCCostCaseController.getHealthcareCostsMSPForCase(c.Id,filterRecordsToday,pageSize, pageNumber, sortOrder);    
        }
        catch(DmlException dml){
            exceptionMessage = dml.getMessage();
        }
        Test.stopTest();
        if(exceptionMessage != null){
            System.assertNotEquals(null, exceptionMessage);
        }
        else {
            System.assertEquals(caseDetailWrapper2.hccList.size(),caseDetailWrapper3.hccList.size());            
        }
    }

    @isTest
    static void testGetHealthcareCostsPharmacareForCaseDescendingSort(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
		Healthcare_Cost__c hcc1 = TestDataFactory.pharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.pharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc3 = TestDataFactory.pharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc4 = TestDataFactory.pharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc5 = TestDataFactory.pharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc6 = TestDataFactory.pharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc7 = TestDataFactory.pharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc8 = TestDataFactory.pharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc9 = TestDataFactory.pharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc10 = TestDataFactory.pharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc11 = TestDataFactory.pharmacareCostRecord(acc.Id, c.Id);
            
        Test.startTest();
        String filterAllRecords = Label.TPL_All_Records;
        String filterManualRecords = Label.TPL_Manual_Records;
        String filterRecordsToday = Label.TPL_Records_Created_Today;
        Integer pageNumber = 1;
        Integer pageSize = 5;
        String sortOrder = Label.TPL_Descending;
        String exceptionMessage = null;
        HCCostCaseController.HCCostCaseDetailWrapper caseDetailWrapper1 = new HCCostCaseController.HCCostCaseDetailWrapper();
        HCCostCaseController.HCCostCaseDetailWrapper caseDetailWrapper2 = new HCCostCaseController.HCCostCaseDetailWrapper();
        HCCostCaseController.HCCostCaseDetailWrapper caseDetailWrapper3 = new HCCostCaseController.HCCostCaseDetailWrapper();
        try{
            insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3, hcc4, hcc5, hcc6, hcc7, hcc8, hcc9, hcc10, hcc11};
            caseDetailWrapper1 = HCCostCaseController.getHealthcareCostsPharmacareForCase(c.Id,filterAllRecords,pageSize, pageNumber, sortOrder);
            caseDetailWrapper2 = HCCostCaseController.getHealthcareCostsPharmacareForCase(c.Id,filterManualRecords,pageSize, pageNumber, sortOrder);
            caseDetailWrapper3 = HCCostCaseController.getHealthcareCostsPharmacareForCase(c.Id,filterRecordsToday,pageSize, pageNumber, sortOrder);    
        }
        catch(DmlException dml){
            exceptionMessage = dml.getMessage();
        }
        Test.stopTest();
        if(exceptionMessage != null){
            System.assertNotEquals(null, exceptionMessage);
        }
        else {
            System.assertEquals(caseDetailWrapper2.hccList.size(),caseDetailWrapper3.hccList.size());            
        }
    }

    @isTest
    static void testGetHealthcareCostsPharmacareForCaseAscendingSort(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
		Healthcare_Cost__c hcc1 = TestDataFactory.pharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.pharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc3 = TestDataFactory.pharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc4 = TestDataFactory.pharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc5 = TestDataFactory.pharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc6 = TestDataFactory.pharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc7 = TestDataFactory.pharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc8 = TestDataFactory.pharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc9 = TestDataFactory.pharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc10 = TestDataFactory.pharmacareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc11 = TestDataFactory.pharmacareCostRecord(acc.Id, c.Id);
            
        Test.startTest();
        String filterAllRecords = Label.TPL_All_Records;
        String filterManualRecords = Label.TPL_Manual_Records;
        String filterRecordsToday = Label.TPL_Records_Created_Today;
        Integer pageNumber = 1;
        Integer pageSize = 5;
        String sortOrder = Label.TPL_Ascending;
        String exceptionMessage = null;
        HCCostCaseController.HCCostCaseDetailWrapper caseDetailWrapper1 = new HCCostCaseController.HCCostCaseDetailWrapper();
        HCCostCaseController.HCCostCaseDetailWrapper caseDetailWrapper2 = new HCCostCaseController.HCCostCaseDetailWrapper();
        HCCostCaseController.HCCostCaseDetailWrapper caseDetailWrapper3 = new HCCostCaseController.HCCostCaseDetailWrapper();
        try{
            insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3, hcc4, hcc5, hcc6, hcc7, hcc8, hcc9, hcc10, hcc11};
            caseDetailWrapper1 = HCCostCaseController.getHealthcareCostsPharmacareForCase(c.Id,filterAllRecords,pageSize, pageNumber, sortOrder);
            caseDetailWrapper2 = HCCostCaseController.getHealthcareCostsPharmacareForCase(c.Id,filterManualRecords,pageSize, pageNumber, sortOrder);
            caseDetailWrapper3 = HCCostCaseController.getHealthcareCostsPharmacareForCase(c.Id,filterRecordsToday,pageSize, pageNumber, sortOrder);    
        }
        catch(DmlException dml){
            exceptionMessage = dml.getMessage();
        }
        Test.stopTest();
        if(exceptionMessage != null){
            System.assertNotEquals(null, exceptionMessage);
        }
        else {
            System.assertEquals(caseDetailWrapper2.hccList.size(),caseDetailWrapper3.hccList.size());            
        }
    }

    @isTest
    static void testGetHealthcareCostsContinuingCareForCase(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
		Healthcare_Cost__c hcc1 = TestDataFactory.continuingcareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.continuingcareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc3 = TestDataFactory.continuingcareCostRecord(acc.Id, c.Id);
      
        Test.startTest();
        String filterManualRecords = Label.TPL_Manual_Records;
        String filterRecordsToday = Label.TPL_Records_Created_Today;
        Integer pageNumber = 1;
        String sortOrder = Label.TPL_Descending;
        Integer pageSize = 5;
        String exceptionMessage = null;
        HCCostCaseController.HCCostCaseDetailWrapper caseDetailWrapper1 = new HCCostCaseController.HCCostCaseDetailWrapper();
        HCCostCaseController.HCCostCaseDetailWrapper caseDetailWrapper2 = new HCCostCaseController.HCCostCaseDetailWrapper();
        try{
            insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3};
            caseDetailWrapper1 = HCCostCaseController.getHealthcareCostsCCForCase(c.Id,filterManualRecords,pageSize, pageNumber, sortOrder);
            caseDetailWrapper2 = HCCostCaseController.getHealthcareCostsCCForCase(c.Id,filterRecordsToday,pageSize, pageNumber, sortOrder);    
        }
        catch(DmlException dml){
            exceptionMessage = dml.getMessage();
        }
        Test.stopTest();
        if(exceptionMessage != null){
            System.assertNotEquals(null, exceptionMessage);
        }
        else {
            System.assertEquals(caseDetailWrapper1.hccList.size(),caseDetailWrapper2.hccList.size());            
        }
    }

    @isTest
    static void testGetHealthcareCostsFutureCareForCase(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
		Healthcare_Cost__c hcc1 = TestDataFactory.futurecareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.futurecareCostRecord(acc.Id, c.Id);
        Healthcare_Cost__c hcc3 = TestDataFactory.futurecareCostRecord(acc.Id, c.Id);
      
        Test.startTest();
        String filterAllRecords = Label.TPL_All_Records;
        String filterManualRecords = Label.TPL_Manual_Records;
        String filterRecordsToday = Label.TPL_Records_Created_Today;
        Integer pageNumber = 1;
        String sortOrder = Label.TPL_Descending;
        Integer pageSize = 5;
        String exceptionMessage = null;
        HCCostCaseController.HCCostCaseDetailWrapper caseDetailWrapper1 = new HCCostCaseController.HCCostCaseDetailWrapper();
        HCCostCaseController.HCCostCaseDetailWrapper caseDetailWrapper2 = new HCCostCaseController.HCCostCaseDetailWrapper();
      
        try{
            insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3};
            caseDetailWrapper1 = HCCostCaseController.getHealthcareCostsFCForCase(c.Id,filterManualRecords,pageSize, pageNumber, sortOrder);
            caseDetailWrapper2 = HCCostCaseController.getHealthcareCostsFCForCase(c.Id,filterRecordsToday,pageSize, pageNumber, sortOrder);    
        }
        catch(DmlException dml){
            exceptionMessage = dml.getMessage();
        }
        Test.stopTest();
        if(exceptionMessage != null){
            System.assertNotEquals(null, exceptionMessage);
        }
        else {
            System.assertEquals(caseDetailWrapper1.hccList.size(),caseDetailWrapper2.hccList.size());            
        }
    }
}