public with sharing class HCCCostCCRecord {
    
    private static Id getContinuingCareRecordId(){
       return Schema.SObjectType.Healthcare_Cost__c.getRecordTypeInfosByName().get('Continuing Care').getRecordTypeId();
    }
    
    @AuraEnabled(cacheable=true)
    public static List <Healthcare_Cost__c> getHealthcareCostsCCForCase(String caseId){
        List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
        try{
            Id recordTypeId = getContinuingCareRecordId();
            
            hccCostList = [SELECT Cost__c, Description__c, Case2__c, Case_Number__c, Name FROM Healthcare_Cost__c WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId ORDER BY Name DESC LIMIT 50000]; 
            System.debug('HCC Cost List Size (CC) : ' + hccCostList.size());
            
        }
        catch(NullPointerException nullpointer){
            nullpointer.getMessage();
        }
        catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return hccCostList;
    }
    
    @AuraEnabled(cacheable=true)
    public static Integer getContinuingCareCountonCase(String caseId){
        Integer countContinuingCareCases = 0;
        try {
            Id recordTypeId = getContinuingCareRecordId();
            countContinuingCareCases = [SELECT count() from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId];

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        System.debug('Count of Ambulance records on Account  : ' + countContinuingCareCases);
        return countContinuingCareCases;
    }

    @AuraEnabled
    public static String deleteContinuingCareRecords(List<Healthcare_Cost__c> deletionRecords){
        String result = null;
        System.debug('Deletion Records Size : ' + deletionRecords.size());
        try {
            if(deletionRecords.size() == 0 || deletionRecords == null)
            {
                result = Label.TPL_Failed;
            }
            else{
                delete deletionRecords;
                result = Label.TPL_Passed;
            }
        } catch (DMLException dml) {
            dml.getMessage();
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return result; 
    }
}