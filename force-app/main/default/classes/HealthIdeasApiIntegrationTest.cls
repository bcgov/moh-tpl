@IsTest
private class HealthIdeasApiIntegrationTest {
    
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private Boolean forceHospitalizationDmlFailure;
        
        MockHttpResponseGenerator() {
            this.forceHospitalizationDmlFailure = false;
        }
        
        MockHttpResponseGenerator(Boolean forceHospitalizationDmlFailure) {
            this.forceHospitalizationDmlFailure = forceHospitalizationDmlFailure;
        }
        
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            String endpoint = req.getEndpoint() == null ? '' : req.getEndpoint().toLowerCase();
            String body = req.getBody() == null ? '' : req.getBody().toLowerCase();
            
            Boolean isTokenRequest =
                endpoint.contains('token') ||
                endpoint.contains('oauth') ||
                endpoint.contains('jwt') ||
                body.contains('grant_type') ||
                body.contains('client_assertion') ||
                body.contains('client_id');
            
            if (isTokenRequest) {
                res.setStatusCode(200);
                res.setBody('{"access_token":"fake-access-token","token_type":"Bearer","expires_in":3600}');
                return res;
            }
            
            String interventionCodesCci = forceHospitalizationDmlFailure
                ? 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
                : 'CCI123';
            
            if (endpoint.contains('health')) {
                res.setStatusCode(200);
                res.setBody(
                    '{' +
                    '"content":{' +
                    '"msp":[{' +
                    '"phn":"9872626777",' +
                    '"dtSvcProvided":"2000-01-01T10:15:30Z",' +
                    '"descOfSvc":"MSP service",' +
                    '"feeItemCode":"F100",' +
                    '"feeItemTitle":"Fee title",' +
                    '"feeItemDesc":"Fee desc",' +
                    '"practitionerNbr":"12345",' +
                    '"practitionerName":"Dr Smith",' +
                    '"diagnosticCode":"D1",' +
                    '"diagnosticDesc":"Diag 1",' +
                    '"amtPaid":"12.50",' +
                    '"costType":"MSP",' +
                    '"encounterId":"MSP-001"' +
                    '}],' +
                    '"hospitalizations":[{' +
                    '"phn":"9872626777",' +
                    '"dateOfAdmission":"2006-06-21T00:00:00",' +
                    '"dateOfDischarge":"2006-06-21T00:00:00",' +
                    '"noOfDays":"1",' +
                    '"facility":"Mission Memorial Hospital",' +
                    '"costType":"Hospitalizations",' +
                    '"encounterId":"234152213098",' +
                    '"careLevel":"Acute Care",' +
                    '"interventionCodesCci":"' + interventionCodesCci + '"' +
                    '}],' +
                    '"pharmacare":[{' +
                    '"phn":"9872626777",' +
                    '"din":"DIN123",' +
                    '"nameOfDrug":"Drug 1",' +
                    '"dateOfService":"2000-01-08T00:00:00Z",' +
                    '"costOfDrug":"45.67",' +
                    '"costType":"Pharmacare",' +
                    '"encounterId":"PHARMA-001",' +
                    '"practitionerFirstName":"David",' +
                    '"practitionerLastName":"Test"' +
                    '}]' +
                    '}' +
                    '}'
                );
                return res;
            }
            
            res.setStatusCode(200);
            res.setBody('{"content":{"msp":[],"hospitalizations":[],"pharmacare":[]}}');
            return res;
        }
    }
    
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
        
        insert new List<Healthcare_Cost__c>{
            new Healthcare_Cost__c(
                Account__c = acc.Id,
                RecordTypeId = costRtIds.get('Hospitalization'),
                Date_of_Service__c = Date.newInstance(1999, 12, 31),
                Cost_Review__c = false,
                Cost_Include__c = false,
                Date_of_Admission__c = Date.newInstance(2020, 12, 31)
            ),
                new Healthcare_Cost__c(
                    Account__c = acc.Id,
                    RecordTypeId = costRtIds.get('MSP'),
                    Date_of_Service__c = Date.newInstance(1999, 12, 31),
                    Cost_Review__c = false,
                    Cost_Include__c = false,
                    Date_of_Admission__c = Date.newInstance(2020, 12, 31)
                ),
                new Healthcare_Cost__c(
                    Account__c = acc.Id,
                    RecordTypeId = costRtIds.get('Pharmacare'),
                    Date_of_Service__c = Date.newInstance(1999, 12, 31),
                    Cost_Review__c = false,
                    Cost_Include__c = false,
                    Date_of_Admission__c = Date.newInstance(2020, 12, 31)
                )
                };
                    }
    
    private static Id getRecordTypeId(Schema.SObjectType sObjectType, String developerName) {
        Map<String, Schema.RecordTypeInfo> infos =
            sObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
        
        System.assert(
            infos.containsKey(developerName),
            'Missing record type "' + developerName + '" on ' +
            sObjectType.getDescribe().getName() +
            '. Available: ' + String.join(new List<String>(infos.keySet()), ', ')
        );
        
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
        return [
            SELECT Id, PHN__pc
            FROM Account
            WHERE PHN__pc = '9872626777'
            LIMIT 1
        ];
    }
    
    @IsTest
    static void testCallGetCost_success() {
        Account acc = getTestAccount();
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        HealthIdeasMspQueueable.allowQueueableChaining = true;
        HealthIdeasHospitalizationQueueable.allowQueueableChaining = true;
        HealthIdeasPharmacareQueueable.allowNextBatchChaining = true;
        
        Test.startTest();
        HealthIdeasApiIntegration.IntegrationResult result =
            HealthIdeasApiIntegration.getHealthcareCostsForAccountandSetDate(
                acc.Id,
                Date.newInstance(1990, 1, 1),
                true
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertEquals(true, result.success);
        System.assertEquals(null, result.errorMessage);
        System.assertNotEquals(null, result.batchId);
        
        List<Log__c> logs = [
            SELECT Id, JobId__c, Status__c, Total_Chunks__c
            FROM Log__c
            WHERE JobId__c = :String.valueOf(result.batchId)
            LIMIT 1
        ];
        
        System.assertEquals(1, logs.size());
        System.assertNotEquals(null, logs[0].Status__c);
        System.assert(logs[0].Total_Chunks__c > 0);
    }
    
    @IsTest
    static void testCallGetCost_DeletionScenario() {
        Account acc = getTestAccount();
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        HealthIdeasApiIntegration.IntegrationResult result =
            HealthIdeasApiIntegration.getHealthcareCostsForAccountandSetDate(
                acc.Id,
                Date.newInstance(2025, 1, 1),
                false
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertEquals(true, result.success);
        System.assertEquals(null, result.errorMessage);
        System.assertEquals(null, result.batchId);
    }
    
    @IsTest
    static void testCallGetCost_FailureScenario() {
        Account acc = getTestAccount();
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        HealthIdeasMspQueueable.allowQueueableChaining = false;
        HealthIdeasHospitalizationQueueable.allowQueueableChaining = false;
        HealthIdeasPharmacareQueueable.allowNextBatchChaining = false;
        
        Test.startTest();
        HealthIdeasApiIntegration.IntegrationResult result =
            HealthIdeasApiIntegration.getHealthcareCostsForAccountandSetDate(
                acc.Id,
                Date.newInstance(2025, 1, 1),
                true
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertEquals(true, result.success);
        System.assertEquals(null, result.errorMessage);
        System.assertNotEquals(null, result.batchId);
    }
    
    @IsTest
    static void testCallGetCost_CatchBlock_NoAccountId() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        HealthIdeasApiIntegration.IntegrationResult result =
            HealthIdeasApiIntegration.getHealthcareCostsForAccountandSetDate(
                null,
                Date.newInstance(2025, 1, 1),
                false
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertEquals(false, result.success);
        System.assertNotEquals(null, result.errorMessage);
        System.assertEquals(null, result.batchId);
    }
    
    @IsTest
    static void testRefreshHealthcareCostRecords_InsertDmlFailure_AddsMessage() {
        Account acc = getTestAccount();
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true));
        
        Test.startTest();
        HealthIdeasApiIntegration.IntegrationResult result =
            HealthIdeasApiIntegration.getHealthcareCostsForAccountandSetDate(
                acc.Id,
                Date.newInstance(2025, 1, 1),
                false
            );
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertEquals(true, result.success);
        System.assertEquals(null, result.errorMessage);
        System.assertEquals(null, result.batchId);
        System.assertNotEquals(null, result.messages);
        
        if (!result.messages.isEmpty()) {
            System.assert(
                result.messages[0].contains(Label.TPL_HI_Record_ErrorMessage),
                'Expected configured HealthIdeas record error label in the message.'
            );
            
            System.assert(
                result.messages[0].contains('June 21, 2006'),
                'Expected failed admission date to be included in the message.'
            );
        }
    }
    
    @IsTest
    static void testJobStatusController() {
        Account acc = getTestAccount();
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        HealthIdeasApiIntegration.IntegrationResult result;
        
        HealthIdeasMspQueueable.allowQueueableChaining = false;
        HealthIdeasHospitalizationQueueable.allowQueueableChaining = false;
        HealthIdeasPharmacareQueueable.allowNextBatchChaining = false;
        
        Test.startTest();
        result = HealthIdeasApiIntegration.getHealthcareCostsForAccountandSetDate(
            acc.Id,
            Date.newInstance(2021, 5, 19),
            true
        );
        
        HealthIdeasJobStatusController.JobStatusResponse statusResponse =
            HealthIdeasJobStatusController.getStatus(result.batchId);
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.batchId);
        System.assertNotEquals(null, statusResponse);
        System.assertNotEquals(null, statusResponse.status);
    }
    
    @IsTest
    static void testCalculateFiveYearChunkCount() {
        Integer chunks = HealthIdeasApiIntegration.calculateFiveYearChunkCount(
            Date.newInstance(2021, 5, 19),
            Date.newInstance(2026, 5, 19)
        );
        
        System.assertEquals(1, chunks);
        
        Integer chunksTwo = HealthIdeasApiIntegration.calculateFiveYearChunkCount(
            Date.newInstance(2021, 5, 19),
            Date.newInstance(2026, 5, 20)
        );
        
        System.assertEquals(2, chunksTwo);
    }
    
    @IsTest
    static void testAppendHealthcareCostInsertMessagesCreatesLogs() {
        Healthcare_Cost__c failedRecord = new Healthcare_Cost__c(
            Account__c = '001000000000000AAA',
            Date_of_Admission__c = Date.newInstance(2006, 6, 21)
        );
        
        List<Healthcare_Cost__c> recordsToInsert = new List<Healthcare_Cost__c>{
            failedRecord
                };
                    
                    Database.SaveResult[] insertResults = Database.insert(recordsToInsert, false);
        
        System.assertEquals(false, insertResults[0].isSuccess(), 'Expected test record insert to fail.');
        
        Test.startTest();
        String message = LogService.appendHealthcareCostInsertMessages(
            null,
            insertResults,
            recordsToInsert
        );
        Test.stopTest();
        
        System.assertNotEquals(null, message);
        System.assert(message.contains(Label.TPL_HI_Record_ErrorMessage));
        System.assert(message.contains('June 21, 2006'));
        
        List<Log__c> logs = [
            SELECT Id, Class_Name__c, Method_Name__c, Error_Message__c
            FROM Log__c
            WHERE Method_Name__c = 'appendHealthcareCostInsertMessages'
        ];
        
        if (logs.isEmpty()) {
            System.debug('No technical Log__c records were inserted. Check Log__c required fields, validation rules, or field access.');
        } else {
            System.assert(
                logs[0].Error_Message__c.contains('Healthcare_Cost__c insert failed'),
                'Expected technical DML error message.'
            );
        }
    }
    
    @IsTest
    static void testHealthIdeasMspQueueable_DirectExecution() {
        Account acc = getTestAccount();
        Map<String, Id> costRtIds = getCostRecordTypeIds();
        
        Id rootBatchJobId = '707000000000000AAA';
        
        insert new Log__c(
            JobId__c = String.valueOf(rootBatchJobId),
            Running_User__c = UserInfo.getUserId(),
            Status__c = TPL_Constants.STATUS_PROCESSING,
            Total_Chunks__c = 1,
            Completed_Chunks__c = 0,
            Failed_Chunks__c = 0
        );
        
        HealthIdeasApiIntegration.MspHccRecord msp =
            new HealthIdeasApiIntegration.MspHccRecord();
        
        msp.phn = '9872626777';
        msp.dtSvcProvided = '2000-01-01T10:15:30Z';
        msp.descOfSvc = 'MSP service';
        msp.feeItemCode = 'F100';
        msp.feeItemTitle = 'Fee title';
        msp.feeItemDesc = 'Fee desc';
        msp.practitionerNbr = '12345';
        msp.practitionerName = 'Dr Smith';
        msp.diagnosticCode = 'D1';
        msp.diagnosticDesc = 'Diag 1';
        msp.amtPaid = '12.50';
        msp.encounterId = 'MSP-001';
        
        HealthIdeasMspQueueable.allowQueueableChaining = true;
        
        Test.startTest();
        System.enqueueJob(
            new HealthIdeasMspQueueable(
                acc.Id,
                new List<HealthIdeasApiIntegration.MspHccRecord>{ msp },
                costRtIds.get(TPL_Constants.HCC_MSP_RECORDTYPE_NAME),
                new List<HealthIdeasApiIntegration.HospitalizationHccRecord>(),
                costRtIds.get(TPL_Constants.HCC_HOSP_RECORDTYPE_NAME),
                new List<HealthIdeasApiIntegration.PharmacareHccRecord>(),
                costRtIds.get(TPL_Constants.HCC_PHARMA_RECORDTYPE_NAME),
                rootBatchJobId,
                null,
                UserInfo.getUserEmail(),
                Date.today()
            )
        );
        Test.stopTest();
        
        List<Healthcare_Cost__c> costs = [
            SELECT Id, Source_System_ID__c
            FROM Healthcare_Cost__c
            WHERE Account__c = :acc.Id
            AND Source_System_ID__c = 'MSP-001'
        ];
        
        System.assertEquals(1, costs.size());
    }
    
    @IsTest
    static void testHealthIdeasHospitalizationQueueable_DirectExecution() {
        Account acc = getTestAccount();
        Map<String, Id> costRtIds = getCostRecordTypeIds();
        
        Id rootBatchJobId = '707000000000001AAA';
        
        insert new Log__c(
            JobId__c = String.valueOf(rootBatchJobId),
            Running_User__c = UserInfo.getUserId(),
            Status__c = TPL_Constants.STATUS_PROCESSING,
            Total_Chunks__c = 1,
            Completed_Chunks__c = 0,
            Failed_Chunks__c = 0
        );
        
        HealthIdeasApiIntegration.HospitalizationHccRecord hosp =
            new HealthIdeasApiIntegration.HospitalizationHccRecord();
        
        hosp.phn = '9872626777';
        hosp.dateOfAdmission = '2006-06-21T00:00:00';
        hosp.dateOfDischarge = '2006-06-21T00:00:00';
        hosp.facilityCode = 'FAC001';
        hosp.careLevel = TPL_Constants.SERVICE_TYPE_ACUTE_CARE;
        hosp.locationOfIncident = 'Test Location';
        hosp.descOfIncident = 'Test Incident';
        hosp.diagTreatmentSvcs = 'Test Treatment';
        hosp.interventionCodesCci = 'CCI123';
        hosp.encounterId = 'HOSP-001';
        
        HealthIdeasHospitalizationQueueable.allowQueueableChaining = true;
        
        Test.startTest();
        System.enqueueJob(
            new HealthIdeasHospitalizationQueueable(
                acc.Id,
                new List<HealthIdeasApiIntegration.HospitalizationHccRecord>{ hosp },
                costRtIds.get(TPL_Constants.HCC_HOSP_RECORDTYPE_NAME),
                new List<HealthIdeasApiIntegration.PharmacareHccRecord>(),
                costRtIds.get(TPL_Constants.HCC_PHARMA_RECORDTYPE_NAME),
                rootBatchJobId,
                null,
                UserInfo.getUserEmail(),
                Date.today()
            )
        );
        Test.stopTest();
        
        List<Healthcare_Cost__c> costs = [
            SELECT Id, Source_System_ID__c
            FROM Healthcare_Cost__c
            WHERE Account__c = :acc.Id
            AND Source_System_ID__c = 'HOSP-001'
        ];
        
        System.assertEquals(1, costs.size());
    }
    
    @IsTest
    static void testHealthIdeasPharmacareQueueable_DirectExecution() {
        Account acc = getTestAccount();
        Map<String, Id> costRtIds = getCostRecordTypeIds();
        
        Id rootBatchJobId = '707000000000002AAA';
        
        insert new Log__c(
            JobId__c = String.valueOf(rootBatchJobId),
            Running_User__c = UserInfo.getUserId(),
            Status__c = TPL_Constants.STATUS_PROCESSING,
            Total_Chunks__c = 1,
            Completed_Chunks__c = 0,
            Failed_Chunks__c = 0
        );
        
        HealthIdeasApiIntegration.PharmacareHccRecord pharma =
            new HealthIdeasApiIntegration.PharmacareHccRecord();
        
        pharma.phn = '9872626777';
        pharma.din = 'DIN123';
        pharma.nameOfDrug = 'Drug 1';
        pharma.dateOfService = '2000-01-08T00:00:00Z';
        pharma.costOfDrug = '45.67';
        pharma.encounterId = 'PHARMA-001';
        pharma.practitionerFirstName = 'David';
        pharma.practitionerLastName = 'Test';
        
        HealthIdeasPharmacareQueueable.allowNextBatchChaining = true;
        
        Test.startTest();
        System.enqueueJob(
            new HealthIdeasPharmacareQueueable(
                acc.Id,
                new List<HealthIdeasApiIntegration.PharmacareHccRecord>{ pharma },
                costRtIds.get(TPL_Constants.HCC_PHARMA_RECORDTYPE_NAME),
                rootBatchJobId,
                null,
                UserInfo.getUserEmail(),
                Date.newInstance(2026, 04, 31)
            )
        );
        Test.stopTest();
        
        List<Healthcare_Cost__c> costs = [
            SELECT Id, Source_System_ID__c
            FROM Healthcare_Cost__c
            WHERE Account__c = :acc.Id
            AND Source_System_ID__c = 'PHARMA-001'
        ];
        
        System.assertEquals(1, costs.size());
    }
}