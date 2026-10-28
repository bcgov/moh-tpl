public class TPL_BatchTriggerHandler {
    public void OnBeforeDelete(List<Batch__c> oldBatchRecords)
    {
        // Create a set to hold the IDs of Batches that are being deleted
        Set<Id> batchIds = new Set<Id>();
        
        // Loop through the Batches that are attempting to be deleted and collect their IDs
        for (Batch__c batch : oldBatchRecords) {
            batchIds.add(batch.Id);
        }
        
        // Query for any related Payment records where the Batch ID is in the set of Batch IDs
        List<Payment__c> relatedPayments = [
            SELECT Id 
            FROM Payment__c 
            WHERE   Batch_Number__c IN :batchIds
        ];
        
        // If there are any related Payments, prevent deletion
        if (!relatedPayments.isEmpty()) {
            for (Batch__c batch : oldBatchRecords) {
                batch.addError(Label.TPL_Prevent_Batch_Deletion);
            }
        }
    }
}