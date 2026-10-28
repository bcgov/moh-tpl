/*
* Company: CGI for BC Ministry of Health
* Date: April 12, 2023
* Author: Anudish Jinturkar, Ahmed Shaik
* Description: public with sharing class HCCostAccountController that implements on the Healthcare Costs at Account level grid. 
This code contains callouts to account bound HC Cost Information. 
*    Methods:
*         getHCCostCountonAccount(String accId, String selectedFilterValue, Id recordTypeId) : This method is a private method restricted to this class that calculates returns the HCCost value.
*         getStartNumber(Integer pageSize, Integer pageNumber, Integer totalCount) : This method calculates the starting item number to query from, 
		  based on Page Size, Page Number, and total count of records.
*         getHealthcareCostsAmbulanceForAccount(String accId, String selectedFilterValue, Integer pageNumber, Integer pageSize, String sortOrder): This method gets the
		  Healthcare Cost records for Ambulance level record type associated with that selected Account.
*         getHealthcareCostsPharmacareForAccount(String accId, String selectedFilterValue, Integer pageNumber, Integer pageSize, String sortOrder): This method gets the
		  Healthcare Cost records for Pharmacare level record type associated with that selected Account.
*         getHealthcareCostsMSPForAccount(String accId, String selectedFilterValue, Integer pageNumber, Integer pageSize, String sortOrder): This method gets the
		  Healthcare Cost records for MSP level record type associated with that selected Account.
*         getHealthcareCostsHospitalForAccount(String accId, String selectedFilterValue, Integer pageNumber, Integer pageSize, String sortOrder): This method gets the
		  Healthcare Cost records for Hospital level record type associated with that selected Account.
*         getHealthcareCostsCCForAccount(String accId, String selectedFilterValue, Integer pageNumber, Integer pageSize, String sortOrder): This method gets the
		  Healthcare Cost records for Continuing Care level record type associated with that selected Account.
*         getHealthcareCostsFCForAccount(String accId, String selectedFilterValue, Integer pageNumber, Integer pageSize, String sortOrder): This method gets the
		  Healthcare Cost records for Future Care level record type associated with that selected Account.
*         assignAll(String currentAccountId,String newCaseId,List<Healthcare_cost__c> currentRecords,String recordType): This method assigns case to all the selected Healthcare Cost Records
*         findIfUnderUpdate(String userId): This method checks if the current user is processing any Ascynchronous Job.
* History:
*     Initial version: April 12, 2023 - AJ
*     Update to codebase: June 10, 2023 - AJ
*     Update to codebase June 16, 2023 - AS
*/
public with sharing class HCCostAccountController {
    /*
* Description: Private method written to get the count of Healthcare Cost records from the database with given parameters as conditions.
* Parameters:
*     String accId: It consist of the account associated with the Healthcare Cost Records
*     String selectedFilterValue: It depicts the filter selected on the UI to see the records
*     Id recordTypeId: It contains the ID of the selected Healthcare cost record type
* Returns:
*     Integer: Returns integer count of total number of HC Cost records based on the parameterized conditions
* 
*/
    private static Integer getHCCostCountonAccount(String accId, String selectedFilterValue, Id recordTypeId){
        if(selectedFilterValue == Label.TPL_All_Records)
        {
            return [SELECT count() 
                    FROM Healthcare_Cost__c 
                    WHERE Account__c = :accId AND RecordTypeId = :recordTypeId];            
        }
        else{
            return [SELECT count() 
                    FROM Healthcare_Cost__c 
                    WHERE Account__c = :accId AND RecordTypeId = :recordTypeId AND Cost_Include__c = false AND Cost_Review__c = false];
        }
    }
    
    /*
* Description: Private Method to calculate the Start Number index from the input page size, page number, and total count given for the record
* Parameters:
*    Integer pageSize: Page Size parameter gives the count of records displayed on the page
*    Integer pageNumber: Page Number parameter tells the current page number from the grid
*    Integer totalCount: Total Count tells the count of the total number of records for that record type on account level
* Returns:
*     Integer: Returns the start Number for the index to traverse from
* 
*/
    private static Integer getStartNumber(Integer pageSize, Integer pageNumber, Integer totalCount){
        Integer startNumber = 1;
        if(pageSize > = totalCount){
            startNumber = 1;
        }
        else{
            startNumber = ((pageNumber -1) * pageSize) + 1;
        }
        return startNumber;
    }
    
    /*
* Description: Method to get the list of Healthcare cost records for Ambulance Record type at account level
* Parameters:
*    String accId: accId contains the Account ID parameter to find out the Healthcare Cost records for associated account ID
*    String selectedFilterValue: This parameter gives the parameter 
*    Integer pageNumber: Page Number parameter tells the current page number from the grid
*    Integer pageSize: Page Size parameter gives the count of records displayed on the page
*    String sortOrder: sortOrder string states if the order is ascending or descending 
* Returns:
*     HCCostAccountDetailWrapper: Returns the accountDetailWrapper that contains Healthcare Cost List and total count of Healthcare cost records
* 
*/
    @AuraEnabled
    public static HCCostAccountDetailWrapper getHealthcareCostsAmbulanceForAccount(String accId, String selectedFilterValue, Integer pageNumber, Integer pageSize, String sortOrder){
        List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
        HCCostAccountDetailWrapper accountDetailWrapper = new HCCostAccountDetailWrapper();
        Integer startItemNumber = 0;
        Integer totalCount = 0;
        String ambulanceFields = Label.TPL_Ambulance_Fields;
        try {
            Id recordTypeId = HCCostRecordTypeIds.getAmbulanceRecordId();
            totalCount = HCCostAccountController.getHCCostCountonAccount(accId, selectedFilterValue, recordTypeId);
            startItemNumber = HCCostAccountController.getStartNumber(pageSize, pageNumber, totalCount);
            
            hccCostList = HCCostAccountDAO.getHCCostAccountRecords(accId, selectedFilterValue, recordTypeId, startItemNumber, pageSize, ambulanceFields, sortOrder);
            
            accountDetailWrapper.hccList = hccCostList;
            accountDetailWrapper.totalCount = totalCount;
        } catch(NullPointerException nullpointer){
            System.debug(nullpointer.getMessage());
        } catch(QueryException qe){
            System.debug(qe.getMessage());
        }
        return accountDetailWrapper;
    }
    
    /*
* Description: Method to get the list of Healthcare cost records for Pharmacare Record type at account level
* Parameters:
*    String accId: accId contains the Account ID parameter to find out the Healthcare Cost records for associated account ID
*    String selectedFilterValue: This parameter gives the parameter 
*    Integer pageNumber: Page Number parameter tells the current page number from the grid
*    Integer pageSize: Page Size parameter gives the count of records displayed on the page
*    String sortOrder: sortOrder string states if the order is ascending or descending 
* Returns:
*     HCCostAccountDetailWrapper: Returns the accountDetailWrapper that contains Healthcare Cost List and total count of Healthcare cost records
* 
*/
    @AuraEnabled
    public static HCCostAccountDetailWrapper getHealthcareCostsPharmacareForAccount(String accId, String selectedFilterValue, Integer pageNumber, Integer pageSize, String sortOrder)
    {
        List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
        HCCostAccountDetailWrapper accountDetailWrapper = new HCCostAccountDetailWrapper();
        Integer startItemNumber = 0;
        Integer totalCount = 0;
        String pharmacareFields = Label.TPL_Pharmacare_Fields;
        try{
            Id recordTypeId = HCCostRecordTypeIds.getPharmacareRecordId();
            totalCount = HCCostAccountController.getHCCostCountonAccount(accId, selectedFilterValue, recordTypeId);
            startItemNumber = HCCostAccountController.getStartNumber(pageSize, pageNumber, totalCount);
            hccCostList = HCCostAccountDAO.getHCCostAccountRecords(accId, selectedFilterValue, recordTypeId, startItemNumber, pageSize, pharmacareFields, sortOrder);
            accountDetailWrapper.hccList = hccCostList;
            accountDetailWrapper.totalCount = totalCount;
        } catch(NullPointerException nullpointer){
            System.debug(nullpointer.getMessage());
        }catch(QueryException qe){
            System.debug(qe.getMessage());
        }
        return accountDetailWrapper;
    }
    
    /*
* Description: Method to get the list of Healthcare cost records for MSP Record type at account level
* Parameters:
*    String accId: accId contains the Account ID parameter to find out the Healthcare Cost records for associated account ID
*    String selectedFilterValue: This parameter gives the parameter 
*    Integer pageNumber: Page Number parameter tells the current page number from the grid
*    Integer pageSize: Page Size parameter gives the count of records displayed on the page
*    String sortOrder: sortOrder string states if the order is ascending or descending 
* Returns:
*     HCCostAccountDetailWrapper: Returns the accountDetailWrapper that contains Healthcare Cost List and total count of Healthcare cost records
* 
*/
    @AuraEnabled
    public static HCCostAccountDetailWrapper getHealthcareCostsMSPForAccount(String accId, String selectedFilterValue, Integer pageNumber, Integer pageSize, String sortOrder)
    {      
        List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
        HCCostAccountDetailWrapper accountDetailWrapper = new HCCostAccountDetailWrapper();
        Integer startItemNumber = 0;
        Integer totalCount = 0;
        String mspFields = Label.TPL_MSP_Fields;
        try{
            Id recordTypeId = HCCostRecordTypeIds.getMSPRecordId();
            totalCount = HCCostAccountController.getHCCostCountonAccount(accId, selectedFilterValue, recordTypeId);
            startItemNumber = HCCostAccountController.getStartNumber(pageSize, pageNumber, totalCount);
            hccCostList = HCCostAccountDAO.getHCCostAccountRecords(accId, selectedFilterValue, recordTypeId, startItemNumber, pageSize, mspFields, sortOrder);
            accountDetailWrapper.hccList = hccCostList;
            accountDetailWrapper.totalCount = totalCount;
        } catch(NullPointerException nullpointer){
            System.debug(nullpointer.getMessage());
        } catch(QueryException qe){
            System.debug(qe.getMessage());
        }
        return accountDetailWrapper;
    }
    
    /*
* Description: Method to get the list of Healthcare cost records for Hospital Record type at account level
* Parameters:
*    String accId: accId contains the Account ID parameter to find out the Healthcare Cost records for associated account ID
*    String selectedFilterValue: This parameter gives the parameter 
*    Integer pageNumber: Page Number parameter tells the current page number from the grid
*    Integer pageSize: Page Size parameter gives the count of records displayed on the page
*    String sortOrder: sortOrder string states if the order is ascending or descending 
* Returns:
*     HCCostAccountDetailWrapper: Returns the accountDetailWrapper that contains Healthcare Cost List and total count of Healthcare cost records
* 
*/
    @AuraEnabled
    public static HCCostAccountDetailWrapper getHealthcareCostsHospitalForAccount(String accId, String selectedFilterValue, Integer pageNumber, Integer pageSize, String sortOrder)
    {
        List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
        HCCostAccountDetailWrapper accountDetailWrapper = new HCCostAccountDetailWrapper();
        Integer startItemNumber = 0;
        Integer totalCount = 0;
        String hospitalFields = Label.TPL_Hospitalization_Fields;
        try{
            Id recordTypeId = HCCostRecordTypeIds.getHospitalRecordId();
            totalCount = HCCostAccountController.getHCCostCountonAccount(accId, selectedFilterValue, recordTypeId);
            startItemNumber = HCCostAccountController.getStartNumber(pageSize, pageNumber, totalCount);
            hccCostList = HCCostAccountDAO.getHCCostAccountRecords(accId, selectedFilterValue, recordTypeId, startItemNumber, pageSize, hospitalFields, sortOrder);
            accountDetailWrapper.hccList = hccCostList;
            accountDetailWrapper.totalCount = totalCount;
        } catch(NullPointerException nullpointer){
            System.debug(nullpointer.getMessage());
        } catch(QueryException qe){
            System.debug(qe.getMessage());
        }
        return accountDetailWrapper;
    }
    
    /*
* Description: Method to get the list of Healthcare cost records for Continuing Care Record type at account level
* Parameters:
*    String accId: accId contains the Account ID parameter to find out the Healthcare Cost records for associated account ID
*    String selectedFilterValue: This parameter gives the parameter 
*    Integer pageNumber: Page Number parameter tells the current page number from the grid
*    Integer pageSize: Page Size parameter gives the count of records displayed on the page
*    String sortOrder: sortOrder string states if the order is ascending or descending 
* Returns:
*     HCCostAccountDetailWrapper: Returns the accountDetailWrapper that contains Healthcare Cost List and total count of Healthcare cost records
* 
*/
    @AuraEnabled
    public static HCCostAccountDetailWrapper getHealthcareCostsCCForAccount(String accId, String selectedFilterValue, Integer pageNumber, Integer pageSize, String sortOrder)
    {
        List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
        HCCostAccountDetailWrapper accountDetailWrapper = new HCCostAccountDetailWrapper();
        Integer startItemNumber = 0;
        Integer totalCount = 0;
        String continuingCareFields = Label.TPL_Continuing_Care_Fields;
        try{
            Id recordTypeId = HCCostRecordTypeIds.getContinuingCareRecordId();
            totalCount = HCCostAccountController.getHCCostCountonAccount(accId, selectedFilterValue, recordTypeId);
            startItemNumber = HCCostAccountController.getStartNumber(pageSize, pageNumber, totalCount);
            hccCostList = HCCostAccountDAO.getHCCostAccountRecords(accId, selectedFilterValue, recordTypeId, startItemNumber, pageSize, continuingCareFields, sortOrder);
            accountDetailWrapper.hccList = hccCostList;
            accountDetailWrapper.totalCount = totalCount;
        } catch(NullPointerException nullpointer){
            System.debug(nullpointer.getMessage());
        } catch(QueryException qe){
            System.debug(qe.getMessage());
        }
        return accountDetailWrapper;
    }
    
    /*
* Description: Method to get the list of Healthcare cost records for Future Care Record type at account level
* Parameters:
*    String accId: accId contains the Account ID parameter to find out the Healthcare Cost records for associated account ID
*    String selectedFilterValue: This parameter gives the parameter 
*    Integer pageNumber: Page Number parameter tells the current page number from the grid
*    Integer pageSize: Page Size parameter gives the count of records displayed on the page
*    String sortOrder: sortOrder string states if the order is ascending or descending 
* Returns:
*     HCCostAccountDetailWrapper: Returns the accountDetailWrapper that contains Healthcare Cost List and total count of Healthcare cost records
* 
*/
    @AuraEnabled
    public static HCCostAccountDetailWrapper getHealthcareCostsFCForAccount(String accId, String selectedFilterValue, Integer pageNumber, Integer pageSize, String sortOrder)
    {
        List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
        HCCostAccountDetailWrapper accountDetailWrapper = new HCCostAccountDetailWrapper();
        Integer startItemNumber = 0;
        Integer totalCount = 0;
        String futureCareFields = Label.TPL_Future_Care_Fields;
        try{
            Id recordTypeId = HCCostRecordTypeIds.getFutureCareRecordId();
            totalCount = HCCostAccountController.getHCCostCountonAccount(accId, selectedFilterValue, recordTypeId);
            startItemNumber = HCCostAccountController.getStartNumber(pageSize, pageNumber, totalCount);
            hccCostList = HCCostAccountDAO.getHCCostAccountRecords(accId, selectedFilterValue, recordTypeId, startItemNumber, pageSize, futureCareFields, sortOrder);
            accountDetailWrapper.hccList = hccCostList;
            accountDetailWrapper.totalCount = totalCount;
        } catch(NullPointerException nullpointer){
            System.debug(nullpointer.getMessage());
        } catch(QueryException qe){
            System.debug(qe.getMessage());
        }
        return accountDetailWrapper;
    }
    
    /*
* Description: assignAll method to assign the case to all the Healthcare Cost records for the selected record type
* Parameters:
*    String currentAccountId: accId contains the Account ID parameter to find out the Healthcare Cost records for associated account ID
*    String newCaseId: this gives the case ID to be assigned to the HC Cost records
*    List<Healthcare_cost__c> currentRecords: it gives the list of Healthcare Cost records to assign the case ID
*    String recordType: Gives the name of record type to whom the case ID needs to be assigned
* Returns:
*     List<Healthcare_cost__c>: returns the updated list of Healthcare Cost records 
* 
*/
    @AuraEnabled
    public static List<Healthcare_cost__c> assignAll(String currentAccountId,String newCaseId,List<Healthcare_cost__c> currentRecords,String recordType){
        
        List<Healthcare_Cost__c> hccList = [SELECT id,case2__c 
                                            FROM Healthcare_Cost__c 
                                            WHERE Account__c =: currentAccountId AND id NOT IN: currentRecords AND Cost_Include__c = false 
                                            AND Cost_Review__c = false AND RecordType.developerName =:recordType FOR UPDATE];
        
        if(String.isBlank(newCaseId)){
            newCaseId = null; 
        }
        
        for(Healthcare_Cost__c hcc : currentRecords){
            if(!hcc.Cost_Include__c && !hcc.Cost_Review__c) {
                hcc.case2__c = newCaseId;    
            }
        }
        try{
            Database.saveResult[] sr = database.update(currentRecords,false);
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        
        for(Healthcare_Cost__c hcc : hccList){
            hcc.case2__c = newCaseId;
        }
        
        System.enqueueJob(new AccountQueueable(hccList));
        return currentRecords;
    }
    
    /*
* Description: assignAll method to assign the case to all the Healthcare Cost records for the selected record type
* Parameters:
*    String userId: this parameter passes the current users ID
* Returns:
*     Boolean: returns true if current user is processing any assynchornous job update or else false if no job under process by current user 
* 
*/
    @AuraEnabled
    public static Boolean findIfUnderUpdate(String userId){
        try {
            List<AsyncApexJob> apexJobs = [SELECT id ,Status, ApexClass.Name,CreatedById,JobType 
                                           FROM AsyncApexJob 
                                           WHERE  JobType = 'Queueable' AND (status = 'Processing' or status = 'Queued') 
                                           AND createdbyId =:userId];
            if(apexJobs.size()>0){
                return true;
            }else{
                return false;
            }
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /*
* Description: Wrapper class to perform transactions on account level in Healthcare cost.
* Parameters:
*    List<Healthcare_Cost__c> hccList: Contains the Healthcare Cost records List
*    Integer totalCount: This count is the total number of Healthcare Cost records for given record type
*/  
    public class HCCostAccountDetailWrapper{
        @AuraEnabled public List<Healthcare_Cost__c> hccList {get;set;}
        @AuraEnabled public Integer totalCount {get;set;}
    }
}