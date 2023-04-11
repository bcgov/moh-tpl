public with sharing class HCCCostPharmacareRecord {
    private static Id getPharmacareRecordId(){
        return Schema.SObjectType.Healthcare_Cost__c.getRecordTypeInfosByName().get('Pharmacare').getRecordTypeId();
    }

    private static Integer getPharmacareCountonCase(String caseId, String filterValue, Id recordTypeId){
        String sourceSystemId = null;
        if(filterValue == Label.TPL_Manual_Records){
            return [SELECT count() from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId and Source_System_ID__c = :sourceSystemId];
        }
        else if(filterValue == Label.TPL_Records_Created_Today)
        {
            return [SELECT count() from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId and Source_System_ID__c = :sourceSystemId and CreatedDate = TODAY];
        }
        else
        {
            return [SELECT count() from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId];
        }
    }

    private static Integer getPharmacareCountonAccount(String accId, String selectedFilterValue, Id recordTypeId){
        if(selectedFilterValue == Label.TPL_All_Records)
        {
            return [SELECT count() from Healthcare_Cost__c where Account__c = :accId and RecordTypeId = :recordTypeId];            
        }
        else{
            return [SELECT count() from Healthcare_Cost__c where Account__c = :accId and RecordTypeId = :recordTypeId and Cost_Include__c = false and Cost_Review__c = false];
        }
    }


    @AuraEnabled
    public static HCCostPharmacareDetailWrapper getHealthcareCostsPharmacareForAccount(String accId, String selectedFilterValue, Integer pageNumber, Integer pageSize)
    {
        List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
        HCCostPharmacareDetailWrapper pharmacareDetailWrapper = new HCCostPharmacareDetailWrapper();
        Integer offsetSize = 0;
        Integer totalCount = 0;
        Set<Id> hccCaseId = new Set<Id>();
       
        try{
            Id recordTypeId = getPharmacareRecordId();
            totalCount = getPharmacareCountonAccount(accId, selectedFilterValue, recordTypeId);
         
            if(pageSize > = totalCount){
                offsetSize = 0;
            }
            else{
                offsetSize = (pageNumber -1) * pageSize;
            }
         
            System.debug('Page Size : ' + pageSize + ', Page Number : ' + pageNumber + ', offset Value : ' + offsetSize);
            if(selectedFilterValue == Label.TPL_All_Records){
                hccCostList = [select Case2__c, Case_Number__c, Cost_Include__c, Cost_Review__c, Name, Date_of_Service__c, Practitioner_Name__c, DIN__c, Name_of_Drug__c, Cost_of_Drug__c, Total_Cost_Override__c, Source_System_ID__c from Healthcare_Cost__c where Account__c = :accId and RecordTypeId = :recordTypeId ORDER BY Name LIMIT :pageSize OFFSET :offsetSize];
            }
            else{
                hccCostList = [select Case2__c, Case_Number__c, Cost_Include__c, Cost_Review__c, Name, Date_of_Service__c, Practitioner_Name__c, DIN__c, Name_of_Drug__c, Cost_of_Drug__c, Total_Cost_Override__c, Source_System_ID__c from Healthcare_Cost__c where Account__c = :accId and RecordTypeId = :recordTypeId and Cost_Include__c = false and Cost_Review__c = false ORDER BY Name LIMIT :pageSize OFFSET :offsetSize];
            }
            System.debug('HCC Cost List (Account Records) : ' + hccCostList.size());      
          
            pharmacareDetailWrapper.hccList = hccCostList;
            pharmacareDetailWrapper.totalCount = totalCount; 
        }
    	catch(NullPointerException nullpointer){
            System.debug(nullpointer.getMessage());
        }
        catch(DmlException dml){
            System.debug(dml.getMessage());
        }
        catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return pharmacareDetailWrapper;
    }
         
    @AuraEnabled
    public static HCCostPharmacareDetailWrapper getHealthcareCostsPharmacareForCase(String caseId, String filterValue, Integer pageSize, Integer pageNumber){
     	List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
         HCCostPharmacareDetailWrapper pharmacareDetailWrapper = new HCCostPharmacareDetailWrapper();
         String sourceSystemId = null;
         Integer totalCount = 0;
         Integer offsetSize = 0;

         try{
            Id recordTypeId = getPharmacareRecordId();
            totalCount = getPharmacareCountonCase(caseId, filterValue, recordTypeId);
            if(pageSize > = totalCount){
                offsetSize = 0;
            }
            else{
                offsetSize = (pageNumber -1) * pageSize;
            }
            if(filterValue == Label.TPL_Manual_Records)
            { 
                hccCostList = [select Case2__c,  Cost_Include__c, Cost_Review__c, Name, Date_of_Service__c, Practitioner_Name__c, DIN__c, Name_of_Drug__c, Cost_of_Drug__c, Total_Cost_Override__c, Source_System_ID__c from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId and Source_System_ID__c = :sourceSystemId ORDER BY Name LIMIT :pageSize OFFSET :offsetSize];   
            }
            else if(filterValue == Label.TPL_Records_Created_Today){
                hccCostList = [select Case2__c, Cost_Include__c, Cost_Review__c, Name, Date_of_Service__c, Practitioner_Name__c, DIN__c, Name_of_Drug__c, Cost_of_Drug__c, Total_Cost_Override__c, Source_System_ID__c from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId and Source_System_ID__c = :sourceSystemId and CreatedDate = TODAY ORDER BY CreatedDate ASC LIMIT :pageSize OFFSET :offsetSize];       
            }
            else{
                hccCostList = [select Case2__c, Cost_Include__c, Cost_Review__c, Name, Date_of_Service__c, Practitioner_Name__c, DIN__c, Name_of_Drug__c, Cost_of_Drug__c, Total_Cost_Override__c, Source_System_ID__c from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId ORDER BY Name LIMIT :pageSize OFFSET :offsetSize];   
            }
            pharmacareDetailWrapper.hccList = hccCostList;
            pharmacareDetailWrapper.totalCount = totalCount;
        }
        catch(DmlException dml){
            System.debug(dml.getMessage());
        }
        catch(NullPointerException nullpointer){
            System.debug(nullpointer.getMessage());
        }
        catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return pharmacareDetailWrapper;
    }

    @AuraEnabled
    public static HCCostAccountCaseWrapper updateHCCCaseInformation (List<Healthcare_Cost__c> hccList, String caseId, List<Healthcare_Cost__c> recordDisplay){
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
                if(hcc.Cost_Review__c == true || hcc.Cost_Include__c == true){
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
 
    public class HCCostPharmacareDetailWrapper{
        @AuraEnabled public List<Healthcare_Cost__c> hccList {get;set;}
        @AuraEnabled public Integer totalCount {get;set;}
    }
    
    public class HCCostAccountCaseWrapper{
        @AuraEnabled public String updateMessage {get;set;}
        @AuraEnabled public String passMessage {get;set;}
    }

}