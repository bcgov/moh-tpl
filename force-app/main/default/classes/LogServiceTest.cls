/**
* Author: Nikhil Jeenru
* Company: CGI
* Purpose:
* Test coverage for the LogService helper methods used in the HealthIdeas async refresh flow,
* including status tracking, error handling, and log persistence.
*/
@IsTest
private class LogServiceTest {
    
    @testSetup
    static void setupData() {
        insert new List<Account>{
            new Account(Name = 'LogService Test Account 1'),
                new Account(Name = 'LogService Test Account 2'),
                new Account(Name = 'LogService Test Account 3')
                };
                    }
    
    private static List<Account> getAccounts() {
        return [
            SELECT Id
            FROM Account
            ORDER BY CreatedDate
        ];
    }
    
    private static Id getAccountId(Integer index) {
        return getAccounts()[index].Id;
    }
    
    private static String uniqueKey(String prefix) {
        return prefix + '-' + String.valueOf(DateTime.now().getTime());
    }
    
    private static Log__c getLog(Id rootBatchJobId) {
        return [
            SELECT Id,
            JobId__c,
            Queueable_JobId__c,
            Running_User__c,
            Status__c,
            Total_Chunks__c,
            Completed_Chunks__c,
            Failed_Chunks__c,
            Error_Message__c,
            Stack_Trace__c,
            Class_Name__c,
            Method_Name__c,
            Record_Id__c
            FROM Log__c
            WHERE JobId__c = :String.valueOf(rootBatchJobId)
            AND Running_User__c = :UserInfo.getUserId()
            LIMIT 1
        ];
    }
    
    @IsTest
    static void testAppendMessage() {
        String longMsg = '';
        for (Integer i = 0; i < 4000; i++) {
            longMsg += '1234567890';
        }
        
        System.assertEquals('new', LogService.appendMessage(null, 'new'));
        System.assertEquals('existing', LogService.appendMessage('existing', null));
        System.assertEquals(32767, LogService.appendMessage(null, longMsg).length());
    }
    
    @IsTest
    static void testBuildLog() {
        Id accountId = getAccountId(0);
        Log__c logRec = LogService.buildLog('TestClass', 'testMethod', 'boom', accountId);
        
        System.assertEquals('TestClass', logRec.Class_Name__c);
        System.assertEquals('testMethod', logRec.Method_Name__c);
        System.assertEquals(UserInfo.getUserId(), logRec.Running_User__c);
    }
    
    @IsTest
    static void testInitializeAsyncStatus() {
        Id rootBatchId = getAccountId(0);
        LogService.initializeAsyncStatus(rootBatchId, 2, 'InitClass', 'initMethod');
        
        Log__c logRec = getLog(rootBatchId);
        
        System.assertEquals(TPL_Constants.STATUS_PROCESSING, logRec.Status__c);
        System.assertEquals(2, logRec.Total_Chunks__c);
        System.assertEquals(0, logRec.Failed_Chunks__c);
    }
    
    @IsTest
    static void testAppendAndUpdateAsyncStatus() {
        Id rootBatchId = getAccountId(1);
        LogService.initializeAsyncStatus(rootBatchId, 1, 'AppendClass', 'appendMethod');
        
        LogService.appendAsyncError(rootBatchId, 'first error');
        LogService.updateAsyncStatus(rootBatchId, TPL_Constants.STATUS_FAILED);
        
        Log__c logRec = getLog(rootBatchId);
        
        System.assertEquals('first error', logRec.Error_Message__c);
        System.assertEquals(TPL_Constants.STATUS_FAILED, logRec.Status__c);
        System.assertEquals(true, LogService.isAsyncFailed(rootBatchId));
    }
    
    @IsTest
    static void testMarkChunkFinished() {
        Id rootBatchId = getAccountId(2);
        LogService.initializeAsyncStatus(rootBatchId, 2, 'FinishClass', 'finishMethod');
        
        LogService.markChunkFinished(rootBatchId, UserInfo.getUserId(), 'chunk warning');
        LogService.markChunkFinished(rootBatchId, null, null);
        
        Log__c logRec = getLog(rootBatchId);
        
        System.assertEquals(2, logRec.Completed_Chunks__c);
        System.assertEquals(TPL_Constants.STATUS_COMPLETED_WITH_ERRORS, logRec.Status__c);
        System.assert(logRec.Error_Message__c.contains('chunk warning'));
    }
    
    @IsTest
    static void testMarkChunkFailed() {
        Id rootBatchId = getAccountId(0);
        LogService.initializeAsyncStatus(rootBatchId, 1, 'FailClass', 'failMethod');
        
        LogService.markChunkFailed(
            rootBatchId,
            UserInfo.getUserId(),
            'failed message',
            'stack trace text',
            'HealthIdeasApiCalloutBatch',
            'execute'
        );
        
        Log__c logRec = getLog(rootBatchId);
        
        System.assertEquals(TPL_Constants.STATUS_FAILED, logRec.Status__c);
        System.assertEquals(1, logRec.Failed_Chunks__c);
        System.assertEquals('HealthIdeasApiCalloutBatch', logRec.Class_Name__c);
    }
    
    @IsTest
    static void testSystemModeHelpers() {
        Id accountId = getAccountId(1);
        
        Log__c insertCandidate = LogService.buildLog(
            'InsertClass',
            'insertMethod',
            'insert message',
            accountId
        );
        insertCandidate.JobId__c = uniqueKey('JOB-A');
        
        Database.SaveResult[] insertResults =
            LogService.upsertLogsInSystemModeWithReturnValue(
                new List<SObject>{ insertCandidate }
            );
        
        Log__c directInsertCandidate = LogService.buildLog(
            'DirectInsertClass',
            'directInsertMethod',
            'direct insert message',
            accountId
        );
        directInsertCandidate.JobId__c = uniqueKey('JOB-B');
        LogService.insertLogsInSystemMode(new List<SObject>{ directInsertCandidate });
        
        Log__c upsertCandidate = LogService.buildLog(
            'UpsertClass',
            'upsertMethod',
            'upsert message',
            accountId
        );
        upsertCandidate.JobId__c = uniqueKey('JOB-C');
        LogService.upsertLogsInSystemMode(new List<SObject>{ upsertCandidate });
        
        upsertCandidate.Error_Message__c = 'updated message';
        LogService.updateLogsInSystemMode(new List<SObject>{ upsertCandidate });
        
        Log__c queriedInsert = [
            SELECT Error_Message__c
            FROM Log__c
            WHERE JobId__c = :directInsertCandidate.JobId__c
            LIMIT 1
        ];
        
        Log__c queriedUpsert = [
            SELECT Error_Message__c
            FROM Log__c
            WHERE JobId__c = :upsertCandidate.JobId__c
            LIMIT 1
        ];
        
        System.assertEquals(true, insertResults[0].isSuccess());
        System.assertEquals(1, [SELECT COUNT() FROM Log__c WHERE JobId__c = :directInsertCandidate.JobId__c]);
        System.assertEquals('updated message', queriedUpsert.Error_Message__c);
    }
    
    @IsTest
    static void testHealthcareInsertMessagesAndLogErrors() {
        LogService.logErrors(null);
        
        Healthcare_Cost__c badCost = new Healthcare_Cost__c();
        badCost.Account__c = (Id)'001000000000000AAA';
        badCost.Date_of_Service__c = Date.today();
        
        Database.SaveResult[] results =
            Database.insert(new List<Healthcare_Cost__c>{ badCost }, false);
        
        Test.startTest();
        String result = LogService.appendHealthcareCostInsertMessages(
            'base message',
            results,
            new List<Healthcare_Cost__c>{ badCost },
            'MSP'
        );
        Test.stopTest();
        
        System.assertNotEquals('base message', result);
        System.assert(result.contains('MSP'));
        System.assert(!String.isBlank(result));
    }
    
    @IsTest
    static void testLogExtendedStatus() {
        Id rootBatchId = getAccountId(0);
        LogService.initializeAsyncStatus(rootBatchId, 1, 'RootClass', 'rootMethod');
        
        Log__c batchLog = LogService.buildLog(
            'BatchClass',
            'batchMethod',
            'batch message',
            rootBatchId
        );
        batchLog.JobId__c = uniqueKey('JOB-BATCH');
        
        Id batchJobId;
        Test.startTest();
        batchJobId = Database.executeBatch(
            new LogInsertBatch(new List<Log__c>{ batchLog }),
            1
        );
        Test.stopTest();
        
        LogService.logExtendedStatus(batchJobId, rootBatchId);
        
        AsyncApexJob job = [
            SELECT Status
            FROM AsyncApexJob
            WHERE Id = :batchJobId
            LIMIT 1
        ];
        
        Log__c rootLog = getLog(rootBatchId);
        
        System.assertNotEquals(null, batchJobId);
        System.assertEquals('Completed', job.Status);
        System.assertEquals(TPL_Constants.STATUS_PROCESSING, rootLog.Status__c);
    }
    
    @IsTest
    static void testBuildAndWriteGenerationLog() {
        Id caseId = getAccountId(0);
        String jobId = uniqueKey('DOCX-JOB');
        
        Log__c builtLog = LogService.buildGenerationLog(
            caseId,
            jobId,
            TPL_Constants.STATUS_PROCESSING,
            'generation started'
        );
        
        System.assertEquals(jobId, builtLog.JobId__c);
        System.assertEquals(String.valueOf(caseId), builtLog.Record_Id__c);
        System.assertEquals(UserInfo.getUserId(), builtLog.Running_User__c);
        System.assertEquals(TPL_Constants.CLASS_DOCX_GENERATOR_CONTROLLER, builtLog.Class_Name__c);
        System.assertEquals(TPL_Constants.METHOD_GENERATE_DOCUMENT, builtLog.Method_Name__c);
        System.assertEquals(TPL_Constants.STATUS_PROCESSING, builtLog.Status__c);
        System.assertEquals('generation started', builtLog.Error_Message__c);
        
        LogService.writeGenerationLog(
            caseId,
            jobId,
            TPL_Constants.STATUS_PROCESSING,
            'generation started'
        );
        
        Log__c insertedLog = [
            SELECT Id,
            JobId__c,
            Record_Id__c,
            Running_User__c,
            Class_Name__c,
            Method_Name__c,
            Status__c,
            Error_Message__c
            FROM Log__c
            WHERE JobId__c = :jobId
            LIMIT 1
        ];
        
        System.assertEquals(String.valueOf(caseId), insertedLog.Record_Id__c);
        System.assertEquals(TPL_Constants.STATUS_PROCESSING, insertedLog.Status__c);
        System.assertEquals('generation started', insertedLog.Error_Message__c);
    }
    
    @IsTest
    static void testGetGenerationLogById() {
        Id caseId = getAccountId(0);
        String jobId = uniqueKey('DOCX-GET');
        
        LogService.writeGenerationLog(
            caseId,
            jobId,
            TPL_Constants.STATUS_PROCESSING,
            'get by id message'
        );
        
        Log__c insertedLog = [
            SELECT Id
            FROM Log__c
            WHERE JobId__c = :jobId
            LIMIT 1
        ];
        
        Log__c foundLog = LogService.getGenerationLogById(insertedLog.Id);
        
        System.assertEquals(null, LogService.getGenerationLogById(null));
        System.assertNotEquals(null, foundLog);
        System.assertEquals(insertedLog.Id, foundLog.Id);
        System.assertEquals(jobId, foundLog.JobId__c);
        System.assertEquals(String.valueOf(caseId), foundLog.Record_Id__c);
    }
    
    @IsTest
    static void testGetLatestGenerationLogReturnsLatestAndFallback() {
        Id caseId = getAccountId(1);
        
        Log__c fallbackLog = LogService.getLatestGenerationLog(caseId);
        
        System.assertEquals(String.valueOf(caseId), fallbackLog.Record_Id__c);
        System.assertEquals(UserInfo.getUserId(), fallbackLog.Running_User__c);
        System.assertEquals(TPL_Constants.CLASS_DOCX_GENERATOR_CONTROLLER, fallbackLog.Class_Name__c);
        System.assertEquals(TPL_Constants.METHOD_GENERATE_DOCUMENT, fallbackLog.Method_Name__c);
        
        String oldJobId = uniqueKey('DOCX-OLD');
        
        LogService.writeGenerationLog(
            caseId,
            oldJobId,
            TPL_Constants.STATUS_PROCESSING,
            'old message'
        );
        
        Log__c latestLog = LogService.getLatestGenerationLog(caseId);
        
        System.assertEquals(oldJobId, latestLog.JobId__c);
        System.assertEquals(TPL_Constants.STATUS_PROCESSING, latestLog.Status__c);
        System.assertEquals('old message', latestLog.Error_Message__c);
    }
    
    @IsTest
    static void testUpdateGenerationLog() {
        Id caseId = getAccountId(1);
        String originalJobId = uniqueKey('DOCX-UPD-A');
        
        LogService.writeGenerationLog(
            caseId,
            originalJobId,
            TPL_Constants.STATUS_PROCESSING,
            'original message'
        );
        
        Log__c logRec = [
            SELECT Id,
            JobId__c,
            Record_Id__c,
            Running_User__c,
            Class_Name__c,
            Method_Name__c,
            Status__c,
            Error_Message__c
            FROM Log__c
            WHERE JobId__c = :originalJobId
            LIMIT 1
        ];
        
        String updatedJobId = uniqueKey('DOCX-UPD-B');
        
        LogService.updateGenerationLog(
            logRec,
            updatedJobId,
            TPL_Constants.STATUS_COMPLETED,
            'updated message'
        );
        
        LogService.updateGenerationLog(null, updatedJobId, TPL_Constants.STATUS_FAILED, 'ignored');
        
        Log__c updatedLog = [
            SELECT JobId__c,
            Status__c,
            Error_Message__c
            FROM Log__c
            WHERE Id = :logRec.Id
            LIMIT 1
        ];
        
        System.assertEquals(updatedJobId, updatedLog.JobId__c);
        System.assertEquals(TPL_Constants.STATUS_COMPLETED, updatedLog.Status__c);
        System.assertEquals('updated message', updatedLog.Error_Message__c);
    }
    
    @IsTest
    static void testMarkDocxGenerationProcessingById() {
        Id caseId = getAccountId(2);
        String jobId = uniqueKey('DOCX-PROC-A');
        
        LogService.writeGenerationLog(
            caseId,
            jobId,
            TPL_Constants.STATUS_FAILED,
            'existing message'
        );
        
        Log__c insertedLog = [
            SELECT Id
            FROM Log__c
            WHERE JobId__c = :jobId
            LIMIT 1
        ];
        
        String processingJobId = uniqueKey('DOCX-PROC-B');
        
        LogService.markDocxGenerationProcessingById(insertedLog.Id, processingJobId);
        LogService.markDocxGenerationProcessingById(null, processingJobId);
        
        Log__c processedLog = [
            SELECT JobId__c,
            Status__c,
            Error_Message__c
            FROM Log__c
            WHERE Id = :insertedLog.Id
            LIMIT 1
        ];
        
        System.assertEquals(processingJobId, processedLog.JobId__c);
        System.assertEquals(TPL_Constants.STATUS_PROCESSING, processedLog.Status__c);
        System.assertEquals('existing message', processedLog.Error_Message__c);
    }
    
    @IsTest
    static void testMarkDocxGenerationCompletedById() {
        Id caseId = getAccountId(2);
        String jobId = uniqueKey('DOCX-COMP-A');
        
        LogService.writeGenerationLog(
            caseId,
            jobId,
            TPL_Constants.STATUS_PROCESSING,
            'message before complete'
        );
        
        Log__c insertedLog = [
            SELECT Id
            FROM Log__c
            WHERE JobId__c = :jobId
            LIMIT 1
        ];
        
        String completedJobId = uniqueKey('DOCX-COMP-B');
        String contentDocumentId = '069000000000001AAA';
        
        LogService.markDocxGenerationCompletedById(
            insertedLog.Id,
            completedJobId,
            contentDocumentId
        );
        
        LogService.markDocxGenerationCompletedById(null, completedJobId, contentDocumentId);
        
        Log__c completedLog = [
            SELECT JobId__c,
            Status__c,
            Error_Message__c
            FROM Log__c
            WHERE Id = :insertedLog.Id
            LIMIT 1
        ];
        
        System.assertEquals(completedJobId, completedLog.JobId__c);
        System.assertEquals(TPL_Constants.STATUS_COMPLETED, completedLog.Status__c);
        System.assertEquals(null, completedLog.Error_Message__c);
    }
    
    @IsTest
    static void testMarkLatestDocxGenerationCompleted() {
        Id caseId = getAccountId(0);
        String jobId = uniqueKey('DOCX-LATEST-COMP');
        
        LogService.writeGenerationLog(
            caseId,
            jobId,
            TPL_Constants.STATUS_PROCESSING,
            'latest before complete'
        );
        
        List<Id> contentDocumentIds = new List<Id>{
            (Id)'069000000000001AAA',
                (Id)'069000000000002AAA'
                };
                    
                    LogService.markLatestDocxGenerationCompleted(caseId, contentDocumentIds);
        
        Log__c completedLog = [
            SELECT Status__c,
            Error_Message__c
            FROM Log__c
            WHERE JobId__c = :jobId
            LIMIT 1
        ];
        
        System.assertEquals(TPL_Constants.STATUS_COMPLETED, completedLog.Status__c);
        System.assertEquals(null, completedLog.Error_Message__c);
    }
    
    @IsTest
    static void testMarkDocxGenerationFailedWithExistingLog() {
        Id caseId = getAccountId(1);
        String jobId = uniqueKey('DOCX-FAIL-A');
        
        LogService.writeGenerationLog(
            caseId,
            jobId,
            TPL_Constants.STATUS_PROCESSING,
            'before failure'
        );
        
        Log__c insertedLog = [
            SELECT Id
            FROM Log__c
            WHERE JobId__c = :jobId
            LIMIT 1
        ];
        
        String failedJobId = uniqueKey('DOCX-FAIL-B');
        
        LogService.markDocxGenerationFailed(
            insertedLog.Id,
            caseId,
            failedJobId,
            'friendly error',
            'stack trace value',
            'FailureClass',
            'failureMethod'
        );
        
        Log__c failedLog = [
            SELECT JobId__c,
            Record_Id__c,
            Status__c,
            Error_Message__c,
            Stack_Trace__c,
            Class_Name__c,
            Method_Name__c
            FROM Log__c
            WHERE Id = :insertedLog.Id
            LIMIT 1
        ];
        
        System.assertEquals(failedJobId, failedLog.JobId__c);
        System.assertEquals(String.valueOf(caseId), failedLog.Record_Id__c);
        System.assertEquals(TPL_Constants.STATUS_FAILED, failedLog.Status__c);
        System.assertEquals('friendly error', failedLog.Error_Message__c);
        System.assertEquals('stack trace value', failedLog.Stack_Trace__c);
        System.assertEquals('FailureClass', failedLog.Class_Name__c);
        System.assertEquals('failureMethod', failedLog.Method_Name__c);
    }
    
    @IsTest
    static void testMarkDocxGenerationFailedCreatesLogWhenIdNull() {
        Id caseId = getAccountId(2);
        String jobId = uniqueKey('DOCX-FAIL-CREATE');
        
        LogService.markDocxGenerationFailed(
            null,
            caseId,
            jobId,
            'created failure',
            'created stack',
            'CreatedFailureClass',
            'createdFailureMethod'
        );
        
        Log__c createdLog = [
            SELECT JobId__c,
            Record_Id__c,
            Running_User__c,
            Status__c,
            Error_Message__c,
            Stack_Trace__c,
            Class_Name__c,
            Method_Name__c
            FROM Log__c
            WHERE JobId__c = :jobId
            LIMIT 1
        ];
        
        System.assertEquals(String.valueOf(caseId), createdLog.Record_Id__c);
        System.assertEquals(UserInfo.getUserId(), createdLog.Running_User__c);
        System.assertEquals(TPL_Constants.STATUS_FAILED, createdLog.Status__c);
        System.assertEquals('created failure', createdLog.Error_Message__c);
        System.assertEquals('created stack', createdLog.Stack_Trace__c);
        System.assertEquals('CreatedFailureClass', createdLog.Class_Name__c);
        System.assertEquals('createdFailureMethod', createdLog.Method_Name__c);
    }
    
    @IsTest
    static void testMarkLatestDocxGenerationFailed() {
        Id caseId = getAccountId(0);
        String jobId = uniqueKey('DOCX-LATEST-FAIL-A');
        
        LogService.writeGenerationLog(
            caseId,
            jobId,
            TPL_Constants.STATUS_PROCESSING,
            'before latest failure'
        );
        
        String failedJobId = uniqueKey('DOCX-LATEST-FAIL-B');
        
        LogService.markLatestDocxGenerationFailed(
            caseId,
            failedJobId,
            'latest friendly error',
            'latest stack trace',
            'LatestFailureClass',
            'latestFailureMethod'
        );
        
        Log__c failedLog = [
            SELECT JobId__c,
            Record_Id__c,
            Status__c,
            Error_Message__c,
            Stack_Trace__c,
            Class_Name__c,
            Method_Name__c
            FROM Log__c
            WHERE JobId__c = :failedJobId
            LIMIT 1
        ];
        
        System.assertEquals(String.valueOf(caseId), failedLog.Record_Id__c);
        System.assertEquals(TPL_Constants.STATUS_FAILED, failedLog.Status__c);
        System.assertEquals('latest friendly error', failedLog.Error_Message__c);
        System.assertEquals('latest stack trace', failedLog.Stack_Trace__c);
        System.assertEquals('LatestFailureClass', failedLog.Class_Name__c);
        System.assertEquals('latestFailureMethod', failedLog.Method_Name__c);
    }
}