public with sharing class HCCCostPharmacareRecord {
 private static Id getPharmacareRecordId(){
        return Schema.SObjectType.Healthcare_Cost__c.getRecordTypeInfosByName().get('Pharmacare').getRecordTypeId();
    }
        @AuraEnabled(cacheable=true)
    public static List <Healthcare_Cost__c> getHealthcareCostsPharmacareForAccount(String accId)
    {
        List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
        try{
        	Id recordTypeId = getPharmacareRecordId();
            hccCostList = [select Case2__c, Case_Number__c, Account__c, Cost_Include__c, Cost_Review__c, Name, Date_of_Service__c, Practitioner_Name__c, DIN__c, Name_of_Drug__c, Cost_of_Drug__c, Total_Cost_Override__c from Healthcare_Cost__c where Account__c = :accId and RecordTypeId = :recordTypeId ORDER BY Name LIMIT 50000];
            System.debug('HCC Cost List (Account Records) : ' + hccCostList.size());      
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
    public static Integer getPharmacareCountonAccount(String accId){
        Integer countPharmacareAccount = 0;
        try {
            Id recordTypeId = getPharmacareRecordId();
            countPharmacareAccount = [SELECT count() from Healthcare_Cost__c where Account__c = :accId and RecordTypeId = :recordTypeId];

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        System.debug('Count of Pharmacare records on Account  : ' + countPharmacareAccount);
        return countPharmacareAccount;
    }
     @AuraEnabled(cacheable=true)
    public static List <Healthcare_Cost__c> getHealthcareCostsPharmacareForCase(String caseId){
     	List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
        try{
            Id recordTypeId = getPharmacareRecordId();
            hccCostList = [select Case2__c, Case_Number__c, Account__c, Cost_Include__c, Cost_Review__c, Name, Date_of_Service__c, Practitioner_Name__c, DIN__c, Name_of_Drug__c, Cost_of_Drug__c, Total_Cost_Override__c, Source_System_ID__c from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId ORDER BY Name DESC LIMIT 50000];   
     }
        catch(NullPointerException nullpointer){
            nullpointer.getMessage();
        }
        catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return hccCostList;
    }

    @AuraEnabled
    public static String updateHCCCaseInformation (List<Healthcare_Cost__c> hccList, String caseId){
        List <Healthcare_Cost__c> updatedHealthcareCosts = new List<Healthcare_Cost__c>();
        String giveStatus = null;
        Boolean checkFail = false;
        Integer totalResultsCount = hccList.size();
        Integer verifyFalseResultCount = 0;
        try{
            if(caseId == null || caseId.length() == 0 || hccList.size() == 0){
                giveStatus = Label.Failed;
                return giveStatus;
            }
            else{
            
                for(Healthcare_Cost__c hcc: hccList){
                
                    if(hcc.Cost_Include__c == true || hcc.Cost_Review__c == true){
                        checkFail = true;
                        verifyFalseResultCount ++;
                      
                    }
                    else{
                        updatedHealthcareCosts.add(new Healthcare_Cost__c(Id= hcc.Id, Case2__c = caseId));
                        checkFail = false;
                    }      
                }
                
                if(verifyFalseResultCount == totalResultsCount){
                    giveStatus = Label.Failed;
                    return giveStatus;
                }
                else{
                    update updatedHealthcareCosts;
                    giveStatus = Label.Passed;
                }
            }
        }
        catch(DmlException dmlexception){
            dmlexception.getMessage();
        }
        return giveStatus;
    }

}