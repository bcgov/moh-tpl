public with sharing class HCCCostController {
   
    @AuraEnabled(cacheable=true)
    public static List <Healthcare_Cost__c> getHealthcareCostsAmbulanceForAccount(String accId){
    try{
            List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
            hccCostList = [select Case2__c, Case_Number__c, Cost_Include__c, Cost_Review__c, Name, Date_of_Service__c, Location_Responded__c, Basic_Amount__c, Cost__c, Total_Cost_Override__c, Site_Code__c, Facility__c, Sub_Total__c, Fixed_Wing_Helicopter__c from Healthcare_Cost__c where Account__c = :accId and RecordTypeName__c = 'Ambulance' LIMIT 2000];
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
                giveStatus = 'Failed';
                return giveStatus;
            }
            else{
                update hccIds;
                giveStatus = 'Passed';
            }
        
        } catch (DmlException dmlexception) {
            dmlexception.getMessage();
        }
        return giveStatus;
    }

    @AuraEnabled(cacheable=true)
    public static List <Healthcare_Cost__c> getHealthcareCostsAmbulanceForCase(String caseId){
    try{
            List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
            hccCostList = [select Cost_Include__c, Cost_Review__c, Name, Date_of_Service__c, Location_Responded__c, Basic_Amount__c, Cost__c, Total_Cost_Override__c, Fixed_Wing_Helicopter__c, Site_Code__c, Facility__c, Sub_Total__c from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeName__c = 'Ambulance' LIMIT 2000];
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
                giveStatus = 'Failed';
                return giveStatus;
            }
            else{
                for(String hccId: hccIds){
                   updatedHealthcareCosts.add(new Healthcare_Cost__c(Id= hccId, Case2__c = caseId));
                }
                giveStatus = 'Passed';    
                update updatedHealthcareCosts;
                              
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