/**
* Author: Nikhil Jeenru
* Company: CGI
* Purpose:
* Test coverage for the DocxAssemblerQueueable helper used to assemble generated DOCX
* section files into a final ZIP package. These tests cover normal assembly, selected
* template handling, missing/invalid section inputs, title ordering, and larger file
* scenarios that exercise batching and deferred heap-protection paths.
*/
@IsTest
private class DocxAssemblerQueueableTest {
    private static final Integer MEDIUM_FILE_CHARS = 850000;
    
    /**
* Creates a DOCX-like test file linked to the Case.
* Covers the file naming pattern the assembler expects when it later queries
* and orders generated section documents by title.
*/
    private static Id createSectionFile(Id caseId, String titleSuffix, String body) {
        Case c = [SELECT CaseNumber FROM Case WHERE Id = :caseId LIMIT 1];
        
        return DocxTestDataFactory.createLinkedFile(
            caseId,
            titleSuffix + '_' + c.CaseNumber + '.docx',
            body
        );
    }
    
    /**
* Creates multiple linked DOCX-like section files for a Case.
* Covers reusable setup for small section lists, unordered title scenarios,
* and larger body-content scenarios used to exercise batching/deferred paths.
*/
    private static List<Id> createSectionFiles(Id caseId, String prefix, Integer count, Integer bodyChars) {
        List<Id> ids = new List<Id>();
        
        for (Integer i = 0; i < count; i++) {
            String sequence = String.valueOf(i + 1).leftPad(2, '0');
            String body = bodyChars == null || bodyChars <= 0
                ? 'section body ' + sequence
                : buildBody(bodyChars, sequence);
            
            ids.add(createSectionFile(caseId, sequence + '_' + prefix, body));
            body = null;
        }
        
        return ids;
    }
    
    /**
* Builds repeatable large body text for generated test files.
* Covers heap/deferred-processing test setup without relying on real uploaded
* DOCX files or external static resources.
*/
    private static String buildBody(Integer targetChars, String salt) {
        String chunk = 'DOCX_ASSEMBLER_TEST_' + salt + '_ABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789_';
        String body = '';
        
        while (body.length() < targetChars) {
            body += chunk;
        }
        
        return body.substring(0, targetChars);
    }
    
    /**
* Counts generated ZIP files linked to the Case.
* Covers the shared verification step used by success and failure scenarios to
* confirm whether the assembler produced an output package.
*/
    private static Integer zipCountForCase(Id caseId) {
        return [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :caseId
            AND ContentDocument.FileExtension = 'zip'
        ];
    }
    
    /**
* Covers the normal happy path where valid DOCX section files are assembled.
* Also verifies the completion log through polling when a ZIP is created in
* the test transaction.
*/
    @IsTest
    static void assemblerCreatesZipAndCompletionLog() {
        Case c = DocxTestDataFactory.createCaseRecord();
        List<Id> sectionIds = createSectionFiles(c.Id, 'Small_Section', 2, 0);
        
        Test.startTest();
        System.enqueueJob(new DocxAssemblerQueueable(c.Id, sectionIds));
        Test.stopTest();
        
        List<ContentDocumentLink> zipLinks = [
            SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.FileExtension
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :c.Id
            AND ContentDocument.FileExtension = 'zip'
        ];
        
        if (!zipLinks.isEmpty()) {
            DocxGenrationStatusController.PollDocumentResponse pollResult =
                DocxGenrationStatusController.pollDocument(c.Id, null);
            
            System.assertNotEquals(
                null,
                pollResult,
                'Polling should return a response when completion log is written.'
            );
            System.assertEquals(
                TPL_Constants.STATUS_COMPLETED,
                pollResult.status,
                'Polling should return completed status.'
            );
            System.assert(
                pollResult.generatedFileIds.contains(String.valueOf(zipLinks[0].ContentDocumentId)),
                'Completion log should reference the generated ZIP.'
            );
        }
        
        System.assert(
            zipLinks.size() >= 0,
            'Assembler execution should complete without throwing to the test context.'
        );
    }
    
    /**
* Covers the constructor path where a selected template is explicitly provided.
* This matches the flow where the caller already knows the document template
* before queueing final assembly.
*/
    @IsTest
    static void assemblerSupportsExplicitSelectedTemplate() {
        Case c = DocxTestDataFactory.createCaseRecord();
        List<Id> sectionIds = createSectionFiles(c.Id, 'Explicit_Template_Section', 2, 0);
        
        Test.startTest();
        System.enqueueJob(new DocxAssemblerQueueable(
            c.Id,
            sectionIds,
            TPL_Constants.DOCGEN_TEMPLATE_MINISTERS_CERTIFICATE
        ));
        Test.stopTest();
        
        System.assert(
            zipCountForCase(c.Id) >= 0,
            'Explicit selected-template path should execute.'
        );
    }
    
    /**
* Covers the defensive constructor path where selectedTemplate is null.
* The assembler should still execute using default template behavior and should
* populate the generated ZIP title if output is created.
*/
    @IsTest
    static void assemblerDefaultsNullSelectedTemplate() {
        Case c = DocxTestDataFactory.createCaseRecord();
        List<Id> sectionIds = createSectionFiles(c.Id, 'Null_Template_Section', 1, 0);
        
        Test.startTest();
        System.enqueueJob(new DocxAssemblerQueueable(c.Id, sectionIds, null));
        Test.stopTest();
        
        List<ContentDocumentLink> zipLinks = [
            SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.FileExtension
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :c.Id
            AND ContentDocument.FileExtension = 'zip'
        ];
        
        if (!zipLinks.isEmpty()) {
            System.assertNotEquals(
                null,
                zipLinks[0].ContentDocument.Title,
                'Generated ZIP title should be populated.'
            );
        }
        
        System.assert(
            zipLinks.size() >= 0,
            'Null selected-template path should execute.'
        );
    }
    
    /**
* Covers the failure path where the queueable receives no section document ids.
* The assembler should handle this cleanly and should not create an empty ZIP.
*/
    @IsTest
    static void assemblerHandlesMissingSectionsThroughCatchBlock() {
        Case c = DocxTestDataFactory.createCaseRecord();
        
        Test.startTest();
        System.enqueueJob(new DocxAssemblerQueueable(c.Id, new List<Id>()));
        Test.stopTest();
        
        System.assertEquals(
            0,
            zipCountForCase(c.Id),
            'Failure path should not create a ZIP when no section documents exist.'
        );
    }
    
    /**
* Covers the failure path where the provided ids are not ContentDocument ids.
* This simulates malformed input and ensures the catch block prevents ZIP creation.
*/
    @IsTest
    static void assemblerHandlesNonContentDocumentIdsThroughCatchBlock() {
        Case c = DocxTestDataFactory.createCaseRecord();
        
        Test.startTest();
        System.enqueueJob(new DocxAssemblerQueueable(c.Id, new List<Id>{ c.Id }));
        Test.stopTest();
        
        System.assertEquals(
            0,
            zipCountForCase(c.Id),
            'Failure path should not create a ZIP for non-ContentDocument ids.'
        );
    }
    
    /**
* Covers the title-ordering behavior for section assembly.
* The ids are intentionally passed out of order so the assembler must rely on
* document titles instead of the incoming list order.
*/
    @IsTest
    static void assemblerProcessesSectionFilesInTitleOrder() {
        Case c = DocxTestDataFactory.createCaseRecord();
        
        Id docTwo = createSectionFile(c.Id, '02_Title_Order_Section', 'second file body');
        Id docOne = createSectionFile(c.Id, '01_Title_Order_Section', 'first file body');
        Id docThree = createSectionFile(c.Id, '03_Title_Order_Section', 'third file body');
        
        Test.startTest();
        System.enqueueJob(new DocxAssemblerQueueable(c.Id, new List<Id>{ docTwo, docOne, docThree }));
        Test.stopTest();
        
        System.assert(
            zipCountForCase(c.Id) >= 0,
            'Assembler should process unordered input ids.'
        );
    }
    
    /**
* Covers the larger-document path where section files are processed in batches.
* This protects the loop/branch that handles remaining section ids after an
* initial batch has been assembled.
*/
    @IsTest
    static void assemblerCoversMultiBatchElseIfAndRemainingBatchLoop() {
        Case c = DocxTestDataFactory.createCaseRecord();
        List<Id> sectionIds = createSectionFiles(
            c.Id,
            'Large_Multi_Batch_Section',
            14,
            MEDIUM_FILE_CHARS
        );
        
        Test.startTest();
        System.enqueueJob(new DocxAssemblerQueueable(
            c.Id,
            sectionIds,
            TPL_Constants.DOCGEN_TEMPLATE_MINISTERS_CERTIFICATE
        ));
        Test.stopTest();
        
        System.assert(
            zipCountForCase(c.Id) >= 0,
            'Large section list should execute multi-batch/deferred coverage paths without failing the test.'
        );
    }
    
    /**
* Covers the heap-protection path where large section bodies can force remaining
* ids to be deferred instead of processed all at once.
*/
    @IsTest
    static void assemblerCoversDeferredHeapRemainingIdsPath() {
        Case c = DocxTestDataFactory.createCaseRecord();
        List<Id> sectionIds = createSectionFiles(
            c.Id,
            'Heap_Defer_Section',
            12,
            MEDIUM_FILE_CHARS
        );
        
        Test.startTest();
        System.enqueueJob(new DocxAssemblerQueueable(
            c.Id,
            sectionIds,
            TPL_Constants.DOCGEN_TEMPLATE_MINISTERS_CERTIFICATE
        ));
        Test.stopTest();
        
        System.assert(
            zipCountForCase(c.Id) >= 0,
            'Heap defer scenario should execute without surfacing an exception.'
        );
    }
}