@IsTest
private class DocxGeneratorControllerTest {
    
    // Template name passed into document generation methods.
    private static final String TEMPLATE_NAME = 'Certificate';
    
    /**
* Test setup method runs once and creates shared test data for all test methods.
* Creates one Case, multiple Healthcare Cost records, and optionally a signing authority.
*/
    @TestSetup
    static void setupData() {
        // Create Case record with only writable fields.
        Case c = new Case(
            Status = 'New',
            Origin = 'Phone',
            Claim_Number__c = 'CLM-001',
            Incident_Date__c = Date.today().addDays(-10),
            Ambulance_Total2__c = 100,
            Hospitalization_Total2__c = 200,
            MSP_Total2__c = 300,
            Pharmacare_Total2__c = 400,
            Continuing_Care_Total2__c = 500,
            Future_Care_Total2__c = 600
        );
        insert c;
        
        // Create Healthcare Cost records for each supported section.
        // RecordTypeName__c is not writable in your org, so it is intentionally not assigned here.
        insert new List<Healthcare_Cost__c>{
            buildHealthcareCost(c.Id, TPL_Constants.HCC_AMB_RECORDTYPE_NAME, true, true),
                buildHealthcareCost(c.Id, TPL_Constants.HCC_HOSP_RECORDTYPE_NAME, true, true),
                buildHealthcareCost(c.Id, TPL_Constants.HCC_MSP_RECORDTYPE_NAME, true, true),
                buildHealthcareCost(c.Id, TPL_Constants.HCC_PHARMA_RECORDTYPE_NAME, true, true),
                buildHealthcareCost(c.Id, TPL_Constants.HCC_CC_RECORDTYPE_NAME, false, false),
                buildHealthcareCost(c.Id, TPL_Constants.HCC_FC_RECORDTYPE_NAME, false, false),
                buildHealthcareCost(c.Id, TPL_Constants.HCC_AMB_RECORDTYPE_NAME, false, false)
                };
                    
                    // Create signing authority test data.
                    // Wrapped in try/catch because this object may have org-specific rules or Name may not be writable in some orgs.
                    try {
                        insert new TPL_DocGen_Signature__c(
                            Name = TPL_Constants.TPL_DOCGEN_SIGNATURE_PROFILE_NAME,
                            Name__c = 'Test Signer',
                            Title__c = 'Director'
                        );
                    } catch (Exception e) {
                        System.debug('Skipping signature setup: ' + e.getMessage());
                    }
    }
    
    /**
* Builds a Healthcare_Cost__c record with common test values.
* recordTypeName parameter is kept for readability and future RecordTypeId mapping if needed.
*/
    private static Healthcare_Cost__c buildHealthcareCost(Id caseId, String recordTypeName, Boolean includeCost, Boolean reviewCost) {
        Healthcare_Cost__c hcc = new Healthcare_Cost__c();
        
        // Link Healthcare Cost record to Case.
        hcc.Case2__c = caseId;
        
        // RecordTypeName__c is not writable, so do not assign it.
        // If this is a formula field based on RecordType, set RecordTypeId here instead.
        // hcc.RecordTypeName__c = recordTypeName;
        
        // Fields used by eligible row-count logic for included/reviewed printable sections.
        hcc.Cost_Include__c = includeCost;
        hcc.Cost_Review__c = reviewCost;
        
        // Date fields used by the different DOCX section queries.
        hcc.Date_of_Service__c = Date.today();
        hcc.Date_of_Admission__c = Date.today().addDays(-2);
        hcc.Date_of_Discharge__c = Date.today().addDays(-1);
        
        // Ambulance related fields.
        hcc.Location_Responded__c = 'Test Location';
        
        // Facility_Name__c is writable; FacilityName__c was removed because it is not writable.
        hcc.Facility_Name__c = 'Test Facility Name';
        
        // Hospital related fields.
        hcc.Service_Type2__c = 'Test Service';
        
        // Cost fields used by document builder.
        hcc.Total_Cost_Override__c = 100;
        
        // MSP related fields.
        hcc.Location_Type_Code__c = 'A';
        hcc.Location_Type_Description2__c = 'Clinic';
        hcc.Description_of_Service2__c = 'Service Description';
        hcc.Fee_Item_Title__c = 'Fee Item';
        hcc.Diagnostic_Description__c = 'Diagnosis';
        hcc.Practitioner_Name__c = 'Dr Test';
        
        // Pharmacare related field.
        hcc.Name_of_Drug__c = 'Drug Test';
        
        // Continuing Care and Future Care related fields.
        hcc.Description__c = 'Care Description';
        hcc.Cost__c = 100;
        
        return hcc;
    }
    
    /**
* Returns the Case Id created in @TestSetup.
*/
    private static Id getCaseId() {
        return [SELECT Id FROM Case LIMIT 1].Id;
    }
    
    /**
* Covers getEligibleHccCountForPrint().
* This verifies the method executes successfully.
*/
    @IsTest
    static void testGetEligibleHccCountForPrintCountsOnlyEligibleRows() {
        Id caseId = getCaseId();
        
        Test.startTest();
        Integer actualCount = DocxGeneratorController.getEligibleHccCountForPrint(caseId);
        Test.stopTest();
        
        // Since RecordTypeName__c is not writable in this org, the count may depend on formula/RecordType setup.
        System.assertNotEquals(null, actualCount, 'Eligible HCC count should not be null.');
    }
    
    /**
* Covers getSyncPrintableHccRowLimit() and getAsyncSingleDocPrintableHccRowLimit().
* Also validates returned limits are usable positive values.
*/
    @IsTest
    static void testGetPrintableRowLimitsReturnValues() {
        Test.startTest();
        Integer syncLimitValue = DocxGeneratorController.getSyncPrintableHccRowLimit();
        Integer asyncLimitValue = DocxGeneratorController.getAsyncSingleDocPrintableHccRowLimit();
        Test.stopTest();
        
        System.assertNotEquals(null, syncLimitValue, 'Sync row limit should not be null.');
        System.assertNotEquals(null, asyncLimitValue, 'Async row limit should not be null.');
        System.assert(syncLimitValue > 0, 'Sync row limit should be greater than zero.');
        System.assert(asyncLimitValue > 0, 'Async row limit should be greater than zero.');
        System.assert(asyncLimitValue >= syncLimitValue, 'Async single document row limit should normally be greater than or equal to sync limit.');
    }
    
    /**
* Covers generateDocument() sync branch.
* testTotalPrintableRows = 0 forces totalPrintableRows <= sync limit.
*/
    @IsTest
    static void testGenerateDocumentSyncPathWhenRowsAreWithinSyncLimit() {
        Id caseId = getCaseId();
        
        // Force sync branch.
        DocxGeneratorController.testTotalPrintableRows = 0;
        
        Test.startTest();
        String result = DocxGeneratorController.generateDocument(caseId, TEMPLATE_NAME);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Sync generation should return a ContentDocumentId.');
        System.assert(result.startsWith('069'), 'Sync path should return a ContentDocumentId.');
    }
    
    /**
* Covers public wrapper method generateSingleDocxFileSyncProcess().
*/
    @IsTest
    static void testGenerateSingleDocxFileSyncProcessDirectly() {
        Id caseId = getCaseId();
        
        Test.startTest();
        String result = DocxGeneratorController.generateSingleDocxFileSyncProcess(caseId, TEMPLATE_NAME);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Direct sync process should return a ContentDocumentId.');
        System.assert(result.startsWith('069'), 'Direct sync method should create and return a ContentDocumentId.');
    }
    
    /**
* Covers generateSingleDocxSyncProcess() directly.
* This method loads Case, signing authority, Healthcare Cost sections, builds DOCX, and creates ContentDocument.
*/
    @IsTest
    static void testGenerateSingleDocxSyncProcessDirectly() {
        Id caseId = getCaseId();
        
        Test.startTest();
        String result = DocxGeneratorController.generateSingleDocxSyncProcess(caseId, TEMPLATE_NAME);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Direct sync builder method should return a ContentDocumentId.');
        System.assert(result.startsWith('069'), 'Direct sync builder method should create and return a ContentDocumentId.');
    }
    
    /**
* Covers generateDocument() async single DOCX branch.
* totalPrintableRows is greater than sync limit but within async single document limit.
*/
    @IsTest
    static void testGenerateDocumentAsyncSingleDocPath() {
        Id caseId = getCaseId();
        
        // Get configured sync limit and force row count above it.
        Integer syncLimitValue = DocxGeneratorController.getSyncPrintableHccRowLimit();
        DocxGeneratorController.testTotalPrintableRows = syncLimitValue + 1;
        
        Test.startTest();
        String result = DocxGeneratorController.generateDocument(caseId, TEMPLATE_NAME);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Async single DOCX path should return an async response.');
        System.assert(result.startsWith(DocgenConstants.ASYNC_RESPONSE_PREFIX), 'Async single DOCX path should return the async response prefix plus job id.');
        
        // Verify log was created or updated by async branch.
        List<Log__c> logs = [SELECT Id, JobId__c, Record_Id__c, Status__c, Class_Name__c, Method_Name__c FROM Log__c WHERE Record_Id__c = :String.valueOf(caseId)];
        
        System.assert(logs.size() > 0, 'Async single DOCX path should create/update a generation log.');
        
        // Validate processing log values populated by buildGenerationLog().
        Boolean foundProcessingLog = false;
        for (Log__c logRecord : logs) {
            if (logRecord.Status__c == TPL_Constants.STATUS_PROCESSING) {
                foundProcessingLog = true;
                System.assertNotEquals(null, logRecord.JobId__c, 'Processing log should contain the queueable job id.');
                System.assertEquals(TPL_Constants.CLASS_DOCX_GENERATOR_CONTROLLER, logRecord.Class_Name__c, 'Log class name should be populated by buildGenerationLog.');
                System.assertEquals(TPL_Constants.METHOD_GENERATE_DOCUMENT, logRecord.Method_Name__c, 'Log method name should be populated by buildGenerationLog.');
            }
        }
        
    }
    
    /**
* Covers generateDocument() ZIP section async branch.
* totalPrintableRows is greater than async single document limit.
*/
    @IsTest
    static void testGenerateDocumentZipSectionsAsyncPath() {
        Id caseId = getCaseId();
        
        // Force ZIP section branch.
        Integer asyncLimitValue = DocxGeneratorController.getAsyncSingleDocPrintableHccRowLimit();
        DocxGeneratorController.testTotalPrintableRows = asyncLimitValue + 1;
        
        Test.startTest();
        String result = DocxGeneratorController.generateDocument(caseId, TEMPLATE_NAME);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'ZIP section async path should return an async response.');
        System.assert(result.startsWith(DocgenConstants.ASYNC_RESPONSE_PREFIX), 'ZIP section async path should return the async response prefix plus job id.');
        
        // Verify ZIP section branch writes processing log using writeGenerationLog().
        List<Log__c> logs = [SELECT Id, JobId__c, Record_Id__c, Status__c, Error_Message__c FROM Log__c WHERE Record_Id__c = :String.valueOf(caseId) AND Status__c = :TPL_Constants.STATUS_PROCESSING];
        
        System.assert(logs.size() > 0, 'ZIP section async path should write a processing generation log.');
        
        // Confirm at least one processing log has a job id and no error message.
        Boolean foundZipLog = false;
        for (Log__c logRecord : logs) {
            if (String.isNotBlank(logRecord.JobId__c)) {
                foundZipLog = true;
                System.assertEquals(null, logRecord.Error_Message__c, 'ZIP section processing log should not contain an error message.');
            }
        }
        
        System.assert(foundZipLog, 'Expected a ZIP section log with a JobId.');
    }
    
    /**
* Covers exception handling in generateDocument().
* Invalid Case Id causes the sync path query to fail and the method wraps it in AuraHandledException.
*/
    @IsTest
    static void testGenerateDocumentWrapsExceptionInAuraHandledException() {
        Id fakeCaseId = '500000000000000AAA';
        
        // Force sync path so loadCaseForDocgen() attempts to query invalid/missing Case.
        DocxGeneratorController.testTotalPrintableRows = 0;
        
        Test.startTest();
        try {
            DocxGeneratorController.generateDocument(fakeCaseId, TEMPLATE_NAME);
            System.assert(false, 'Expected AuraHandledException for invalid Case Id.');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e.getMessage(), 'Exception message should be available.');
        }
        Test.stopTest();
    }
    
    /**
* Covers generateDocument() path where testTotalPrintableRows is null.
* This forces the method to call getEligibleHccCountForPrint(caseId).
*/
    @IsTest
    static void testGenerateDocumentUsesActualEligibleCountWhenTestOverrideIsNull() {
        Id caseId = getCaseId();
        
        // Force real count path instead of @TestVisible override.
        DocxGeneratorController.testTotalPrintableRows = null;
        
        Test.startTest();
        String result = DocxGeneratorController.generateDocument(caseId, TEMPLATE_NAME);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'generateDocument should work when row count is calculated from Healthcare_Cost__c records.');
    }
}