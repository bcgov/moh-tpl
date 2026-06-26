/**
 * Author: CGI
 * Purpose: Test coverage for HealthIdeasJobStatusController.
 */
@IsTest
private class HealthIdeasJobStatusControllerTest {

    private static Id insertFakeJobId() {
        Account acc = new Account(Name = 'JobStatus Test ' + String.valueOf(DateTime.now().getTime()));
        insert acc;
        return acc.Id;
    }

    private static Log__c buildLog(Id batchId, String status, Integer totalChunks, Integer completedChunks, Integer failedChunks, String errorMessage) {
        return new Log__c(
            JobId__c        = String.valueOf(batchId),
            Running_User__c = UserInfo.getUserId(),
            Status__c       = status,
            Total_Chunks__c    = totalChunks,
            Completed_Chunks__c = completedChunks,
            Failed_Chunks__c   = failedChunks,
            Error_Message__c   = errorMessage
        );
    }

    @IsTest
    static void testGetStatus_NullBatchId_ReturnsNotStarted() {
        Test.startTest();
        HealthIdeasJobStatusController.JobStatusResponse response =
            HealthIdeasJobStatusController.getStatus(null);
        Test.stopTest();

        System.assertEquals(TPL_Constants.ASYNC_STATUS_NOT_STARTED, response.status,
            'Null batchId should return NOT_STARTED status');
        System.assertEquals(0, response.totalChunks);
        System.assertEquals(0, response.completedChunks);
        System.assertEquals(0, response.failedChunks);
        System.assertEquals(false, response.isDone);
    }

    @IsTest
    static void testGetStatus_NoLogFound_ReturnsStarting() {
        Id batchId = insertFakeJobId();

        Test.startTest();
        HealthIdeasJobStatusController.JobStatusResponse response =
            HealthIdeasJobStatusController.getStatus(batchId);
        Test.stopTest();

        System.assertEquals(TPL_Constants.ASYNC_STATUS_STARTING, response.status,
            'Non-null batchId with no log should return STARTING status');
        System.assertEquals(0, response.totalChunks);
        System.assertEquals(0, response.completedChunks);
        System.assertEquals(0, response.failedChunks);
        System.assertEquals(false, response.isDone);
    }

    @IsTest
    static void testGetStatus_Processing_IsNotDone() {
        Id batchId = insertFakeJobId();
        insert buildLog(batchId, TPL_Constants.STATUS_PROCESSING, 5, 2, 0, null);

        Test.startTest();
        HealthIdeasJobStatusController.JobStatusResponse response =
            HealthIdeasJobStatusController.getStatus(batchId);
        Test.stopTest();

        System.assertEquals(TPL_Constants.STATUS_PROCESSING, response.status);
        System.assertEquals(5, response.totalChunks);
        System.assertEquals(2, response.completedChunks);
        System.assertEquals(0, response.failedChunks);
        System.assertEquals(false, response.isDone);
    }

    @IsTest
    static void testGetStatus_Completed_IsDone() {
        Id batchId = insertFakeJobId();
        insert buildLog(batchId, TPL_Constants.STATUS_COMPLETED, 3, 3, 0, null);

        Test.startTest();
        HealthIdeasJobStatusController.JobStatusResponse response =
            HealthIdeasJobStatusController.getStatus(batchId);
        Test.stopTest();

        System.assertEquals(TPL_Constants.STATUS_COMPLETED, response.status);
        System.assertEquals(true, response.isDone);
        System.assertEquals(3, response.totalChunks);
        System.assertEquals(3, response.completedChunks);
    }

    @IsTest
    static void testGetStatus_CompletedWithErrors_IsDone() {
        Id batchId = insertFakeJobId();
        insert buildLog(batchId, TPL_Constants.STATUS_COMPLETED_WITH_ERRORS, 4, 3, 1, 'Some errors occurred');

        Test.startTest();
        HealthIdeasJobStatusController.JobStatusResponse response =
            HealthIdeasJobStatusController.getStatus(batchId);
        Test.stopTest();

        System.assertEquals(TPL_Constants.STATUS_COMPLETED_WITH_ERRORS, response.status);
        System.assertEquals(true, response.isDone);
        System.assertEquals(1, response.failedChunks);
        System.assertEquals('Some errors occurred', response.errorMessage);
    }

    @IsTest
    static void testGetStatus_Failed_IsDone() {
        Id batchId = insertFakeJobId();
        insert buildLog(batchId, TPL_Constants.STATUS_FAILED, 1, 0, 1, 'Fatal failure');

        Test.startTest();
        HealthIdeasJobStatusController.JobStatusResponse response =
            HealthIdeasJobStatusController.getStatus(batchId);
        Test.stopTest();

        System.assertEquals(TPL_Constants.STATUS_FAILED, response.status);
        System.assertEquals(true, response.isDone);
        System.assertEquals('Fatal failure', response.errorMessage);
    }

    @IsTest
    static void testGetStatus_NullChunkFields_DefaultToZero() {
        Id batchId = insertFakeJobId();
        insert new Log__c(
            JobId__c        = String.valueOf(batchId),
            Running_User__c = UserInfo.getUserId(),
            Status__c       = TPL_Constants.STATUS_PROCESSING
        );

        Test.startTest();
        HealthIdeasJobStatusController.JobStatusResponse response =
            HealthIdeasJobStatusController.getStatus(batchId);
        Test.stopTest();

        System.assertEquals(0, response.totalChunks,    'Null Total_Chunks__c should default to 0');
        System.assertEquals(0, response.completedChunks, 'Null Completed_Chunks__c should default to 0');
        System.assertEquals(0, response.failedChunks,    'Null Failed_Chunks__c should default to 0');
    }

    @IsTest
    static void testGetStatus_QueueableJobId_IsReturned() {
        Id batchId = insertFakeJobId();
        Log__c log = buildLog(batchId, TPL_Constants.STATUS_PROCESSING, 1, 0, 0, null);
        log.Queueable_JobId__c = '7073i000000XXXAAAA';
        insert log;

        Test.startTest();
        HealthIdeasJobStatusController.JobStatusResponse response =
            HealthIdeasJobStatusController.getStatus(batchId);
        Test.stopTest();

        System.assertEquals('7073i000000XXXAAAA', response.queueableJobId);
    }
}