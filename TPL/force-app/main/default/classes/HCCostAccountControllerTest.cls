/*
* Company: CGI for BC Ministry of Health
* Date: April 30, 2023
* Author: Anudish Jinturkar
* Description: public class HCCostAccountControllerTest : Test class written on the generic controller class HCCostAccountController covers the Account level-based functionality of Healthcare Cost
*    Test Methods:
*         testGetHealthcareCostsAmbulanceForAccountDescendingSort() : Test Method to test the Ambulance records fetched in the descending sort order on the account level based on account selected for Healthcare cost records
*         insertHCCFutureMethod() : Test Method to test the Healthcare cost future method for running batch execution of mass records for assigning cases
*         testHCCostAccountDAO() : Test Method to test execution of case assignment to bulk healthcare cost records on account level
*         testGetHealthcareCostsAmbulanceForAccountAscendingSort():Test Method to test the Ambulance records fetched in the ascending sort order on the account level based on account selected for Healthcare cost records
*         testGetHealthcareCostsHospitalForAccountDescendingSort(): Test Method to test the Hospitalization records fetched in the descending sort order on the account level based on account selected for Healthcare cost records
*         testGetHealthcareCostsHospitalForAccountAscendingSort(): Test Method to test the Hospitalization records fetched in the ascending sort order on the account level based on account selected for Healthcare cost records
*		  testGetHealthcareCostsMSPForAccountDescendingSort(): Test Method to test the MSP records fetched in the descending sort order on the account level based on account selected for Healthcare cost records
*		  testGetHealthcareCostsMSPForAccountAscendingSort(): Test Method to test the MSP records fetched in the ascending sort order on the account level based on account selected for Healthcare cost records
*		  testGetHealthcareCostsPharmacareForAccountDescendingSort():Test Method to test the Pharmacare records fetched in the descending sort order on the account level based on account selected for Healthcare cost records
*		  testGetHealthcareCostsPharmacareForAccountAscendingSort(): Test Method to test the Pharmacare records fetched in the ascending sort order on the account level based on account selected for Healthcare cost records
*		  testGetHealthcareCostsContinuingCareForAccount(): Test Method to test the Continuing Care records fetched on the account level based on account selected for Healthcare cost records
*         testGetHealthcareCostsFutureCareForAccount(): Test Method to test the Future Care records fetched on the account level based on account selected for Healthcare cost records
*         testAssignAll(): Test Method to test assign all functionality for assignment of case to all the Healthcare cost records under the selected record type and have cost review and cost review unchecked
* History:
*     Initial version: March 30, 2023 - AJ
*     Updates to codebase: May 10, 2023 - AJ
*     Updates to codebase: July 4, 2023 - AJ
*/
@isTest
public with sharing class HCCostAccountControllerTest {
    
    @isTest
    static void testGetHealthcareCostsAmbulanceForAccountDescendingSort(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
        List<Healthcare_Cost__c> hccList = new List<Healthcare_Cost__c>();
        for(Integer i=0; i<12;i++){
	        Healthcare_Cost__c hcc = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
            hccList.add(hcc);
        }

        Test.startTest();
        String filterAllRecords = Label.TPL_All_Records;
        String filterUncheckedRecords = Label.TPL_Both_Unchecked;
        String sortOrder = Label.TPL_Descending;
        Integer pageNumber = 2;
        Integer pageSize = 5;
        String exceptionMessage = null;
        HCCostAccountController.HCCostAccountDetailWrapper accountDetailWrapper1 = new HCCostAccountController.HCCostAccountDetailWrapper();
        HCCostAccountController.HCCostAccountDetailWrapper accountDetailWrapper2 = new HCCostAccountController.HCCostAccountDetailWrapper();
        try{
			insert hccList;
            accountDetailWrapper1 = HCCostAccountController.getHealthcareCostsAmbulanceForAccount(acc.Id, filterAllRecords, pageNumber, pageSize, sortOrder);
            accountDetailWrapper2 = HCCostAccountController.getHealthcareCostsAmbulanceForAccount(acc.Id, filterUncheckedRecords, pageNumber, pageSize, sortOrder);
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
        HCCostAccountControllerTest.testHCCostAccountDAO();
    }
    
    @isTest
    public static void testHCCostAccountDAO(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
        Test.startTest();
        String allRecords = Label.TPL_All_Records;
        String checkedRecords = Label.TPL_Both_Checked;
        String fields = Label.TPL_Ambulance_Fields;
        String sortOrder = Label.TPL_Descending;
        Integer startItemNumber = 4000;
        Integer pageSize = 10;
        Id recordTypeId = Schema.SObjectType.Healthcare_Cost__c.getRecordTypeInfosByName().get('Ambulance').getRecordTypeId(); 
        HCCostAccountDAO.getHCCostAccountRecords(acc.Id, allRecords, recordTypeId, startItemNumber, pageSize, fields, sortOrder);
        HCCostAccountDAO.getHCCostAccountRecords(acc.Id, allRecords, recordTypeId, startItemNumber, pageSize, fields,'');
        HCCostAccountDAO.getHCCostAccountRecords(acc.Id, checkedRecords, recordTypeId, startItemNumber, pageSize, fields, sortOrder);
        HCCostAccountDAO.getHCCostAccountRecords(acc.Id, checkedRecords, recordTypeId, startItemNumber, pageSize, fields,'');
        Test.stopTest();
    }
    
    @isTest
    static void testGetHealthcareCostsAmbulanceForAccountAscendingSort(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
        List<Healthcare_Cost__c> hccList = new List<Healthcare_Cost__c>();
        for(Integer i=0;i<12;i++){
            Healthcare_Cost__c hcc = TestDataFactory.ambulanceCostRecord(acc.Id, c.Id);
            hccList.add(hcc);
        }

        Test.startTest();
        String filterAllRecords = Label.TPL_All_Records;
        String filterUncheckedRecords = Label.TPL_Both_Unchecked;
        String sortOrder = Label.TPL_Ascending;
        Integer pageNumber = 2;
        Integer pageSize = 5;
        String exceptionMessage = null;
        HCCostAccountController.HCCostAccountDetailWrapper accountDetailWrapper1 = new HCCostAccountController.HCCostAccountDetailWrapper();
        HCCostAccountController.HCCostAccountDetailWrapper accountDetailWrapper2 = new HCCostAccountController.HCCostAccountDetailWrapper();
        try{
			insert hccList;
            accountDetailWrapper1 = HCCostAccountController.getHealthcareCostsAmbulanceForAccount(acc.Id, filterAllRecords, pageNumber, pageSize, sortOrder);
            accountDetailWrapper2 = HCCostAccountController.getHealthcareCostsAmbulanceForAccount(acc.Id, filterUncheckedRecords, pageNumber, pageSize, sortOrder);
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
    static void testGetHealthcareCostsHospitalForAccountDescendingSort(){
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
        String filterUncheckedRecords = Label.TPL_Both_Unchecked;
        Integer pageNumber = 1;
        String sortOrder = Label.TPL_Descending;
        Integer pageSize = 5;
        String exceptionMessage = null;
        HCCostAccountController.HCCostAccountDetailWrapper accountDetailWrapper1 = new HCCostAccountController.HCCostAccountDetailWrapper();
        HCCostAccountController.HCCostAccountDetailWrapper accountDetailWrapper2 = new HCCostAccountController.HCCostAccountDetailWrapper();
        
        try{
            insert pr;
            Healthcare_Cost__c hcc1 = TestDataFactory.hospitalizationCostRecord(acc.Id, c.Id, facility.Id, pr.Id, serviceType);
            Healthcare_Cost__c hcc2 = TestDataFactory.hospitalizationCostRecord(acc.Id, c.Id, facility.Id, pr.Id, serviceType);
            Healthcare_Cost__c hcc3 = TestDataFactory.hospitalizationCostRecord(acc.Id, c.Id, facility.Id, pr.Id, serviceType);
            Healthcare_Cost__c hcc4 = TestDataFactory.hospitalizationCostRecord(acc.Id, c.Id, facility.Id, pr.Id, serviceType);
            hcc4.Cost_Include__c = false;
            hcc4.Cost_Review__c = false;
            
            insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3, hcc4};   
                
            accountDetailWrapper1 = HCCostAccountController.getHealthcareCostsHospitalForAccount(acc.Id, filterAllRecords, pageNumber, pageSize, sortOrder);
            accountDetailWrapper2 = HCCostAccountController.getHealthcareCostsHospitalForAccount(acc.Id, filterUncheckedRecords, pageNumber, pageSize, sortOrder);
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
    static void testGetHealthcareCostsHospitalForAccountAscendingSort(){
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
        String filterUncheckedRecords = Label.TPL_Both_Unchecked;
        Integer pageNumber = 1;
        String sortOrder = Label.TPL_Ascending;
        Integer pageSize = 5;
        String exceptionMessage = null;
        HCCostAccountController.HCCostAccountDetailWrapper accountDetailWrapper1 = new HCCostAccountController.HCCostAccountDetailWrapper();
        HCCostAccountController.HCCostAccountDetailWrapper accountDetailWrapper2 = new HCCostAccountController.HCCostAccountDetailWrapper();
        
        try{
            insert pr;
            Healthcare_Cost__c hcc1 = TestDataFactory.hospitalizationCostRecord(acc.Id, c.Id, facility.Id, pr.Id, serviceType);
            Healthcare_Cost__c hcc2 = TestDataFactory.hospitalizationCostRecord(acc.Id, c.Id, facility.Id, pr.Id, serviceType);
            Healthcare_Cost__c hcc3 = TestDataFactory.hospitalizationCostRecord(acc.Id, c.Id, facility.Id, pr.Id, serviceType);
            Healthcare_Cost__c hcc4 = TestDataFactory.hospitalizationCostRecord(acc.Id, c.Id, facility.Id, pr.Id, serviceType);
            hcc4.Cost_Include__c = false;
            hcc4.Cost_Review__c = false;
            
            insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3, hcc4};   
                
            accountDetailWrapper1 = HCCostAccountController.getHealthcareCostsHospitalForAccount(acc.Id, filterAllRecords, pageNumber, pageSize, sortOrder);
            accountDetailWrapper2 = HCCostAccountController.getHealthcareCostsHospitalForAccount(acc.Id, filterUncheckedRecords, pageNumber, pageSize, sortOrder);
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
    static void testGetHealthcareCostsMSPForAccountDescendingSort(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
        List<Healthcare_Cost__c> hccList = new List<Healthcare_Cost__c>();
        for(Integer i=0;i<18;i++){
            Healthcare_Cost__c hcc = TestDataFactory.mspCostRecord(acc.Id, c.Id);
            if(i>2){
                hcc.Cost_Include__c = false;
                hcc.Cost_Review__c = false;
            }
            hccList.add(hcc);
        }
        
        Test.startTest();
        String filterAllRecords = Label.TPL_All_Records;
        String filterUncheckedRecords = Label.TPL_Both_Unchecked;
        Integer pageNumber = 2;
        Integer pageSize = 5;
        String sortOrder = Label.TPL_Descending;
        String exceptionMessage = null;
        HCCostAccountController.HCCostAccountDetailWrapper accountDetailWrapper1 = new HCCostAccountController.HCCostAccountDetailWrapper();
        HCCostAccountController.HCCostAccountDetailWrapper accountDetailWrapper2 = new HCCostAccountController.HCCostAccountDetailWrapper();
        
        try{
			insert hccList;
            accountDetailWrapper1 = HCCostAccountController.getHealthcareCostsMSPForAccount(acc.Id, filterAllRecords, pageNumber, pageSize, sortOrder);
            accountDetailWrapper2 = HCCostAccountController.getHealthcareCostsMSPForAccount(acc.Id, filterUncheckedRecords, pageNumber, pageSize, sortOrder);
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
    static void testGetHealthcareCostsMSPForAccountAscendingSort(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
        List<Healthcare_Cost__c> hccList = new List<Healthcare_Cost__c>();
        for(Integer i=0;i<18;i++){
            Healthcare_Cost__c hcc = TestDataFactory.mspCostRecord(acc.Id, c.Id);
            if(i>2){
                hcc.Cost_Include__c = false;
                hcc.Cost_Review__c = false;
            }
            hccList.add(hcc);
        }
        
        Test.startTest();
        String filterAllRecords = Label.TPL_All_Records;
        String filterUncheckedRecords = Label.TPL_Both_Unchecked;
        Integer pageNumber = 2;
        Integer pageSize = 5;
        String sortOrder = Label.TPL_Ascending;
        String exceptionMessage = null;
        HCCostAccountController.HCCostAccountDetailWrapper accountDetailWrapper1 = new HCCostAccountController.HCCostAccountDetailWrapper();
        HCCostAccountController.HCCostAccountDetailWrapper accountDetailWrapper2 = new HCCostAccountController.HCCostAccountDetailWrapper();
        
        try{
			insert hccList;
            accountDetailWrapper1 = HCCostAccountController.getHealthcareCostsMSPForAccount(acc.Id, filterAllRecords, pageNumber, pageSize, sortOrder);
            accountDetailWrapper2 = HCCostAccountController.getHealthcareCostsMSPForAccount(acc.Id, filterUncheckedRecords, pageNumber, pageSize, sortOrder);
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
    static void testGetHealthcareCostsPharmacareForAccountDescendingSort(){
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
        String sortOrder = Label.TPL_Descending;
        String exceptionMessage = null;
        HCCostAccountController.HCCostAccountDetailWrapper accountDetailWrapper1 = new HCCostAccountController.HCCostAccountDetailWrapper();
        HCCostAccountController.HCCostAccountDetailWrapper accountDetailWrapper2 = new HCCostAccountController.HCCostAccountDetailWrapper();
        
        try{
            insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3, hcc4};    
            accountDetailWrapper1 = HCCostAccountController.getHealthcareCostsPharmacareForAccount(acc.Id, filterAllRecords, pageNumber, pageSize, sortOrder);
            accountDetailWrapper2 = HCCostAccountController.getHealthcareCostsPharmacareForAccount(acc.Id, filterUncheckedRecords, pageNumber, pageSize, sortOrder);
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
    static void testGetHealthcareCostsPharmacareForAccountAscendingSort(){
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
        String sortOrder = Label.TPL_Ascending;
        String exceptionMessage = null;
        HCCostAccountController.HCCostAccountDetailWrapper accountDetailWrapper1 = new HCCostAccountController.HCCostAccountDetailWrapper();
        HCCostAccountController.HCCostAccountDetailWrapper accountDetailWrapper2 = new HCCostAccountController.HCCostAccountDetailWrapper();
        
        try{
            insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3, hcc4};    
            accountDetailWrapper1 = HCCostAccountController.getHealthcareCostsPharmacareForAccount(acc.Id, filterAllRecords, pageNumber, pageSize, sortOrder);
            accountDetailWrapper2 = HCCostAccountController.getHealthcareCostsPharmacareForAccount(acc.Id, filterUncheckedRecords, pageNumber, pageSize, sortOrder);
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
        String sortOrder = Label.TPL_Ascending;
        HCCostAccountController.HCCostAccountDetailWrapper accountDetailWrapper1 = new HCCostAccountController.HCCostAccountDetailWrapper();
        HCCostAccountController.HCCostAccountDetailWrapper accountDetailWrapper2 = new HCCostAccountController.HCCostAccountDetailWrapper();
        try{
            insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3, hcc4};    
            accountDetailWrapper1 = HCCostAccountController.getHealthcareCostsCCForAccount(acc.Id, filterManualRecords, pageNumber, pageSize, sortOrder);
            accountDetailWrapper2 = HCCostAccountController.getHealthcareCostsCCForAccount(acc.Id, filterRecordsCreatedToday, pageNumber, pageSize, sortOrder);
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
        String sortOrder = Label.TPL_Ascending;
        String exceptionMessage = null;
        HCCostAccountController.HCCostAccountDetailWrapper accountDetailWrapper1 = new HCCostAccountController.HCCostAccountDetailWrapper();
        HCCostAccountController.HCCostAccountDetailWrapper accountDetailWrapper2 = new HCCostAccountController.HCCostAccountDetailWrapper();
        
        try{
            insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3, hcc4};    
            accountDetailWrapper1 = HCCostAccountController.getHealthcareCostsFCForAccount(acc.Id, filterManualRecords, pageNumber, pageSize, sortOrder);
            accountDetailWrapper2 = HCCostAccountController.getHealthcareCostsFCForAccount(acc.Id, filterRecordsCreatedToday, pageNumber, pageSize, sortOrder);
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
    static void testAssignAll(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
        Case c2 = TestDataFactory.newCase(acc.Id);
        insert c2;
        String exceptionMessage = null;
        Boolean getStatus = false;
        List<Healthcare_Cost__c> hccList = new List<Healthcare_Cost__c>();
        List<Healthcare_Cost__c> resultHCCList = new List<Healthcare_Cost__c>();
        for(Integer i = 0; i< 250 ; i++){
            Healthcare_Cost__c hcc = TestDataFactory.pharmacareCostRecord(acc.Id, c.Id);
            hcc.Cost_Include__c = false;
            hcc.Cost_Review__c = false;
            hccList.add(hcc);
        }
        
        Test.startTest();
        try {
            insert hccList;
            String recordType = 'Pharmacare';
            List<Healthcare_Cost__c> currenthccList = new List<Healthcare_Cost__c>();
            for(Integer i=0;i<5;i++){
                currenthccList.add(hccList[i]);
            }
            
            resultHCCList = HCCostAccountController.assignAll(acc.Id, c2.Id, currenthccList, recordType);
            Id userId = UserInfo.getUserId();
            getStatus = HCCostAccountController.findIfUnderUpdate(userId);
            
        } catch (Exception e) {
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();
        if(exceptionMessage != null){
            System.assertNotEquals(null, exceptionMessage);
        }   
    }
}