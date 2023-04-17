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
    public static HCCostAccountDetailWrapper getHealthcareCostsAmbulanceForAccount(String accId, String selectedFilterValue, Integer pageNumber, Integer pageSize){
        List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
        HCCostAccountDetailWrapper accountDetailWrapper = new HCCostAccountDetailWrapper();
        Integer startItemNumber = 0;
        Integer totalCount = 0;
        String ambulanceFields = Label.TPL_Ambulance_Fields;
        try {
            Id recordTypeId = HCCostRecordTypeIds.getAmbulanceRecordId();
            totalCount = HCCostAccountController.getHCCostCountonAccount(accId, selectedFilterValue, recordTypeId);
            startItemNumber = HCCostAccountController.getStartNumber(pageSize, pageNumber, totalCount);
            
            System.debug('Page Size : ' + pageSize + ', Page Number : ' + pageNumber + ', Total Count : ' + totalCount +', Start Item Number : ' + startItemNumber );
            System.debug('Ambulance Fields : ' + ambulanceFields);
            hccCostList = HCCostAccountDAO.getHCCostAccountRecords(accId, selectedFilterValue, recordTypeId, startItemNumber, pageSize, ambulanceFields);
            
            System.debug('HCC Cost List Size : ' + hccCostList.size());
            accountDetailWrapper.hccList = hccCostList;
            accountDetailWrapper.totalCount = totalCount;
        } catch(NullPointerException nullpointer){
            System.debug(nullpointer.getMessage());
        }
        catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return accountDetailWrapper;
    }

    @AuraEnabled
    public static HCCostAccountDetailWrapper getHealthcareCostsPharmacareForAccount(String accId, String selectedFilterValue, Integer pageNumber, Integer pageSize)
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
            System.debug('Pharmacare Fields : ' + pharmacareFields);
            System.debug('Page Size : ' + pageSize + ', Page Number : ' + pageNumber + ', Total Count : ' + totalCount +', Start Item Number : ' + startItemNumber );
            hccCostList = HCCostAccountDAO.getHCCostAccountRecords(accId, selectedFilterValue, recordTypeId, startItemNumber, pageSize, pharmacareFields);
            System.debug('HCC Cost List Size : ' + hccCostList.size());
            accountDetailWrapper.hccList = hccCostList;
            accountDetailWrapper.totalCount = totalCount;
        } catch(NullPointerException nullpointer){
            System.debug(nullpointer.getMessage());
        }
        catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return accountDetailWrapper;
    }

    @AuraEnabled
    public static HCCostAccountDetailWrapper getHealthcareCostsMSPForAccount(String accId, String selectedFilterValue, Integer pageNumber, Integer pageSize)
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
            System.debug('MSP Fields : ' + mspFields);
            System.debug('Page Size : ' + pageSize + ', Page Number : ' + pageNumber + ', Total Count : ' + totalCount +', Start Item Number : ' + startItemNumber );
            hccCostList = HCCostAccountDAO.getHCCostAccountRecords(accId, selectedFilterValue, recordTypeId, startItemNumber, pageSize, mspFields);
            System.debug('HCC Cost List Size : ' + hccCostList.size());
            accountDetailWrapper.hccList = hccCostList;
            accountDetailWrapper.totalCount = totalCount;
        } catch(NullPointerException nullpointer){
            System.debug(nullpointer.getMessage());
        }
        catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return accountDetailWrapper;
    }
    
    @AuraEnabled
    public static HCCostAccountDetailWrapper getHealthcareCostsHospitalForAccount(String accId, String selectedFilterValue, Integer pageNumber, Integer pageSize)
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
            System.debug('Hospital Fields : ' + hospitalFields);
            System.debug('Page Size : ' + pageSize + ', Page Number : ' + pageNumber + ', Total Count : ' + totalCount +', Start Item Number : ' + startItemNumber );
            hccCostList = HCCostAccountDAO.getHCCostAccountRecords(accId, selectedFilterValue, recordTypeId, startItemNumber, pageSize, hospitalFields);
            System.debug('HCC Cost List Size : ' + hccCostList.size());
            accountDetailWrapper.hccList = hccCostList;
            accountDetailWrapper.totalCount = totalCount;
        } catch(NullPointerException nullpointer){
            System.debug(nullpointer.getMessage());
        }
        catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return accountDetailWrapper;
    }

    @AuraEnabled
    public static HCCostAccountDetailWrapper getHealthcareCostsCCForAccount(String accId, String selectedFilterValue, Integer pageNumber, Integer pageSize)
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
            System.debug('Continuing Care Fields : ' + continuingCareFields);
            System.debug('Page Size : ' + pageSize + ', Page Number : ' + pageNumber + ', Total Count : ' + totalCount +', Start Item Number : ' + startItemNumber );
            hccCostList = HCCostAccountDAO.getHCCostAccountRecords(accId, selectedFilterValue, recordTypeId, startItemNumber, pageSize, continuingCareFields);
            System.debug('HCC Cost List Size : ' + hccCostList.size());
            accountDetailWrapper.hccList = hccCostList;
            accountDetailWrapper.totalCount = totalCount;
        } catch(NullPointerException nullpointer){
            System.debug(nullpointer.getMessage());
        }
        catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return accountDetailWrapper;
    }

    @AuraEnabled
    public static HCCostAccountDetailWrapper getHealthcareCostsFCForAccount(String accId, String selectedFilterValue, Integer pageNumber, Integer pageSize)
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
            System.debug('Future Care Fields : ' + futureCareFields);
            System.debug('Page Size : ' + pageSize + ', Page Number : ' + pageNumber + ', Total Count : ' + totalCount +', Start Item Number : ' + startItemNumber );
            hccCostList = HCCostAccountDAO.getHCCostAccountRecords(accId, selectedFilterValue, recordTypeId, startItemNumber, pageSize, futureCareFields);
            System.debug('HCC Cost List Size : ' + hccCostList.size());
            accountDetailWrapper.hccList = hccCostList;
            accountDetailWrapper.totalCount = totalCount;
        } catch(NullPointerException nullpointer){
            System.debug(nullpointer.getMessage());
        }
        catch(DmlException dml){
            System.debug(dml.getMessage());
        }
        catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return accountDetailWrapper;
    }

    public class HCCostAccountDetailWrapper{
        @AuraEnabled public List<Healthcare_Cost__c> hccList {get;set;}
        @AuraEnabled public Integer totalCount {get;set;}
    }
}