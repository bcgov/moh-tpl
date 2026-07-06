@IsTest
private class DocxGenerationAsyncQueueableTest {
    
    private static final String TEMPLATE_MINISTERS_CERT = System.Label.TPL_DocGen_Template_Ministers_Cert;
    
    // Creates shared Case test data used by the queueable tests.
    @TestSetup
    static void setupTestData() {
        DocxTestDataFactory.createCaseRecord();
    }
    
    // Returns the shared Case created by test setup.
    private static Case getTestCase() {
        return [SELECT Id FROM Case LIMIT 1];
    }
    
    // Creates a generation log record used by DocxGenerationAsyncQueueable.
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
    
    // Covers the two-argument constructor without executing the queueable.
    @IsTest
    static void constructorWithoutLogIdCanBeCreated() {
        Case c = getTestCase();
        
        DocxGenerationAsyncQueueable queueableJob = new DocxGenerationAsyncQueueable(c.Id, TEMPLATE_MINISTERS_CERT);
        
        System.assertNotEquals(null, queueableJob, 'Queueable instance should be created using constructor without log id.');
    }
    
    // Covers the execute try block and verifies DOCX generation completes successfully.
    @IsTest
    static void executeCoversTryBlockAndCompletesLog() {
        Case c = getTestCase();
        Log__c logRecord = createGenerationLog(c.Id);
        
        Test.startTest();
        Id jobId = System.enqueueJob(new DocxGenerationAsyncQueueable(c.Id, TEMPLATE_MINISTERS_CERT, logRecord.Id));
        Test.stopTest();
        
        System.assertNotEquals(null, jobId, 'Queueable job id should be returned.');
        
        Log__c refreshedLog = [SELECT Id, JobId__c, Record_Id__c, Status__c, Error_Message__c, Class_Name__c, Method_Name__c FROM Log__c WHERE Id = :logRecord.Id LIMIT 1];
        
        System.assertEquals(String.valueOf(c.Id), refreshedLog.Record_Id__c, 'Log should remain associated to the Case.');
        System.assertNotEquals(null, refreshedLog.JobId__c, 'Queueable job id should be saved on the log.');
        
        List<ContentDocumentLink> docLinks = [SELECT ContentDocumentId, ContentDocument.FileExtension FROM ContentDocumentLink WHERE LinkedEntityId = :c.Id AND ContentDocument.FileExtension = 'docx'];
        
        System.assert(!docLinks.isEmpty(), 'Try block should create and link a DOCX file to the Case.');
    }
    
    // Covers the execute catch block by passing an invalid Case Id while keeping a valid Log Id.
    @IsTest
    static void executeCoversCatchBlockAndMarksLogFailed() {
        Case c = getTestCase();
        Log__c logRecord = createGenerationLog(c.Id);
        Id fakeCaseId = '500000000000001AAA';
        
        Test.startTest();
        Id jobId = System.enqueueJob(new DocxGenerationAsyncQueueable(fakeCaseId, TEMPLATE_MINISTERS_CERT, logRecord.Id));
        Test.stopTest();
        
        System.assertNotEquals(null, jobId, 'Queueable job id should still be returned even when execution fails.');
        
        Log__c refreshedLog = [SELECT Id, JobId__c, Record_Id__c, Status__c, Error_Message__c, Class_Name__c, Method_Name__c FROM Log__c WHERE Id = :logRecord.Id LIMIT 1];
        
        System.assertNotEquals(null, refreshedLog.JobId__c, 'Failed queueable execution should still save the job id on the log.');
        System.assertNotEquals(null, refreshedLog.Error_Message__c, 'Catch block should save the exception message on the log.');
        System.assertEquals('DocxGenerationAsyncQueueable', refreshedLog.Class_Name__c, 'Catch block should save the queueable class name.');
        System.assertEquals('execute', refreshedLog.Method_Name__c, 'Catch block should save the failed method name.');
    }
}