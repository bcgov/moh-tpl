public with sharing class HCCCostController {
   
    @AuraEnabled(cacheable=true)
    public static List <Healthcare_Cost__c> getHealthcareCostsAmbulanceForAccount(String accId){
        String accName = null;
        String caseNum = null;
        try{
            List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
            hccCostList = [select Case__c, Cost_Include__c, Cost_Review__c, Name, Date_of_Service__c, Location_Responded__c, Facility_Code__c, Basic_Amount__c, Cost__c, Total_Override__c, Fixed_Wing_Helicopter__c from Healthcare_Cost__c where Account__c = :accId and RecordTypeName__c = 'Ambulance' WITH SECURITY_ENFORCED LIMIT 2000];
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
    public static List<Account> listOfIndividualAccounts(){
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
    public static List<Case> caseListIndividual(){
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
}