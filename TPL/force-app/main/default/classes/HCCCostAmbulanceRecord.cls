public with sharing class HCCCostAmbulanceRecord {
    
    private static Id getAmbulanceRecordId(){
        return Schema.SObjectType.Healthcare_Cost__c.getRecordTypeInfosByName().get('Ambulance').getRecordTypeId();
    }

    private static Integer getTotalAmbulanceCountonAccount(String accId, String selectedFilterValue, Id recordTypeId){
        if(selectedFilterValue == Label.TPL_All_Records)
        {
          return [SELECT count() from Healthcare_Cost__c where Account__c = :accId and RecordTypeId = :recordTypeId];            
        }
        else{
          return [SELECT count() from Healthcare_Cost__c where Account__c = :accId and RecordTypeId = :recordTypeId and Cost_Include__c = false and Cost_Review__c = false];
        }
    }
    
    @AuraEnabled
    public static Integer getAmbulanceCountonCase(String caseId, String filterValue){
        String sourceSystemId = null;
        Integer countOfAmbulanceRecords = 0;
        try{
            Id recordTypeId = getAmbulanceRecordId();
            if(filterValue == Label.TPL_Manual_Records){
                countOfAmbulanceRecords = [SELECT count() from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId and Source_System_ID__c = :sourceSystemId];
            }
            else if(filterValue == Label.TPL_Records_Created_Today) {
                countOfAmbulanceRecords = [SELECT count() from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId and Source_System_ID__c = :sourceSystemId and CreatedDate = TODAY];                
            }
            else 
            {
                countOfAmbulanceRecords = [SELECT count() from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId];
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
      
        return countOfAmbulanceRecords;
    }

    @AuraEnabled
    public static List<Healthcare_Cost__c> getHealthcareCostsAmbulanceForCase(String caseId, String filterValue, Integer limitSize, Integer offsetSize){
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
    public static HCCostAmbulanceDetailWrapper getHealthcareCostsAmbulanceForAccount(String accId, String selectedFilterValue, Integer pageNumber, Integer pageSize){
        List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
        HCCostAmbulanceDetailWrapper ambulanceDetailWrapper = new HCCostAmbulanceDetailWrapper();
    
        try {
            Id recordTypeId = getAmbulanceRecordId();
            Integer offsetSize = 0;
            Integer totalCount = 0;
            System.debug('Initial Page Number : ' + pageNumber);
            totalCount = HCCCostAmbulanceRecord.getTotalAmbulanceCountonAccount(accId, selectedFilterValue, recordTypeId);
            
            if(pageSize > = totalCount){
                offsetSize = 0;
            }
            else{
                offsetSize = (pageNumber -1) * pageSize;
            }
            System.debug('Page Size : ' + pageSize + ', Page Number : ' + pageNumber + ', offset Value : ' + offsetSize);
            
            if(selectedFilterValue == Label.TPL_All_Records)
            {   
                hccCostList = [Select Id, Name, Case2__c, Case2__r.CaseNumber, Case_Number__c, Cost_Include__c, Cost_Review__c, Date_of_Service__c, Location_Responded__c, Basic_Amount__c, Cost__c, Total_Cost_Override__c, Site_Code__c, Facility__c, FacilityName__c, Fixed_Wing_Helicopter__c, Source_System_ID__c from Healthcare_Cost__c where Account__c = :accId and RecordTypeId = :recordTypeId ORDER BY Name LIMIT :pageSize OFFSET :offsetSize];
             }
            else{
                hccCostList = [Select Id, Name, Case2__c, Case2__r.CaseNumber, Case_Number__c, Cost_Include__c, Cost_Review__c,  Date_of_Service__c, Location_Responded__c, Basic_Amount__c, Cost__c, Total_Cost_Override__c, Site_Code__c, Facility__c, FacilityName__c, Fixed_Wing_Helicopter__c, Source_System_ID__c from Healthcare_Cost__c where Account__c = :accId and RecordTypeId = :recordTypeId and Cost_Include__c = false and Cost_Review__c = false ORDER BY Name LIMIT :pageSize OFFSET :offsetSize];            
            }

            System.debug('HCC Cost List Size : ' + hccCostList.size());
            ambulanceDetailWrapper.hccList = hccCostList;
            ambulanceDetailWrapper.totalCount = totalCount;
        } catch(NullPointerException nullpointer){
            System.debug(nullpointer.getMessage());
        }
        catch(DmlException dml){
            System.debug(dml.getMessage());
        }
        catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return ambulanceDetailWrapper;
    }

    @AuraEnabled
    public static HCCostAccountCaseWrapper updateHCCCaseInformation (List<Healthcare_Cost__c> hccList, String caseId,List<Healthcare_Cost__c> recordDisplay){
        String giveStatus = null;
        String passMessage = null;
        Boolean checkFail = false;
        HCCostAccountCaseWrapper hac = new HCCostAccountCaseWrapper();
        List<Healthcare_Cost__c> updateHealthCareCost = new List<Healthcare_Cost__c>();
            
        if(caseId == null || caseId.length() == 0 || hccList.size() == 0){
                passMessage = Label.TPL_Empty_Selection;
        }
        else{
            for(Healthcare_Cost__c hcc: hccList){
                if(hcc.Cost_Include__c == true || hcc.Cost_Review__c == true){
                    checkFail = true;
                    break;
                }
                else{
                    updateHealthCareCost.add(new Healthcare_Cost__c(Id = hcc.Id, Case2__c = caseId));
                    checkFail = false;
                }      
            }
            
            System.debug('Records Display Length : ' + recordDisplay.size());
            if(!checkFail){ 
                Map<Id, Integer> rowCountMap = new Map<Id, Integer>();
                Integer index = 1;
                for(Healthcare_Cost__c hcc: recordDisplay){
                    rowCountMap.put(hcc.Id, index);
                    index++;
                }   
                try{
                    Database.SaveResult[] srList = Database.update(updateHealthCareCost, false);
                    String result = '';
                    List<Integer> capturedIndex = new List<Integer>();
                    for (Database.SaveResult sr : srList){
                        if (sr.isSuccess()) {
                            capturedIndex.add(rowCountMap.get(sr.getId()));
                        }
                        else{
                            for(Database.Error err : sr.getErrors()) {
                              result += 'Row ' + rowCountMap.get(sr.getId()) + ' ' + err.getMessage() + '\n';
                            }
                           
                        }
                    }
                    if(capturedIndex.size() == updateHealthCareCost.size())
                    {
                        passMessage = Label.TPL_Passed;
                  
                    }
                    else if(capturedIndex.size()>0){
                        passMessage = 'Partial Success';
                        giveStatus = result;
                    }
                    else{
                        giveStatus = result;
                    }  
                                        
                } 
                catch(DmlException dml){
                    System.debug(dml.getMessage());
                    giveStatus = dml.getMessage();
                }
                catch(NullPointerException np){
                    System.debug(np.getMessage());
                    giveStatus = Label.TPL_Failed;
                }
            }
            else{
                passMessage = Label.TPL_Failed;
            }
            
            hac.updateMessage = giveStatus;
            hac.passMessage = passMessage;
        }
        return hac;
    }
  
    public class HCCostAmbulanceDetailWrapper{
        @AuraEnabled public List<Healthcare_Cost__c> hccList {get;set;}
        @AuraEnabled public Integer totalCount {get;set;}
    }
    
    public class HCCostAccountCaseWrapper{
        @AuraEnabled public String updateMessage {get;set;}
        @AuraEnabled public String passMessage {get;set;}
    }
}