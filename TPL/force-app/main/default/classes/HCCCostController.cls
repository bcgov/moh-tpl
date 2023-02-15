public with sharing class HCCCostController {
   
    @AuraEnabled(cacheable=true)
    public static List <Healthcare_Cost__c> getHealthcareCostsAmbulanceForAccount(String accId){
    try{
            List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
            hccCostList = [select Case2__c, Case_Number__c, Cost_Include__c, Cost_Review__c, Name, Date_of_Service__c, Location_Responded__c, Basic_Amount__c, Cost__c, Total_Cost_Override__c, Fixed_Wing_Helicopter__c from Healthcare_Cost__c where Account__c = :accId and RecordTypeName__c = 'Ambulance' LIMIT 2000];
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
    public static List<Case> getCaseListIndividual(String accId){
        try {
            List<Case> caseList = new List<Case>();
            Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Individual').getRecordTypeId();
            caseList = [select CaseNumber from Case where RecordTypeId = :recordTypeId and AccountId = :accId LIMIT 100];
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

    @AuraEnabled
    public static String updateHCCRecordInformation(List<Healthcare_Cost__c> hccIds){
        Id caseId = null;
        String giveStatus = null;
        Boolean checkFail = false;
       // List <Healthcare_Cost__c> updatedHealthcareCosts = new List<Healthcare_Cost__c>();
        try {
            for(Healthcare_Cost__c hcc: hccIds){
                System.debug('hccId : ' + hcc.Id);
                if(hcc.Cost_Include__c == true || hcc.Cost_Review__c == true){
                    checkFail = true;
                   System.debug('Please uncheck Cost Include and Cost Review for HCC Cost : ' + hcc.Id);
                }
                else{
                    hcc.Case2__c = caseId;
                    checkFail = false;
                }
          //      updatedHealthcareCosts.add(new Healthcare_Cost__c(Id=hccId, Case2__c = caseId));
            }
            if(checkFail == true){
                giveStatus = 'Failed';
                return giveStatus;
            }
            else{
                update hccIds;
                giveStatus = 'Passed';
            }
          //  update updatedHealthcareCosts;
        } catch (DmlException dmlexception) {
            dmlexception.getMessage();
        }
        return giveStatus;
    }

    @AuraEnabled(cacheable=true)
    public static List <Healthcare_Cost__c> getHealthcareCostsAmbulanceForCase(String caseId){
    try{
            List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
            hccCostList = [select Cost_Include__c, Cost_Review__c, Name, Date_of_Service__c, Location_Responded__c, Basic_Amount__c, Cost__c, Total_Cost_Override__c, Fixed_Wing_Helicopter__c from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeName__c = 'Ambulance' LIMIT 2000];
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
    public static String updateHCCCaseInformation (List<String> hccIds, String caseId){
        List <Healthcare_Cost__c> updatedHealthcareCosts = new List<Healthcare_Cost__c>();
        String giveStatus = null;
        System.debug('Case ID : ' + caseId);
        try{
            if(caseId == null || caseId.length() == 0 || hccIds.size() == 0){
                giveStatus = 'Failed';
                return giveStatus;
            }
            else{
                for(String hccId: hccIds){
                    System.debug('hccId : '+hccId);
                    updatedHealthcareCosts.add(new Healthcare_Cost__c(Id= hccId, Case2__c = caseId));
                }
                update updatedHealthcareCosts;
                giveStatus = 'Passed';                    
            }
            
        }
        catch(DmlException dmlexception){
            dmlexception.getMessage();
        }
        return giveStatus;
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