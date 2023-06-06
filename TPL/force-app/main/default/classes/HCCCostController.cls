public with sharing class HCCCostController {

    @AuraEnabled
    public static CaseListWrapper saveDraftValues(Object data , List<Healthcare_Cost__c> recordDisplay,String recordType ) {
        String result = '';
        String passedResult = '';
        List<Healthcare_Cost__c> listOfHealthcareCost = (List<Healthcare_Cost__c>) JSON.deserialize(
            JSON.serialize(data),
            List<Healthcare_Cost__c>.class
        );
     
        CaseListWrapper caseListWrapper = new CaseListWrapper();
        Map<Id, Integer> rowCountMap = new Map<Id,Integer>();
        Map<Id,Healthcare_Cost__c> healthCareMap = new Map<Id,Healthcare_Cost__c>();
        Integer index = 1;
        for(Healthcare_Cost__c hcc: recordDisplay){
            rowCountMap.put(hcc.Id, index);
            healthCareMap.put(hcc.Id,hcc);
            index++;
        }   

        if(listOfHealthcareCost.size() > 0)
        {   
            Database.SaveResult[] srList = Database.update(listOfHealthcareCost, false);
            List<Integer> capturehccIds = new List<Integer>();
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
            String fields = '';
            if(recordType == 'Ambulance'){
                fields = Label.TPL_Ambulance_Fields;
            }
            else if(recordType == 'MSP'){
                fields = Label.TPL_MSP_Fields;
            }
            else if(recordType == 'Hospitalization'){
                fields = Label.TPL_Hospitalization_Fields;
            }
            else if(recordType == 'Pharmacare')
            {
                fields = Label.TPL_Pharmacare_Fields;
            }
            else if(recordType == 'Continuing Care')
            {
                fields = Label.TPL_Continuing_Care_Fields;
            }
            else if(recordType == 'Future Care'){
                fields = Label.TPL_Future_Care_Fields;
            }
            
            caseListWrapper.actionMessage = result;
            caseListWrapper.indexNumbers = capturedIndex;
            String query =  'SELECT ' + fields + ' FROM Healthcare_Cost__c WHERE ID IN:recordDisplay ';
            
           List<Healthcare_Cost__c> updatedRecords = database.query(query);
            if(capturedIndex.size() == listOfHealthcareCost.size()){
                caseListWrapper.passedResult = Label.TPL_Passed;
                caseListWrapper.updatedRecords = updatedRecords;
            }
            else if(capturedIndex.size() > 0){
                caseListWrapper.passedResult = Label.TPL_Partial_Success;
                caseListWrapper.updatedRecords = updatedRecords;
            }
            else if(capturedIndex.size() == 0){
                caseListWrapper.passedResult = Label.TPL_Failed;
                caseListWrapper.updatedRecords = updatedRecords;
            }
            
        }
        else{
            caseListWrapper.passedResult = Label.TPL_Failed;
        }
        return caseListWrapper;
    }

    public static List<Case> getCaseNumber(Set<Id> caseId){
        List<Case> caseList = new List<Case>();
        try {
            caseList = [Select CaseNumber,Id from Case where Id IN :caseId];
        } catch (DmlException dml) {
            System.debug(dml.getMessage());
        }
        return caseList;
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
                        passMessage = Label.TPL_Partial_Success;
                        giveStatus = result;
                    }
                    else{
                        giveStatus = result;
                    }  
                                        
                } 
                catch(DmlException dml){
                    giveStatus = dml.getMessage();
                }
                catch(NullPointerException np){
                    giveStatus = np.getMessage();
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

    @AuraEnabled
    public static String deleteHCCRecord(List<Healthcare_Cost__c> deletionRecords, String filterOption){
        String result = null;
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
            result = Label.TPL_Insufficient_Privileges;
        }
        catch(ListException le){
            result = Label.TPL_Insufficient_Privileges;
        }
        return result; 
    }
    public class tempClass{
        public string Id;
        public string siteCode;
    }
    @AuraEnabled
    public static List<Account> getFacilityBySiteCode(Object siteCodeIds){
        
        try {
            List<tempClass> contactsForUpdate = (List<tempClass>) JSON.deserialize(
         JSON.serialize(siteCodeIds),
         List<tempClass>.class
        );
        Map<String,List<String>> helathCareMap = new Map<String,List<String>>();
            for(tempClass obj:contactsForUpdate){
                List<String> tempStringList = new List<String>();
                if(helathCareMap.containsKey(obj.siteCode)){
                    tempStringList.addAll(helathCareMap.get(obj.siteCode));
                    tempStringList.add(obj.Id);
                    helathCareMap.put(obj.siteCode,tempStringList);
                }
                else{
                    tempStringList.add(obj.Id);
                    helathCareMap.put(obj.siteCode,tempStringList);
                }
            }
        
            List<Healthcare_Cost__c> hccUpdate = new List<Healthcare_Cost__c>();
            List<Account> accList = [select id,name,Site_Code__c from account where Site_Code__c IN:helathCareMap.keySet()  LIMIT 1];
            for(Account a : accList){
                for(String id : helathCareMap.get(a.Site_Code__c)){
                    Healthcare_Cost__c hcc = new Healthcare_Cost__c();
                    hcc.id = id;
                    hcc.Facility__c = a.id;
                    hccUpdate.add(hcc);
                }
            }
            update hccUpdate;
            return accList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static void updateAll(String caseId,Boolean costReview, Boolean costInclude){
        List<Healthcare_Cost__c> hccList = [select id,case2__c from Healthcare_Cost__c where case2__c  =: caseId FOR UPDATE];
        for(Healthcare_Cost__c hcc : hccList){
            hcc.Cost_Include__c = costInclude;
            hcc.Cost_Review__c = costReview;
        }
        System.enqueueJob(new AccountQueueable(hccList));
    }
    
    public class CaseListWrapper{
       @AuraEnabled public String actionMessage {get;set;}
       @AuraEnabled public String passedResult {get;set;}
       @AuraEnabled public List<Integer> indexNumbers {get;set;}
       @AuraEnabled public List<Healthcare_Cost__c> updatedRecords{get;set;}
    }
      
    public class HCCostAccountCaseWrapper{
        @AuraEnabled public String updateMessage {get;set;}
        @AuraEnabled public String passMessage {get;set;}
    }
}