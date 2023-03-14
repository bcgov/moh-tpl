public with sharing class HCCCostAmbulanceRecord {
    
    private static Id getAmbulanceRecordId(){
        return Schema.SObjectType.Healthcare_Cost__c.getRecordTypeInfosByName().get('Ambulance').getRecordTypeId();
    }

    @AuraEnabled(cacheable=true)
    public static List <Healthcare_Cost__c> getHealthcareCostsAmbulanceForAccount(String accId, String selectedFilterValue)
    {
        List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
        Boolean costInclude, costReview;
        try{
        	Id recordTypeId = getAmbulanceRecordId();
            if(selectedFilterValue == Label.TPL_All_Records){
                hccCostList = [select Case2__c, Case_Number__c, Cost_Include__c, Cost_Review__c, Name, Date_of_Service__c, Location_Responded__c, Basic_Amount__c, Cost__c, Total_Cost_Override__c, Site_Code__c, Facility__c, FacilityName__c, Sub_Total__c, Fixed_Wing_Helicopter__c from Healthcare_Cost__c where Account__c = :accId and RecordTypeId = :recordTypeId ORDER BY Name  LIMIT 50000];
                System.debug('HCC Cost List (Account Records) : ' + hccCostList.size());      
            }
            else{
                if(selectedFilterValue == Label.TPL_Both_Checked)
                {
                    costInclude = true;
                    costReview =true;
                }
                else if(selectedFilterValue == Label.TPL_Cost_Review_Checked){
                    costInclude = false;
                    costReview = true;
                }
                else if(selectedFilterValue == Label.TPL_Cost_Include_Checked){
                    costInclude = true;
                    costReview = false;
                }
                else if(selectedFilterValue == Label.TPL_Both_Unchecked){
                    costInclude = false;
                    costReview = false;
                }
                hccCostList = [select Case2__c, Case_Number__c, Cost_Include__c, Cost_Review__c, Name, Date_of_Service__c, Location_Responded__c, Basic_Amount__c, Cost__c, Total_Cost_Override__c, Site_Code__c, Facility__c, FacilityName__c, Sub_Total__c, Fixed_Wing_Helicopter__c from Healthcare_Cost__c where Account__c = :accId and RecordTypeId = :recordTypeId and Cost_Review__c = :costReview and Cost_Include__c = :costInclude ORDER BY Name  LIMIT 50000];
                System.debug('HCC Cost List (Account Records) : ' + hccCostList.size());      
    
            }
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
    
     @AuraEnabled(cacheable=true)
    public static List <Healthcare_Cost__c> getHealthcareCostsAmbulanceForCase(String caseId, String filterValue){
     	List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
        try{
            Id recordTypeId = getAmbulanceRecordId();
            String sourceSystemId = null;
            if(filterValue == Label.Manual_Records)
            {
                hccCostList = [select Cost_Include__c, Cost_Review__c, Name, Date_of_Service__c, Location_Responded__c, Basic_Amount__c, Cost__c, Total_Cost_Override__c, Fixed_Wing_Helicopter__c, Site_Code__c, Facility__c, FacilityName__c, Sub_Total__c, Source_System_ID__c from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId and Source_System_ID__c = :sourceSystemId ORDER BY Name DESC  LIMIT 50000];

            }
            else{
                hccCostList = [select Cost_Include__c, Cost_Review__c, Name, Date_of_Service__c, Location_Responded__c, Basic_Amount__c, Cost__c, Total_Cost_Override__c, Fixed_Wing_Helicopter__c, Site_Code__c, Facility__c, FacilityName__c, Sub_Total__c, Source_System_ID__c from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId ORDER BY Name DESC  LIMIT 50000];
            } 
            
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
       
        try{
            if(caseId == null || caseId.length() == 0 || hccList.size() == 0){
                giveStatus = Label.TPL_Empty_Selection;
                return giveStatus;
            }
            else{
            
                for(Healthcare_Cost__c hcc: hccList){
                
                    if(hcc.Cost_Include__c == true || hcc.Cost_Review__c == true){
                        checkFail = true;
                        break;
                      
                    }
                    else{
                        updatedHealthcareCosts.add(new Healthcare_Cost__c(Id= hcc.Id, Case2__c = caseId));
                        checkFail = false;
                    }      
                }
                if(checkFail){
                    giveStatus = Label.TPL_Failed;
                }
                else{
                    update updatedHealthcareCosts;
                    giveStatus = Label.TPL_Passed;
    
                }
            }
            
        }
        catch(DmlException dmlexception){
            System.debug(dmlexception.getMessage());
            giveStatus = Label.Failed;
        }
        return giveStatus;
    }
}