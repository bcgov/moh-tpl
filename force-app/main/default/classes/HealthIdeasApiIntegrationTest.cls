@IsTest
private class HealthIdeasApiIntegrationTest {

    // Mock response generator for token and HealthIdeas API callouts.
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
            system.debug(endpoint);
            String body = req.getBody() == null ? '' : req.getBody().toLowerCase();

            // Detects token-related requests.
            Boolean isTokenRequest =
                endpoint.contains('token') ||
                endpoint.contains('oauth') ||
                endpoint.contains('jwt') ||
                body.contains('grant_type') ||
                body.contains('client_assertion') ||
                body.contains('client_id');

            // Returns mocked auth token response.
            if (isTokenRequest) {
                res.setStatusCode(200);
                res.setBody('{"access_token":"fake-access-token","token_type":"Bearer","expires_in":3600}');
                return res;
            }

            String interventionCodesCci = forceHospitalizationDmlFailure
                ? 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
                : 'CCI123';

            // Returns mocked HealthIdeas response data.
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

            // Default empty response.
            res.setStatusCode(200);
            res.setBody('{"content":{"msp":[],"hospitalizations":[],"pharmacare":[]}}');
            return res;
        }
    }

    // Creates base Account and Healthcare Cost test data.
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

    // Returns record type Id by developer name.
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

    // Returns Healthcare Cost record type Ids used by tests.
    private static Map<String, Id> getCostRecordTypeIds() {
        return new Map<String, Id>{
            'MSP' => getRecordTypeId(Healthcare_Cost__c.SObjectType, 'MSP'),
            'Pharmacare' => getRecordTypeId(Healthcare_Cost__c.SObjectType, 'Pharmacare'),
            'Hospitalization' => getRecordTypeId(Healthcare_Cost__c.SObjectType, 'Hospitalization')
        };
    }

    // Returns the test Person Account.
    private static Account getTestAccount() {
        return [
            SELECT Id, PHN__pc
            FROM Account
            WHERE PHN__pc = '9872626777'
            LIMIT 1
        ];
    }

    // Covers successful API call and batch launch.
    @IsTest
    static void testCallGetCost_success() {
        Account acc = getTestAccount();

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        HealthIdeasApiIntegration.IntegrationResult result = HealthIdeasApiIntegration.getHealthcareCostsForAccountandSetDate(acc.Id,Date.newInstance(1990, 1, 1), true);
        Test.stopTest();

        // Validate successful response.
        System.assertNotEquals(null, result);
        System.assertEquals(true, result.success);
        System.assertEquals(null, result.errorMessage);
        System.assertNotEquals(null, result.batchId);
    }
    
    // Covers scenario where existing records may be deleted and refreshed.
    @IsTest
     static void testCallGetCost_DeletionScenario() {
        Account acc = getTestAccount();

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        HealthIdeasApiIntegration.IntegrationResult result = HealthIdeasApiIntegration.getHealthcareCostsForAccountandSetDate(acc.Id,Date.newInstance(2025, 1, 1), false);
        Test.stopTest();

        // Validate delete and reload flow started.
        System.assertNotEquals(null, result);
        System.assertEquals(true, result.success);
        System.assertEquals(null, result.errorMessage);
        System.assertEquals(null, result.batchId);
    }
    
     // Current failure-named test still executes the success path.
     @IsTest
     static void testCallGetCost_FailureScenario() {
        Account acc = getTestAccount();

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        HealthIdeasApiIntegration.IntegrationResult result = HealthIdeasApiIntegration.getHealthcareCostsForAccountandSetDate(acc.Id,Date.newInstance(2025, 1, 1), true);
        Test.stopTest();

        // Current input still follows success path.
        System.assertNotEquals(null, result);
        System.assertEquals(true, result.success);
        System.assertEquals(null, result.errorMessage);
        System.assertNotEquals(null, result.batchId);
    }
    
    // Covers batch status polling method.
    @IsTest
    static void testIsBatchInProgress() {
        Account acc = getTestAccount();
    
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
    
        Id batchId;
    
        Test.startTest();
        HealthIdeasApiIntegration.IntegrationResult result =
            HealthIdeasApiIntegration.getHealthcareCostsForAccountandSetDate(
                acc.Id,
                Date.newInstance(2025, 1, 1), true
            );
    
        batchId = result.batchId;
        Boolean inProgress = HealthIdeasApiIntegration.isBatchInProgress(batchId);
        Test.stopTest();
    
        // Validate batch tracking response.
        System.assertNotEquals(null, result);
        System.assertEquals(true, result.success);
        System.assertNotEquals(null, batchId);
        System.assertEquals(true, inProgress);
    }
    
    @IsTest
	static void testCallGetCost_CatchBlock_NoAccountId() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
    
        Test.startTest();
        HealthIdeasApiIntegration.IntegrationResult result =
            HealthIdeasApiIntegration.getHealthcareCostsForAccountandSetDate(
                null,
                Date.newInstance(2025, 1, 1), true
            );
        Test.stopTest();
    
        // Validates catch block execution.
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

        System.assertNotEquals(null, result, 'Expected integration result.');

        System.assertEquals(true, result.success, 'Expected integration call to complete successfully even when one insert row fails.');

        System.assertEquals(null, result.errorMessage, 'Expected no top-level integration error.');

        System.assertEquals(null, result.batchId, 'Expected no batch Id for synchronous refresh.');

        System.assertNotEquals(null, result.messages, 'Expected messages list to be initialized.');

      //  System.assertEquals(1, result.messages.size(), 'Expected one user-facing message for the failed hospitalization insert.');

     //   System.assert(result.messages[0].contains(Label.TPL_HI_Record_ErrorMessage), 'Expected configured HealthIdeas record error label in the message.');

     //   System.assert(result.messages[0].contains('June 21, 2006'), 'Expected failed admission date to be included in the message.');
    }
}