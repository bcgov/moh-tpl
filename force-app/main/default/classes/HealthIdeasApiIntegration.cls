/**
* Author: Nikhil Jeenru 
* Company : CGI
* Purpose:
* This class handles the HealthIdeas API integration, prepares the response data,
* and starts the batch process that refreshes Healthcare Cost records on the Person Accounts.
*/

public with sharing class HealthIdeasApiIntegration {

    private static final Boolean ENABLE_DEBUG_LOGS = false;
    
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
    public static IntegrationResult getHealthcareCostsForAccountandSetDate(
        Id accountId,
        Date asOfDate,
        Boolean isASyncCall
    ) {
        String requesterUserName = UserInfo.getUserEmail();
        IntegrationResult result = new IntegrationResult();
        Date endDate = Date.today();
        
        if (isASyncCall == true) {
            
            
            Id batchId = Database.executeBatch(
                new HealthIdeasHCCRecordsDeleteBatch(
                    accountId,
                    asOfDate,
                    requesterUserName),
                200
            );
            
            LogService.initializeAsyncStatus(
                batchId,
                calculateFiveYearChunkCount(asOfDate, endDate),
                'HealthIdeasApiIntegration',
                'getHealthcareCostsForAccountandSetDate'
            );  
            
            result.batchId = batchId;
            result.success = true; 
            return result;
            
        } else {
            return fetchHealthcareCosts(accountId, asOfDate, endDate, requesterUserName);
        } 
    }
    /**
* Main integration method.
* - Gets the member PHN from Account
* - Calls HealthIdeas API
* - Combines returned datasets
* - Starts the delete/Insert batch job
*/
    public static IntegrationResult fetchHealthcareCosts(Id accountId, Date asOfDate, Date endDate, String requesterUserName) {
        
        IntegrationResult result = new IntegrationResult();
        Integer retryCount = 0;

        /*
        Retry Mechanism for handling timeouts exceptions. 
        If the callout fails due to a timeout, it will retry up to MAX_ATTEMPTS times.
        */
        while (retryCount < TPL_Constants.MAX_ATTEMPTS) {
            try {
                Account acc = [SELECT Id, PHN__pc FROM Account WHERE Id = :accountId LIMIT 1];
                
                HttpResponse res = sendHealthIdeasRequest(requesterUserName, acc.PHN__pc, asOfDate, endDate);
                
                debugLog('Response Status Code: ' + res.getStatusCode());
                debugLog('Response Status: ' + res.getStatus());

                if (res.getStatusCode() != 200) {
                    result.success = false;
                    result.errorMessage = TPL_Constants.ERROR_HEALTH_IDEAS_API_CALLOUT_FAILED + res.getStatus();
                    return result;
                }

                String responseBody = res.getBody();
                
                Map<String, Id> hccrecordTypeIds = getHealthcareCostRecordTypeIds();

                HealthIdeasBatchPayload payload = parseHealthIdeasPayload(responseBody);
                
                refreshHealthcareCostRecords(
                    accountId,
                    asOfDate,
                    payload,
                    hccrecordTypeIds,
                    result.messages
                );
                result.success = true;
                return result;
            } 
            catch (Exception e) {
                retryCount++;
                if (!e.getMessage().contains(TPL_Constants.TIMEOUT_ERROR_MESSAGE) || retryCount >= TPL_Constants.MAX_ATTEMPTS) {
                    result.success = false;
                    result.errorMessage = e.getMessage();
                    return result;
                }
            }
        }

        // Fallback return in case the retry loop exits without returning.
        result.success = false;
        result.errorMessage =  TPL_Constants.TIMEOUT_ERROR_MESSAGE;
        return result;
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
                recordTypeIds.get(TPL_Constants.HCC_PHARMA_RECORDTYPE_NAME),
                    recordTypeIds.get(TPL_Constants.HCC_HOSP_RECORDTYPE_NAME),
                    recordTypeIds.get(TPL_Constants.HCC_MSP_RECORDTYPE_NAME)
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
        
            Map<String, List<Healthcare_Cost__c>> recordsToInsertByType = new Map<String, List<Healthcare_Cost__c>>();

            if (!mspList.isEmpty()) {
                recordsToInsertByType.put(
                    TPL_Constants.HCC_MSP_RECORDTYPE_NAME,
                    HealthIdeasApiIntegration.buildMspHealthcareCostRecords(
                        mspList,
                        accountId,
                        recordTypeIds.get(TPL_Constants.HCC_MSP_RECORDTYPE_NAME)
                    )
                );
            }

            if (!hospList.isEmpty()) {
                recordsToInsertByType.put(
                    TPL_Constants.HCC_HOSP_RECORDTYPE_NAME,
                    HealthIdeasApiIntegration.buildHospitalizationHealthcareCostRecords(
                        hospList,
                        accountId,
                        recordTypeIds.get(TPL_Constants.HCC_HOSP_RECORDTYPE_NAME)
                    )
                );
            }

            if (!pharmaList.isEmpty()) {
                recordsToInsertByType.put(
                    TPL_Constants.HCC_PHARMA_RECORDTYPE_NAME,
                    HealthIdeasApiIntegration.buildPharmacareHealthcareCostRecords(
                        pharmaList,
                        accountId,
                        recordTypeIds.get(TPL_Constants.HCC_PHARMA_RECORDTYPE_NAME)
                    )
                );
            }

            for (String hccType : recordsToInsertByType.keySet()) {
                List<Healthcare_Cost__c> recordsToInsert = recordsToInsertByType.get(hccType);

                if (recordsToInsert == null || recordsToInsert.isEmpty()) {
                    continue;
                }

                Database.SaveResult[] insertResults = Database.insert(recordsToInsert, false);
                Set<String> affectedDates = new Set<String>();

                for (Integer i = 0; i < insertResults.size(); i++) {
                    if (!insertResults[i].isSuccess()) {
                        Healthcare_Cost__c failedRecord = recordsToInsert[i];

                        for (Database.Error err : insertResults[i].getErrors()) {
                            if (err.getStatusCode() != StatusCode.DUPLICATE_VALUE) {
                                Date affectedDate = failedRecord.Date_of_Admission__c != null
                                    ? failedRecord.Date_of_Admission__c
                                    : failedRecord.Date_of_Service__c;

                                String formattedDate = HealthIdeasApiIntegration.formatDateForDisplay(affectedDate);
                                if (formattedDate != null) {
                                    affectedDates.add(formattedDate);
                                }
                            }
                        }
                    }
                }

                for (String affectedDate : affectedDates) {
                    messages.add(
                        Label.TPL_HI_Record_ErrorMessage + ' ' + hccType + ' records for ' + affectedDate
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
            TPL_Constants.HCC_MSP_RECORDTYPE_NAME => rtMap.get(TPL_Constants.HCC_MSP_RECORDTYPE_NAME).getRecordTypeId(),
                TPL_Constants.HCC_PHARMA_RECORDTYPE_NAME => rtMap.get(TPL_Constants.HCC_PHARMA_RECORDTYPE_NAME).getRecordTypeId(),
                TPL_Constants.HCC_HOSP_RECORDTYPE_NAME => rtMap.get(TPL_Constants.HCC_HOSP_RECORDTYPE_NAME).getRecordTypeId()
                };
                    }
    
    public static HealthIdeasBatchPayload parseHealthIdeasPayload(String responseBody) {
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
                
                if (fieldName == TPL_Constants.HCC_MSP_RECORDTYPE_NAME.toLowerCase()) {
                    payload.msp =
                        (List<MspHccRecord>) parser.readValueAs(
                            List<MspHccRecord>.class
                        );
                    
                } else if (fieldName == TPL_Constants.RESPONSE_HOSPITALIZATIONS.toLowerCase()) {
                    payload.hospitalizations =
                        (List<HospitalizationHccRecord>) parser.readValueAs(
                            List<HospitalizationHccRecord>.class
                        );
                    
                } else if (fieldName == TPL_Constants.HCC_PHARMA_RECORDTYPE_NAME.toLowerCase()) {
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
    public static HttpResponse sendHealthIdeasRequest(String requesterUserName, String phn, Date asOfDate, Date endDate) {
        
        Integer timeValue = getTimeOutInteger(TPL_Constants.HI_BATCH_CONFIGURATION_RECORD_NAME, TPL_Constants.TIMEOUT_FIELD_NAME);
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:HealthIdeas');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(timeValue);
        system.debug(timeValue);
        req.setBody(JSON.serialize(new Map<String, Object>{
            'requester' => requesterUserName,
                'personalHealthNumber' => phn,
                'asOfDate' => String.valueOf(asOfDate),
                'endDate' => String.valueOf(endDate)
                }));
        
        return new Http().send(req);
    }


    /**
* Builds Healthcare Cost records for MSP data.
*/
    public static List<Healthcare_Cost__c> buildMspHealthcareCostRecords(List<MspHccRecord> items, Id accountId, Id recordTypeId) {
        List<Log__c> logsToInsert = new List<Log__c>();
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

            row.Diagnostic_Code__c = truncateIncomingFieldValueToMax(item.diagnosticCode, 50, 'Diagnostic_Code__c', item.encounterId, logsToInsert);
            row.Diagnostic_Code_1__c = truncateIncomingFieldValueToMax(item.diagnosticCode1, 50, 'Diagnostic_Code_1__c', item.encounterId, logsToInsert);
            row.Diagnostic_Code_2__c = truncateIncomingFieldValueToMax(item.diagnosticCode2, 50, 'Diagnostic_Code_2__c', item.encounterId, logsToInsert);
            row.Diagnostic_Code_3__c = truncateIncomingFieldValueToMax(item.diagnosticCode3, 50, 'Diagnostic_Code_3__c', item.encounterId, logsToInsert);

            row.Diagnostic_Description__c = truncateIncomingFieldValueToMax(item.diagnosticDesc, 255, 'Diagnostic_Description__c', item.encounterId, logsToInsert);
            row.Diagnostic_Description_1__c = truncateIncomingFieldValueToMax(item.diagnosticDesc1, 255, 'Diagnostic_Description_1__c', item.encounterId, logsToInsert);
            row.Diagnostic_Description_2__c = truncateIncomingFieldValueToMax(item.diagnosticDesc2, 255, 'Diagnostic_Description_2__c', item.encounterId, logsToInsert);
            row.Diagnostic_Description_3__c = truncateIncomingFieldValueToMax(item.diagnosticDesc3, 255, 'Diagnostic_Description_3__c', item.encounterId, logsToInsert);

            row.Description_of_Service2__c = truncateIncomingFieldValueToMax(item.descOfSvc, 255, 'Description_of_Service2__c', item.encounterId, logsToInsert);
            row.Fee_Item_Code__c = truncateIncomingFieldValueToMax(item.feeItemCode, 20, 'Fee_Item_Code__c', item.encounterId, logsToInsert);
            row.Fee_Item_Title__c = truncateIncomingFieldValueToMax(item.feeItemTitle, 80, 'Fee_Item_Title__c', item.encounterId, logsToInsert);
            row.Fee_Item_Description__c = truncateIncomingFieldValueToMax(item.feeItemDesc, 255, 'Fee_Item_Description__c', item.encounterId, logsToInsert);

            row.Practitioner_Name__c = truncateIncomingFieldValueToMax(item.practitionerName, 120, 'Practitioner_Name__c', item.encounterId, logsToInsert);
            row.Practitioner_Number__c = truncateIncomingFieldValueToMax(item.practitionerNbr, 40, 'Practitioner_Number__c', item.encounterId, logsToInsert);
            row.Payee_Number__c = truncateIncomingFieldValueToMax(item.payeeNbr, 40, 'Payee_Number__c', item.encounterId, logsToInsert);
            row.Payee_Description__c = truncateIncomingFieldValueToMax(item.payeeDesc, 255, 'Payee_Description__c', item.encounterId, logsToInsert);

            row.Location_Type_Code__c = truncateIncomingFieldValueToMax(item.locationTypeCode, 100, 'Location_Type_Code__c', item.encounterId, logsToInsert);
            row.Location_Type_Description2__c = truncateIncomingFieldValueToMax(item.locationTypeDesc, 100, 'Location_Type_Description2__c', item.encounterId, logsToInsert);

            row.Amount_Paid__c = parseDecimal(item.amtPaid);
            row.Specialty_Code__c = truncateIncomingFieldValueToMax(item.specialtyCode, 40, 'Specialty_Code__c', item.encounterId, logsToInsert);
            row.Specialty_Description2__c = truncateIncomingFieldValueToMax(item.specialtyDesc, 50, 'Specialty_Description2__c', item.encounterId, logsToInsert);
            row.Site_Code__c = item.facilityCode;
            row.Facility_Type__c = truncateIncomingFieldValueToMax(item.facilityType, 30, 'Facility_Type__c', item.encounterId, logsToInsert);

            rows.add(row);
        }

        LogService.logErrors(logsToInsert);
        return rows;
    }
    
    /**
* Builds Healthcare Cost records for hospitalization data.
*/
    public static List<Healthcare_Cost__c> buildHospitalizationHealthcareCostRecords(List<HospitalizationHccRecord> items, Id accountId, Id recordTypeId) {
        List<Healthcare_Cost__c> rows = new List<Healthcare_Cost__c>();
        List<Log__c> logsToInsert = new List<Log__c>();

        for (HospitalizationHccRecord item : items) {
            Healthcare_Cost__c row = new Healthcare_Cost__c();
            row.Account__c = accountId;
            row.RecordTypeId = recordTypeId;
            row.PHN__c = item.phn;
            row.Date_of_Admission__c = parseDate(item.dateOfAdmission);
            row.Date_of_Discharge__c = parseDate(item.dateOfDischarge);
            row.Site_Code__c = item.facilityCode;

            row.Service_Type2__c = truncateIncomingFieldValueToMax(
                normalizeDatedHospitalServiceType(item.careLevel, row.Date_of_Admission__c),
                40,
                'Service_Type2__c',
                item.encounterId,
                logsToInsert
            );

            row.Service_Type__c = truncateIncomingFieldValueToMax(
                returnServiceTypeProduct(item.careLevel, row.Date_of_Admission__c, row.Site_Code__c),
                40,
                'Service_Type__c',
                item.encounterId,
                logsToInsert
            );

            row.Location_of_Incident__c = truncateIncomingFieldValueToMax(item.locationOfIncident, 50, 'Location_of_Incident__c', item.encounterId, logsToInsert);
            row.Description_of_Incident__c = truncateIncomingFieldValueToMax(item.descOfIncident, 100, 'Description_of_Incident__c', item.encounterId, logsToInsert);
            row.Diagnostic_Treatment_Service2__c = truncateIncomingFieldValueToMax(item.diagTreatmentSvcs, 100, 'Diagnostic_Treatment_Service2__c', item.encounterId, logsToInsert);
            row.Intervention_Code_CCI__c = truncateIncomingFieldValueToMax(item.interventionCodesCci, 255, 'Intervention_Code_CCI__c', item.encounterId, logsToInsert);
            row.Source_System_ID__c = item.encounterId;
        
            rows.add(row);
        }

        LogService.logErrors(logsToInsert);
        return rows;
    }

    /**
* Builds Healthcare Cost records for Pharmacare data.
*/
    public static List<Healthcare_Cost__c> buildPharmacareHealthcareCostRecords(List<PharmacareHccRecord> items, Id accountId, Id recordTypeId) {
        List<Healthcare_Cost__c> rows = new List<Healthcare_Cost__c>();
        List<Log__c> logsToInsert = new List<Log__c>();

        for (PharmacareHccRecord item : items) {
            Healthcare_Cost__c row = new Healthcare_Cost__c();
            row.Account__c = accountId;
            row.RecordTypeId = recordTypeId;
            row.PHN__c = item.phn;
            row.Source_System_ID__c = item.encounterId;
            row.Date_of_Service__c = parseDate(item.dateOfService);
            row.Name_of_Drug__c = truncateIncomingFieldValueToMax(item.nameOfDrug, 80, 'Name_of_Drug__c', item.encounterId, logsToInsert);
            row.Cost_of_Drug__c = parseDecimal(item.costOfDrug);
            row.DIN__c = truncateIncomingFieldValueToMax(item.din, 80, 'DIN__c', item.encounterId, logsToInsert);

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

            row.Practitioner_Name__c = truncateIncomingFieldValueToMax(fullName, 120, 'Practitioner_Name__c', item.encounterId, logsToInsert);
            row.Practitioner_First_Name__c = truncateIncomingFieldValueToMax(item.practitionerFirstName, 120, 'Practitioner_First_Name__c', item.encounterId, logsToInsert);
            row.Practitioner_Last_Name__c = truncateIncomingFieldValueToMax(item.practitionerLastName, 120, 'Practitioner_Last_Name__c', item.encounterId, logsToInsert);

            rows.add(row);
        }

        LogService.logErrors(logsToInsert);
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
        
        if (value == TPL_Constants.SERVICE_TYPE_DAY_SURGERY) {
            return TPL_Constants.SERVICE_TYPE_SURGICAL_DAY_CARE + '-' + yearSTR;
        }
        if (value == TPL_Constants.SERVICE_TYPE_ACUTE_CARE) {
            return TPL_Constants.SERVICE_TYPE_ACUTE + '-' + yearSTR;
        }
        return value + '-' + yearSTR;
    }
    
    /**
* Builds the service type product value based on care level, year, and site code.
*/
    private static String returnServiceTypeProduct(String value, Date admissionDate, String siteCode) {

        if (admissionDate == null) {
            return null;
        }
        String yearSTR = String.valueOf(admissionDate.year());
        
        If(admissionDate.month() > 3){
            yearSTR = String.valueOf(admissionDate.year() + 1);
        }
        
        if (value == TPL_Constants.SERVICE_TYPE_DAY_SURGERY) {
            return TPL_Constants.SERVICE_TYPE_SURGICAL_DAY_CARE + '-' + yearSTR;
        }
        if (value == TPL_Constants.SERVICE_TYPE_ACUTE_CARE) {
            return siteCode + '-' + TPL_Constants.SERVICE_TYPE_ACUTE + '-' + yearSTR;
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
* Calculates the total number of HealthIdeas date chunks required between the
* selected as-of date and the final end date(Current Day).
* The chunk size is currently five year.
*/
    public static Integer calculateFiveYearChunkCount(Date asOfDate, Date finalEndDate) {
        Integer count = 0;
        Date currentAsOfDate = asOfDate;
        Integer batchSize = getHealthIdeasBatchSize();
        
        while (currentAsOfDate <= finalEndDate) {
            Date currentEndDate = currentAsOfDate.addYears(batchSize);
            
            if (currentEndDate > finalEndDate) {
                currentEndDate = finalEndDate;
            }
            
            count++;
            
            if (currentEndDate == finalEndDate) {
                break;
            }
            
            currentAsOfDate = currentEndDate;
        }
        
        return count;
    }
    
    /**
* Returns the end date for the current HealthIdeas API chunk.
* The chunk size is controlled by the HealthIdeas Batch Configuration
* custom metadata record.
*/
    public static Date getHealthIdeasChunkEndDate(Date asOfDate) {
        Integer batchSize = getHealthIdeasBatchSize();
        
        Date currentEndDate =
            asOfDate.addYears(batchSize);
        
        if (currentEndDate > Date.today()) {
            currentEndDate = Date.today();
        }
        
        return currentEndDate;
    }
    
    /**
* Returns the HealthIdeas batch chunk size from the HealthIdeas Batch Configuration
* custom metadata record.
*/
    public static Integer getHealthIdeasBatchSize() {
        HealthIdeas_Batch_Configuration__mdt config =
            HealthIdeas_Batch_Configuration__mdt.getInstance(
                TPL_Constants.HI_BATCH_CONFIGURATION_RECORD_NAME
            );
        
        return Integer.valueOf(config.Batch_Size__c);
    }
    
    
    /**
* Truncates the incoming value if it exceeds the max allowed length.
* Logs when truncation occurs.
*/
    
    private static String truncateIncomingFieldValueToMax(
        String value,
        Integer maxLength,
        String fieldName,
        String sourceSystemId,
        List<Log__c> logsToInsert
    ) {
        if (value == null) {
            return null;
        }

        if (value.length() <= maxLength) {
            return value;
        }
        
        String truncatedValue = value.left(maxLength);
        
        logsToInsert.add(
            LogService.buildLog(
                TPL_Constants.CLASS_HEALTH_IDEAS_API_INTEGRATION,
                'truncateIncomingFieldValueToMax',
                'Value truncated for Healthcare_Cost__c.' + fieldName +
                ' for Source_System_ID__c=' + sourceSystemId +
                ' from ' + value.length() +
                ' to ' + maxLength + ' characters.',
                null
            )
        );
        
        return truncatedValue;
    }


    // Get max timeout value set from the custom metadata records.
    private static Integer getTimeOutInteger(String metadataRecordName, String fieldName) 
    {
        HealthIdeas_Batch_Configuration__mdt config =
            HealthIdeas_Batch_Configuration__mdt.getInstance(metadataRecordName);

        return config != null && config.get(fieldName) != null
            ? Integer.valueOf(String.valueOf(config.get(fieldName)))
            : TPL_Constants.DEFAULT_TIMEOUT_VALUE;
    }

    // Format date for UI Display
    public  static String formatDateForDisplay(Date affectedDate) {
        if (affectedDate == null) {
            return null;
        }

        return DateTime.newInstance(affectedDate, Time.newInstance(0, 0, 0, 0))
            .format('MMMM d, yyyy');
   }
}