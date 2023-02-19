public with sharing class HCCCostAmbulanceRecord {
    
    private static Id getAmbulanceRecordId(){
        return Schema.SObjectType.Healthcare_Cost__c.getRecordTypeInfosByName().get('Ambulance').getRecordTypeId();
    }

    @AuraEnabled(cacheable=true)
    public static List <Healthcare_Cost__c> getHealthcareCostsAmbulanceForAccount(String accId, Integer limitValue, Integer offset) /*, Integer limitSize, Integer offset */
    {
        try{
        	
            List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
        	Id recordTypeId = getAmbulanceRecordId();
            hccCostList = [select Case2__c, Case_Number__c, Cost_Include__c, Cost_Review__c, Name, Date_of_Service__c, Location_Responded__c, Basic_Amount__c, Cost__c, Total_Cost_Override__c, Site_Code__c, Facility__c, Sub_Total__c, Fixed_Wing_Helicopter__c from Healthcare_Cost__c where Account__c = :accId and RecordTypeId = :recordTypeId ORDER BY Name LIMIT :limitValue OFFSET :offset];
            System.debug('HCC Cost List (Account Records) : ' + hccCostList.size());
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
    
    @AuraEnabled(cacheable=true)
    public static Integer getAmbulanceCountonAccount(String accId){
        Integer countAmbulanceAccount = 0;
        try {
            Id recordTypeId = getAmbulanceRecordId();
            countAmbulanceAccount = [SELECT count() from Healthcare_Cost__c where Account__c = :accId and RecordTypeId = :recordTypeId];

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        System.debug('Count of Ambulance records on Account  : ' + countAmbulanceAccount);
        return countAmbulanceAccount;
    }
    
    @AuraEnabled
    public static String updateHCCRecordInformation(List<Healthcare_Cost__c> hccIds){
        Id caseId = null;
        String giveStatus = null;
        Boolean checkFail = false;
      
        try {
            for(Healthcare_Cost__c hcc: hccIds){
                
                if(hcc.Cost_Include__c == true || hcc.Cost_Review__c == true){
                    checkFail = true;
                  
                }
                else{
                    hcc.Case2__c = caseId;
                    checkFail = false;
                }      
            }
            if(checkFail == true){
                giveStatus = Label.Failed;
                return giveStatus;
            }
            else{
                update hccIds;
                giveStatus = Label.Passed;
            }
        
        } catch (DmlException dmlexception) {
            dmlexception.getMessage();
        }
        return giveStatus;
    }
    
     @AuraEnabled(cacheable=true)
    public static List <Healthcare_Cost__c> getHealthcareCostsAmbulanceForCase(String caseId){
    try{
            Id recordTypeId = getAmbulanceRecordId();
            List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
            hccCostList = [select Cost_Include__c, Cost_Review__c, Name, Date_of_Service__c, Location_Responded__c, Basic_Amount__c, Cost__c, Total_Cost_Override__c, Fixed_Wing_Helicopter__c, Site_Code__c, Facility__c, Sub_Total__c from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId ORDER BY Name DESC LIMIT 2000];
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
        
        try{
            if(caseId == null || caseId.length() == 0 || hccIds.size() == 0){
                giveStatus = Label.Failed;
                return giveStatus;
            }
            else{
                for(String hccId: hccIds){
                   updatedHealthcareCosts.add(new Healthcare_Cost__c(Id= hccId, Case2__c = caseId));
                }
                giveStatus = Label.Passed;    
                update updatedHealthcareCosts;
            }
        }
        catch(DmlException dmlexception){
            dmlexception.getMessage();
        }
        return giveStatus;
    }
}