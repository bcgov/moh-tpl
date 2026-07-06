@IsTest
private class DocxGenrationStatusControllerTest {
    
    // Creates shared Case test data used by all pollDocument tests.
    @TestSetup
    static void setupTestData() {
        DocxTestDataFactory.createCaseRecord();
    }
    
    // Returns the shared Case created in test setup.
    private static Case getTestCase() {
        return [SELECT Id FROM Case LIMIT 1];
    }
    
    // Creates a test ContentDocument and returns its ContentDocumentId.
    private static Id createTestContentDocument(Id caseId, String fileName, String body) {
        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = fileName;
        cv.VersionData = Blob.valueOf(body);
        cv.FirstPublishLocationId = caseId;
        cv.SharingPrivacy = 'N';
        cv.IsMajorVersion = true;
        insert cv;
        
        return [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1].ContentDocumentId;
    }
    
    // Creates a Log__c record used by pollDocument status checks.
    private static Log__c createGenerationLog(Id caseId, String jobId, String status, String errorMessage, String generatedFileIds) {
        Log__c logRecord = new Log__c();
        logRecord.JobId__c = jobId;
        logRecord.Record_Id__c = String.valueOf(caseId);
        logRecord.Running_User__c = UserInfo.getUserId();
        logRecord.Class_Name__c = TPL_Constants.CLASS_DOCX_GENERATOR_CONTROLLER;
        logRecord.Method_Name__c = TPL_Constants.METHOD_GENERATE_DOCUMENT;
        logRecord.Status__c = status;
        logRecord.Error_Message__c = errorMessage;
        logRecord.Generated_File_Ids__c = generatedFileIds;
        insert logRecord;
        return logRecord;
    }
    
    // Covers pollDocument returning PROCESSING when no matching Log__c exists.
    @IsTest
    static void pollDocumentReturnsProcessingWhenNoLogExists() {
        Case c = getTestCase();
        
        Test.startTest();
        DocxGenrationStatusController.PollDocumentResponse result = DocxGenrationStatusController.pollDocument(c.Id, '707000000000000AAA');
        Test.stopTest();
        
        System.assertEquals(TPL_Constants.STATUS_PROCESSING, result.status, 'Polling should return PROCESSING when no generation log exists.');
        System.assertEquals(null, result.generatedFileIds, 'Generated file ids should be null when no generation log exists.');
        System.assertEquals(null, result.errorMessage, 'Error message should be null when no generation log exists.');
    }
    
    // Covers pollDocument returning PROCESSING when jobId is blank and no matching Log__c exists.
    @IsTest
    static void pollDocumentReturnsProcessingWhenJobIdIsBlankAndNoLogExists() {
        Case c = getTestCase();
        
        Test.startTest();
        DocxGenrationStatusController.PollDocumentResponse result = DocxGenrationStatusController.pollDocument(c.Id, null);
        Test.stopTest();
        
        System.assertEquals(TPL_Constants.STATUS_PROCESSING, result.status, 'Polling should return PROCESSING when job id is blank and no generation log exists.');
        System.assertEquals(null, result.generatedFileIds, 'Generated file ids should be null when job id is blank and no generation log exists.');
        System.assertEquals(null, result.errorMessage, 'Error message should be null when job id is blank and no generation log exists.');
    }
    
    // Covers pollDocument returning COMPLETED when completed log contains a ready document id.
    @IsTest
    static void pollDocumentReturnsFileIdsWhenCompletedDocumentIsReady() {
        Case c = getTestCase();
        Id contentDocumentId = createTestContentDocument(c.Id, 'CompletedDoc.docx', 'completed document body');
        createGenerationLog(c.Id, '707000000000001AAA', TPL_Constants.STATUS_COMPLETED, null, String.valueOf(contentDocumentId));
        
        Test.startTest();
        DocxGenrationStatusController.PollDocumentResponse result = DocxGenrationStatusController.pollDocument(c.Id, '707000000000001AAA');
        Test.stopTest();
        
        System.assertEquals(TPL_Constants.STATUS_COMPLETED, result.status, 'Polling should return COMPLETED when generated document is ready.');
        System.assertEquals(String.valueOf(contentDocumentId), result.generatedFileIds, 'Polling should return the completed ContentDocumentId.');
        System.assertEquals(null, result.errorMessage, 'Error message should be null for completed polling result.');
    }
    
    // Covers pollDocument completed status returning PROCESSING when completed log has no file ids.
    @IsTest
    static void pollDocumentReturnsProcessingWhenCompletedLogHasBlankFileIds() {
        Case c = getTestCase();
        createGenerationLog(c.Id, '707000000000002AAA', TPL_Constants.STATUS_COMPLETED, null, null);
        
        Test.startTest();
        DocxGenrationStatusController.PollDocumentResponse result = DocxGenrationStatusController.pollDocument(c.Id, '707000000000002AAA');
        Test.stopTest();
        
        System.assertEquals(TPL_Constants.STATUS_PROCESSING, result.status, 'Polling should return PROCESSING when completed log does not contain file ids.');
        System.assertEquals(null, result.generatedFileIds, 'Generated file ids should be null when completed log has blank file ids.');
        System.assertEquals(null, result.errorMessage, 'Error message should be null when completed log has blank file ids.');
    }
    
    // Covers contentDocumentsReady returning false through pollDocument when file id text is invalid.
    @IsTest
    static void pollDocumentReturnsProcessingWhenCompletedLogHasInvalidFileIds() {
        Case c = getTestCase();
        createGenerationLog(c.Id, '707000000000003AAA', TPL_Constants.STATUS_COMPLETED, null, 'not-a-valid-content-document-id');
        
        Test.startTest();
        DocxGenrationStatusController.PollDocumentResponse result = DocxGenrationStatusController.pollDocument(c.Id, '707000000000003AAA');
        Test.stopTest();
        
        System.assertEquals(TPL_Constants.STATUS_PROCESSING, result.status, 'Polling should return PROCESSING when completed log contains invalid file ids.');
        System.assertEquals(null, result.generatedFileIds, 'Generated file ids should be null when completed log contains invalid file ids.');
        System.assertEquals(null, result.errorMessage, 'Error message should be null when completed log contains invalid file ids.');
    }
    
    // Covers contentDocumentsReady returning false through pollDocument when ContentDocument does not exist.
    @IsTest
    static void pollDocumentReturnsProcessingWhenCompletedLogHasMissingContentDocument() {
        Case c = getTestCase();
        createGenerationLog(c.Id, '707000000000004AAA', TPL_Constants.STATUS_COMPLETED, null, '069000000000001AAA');
        
        Test.startTest();
        DocxGenrationStatusController.PollDocumentResponse result = DocxGenrationStatusController.pollDocument(c.Id, '707000000000004AAA');
        Test.stopTest();
        
        System.assertEquals(TPL_Constants.STATUS_PROCESSING, result.status, 'Polling should return PROCESSING when the ContentDocumentId in the log is not ready or does not exist.');
        System.assertEquals(null, result.generatedFileIds, 'Generated file ids should be null when ContentDocument does not exist.');
        System.assertEquals(null, result.errorMessage, 'Error message should be null when ContentDocument does not exist.');
    }
    
    // Covers pollDocument fallback query by Case when provided jobId does not match a Log__c record.
    @IsTest
    static void pollDocumentFallsBackToLatestCaseLogWhenJobIdDoesNotMatch() {
        Case c = getTestCase();
        Id contentDocumentId = createTestContentDocument(c.Id, 'FallbackDoc.docx', 'fallback document body');
        createGenerationLog(c.Id, '707000000000005AAA', TPL_Constants.STATUS_COMPLETED, null, String.valueOf(contentDocumentId));
        
        Test.startTest();
        DocxGenrationStatusController.PollDocumentResponse result = DocxGenrationStatusController.pollDocument(c.Id, '707000000000999AAA');
        Test.stopTest();
        
        System.assertEquals(TPL_Constants.STATUS_COMPLETED, result.status, 'Polling should fall back to the latest matching Case log when job id does not match.');
        System.assertEquals(String.valueOf(contentDocumentId), result.generatedFileIds, 'Polling should return generated file ids from the fallback Case log.');
        System.assertEquals(null, result.errorMessage, 'Error message should be null for completed fallback result.');
    }
    
    // Covers pollDocument querying by Case when jobId is blank and returning completed file ids.
    @IsTest
    static void pollDocumentUsesCaseLogWhenJobIdIsBlank() {
        Case c = getTestCase();
        Id contentDocumentId = createTestContentDocument(c.Id, 'BlankJobDoc.docx', 'blank job document body');
        createGenerationLog(c.Id, null, TPL_Constants.STATUS_COMPLETED, null, String.valueOf(contentDocumentId));
        
        Test.startTest();
        DocxGenrationStatusController.PollDocumentResponse result = DocxGenrationStatusController.pollDocument(c.Id, '');
        Test.stopTest();
        
        System.assertEquals(TPL_Constants.STATUS_COMPLETED, result.status, 'Polling should use the latest matching Case log when job id is blank.');
        System.assertEquals(String.valueOf(contentDocumentId), result.generatedFileIds, 'Polling should return generated file ids when job id is blank.');
        System.assertEquals(null, result.errorMessage, 'Error message should be null when polling completes successfully with blank job id.');
    }
    
    // Covers pollDocument returning PROCESSING when log status is still processing and job has not failed.
    @IsTest
    static void pollDocumentReturnsProcessingWhenLogIsStillProcessing() {
        Case c = getTestCase();
        createGenerationLog(c.Id, null, TPL_Constants.STATUS_PROCESSING, null, null);
        
        Test.startTest();
        DocxGenrationStatusController.PollDocumentResponse result = DocxGenrationStatusController.pollDocument(c.Id, null);
        Test.stopTest();
        
        System.assertEquals(TPL_Constants.STATUS_PROCESSING, result.status, 'Polling should return PROCESSING while the generation log is still processing.');
        System.assertEquals(null, result.generatedFileIds, 'Generated file ids should be null while the generation log is still processing.');
        System.assertEquals(null, result.errorMessage, 'Error message should be null while the generation log is still processing.');
    }
    
    // Covers pollDocument jobId branch and AsyncApexJob lookup path when status is still processing.
    @IsTest
    static void pollDocumentReturnsProcessingForProcessingLogWithRealJobId() {
        Case c = getTestCase();
        Log__c logRecord = createGenerationLog(c.Id, null, TPL_Constants.STATUS_PROCESSING, null, null);
        
        Test.startTest();
        Id jobId = System.enqueueJob(new NoOpQueueable());
        Test.stopTest();
        
        logRecord.JobId__c = String.valueOf(jobId);
        update logRecord;
        
        DocxGenrationStatusController.PollDocumentResponse result = DocxGenrationStatusController.pollDocument(c.Id, String.valueOf(jobId));
        
        System.assertEquals(TPL_Constants.STATUS_PROCESSING, result.status, 'Polling should return PROCESSING when the log is processing and the async job is not failed or aborted.');
        System.assertEquals(null, result.generatedFileIds, 'Generated file ids should be null when the async job is still processing.');
        System.assertEquals(null, result.errorMessage, 'Error message should be null when the async job is still processing.');
    }
    
    // Covers pollDocument returning FAILED when Log__c status is FAILED with a custom error message.
    @IsTest
    static void pollDocumentReturnsFailedWhenLogStatusFailedWithMessage() {
        Case c = getTestCase();
        createGenerationLog(c.Id, '707000000000006AAA', TPL_Constants.STATUS_FAILED, 'Generated document failed.', null);
        
        Test.startTest();
        DocxGenrationStatusController.PollDocumentResponse result = DocxGenrationStatusController.pollDocument(c.Id, '707000000000006AAA');
        Test.stopTest();
        
        System.assertEquals(TPL_Constants.STATUS_FAILED, result.status, 'Polling should return FAILED when the generation log failed.');
        System.assertEquals(null, result.generatedFileIds, 'Generated file ids should be null when the generation log failed.');
        System.assertEquals('Generated document failed.', result.errorMessage, 'Polling should return the custom failure message.');
    }
    
    // Covers pollDocument returning FAILED when Log__c status is FAILED without a custom error message.
    @IsTest
    static void pollDocumentReturnsFailedWhenLogStatusFailedWithoutMessage() {
        Case c = getTestCase();
        createGenerationLog(c.Id, '707000000000007AAA', TPL_Constants.STATUS_FAILED, null, null);
        
        Test.startTest();
        DocxGenrationStatusController.PollDocumentResponse result = DocxGenrationStatusController.pollDocument(c.Id, '707000000000007AAA');
        Test.stopTest();
        
        System.assertEquals(TPL_Constants.STATUS_FAILED, result.status, 'Polling should return FAILED when the generation log failed without an error message.');
        System.assertEquals(null, result.generatedFileIds, 'Generated file ids should be null when the generation log failed without an error message.');
        System.assertEquals(System.Label.TPL_DocGen_Status_Failed, result.errorMessage, 'Polling should return the default failed message when no custom error message exists.');
    }
    
    // Covers AsyncApexJob failed-status branch using TestVisible override and verifies the log is updated to FAILED.
    @IsTest
    static void pollDocumentReturnsFailedWhenAsyncJobStatusFailed() {
        Case c = getTestCase();
        Log__c logRecord = createGenerationLog(c.Id, '707000000000008AAA', TPL_Constants.STATUS_PROCESSING, null, '069000000000001AAA');
        
        DocxGenrationStatusController.testAsyncJobStatus = TPL_Constants.ASYNC_JOB_STATUS_FAILED;
        DocxGenrationStatusController.testAsyncJobExtendedStatus = 'Async job failed from test.';
        
        Test.startTest();
        DocxGenrationStatusController.PollDocumentResponse result = DocxGenrationStatusController.pollDocument(c.Id, '707000000000008AAA');
        Test.stopTest();
        
        System.assertEquals(TPL_Constants.STATUS_FAILED, result.status, 'Polling should return FAILED when async job status is failed.');
        System.assertEquals(null, result.generatedFileIds, 'Generated file ids should be null when async job failed.');
        System.assertEquals('Async job failed from test.', result.errorMessage, 'Polling should return the async job extended status message.');
        
        Log__c refreshedLog = [SELECT Id, Status__c, Error_Message__c, Generated_File_Ids__c FROM Log__c WHERE Id = :logRecord.Id LIMIT 1];
        
        System.assertEquals(TPL_Constants.STATUS_FAILED, refreshedLog.Status__c, 'Log should be updated to FAILED when async job failed.');
        System.assertEquals('Async job failed from test.', refreshedLog.Error_Message__c, 'Log should store the async failure message.');
        System.assertEquals(null, refreshedLog.Generated_File_Ids__c, 'Generated file ids should be cleared when async job failed.');
        
        DocxGenrationStatusController.testAsyncJobStatus = null;
        DocxGenrationStatusController.testAsyncJobExtendedStatus = null;
    }
    
    // Covers AsyncApexJob aborted-status branch using TestVisible override and default failure message.
    @IsTest
    static void pollDocumentReturnsFailedWhenAsyncJobStatusAbortedWithoutExtendedStatus() {
        Case c = getTestCase();
        Log__c logRecord = createGenerationLog(c.Id, '707000000000009AAA', TPL_Constants.STATUS_PROCESSING, null, '069000000000001AAA');
        
        DocxGenrationStatusController.testAsyncJobStatus = TPL_Constants.ASYNC_JOB_STATUS_ABORTED;
        DocxGenrationStatusController.testAsyncJobExtendedStatus = null;
        
        Test.startTest();
        DocxGenrationStatusController.PollDocumentResponse result = DocxGenrationStatusController.pollDocument(c.Id, '707000000000009AAA');
        Test.stopTest();
        
        System.assertEquals(TPL_Constants.STATUS_FAILED, result.status, 'Polling should return FAILED when async job status is aborted.');
        System.assertEquals(null, result.generatedFileIds, 'Generated file ids should be null when async job aborted.');
        System.assertEquals(System.Label.TPL_DocGen_Status_Failed, result.errorMessage, 'Polling should return default failure message when async job extended status is blank.');
        
        Log__c refreshedLog = [SELECT Id, Status__c, Error_Message__c, Generated_File_Ids__c FROM Log__c WHERE Id = :logRecord.Id LIMIT 1];
        
        System.assertEquals(TPL_Constants.STATUS_FAILED, refreshedLog.Status__c, 'Log should be updated to FAILED when async job aborted.');
        System.assertEquals(System.Label.TPL_DocGen_Status_Failed, refreshedLog.Error_Message__c, 'Log should store default failure message when extended status is blank.');
        System.assertEquals(null, refreshedLog.Generated_File_Ids__c, 'Generated file ids should be cleared when async job aborted.');
        
        DocxGenrationStatusController.testAsyncJobStatus = null;
        DocxGenrationStatusController.testAsyncJobExtendedStatus = null;
    }
    
    // Covers a harmless Queueable used only to create a real AsyncApexJob id for polling.
    private class NoOpQueueable implements Queueable {
        public void execute(QueueableContext context) {
        }
    }
}