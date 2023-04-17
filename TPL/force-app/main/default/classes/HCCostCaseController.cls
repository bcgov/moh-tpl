public with sharing class HCCostCaseController {
    private static Integer getHCCostCountonCase(String caseId, String filterValue, Id recordTypeId){
        String sourceSystemId = null;
        if(filterValue == Label.TPL_Manual_Records){
            return [SELECT count() from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId and Source_System_ID__c = :sourceSystemId];
        }
        else if(filterValue == Label.TPL_Records_Created_Today) {
            return [SELECT count() from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId and Source_System_ID__c = :sourceSystemId and CreatedDate = TODAY];                
        }
        else 
        {
            return [SELECT count() from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId];
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
    public static HCCostCaseDetailWrapper getHealthcareCostsAmbulanceForCase(String caseId, String filterValue, Integer pageSize, Integer pageNumber){
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
            hccCostList = HCCostCaseDAO.getHCCostCaseRecords(caseId, filterValue, recordTypeId, startItemNumber, pageSize, ambulanceFields);
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

    @AuraEnabled
    public static HCCostCaseDetailWrapper getHealthcareCostsPharmacareForCase(String caseId, String filterValue, Integer pageSize, Integer pageNumber){
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
            hccCostList = HCCostCaseDAO.getHCCostCaseRecords(caseId, filterValue, recordTypeId, startItemNumber, pageSize, pharmacareFields);
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

    @AuraEnabled
    public static HCCostCaseDetailWrapper getHealthcareCostsMSPForCase(String caseId, String filterValue, Integer pageNumber, Integer pageSize)
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
            hccCostList = HCCostCaseDAO.getHCCostCaseRecords(caseId, filterValue, recordTypeId, startItemNumber, pageSize, mspFields);
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

    @AuraEnabled
    public static HCCostCaseDetailWrapper getHealthcareCostsHospitalForCase(String caseId, String filterValue, Integer pageNumber, Integer pageSize){
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
            hccCostList = HCCostCaseDAO.getHCCostCaseRecords(caseId, filterValue, recordTypeId, startItemNumber, pageSize, hospitalFields);
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

    @AuraEnabled
    public static HCCostCaseDetailWrapper getHealthcareCostsCCForCase(String caseId, String filterValue, Integer pageNumber, Integer pageSize){
        List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
        HCCostCaseDetailWrapper caseDetailWrapper = new HCCostCaseDetailWrapper();
        Integer totalCount = 0;
        Integer startItemNumber = 0;
        String countinuingCareFields = Label.TPL_Continuing_Care_Fields;
        try{
            Id recordTypeId = HCCostRecordTypeIds.getContinuingCareRecordId();
            totalCount = HCCostCaseController.getHCCostCountonCase(caseId, filterValue, recordTypeId);
            startItemNumber = HCCostCaseController.getStartNumber(pageSize, pageNumber, totalCount);
            hccCostList = HCCostCaseDAO.getHCCostCaseRecords(caseId, filterValue, recordTypeId, startItemNumber, pageSize, countinuingCareFields);
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

     
    @AuraEnabled
    public static HCCostCaseDetailWrapper getHealthcareCostsFCForCase(String caseId, String filterValue, Integer pageNumber, Integer pageSize){
        List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
        HCCostCaseDetailWrapper caseDetailWrapper = new HCCostCaseDetailWrapper();
        Integer totalCount = 0;
        Integer startItemNumber = 0;
        String futureCareFields = Label.TPL_Future_Care_Fields;
        try{
            Id recordTypeId = HCCostRecordTypeIds.getFutureCareRecordId();
            totalCount = HCCostCaseController.getHCCostCountonCase(caseId, filterValue, recordTypeId);
            startItemNumber = HCCostCaseController.getStartNumber(pageSize, pageNumber, totalCount);
            hccCostList = HCCostCaseDAO.getHCCostCaseRecords(caseId, filterValue, recordTypeId, startItemNumber, pageSize, futureCareFields);
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

    public class HCCostCaseDetailWrapper{
        @AuraEnabled public List<Healthcare_Cost__c> hccList {get;set;}
        @AuraEnabled public Integer totalCount {get;set;}
    }
}