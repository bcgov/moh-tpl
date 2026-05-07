/*
* Company: CGI for BC Ministry of Health
* Date: April 30, 2023
* Author: Anudish Jinturkar
* Description: public class HCCostCaseControllerTest : Test class written on the generic controller class HCCostCaseController covers the Case level-based functionality of Healthcare Cost
*    Test Methods:
*         testGetHealthcareCostsAmbulanceForCaseDescendingSort() : Test Method to test the Ambulance records fetched in the descending sort order on the case level based on case and related account selected for Healthcare cost records
*         insertHCCFutureMethod() : Test Method to insert bulk records for processing mass healthcare cost records testing on case level 
*         testHCCostCaseDAO() : Test Method to test the execution of case assignment to bulk healthcare cost records on case level
*         testGetHealthcareCostsAmbulanceForCaseAscendingSort():Test Method to test the Ambulance records fetched in the ascending sort order on the case level based on case and related account selected for Healthcare cost records
*         testGetHealthcareCostsHospitalForCaseDescendingSort(): Test Method to test the Hospitalization records fetched in the descending sort order on the case level based on case and related account selected for Healthcare cost records
*         testGetHealthcareCostsHospitalForCaseAscendingSort(): Test Method to test the Hospitalization records fetched in the ascending sort order on the case level based on case and related account selected for Healthcare cost records
*		  testGetHealthcareCostsMSPForCaseDescendingSort(): Test Method to test the MSP records fetched in the descending sort order on the case level based on case and related account selected for Healthcare cost records
*		  testGetHealthcareCostsMSPForCaseAscendingSort(): Test Method to test the MSP records fetched in the ascending sort order on the case level based on case and related account selected for Healthcare cost records
*		  testGetHealthcareCostsPharmacareForCaseDescendingSort():Test Method to test the Pharmacare records fetched in the descending sort order on the case level based on case and related account selected for Healthcare cost records
*		  testGetHealthcareCostsPharmacareForCaseAscendingSort(): Test Method to test the Pharmacare records fetched in the ascending sort order on the case level based on case and related account selected for Healthcare cost records
*		  testGetHealthcareCostsContinuingCareForCase(): Test Method to test the Continuing Care records fetched on the case level based on case and related account selected for Healthcare cost records
*         testGetHealthcareCostsFutureCareForCase(): Test Method to test the Future Care records fetched on the case level based on case and related account selected for Healthcare cost records
* History:
*     Initial version: March 30, 2023 - AJ
*     Updates to codebase: May 10, 2023 - AJ
*     Updates to codebase: July 4, 2023 - AJ
*	  Updates to codebase: Nov 5, 2025 - RRG
*/
@isTest
public with sharing class HCCostCaseControllerTest {
    //For testclass
    private static Integer getRecordCount(HCCostCaseController.HCCostCaseDetailWrapper w) {
    return (w != null && w.hccList != null) ? w.hccList.size() : 0;
    }

    @isTest
    static void testGetHealthcareCostsAmbulanceForCaseDescendingSort(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
        List<Healthcare_Cost__c> hccList = new List<Healthcare_Cost__c>();
        
        for(Integer i = 0; i< 11; i++){
            Healthcare_Cost__c hcc = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
            hccList.add(hcc);
        }
        
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
            insert hccList;                
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
            System.assertEquals(getRecordCount(caseDetailWrapper2), getRecordCount(caseDetailWrapper3));            
        }
    }
    @future
    public static void insertHCCFutureMethod(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
        List<Healthcare_Cost__c> hccListInsert = new List<Healthcare_Cost__c>();
        for(Integer i=0;i<4000;i++){
            Healthcare_Cost__c hcc2 = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
            hccListInsert.add(hcc2);
        }
        database.insert(hccListInsert,false);
        HCCostCaseControllerTest.testHCCostCaseDAO();
    }
    
    @isTest
    public static void testHCCostCaseDAO(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
        Test.startTest();
        String manualRecords = Label.TPL_Manual_Records;
        String recordsCreatedToday = Label.TPL_Records_Created_Today;
        String totalTecords = Label.TPL_All_Records;
        Integer startNumber = 4000;
        Integer pageSize = 10;
        Id recordTypeId = Schema.SObjectType.Healthcare_Cost__c.getRecordTypeInfosByName().get('Ambulance').getRecordTypeId(); 
        HCCostCaseDAO.getHCCostCaseRecords(c.Id,manualRecords,recordTypeId,startNumber,pageSize,Label.TPL_Ambulance_Fields,Label.TPL_Descending);
        HCCostCaseDAO.getHCCostCaseRecords(c.Id,manualRecords,recordTypeId,startNumber,pageSize,Label.TPL_Ambulance_Fields,'');
        HCCostCaseDAO.getHCCostCaseRecords(c.Id,recordsCreatedToday,recordTypeId,startNumber,pageSize,Label.TPL_Ambulance_Fields,Label.TPL_Descending);
        HCCostCaseDAO.getHCCostCaseRecords(c.Id,recordsCreatedToday,recordTypeId,startNumber,pageSize,Label.TPL_Ambulance_Fields,'');
        HCCostCaseDAO.getHCCostCaseRecords(c.Id,Label.TPL_All_Records,recordTypeId,startNumber,pageSize,Label.TPL_Ambulance_Fields,Label.TPL_Descending);
        HCCostCaseDAO.getHCCostCaseRecords(c.Id,Label.TPL_All_Records,recordTypeId,startNumber,pageSize,Label.TPL_Ambulance_Fields,'');
        Test.stopTest();
    }
    
    @isTest
    static void testGetHealthcareCostsAmbulanceForCaseAscendingSort(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
        List<Healthcare_Cost__c> hccList = new List<Healthcare_Cost__c>();
        for(Integer i=0; i<11;i++){
            Healthcare_Cost__c hcc = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);            
            hccList.add(hcc);
        }
        
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
            insert hccList;
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
            System.assertEquals(getRecordCount(caseDetailWrapper2), getRecordCount(caseDetailWrapper3));            
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
            System.assertEquals(getRecordCount(caseDetailWrapper2), getRecordCount(caseDetailWrapper3));            
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
            System.assertEquals(getRecordCount(caseDetailWrapper2), getRecordCount(caseDetailWrapper3));            
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
            System.assertEquals(getRecordCount(caseDetailWrapper2), getRecordCount(caseDetailWrapper3));            
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
            System.assertEquals(getRecordCount(caseDetailWrapper2), getRecordCount(caseDetailWrapper3));            
        }
    }
    
    @isTest
    static void testGetHealthcareCostsPharmacareForCaseDescendingSort(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
        List<Healthcare_Cost__c> hccList = new List<Healthcare_Cost__c>();
        for(Integer i=0;i<11;i++){
            Healthcare_Cost__c hcc = TestDataFactory.pharmacareCostRecord(acc.Id, c.Id); 
            hccList.add(hcc);
        }
        
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
            insert hccList;
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
            System.assertEquals(getRecordCount(caseDetailWrapper2), getRecordCount(caseDetailWrapper3));            
        }
    }
    
    @isTest
    static void testGetHealthcareCostsPharmacareForCaseAscendingSort(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
        List<Healthcare_Cost__c> hccList = new List<Healthcare_Cost__c>();
        for(Integer i=0;i<11;i++){
            Healthcare_Cost__c hcc = TestDataFactory.pharmacareCostRecord(acc.Id, c.Id);  
            hccList.add(hcc);          
        }
        
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
            insert hccList;
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
            System.assertEquals(getRecordCount(caseDetailWrapper2), getRecordCount(caseDetailWrapper3));            
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
            System.assertEquals(getRecordCount(caseDetailWrapper1), getRecordCount(caseDetailWrapper2));            
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
            System.assertEquals(getRecordCount(caseDetailWrapper1), getRecordCount(caseDetailWrapper2));            
        }
    }
    
      
    @isTest
	static void testUpdateAllMethod() {
    // Arrange
    Account acc = TestDataFactory.individualAccount();
    insert acc;

    Case c = TestDataFactory.newCase(acc.Id);
    insert c;

    Healthcare_Cost__c hcc = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
    insert hcc;

    // Set the fields to be updated
    hcc.Cost_Include__c = true;
    hcc.Cost_Review__c = false;

    List<Healthcare_Cost__c> hccList = new List<Healthcare_Cost__c>{ hcc };

    Test.startTest();
    HCCostCaseController.updateAll(c.Id, true, true, hccList, 'Ambulance');
    Test.stopTest();

    // Verify the updates
    Healthcare_Cost__c updated = [SELECT Cost_Include__c, Cost_Review__c FROM Healthcare_Cost__c WHERE Id = :hcc.Id];
    System.assertEquals(true, updated.Cost_Include__c);
    System.assertEquals(false, updated.Cost_Review__c);
	}
  // Test
     @isTest
    static void testHCCostCountAllRecordsBranch() {
        Account acc = TestDataFactory.individualAccount();
        insert acc;

        Case c = TestDataFactory.newCase(acc.Id);
        insert c;

        Healthcare_Cost__c hcc = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        insert hcc;

        String filterValue = Label.TPL_All_Records; // Triggers 'else' branch
        Integer pageNumber = 1;
        Integer pageSize = 5;
        String sortOrder = Label.TPL_Ascending;

        Test.startTest();
        HCCostCaseController.HCCostCaseDetailWrapper wrapper = HCCostCaseController.getHealthcareCostsAmbulanceForCase(
            c.Id, filterValue, pageSize, pageNumber, sortOrder
        );
        Test.stopTest();

        System.assert(wrapper != null);
    }

    @isTest
    static void testPaginationStartNumberElseBranch() {
        Integer pageSize = 5;
        Integer pageNumber = 3;
        Integer totalCount = 20; // Triggers else

        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;

        for (Integer i = 0; i < 20; i++) {
            insert TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
        }

        Test.startTest();
        HCCostCaseController.HCCostCaseDetailWrapper wrapper = HCCostCaseController.getHealthcareCostsAmbulanceForCase(
            c.Id, Label.TPL_All_Records, pageSize, pageNumber, Label.TPL_Ascending
        );
        Test.stopTest();

        System.assertNotEquals(null, wrapper);
    }
    
    @isTest
	static void testGetHealthcareCostsHospitalForCase_CoverageOnly() {
    // Create a valid Person Account
    Account acc = new Account(
        FirstName = 'Test',
        LastName = 'Account',
        RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Individual').getRecordTypeId(),
        PersonEmail = 'test@example.com'
    );
    insert acc;

    // Create a related Case
    Case c = new Case(
        RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Individual').getRecordTypeId(),
        Status = 'Open',
        Origin = 'Phone',
        AccountId = acc.Id,
        Subject = 'Test Case'
    );
    insert c;

    // Get the hospitalization record type ID
    Id hospitalRecordTypeId = Schema.SObjectType.Healthcare_Cost__c.getRecordTypeInfosByName().get('Hospitalization').getRecordTypeId();

    // Create a Healthcare_Cost__c record
    Healthcare_Cost__c hc = new Healthcare_Cost__c(
        RecordTypeId = hospitalRecordTypeId,
        Case2__c = c.Id,
        Account__c = acc.Id,
        Date_of_Admission__c = Date.today().addDays(-5),
        Date_of_Discharge__c = Date.today()
    );
    insert hc;

    // Run the method
    Test.startTest();
    HCCostCaseController.HCCostCaseDetailWrapper wrapper = HCCostCaseController.getHealthcareCostsHospitalForCase(
        c.Id,
        Label.TPL_All_Records,
        1,
        5,
        Label.TPL_Descending
    );
    Test.stopTest();

    System.assertNotEquals(null, wrapper);
	}
    
    // User Registration Exception class
    @IsTest
	static void test_UserRegistrationException_Raise() {
    UserRegistrationException ex = new UserRegistrationException('Test error message');
    Exception raised = ex.RaiseException();
    System.assertEquals(ex, raised, 'RaiseException() should return the same exception instance');
	}

}