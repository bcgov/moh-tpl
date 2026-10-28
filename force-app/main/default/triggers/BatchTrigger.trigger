trigger BatchTrigger on Batch__c (before delete) {
    TPL_BatchTriggerHandler batchHandler = new TPL_BatchTriggerHandler();
    if (Trigger.isBefore) {
        if (Trigger.isDelete){
            batchHandler.OnBeforeDelete(Trigger.old);
        }
    }
}