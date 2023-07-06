/*
* Company: CGI for BC Ministry of Health
* Date: April 30, 2023
* Author: Anudish Jinturkar, Ahmed Shaik
* Description: public with sharing class HCCCostController
*    Methods:
*         saveDraftValues(Object data , List<Healthcare_Cost__c> recordDisplay,String recordType ): Written to save the HC Cost draft values in the database.
*         getCaseNumber(Set<Id> caseId): Method to get the case number from the input caseID given for the record
updateHCCCaseInformation (List<Healthcare_Cost__c> hccList, String caseId,List<Healthcare_Cost__c> recordDisplay): Method to update the Healthcare cost record information
*         deleteHCCRecord(List<Healthcare_Cost__c> deletionRecords, String filterOption): method implemented to delete the Healthcare cost records
*         getFacilityBySiteCode(Object siteCodeIds): Written to get the facility on the basis of Site Code given
*         updateAll(String caseId,Boolean costReview, Boolean costInclude,List<Healthcare_cost__c> currentRecords,String recordType): Method written to update the Cost Include and Cost Review of all the Healthcare Cost records on case
*         findIfUnderUpdate(String userId): method checks if any update operation is active for HC Cost record 
* History:
*     Initial version: March 31, 2023 - AJ
*     Updates to codebase: May 1, 2023 - AJ
*     Updates to codebase: Jun 20, 2023 - AS
*/

public with sharing class HCCCostController {
    
    /*
	* Description: Written to save the HC Cost draft values in the database.
	* Parameters:
	*     Object data: Healthcare Cost rows from the UI Grid which are modified and need to be updated in database
	*     List<Healthcare_Cost__c> recordDisplay: list of Healthcare cost records displayed on the grid in UI
	*     String recordType: Healthcare Cost record type name
	* Returns:
	*     CaseListWrapper: Returns caselistwrapper class output that has four parameters actionMessage (result message of update query), passedResult (transaction message if results are passed or partil success or fail), indexNumbers (if any error encountered then line number from the update list), and updatedRecords (returns updated list of HealthCare Cost records).
	* 
	*/
    @AuraEnabled
    public static CaseListWrapper saveDraftValues(Object data , List<Healthcare_Cost__c> recordDisplay,String recordType ) {
        String result = '';
        String passedResult = '';
        List<Healthcare_Cost__c> listOfHealthcareCost = (List<Healthcare_Cost__c>) JSON.deserialize(
            JSON.serialize(data),
            List<Healthcare_Cost__c>.class
        );
        
        CaseListWrapper caseListWrapper = new CaseListWrapper();
        Map<Id, Integer> rowCountMap = new Map<Id,Integer>();
        Map<Id,Healthcare_Cost__c> healthCareMap = new Map<Id,Healthcare_Cost__c>();
        Integer index = 1;
        for(Healthcare_Cost__c hcc: recordDisplay){
            rowCountMap.put(hcc.Id, index);
            healthCareMap.put(hcc.Id,hcc);
            index++;
        }   
        
        if(listOfHealthcareCost.size() > 0)
        {   
            Database.SaveResult[] srList = Database.update(listOfHealthcareCost, false);
            List<Integer> capturehccIds = new List<Integer>();
            List<Integer> capturedIndex = new List<Integer>();
            for (Database.SaveResult sr : srList){
                if (sr.isSuccess()) {
                    capturedIndex.add(rowCountMap.get(sr.getId()));
                }
                else{
                    for(Database.Error err : sr.getErrors()) {
                        result += 'Row ' + rowCountMap.get(sr.getId()) + ' ' + err.getMessage() + '\n';
                    }
                    
                }
            }
            String fields = '';
            if(recordType == 'Ambulance'){
                fields = Label.TPL_Ambulance_Fields;
            }
            else if(recordType == 'MSP'){
                fields = Label.TPL_MSP_Fields;
            }
            else if(recordType == 'Hospitalization'){
                fields = Label.TPL_Hospitalization_Fields;
            }
            else if(recordType == 'Pharmacare')
            {
                fields = Label.TPL_Pharmacare_Fields;
            }
            else if(recordType == 'Continuing Care')
            {
                fields = Label.TPL_Continuing_Care_Fields;
            }
            else if(recordType == 'Future Care'){
                fields = Label.TPL_Future_Care_Fields;
            }
            
            caseListWrapper.actionMessage = result;
            caseListWrapper.indexNumbers = capturedIndex;
            String query =  'SELECT ' + fields + ' FROM Healthcare_Cost__c WHERE ID IN:recordDisplay ';
            
            List<Healthcare_Cost__c> updatedRecords = database.query(query);
            if(capturedIndex.size() == listOfHealthcareCost.size()){
                caseListWrapper.passedResult = Label.TPL_Passed;
                caseListWrapper.updatedRecords = updatedRecords;
            }
            else if(capturedIndex.size() > 0){
                caseListWrapper.passedResult = Label.TPL_Partial_Success;
                caseListWrapper.updatedRecords = updatedRecords;
            }
            else if(capturedIndex.size() == 0){
                caseListWrapper.passedResult = Label.TPL_Failed;
                caseListWrapper.updatedRecords = updatedRecords;
            }
            
        }
        else{
            caseListWrapper.passedResult = Label.TPL_Failed;
        }
        return caseListWrapper;
    }
    
    /*
    * Description: Method to get the case number from the input caseID given for the record
    * Parameters:
    *    Set<Id> casedId: Unique set of caseId given to method to return caseNumbers associated to that record
    * Returns:
    *     List<Case> caseList: Returns case list that contains the case number for the caseId given
    * 
	*/
    public static List<Case> getCaseNumber(Set<Id> caseId){
        List<Case> caseList = new List<Case>();
        try {
            caseList = [Select CaseNumber,Id from Case where Id IN :caseId];
        } catch (DmlException dml) {
            System.debug(dml.getMessage());
        }
        return caseList;
    }
    
    /*
    * Description: Method to update the Healthcare cost record information
    * Parameters:
    *    List<Healthcare_Cost__c> hccList: case to be updated on the Healthcare cost records in the database
    *    String caseId: case ID for the given case number 
    *    List<Healthcare_Cost__c> recordDisplay: list of Healthcare cost records displayed on the grid in UI  
    * Returns:
    *     HCCostAccountCaseWrapper: Returns HCCostAccountCaseWrapper class output that has two parameters updateMessage (status message of update query), passMessage (transaction message if results are passed or partil success or fail)
    * 
    */
    @AuraEnabled
    public static HCCostAccountCaseWrapper updateHCCCaseInformation (List<Healthcare_Cost__c> hccList, String caseId,List<Healthcare_Cost__c> recordDisplay){
        String giveStatus = null;
        String passMessage = null;
        Boolean checkFail = false;
        HCCostAccountCaseWrapper hac = new HCCostAccountCaseWrapper();
        List<Healthcare_Cost__c> updateHealthCareCost = new List<Healthcare_Cost__c>();
        
        
        for(Healthcare_Cost__c hcc: hccList){
            if(hcc.Cost_Include__c == true || hcc.Cost_Review__c == true){
                checkFail = true;
                break;
            }
            else{
                
                if(String.isEmpty(caseId)){
                    caseId = null;
                   }
                    
                    Healthcare_Cost__c hc = new Healthcare_Cost__c();
                    hc.id = hcc.id;
                    hc.Case2__c = caseId;
                    updateHealthCareCost.add(hc);
                    checkFail = false;
                }      
            }
            
            if(!checkFail){ 
                Map<Id, Integer> rowCountMap = new Map<Id, Integer>();
                Integer index = 1;
                for(Healthcare_Cost__c hcc: recordDisplay){
                    rowCountMap.put(hcc.Id, index);
                    index++;
                }   
                try{
                    Database.SaveResult[] srList = Database.update(updateHealthCareCost, false);
                    String result = '';
                    List<Integer> capturedIndex = new List<Integer>();
                    for (Database.SaveResult sr : srList){
                        if (sr.isSuccess()) {
                            capturedIndex.add(rowCountMap.get(sr.getId()));
                        }
                        else{
                            for(Database.Error err : sr.getErrors()) {
                              result += 'Row ' + rowCountMap.get(sr.getId()) + ' ' + err.getMessage() + '\n';
                            }
                           
                        }
                    }
                    if(capturedIndex.size() == updateHealthCareCost.size())
                    {
                        passMessage = Label.TPL_Passed;
                  
                    }
                    else if(capturedIndex.size()>0){
                        passMessage = Label.TPL_Partial_Success;
                        giveStatus = result;
                    }
                    else{
                        giveStatus = result;
                    }  
                                        
                } 
                catch(DmlException dml){
                    giveStatus = dml.getMessage();
                }
                catch(NullPointerException np){
                    giveStatus = np.getMessage();
                } 
            }
            else{
                passMessage = Label.TPL_Failed;
            }
            
            hac.updateMessage = giveStatus;
            hac.passMessage = passMessage;
        
        return hac;
    }
    
    /*
    * Description: Method to delete the Healthcare cost record
    * Parameters:
    *    List<Healthcare_Cost__c> deletionRecords: this list contains the Healthcare cost records marked for deletion
    *    String filterOption: the filter option selected by user while marking deletion 
    * Returns:
    *     String : Returns a string message as the records deleted or not successfully
    * 
    */
    @AuraEnabled
    public static String deleteHCCRecord(List<Healthcare_Cost__c> deletionRecords, String filterOption){
        String result = null;
        try {
            if(deletionRecords.size() == 0 || deletionRecords == null || (filterOption != Label.TPL_Manual_Records && filterOption != Label.TPL_Records_Created_Today))
            {
                result = Label.TPL_Failed;
            }
            else{
                for(Healthcare_Cost__c hcc: deletionRecords){
                    if(hcc.Source_System_ID__c != null){
                        result = Label.TPL_Failed;
                        return result;
                    }
                }
                delete deletionRecords;
                result = Label.TPL_Passed;
            }
        } catch (DMLException dml) {
            result = Label.TPL_Insufficient_Privileges;
        }
        catch(ListException le){
            result = Label.TPL_Insufficient_Privileges;
        }   
        return result; 
    }
    
    public class tempClass{
        public string Id;
        public string siteCode;
    }
    
    /*
    * Description: Method to get the Facility Account details by Site Code on the Healthcare cost record
    * Parameters:
    *    Object siteCodeIds: Paramters passed as object list of site code to the method
    * Returns:
    *     List <Account> : Returns the list of accounts associated with the respective site codes as input parameters
    * 
    */  
    @AuraEnabled
    public static List<Account> getFacilityBySiteCode(Object siteCodeIds){
        
        try {
            List<tempClass> contactsForUpdate = (List<tempClass>) JSON.deserialize(
                JSON.serialize(siteCodeIds),
                List<tempClass>.class
            );
            Map<String,List<String>> healthCareMap = new Map<String,List<String>>();
            for(tempClass obj:contactsForUpdate){
                List<String> tempStringList = new List<String>();
                if(healthCareMap.containsKey(obj.siteCode)){
                    tempStringList.addAll(healthCareMap.get(obj.siteCode));
                    tempStringList.add(obj.Id);
                    healthCareMap.put(obj.siteCode,tempStringList);
                }
                else{
                    tempStringList.add(obj.Id);
                    healthCareMap.put(obj.siteCode,tempStringList);
                }
            }
            
            List<Healthcare_Cost__c> hccUpdate = new List<Healthcare_Cost__c>();
            List<Account> accList = [select id,name,Site_Code__c from account where Site_Code__c IN:healthCareMap.keySet()  LIMIT 1];
            for(Account a : accList){
                for(String id : healthCareMap.get(a.Site_Code__c)){
                    Healthcare_Cost__c hcc = new Healthcare_Cost__c();
                    hcc.id = id;
                    hcc.Facility__c = a.id;
                    hccUpdate.add(hcc);
                }
            }
            update hccUpdate;
            return accList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /*
    * Description: Method to update the cost include and cost review for all the Healthcare cost records of the record type
    * Parameters:
    *    String caseId: case Id value of the selected case record
    *    Boolean costReview: Cost Review value in the parameter if its checked (true) or unchecked (false)
    *    Boolean costInclude: Cost Include value in the parameter if its checked (true) or unchecked (false)
    *    List<Healthcare_cost__c> currentRecords: List of Healthcare Cost Records under the selected record type
    *    String recordType: record type selected of healthcare cost record
    * Returns:
    *     List <Healthcare_cost__c> : Returns the list of Healthcare_cost__c records currentRecords
    * 
    */  
    @AuraEnabled
    public static List<Healthcare_cost__c> updateAll(String caseId,Boolean costReview, Boolean costInclude,List<Healthcare_cost__c> currentRecords,String recordType){
        List<Healthcare_Cost__c> hccList = [select id,case2__c from Healthcare_Cost__c where ID NOT IN:currentRecords and case2__c  =: caseId and RecordType.developerName =:recordType   FOR UPDATE];
        for(Healthcare_Cost__c hcc : currentRecords){
            hcc.Cost_Include__c = costInclude;
            hcc.Cost_Review__c = costReview;
        }
        try{
            database.update(currentRecords,false);
        }catch(Exception e){
            System.debug(e);
        }
        for(Healthcare_Cost__c hcc : hccList){
            hcc.Cost_Include__c = costInclude;
            hcc.Cost_Review__c = costReview;
        }
        System.enqueueJob(new HCCQueueable(hccList));
        return currentRecords;
    }
    
    /*
    * Description: Method to update the cost include and cost review for all the Healthcare cost records of the record type
    * Parameters:
    *    String userId: user Id of the logged in user
    * Returns:
    *     Boolean : Returns status of current job execution
    * 
    */  
    @AuraEnabled
    public static Boolean findIfUnderUpdate(String userId){
        try {
            List<AsyncApexJob> apexJobs = [Select id ,Status, ApexClass.Name,CreatedById,JobType from AsyncApexJob where  JobType = 'Queueable'  and (status = 'Processing' or status = 'Queued') and createdbyId =:userId];
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
    * Description: Wrapper class to implement case list with message parameters.
    * Parameters:
    *    String actionMessage: Action message describes any actions to be performed after the DML execution
    *    String passedResult: Pass message in regards to status of DML transaction
    *    List<Integer> indexNumbers:  any row number where errors have been encountered in DML processsing 
    *    List<Healthcare_Cost__c> updatedRecords : list of Updated Records after DML operation
    */  
    public class CaseListWrapper{
        @AuraEnabled public String actionMessage {get;set;}
        @AuraEnabled public String passedResult {get;set;}
        @AuraEnabled public List<Integer> indexNumbers {get;set;}
        @AuraEnabled public List<Healthcare_Cost__c> updatedRecords{get;set;}
    }
    
    /*
    * Description: Wrapper class to perform transactions on account and case in Healthcare cost.
    * Parameters:
    *    String updateMessage: Update message describes any actions to be performed after the DML execution
    *    String passMessage: Pass message in regards to status of DML transaction
    */  
    public class HCCostAccountCaseWrapper{
        @AuraEnabled public String updateMessage {get;set;}
        @AuraEnabled public String passMessage {get;set;}
    }
}