public without sharing class HealthIdeasApiIntegration {
    public class IntegrationResult {
        @AuraEnabled public Boolean success = false;
        @AuraEnabled public String rawResponse;
        @AuraEnabled public List<String> messages = new List<String>();

        @AuraEnabled public Boolean mspTransactionsComplete = false;
        @AuraEnabled public Boolean hospitalTransactionsComplete = false;
        @AuraEnabled public Boolean pharmacareTransactionsComplete = false;

        @AuraEnabled public List<Id> deletedMspIds = new List<Id>();
        @AuraEnabled public List<Id> deletedHospitalIds = new List<Id>();
        @AuraEnabled public List<Id> deletedPharmacareIds = new List<Id>();

        @AuraEnabled public List<Id> createdMspIds = new List<Id>();
        @AuraEnabled public List<Id> createdHospitalIds = new List<Id>();
        @AuraEnabled public List<Id> createdPharmacareIds = new List<Id>();

        @AuraEnabled public String errorMessage;
    }

    public class HealthIdeasResponse {
        public HealthIdeasContent content;
        public String error;
        public Boolean success;
        public String responseDateTime;
    }

    public class HealthIdeasContent {
        public List<PharmacareItem> pharmacare;
        public List<HospitalItem> hospitalizations;
        public List<MspItem> msp;
    }

    public class MspItem {
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
        public String costType;
        public String encounterId;
    }

    public class HospitalItem {
        public String phn;
        public String dateOfAdmission;
        public String dateOfDischarge;
        public String noOfDays;
        public String facilityCode;
        public String facility;
        public String careLevelGroup;
        public String careLevelCode;
        public String careLevel;
        public String locationOfIncident;
        public String descOfIncident;
        public String diagTreatmentSvcs;
        public String entryCode;
        public String entryCodeDescription;
        public String interventionCodesCci;
        public String costType;
        public String encounterId;
	}

    public class PharmacareItem {
        public String phn;
        public String din;
        public String nameOfDrug;
        public String dateOfService;
        public String practitionerId;
        public String practitionerFirstName;
        public String practitionerLastName;
        public String costOfDrug;
        public String costType;
        public String encounterId;
	}
    
    
    @AuraEnabled
	public static IntegrationResult callGetCost(Id accountId, Date asOfDate, String requesterUserName) {
        IntegrationResult result = new IntegrationResult();
    
        try {
            if (accountId == null) {
                throw new AuraHandledException('accountId is required.');
            }
            if (asOfDate == null) {
                throw new AuraHandledException('asOfDate is required.');
            }
            if (String.isBlank(requesterUserName)) {
                throw new AuraHandledException('requesterUserName is required.');
            }
    
            Account acc = [
                SELECT Id, PHN__pc
                FROM Account
                WHERE Id = :accountId
                LIMIT 1
            ];
    
            String personalHealthNumber = acc.PHN__pc;
            if (String.isBlank(personalHealthNumber)) {
                throw new AuraHandledException('Account.PHN__pc is blank.');
            }
    
            Map<String, Id> recordTypeIds = resolveRecordTypeIds();
    
          //  Date windowStart = asOfDate;
           // Date todayDate = Date.today();
    
            if (result.createdPharmacareIds == null) result.createdPharmacareIds = new List<Id>();
            if (result.createdHospitalIds == null) result.createdHospitalIds = new List<Id>();
            if (result.createdMspIds == null) result.createdMspIds = new List<Id>();
    
               // Date windowEnd = getFiveYearWindowEnd(windowStart, todayDate);
    
                HttpResponse mainRes = doHealthIdeasCallout(
                    requesterUserName,
                    personalHealthNumber,
                    asOfDate
                );
    
                result.rawResponse = mainRes.getBody();
    
                if (mainRes.getStatusCode() < 200 || mainRes.getStatusCode() > 299) {
                    throw new AuraHandledException(
                        'HealthIdeas callout failed. Status=' + mainRes.getStatusCode() +
                        ', Body=' + mainRes.getBody()
                    );
                }
    
                System.debug(mainRes.getBody());
    
                HealthIdeasResponse apiResponse =
                    (HealthIdeasResponse) JSON.deserialize(mainRes.getBody(), HealthIdeasResponse.class);
                System.debug(apiResponse);
    
                HealthIdeasContent content = apiResponse.content;
            
            
             result.deletedPharmacareIds = deleteExistingCosts(
                accountId,
                recordTypeIds.get('Pharmacare'),
                asOfDate,
                result.messages
            );
            result.deletedHospitalIds = deleteExistingCosts(
                accountId,
                recordTypeIds.get('Hospitalization'),
                asOfDate,
                result.messages
            );
            result.deletedMspIds = deleteExistingCosts(
                accountId,
                recordTypeIds.get('MSP'),
                asOfDate,
                result.messages
            );
    
             system.debug(content.pharmacare);
                if (content.pharmacare != null && !content.pharmacare.isEmpty()) {
                    List<Healthcare_Cost__c> pharmRecords = buildPharmacareRecords(
                        content.pharmacare,
                        accountId,
                        recordTypeIds.get('Pharmacare')
                    );
                    result.createdPharmacareIds.addAll(saveCosts(pharmRecords, result.messages));
                }
                result.pharmacareTransactionsComplete = true;
    
             system.debug(content.hospitalizations);
                if (content.hospitalizations != null && !content.hospitalizations.isEmpty()) {
                    List<Healthcare_Cost__c> hospitalRecords = buildHospitalRecords(
                        content.hospitalizations,
                        accountId,
                        recordTypeIds.get('Hospitalization')
                    );
                    result.createdHospitalIds.addAll(saveCosts(hospitalRecords, result.messages));
                }
                result.hospitalTransactionsComplete = true;
            
            system.debug(content.msp);
    
                if (content.msp != null && !content.msp.isEmpty()) {
                    List<Healthcare_Cost__c> mspRecords = buildMspRecords(
                        content.msp,
                        accountId,
                        recordTypeIds.get('MSP')
                    );
                    result.createdMspIds.addAll(saveCosts(mspRecords, result.messages));
                }
                result.mspTransactionsComplete = true;
    
            result.success = true;
            return result;
        
    
        } 
        catch (Exception e) {
            result.success = false;
            result.errorMessage = e.getMessage();
            result.messages.add(e.getMessage());
            system.debug(e.getMessage());
            return result;
        }
	}


    private static HttpResponse doHealthIdeasCallout( String requesterUserName,
                                                        String personalHealthNumber,
                                                        Date asOfDate
                                                     ) 
    {
        JWTGenerateAuth auth = new JWTGenerateAuth();
        JWTGenerateAuth.TokenResponse tokenRes = auth.getClientCredentialsToken();

        if (tokenRes == null || String.isBlank(tokenRes.access_token)) {
            throw new AuraHandledException('No access token returned from JWTGenerateAuth.');
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://moh-dms-m-prd-api.azure-api.net/api/tplprd/getCost/');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + tokenRes.access_token);
        req.setTimeout(120000);

        Map<String, Object> requestBody = new Map<String, Object>{
            'requester' => requesterUserName,
            'personalHealthNumber' => personalHealthNumber,
            'asOfDate' => String.valueOf(asOfDate)
        };

        req.setBody(JSON.serialize(requestBody));

        Http http = new Http();
        return http.send(req);
    }

    private static Map<String, Id> resolveRecordTypeIds() {
        Map<String, Schema.RecordTypeInfo> byDevName =
            Healthcare_Cost__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();

        return new Map<String, Id>{
            'MSP' => byDevName.get('MSP').getRecordTypeId(),
            'Pharmacare' => byDevName.get('Pharmacare').getRecordTypeId(),
            'Hospitalization' => byDevName.get('Hospitalization').getRecordTypeId()
        };
    }

    private static List<Id> deleteExistingCosts(Id accountId, Id recordTypeId, Date asOfDate, List<String> messages) {
        List<Id> idsToDelete = new List<Id>();

        List<Healthcare_Cost__c> existingRows = [
            SELECT Id
            FROM Healthcare_Cost__c
            WHERE Account__c = :accountId
              AND RecordTypeId = :recordTypeId
              AND Date_of_Service__c < :asOfDate
              AND Cost_Review__c = false
              AND Cost_Include__c = false
              AND (Case2__c = null OR Case2__c = '')
        ];

        for (Healthcare_Cost__c row : existingRows) {
            idsToDelete.add(row.Id);
        }

        if (!idsToDelete.isEmpty()) {
            Database.DeleteResult[] deleteResults = Database.delete(idsToDelete, false);
            for (Integer i = 0; i < deleteResults.size(); i++) {
                if (!deleteResults[i].isSuccess()) {
                    for (Database.Error err : deleteResults[i].getErrors()) {
                        messages.add('Delete failed for Healthcare_Cost__c Id ' + String.valueOf(idsToDelete[i]) + ': ' + err.getMessage());
                    }
                }
            }
        }

        return idsToDelete;
    }

    private static List<Id> saveCosts(List<Healthcare_Cost__c> rows, List<String> messages) {
        List<Id> savedIds = new List<Id>();
        if (rows == null || rows.isEmpty()) {
            return savedIds;
        }

        Database.SaveResult[] results = Database.insert(rows, false);
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                savedIds.add(results[i].getId());
            } else {
                for (Database.Error err : results[i].getErrors()) {
                    messages.add('Save failed for Healthcare_Cost__c row ' + i + ': ' + err.getMessage());
                }
            }
        }

        return savedIds;
    }

    private static List<Healthcare_Cost__c> buildMspRecords(List<MspItem> items, Id accountId, Id recordTypeId) {
        List<Healthcare_Cost__c> rows = new List<Healthcare_Cost__c>();

        for (MspItem item : items) {
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
            row.Fee_Item_Description__c = item.feeItemDesc;

            row.Practitioner_Name__c = item.practitionerName;
            row.Practitioner_Number__c = item.practitionerNbr;
            row.Payee_Number__c = item.payeeNbr;
            row.Payee_Description__c = item.payeeDesc;

            row.Location_Type_Code__c = item.locationTypeCode;
            row.Location_Type_Description2__c = item.locationTypeDesc;

            row.Amount_Paid__c = parseDecimal(item.amtPaid);
            row.Specialty_Code__c = item.specialtyCode;
            row.Specialty_Description2__c = item.specialtyDesc;

           // row.Facility__c = item.facility;
            row.Site_Code__c = item.facilityCode;
            row.Facility_Type__c = item.facilityType;

            rows.add(row);
        }

        return rows;
    }

    private static List<Healthcare_Cost__c> buildHospitalRecords(List<HospitalItem> items, Id accountId, Id recordTypeId) {
        List<Healthcare_Cost__c> rows = new List<Healthcare_Cost__c>();

        for (HospitalItem item : items) {
            System.debug('Hospital item = ' + JSON.serialize(item));
        
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
        
            // Only set this if your target field is supposed to store encounter id
            row.Source_System_ID__c = item.encounterId;
        
            rows.add(row);
        }
        return rows;
    }

    private static List<Healthcare_Cost__c> buildPharmacareRecords(List<PharmacareItem> items, Id accountId, Id recordTypeId) {
        List<Healthcare_Cost__c> rows = new List<Healthcare_Cost__c>();

          for (PharmacareItem item : items) {
                System.debug('Pharmacare item = ' + JSON.serialize(item));
        
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

    private static String normalizeHospitalServiceType(String value) {
          
        if (value == 'Day Surgery') {
            return 'Surgical Day Care';
        }
        if (value == 'Acute Care') {
            return 'Acute';
        }
        return value;
    }

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

    private static Date parseDate(String value) {
        if (String.isBlank(value)) {
            return null;
        }
        String s = value;
        if (s.contains('T')) {
            s = s.substring(0, 10);
        }
        return Date.valueOf(s);
    }

    private static Decimal parseDecimal(String value) {
        if (String.isBlank(value)) {
            return null;
        }
        return Decimal.valueOf(value);
    }
}