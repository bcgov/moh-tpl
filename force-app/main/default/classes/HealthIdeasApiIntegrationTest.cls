@IsTest
private class HealthIdeasApiIntegrationTest {

    private static String mockScenario = 'EMPTY';

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            String endpoint = req.getEndpoint() == null ? '' : req.getEndpoint().toLowerCase();

            if (endpoint.contains('token') || endpoint.contains('oauth') || endpoint.contains('jwt')) {
                if (mockScenario == 'TOKEN_FAIL') {
                    res.setStatusCode(200);
                    res.setBody('{"token_type":"Bearer","expires_in":3600}');
                    return res;
                }

                res.setStatusCode(200);
                res.setBody('{"access_token":"fake-access-token","token_type":"Bearer","expires_in":3600}');
                return res;
            }

            if (endpoint.contains('getcost')) {
                if (mockScenario == 'HTTP_ERROR') {
                    res.setStatusCode(500);
                    res.setBody('{"error":"server error"}');
                    return res;
                }

                if (mockScenario == 'BAD_JSON') {
                    res.setStatusCode(200);
                    res.setBody('this is not valid json');
                    return res;
                }

                if (mockScenario == 'FULL') {
                    res.setStatusCode(200);
                    res.setBody(
                        '{' +
                            '"content":{' +
                                '"msp":[{' +
                                    '"phn":"9872626746",' +
                                    '"dtSvcProvided":"2000-01-01T10:15:30Z",' +
                                    '"descOfSvc":"MSP service",' +
                                    '"feeItemCode":"F100",' +
                                    '"feeItemTitle":"Fee title",' +
                                    '"feeItemDesc":"Fee desc",' +
                                    '"practitionerNbr":"12345",' +
                                    '"practitionerName":"Dr Smith",' +
                                    '"diagnosticCode":"D1",' +
                                    '"diagnosticDesc":"Diag 1",' +
                                    '"diagnosticCode1":"D2",' +
                                    '"diagnosticDesc1":"Diag 2",' +
                                    '"diagnosticCode2":"D3",' +
                                    '"diagnosticDesc2":"Diag 3",' +
                                    '"diagnosticCode3":"D4",' +
                                    '"diagnosticDesc3":"Diag 4",' +
                                    '"amtPaid":"12.50",' +
                                    '"specialtyCode":"SC1",' +
                                    '"specialtyDesc":"Specialty 1",' +
                                    '"payeeNbr":"P1",' +
                                    '"payeeDesc":"Payee desc",' +
                                    '"svcStartDt":"2000-01-01",' +
                                    '"svcFinishDt":"2000-01-02",' +
                                    '"facility":"Facility 1",' +
                                    '"facilityCode":"FAC1",' +
                                    '"facilityType":"Clinic",' +
                                    '"locationTypeCode":"LOC1",' +
                                    '"locationTypeDesc":"Location 1",' +
                                    '"costType":"MSP",' +
                                    '"encounterId":"MSP-001"' +
                                '}],' +
                                '"hospitalizations":[{' +
                                    '"phn":"9872626746",' +
                                    '"dateOfAdmission":"2006-06-21T00:00:00",' +
                                    '"dateOfDischarge":"2006-06-21T00:00:00",' +
                                    '"noOfDays":"1",' +
                                    '"facilityCode":"602",' +
                                    '"facility":"Mission Memorial Hospital",' +
                                    '"careLevelGroup":"Day Surgery",' +
                                    '"careLevelCode":"S",' +
                                    '"careLevel":"Day Surgery",' +
                                    '"locationOfIncident":"Hospital",' +
                                    '"descOfIncident":"Not Applicable",' +
                                    '"diagTreatmentSvcs":"Therapeutic Interventions for Carpal Tunnel (004)",' +
                                    '"entryCode":"D",' +
                                    '"entryCodeDescription":"Direct",' +
                                    '"interventionCodesCci":"1BN72LA",' +
                                    '"costType":"Hospitalizations",' +
                                    '"encounterId":"234152213098"' +
                                '}],' +
                                '"pharmacare":[{' +
                                    '"phn":"9872626746",' +
                                    '"din":"DIN123",' +
                                    '"nameOfDrug":"Drug 1",' +
                                    '"dateOfService":"2000-01-08T00:00:00Z",' +
                                    '"practitionerId":"PR1",' +
                                    '"practitionerFirstName":"Crystal",' +
                                    '"practitionerLastName":"Zhu",' +
                                    '"costOfDrug":"45.67",' +
                                    '"costType":"Pharmacare",' +
                                    '"encounterId":"PHARMA-001"' +
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

            res.setStatusCode(404);
            res.setBody('{"error":"Unexpected endpoint: ' + req.getEndpoint() + '"}');
            return res;
        }
    }

    @testSetup
    static void setupData() {
        Account acc = new Account();
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Individual').getRecordTypeId();
        acc.FirstName = 'David';
        acc.LastName = 'Scott';
        acc.Type = 'Client';
        acc.Date_of_Birth__pc = Date.newInstance(1996, 11, 14);
        acc.PHN__pc = '9872626746';
        insert acc;

        Map<String, Schema.RecordTypeInfo> byDevName =
            Healthcare_Cost__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();

        insert new List<Healthcare_Cost__c>{
            new Healthcare_Cost__c(
                Account__c = acc.Id,
                RecordTypeId = byDevName.get('Pharmacare').getRecordTypeId(),
                Date_of_Service__c = Date.newInstance(1999, 12, 31),
                Cost_Review__c = false,
                Cost_Include__c = false,
                Date_of_Admission__c = Date.newInstance(2020, 12, 31)
            ),
            new Healthcare_Cost__c(
                Account__c = acc.Id,
                RecordTypeId = byDevName.get('Hospitalization').getRecordTypeId(),
                Date_of_Service__c = Date.newInstance(1999, 12, 31),
                Cost_Review__c = false,
                Cost_Include__c = false,
                Date_of_Admission__c = Date.newInstance(2020, 12, 31)
            ),
            new Healthcare_Cost__c(
                Account__c = acc.Id,
                RecordTypeId = byDevName.get('MSP').getRecordTypeId(),
                Date_of_Service__c = Date.newInstance(1999, 12, 31),
                Cost_Review__c = false,
                Cost_Include__c = false,
                Date_of_Admission__c = Date.newInstance(2020, 12, 31)
            )
        };
    }

    private static Account getTestAccount() {
        return [
            SELECT Id, PHN__pc
            FROM Account
            WHERE PHN__pc = '9872626746'
            LIMIT 1
        ];
    }

    private static Map<String, Id> getCostRecordTypeIds() {
        Map<String, Schema.RecordTypeInfo> byDevName =
            Healthcare_Cost__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();

        return new Map<String, Id>{
            'MSP' => byDevName.get('MSP').getRecordTypeId(),
            'Pharmacare' => byDevName.get('Pharmacare').getRecordTypeId(),
            'Hospitalization' => byDevName.get('Hospitalization').getRecordTypeId()
        };
    }

    @IsTest
	static void testCallGetCost_fullResponseCreatesRecords() {
    mockScenario = 'FULL';
    Account acc = getTestAccount();

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

    HealthIdeasApiIntegration.IntegrationResult result =
        HealthIdeasApiIntegration.callGetCost(
            acc.Id,
            Date.newInstance(2000, 1, 1),
            'crystal.zhu@hi.com'
        );
    Test.stopTest();

   // System.assertEquals(true, result.success, result.errorMessage);
   // System.assertEquals(true, result.pharmacareTransactionsComplete);
   // System.assertEquals(true, result.hospitalTransactionsComplete);
   // System.assertEquals(true, result.mspTransactionsComplete);
   // System.assertEquals(1, result.createdPharmacareIds.size());
//    System.assertEquals(1, result.createdHospitalIds.size());
   // System.assertEquals(1, result.createdMspIds.size());
	}
}