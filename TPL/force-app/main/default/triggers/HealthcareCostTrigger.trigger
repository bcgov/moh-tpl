trigger HealthcareCostTrigger on Healthcare_Cost__c (after insert,after update, after delete) {
    if(Trigger.isAfter){
        if(Trigger.isInsert || Trigger.isUpdate ){
            if(HealthcareCostTriggerHandler.isFirstTime){
                HealthcareCostTriggerHandler.isFirstTime = false;
                System.debug('Inside trigger '+trigger.new);
                HealthcareCostTriggerHandler.updateRollup(Trigger.new);
                HealthcareCostTriggerHandler.populateDateId(Trigger.new);
            }
            
        }
    }
    if(Trigger.isAfter && Trigger.isDelete){
        if(HealthcareCostTriggerHandler.isFirstTime){
            HealthcareCostTriggerHandler.isFirstTime = false;  
            HealthcareCostTriggerHandler.updateRollup(Trigger.old);
        }
    }

}