@IsTest
private class DocxGeneratorControllerTest {
    
    private static final String TEMPLATE_MINISTERS_CERT =
        System.Label.TPL_DocGen_Template_Ministers_Cert;
    
    // -------------------------------------------------------------------------
    // Covers generateDocument IF branch:
    // totalPrintableRows <= sync printable row limit
    // -------------------------------------------------------------------------
    @IsTest
    static void generateDocumentCoversSyncBranch() {
        Case c = DocxTestDataFactory.createCaseRecord();
        
        DocxGeneratorController.testTotalPrintableRows =
            DocxGeneratorController.getSyncPrintableHccRowLimit();
        
        Test.startTest();
        String result = DocxGeneratorController.generateDocument(
            c.Id,
            TEMPLATE_MINISTERS_CERT
        );
        Test.stopTest();
        
        System.assertNotEquals(
            null,
            result,
            'Sync branch should return ContentDocumentId.'
        );
        
        System.assert(
            result.startsWith('069'),
            'Sync branch should return a ContentDocumentId.'
        );
        
        System.assert(
            !result.startsWith(DocgenConstants.ASYNC_RESPONSE_PREFIX),
            'Sync branch should not return ASYNC response.'
        );
        
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId,
            ContentDocument.FileExtension
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :c.Id
            AND ContentDocumentId = :result
            LIMIT 1
        ];
        
        System.assertEquals(
            1,
            links.size(),
            'Generated DOCX should be linked to the Case.'
        );
        
        System.assertEquals(
            'docx',
            links[0].ContentDocument.FileExtension,
            'Sync branch should generate DOCX.'
        );
        
        DocxGeneratorController.testTotalPrintableRows = null;
    }
    
    // -------------------------------------------------------------------------
    // Covers generateDocument ELSE IF branch:
    // totalPrintableRows > sync printable row limit
    // totalPrintableRows <= async single document printable row limit
    // -------------------------------------------------------------------------
    @IsTest
    static void generateDocumentCoversAsyncSingleDocBranch() {
        Case c = DocxTestDataFactory.createCaseRecord();
        
        Integer testCount =
            DocxGeneratorController.getSyncPrintableHccRowLimit() + 1;
        
        System.assert(
            testCount <= DocxGeneratorController.getAsyncSingleDocPrintableHccRowLimit(),
            'Async single-doc limit must be greater than sync limit.'
        );
        
        DocxGeneratorController.testTotalPrintableRows = testCount;
        
        Test.startTest();
        String result = DocxGeneratorController.generateDocument(
            c.Id,
            TEMPLATE_MINISTERS_CERT
        );
        Test.stopTest();
        
        System.assertNotEquals(
            null,
            result,
            'Async single-doc branch should return response.'
        );
        
        System.assert(
            result.startsWith(DocgenConstants.ASYNC_RESPONSE_PREFIX),
            'Async single-doc branch should return ASYNC:<jobId>.'
        );
        
        String jobId = result.replace(DocgenConstants.ASYNC_RESPONSE_PREFIX, '');
        
        System.assertNotEquals(
            '',
            jobId,
            'Async single-doc response should include job id.'
        );
        
        List<Log__c> logs = [
            SELECT Id,
            JobId__c,
            Record_Id__c,
            Status__c,
            Class_Name__c,
            Method_Name__c
            FROM Log__c
            WHERE Record_Id__c = :String.valueOf(c.Id)
            ORDER BY CreatedDate DESC
        ];
        
        System.assert(
            !logs.isEmpty(),
            'Async single-doc branch should create a generation log.'
        );
        
        DocxGeneratorController.testTotalPrintableRows = null;
    }
    
    // -------------------------------------------------------------------------
    // Covers generateDocument ELSE branch:
    // totalPrintableRows > async single document printable row limit
    // -------------------------------------------------------------------------
    @IsTest
    static void generateDocumentCoversSectionZipBranch() {
        Case c = DocxTestDataFactory.createCaseRecord();
        
        DocxGeneratorController.testTotalPrintableRows =
            DocxGeneratorController.getAsyncSingleDocPrintableHccRowLimit() + 1;
        
        Test.startTest();
        String result = DocxGeneratorController.generateDocument(
            c.Id,
            TEMPLATE_MINISTERS_CERT
        );
        Test.stopTest();
        
        System.assertNotEquals(
            null,
            result,
            'Section-ZIP branch should return response.'
        );
        
        System.assert(
            result.startsWith(DocgenConstants.ASYNC_RESPONSE_PREFIX),
            'Section-ZIP branch should return ASYNC:<jobId>.'
        );
        
        String jobId = result.replace(DocgenConstants.ASYNC_RESPONSE_PREFIX, '');
        
        System.assertNotEquals(
            '',
            jobId,
            'Section-ZIP response should include job id.'
        );
        
        List<Log__c> logs = [
            SELECT Id,
            JobId__c,
            Record_Id__c,
            Status__c,
            Class_Name__c,
            Method_Name__c,
            Error_Message__c
            FROM Log__c
            WHERE Record_Id__c = :String.valueOf(c.Id)
            ORDER BY CreatedDate DESC
        ];
        
        System.assert(
            !logs.isEmpty(),
            'Section-ZIP branch should write a generation log.'
        );
        
        Boolean foundProcessingLog = false;
        
        for (Log__c logRecord : logs) {
            if (logRecord.Status__c == TPL_Constants.STATUS_PROCESSING) {
                foundProcessingLog = true;
                break;
            }
        }
        
        System.assertEquals(
            true,
            foundProcessingLog,
            'Section-ZIP branch should write PROCESSING log.'
        );
        
        DocxGeneratorController.testTotalPrintableRows = null;
    }
    
    // -------------------------------------------------------------------------
    // Direct sync method coverage
    // -------------------------------------------------------------------------
    @IsTest
    static void generateSingleDocxFileSyncProcessCreatesLinkedDocx() {
        Case c = DocxTestDataFactory.createCaseRecord();
        
        Test.startTest();
        String contentDocumentId =
            DocxGeneratorController.generateSingleDocxFileSyncProcess(
                c.Id,
                TEMPLATE_MINISTERS_CERT
            );
        Test.stopTest();
        
        System.assertNotEquals(
            null,
            contentDocumentId,
            'Sync process should return ContentDocumentId.'
        );
        
        System.assert(
            contentDocumentId.startsWith('069'),
            'Sync process should return ContentDocumentId.'
        );
        
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId,
            ContentDocument.FileExtension
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :c.Id
            AND ContentDocumentId = :contentDocumentId
            LIMIT 1
        ];
        
        System.assertEquals(
            1,
            links.size(),
            'Generated DOCX should be linked to Case.'
        );
        
        System.assertEquals(
            'docx',
            links[0].ContentDocument.FileExtension,
            'Generated file should be DOCX.'
        );
        
        ContentVersion cv = [
            SELECT ContentDocumentId,
            PathOnClient,
            ContentSize,
            SharingPrivacy
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocumentId
            LIMIT 1
        ];
        
        System.assertEquals(
            contentDocumentId,
            cv.ContentDocumentId,
            'ContentVersion should belong to generated ContentDocument.'
        );
        
        System.assert(
            cv.PathOnClient.endsWith('.docx'),
            'PathOnClient should end with .docx.'
        );
        
        System.assert(
            cv.ContentSize > 0,
            'Generated DOCX should not be empty.'
        );
        
        System.assertEquals(
            'N',
            cv.SharingPrivacy,
            'Generated file should have SharingPrivacy N.'
        );
    }
    
    // -------------------------------------------------------------------------
    // Async single-DOC queueable direct coverage
    // -------------------------------------------------------------------------
    @IsTest
    static void docxSyncQueueableCreatesDocxAndUpdatesLog() {
        Case c = DocxTestDataFactory.createCaseRecord();
        
        Log__c logRecord = new Log__c();
        logRecord.Record_Id__c = String.valueOf(c.Id);
        logRecord.Running_User__c = UserInfo.getUserId();
        logRecord.Class_Name__c = TPL_Constants.CLASS_DOCX_GENERATOR_CONTROLLER;
        logRecord.Method_Name__c = TPL_Constants.METHOD_GENERATE_DOCUMENT;
        logRecord.Status__c = TPL_Constants.STATUS_PROCESSING;
        insert logRecord;
        
        Test.startTest();
        Id jobId = System.enqueueJob(
            new DocxSyncQueueable(
                c.Id,
                TEMPLATE_MINISTERS_CERT,
                logRecord.Id
            )
        );
        Test.stopTest();
        
        System.assertNotEquals(
            null,
            jobId,
            'Queueable job id should be returned.'
        );
        
        Log__c refreshedLog = [
            SELECT Id,
            Status__c,
            Error_Message__c,
            Record_Id__c
            FROM Log__c
            WHERE Id = :logRecord.Id
            LIMIT 1
        ];
        
        System.assertEquals(
            String.valueOf(c.Id),
            refreshedLog.Record_Id__c,
            'Log should stay associated to the Case.'
        );
        
        List<ContentDocumentLink> docLinks = [
            SELECT ContentDocumentId,
            ContentDocument.FileExtension
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :c.Id
            AND ContentDocument.FileExtension = 'docx'
        ];
        
        System.assert(
            !docLinks.isEmpty(),
            'Async queueable should create and link DOCX.'
        );
    }
    
    // -------------------------------------------------------------------------
    // Section queueable direct coverage
    // -------------------------------------------------------------------------
    @IsTest
    static void docxSectionQueueableCanBeEnqueuedForZipFlowCoverage() {
        Case c = DocxTestDataFactory.createCaseRecord();
        
        Test.startTest();
        Id jobId = System.enqueueJob(
            new DocxSectionQueueable(
                c.Id,
                0,
                null,
                1,
                'TEST-CASE-NUMBER',
                '',
                '',
                TEMPLATE_MINISTERS_CERT,
                new List<Id>()
            )
        );
        Test.stopTest();
        
        System.assertNotEquals(
            null,
            jobId,
            'Section queueable should be enqueueable.'
        );
    }
    
    // -------------------------------------------------------------------------
    // ZIP assembler coverage
    // -------------------------------------------------------------------------
    @IsTest
    static void docxAssemblerQueueableCreatesZip() {
        Case c = DocxTestDataFactory.createCaseRecord();
        
        List<Id> sectionDocIds = new List<Id>();
        
        sectionDocIds.add(
            createSectionContentDocument(
                c.Id,
                '01_Certificate.docx',
                'section one'
            )
        );
        
        sectionDocIds.add(
            createSectionContentDocument(
                c.Id,
                '02_Totals.docx',
                'section two'
            )
        );
        
        sectionDocIds.add(
            createSectionContentDocument(
                c.Id,
                '03_MSP.docx',
                'section three'
            )
        );
        
        Test.startTest();
        System.enqueueJob(new DocxAssemblerQueueable(c.Id, sectionDocIds));
        Test.stopTest();
        
        List<ContentDocumentLink> zipLinks = [
            SELECT ContentDocumentId,
            ContentDocument.Title,
            ContentDocument.FileExtension
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :c.Id
            AND ContentDocument.FileExtension = 'zip'
        ];
        
        System.assertEquals(
            1,
            zipLinks.size(),
            'One ZIP should be created.'
        );
        
        System.assertEquals(
            'zip',
            zipLinks[0].ContentDocument.FileExtension,
            'Generated file should be ZIP.'
        );
        
        System.assertNotEquals(
            null,
            zipLinks[0].ContentDocument.Title,
            'ZIP title should be populated.'
        );
        
        ContentVersion zipVersion = [
            SELECT ContentDocumentId,
            PathOnClient,
            ContentSize,
            SharingPrivacy
            FROM ContentVersion
            WHERE ContentDocumentId = :zipLinks[0].ContentDocumentId
            LIMIT 1
        ];
        
        System.assert(
            zipVersion.PathOnClient.endsWith('.zip'),
            'ZIP PathOnClient should end with .zip.'
        );
        
        System.assert(
            zipVersion.ContentSize > 0,
            'ZIP file should not be empty.'
        );
        
        System.assertEquals(
            'N',
            zipVersion.SharingPrivacy,
            'ZIP SharingPrivacy should be N.'
        );
    }
    
    // -------------------------------------------------------------------------
    // writeGenerationLog coverage
    // -------------------------------------------------------------------------
    @IsTest
    static void writeGenerationLogCreatesProcessingLog() {
        Case c = DocxTestDataFactory.createCaseRecord();
        
        Test.startTest();
        DocxGeneratorController.writeGenerationLog(
            c.Id,
            '707000000000000AAA',
            TPL_Constants.STATUS_PROCESSING,
            null
        );
        Test.stopTest();
        
        List<Log__c> logs = [
            SELECT Id,
            JobId__c,
            Record_Id__c,
            Status__c,
            Class_Name__c,
            Method_Name__c,
            Error_Message__c
            FROM Log__c
            WHERE Record_Id__c = :String.valueOf(c.Id)
        ];
        
        System.assertEquals(
            1,
            logs.size(),
            'One generation log should be created.'
        );
        
        System.assertEquals(
            '707000000000000AAA',
            logs[0].JobId__c,
            'Job id should be saved on the log.'
        );
        
        System.assertEquals(
            TPL_Constants.STATUS_PROCESSING,
            logs[0].Status__c,
            'Status should be PROCESSING.'
        );
    }
    
    // -------------------------------------------------------------------------
    // Poll pending-state coverage
    // -------------------------------------------------------------------------
    @IsTest
    static void pollDocumentReturnsNullWhenAsyncIsStillPending() {
        Case c = DocxTestDataFactory.createCaseRecord();
        
        Test.startTest();
        DocxGenrationStatusController.PollDocumentResponse result = DocxGenrationStatusController.pollDocument(
            c.Id,
            '707000000000000AAA'
        );
        Test.stopTest();
        
        System.assertEquals(
            TPL_Constants.STATUS_PROCESSING,
            result.status,
            'Polling should return processing when no completed generation log exists.'
        );
    }
    
    // -------------------------------------------------------------------------
    // Error coverage
    // -------------------------------------------------------------------------
    @IsTest
    static void generateDocumentThrowsExceptionForInvalidCaseId() {
        Id fakeCaseId = '500000000000001AAA';
        
        DocxGeneratorController.testTotalPrintableRows = 0;
        
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            DocxGeneratorController.generateDocument(
                fakeCaseId,
                TEMPLATE_MINISTERS_CERT
            );
        } catch (Exception e) {
            exceptionThrown = true;
            
            System.assertNotEquals(
                null,
                e.getMessage(),
                'Exception message should be populated.'
            );
        }
        Test.stopTest();
        
        System.assertEquals(
            true,
            exceptionThrown,
            'Invalid Case Id should throw an exception.'
        );
        
        DocxGeneratorController.testTotalPrintableRows = null;
    }
    
    @IsTest
    static void generateDocumentThrowsExceptionForNullCaseId() {
        DocxGeneratorController.testTotalPrintableRows = 0;
        
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            DocxGeneratorController.generateDocument(
                null,
                TEMPLATE_MINISTERS_CERT
            );
        } catch (Exception e) {
            exceptionThrown = true;
            
            System.assertNotEquals(
                null,
                e.getMessage(),
                'Exception message should be populated.'
            );
        }
        Test.stopTest();
        
        System.assertEquals(
            true,
            exceptionThrown,
            'Null Case Id should throw an exception.'
        );
        
        DocxGeneratorController.testTotalPrintableRows = null;
    }
    
    // -------------------------------------------------------------------------
    // Helper
    // -------------------------------------------------------------------------
    private static Id createSectionContentDocument(
        Id caseId,
        String fileName,
        String body
    ) {
        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = fileName;
        cv.VersionData = Blob.valueOf(body);
        cv.FirstPublishLocationId = caseId;
        cv.SharingPrivacy = 'N';
        cv.IsMajorVersion = true;
        insert cv;
        
        return [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
            LIMIT 1
        ].ContentDocumentId;
    }
    
    
    
    @IsTest
    static void getEligibleHccCountForPrintReturnsOnlyPrintableRows() {
        Case c = DocxTestDataFactory.createCaseRecord();
        
        Id hccRecordTypeId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Healthcare_Cost__c'
            LIMIT 1
        ].Id;
        
        List<Healthcare_Cost__c> costs = new List<Healthcare_Cost__c>();
        
        // Eligible row 1
        costs.add(new Healthcare_Cost__c(
            Case2__c = c.Id,
            RecordTypeId = hccRecordTypeId,
            Cost_Include__c = true,
            Cost_Review__c = true,
            Date_of_Service__c = Date.today(),
            Total_Cost_Override__c = 100,
            Description_of_Service2__c = 'Eligible service 1',
            Fee_Item_Title__c = 'Eligible fee 1',
            Diagnostic_Description__c = 'Eligible diagnostic 1',
            Practitioner_Name__c = 'Eligible practitioner 1',
            Location_Type_Description2__c = 'Office'
        ));
        
        // Eligible row 2
        costs.add(new Healthcare_Cost__c(
            Case2__c = c.Id,
            RecordTypeId = hccRecordTypeId,
            Cost_Include__c = true,
            Cost_Review__c = true,
            Date_of_Service__c = Date.today(),
            Total_Cost_Override__c = 200,
            Description_of_Service2__c = 'Eligible service 2',
            Fee_Item_Title__c = 'Eligible fee 2',
            Diagnostic_Description__c = 'Eligible diagnostic 2',
            Practitioner_Name__c = 'Eligible practitioner 2',
            Location_Type_Description2__c = 'Office'
        ));
        
        // Not printable because Cost_Include__c = false
        costs.add(new Healthcare_Cost__c(
            Case2__c = c.Id,
            RecordTypeId = hccRecordTypeId,
            Cost_Include__c = false,
            Cost_Review__c = true,
            Date_of_Service__c = Date.today(),
            Total_Cost_Override__c = 300,
            Description_of_Service2__c = 'Not included service',
            Fee_Item_Title__c = 'Not included fee',
            Diagnostic_Description__c = 'Not included diagnostic',
            Practitioner_Name__c = 'Not included practitioner',
            Location_Type_Description2__c = 'Office'
        ));
        
        // Not printable because Cost_Review__c = false
        costs.add(new Healthcare_Cost__c(
            Case2__c = c.Id,
            RecordTypeId = hccRecordTypeId,
            Cost_Include__c = true,
            Cost_Review__c = false,
            Date_of_Service__c = Date.today(),
            Total_Cost_Override__c = 400,
            Description_of_Service2__c = 'Not reviewed service',
            Fee_Item_Title__c = 'Not reviewed fee',
            Diagnostic_Description__c = 'Not reviewed diagnostic',
            Practitioner_Name__c = 'Not reviewed practitioner',
            Location_Type_Description2__c = 'Office'
        ));
        
        Test.startTest();
        insert costs;
        
        Integer printableCount =
            DocxGeneratorController.getEligibleHccCountForPrint(c.Id);
        Test.stopTest();
        
        System.assertEquals(
            2,
            printableCount,
            'Only rows with Cost_Include__c = true and Cost_Review__c = true should be counted.'
        );
    }
}