@IsTest
private class HealthIdeasApiCalloutBatchTest {

    private class HealthIdeasMock implements HttpCalloutMock {
        Integer statusCode;
        String statusText;
        String body;

        HealthIdeasMock(Integer statusCode, String statusText, String body) {
            this.statusCode = statusCode;
            this.statusText = statusText;
            this.body = body;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setStatus(statusText);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(body);
            return res;
        }
    }

    // Looks up the Person Account record type Id for Account.
    private static Id getIndividualRtId() {
        return [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND IsPersonType = true
            LIMIT 1
        ].Id;
    }

    // Creates a reusable test Person Account.
    private static Account createAccount() {
        Id individualRtId = getIndividualRtId();

        Account acc = new Account(
            RecordTypeId = individualRtId,
            FirstName = 'David',
            LastName = 'Scott',
            Type = 'Client',
            Date_of_Birth__pc = Date.newInstance(1996, 11, 14),
            PHN__pc = '9872626777'
        );
        insert acc;
        return acc;
    }

    // Retrieves the batch-level Log__c record for the given root batch job Id.
    private static Log__c getLog(Id rootBatchJobId) {
        return [
            SELECT Status__c, Failed_Chunks__c, Error_Message__c, Stack_Trace__c
            FROM Log__c
            WHERE JobId__c = :String.valueOf(rootBatchJobId)
            AND Running_User__c = :UserInfo.getUserId()
            LIMIT 1
        ];
    }

    // Retrieves the most recent Log__c record created inside sendHealthIdeasRequest itself,
    // which holds the real HTTP status/response detail (the batch-level log only gets the
    // generic UI message that sendHealthIdeasRequest already sanitized before returning).
    private static Log__c getSendRequestLog() {
        return [
            SELECT Error_Message__c
            FROM Log__c
            WHERE Method_Name__c = 'sendHealthIdeasRequest'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
    }

    // Covers an HTTP 500 failure from the callout: confirms the batch-level log records
    // STATUS_FAILED with 1 failed chunk and the generic UI message, while the deeper log
    // created inside sendHealthIdeasRequest still holds the real "Internal Server Error" detail.
    @IsTest
    static void testExecuteHttpFailure() {
        Account acc = createAccount();
        LogService.initializeAsyncStatus(acc.Id, 1, 'HealthIdeasApiCalloutBatch', 'execute');
        Test.setMock(HttpCalloutMock.class, new HealthIdeasMock(500, 'Internal Server Error', '{"error":"failure"}'));

        Test.startTest();
        Database.executeBatch(new HealthIdeasApiCalloutBatch(acc.Id, Date.today(), UserInfo.getUserName(), acc.Id), 1);
        Test.stopTest();

        Log__c logRec = getLog(acc.Id);
        System.assertEquals(TPL_Constants.STATUS_FAILED, logRec.Status__c);
        System.assertEquals(1, logRec.Failed_Chunks__c);
        System.assertEquals(Label.TPL_HI_Callout_Failure_Message, logRec.Error_Message__c);

        Log__c detailedLog = getSendRequestLog();
        System.assert(detailedLog.Error_Message__c.contains('Internal Server Error'));
    }

    // Covers the callout returning HTTP 200 with unparseable JSON: confirms the batch-level
    // log records STATUS_FAILED with 1 failed chunk and a populated stack trace.
    @IsTest
    static void testExecuteBadJson() {
        Account acc = createAccount();
        LogService.initializeAsyncStatus(acc.Id, 1, 'HealthIdeasApiCalloutBatch', 'execute');
        Test.setMock(HttpCalloutMock.class, new HealthIdeasMock(200, 'OK', '{bad json'));

        Test.startTest();
        Database.executeBatch(new HealthIdeasApiCalloutBatch(acc.Id, Date.today(), UserInfo.getUserName(), acc.Id), 1);
        Test.stopTest();

        Log__c logRec = getLog(acc.Id);
        System.assertEquals(TPL_Constants.STATUS_FAILED, logRec.Status__c);
        System.assertEquals(1, logRec.Failed_Chunks__c);
        System.assert(!String.isBlank(logRec.Stack_Trace__c));
    }

    // Covers the callout returning HTTP 200 with an empty payload (no msp/hospitalization/
    // pharmacare records): confirms the batch job completes successfully and exactly one
    // Log__c record was created for it.
    @IsTest
    static void testExecuteEmptyPayload() {
        Account acc = createAccount();
        LogService.initializeAsyncStatus(acc.Id, 1, 'HealthIdeasApiCalloutBatch', 'execute');
        Test.setMock(HttpCalloutMock.class, new HealthIdeasMock(200, 'OK', '{"msp":[],"hospitalizations":[],"pharmacare":[]}'));

        Test.startTest();
        Id batchJobId = Database.executeBatch(new HealthIdeasApiCalloutBatch(acc.Id, Date.today(), UserInfo.getUserName(), acc.Id), 1);
        Test.stopTest();

        AsyncApexJob job = [SELECT Status FROM AsyncApexJob WHERE Id = :batchJobId LIMIT 1];
        System.assertNotEquals(null, batchJobId);
        System.assertEquals('Completed', job.Status);
        System.assertEquals(1, [SELECT COUNT() FROM Log__c WHERE JobId__c = :String.valueOf(acc.Id)]);
    }
}