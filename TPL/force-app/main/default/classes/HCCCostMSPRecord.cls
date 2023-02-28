public with sharing class HCCCostMSPRecord {
 private static Id getMSPRecordId(){
        return Schema.SObjectType.Healthcare_Cost__c.getRecordTypeInfosByName().get('MSP').getRecordTypeId();
    }
        @AuraEnabled(cacheable=true)
    public static List <Healthcare_Cost__c> getHealthcareCostsMSPForAccount(String accId)
    {
        List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
        try{
        	Id recordTypeId = getMSPRecordId();
            hccCostList = [select Case2__c, Case_Number__c, Account__c, Cost_Include__c, Cost_Review__c, Name, Date_of_Service__c, Facility_Type__c, FacilityName__c, Facility__c, Description_of_Service__c, Fee_Item_Code__c, Fee_Item_Title__c, Fee_Item_Description__c, Practitioner_Number__c, Practitioner_Name__c, Diagnostic_Code__c, Diagnostic_Description__c, Amount_Paid__c, Total_Cost_Override__c, Specialty_Code__c, Specialty_Description__c, Payee_Number__c, Payee_Description__c, Service_Start_Date__c, Service_Finish_Date__c, Location_Type_Code__c, Location_Type_Description__c from Healthcare_Cost__c where Account__c = :accId and RecordTypeId = :recordTypeId ORDER BY Name LIMIT 2000];
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
    public static Integer getMSPCountonAccount(String accId){
        Integer countMSPAccount = 0;
        try {
            Id recordTypeId = getMSPRecordId();
            countMSPAccount = [SELECT count() from Healthcare_Cost__c where Account__c = :accId and RecordTypeId = :recordTypeId];

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        System.debug('Count of MSP records on Account  : ' + countMSPAccount);
        return countMSPAccount;
    }
     @AuraEnabled(cacheable=true)
    public static List <Healthcare_Cost__c> getHealthcareCostsMSPForCase(String caseId){
     	List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
        try{
            Id recordTypeId = getMSPRecordId();
           
            hccCostList = [select Case2__c, Case_Number__c, Account__c, Cost_Include__c, Cost_Review__c, Name, Date_of_Service__c, Facility_Type__c, Facility__c, FacilityName__c, Description_of_Service__c, Fee_Item_Code__c, Fee_Item_Title__c, Fee_Item_Description__c, Practitioner_Number__c, Practitioner_Name__c, Diagnostic_Code__c, Diagnostic_Description__c, Amount_Paid__c, Total_Cost_Override__c, Specialty_Code__c, Specialty_Description__c, Payee_Number__c, Payee_Description__c, Service_Start_Date__c, Service_Finish_Date__c, Location_Type_Code__c, Location_Type_Description__c, Source_System_ID__c from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId ORDER BY Name DESC LIMIT 2000];
            
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