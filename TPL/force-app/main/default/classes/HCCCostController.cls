public with sharing class HCCCostController {

    @AuraEnabled
    public static CaseListWrapper saveDraftValues(Object data , List<Healthcare_Cost__c> recordDisplay ) {
        String result = '';
        String passedResult = '';
        List<Healthcare_Cost__c> listOfHealthcareCost = (List<Healthcare_Cost__c>) JSON.deserialize(
            JSON.serialize(data),
            List<Healthcare_Cost__c>.class
        );
        System.debug('List size to update cases : ' + listOfHealthcareCost);
        CaseListWrapper caseListWrapper = new CaseListWrapper();
        Map<Id, Integer> rowCountMap = new Map<Id,Integer>();
      //  List<Healthcare_Cost__c> updatedHCost = new List<Healthcare_Cost__c>();
        Integer index = 1;
        for(Healthcare_Cost__c hcc: recordDisplay){
            rowCountMap.put(hcc.Id, index);
           // updatedHCost.add(hcc);
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
                caseListWrapper.passedResult = 'Partial Success';
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
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        return caseList;
    }

    public class CaseListWrapper{
       @AuraEnabled public String actionMessage {get;set;}
       @AuraEnabled public String passedResult {get;set;}
       @AuraEnabled public List<Integer> indexNumbers {get;set;}
    }
    
}