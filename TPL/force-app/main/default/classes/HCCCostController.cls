public with sharing class HCCCostController {
    //String phn = '7896785674';
        
    @AuraEnabled(cacheable=true)
    public static List <Healthcare_Cost__c> getHealthcareCostsAmbulance(String accId){
        String accName = null;
        String caseNum = null;
        try{
            List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
            hccCostList = [select PHN__c, Cost_Include__c, Cost_Review__c, Name, Case__c, Account__c,RecordTypeName__c, Basic_Amount__c, Cost__c,Total_Override__c from Healthcare_Cost__c where Account__c = :accId and RecordTypeName__c = 'Ambulance'  WITH SECURITY_ENFORCED LIMIT 2000];
            return hccCostList;
     }
        catch(NullPointerException nullpointer){
            return null;
        }
    }

    /*
    @AuraEnabled(cacheable=true)
    public static List <Healthcare_Cost__c> getHealthcareCostsHospital(String accId){
        String accName = null;
        String caseNum = null;
        try{
            List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
            hccCostList = [select PHN__c, Cost_Include__c, Cost_Review__c, Name, Case__c, Account__c from Healthcare_Cost__c where Account__c = :accId and RecordTypeName__c = 'Hospitalization'  WITH SECURITY_ENFORCED];
         
            return hccCostList;
     }
        catch(NullPointerException nullpointer){
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List <Healthcare_Cost__c> getHealthcareCostsMSP(String accId){
        String accName = null;
        String caseNum = null;
        try{
            List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
            hccCostList = [select PHN__c, Cost_Include__c, Cost_Review__c, Name, Case__c, Account__c from Healthcare_Cost__c where Account__c = :accId and RecordTypeName__c = 'MSP' WITH SECURITY_ENFORCED];
            return hccCostList;
     }
        catch(NullPointerException nullpointer){
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List <Healthcare_Cost__c> getHealthcareCostsPharmacare(String accId){
        String accName = null;
        String caseNum = null;
        try{
          return [select PHN__c, Cost_Include__c, Cost_Review__c, Name, Case__c, Account__c from Healthcare_Cost__c where Account__c = :accId and RecordTypeName__c = 'Pharmacare' WITH SECURITY_ENFORCED];
     }
        catch(NullPointerException nullpointer){
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List <Healthcare_Cost__c> getHealthcareCostsContinuingCare(String accId){
        String accName = null;
        String caseNum = null;
        try{
            return [select PHN__c, Cost_Include__c, Cost_Review__c, Name, Case__c, Account__c from Healthcare_Cost__c where Account__c = :accId and RecordTypeName__c = 'Continuing_Care' WITH SECURITY_ENFORCED];
        }
        catch(NullPointerException nullpointer){
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List <Healthcare_Cost__c> getHealthcareCostsFutureCare(String accId){
        String accName = null;
        String caseNum = null;
        try{
            return [select PHN__c, Cost_Include__c, Cost_Review__c, Name, Case__c, Account__c from Healthcare_Cost__c where Account__c = :accId and RecordTypeName__c = 'Future_Care' WITH SECURITY_ENFORCED];
        }
        catch(NullPointerException nullpointer){
            return null;
        }
    }
*/

}