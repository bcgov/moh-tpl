@isTest
public class TPL_BatchTriggerHandlerTest {
   @testSetup
    static void setupTestData() {
        //Create Individual Account
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        //Create Case
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;
        
        // Create a sample Batch record
        Batch__c batchRec = TestDataFactory.newBatch();
        insert batchRec;
        
        // Create a related Payment record referencing the Batch
        Payment__c payment = TestDataFactory.newPayments(c.Id, 1000, 'Wire Transfer', batchRec.Id);
        insert payment;
    }
    
    @isTest
    static void testOnBeforeDeleteWithRelatedPayments() {
        // Retrieve the Batch record created in the test setup
        Batch__c batchToDelete = [SELECT Id FROM Batch__c LIMIT 1];
        
        // Try to delete the Batch record and catch the expected exception
        try {
            delete batchToDelete;
            System.assert(false, 'Expected a DMLException due to related Payment records.');
        } catch (DmlException e) {
            // Verify that the error message matches the custom label
            System.assert(e.getMessage().contains(Label.TPL_Prevent_Batch_Deletion), 
                          'Unexpected error message: ' + e.getMessage());
        }
    }
    
    @isTest
    static void testOnBeforeDeleteWithoutRelatedPayments() {
        // Create a new Batch record with no related Payment records
        Batch__c batchWithoutPayments = new Batch__c(Batch_Status__c = 'Open', Batch_Type__c = 'Private',Batch_Date__c = System.now());
        insert batchWithoutPayments;
        
        // Try deleting the Batch without related Payment records
        Test.startTest();
        delete batchWithoutPayments;
        Test.stopTest();
        
        // Assert that the record was deleted successfully
        List<Batch__c> deletedBatch = [SELECT Id FROM Batch__c WHERE Id = :batchWithoutPayments.Id];
        System.assertEquals(0, deletedBatch.size(), 'The batch should have been deleted successfully.');
    }
}