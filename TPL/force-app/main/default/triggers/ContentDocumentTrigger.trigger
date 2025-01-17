trigger ContentDocumentTrigger on ContentDocument (before delete) {
    if(Trigger.isBefore && Trigger.isDelete){
        TPLContentDocumentTriggerHandler.preventDeletion(Trigger.old);
    }
}