/*
* Company: CGI for BC Ministry of Health
* Date: April 12, 2023
* Author: Anudish Jinturkar, Ahmed Shaik
* Description: public with sharing class HCCostCaseController that implements on the Healthcare Costs at Case level grid. 
This code contains callouts to case bound HC Cost Information. 
*    Methods:
*         getHCCostCountonCase(String caseId, String filterValue, Id recordTypeId) : This method is a private method restricted to this class that calculates returns the HCCost value.
*         getStartNumber(Integer pageSize, Integer pageNumber, Integer totalCount) : This method calculates the starting item number to query from based on Page Size, Page Number, and total count of records.
*         getHealthcareCostsAmbulanceForCase(String caseId, String filterValue, Integer pageSize, Integer pageNumber, String sortOrder): This method gets the
          Healthcare Cost records for Ambulance level record type associated with that selected Case.
*         getHealthcareCostsPharmacareForCase(String caseId, String filterValue, Integer pageSize, Integer pageNumber, String sortOrder): This method gets the
          Healthcare Cost records for Pharmacare level record type associated with that selected Case.
*         getHealthcareCostsMSPForCase(String caseId, String filterValue, Integer pageNumber, Integer pageSize, String sortOrder): This method gets the
          Healthcare Cost records for MSP level record type associated with that selected Case.
*         getHealthcareCostsHospitalForCase(String caseId, String filterValue, Integer pageNumber, Integer pageSize, String sortOrder): This method gets the
          Healthcare Cost records for Hospitalization level record type associated with that selected Case.
*         getHealthcareCostsCCForCase(String caseId, String filterValue, Integer pageNumber, Integer pageSize, String sortOrder): This method gets the
          Healthcare Cost records for Continuing Care level record type associated with that selected Case.
*         getHealthcareCostsFCForCase(String caseId, String filterValue, Integer pageNumber, Integer pageSize, String sortOrder): This method gets the
          Healthcare Cost records for Future Care level record type associated with that selected Case. 
* History:
*     Initial version: April 12, 2023 - AJ
*     Update to codebase: June 10, 2023 - AJ
*     Update to codebase: June 16, 2023 - AS
*     Update to codebase: July 06, 2023 - AJ
*/
public with sharing class HCCostCaseController {

/*
* Description: Private method written to get the count of Healthcare Cost records from the database with given parameters as conditions.
* Parameters:
*     String caseId: It consist of the caseID associated with the Healthcare Cost Records
*     String filterValue: It depicts the filter selected on the UI to see the records
*     Id recordTypeId: It contains the ID of the selected Healthcare cost record type
* Returns:
*     Integer: Returns integer count of total number of HC Cost records based on the parameterized conditions
* 
*/
private static Integer getHCCostCountonCase(String caseId, String filterValue, Id recordTypeId){
    String sourceSystemId = null;
    if(filterValue == Label.TPL_Manual_Records){
        return [SELECT count() FROM Healthcare_Cost__c WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId AND Source_System_ID__c = :sourceSystemId];
    }
    else if(filterValue == Label.TPL_Records_Created_Today) {
        return [SELECT count() FROM Healthcare_Cost__c WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId AND Source_System_ID__c = :sourceSystemId AND CreatedDate = TODAY];                
    }
    else 
    {
        return [SELECT count() FROM Healthcare_Cost__c WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId];
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
* Description: Method to get the list of Healthcare cost records for Ambulance Record type at case level
* Parameters:
*    String caseId: caseId contains the Case ID parameter to find out the Healthcare Cost records for associated case ID
*    String filterValue: This parameter gives the parameter 
*    Integer pageNumber: Page Number parameter tells the current page number from the grid
*    Integer pageSize: Page Size parameter gives the count of records displayed on the page
*    String sortOrder: sortOrder string states if the order is ascending or descending 
* Returns:
*     HCCostCaseDetailWrapper: Returns the caseDetailWrapper that contains Healthcare Cost List and total count of Healthcare cost records
* 
*/
@AuraEnabled
public static HCCostCaseDetailWrapper getHealthcareCostsAmbulanceForCase(String caseId, String filterValue, Integer pageSize, Integer pageNumber, String sortOrder){
    List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
    HCCostCaseDetailWrapper caseDetailWrapper = new HCCostCaseDetailWrapper();
    String sourceSystemId = null;
    Integer totalCount = 0;
    Integer startItemNumber = 0;
    String ambulanceFields = Label.TPL_Ambulance_Fields;
    try{
        Id recordTypeId = HCCostRecordTypeIds.getAmbulanceRecordId();
        totalCount = HCCostCaseController.getHCCostCountonCase(caseId, filterValue, recordTypeId);
        startItemNumber = HCCostCaseController.getStartNumber(pageSize, pageNumber, totalCount);
        hccCostList = HCCostCaseDAO.getHCCostCaseRecords(caseId, filterValue, recordTypeId, startItemNumber, pageSize, ambulanceFields, sortOrder);
        caseDetailWrapper.hccList = hccCostList;
        caseDetailWrapper.totalCount = totalCount;
    } catch(NullPointerException nullpointer){
        System.debug(nullpointer.getMessage());
    }
    catch(QueryException qe) {
        System.debug(qe.getMessage());    
    }
    return caseDetailWrapper;
}

        /*
* Description: Method to get the list of Healthcare cost records for Pharmacare Record type at case level
* Parameters:
*    String caseId: caseId contains the Case ID parameter to find out the Healthcare Cost records for associated case ID
*    String filterValue: This parameter gives the parameter 
*    Integer pageNumber: Page Number parameter tells the current page number from the grid
*    Integer pageSize: Page Size parameter gives the count of records displayed on the page
*    String sortOrder: sortOrder string states if the order is ascending or descending 
* Returns:
*     HCCostCaseDetailWrapper: Returns the caseDetailWrapper that contains Healthcare Cost List and total count of Healthcare cost records
* 
*/

@AuraEnabled
public static HCCostCaseDetailWrapper getHealthcareCostsPharmacareForCase(String caseId, String filterValue, Integer pageSize, Integer pageNumber, String sortOrder){
    List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
    HCCostCaseDetailWrapper caseDetailWrapper = new HCCostCaseDetailWrapper();
    String sourceSystemId = null;
    Integer totalCount = 0;
    Integer startItemNumber = 0;
    String pharmacareFields = Label.TPL_Pharmacare_Fields;
        try{
        Id recordTypeId = HCCostRecordTypeIds.getPharmacareRecordId();
        totalCount = HCCostCaseController.getHCCostCountonCase(caseId, filterValue, recordTypeId);
        startItemNumber = HCCostCaseController.getStartNumber(pageSize, pageNumber, totalCount);
        hccCostList = HCCostCaseDAO.getHCCostCaseRecords(caseId, filterValue, recordTypeId, startItemNumber, pageSize, pharmacareFields,sortOrder);
        caseDetailWrapper.hccList = hccCostList;
        caseDetailWrapper.totalCount = totalCount;
    } catch(NullPointerException nullpointer){
        System.debug(nullpointer.getMessage());
    }
    catch(QueryException qe) {
        System.debug(qe.getMessage());    
    }
    return caseDetailWrapper;
}

        /*
* Description: Method to get the list of Healthcare cost records for MSP Record type at case level
* Parameters:
*    String caseId: caseId contains the Case ID parameter to find out the Healthcare Cost records for associated case ID
*    String filterValue: This parameter gives the parameter 
*    Integer pageNumber: Page Number parameter tells the current page number from the grid
*    Integer pageSize: Page Size parameter gives the count of records displayed on the page
*    String sortOrder: sortOrder string states if the order is ascending or descending 
* Returns:
*     HCCostCaseDetailWrapper: Returns the caseDetailWrapper that contains Healthcare Cost List and total count of Healthcare cost records
* 
*/
@AuraEnabled
public static HCCostCaseDetailWrapper getHealthcareCostsMSPForCase(String caseId, String filterValue, Integer pageNumber, Integer pageSize, String sortOrder)
{ 
    List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
    HCCostCaseDetailWrapper caseDetailWrapper = new HCCostCaseDetailWrapper();
    String sourceSystemId = null;
    Integer totalCount = 0;
    Integer startItemNumber = 0;
    String mspFields = Label.TPL_MSP_Fields;
    try{
        Id recordTypeId = HCCostRecordTypeIds.getMSPRecordId();
        totalCount = HCCostCaseController.getHCCostCountonCase(caseId, filterValue, recordTypeId);
        startItemNumber = HCCostCaseController.getStartNumber(pageSize, pageNumber, totalCount);
        hccCostList = HCCostCaseDAO.getHCCostCaseRecords(caseId, filterValue, recordTypeId, startItemNumber, pageSize, mspFields, sortOrder);
        caseDetailWrapper.hccList = hccCostList;
        caseDetailWrapper.totalCount = totalCount;
    } catch(NullPointerException nullpointer){
        nullpointer.getMessage();
    }
    catch(QueryException qe) {
        System.debug(qe.getMessage());    
    }
    return caseDetailWrapper;
}

        /*
* Description: Method to get the list of Healthcare cost records for Hospitalization  Record type at case level
* Parameters:
*    String caseId: caseId contains the Case ID parameter to find out the Healthcare Cost records for associated case ID
*    String filterValue: This parameter gives the parameter 
*    Integer pageNumber: Page Number parameter tells the current page number from the grid
*    Integer pageSize: Page Size parameter gives the count of records displayed on the page
*    String sortOrder: sortOrder string states if the order is ascending or descending 
* Returns:
*     HCCostCaseDetailWrapper: Returns the caseDetailWrapper that contains Healthcare Cost List and total count of Healthcare cost records
* 
*/

@AuraEnabled
public static HCCostCaseDetailWrapper getHealthcareCostsHospitalForCase(String caseId, String filterValue, Integer pageNumber, Integer pageSize, String sortOrder){
    List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
    HCCostCaseDetailWrapper caseDetailWrapper = new HCCostCaseDetailWrapper();
    String sourceSystemId = null;
    Integer totalCount = 0;
    Integer startItemNumber = 0;
    String hospitalFields = Label.TPL_Hospitalization_Fields;
    try{
        Id recordTypeId = HCCostRecordTypeIds.getHospitalRecordId();
        totalCount = HCCostCaseController.getHCCostCountonCase(caseId, filterValue, recordTypeId);
        startItemNumber = HCCostCaseController.getStartNumber(pageSize, pageNumber, totalCount);
        hccCostList = HCCostCaseDAO.getHCCostCaseRecords(caseId, filterValue, recordTypeId, startItemNumber, pageSize, hospitalFields, sortOrder);
        caseDetailWrapper.hccList = hccCostList;
        caseDetailWrapper.totalCount = totalCount;
    } catch(NullPointerException nullpointer){
        System.debug(nullpointer.getMessage());
    }
    catch(QueryException qe) {
        System.debug(qe.getMessage());    
    }
    return caseDetailWrapper;
}

    /*
* Description: Method to get the list of Healthcare cost records for Continuing Care Record type at case level
* Parameters:
*    String caseId: caseId contains the Case ID parameter to find out the Healthcare Cost records for associated case ID
*    String filterValue: This parameter gives the parameter 
*    Integer pageNumber: Page Number parameter tells the current page number from the grid
*    Integer pageSize: Page Size parameter gives the count of records displayed on the page
*    String sortOrder: sortOrder string states if the order is ascending or descending 
* Returns:
*     HCCostCaseDetailWrapper: Returns the caseDetailWrapper that contains Healthcare Cost List and total count of Healthcare cost records
* 
*/
@AuraEnabled
public static HCCostCaseDetailWrapper getHealthcareCostsCCForCase(String caseId, String filterValue, Integer pageNumber, Integer pageSize, String sortOrder){
    List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
    HCCostCaseDetailWrapper caseDetailWrapper = new HCCostCaseDetailWrapper();
    Integer totalCount = 0;
    Integer startItemNumber = 0;
    String countinuingCareFields = Label.TPL_Continuing_Care_Fields;
    try{
        Id recordTypeId = HCCostRecordTypeIds.getContinuingCareRecordId();
        totalCount = HCCostCaseController.getHCCostCountonCase(caseId, filterValue, recordTypeId);
        startItemNumber = HCCostCaseController.getStartNumber(pageSize, pageNumber, totalCount);
        hccCostList = HCCostCaseDAO.getHCCostCaseRecords(caseId, filterValue, recordTypeId, startItemNumber, pageSize, countinuingCareFields, sortOrder);
        caseDetailWrapper.hccList = hccCostList;
        caseDetailWrapper.totalCount = totalCount;
    } catch(NullPointerException nullpointer){
        System.debug(nullpointer.getMessage());
    }
    catch(QueryException qe) {
        System.debug(qe.getMessage());    
    }
    return caseDetailWrapper;
}

    /*
* Description: Method to get the list of Healthcare cost records for Future Care Record type at case level
* Parameters:
*    String caseId: caseId contains the Case ID parameter to find out the Healthcare Cost records for associated case ID
*    String filterValue: This parameter gives the parameter 
*    Integer pageNumber: Page Number parameter tells the current page number from the grid
*    Integer pageSize: Page Size parameter gives the count of records displayed on the page
*    String sortOrder: sortOrder string states if the order is ascending or descending 
* Returns:
*     HCCostCaseDetailWrapper: Returns the caseDetailWrapper that contains Healthcare Cost List and total count of Healthcare cost records
* 
*/
@AuraEnabled
public static HCCostCaseDetailWrapper getHealthcareCostsFCForCase(String caseId, String filterValue, Integer pageNumber, Integer pageSize, String sortOrder){
    List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
    HCCostCaseDetailWrapper caseDetailWrapper = new HCCostCaseDetailWrapper();
    Integer totalCount = 0;
    Integer startItemNumber = 0;
    String futureCareFields = Label.TPL_Future_Care_Fields;
    try{
        Id recordTypeId = HCCostRecordTypeIds.getFutureCareRecordId();
        totalCount = HCCostCaseController.getHCCostCountonCase(caseId, filterValue, recordTypeId);
        startItemNumber = HCCostCaseController.getStartNumber(pageSize, pageNumber, totalCount);
        hccCostList = HCCostCaseDAO.getHCCostCaseRecords(caseId, filterValue, recordTypeId, startItemNumber, pageSize, futureCareFields, sortOrder);
        caseDetailWrapper.hccList = hccCostList;
        caseDetailWrapper.totalCount = totalCount;
    } catch(NullPointerException nullpointer){
        System.debug(nullpointer.getMessage());
    }
    catch(QueryException qe) {
        System.debug(qe.getMessage());    
    }
    return caseDetailWrapper;
}

/*
* Description: Wrapper class to perform transactions on case level in Healthcare cost.
* Parameters:
*    List<Healthcare_Cost__c> hccList: Contains the Healthcare Cost records List
*    Integer totalCount: This count is the total number of Healthcare Cost records for given record type
*/  
public class HCCostCaseDetailWrapper{
    @AuraEnabled public List<Healthcare_Cost__c> hccList {get;set;}
    @AuraEnabled public Integer totalCount {get;set;}
}
}