public with sharing class HCCCostAmbulanceRecord {
    
    private static Id getAmbulanceRecordId(){
        return Schema.SObjectType.Healthcare_Cost__c.getRecordTypeInfosByName().get('Ambulance').getRecordTypeId();
    }

    @AuraEnabled
    public static Integer getAmbulanceCountonCase(String caseId, String filterValue){
        Integer countAmbulanceCase = 0;
        try {
            Id recordTypeId = getAmbulanceRecordId();
            String sourceSystemId = null;
            if(filterValue == Label.TPL_Manual_Records){
                countAmbulanceCase = [SELECT count() from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId and Source_System_ID__c = :sourceSystemId];
            }
            else if(filterValue == Label.TPL_Records_Created_Today) {
                countAmbulanceCase = [SELECT count() from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId and Source_System_ID__c = :sourceSystemId and CreatedDate = TODAY];                
               
            }
            else {
                countAmbulanceCase = [SELECT count() from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId];
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        System.debug('Count of Ambulance records on Case  : ' + countAmbulanceCase);
        return countAmbulanceCase;
    }
    @AuraEnabled
    public static List<Healthcare_Cost__c>  getHealthcareCostsAmbulanceForCase(String caseId, String filterValue, Integer offsetSize, Integer limitSize){
        List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
        try {
            Id recordTypeId = getAmbulanceRecordId();
            String sourceSystemId = null;
            if(filterValue == Label.TPL_Manual_Records)
            {
                hccCostList = [select Id,Cost_Include__c, Cost_Review__c, Name, Date_of_Service__c, Location_Responded__c, Basic_Amount__c, Cost__c, Total_Cost_Override__c, Fixed_Wing_Helicopter__c, Site_Code__c, Facility__c, FacilityName__c, Sub_Total__c, Source_System_ID__c from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId and Source_System_ID__c = :sourceSystemId ORDER BY Name LIMIT :limitSize OFFSET :offsetSize ];

            }
            else if(filterValue == Label.TPL_Records_Created_Today){
                hccCostList = [select Id,Cost_Include__c, Cost_Review__c, Name, Date_of_Service__c, Location_Responded__c, Basic_Amount__c, Cost__c, 
                Total_Cost_Override__c, Fixed_Wing_Helicopter__c, Site_Code__c, Facility__c, FacilityName__c, Sub_Total__c, Source_System_ID__c, CreatedDate from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId and Source_System_ID__c = :sourceSystemId and CreatedDate = TODAY ORDER BY CreatedDate ASC LIMIT :limitSize OFFSET :offsetSize];
            }
            else{
                hccCostList = [select Id,Cost_Include__c, Cost_Review__c, Name, Date_of_Service__c, Location_Responded__c, Basic_Amount__c, Cost__c, 
                Total_Cost_Override__c, Fixed_Wing_Helicopter__c, Site_Code__c, Facility__c, FacilityName__c, Sub_Total__c, Source_System_ID__c from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId ORDER BY Name LIMIT :limitSize OFFSET :offsetSize];
            }
            
        } catch(NullPointerException nullpointer){
            nullpointer.getMessage();
        }
        catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return hccCostList;
    }
    
    @AuraEnabled
    public static String deleteAmbulanceRecords(List<Healthcare_Cost__c> deletionRecords, String filterOption){
        String result = null;
        System.debug('Deletion Records Size : ' + deletionRecords.size());
        try {
            if(deletionRecords.size() == 0 || deletionRecords == null || (filterOption != Label.TPL_Manual_Records && filterOption != Label.TPL_Records_Created_Today))
            {
                result = Label.TPL_Failed;
            }
            else{
                for(Healthcare_Cost__c hcc: deletionRecords){
                    if(hcc.Source_System_ID__c != null){
                        result = Label.TPL_Failed;
                        return result;
                    }
                }
                delete deletionRecords;
                result = Label.TPL_Passed;
            }
        } catch (DMLException dml) {
            System.debug(dml.getMessage());
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return result; 
    }
}