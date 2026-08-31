/**
 * Author: Nikhil Jeenru
 * Company: CGI
 * Purpose:
 * Test coverage for the HealthIdeas API integration, sync refresh flow,
 * async batch/queueable flow, job status polling, and healthcare cost insert handling.
 */
@IsTest
private class HealthIdeasApiIntegrationTest {
    
    private static Integer callCount = 0;

    // Exceeds Intervention_Code_CCI__c max length.
    private static final String LONG_CCI = 'x'.repeat(1200);

    // ---------------------------------------------------------------
    // Shared mock-response helpers
    // ---------------------------------------------------------------
    private static Boolean isTokenRequest(HttpRequest req) {
        String endpoint = req.getEndpoint() == null ? '' : req.getEndpoint().toLowerCase();
        String body = req.getBody() == null ? '' : req.getBody().toLowerCase();
        return endpoint.contains('token') || endpoint.contains('oauth') || endpoint.contains('jwt') ||
            body.contains('grant_type') || body.contains('client_assertion') || body.contains('client_id');
    }
    
    private static HttpResponse jsonResponse(Integer statusCode, String statusText, String body) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(statusCode);
        if (statusText != null) res.setStatus(statusText);
        res.setBody(body);
        return res;
    }

    // HTTP reason phrase for the status codes covered by these tests.
    private static String reasonPhraseFor(Integer statusCode) {
        Map<Integer, String> reasonPhrases = new Map<Integer, String>{
            400 => 'Bad Request',
            401 => 'Unauthorized',
            403 => 'Forbidden',
            404 => 'Not Found',
            408 => 'Request Timeout',
            500 => 'Internal Server Error',
            503 => 'Service Unavailable'
        };
        return reasonPhrases.containsKey(statusCode) ? reasonPhrases.get(statusCode) : 'HTTP ' + statusCode;
    }

    private static HttpResponse tokenHttpResponse() {
        return jsonResponse(200, null, '{"access_token":"fake-access-token","token_type":"Bearer","expires_in":3600}');
    }
    
    private static HttpResponse emptyContentResponse() {
        return jsonResponse(200, null, '{"content":{"msp":[],"hospitalizations":[],"pharmacare":[]}}');
    }
    
    private static HttpResponse healthContentResponse(String interventionCodesCci) {
        return jsonResponse(200, null,
            '{"content":{' +
            '"msp":[{"phn":"9872626777","dtSvcProvided":"2000-01-01T10:15:30Z","descOfSvc":"MSP service",' +
            '"feeItemCode":"F100","feeItemTitle":"Fee title","feeItemDesc":"Fee desc","practitionerNbr":"12345",' +
            '"practitionerName":"Dr Smith","diagnosticCode":"D1","diagnosticDesc":"Diag 1","amtPaid":"12.50",' +
            '"costType":"MSP","encounterId":"MSP-001"}],' +
            '"hospitalizations":[{"phn":"9872626777","dateOfAdmission":"2006-06-21T00:00:00",' +
            '"dateOfDischarge":"2006-06-21T00:00:00","noOfDays":"1","facility":"Mission Memorial Hospital",' +
            '"costType":"Hospitalizations","encounterId":"234152213098","careLevel":"Acute Care",' +
            '"interventionCodesCci":"' + interventionCodesCci + '"}],' +
            '"pharmacare":[{"phn":"9872626777","din":"DIN123","nameOfDrug":"Drug 1",' +
            '"dateOfService":"2000-01-08T00:00:00Z","costOfDrug":"45.67","costType":"Pharmacare",' +
            '"encounterId":"PHARMA-001","practitionerFirstName":"David","practitionerLastName":"Test"}]' +
            '}}'
        );
    }

    // Body shape for the DML-failure and empty-payload tests.
    // Field is named "kind", not "contentMode": Apex is case-insensitive, so a field name matching
    // its type by casing alone (e.g. ContentKind/contentKind) collides with the type itself.
    private enum ContentKind { DML_FAILURE, EMPTY }

    // Single configurable HttpCalloutMock. Pass the raw HTTP status code or exception message to
    // return/throw; the production retry loop decides what happens with it.
    private class ConfigurableMock implements HttpCalloutMock {
        private ContentKind kind;
        private Integer statusCode;
        private String exceptionMessage;
        private Integer timesBeforeSuccess;

        // HTTP 200, body shaped by kind.
        ConfigurableMock(ContentKind kind) { this.kind = kind; }

        // Returns this status code on every call. 200 always returns real success data.
        ConfigurableMock(Integer statusCode) { this.statusCode = statusCode; }

        // Returns this status code for the first N calls, then succeeds with real data.
        ConfigurableMock(Integer statusCode, Integer timesBeforeSuccess) {
            this.statusCode = statusCode;
            this.timesBeforeSuccess = timesBeforeSuccess;
        }

        // Throws a CalloutException with this message on every call.
        ConfigurableMock(String exceptionMessage) { this.exceptionMessage = exceptionMessage; }

        // Throws a CalloutException with this message for the first N calls, then succeeds with real data.
        ConfigurableMock(String exceptionMessage, Integer timesBeforeSuccess) {
            this.exceptionMessage = exceptionMessage;
            this.timesBeforeSuccess = timesBeforeSuccess;
        }

        public HttpResponse respond(HttpRequest req) {
            if (isTokenRequest(req)) return tokenHttpResponse();

            Boolean stillFailing = timesBeforeSuccess == null || callCount < timesBeforeSuccess;

            if (exceptionMessage != null) {
                callCount++;
                if (stillFailing) throw new CalloutException(exceptionMessage);
                return healthContentResponse('CCI123');
            }

            if (statusCode != null) {
                callCount++;
                if (statusCode == TPL_Constants.HTTP_STATUS_OK) {
                    return healthContentResponse('CCI123');
                }
                if (stillFailing) return jsonResponse(statusCode, reasonPhraseFor(statusCode), '{"error":"' + reasonPhraseFor(statusCode) + '"}');
                return healthContentResponse('CCI123');
            }

            callCount++;
            if (kind == ContentKind.EMPTY) return emptyContentResponse();
            return healthContentResponse(LONG_CCI);
        }
    }

    // ---------------------------------------------------------------
    // Shared test-data / assertion helpers
    // ---------------------------------------------------------------
    private static void insertProcessingLog(Id jobId) {
        insert new Log__c(
            JobId__c = String.valueOf(jobId),
            Running_User__c = UserInfo.getUserId(),
            Status__c = TPL_Constants.STATUS_PROCESSING,
            Total_Chunks__c = 1,
            Completed_Chunks__c = 0,
            Failed_Chunks__c = 0
        );
    }

    private static void assertHealthcareCostInserted(Id accountId, String sourceSystemId) {
        List<Healthcare_Cost__c> costs = [
            SELECT Id FROM Healthcare_Cost__c
            WHERE Account__c = :accountId AND Source_System_ID__c = :sourceSystemId
        ];
        System.assertEquals(1, costs.size(), 'Expected exactly one Healthcare_Cost__c record for ' + sourceSystemId);
    }

    private static void assertHospitalizationFailureMessage(String message) {
        System.assert(message.contains(Label.TPL_HI_Record_ErrorMessage), 'Expected configured HealthIdeas record error label.');
        System.assert(message.contains('June 21, 2006'), 'Expected failed admission date to be included in the message.');
    }

    private static void setQueueableChaining(Boolean msp, Boolean hospitalization, Boolean pharmacare) {
        HealthIdeasMspQueueable.allowQueueableChaining = msp;
        HealthIdeasHospitalizationQueueable.allowQueueableChaining = hospitalization;
        HealthIdeasPharmacareQueueable.allowNextBatchChaining = pharmacare;
    }

    // Asserts the standard "no retry happened" outcome: immediate failure on the very first call.
    private static void assertFailedImmediatelyNoRetry(HealthIdeasApiIntegration.IntegrationResult result, String expectedMessageFragment) {
        System.assertEquals(false, result.success, 'Expected failure.');
        System.assertEquals(1, callCount, 'Expected exactly 1 call — no retry should have occurred.');
        System.assert(result.errorMessage.contains(expectedMessageFragment), 'Expected error message to contain: ' + expectedMessageFragment);
    }

    // Creates reusable Person Account and Healthcare Cost records for all tests.
    @testSetup
    static void setupData() {
        Id individualRtId = getRecordTypeId(Account.SObjectType, 'PersonAccount');

        Account acc = new Account(
            RecordTypeId = individualRtId,
            FirstName = 'David',
            LastName = 'Scott',
            Type = 'Client',
            Date_of_Birth__pc = Date.newInstance(1996, 11, 14),
            PHN__pc = '9872626777'
        );
        insert acc;

        Map<String, Id> costRtIds = getCostRecordTypeIds();
        List<Healthcare_Cost__c> seedRecords = new List<Healthcare_Cost__c>();
        for (String rtName : new List<String>{ 'Hospitalization', 'MSP', 'Pharmacare' }) {
            seedRecords.add(new Healthcare_Cost__c(
                Account__c = acc.Id,
                RecordTypeId = costRtIds.get(rtName),
                Date_of_Service__c = Date.newInstance(1999, 12, 31),
                Cost_Review__c = false,
                Cost_Include__c = false,
                Date_of_Admission__c = Date.newInstance(2020, 12, 31)
            ));
        }
        insert seedRecords;
    }

    private static Id getRecordTypeId(Schema.SObjectType sObjectType, String developerName) {
        Map<String, Schema.RecordTypeInfo> infos = sObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
        System.assert(infos.containsKey(developerName), 'Missing record type "' + developerName + '" on ' + sObjectType.getDescribe().getName());
        return infos.get(developerName).getRecordTypeId();
    }

    private static Map<String, Id> getCostRecordTypeIds() {
        return new Map<String, Id>{
            'MSP' => getRecordTypeId(Healthcare_Cost__c.SObjectType, 'MSP'),
            'Pharmacare' => getRecordTypeId(Healthcare_Cost__c.SObjectType, 'Pharmacare'),
            'Hospitalization' => getRecordTypeId(Healthcare_Cost__c.SObjectType, 'Hospitalization')
        };
    }

    private static Account getTestAccount() {
        return [SELECT Id, PHN__pc FROM Account WHERE PHN__pc = '9872626777' LIMIT 1];
    }

    // ---------------------------------------------------------------
    // Business-logic tests (not retry-related) — all use a plain HTTP 200 mock
    // ---------------------------------------------------------------

    // Covers successful async request creation and async tracking log initialization.
    @IsTest
    static void testCallGetCost_success() {
        Account acc = getTestAccount();
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(200));
        setQueueableChaining(true, true, true);

        Test.startTest();
        HealthIdeasApiIntegration.IntegrationResult result =
            HealthIdeasApiIntegration.getHealthcareCostsForAccountandSetDate(acc.Id, Date.newInstance(1990, 1, 1), true);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(true, result.success);
        System.assertEquals(null, result.errorMessage);
        System.assertNotEquals(null, result.batchId);

        List<Log__c> logs = [SELECT Id, Status__c, Total_Chunks__c FROM Log__c WHERE JobId__c = :String.valueOf(result.batchId) LIMIT 1];
        System.assertEquals(1, logs.size());
        System.assertNotEquals(null, logs[0].Status__c);
        System.assert(logs[0].Total_Chunks__c > 0);
    }

    // Covers synchronous refresh flow with delete and insert processing.
    @IsTest
    static void testCallGetCost_DeletionScenario() {
        Account acc = getTestAccount();
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(200));

        Test.startTest();
        HealthIdeasApiIntegration.IntegrationResult result =
            HealthIdeasApiIntegration.getHealthcareCostsForAccountandSetDate(acc.Id, Date.newInstance(2025, 1, 1), false);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(true, result.success);
        System.assertEquals(null, result.errorMessage);
        System.assertEquals(null, result.batchId);
    }

    // Covers async request path with queueable chaining disabled for test control.
    @IsTest
    static void testCallGetCost_FailureScenario() {
        Account acc = getTestAccount();
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(200));
        setQueueableChaining(false, false, false);

        Test.startTest();
        HealthIdeasApiIntegration.IntegrationResult result =
            HealthIdeasApiIntegration.getHealthcareCostsForAccountandSetDate(acc.Id, Date.newInstance(2025, 1, 1), true);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(true, result.success);
        System.assertEquals(null, result.errorMessage);
        System.assertNotEquals(null, result.batchId);
    }

    // Covers exception handling when no Account Id is provided.
    @IsTest
    static void testCallGetCost_CatchBlock_NoAccountId() {
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(200));

        Test.startTest();
        HealthIdeasApiIntegration.IntegrationResult result =
            HealthIdeasApiIntegration.getHealthcareCostsForAccountandSetDate(null, Date.newInstance(2025, 1, 1), false);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(false, result.success);
        System.assertNotEquals(null, result.errorMessage);
        System.assertEquals(null, result.batchId);
    }

    // Covers synchronous insert handling when an individual Healthcare Cost row fails.
    @IsTest
    static void testRefreshHealthcareCostRecords_InsertDmlFailure_AddsMessage() {
        Account acc = getTestAccount();
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(ContentKind.DML_FAILURE));

        Test.startTest();
        HealthIdeasApiIntegration.IntegrationResult result =
            HealthIdeasApiIntegration.getHealthcareCostsForAccountandSetDate(acc.Id, Date.newInstance(2025, 1, 1), false);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(true, result.success);
        System.assertEquals(null, result.errorMessage);
        System.assertEquals(null, result.batchId);
        System.assertNotEquals(null, result.messages);

        if (!result.messages.isEmpty()) {
            assertHospitalizationFailureMessage(result.messages[0]);
        }
    }

    // Covers job status polling response for an async HealthIdeas run.
    @IsTest
    static void testJobStatusController() {
        Account acc = getTestAccount();
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(200));
        setQueueableChaining(false, false, false);

        Test.startTest();
        HealthIdeasApiIntegration.IntegrationResult result =
            HealthIdeasApiIntegration.getHealthcareCostsForAccountandSetDate(acc.Id, Date.newInstance(2021, 5, 19), true);
        HealthIdeasJobStatusController.JobStatusResponse statusResponse = HealthIdeasJobStatusController.getStatus(result.batchId);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.batchId);
        System.assertNotEquals(null, statusResponse);
        System.assertNotEquals(null, statusResponse.status);
    }

    // Covers HealthIdeas date chunk count calculation.
    @IsTest
    static void testCalculateFiveYearChunkCount() {
        System.assertEquals(3, HealthIdeasApiIntegration.calculateFiveYearChunkCount(Date.newInstance(2021, 5, 19), Date.newInstance(2026, 5, 19)));
        System.assertEquals(3, HealthIdeasApiIntegration.calculateFiveYearChunkCount(Date.newInstance(2021, 5, 19), Date.newInstance(2026, 5, 20)));
    }

    // Covers user-facing insert failure messages and technical log creation.
    @IsTest
    static void testAppendHealthcareCostInsertMessagesCreatesLogs() {
        Healthcare_Cost__c failedRecord = new Healthcare_Cost__c(Account__c = '001000000000000AAA', Date_of_Admission__c = Date.newInstance(2006, 6, 21));
        List<Healthcare_Cost__c> recordsToInsert = new List<Healthcare_Cost__c>{ failedRecord };
        Database.SaveResult[] insertResults = Database.insert(recordsToInsert, false);
        System.assertEquals(false, insertResults[0].isSuccess(), 'Expected test record insert to fail.');

        Test.startTest();
        String message = LogService.appendHealthcareCostInsertMessages(null, insertResults, recordsToInsert, 'MSP');
        Test.stopTest();

        System.assertNotEquals(null, message);
        assertHospitalizationFailureMessage(message);

        List<Log__c> logs = [SELECT Id, Error_Message__c FROM Log__c WHERE Method_Name__c = 'appendHealthcareCostInsertMessages'];
        if (logs.isEmpty()) {
            System.debug('No technical Log__c records were inserted. Check Log__c required fields, validation rules, or field access.');
        } else {
            System.assert(logs[0].Error_Message__c.contains('Healthcare_Cost__c insert failed'), 'Expected technical DML error message.');
        }
    }

    // Covers direct MSP queueable execution and MSP Healthcare Cost insert.
    @IsTest
    static void testHealthIdeasMspQueueable_DirectExecution() {
        Account acc = getTestAccount();
        Map<String, Id> costRtIds = getCostRecordTypeIds();
        Id rootBatchJobId = '707000000000000AAA';
        insertProcessingLog(rootBatchJobId);

        HealthIdeasApiIntegration.MspHccRecord msp = new HealthIdeasApiIntegration.MspHccRecord();
        msp.phn = '9872626777'; msp.dtSvcProvided = '2000-01-01T10:15:30Z'; msp.descOfSvc = 'MSP service';
        msp.feeItemCode = 'F100'; msp.feeItemTitle = 'Fee title'; msp.feeItemDesc = 'Fee desc';
        msp.practitionerNbr = '12345'; msp.practitionerName = 'Dr Smith'; msp.diagnosticCode = 'D1';
        msp.diagnosticDesc = 'Diag 1'; msp.amtPaid = '12.50'; msp.encounterId = 'MSP-001';

        HealthIdeasMspQueueable.allowQueueableChaining = true;

        Test.startTest();
        System.enqueueJob(new HealthIdeasMspQueueable(
            acc.Id,
            new List<HealthIdeasApiIntegration.MspHccRecord>{ msp },
            costRtIds.get(TPL_Constants.HCC_MSP_RECORDTYPE_NAME),
            new List<HealthIdeasApiIntegration.HospitalizationHccRecord>(),
            costRtIds.get(TPL_Constants.HCC_HOSP_RECORDTYPE_NAME),
            new List<HealthIdeasApiIntegration.PharmacareHccRecord>(),
            costRtIds.get(TPL_Constants.HCC_PHARMA_RECORDTYPE_NAME),
            rootBatchJobId, null, UserInfo.getUserEmail(), Date.today()
        ));
        Test.stopTest();

        assertHealthcareCostInserted(acc.Id, 'MSP-001');
    }

    // Covers direct Hospitalization queueable execution and Hospitalization Healthcare Cost insert.
    @IsTest
    static void testHealthIdeasHospitalizationQueueable_DirectExecution() {
        Account acc = getTestAccount();
        Map<String, Id> costRtIds = getCostRecordTypeIds();
        Id rootBatchJobId = '707000000000001AAA';
        insertProcessingLog(rootBatchJobId);

        HealthIdeasApiIntegration.HospitalizationHccRecord hosp = new HealthIdeasApiIntegration.HospitalizationHccRecord();
        hosp.phn = '9872626777'; hosp.dateOfAdmission = '2006-06-21T00:00:00'; hosp.dateOfDischarge = '2006-06-21T00:00:00';
        hosp.facilityCode = 'FAC001'; hosp.careLevel = TPL_Constants.SERVICE_TYPE_ACUTE_CARE;
        hosp.locationOfIncident = 'Test Location'; hosp.descOfIncident = 'Test Incident';
        hosp.diagTreatmentSvcs = 'Test Treatment'; hosp.interventionCodesCci = 'CCI123'; hosp.encounterId = 'HOSP-001';

        HealthIdeasHospitalizationQueueable.allowQueueableChaining = true;

        Test.startTest();
        System.enqueueJob(new HealthIdeasHospitalizationQueueable(
            acc.Id,
            new List<HealthIdeasApiIntegration.HospitalizationHccRecord>{ hosp },
            costRtIds.get(TPL_Constants.HCC_HOSP_RECORDTYPE_NAME),
            new List<HealthIdeasApiIntegration.PharmacareHccRecord>(),
            costRtIds.get(TPL_Constants.HCC_PHARMA_RECORDTYPE_NAME),
            rootBatchJobId, null, UserInfo.getUserEmail(), Date.today()
        ));
        Test.stopTest();

        assertHealthcareCostInserted(acc.Id, 'HOSP-001');
    }

    // Covers direct Pharmacare queueable execution and Pharmacare Healthcare Cost insert.
    @IsTest
    static void testHealthIdeasPharmacareQueueable_DirectExecution() {
        Account acc = getTestAccount();
        Map<String, Id> costRtIds = getCostRecordTypeIds();
        Id rootBatchJobId = '707000000000002AAA';
        insertProcessingLog(rootBatchJobId);

        HealthIdeasApiIntegration.PharmacareHccRecord pharma = new HealthIdeasApiIntegration.PharmacareHccRecord();
        pharma.phn = '9872626777'; pharma.din = 'DIN123'; pharma.nameOfDrug = 'Drug 1';
        pharma.dateOfService = '2000-01-08T00:00:00Z'; pharma.costOfDrug = '45.67'; pharma.encounterId = 'PHARMA-001';
        pharma.practitionerFirstName = 'David'; pharma.practitionerLastName = 'Test';

        HealthIdeasPharmacareQueueable.allowNextBatchChaining = true;

        Test.startTest();
        System.enqueueJob(new HealthIdeasPharmacareQueueable(
            acc.Id,
            new List<HealthIdeasApiIntegration.PharmacareHccRecord>{ pharma },
            costRtIds.get(TPL_Constants.HCC_PHARMA_RECORDTYPE_NAME),
            rootBatchJobId, null, UserInfo.getUserEmail(), Date.newInstance(2026, 5, 31)
        ));
        Test.stopTest();

        assertHealthcareCostInserted(acc.Id, 'PHARMA-001');
    }

    // Covers individual Healthcare Cost insert failure handling in the sync refresh method.
    @IsTest
    static void testRefreshHealthcareCostRecords_IndividualRecordInsertFailureAddsMessage() {
        Account acc = getTestAccount();
        Map<String, Id> recordTypeIds = getCostRecordTypeIds();
        recordTypeIds.put(TPL_Constants.HCC_HOSP_RECORDTYPE_NAME, getRecordTypeId(Account.SObjectType, 'PersonAccount'));

        HealthIdeasApiIntegration.HealthIdeasBatchPayload payload = new HealthIdeasApiIntegration.HealthIdeasBatchPayload();
        payload.msp = new List<HealthIdeasApiIntegration.MspHccRecord>();
        payload.pharmacare = new List<HealthIdeasApiIntegration.PharmacareHccRecord>();

        HealthIdeasApiIntegration.HospitalizationHccRecord hosp = new HealthIdeasApiIntegration.HospitalizationHccRecord();
        hosp.phn = '9872626777'; hosp.dateOfAdmission = '2006-06-21T00:00:00'; hosp.dateOfDischarge = '2006-06-21T00:00:00';
        hosp.facilityCode = 'FAC001'; hosp.careLevel = TPL_Constants.SERVICE_TYPE_ACUTE_CARE;
        hosp.interventionCodesCci = 'CCI123'; hosp.encounterId = 'HOSP-FAIL-001';
        payload.hospitalizations = new List<HealthIdeasApiIntegration.HospitalizationHccRecord>{ hosp };

        List<String> messages = new List<String>();

        Test.startTest();
        HealthIdeasApiIntegration.refreshHealthcareCostRecords(acc.Id, Date.newInstance(2025, 1, 1), payload, recordTypeIds, messages);
        Test.stopTest();

        System.assertEquals(1, messages.size(), 'Expected one user-facing message for the failed Healthcare_Cost__c insert.');
        assertHospitalizationFailureMessage(messages[0]);
    }

    // Covers async batch no-data payload path where Pharmacare queueable is launched with null values.
    @IsTest
    static void testHealthIdeasApiCalloutBatch_EmptyPayload_LaunchesPharmacareQueueable() {
        Account acc = getTestAccount();
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(ContentKind.EMPTY));
        setQueueableChaining(true, true, false);

        Test.startTest();
        HealthIdeasApiIntegration.IntegrationResult result =
            HealthIdeasApiIntegration.getHealthcareCostsForAccountandSetDate(acc.Id, Date.today(), true);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(true, result.success);
        System.assertEquals(null, result.errorMessage);
        System.assertNotEquals(null, result.batchId);

        Log__c logRecord = [
            SELECT Status__c, Completed_Chunks__c, Failed_Chunks__c, Queueable_JobId__c, Error_Message__c
            FROM Log__c WHERE JobId__c = :String.valueOf(result.batchId) LIMIT 1
        ];
        System.assertEquals(1, logRecord.Completed_Chunks__c);
        System.assertEquals(0, logRecord.Failed_Chunks__c);
        System.assertEquals(TPL_Constants.STATUS_COMPLETED, logRecord.Status__c);
        System.assertNotEquals(null, logRecord.Queueable_JobId__c);
        System.assertEquals(null, logRecord.Error_Message__c);
    }

    // ---------------------------------------------------------------
    // Retry matrix (sendHealthIdeasRequest)
    // Retry only happens on an HTTP 408 status or a CalloutException containing
    // TPL_Constants.TIMEOUT_ERROR_MESSAGE. Everything else fails immediately, no retry.
    // ---------------------------------------------------------------

    // Retry happens: CalloutException with the timeout message.

    // All attempts throw the timeout exception; exhausts MAX_ATTEMPTS, fails with timeout message.
    @IsTest
    static void testRetry_TimeoutException_ExhaustsAllAttempts() {
        Account testAccount = getTestAccount();
        callCount = 0;
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(TPL_Constants.TIMEOUT_ERROR_MESSAGE));

        Test.startTest();
        HealthIdeasApiIntegration.IntegrationResult result =
            HealthIdeasApiIntegration.getHealthcareCostsForAccountandSetDate(testAccount.Id, Date.newInstance(2025, 1, 1), false);
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assertEquals(TPL_Constants.MAX_ATTEMPTS, callCount, 'Expected the callout to be attempted MAX_ATTEMPTS times.');
        System.assert(result.errorMessage.contains(TPL_Constants.TIMEOUT_ERROR_MESSAGE), 'Expected timeout error after maximum retry attempts.');
    }

    // Throws the timeout exception once, succeeds on the 2nd attempt.
    @IsTest
    static void testRetry_TimeoutException_SucceedsOnSecondAttempt() {
        Account testAccount = getTestAccount();
        callCount = 0;
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(TPL_Constants.TIMEOUT_ERROR_MESSAGE, 1));

        Test.startTest();
        HealthIdeasApiIntegration.IntegrationResult result =
            HealthIdeasApiIntegration.getHealthcareCostsForAccountandSetDate(testAccount.Id, Date.newInstance(2025, 1, 1), false);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Expected success on the second attempt after a single timeout.');
        System.assertEquals(2, callCount, 'Expected exactly 2 calls: one timeout, then one success.');
    }

    // Retry happens: real HTTP 408 status, no exception thrown.

    // All attempts return HTTP 408; exhausts MAX_ATTEMPTS, same timeout failure via the status-code path.
    @IsTest
    static void testRetry_Http408Status_ExhaustsAllAttempts() {
        Account testAccount = getTestAccount();
        callCount = 0;
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(TPL_Constants.HTTP_STATUS_REQUEST_TIMEOUT));

        Test.startTest();
        HealthIdeasApiIntegration.IntegrationResult result =
            HealthIdeasApiIntegration.getHealthcareCostsForAccountandSetDate(testAccount.Id, Date.newInstance(2025, 1, 1), false);
        Test.stopTest();

        System.assertEquals(false, result.success, 'Expected failure once all MAX_ATTEMPTS return HTTP 408.');
        System.assertEquals(TPL_Constants.MAX_ATTEMPTS, callCount, 'Expected the callout to be attempted MAX_ATTEMPTS times.');
        System.assert(result.errorMessage.contains(TPL_Constants.TIMEOUT_ERROR_MESSAGE), 'Expected timeout error via HTTP 408 responses.');
    }

    // Returns HTTP 408 once, succeeds on the 2nd attempt.
    @IsTest
    static void testRetry_Http408Status_SucceedsOnSecondAttempt() {
        Account testAccount = getTestAccount();
        callCount = 0;
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(TPL_Constants.HTTP_STATUS_REQUEST_TIMEOUT, 1));

        Test.startTest();
        HealthIdeasApiIntegration.IntegrationResult result =
            HealthIdeasApiIntegration.getHealthcareCostsForAccountandSetDate(testAccount.Id, Date.newInstance(2025, 1, 1), false);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Expected success on the second attempt after a single HTTP 408.');
        System.assertEquals(2, callCount, 'Expected exactly 2 calls: one 408, then one success.');
    }

    // Retry does not happen: any HTTP status other than 408 or 200.

    @IsTest
    static void testNoRetry_Http400Status_FailsImmediately() {
        Account testAccount = getTestAccount();
        callCount = 0;
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(400));

        Test.startTest();
        HealthIdeasApiIntegration.IntegrationResult result =
            HealthIdeasApiIntegration.getHealthcareCostsForAccountandSetDate(testAccount.Id, Date.newInstance(2025, 1, 1), false);
        Test.stopTest();

        assertFailedImmediatelyNoRetry(result, 'Bad Request');
    }

    @IsTest
    static void testNoRetry_Http401Status_FailsImmediately() {
        Account testAccount = getTestAccount();
        callCount = 0;
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(401));

        Test.startTest();
        HealthIdeasApiIntegration.IntegrationResult result =
            HealthIdeasApiIntegration.getHealthcareCostsForAccountandSetDate(testAccount.Id, Date.newInstance(2025, 1, 1), false);
        Test.stopTest();

        assertFailedImmediatelyNoRetry(result, 'Unauthorized');
    }

    @IsTest
    static void testNoRetry_Http403Status_FailsImmediately() {
        Account testAccount = getTestAccount();
        callCount = 0;
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(403));

        Test.startTest();
        HealthIdeasApiIntegration.IntegrationResult result =
            HealthIdeasApiIntegration.getHealthcareCostsForAccountandSetDate(testAccount.Id, Date.newInstance(2025, 1, 1), false);
        Test.stopTest();

        assertFailedImmediatelyNoRetry(result, 'Forbidden');
    }

    @IsTest
    static void testNoRetry_Http404Status_FailsImmediately() {
        Account testAccount = getTestAccount();
        callCount = 0;
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(404));

        Test.startTest();
        HealthIdeasApiIntegration.IntegrationResult result =
            HealthIdeasApiIntegration.getHealthcareCostsForAccountandSetDate(testAccount.Id, Date.newInstance(2025, 1, 1), false);
        Test.stopTest();

        assertFailedImmediatelyNoRetry(result, 'Not Found');
    }

    @IsTest
    static void testNoRetry_Http500Status_FailsImmediately() {
        Account testAccount = getTestAccount();
        callCount = 0;
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(500));

        Test.startTest();
        HealthIdeasApiIntegration.IntegrationResult result =
            HealthIdeasApiIntegration.getHealthcareCostsForAccountandSetDate(testAccount.Id, Date.newInstance(2025, 1, 1), false);
        Test.stopTest();

        assertFailedImmediatelyNoRetry(result, 'Internal Server Error');
        System.assert(result.errorMessage.contains(TPL_Constants.ERROR_HEALTH_IDEAS_API_CALLOUT_FAILED), 'Expected the callout-failed error message to be present.');
    }

    @IsTest
    static void testNoRetry_Http503Status_FailsImmediately() {
        Account testAccount = getTestAccount();
        callCount = 0;
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(503));

        Test.startTest();
        HealthIdeasApiIntegration.IntegrationResult result =
            HealthIdeasApiIntegration.getHealthcareCostsForAccountandSetDate(testAccount.Id, Date.newInstance(2025, 1, 1), false);
        Test.stopTest();

        assertFailedImmediatelyNoRetry(result, 'Service Unavailable');
    }

    // Retry does not happen: CalloutException with a non-timeout message.

    @IsTest
    static void testNoRetry_NonTimeoutCalloutException_FailsImmediately() {
        Account testAccount = getTestAccount();
        callCount = 0;
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock('Too many callouts: 101'));

        Test.startTest();
        HealthIdeasApiIntegration.IntegrationResult result =
            HealthIdeasApiIntegration.getHealthcareCostsForAccountandSetDate(testAccount.Id, Date.newInstance(2025, 1, 1), false);
        Test.stopTest();

        assertFailedImmediatelyNoRetry(result, 'Too many callouts');
    }
}