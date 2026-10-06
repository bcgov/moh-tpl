@IsTest
private class XlsxGenerationAsyncQueueableTest {

    // Creates shared Case test data used by the queueable tests.
    @TestSetup
    static void setupTestData() {
        DocxTestDataFactory.createCaseRecord();
    }

    // Returns the shared Case created by test setup.
    private static Case getTestCase() {
        return [SELECT Id FROM Case LIMIT 1];
    }

    // Creates a generation log record used by XlsxGenerationAsyncQueueable.
    private static Log__c createGenerationLog(Id caseId) {
        Log__c logRecord = new Log__c();
        logRecord.Record_Id__c = String.valueOf(caseId);
        logRecord.Running_User__c = UserInfo.getUserId();
        logRecord.Class_Name__c = TPL_Constants.CLASS_DOCX_GENERATOR_CONTROLLER;
        logRecord.Method_Name__c = TPL_Constants.METHOD_GENERATE_DOCUMENT;
        logRecord.Status__c = TPL_Constants.STATUS_PROCESSING;
        insert logRecord;
        return logRecord;
    }

    // Covers the two-argument (caseId, selectedTemplate) constructor without executing the queueable.
    @IsTest
    static void constructorWithoutLogIdCanBeCreated() {
        Case c = getTestCase();

        XlsxGenerationAsyncQueueable queueableJob = new XlsxGenerationAsyncQueueable(c.Id, 'TestTemplate');

        System.assertNotEquals(null, queueableJob, 'Queueable instance should be created using constructor without log id.');
    }

    // Covers the execute try block and verifies XLSX generation completes successfully.
    @IsTest
    static void executeCoversTryBlockAndCompletesLog() {
        Case c = getTestCase();
        Log__c logRecord = createGenerationLog(c.Id);

        Test.startTest();
        Id jobId = System.enqueueJob(new XlsxGenerationAsyncQueueable(c.Id, logRecord.Id));
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Queueable job id should be returned.');

        Log__c refreshedLog = [SELECT Id, JobId__c, Record_Id__c, Status__c, Error_Message__c, Class_Name__c, Method_Name__c FROM Log__c WHERE Id = :logRecord.Id LIMIT 1];

        System.assertEquals(String.valueOf(c.Id), refreshedLog.Record_Id__c, 'Log should remain associated to the Case.');
        System.assertNotEquals(null, refreshedLog.JobId__c, 'Queueable job id should be saved on the log.');
        System.assertEquals(TPL_Constants.STATUS_COMPLETED, refreshedLog.Status__c, 'Try block should mark the log completed.');

        List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId, ContentDocument.FileExtension FROM ContentDocumentLink WHERE LinkedEntityId = :c.Id AND ContentDocument.FileExtension = 'xlsx'];

        System.assert(!docLinks.isEmpty(), 'Try block should create and link an XLSX file to the Case.');
    }

    // Covers the execute catch block by passing an invalid Case Id while keeping a valid Log Id.
    @IsTest
    static void executeCoversCatchBlockAndMarksLogFailed() {
        Case c = getTestCase();
        Log__c logRecord = createGenerationLog(c.Id);
        Id fakeCaseId = '500000000000001AAA';

        Test.startTest();
        Id jobId = System.enqueueJob(new XlsxGenerationAsyncQueueable(fakeCaseId, logRecord.Id));
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Queueable job id should still be returned even when execution fails.');

        Log__c refreshedLog = [SELECT Id, JobId__c, Record_Id__c, Status__c, Error_Message__c, Class_Name__c, Method_Name__c FROM Log__c WHERE Id = :logRecord.Id LIMIT 1];

        System.assertNotEquals(null, refreshedLog.JobId__c, 'Failed queueable execution should still save the job id on the log.');
        System.assertNotEquals(null, refreshedLog.Error_Message__c, 'Catch block should save the exception message on the log.');
        System.assertEquals('XlsxGenerationAsyncQueueable', refreshedLog.Class_Name__c, 'Catch block should save the queueable class name.');
        System.assertEquals('execute', refreshedLog.Method_Name__c, 'Catch block should save the failed method name.');
    }
}