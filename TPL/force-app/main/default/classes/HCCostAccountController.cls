public with sharing class HCCostAccountController {
    
    private static Integer getHCCostCountonAccount(String accId, String selectedFilterValue, Id recordTypeId){
        if(selectedFilterValue == Label.TPL_All_Records)
        {
            return [SELECT count() from Healthcare_Cost__c where Account__c = :accId and RecordTypeId = :recordTypeId];            
        }
        else{
            return [SELECT count() from Healthcare_Cost__c where Account__c = :accId and RecordTypeId = :recordTypeId and Cost_Include__c = false and Cost_Review__c = false];
        }
    }
    
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
    @AuraEnabled
    public static List<Healthcare_cost__c> assignAll(String currentAccountId,String newCaseId,List<Healthcare_cost__c> currentRecords,String recordType){
        List<Healthcare_Cost__c> hccList = [select id,case2__c from Healthcare_Cost__c where Account__c =: currentAccountId and id NOT IN: currentRecords and Cost_Include__c = false and Cost_Review__c = false and recordType.name =: RecordType FOR UPDATE];
        System.debug(newCaseId);
        if(String.isBlank(newCaseId)){
           newCaseId = null; 
        }
        System.debug(newCaseId);
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
    @AuraEnabled
    public static boolean checkIfProcessing(String userId){
        System.debug(userId);
        List<AsyncApexJob> listOfJobs = [Select id ,Status, ApexClass.Name,CreatedById from AsyncApexJob where Status='Processing' and JobType = 'Queueable' and CreatedById =:userId];
        System.debug(listOfJobs);
        if(listOfJobs.size()>0){
            return true;
        }else{
            return false;
        }
    }
    public class HCCostAccountDetailWrapper{
        @AuraEnabled public List<Healthcare_Cost__c> hccList {get;set;}
        @AuraEnabled public Integer totalCount {get;set;}
    }
}