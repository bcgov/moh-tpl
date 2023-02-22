public with sharing class HCCCostController {

    @AuraEnabled
    public static String saveDraftValues(Object data) {
        String result = null;
        List<Healthcare_Cost__c> listOfHealthcareCost = (List<Healthcare_Cost__c>) JSON.deserialize(
            JSON.serialize(data),
            List<Healthcare_Cost__c>.class
        );
        System.debug('List size to update cases : ' + listOfHealthcareCost);
        if(listOfHealthcareCost.size() > 0)
        {
            update listOfHealthcareCost;
            result = Label.Passed;
        }
        else{
            result = Label.Failed;
        }
        return result;
    }
    
}