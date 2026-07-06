/**
* Author: Nikhil Jeenru
* Company: CGI
* Purpose:
* Routes document generation requests between synchronous, asynchronous, and section ZIP flows.
*/
public with sharing class DocxGeneratorController {
    @TestVisible
    private static Integer testTotalPrintableRows;
    private static Document_Generation_Configuration__mdt cachedDocumentGenerationConfiguration;
    
    /**
Params: Id caseId, String selectedTemplate
* Generates the selected document and returns a ContentDocumentId or async job response.
*/
    @AuraEnabled
    public static String generateDocument(Id caseId, String selectedTemplate) {
        try {
            Integer totalPrintableRows;
            
            if (Test.isRunningTest() && testTotalPrintableRows != null) {
                totalPrintableRows = testTotalPrintableRows;
            } else {
                totalPrintableRows = getEligibleHccCountForPrint(caseId);
            }
            
            if (totalPrintableRows <=  getSyncPrintableHccRowLimit()) {
                return generateSingleDocxFileSyncProcess(caseId, selectedTemplate);
            } else if (totalPrintableRows <= getAsyncSingleDocPrintableHccRowLimit()) {
                String jobId = enqueueSingleDocxGenerationAsyncProcess(caseId, selectedTemplate);
                return asyncResponse(jobId);
            } else {
                String jobId = enqueueSectionsForZipFileGenerationAsync(caseId, selectedTemplate);
                writeGenerationLog(caseId, jobId, TPL_Constants.STATUS_PROCESSING, null);
                return asyncResponse(jobId);
            }
            
        } catch (Exception e) {
            throw new AuraHandledException('Certificate generation failed: ' + e.getMessage());
        }
    }
    
    
    /**
* Reads the sync printable row limit from document generation configuration. Returns 1000 when the configuration value is not available.
*/
    public static Integer getSyncPrintableHccRowLimit() {
        Document_Generation_Configuration__mdt config = getDocumentGenerationConfiguration();
        return config == null || config.Sync_Printable_Row_Limit__c == null ? 1000 : Integer.valueOf(config.Sync_Printable_Row_Limit__c);
    }
    
    /**
* Reads the async printable row limit from document generation configuration. Returns 40000 when the configuration value is not available.
*/
    public static Integer getAsyncSingleDocPrintableHccRowLimit() {
        Document_Generation_Configuration__mdt config = getDocumentGenerationConfiguration();
        return config == null || config.Async_Printable_Row_Limit__c == null ? 40000 : Integer.valueOf(config.Async_Printable_Row_Limit__c);
    }
    
    /**
* Loads the default document generation configuration and returns the cached metadata record after the first lookup.
*/
    private static Document_Generation_Configuration__mdt getDocumentGenerationConfiguration() {
        if (cachedDocumentGenerationConfiguration == null) {
            cachedDocumentGenerationConfiguration = Document_Generation_Configuration__mdt.getInstance('Document_Generation_Configuration');
        }
        return cachedDocumentGenerationConfiguration;
    }
    
    /**
Params: Id recordId, String selectedTemplate
* Generates a DOCX synchronously and saves it. Returns the created ContentDocumentId as text.
*/
    public static String generateSingleDocxFileSyncProcess(Id recordId, String selectedTemplate) {
        return generateSingleDocxSyncProcess(recordId, selectedTemplate);
    }
    
    /**
Params: Id recordId, String selectedTemplate
* Generates a single DOCX synchronously or starts async generation when row limits require it. Returns the ContentDocumentId or async response text.
*/
    public static String generateSingleDocxSyncProcess(Id recordId, String selectedTemplate) {
        Case caseRecord = loadCaseForDocgen(recordId);
        List<TPL_DocGen_Signature__c> sigs = loadSigningAuthorities();
        String sigName  = sigs.isEmpty() ? '' : sigs[0].Name__c;
        String sigTitle = sigs.isEmpty() ? '' : sigs[0].Title__c;
        
        DocxBuilder builder = new DocxBuilder()
            .setCaseData(caseRecord)
            .setSigningAuthority(sigName, sigTitle)
            .setDocumentType(selectedTemplate);
        
        populateHealthcareCostSections(builder, recordId);
        
        Blob docxBlob = builder.build();
        String fileName = DocxFormatHelper.generatedFileName(selectedTemplate, 'docx');
        return String.valueOf(DocxFormatHelper.createContentDocument(recordId, fileName, docxBlob, null));
    }
    
    /**
Params: Id recordId
* Loads the Case and related fields needed for DOCX generation. Returns the matching Case record.
*/
    private static Case loadCaseForDocgen(Id recordId) {
        return [
            SELECT CaseNumber, Claim_Number__c, ContactName__c, PHN__c,
            Date_of_Birth__c, Incident_Date__c, Total_Case_Value__c,
            Ambulance_Total2__c, Hospitalization_Total2__c, MSP_Total2__c,
            Pharmacare_Total2__c, Continuing_Care_Total2__c, Future_Care_Total2__c
            FROM Case WHERE Id = :recordId LIMIT 1
        ];
    }
    
    /**
* Loads active DOCX signing authorities. Returns the matching TPL_DocGen_Signature__c records.
*/
    private static List<TPL_DocGen_Signature__c> loadSigningAuthorities() {
        return [
            SELECT Name__c, Title__c FROM TPL_DocGen_Signature__c
            WHERE Name = :TPL_Constants.TPL_DOCGEN_SIGNATURE_PROFILE_NAME LIMIT 1
        ];
    }
    
    /**
Params: DocxBuilder builder, Id recordId
* Loads Healthcare Cost records into the matching DOCX sections.
*/
    private static void populateHealthcareCostSections(DocxBuilder builder, Id recordId) {
        List<Healthcare_Cost__c> ambulanceRecs = [
            SELECT Date_of_Service__c, Location_Responded__c,
            FacilityName__c, Facility_Name__c, Total_Cost_Override__c
            FROM Healthcare_Cost__c
            WHERE Case2__c = :recordId AND RecordTypeName__c = :TPL_Constants.HCC_AMB_RECORDTYPE_NAME
            AND Cost_Include__c = true AND Cost_Review__c = true
            ORDER BY Date_of_Service__c ASC
        ];
        builder.setAmbulanceRecords(ambulanceRecs);
        ambulanceRecs.clear();
        
        List<Healthcare_Cost__c> hospitalRecs = [
            SELECT Date_of_Admission__c, Date_of_Discharge__c,
            FacilityName__c, Facility_Name__c, Service_Type2__c,
            Number_of_Days__c, Total_Cost_Override__c, Total_Costs_Standard__c
            FROM Healthcare_Cost__c
            WHERE Case2__c = :recordId AND RecordTypeName__c = :TPL_Constants.HCC_HOSP_RECORDTYPE_NAME
            AND Cost_Include__c = true AND Cost_Review__c = true
            ORDER BY Date_of_Admission__c ASC
        ];
        builder.setHospitalRecords(hospitalRecs);
        hospitalRecs.clear();
        
        List<Healthcare_Cost__c> mspRecs = [
            SELECT Date_of_Service__c, Location_Type_Code__c,
            Location_Type_Description2__c, Description_of_Service2__c,
            Fee_Item_Title__c, Diagnostic_Description__c,
            Total_Cost_Override__c, Practitioner_Name__c
            FROM Healthcare_Cost__c
            WHERE Case2__c = :recordId AND RecordTypeName__c = :TPL_Constants.HCC_MSP_RECORDTYPE_NAME
            AND Cost_Include__c = true AND Cost_Review__c = true
            ORDER BY Date_of_Service__c ASC
        ];
        builder.setMSPRecords(mspRecs);
        mspRecs.clear();
        
        List<Healthcare_Cost__c> pharmaRecs = [
            SELECT Date_of_Service__c, Name_of_Drug__c,
            Total_Cost_Override__c, Practitioner_Name__c
            FROM Healthcare_Cost__c
            WHERE Case2__c = :recordId AND RecordTypeName__c = :TPL_Constants.HCC_PHARMA_RECORDTYPE_NAME
            AND Cost_Include__c = true AND Cost_Review__c = true
            ORDER BY Date_of_Service__c ASC
        ];
        builder.setPharmaRecords(pharmaRecs);
        pharmaRecs.clear();
        
        List<Healthcare_Cost__c> ccRecs = [
            SELECT Description__c, Cost__c FROM Healthcare_Cost__c
            WHERE Case2__c = :recordId AND RecordTypeName__c = :TPL_Constants.HCC_CC_RECORDTYPE_NAME
        ];
        builder.setContinuingCareRecords(ccRecs);
        ccRecs.clear();
        
        List<Healthcare_Cost__c> fcRecs = [
            SELECT Description__c, Cost__c FROM Healthcare_Cost__c
            WHERE Case2__c = :recordId AND RecordTypeName__c = :TPL_Constants.HCC_FC_RECORDTYPE_NAME
        ];
        builder.setFutureCareRecords(fcRecs);
        fcRecs.clear();
    }
    
    /**
Params: Id caseId, String selectedTemplate
* Enqueues async single DOCX generation. Returns the serialized async job response.
*/
    private static String enqueueSingleDocxGenerationAsyncProcess(Id caseId, String selectedTemplate) {
        Log__c logRecord = buildGenerationLog(caseId, null, TPL_Constants.STATUS_PROCESSING, null);
        LogService.upsertLogsInSystemMode(new List<SObject>{ logRecord });
        
        Id jobId = System.enqueueJob(new DocxGenerationAsyncQueueable(caseId, selectedTemplate, logRecord.Id));
        
        logRecord.JobId__c = String.valueOf(jobId);
        LogService.upsertLogsInSystemMode(new List<SObject>{ logRecord });
        
        return String.valueOf(jobId);
    }
    
    /**
Params: Id caseId, String selectedTemplate
* Enqueues async section DOCX generation for ZIP output. Returns the serialized async job response.
*/
    private static String enqueueSectionsForZipFileGenerationAsync(Id caseId, String selectedTemplate) {
        Case c = [SELECT CaseNumber FROM Case WHERE Id = :caseId LIMIT 1];
        List<TPL_DocGen_Signature__c> sigs = [
            SELECT Name__c, Title__c FROM TPL_DocGen_Signature__c
            WHERE Name = :TPL_Constants.TPL_DOCGEN_SIGNATURE_PROFILE_NAME LIMIT 1
        ];
        String sigName  = sigs.isEmpty() ? '' : sigs[0].Name__c;
        String sigTitle = sigs.isEmpty() ? '' : sigs[0].Title__c;
        
        Id jobId = System.enqueueJob(new DocxSectionQueueable(
            caseId,
            0,      // sectionIndex = 0 (Certificate summary)
            null,   // lastProcessedDateId
            1,      // chunkWithinSection
            DocxFormatHelper.stringValue(c.CaseNumber),
            sigName,
            sigTitle,
            selectedTemplate,
            new List<Id>()
        ));
        
        return String.valueOf(jobId);
    }
    
    /**
Params: Id caseId
* Counts eligible Healthcare Cost records for printing. Returns the eligible row count.
*/
    public static Integer getEligibleHccCountForPrint(Id caseId) {
        Set<String> includedReviewedRecordTypes = new Set<String>{
            TPL_Constants.HCC_AMB_RECORDTYPE_NAME,
                TPL_Constants.HCC_HOSP_RECORDTYPE_NAME,
                TPL_Constants.HCC_MSP_RECORDTYPE_NAME,
                TPL_Constants.HCC_PHARMA_RECORDTYPE_NAME
                };
                    Set<String> careRecordTypes = new Set<String>{
                        TPL_Constants.HCC_CC_RECORDTYPE_NAME,
                            TPL_Constants.HCC_FC_RECORDTYPE_NAME
                            };
                                return [
                                    SELECT COUNT()
                                    FROM Healthcare_Cost__c
                                    WHERE Case2__c = :caseId
                                    AND (
                                        (
                                            RecordTypeName__c IN :includedReviewedRecordTypes
                                            AND Cost_Include__c = true
                                            AND Cost_Review__c = true
                                        )
                                        OR
                                        RecordTypeName__c IN :careRecordTypes
                                    )
                                ];
    }
    
    @TestVisible
    /**
Params: Id caseId, String jobId, String status, String fileIdsOrMessage
* Writes the document generation status log.
*/
    private static void writeGenerationLog(Id caseId, String jobId, String status, String fileIdsOrMessage) {
        Log__c logRecord = buildGenerationLog(caseId, jobId, status, fileIdsOrMessage);
        LogService.upsertLogsInSystemMode(new List<SObject>{ logRecord });
    }
    
    /**
Params: Id caseId, String jobId, String status, String fileIdsOrMessage
* Builds the generation log record. Returns the unsaved Log__c record.
*/
    private static Log__c buildGenerationLog(Id caseId, String jobId, String status, String fileIdsOrMessage) {
        Log__c logRecord = new Log__c();
        logRecord.JobId__c = jobId;
        logRecord.Record_Id__c = String.valueOf(caseId);
        logRecord.Running_User__c = UserInfo.getUserId();
        logRecord.Class_Name__c = TPL_Constants.CLASS_DOCX_GENERATOR_CONTROLLER;
        logRecord.Method_Name__c = TPL_Constants.METHOD_GENERATE_DOCUMENT;
        logRecord.Status__c = status;
        logRecord.Error_Message__c = fileIdsOrMessage;
        return logRecord;
    }
    
    /**
Params: String jobId
* Builds the async response payload. Returns the serialized JSON response.
*/
    private static String asyncResponse(String jobId) {
        return DocgenConstants.ASYNC_RESPONSE_PREFIX + jobId;
    }
    
}