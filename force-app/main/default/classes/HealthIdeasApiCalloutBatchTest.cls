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

    private static Id getIndividualRtId() {
        return [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND IsPersonType = true
            LIMIT 1
        ].Id;
    }

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

    private static Log__c getLog(Id rootBatchJobId) {
        return [
            SELECT Status__c, Failed_Chunks__c, Error_Message__c, Stack_Trace__c
            FROM Log__c
            WHERE JobId__c = :String.valueOf(rootBatchJobId)
            AND Running_User__c = :UserInfo.getUserId()
            LIMIT 1
        ];
    }

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
        System.assert(logRec.Error_Message__c.contains('Internal Server Error'));
    }

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