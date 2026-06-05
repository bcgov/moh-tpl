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
}