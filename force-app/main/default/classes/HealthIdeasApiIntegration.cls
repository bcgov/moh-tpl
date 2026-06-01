/**
 * Author: Nikhil Jeenru 
 * Company : CGI
 * Purpose:
 * This class handles the HealthIdeas API integration, prepares the response data,
 * and starts the batch process that refreshes Healthcare Cost records on the Person Accounts.
 */

public with sharing class HealthIdeasApiIntegration {

    private static final Boolean ENABLE_DEBUG_LOGS = false;
    private static final String HCC_HOSP_RECORDTYPE_NAME = 'Hospitalization';
    private static final String HCC_PHARMA_RECORDTYPE_NAME = 'Pharmacare';
    private static final String HCC_MSP_RECORDTYPE_NAME = 'MSP';
    private static final String RESPONSE_HOSPITALIZATIONS = 'hospitalizations';
    private static final String HI_API_FAILURE_MESSAGE = 'HealthIdeas API Call failed: ';

    //Helper method for consistent logging throughout the class.
    private static void debugLog(String message) {
        if (ENABLE_DEBUG_LOGS) {
            System.debug(message);
        }
    }

    /**
     * Result returned to the UI or caller after attempting the integration call.
     */
    public class IntegrationResult {
        @AuraEnabled public Boolean success = false;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public Id batchId;
        @AuraEnabled public List<String> messages = new List<String>();
    }

    /**
     * Payload passed from delete batch to insert batch.
     * Keeps API response data in typed lists instead of wrapping every record as Object.
    */
    public class HealthIdeasBatchPayload {
        public List<MspHccRecord> msp;
        public List<HospitalizationHccRecord> hospitalizations;
        public List<PharmacareHccRecord> pharmacare;
    }

    /**
     * Represents a single MSP record returned by the API.
     */
    public class MspHccRecord {
        public String phn;
        public String dtSvcProvided;
        public String descOfSvc;
        public String feeItemCode;
        public String feeItemTitle;
        public String feeItemDesc;
        public String practitionerNbr;
        public String practitionerName;
        public String diagnosticCode;
        public String diagnosticDesc;
        public String diagnosticCode1;
        public String diagnosticDesc1;
        public String diagnosticCode2;
        public String diagnosticDesc2;
        public String diagnosticCode3;
        public String diagnosticDesc3;
        public String amtPaid;
        public String specialtyCode;
        public String specialtyDesc;
        public String payeeNbr;
        public String payeeDesc;
        public String svcStartDt;
        public String svcFinishDt;
        public String facility;
        public String facilityCode;
        public String facilityType;
        public String locationTypeCode;
        public String locationTypeDesc;
        public String encounterId;
    }

    /**
     * Represents a single hospitalization record returned by the API.
     */
    public class HospitalizationHccRecord {
        public String phn;
        public String dateOfAdmission;
        public String dateOfDischarge;
        public String facilityCode;
        public String careLevel;
        public String locationOfIncident;
        public String descOfIncident;
        public String diagTreatmentSvcs;
        public String interventionCodesCci;
        public String encounterId;
    }

     /**
     * Represents a single Pharmacare record returned by the API.
     */
    public class PharmacareHccRecord {
        public String phn;
        public String din;
        public String nameOfDrug;
        public String dateOfService;
        public String practitionerFirstName;
        public String practitionerLastName;
        public String costOfDrug;
        public String encounterId;
    }
    
     /**
     * UI-friendly entry point.
     * Uses the current logged-in user's email as the requester name.
     */
     @AuraEnabled
	public static IntegrationResult  getHealthcareCostsForAccountandSetDate(Id accountId, Date asOfDate, Boolean isASyncCall) {
        String requesterUserName = UserInfo.getUserEmail();
        return fetchHealthcareCosts(accountId, asOfDate, requesterUserName, isASyncCall);
	}
       
    /**
     * Main integration method.
     * - Gets the member PHN from Account
     * - Calls HealthIdeas API
     * - Combines returned datasets
     * - Starts the delete/Insert batch job
     */
    public static IntegrationResult fetchHealthcareCosts(Id accountId, Date asOfDate, String requesterUserName, Boolean isASyncCall) {

        IntegrationResult result = new IntegrationResult();

        try {
            Account acc = [SELECT Id, PHN__pc FROM Account WHERE Id = :accountId LIMIT 1];
    
            HttpResponse res = sendHealthIdeasRequest(requesterUserName, acc.PHN__pc, asOfDate);

            debugLog('Response Status Code: ' + res.getStatusCode());
            debugLog('Response Status: ' + res.getStatus());

            if (res.getStatusCode() != 200) {
                result.success = false;
                result.errorMessage = HI_API_FAILURE_MESSAGE + res.getStatus();
                return result;
            }

            String responseBody = res.getBody();

          //  debugLog(
           //     'Response Body Length: ' +
           //     String.valueOf(responseBody != null ? responseBody.length() : 0)
          //  );

            Map<String, Id> hccrecordTypeIds = getHealthcareCostRecordTypeIds();

            HealthIdeasBatchPayload payload = parseHealthIdeasPayload(responseBody);

            if (isASyncCall) {
                 String jsonData = JSON.serialize(payload);
                Id batchId = Database.executeBatch(
                    new HealthIdeasHCCRecordsDeleteBatch(
                        accountId,
                        asOfDate,
                        jsonData,
                        hccrecordTypeIds
                    ),
                    200
                );

                result.batchId = batchId; 
            } else {
                refreshHealthcareCostRecords(
                    accountId,
                    asOfDate,
                    payload,
                    hccrecordTypeIds,
                    result.messages
                );
            }
            result.success = true;
            return result;
        } 
        catch (Exception e) {
            result.success = false;
            result.errorMessage = e.getMessage();
            return result;
        }
    }

    /**
     * Deletes eligible Healthcare Cost records and inserts refreshed HealthIdeas data synchronously.
     * Sync process
     */
    public static void refreshHealthcareCostRecords(
        Id accountId,
        Date asOfDate,
        HealthIdeasBatchPayload payload,
        Map<String, Id> recordTypeIds,
        List<String> messages
    ) {
        List<Healthcare_Cost__c> recordsToDelete = [
            SELECT Id
            FROM Healthcare_Cost__c
            WHERE Account__c = :accountId
            AND RecordTypeId IN :new List<Id>{
                recordTypeIds.get(HCC_PHARMA_RECORDTYPE_NAME),
                recordTypeIds.get(HCC_HOSP_RECORDTYPE_NAME),
                recordTypeIds.get(HCC_MSP_RECORDTYPE_NAME)
            }
            AND Date_of_Service__c < :asOfDate
            AND Cost_Review__c = false
            AND Cost_Include__c = false
            AND (Case2__c = null OR Case2__c = '')
        ];

        if (!recordsToDelete.isEmpty()) {
            Database.DeleteResult[] deleteResults = Database.delete(recordsToDelete, false);

            for (Integer i = 0; i < deleteResults.size(); i++) {
                if (!deleteResults[i].isSuccess()) {
                    for (Database.Error err : deleteResults[i].getErrors()) {
                        messages.add(
                            'Delete failed for Healthcare_Cost__c Id ' +
                            String.valueOf(recordsToDelete[i].Id) +
                            ': ' +
                            err.getMessage()
                        );
                    }
                }
            }
        }

        List<HealthIdeasApiIntegration.MspHccRecord> mspList =
            payload.msp == null
                ? new List<HealthIdeasApiIntegration.MspHccRecord>()
                : payload.msp;

        List<HealthIdeasApiIntegration.HospitalizationHccRecord> hospList =
            payload.hospitalizations == null
                ? new List<HealthIdeasApiIntegration.HospitalizationHccRecord>()
                : payload.hospitalizations;

        List<HealthIdeasApiIntegration.PharmacareHccRecord> pharmaList =
            payload.pharmacare == null
                ? new List<HealthIdeasApiIntegration.PharmacareHccRecord>()
                : payload.pharmacare;

        List<Healthcare_Cost__c> recordsToInsert = new List<Healthcare_Cost__c>();

        if ( !mspList.isEmpty() ) {
            recordsToInsert.addAll(
                HealthIdeasApiIntegration.buildMspHealthcareCostRecords(
                    mspList,
                    accountId,
                    recordTypeIds.get(HCC_MSP_RECORDTYPE_NAME)
                )
            );
        }

        if ( !hospList.isEmpty() ) {
            recordsToInsert.addAll(
                HealthIdeasApiIntegration.buildHospitalizationHealthcareCostRecords(
                    hospList,
                    accountId,
                    recordTypeIds.get(HCC_HOSP_RECORDTYPE_NAME)
                )
            );
        }

        if ( !pharmaList.isEmpty() ) {
            recordsToInsert.addAll(
                HealthIdeasApiIntegration.buildPharmacareHealthcareCostRecords(
                    pharmaList,
                    accountId,
                    recordTypeIds.get(HCC_PHARMA_RECORDTYPE_NAME)
                )
            );
        }

        if (!recordsToInsert.isEmpty()) {
            Database.SaveResult[] insertResults = Database.insert(recordsToInsert, false);
            Set<String> affectedDates = new Set<String>();

            for (Integer i = 0; i < insertResults.size(); i++) {
                if (!insertResults[i].isSuccess()) {
                    Healthcare_Cost__c failedRecord = recordsToInsert[i];
                    for (Database.Error err : insertResults[i].getErrors()) {
                        if (err.getStatusCode() != StatusCode.DUPLICATE_VALUE) {
                            Date affectedDate = failedRecord.Date_of_Admission__c != null ? failedRecord.Date_of_Admission__c : failedRecord.Date_of_Service__c;
                            if (affectedDate != null) {
                                String admissionDate = DateTime.newInstance(
                                    affectedDate,
                                    Time.newInstance(0, 0, 0, 0)
                                ).format('MMMM d, yyyy');

                                affectedDates.add(admissionDate);
                            }
                        }
                    }
                }
            }

            for (String admissionDate : affectedDates) {
                messages.add(
                     Label.TPL_HI_Record_ErrorMessage + ' ' + admissionDate
                );
            }
        }
    }
    
     /**
     * Resolves Healthcare Cost record type Ids by developer name.
     */
    public static Map<String, Id> getHealthcareCostRecordTypeIds() {
        Map<String, Schema.RecordTypeInfo> rtMap =
            Healthcare_Cost__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();

        return new Map<String, Id>{
            HCC_MSP_RECORDTYPE_NAME => rtMap.get(HCC_MSP_RECORDTYPE_NAME).getRecordTypeId(),
            HCC_PHARMA_RECORDTYPE_NAME => rtMap.get(HCC_PHARMA_RECORDTYPE_NAME).getRecordTypeId(),
            HCC_HOSP_RECORDTYPE_NAME => rtMap.get(HCC_HOSP_RECORDTYPE_NAME).getRecordTypeId()
        };
    }

    private static HealthIdeasBatchPayload parseHealthIdeasPayload(String responseBody) {
    HealthIdeasBatchPayload payload = new HealthIdeasBatchPayload();

    if (String.isBlank(responseBody)) {
        return payload;
    }

    JSONParser parser = JSON.createParser(responseBody);

    while (parser.nextToken() != null) {
        if (
            parser.getCurrentToken() == JSONToken.FIELD_NAME &&
            parser.getText() == 'content'
        ) {
            parser.nextToken();

            if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                parseHealthIdeasContent(parser, payload);
            } else {
                parser.skipChildren();
            }
        }
    }

    return payload;
}

    private static void parseHealthIdeasContent(
            JSONParser parser,
            HealthIdeasBatchPayload payload
        ) {
            while (parser.nextToken() != null) {
                JSONToken token = parser.getCurrentToken();

                if (token == JSONToken.END_OBJECT) {
                    return;
                }

                if (token == JSONToken.FIELD_NAME) {
                    String fieldName = parser.getText();

                    parser.nextToken();

                    if (fieldName == HCC_MSP_RECORDTYPE_NAME.toLowerCase()) {
                        payload.msp =
                            (List<MspHccRecord>) parser.readValueAs(
                                List<MspHccRecord>.class
                            );

                    } else if (fieldName == RESPONSE_HOSPITALIZATIONS.toLowerCase()) {
                        payload.hospitalizations =
                            (List<HospitalizationHccRecord>) parser.readValueAs(
                                List<HospitalizationHccRecord>.class
                            );

                    } else if (fieldName == HCC_PHARMA_RECORDTYPE_NAME.toLowerCase()) {
                        payload.pharmacare =
                            (List<PharmacareHccRecord>) parser.readValueAs(
                                List<PharmacareHccRecord>.class
                            );

                    } else {
                        parser.skipChildren();
                    }
                }
            }
        }
    
     /**
     * Makes the outbound call to HealthIdeas using the named credential and bearer token.
     */
    public static HttpResponse sendHealthIdeasRequest(String requesterUserName, String phn, Date asOfDate) {

        HttpRequest req = new HttpRequest();
       	req.setEndpoint('callout:HealthIdeas');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000);

        req.setBody(JSON.serialize(new Map<String, Object>{
            'requester' => requesterUserName,
            'personalHealthNumber' => phn,
            'asOfDate' => String.valueOf(asOfDate)
        }));

        return new Http().send(req);
    }


    /**
     * Builds Healthcare Cost records for MSP data.
     */
    public static List<Healthcare_Cost__c> buildMspHealthcareCostRecords(List<MspHccRecord> items, Id accountId, Id recordTypeId) {
        List<Healthcare_Cost__c> rows = new List<Healthcare_Cost__c>();
         for (MspHccRecord item : items) {
            Healthcare_Cost__c row = new Healthcare_Cost__c();
            row.Account__c = accountId;
            row.RecordTypeId = recordTypeId;
            row.PHN__c = item.phn;
            row.Source_System_ID__c = item.encounterId;
            row.Date_of_Service__c = parseDate(item.dtSvcProvided);
            row.Service_Start_Date__c = parseDate(item.svcStartDt);
            row.Service_Finish_Date__c = parseDate(item.svcFinishDt);
            row.Diagnostic_Code__c = item.diagnosticCode;
            row.Diagnostic_Code_1__c = item.diagnosticCode1;
            row.Diagnostic_Code_2__c = item.diagnosticCode2;
            row.Diagnostic_Code_3__c = item.diagnosticCode3;
            row.Diagnostic_Description__c = item.diagnosticDesc;
            row.Diagnostic_Description_1__c = item.diagnosticDesc1;
            row.Diagnostic_Description_2__c = item.diagnosticDesc2;
            row.Diagnostic_Description_3__c = item.diagnosticDesc3;
            row.Description_of_Service2__c = item.descOfSvc;
            row.Fee_Item_Code__c = item.feeItemCode;
            row.Fee_Item_Title__c = item.feeItemTitle;
            row.Fee_Item_Description__c = truncateIncomingFieldValueToMax(item.feeItemDesc, 255);
            row.Practitioner_Name__c = item.practitionerName;
            row.Practitioner_Number__c = item.practitionerNbr;
            row.Payee_Number__c = item.payeeNbr;
            row.Payee_Description__c = item.payeeDesc;
            row.Location_Type_Code__c = item.locationTypeCode;
            row.Location_Type_Description2__c = item.locationTypeDesc;
            row.Amount_Paid__c = parseDecimal(item.amtPaid);
            row.Specialty_Code__c = item.specialtyCode;
            row.Specialty_Description2__c = item.specialtyDesc;
            row.Site_Code__c = item.facilityCode;
            row.Facility_Type__c = item.facilityType;

            rows.add(row);
        }

        return rows;
    }
    
	  /**
     * Builds Healthcare Cost records for hospitalization data.
     */
    public static List<Healthcare_Cost__c> buildHospitalizationHealthcareCostRecords(List<HospitalizationHccRecord> items, Id accountId, Id recordTypeId) {
        List<Healthcare_Cost__c> rows = new List<Healthcare_Cost__c>();
          for (HospitalizationHccRecord item : items) {        
            Healthcare_Cost__c row = new Healthcare_Cost__c();
            row.Account__c = accountId;
            row.RecordTypeId = recordTypeId;
            row.PHN__c = item.phn;
            row.Date_of_Admission__c = parseDate(item.dateOfAdmission);
            row.Date_of_Discharge__c = parseDate(item.dateOfDischarge);
            row.Site_Code__c = item.facilityCode;
            row.Service_Type2__c = normalizeDatedHospitalServiceType(item.careLevel, row.Date_of_Admission__c);
            row.Service_Type__c = returnServiceTypeProduct(item.careLevel, row.Date_of_Admission__c, row.Site_Code__c);
            row.Location_of_Incident__c = item.locationOfIncident;
            row.Description_of_Incident__c = item.descOfIncident;
            row.Diagnostic_Treatment_Service2__c = item.diagTreatmentSvcs;
            row.Intervention_Code_CCI__c = item.interventionCodesCci;
            row.Source_System_ID__c = item.encounterId;
        
            rows.add(row);
        }
        return rows;
    }

    /**
     * Builds Healthcare Cost records for Pharmacare data.
     */
    public static List<Healthcare_Cost__c> buildPharmacareHealthcareCostRecords(List<PharmacareHccRecord> items, Id accountId, Id recordTypeId) {
        List<Healthcare_Cost__c> rows = new List<Healthcare_Cost__c>();
         for (PharmacareHccRecord item : items) {        
             Healthcare_Cost__c row = new Healthcare_Cost__c();
             row.Account__c = accountId;
             row.RecordTypeId = recordTypeId;
             row.PHN__c = item.phn;
             row.Source_System_ID__c = item.encounterId;
             row.Date_of_Service__c = parseDate(item.dateOfService);
             row.Name_of_Drug__c = item.nameOfDrug;
             row.Cost_of_Drug__c = parseDecimal(item.costOfDrug);
             row.DIN__c = item.din;
             
             String fullName = '';
             
             if (!String.isBlank(item.practitionerFirstName)) {
                 fullName += item.practitionerFirstName;
             }
             if (!String.isBlank(item.practitionerLastName)) {
                 if (!String.isBlank(fullName)) {
                     fullName += ' ';
                 }
                 fullName += item.practitionerLastName;
             }
             
             row.Practitioner_Name__c = fullName;
             row.Practitioner_First_Name__c = item.practitionerFirstName;
             row.Practitioner_Last_Name__c = item.practitionerLastName;
             
             rows.add(row);
            }
    	return rows;
    }
    
     /**
     * Normalizes hospital service type and appends the financial year.
     */
	 private static String normalizeDatedHospitalServiceType(String value, Date admissionDate) {
        String yearSTR = String.valueOf(admissionDate.year());
        
        If(admissionDate.month() > 3){
            yearSTR = String.valueOf(admissionDate.year() + 1);
        }
              
        if (value == 'Day Surgery') {
            return 'Surgical Day Care' + '-' + yearSTR;
        }
        if (value == 'Acute Care') {
            return 'Acute' + '-' + yearSTR;
        }
        return value + '-' + yearSTR;
    }

     /**
     * Builds the service type product value based on care level, year, and site code.
     */
    private static String returnServiceTypeProduct(String value, Date admissionDate, String siteCode) {
        String yearSTR = String.valueOf(admissionDate.year());
        If(admissionDate.month() > 3){
            yearSTR = String.valueOf(admissionDate.year() + 1);
        }
              
        if (value == 'Day Surgery') {
            return 'Surgical Day Care' + '-' + yearSTR;
        }
        if (value == 'Acute Care') {
            return siteCode + '-' + 'Acute' + '-' + yearSTR;
        }
        return value + '-' + yearSTR;
    }
    
	/**
     * Safely converts a string date into an Apex Date.
     * Handles values that include a time portion.
     */
    private static Date parseDate(String value) {
        if (String.isBlank(value)) return null;
        if (value.contains('T')) value = value.substring(0, 10);
        return Date.valueOf(value);
    }
    
     /**
     * Safely converts a string into a Decimal.
     */
    private static Decimal parseDecimal(String value) {
        if (String.isBlank(value)) return null;
        return Decimal.valueOf(value);
    }
    
    
    /**
     * Checks whether the batch job is still running.
     */
    @AuraEnabled(cacheable=false)
    public static Boolean isBatchInProgress(Id batchId) {
        AsyncApexJob job = [
            SELECT Status
            FROM AsyncApexJob
            WHERE Id = :batchId
            LIMIT 1
        ];
    
        return job.Status == 'Queued'
            || job.Status == 'Preparing'
            || job.Status == 'Processing';
    }

    // Truncates incoming string values to the specified max length to prevent insert errors.
    private static String truncateIncomingFieldValueToMax(String value, Integer maxLength) {
        if (value == null) {
            return null;
        }
        if (value.length() <= maxLength) {
            return value;
        }
        String truncatedValue = value.left(maxLength);
        
        return truncatedValue;
    }
}