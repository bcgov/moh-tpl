public with sharing class HCCCostController {

    @AuraEnabled
    public static CaseListWrapper saveDraftValues(Object data , List<Healthcare_Cost__c> recordDisplay ) {
        String result = '';
        String passedResult = '';
        List<Healthcare_Cost__c> listOfHealthcareCost = (List<Healthcare_Cost__c>) JSON.deserialize(
            JSON.serialize(data),
            List<Healthcare_Cost__c>.class
        );
     
        CaseListWrapper caseListWrapper = new CaseListWrapper();
        Map<Id, Integer> rowCountMap = new Map<Id,Integer>();
        Integer index = 1;
        for(Healthcare_Cost__c hcc: recordDisplay){
            rowCountMap.put(hcc.Id, index);
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
            caseListWrapper.actionMessage = result;
            caseListWrapper.indexNumbers = capturedIndex;

            if(capturedIndex.size() == listOfHealthcareCost.size()){
                caseListWrapper.passedResult = Label.TPL_Passed;
            }
            else if(capturedIndex.size() > 0){
                caseListWrapper.passedResult = Label.TPL_Partial_Success;
            }
            else if(capturedIndex.size() == 0){
                caseListWrapper.passedResult = Label.TPL_Failed;
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

    public class CaseListWrapper{
       @AuraEnabled public String actionMessage {get;set;}
       @AuraEnabled public String passedResult {get;set;}
       @AuraEnabled public List<Integer> indexNumbers {get;set;}
    }
      
    public class HCCostAccountCaseWrapper{
        @AuraEnabled public String updateMessage {get;set;}
        @AuraEnabled public String passMessage {get;set;}
    }
}