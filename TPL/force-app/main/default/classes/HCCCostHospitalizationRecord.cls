public with sharing class HCCCostHospitalizationRecord {
    private static Id getHospitalRecordId(){
        return Schema.SObjectType.Healthcare_Cost__c.getRecordTypeInfosByName().get('Hospitalization').getRecordTypeId();
    }
        @AuraEnabled(cacheable=true)
    public static List <Healthcare_Cost__c> getHealthcareCostsHospitalForAccount(String accId)
    {
        List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
        try{
        	Id recordTypeId = getHospitalRecordId();
            hccCostList = [select Case2__c, Case_Number__c, Cost_Include__c, Cost_Review__c, Name, Date_of_Service__c, Location_of_Incident__c, FacilityName__c, Service_Provider_Facility__c, Description_of_Incident__c, Intervention_Code_CCI__c, CCI_Level__c, Site_Code__c, Facility__c, Date_of_Admission__c, Date_of_Discharge__c, Number_of_Days__c, Service_Provided_by_Facility__c, Service_Type2__c, Standard_Daily_Rate__c, Total_Costs_Standard__c, Total_Cost_Override__c, Diagnostic_Treatment_Service__c from Healthcare_Cost__c where Account__c = :accId and RecordTypeId = :recordTypeId ORDER BY Name LIMIT 50000];
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
    public static Integer getHospitalCountonAccount(String accId){
        Integer countHospitalAccount = 0;
        try {
            Id recordTypeId = getHospitalRecordId();
            countHospitalAccount = [SELECT count() from Healthcare_Cost__c where Account__c = :accId and RecordTypeId = :recordTypeId];

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        System.debug('Count of Hospital records on Account  : ' + countHospitalAccount);
        return countHospitalAccount;
    }
     @AuraEnabled(cacheable=true)
    public static List <Healthcare_Cost__c> getHealthcareCostsHospitalForCase(String caseId){
     	List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
        try{
            Id recordTypeId = getHospitalRecordId();
           
            hccCostList = [select Case2__c, Case_Number__c, Cost_Include__c, Cost_Review__c, Name, Date_of_Service__c, FacilityName__c, Service_Provider_Facility__c, Location_of_Incident__c, Description_of_Incident__c, Intervention_Code_CCI__c, CCI_Level__c, Site_Code__c, Facility__c, Date_of_Admission__c, Date_of_Discharge__c, Number_of_Days__c, Service_Provided_by_Facility__c, Service_Type2__c, Standard_Daily_Rate__c, Total_Costs_Standard__c, Total_Cost_Override__c, Diagnostic_Treatment_Service__c, Source_System_ID__c  from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId ORDER BY Name DESC LIMIT 50000];
            
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
                giveStatus = Label.TPL_Failed;
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
                    giveStatus = Label.TPL_Failed;
                    return giveStatus;
                }
                else{
                    update updatedHealthcareCosts;
                    giveStatus = Label.TPL_Passed;
                }
            }
        }
        catch(DmlException dmlexception){
            dmlexception.getMessage();
        }
        return giveStatus;
    }

}