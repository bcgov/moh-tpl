public with sharing class HCCCostFCRecord {
	private static Id getFutureCareRecordId(){
       return Schema.SObjectType.Healthcare_Cost__c.getRecordTypeInfosByName().get('Future Care').getRecordTypeId(); 
    }
    
    @AuraEnabled(cacheable=true)
    public static List <Healthcare_Cost__c> getHealthcareCostsFCForCase(String caseId){
        List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
        try{
            Id recordTypeId = getFutureCareRecordId();
           
            hccCostList = [select Name, Case2__c, Case_Number__c, Cost__c, Description__c, Account__c from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId ORDER BY Name DESC LIMIT 2000];
            System.debug('HCC Cost List Size (FC) : ' + hccCostList.size());
            
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
    public static Integer getFutureCareCountonCase(String caseId){
        Integer counFutureCareCase = 0;
        try {
            Id recordTypeId = getFutureCareRecordId();
            counFutureCareCase = [SELECT count() from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId];

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        System.debug('Count of Ambulance records on Account  : ' + counFutureCareCase);
        return counFutureCareCase;
    }

    @AuraEnabled
    public static String deleteFutureCareRecords(List<Healthcare_Cost__c> deletionRecords){
        String result = null;
        System.debug('Deletion Records Size : ' + deletionRecords.size());
        try {
            if(deletionRecords.size() == 0 || deletionRecords == null)
            {
                result = Label.Failed;
            }
            else{
                delete deletionRecords;
                result = Label.Passed;
            }
        } catch (DMLException dml) {
            dml.getMessage();
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return result; 
    }
}