public with sharing class HCCCostController {
   
    @AuraEnabled(cacheable=true)
    public static List <Healthcare_Cost__c> getHealthcareCostsAmbulanceForAccount(String accId){
        String accName = null;
        String caseNum = null;
        try{
            List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
            hccCostList = [select Account__r.Name, Case__r.CaseNumber, Case__c, Account__c, Cost_Include__c, Cost_Review__c, Name, Date_of_Service__c, Location_Responded__c, Facility_Code__c, Basic_Amount__c, Cost__c, Total_Override__c, Fixed_Wing_Helicopter__c from Healthcare_Cost__c where Account__c = :accId WITH SECURITY_ENFORCED LIMIT 2000];
            return hccCostList;
     }
        catch(NullPointerException nullpointer){
            nullpointer.getMessage();
        }
        catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return null;
    }

    @AuraEnabled (cacheable = true)
    public static List<Account> getListOfIndividualAccounts(){
        try {
            List<Account> accList = new List<Account>();
            Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Individual').getRecordTypeId();
            accList = [select Name from Account where RecordTypeId =: recordTypeId LIMIT 100];
            return accList;
        } 
        catch(NullPointerException nullpointer){
            nullpointer.getMessage();
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return null;
    }

    @AuraEnabled (cacheable = true)
    public static List<Case> getCaseListIndividual(){
        try {
            List<Case> caseList = new List<Case>();
            Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Individual').getRecordTypeId();
            caseList = [select CaseNumber from Case where RecordTypeId =: recordTypeId LIMIT 100];
            return caseList;
        }
        catch(NullPointerException nullpointer){
            nullpointer.getMessage();
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return null;
    }

    @AuraEnabled(cacheable=true)
    public static List <Healthcare_Cost__c> getHealthcareCostsAmbulanceForCase(String caseId){
        String accName = null;
        String caseNum = null;
        try{
            List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
            hccCostList = [select  Account__r.Name, Case__r.CaseNumber, Account__c, Cost_Include__c, Cost_Review__c, Name, Date_of_Service__c, Location_Responded__c, Facility_Code__c, Basic_Amount__c, Cost__c, Total_Override__c, Fixed_Wing_Helicopter__c from Healthcare_Cost__c where Case__c = :caseId and RecordTypeName__c = 'Ambulance' WITH SECURITY_ENFORCED LIMIT 2000];
            return hccCostList;
     }
        catch(NullPointerException nullpointer){
            nullpointer.getMessage();
        }
        catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return null;
    }

    @AuraEnabled
    public static void saveDraftValues(Object data) {
        List<Healthcare_Cost__c> listOfHealthcareCost = (List<Healthcare_Cost__c>) JSON.deserialize(
            JSON.serialize(data),    
            List<Healthcare_Cost__c>.class
        );
        
        update listOfHealthcareCost;
    }
}