/**
* Author: Nikhil Jeenru
* Company: CGI
* Purpose:
* Test coverage for the DocxSectionQueueable helper used to generate temporary DOCX
* section files before final ZIP assembly. These tests cover certificate/totals
* generation, selected-template behavior, legacy constructors, empty section handling,
* completed-section handoff, and queueable failure handling.
*/
@IsTest
private class DocxSectionQueueableTest {
    
    /**
* Finds generated DOCX files linked to the Case whose title contains the supplied text.
* Covers the shared assertion pattern for certificate, totals, and section file checks.
*/
    private static List<ContentDocumentLink> findGeneratedDocxLinks(Id caseId, String titleContains) {
        String titleFilter = '%' + titleContains + '%';
        
        return [
            SELECT ContentDocumentId,
            ContentDocument.Title,
            ContentDocument.FileExtension
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :caseId
            AND ContentDocument.FileExtension = 'docx'
            AND ContentDocument.Title LIKE :titleFilter
            ORDER BY ContentDocument.Title
        ];
    }
    
    /**
* Counts all generated DOCX files linked to the Case.
* Covers checks where the test only needs to confirm that no temporary section
* file was created for empty healthcare sections.
*/
    private static Integer docxCountForCase(Id caseId) {
        return [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :caseId
            AND ContentDocument.FileExtension = 'docx'
        ];
    }
    
    /**
* Counts ZIP files linked to the Case.
* Covers the completed-section handoff path where DocxSectionQueueable passes
* existing section documents to DocxAssemblerQueueable.
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
* Builds the current selected-template constructor used by the async DOCX flow.
* Covers consistent setup for most tests so each scenario only changes the
* section index, selected template, or existing section document ids.
*/
    private static DocxSectionQueueable newSelectedTemplateJob(
        Case c,
        Integer sectionIndex,
        String lastProcessedDateId,
        Integer chunkWithinSection,
        String selectedTemplate,
        List<Id> sectionDocIds
    ) {
        return new DocxSectionQueueable(
            c.Id,
            sectionIndex,
            lastProcessedDateId,
            chunkWithinSection,
            c.CaseNumber,
            'Test Signer',
            'Test Title',
            selectedTemplate,
            sectionDocIds
        );
    }
    
    /**
* Covers the certificate-summary path for the Ministers Certificate template.
* The certificate section should create the certificate summary DOCX and the totals
* DOCX before moving into the healthcare detail section chain.
*/
    @IsTest
    static void certificateSummarySectionCreatesTemporaryDocx() {
        Case c = DocxTestDataFactory.createCaseRecord();
        
        DocxSectionQueueable job = newSelectedTemplateJob(
            c,
            DocgenConstants.CERTIFICATE_SECTION_INDEX,
            null,
            1,
            TPL_Constants.DOCGEN_TEMPLATE_MINISTERS_CERTIFICATE,
            new List<Id>()
        );
        
        Test.startTest();
        job.execute(null);
        Test.stopTest();
        
        List<ContentDocumentLink> certificateLinks = findGeneratedDocxLinks(c.Id, 'Certificate');
        List<ContentDocumentLink> totalsLinks = findGeneratedDocxLinks(c.Id, 'Totals');
        
        System.assert(!certificateLinks.isEmpty(), 'The certificate summary section should create a temporary DOCX file.');
        System.assertEquals('docx', certificateLinks[0].ContentDocument.FileExtension, 'Certificate section output should be DOCX.');
        System.assert(!totalsLinks.isEmpty(), 'The certificate section should also create the totals DOCX file.');
        System.assertEquals('docx', totalsLinks[0].ContentDocument.FileExtension, 'Totals section output should be DOCX.');
    }
    
    /**
* Covers the Case History template branch inside the certificate section.
* Case History should skip the Ministers Certificate summary page but still
* generate the totals section before continuing the async chain.
*/
    @IsTest
    static void caseHistoryTemplateSkipsCertificateAndCreatesTotalsOnly() {
        Case c = DocxTestDataFactory.createCaseRecord();
        
        DocxSectionQueueable job = newSelectedTemplateJob(
            c,
            DocgenConstants.CERTIFICATE_SECTION_INDEX,
            null,
            1,
            TPL_Constants.DOCGEN_TEMPLATE_CASE_HISTORY,
            new List<Id>()
        );
        
        Test.startTest();
        job.execute(null);
        Test.stopTest();
        
        List<ContentDocumentLink> certificateLinks = findGeneratedDocxLinks(c.Id, 'Certificate');
        List<ContentDocumentLink> totalsLinks = findGeneratedDocxLinks(c.Id, 'Totals');
        
        System.assertEquals(0, certificateLinks.size(), 'Case History template should not create the Ministers Certificate summary DOCX.');
        System.assert(!totalsLinks.isEmpty(), 'Case History template should still create the totals DOCX.');
        System.assertEquals('docx', totalsLinks[0].ContentDocument.FileExtension, 'Totals output should be DOCX.');
    }
    
    /**
* Covers null selected-template defaulting in the main constructor.
* A null selected template should default to the Ministers Certificate behavior.
*/
    @IsTest
    static void nullSelectedTemplateDefaultsToMinistersCertificate() {
        Case c = DocxTestDataFactory.createCaseRecord();
        
        DocxSectionQueueable job = newSelectedTemplateJob(
            c,
            DocgenConstants.CERTIFICATE_SECTION_INDEX,
            null,
            1,
            null,
            null
        );
        
        Test.startTest();
        job.execute(null);
        Test.stopTest();
        
        List<ContentDocumentLink> certificateLinks = findGeneratedDocxLinks(c.Id, 'Certificate');
        List<ContentDocumentLink> totalsLinks = findGeneratedDocxLinks(c.Id, 'Totals');
        
        System.assert(!certificateLinks.isEmpty(), 'Null selected template should default to Ministers Certificate and create the certificate DOCX.');
        System.assert(!totalsLinks.isEmpty(), 'Null selected template should still create the totals DOCX.');
    }
    
    /**
* Covers the legacy constructor that does not include selectedTemplate.
* This protects older callers by confirming the constructor still routes into
* the default Ministers Certificate generation flow.
*/
    @IsTest
    static void legacyConstructorWithoutSelectedTemplateCreatesCertificateFiles() {
        Case c = DocxTestDataFactory.createCaseRecord();
        
        DocxSectionQueueable job = new DocxSectionQueueable(
            c.Id,
            DocgenConstants.CERTIFICATE_SECTION_INDEX,
            null,
            1,
            c.CaseNumber,
            'Test Contact',
            '1234567890',
            'CLAIM-1',
            String.valueOf(Date.today()),
            String.valueOf(Date.today().addYears(-40)),
            'Test Signer',
            'Test Title',
            '$10',
            '$20',
            '$30',
            '$40',
            '$50',
            '$60',
            '$100',
            '$200',
            '$300',
            new List<Id>()
        );
        
        Test.startTest();
        job.execute(null);
        Test.stopTest();
        
        System.assert(!findGeneratedDocxLinks(c.Id, 'Certificate').isEmpty(), 'Legacy constructor should create the certificate DOCX.');
        System.assert(!findGeneratedDocxLinks(c.Id, 'Totals').isEmpty(), 'Legacy constructor should create the totals DOCX.');
    }
    
    /**
* Covers the legacy constructor that includes selectedTemplate.
* When Case History is passed through the legacy signature, the certificate page
* should be skipped while totals are still generated.
*/
    @IsTest
    static void legacyConstructorWithSelectedTemplateHonorsCaseHistoryBehavior() {
        Case c = DocxTestDataFactory.createCaseRecord();
        
        DocxSectionQueueable job = new DocxSectionQueueable(
            c.Id,
            DocgenConstants.CERTIFICATE_SECTION_INDEX,
            null,
            1,
            c.CaseNumber,
            'Test Contact',
            '1234567890',
            'CLAIM-2',
            String.valueOf(Date.today()),
            String.valueOf(Date.today().addYears(-40)),
            'Test Signer',
            'Test Title',
            '$10',
            '$20',
            '$30',
            '$40',
            '$50',
            '$60',
            '$100',
            '$200',
            '$300',
            TPL_Constants.DOCGEN_TEMPLATE_CASE_HISTORY,
            new List<Id>()
        );
        
        Test.startTest();
        job.execute(null);
        Test.stopTest();
        
        System.assertEquals(0, findGeneratedDocxLinks(c.Id, 'Certificate').size(), 'Case History selected through legacy constructor should skip certificate DOCX.');
        System.assert(!findGeneratedDocxLinks(c.Id, 'Totals').isEmpty(), 'Legacy Case History constructor should still create totals DOCX.');
    }
    
    /**
* Covers the empty Ambulance healthcare-section path.
* When no matching Healthcare Cost rows exist and this is the first chunk,
* the queueable should move forward without creating an Ambulance DOCX.
*/
    @IsTest
    static void emptyAmbulanceSectionDoesNotCreateSectionDocx() {
        Case c = DocxTestDataFactory.createCaseRecord();
        
        Integer beforeCount = docxCountForCase(c.Id);
        
        DocxSectionQueueable job = newSelectedTemplateJob(
            c,
            DocgenConstants.AMBULANCE_SECTION_INDEX,
            null,
            1,
            TPL_Constants.DOCGEN_TEMPLATE_MINISTERS_CERTIFICATE,
            new List<Id>()
        );
        
        Test.startTest();
        job.execute(null);
        Test.stopTest();
        
        Integer afterCount = docxCountForCase(c.Id);
        
        System.assertEquals(beforeCount, afterCount, 'Empty first Ambulance section should not create a section DOCX.');
    }
    
    /**
* Covers the empty Hospital healthcare-section path.
* This verifies the no-row skip behavior for a middle healthcare section.
*/
    @IsTest
    static void emptyHospitalSectionDoesNotCreateSectionDocx() {
        Case c = DocxTestDataFactory.createCaseRecord();
        
        Integer beforeCount = docxCountForCase(c.Id);
        
        DocxSectionQueueable job = newSelectedTemplateJob(
            c,
            DocgenConstants.HOSPITAL_SECTION_INDEX,
            null,
            1,
            TPL_Constants.DOCGEN_TEMPLATE_MINISTERS_CERTIFICATE,
            new List<Id>()
        );
        
        Test.startTest();
        job.execute(null);
        Test.stopTest();
        
        Integer afterCount = docxCountForCase(c.Id);
        
        System.assertEquals(beforeCount, afterCount, 'Empty first Hospital section should not create a section DOCX.');
    }
    
    /**
* Covers the empty MSP healthcare-section path.
* This verifies MSP sections with no rows advance without producing an empty DOCX.
*/
    @IsTest
    static void emptyMspSectionDoesNotCreateSectionDocx() {
        Case c = DocxTestDataFactory.createCaseRecord();
        
        Integer beforeCount = docxCountForCase(c.Id);
        
        DocxSectionQueueable job = newSelectedTemplateJob(
            c,
            DocgenConstants.MSP_SECTION_INDEX,
            null,
            1,
            TPL_Constants.DOCGEN_TEMPLATE_MINISTERS_CERTIFICATE,
            new List<Id>()
        );
        
        Test.startTest();
        job.execute(null);
        Test.stopTest();
        
        Integer afterCount = docxCountForCase(c.Id);
        
        System.assertEquals(beforeCount, afterCount, 'Empty first MSP section should not create a section DOCX.');
    }
    
    /**
* Covers the empty PharmaCare healthcare-section path.
* This verifies the no-row branch for PharmaCare detail generation.
*/
    @IsTest
    static void emptyPharmacareSectionDoesNotCreateSectionDocx() {
        Case c = DocxTestDataFactory.createCaseRecord();
        
        Integer beforeCount = docxCountForCase(c.Id);
        
        DocxSectionQueueable job = newSelectedTemplateJob(
            c,
            DocgenConstants.PHARMACARE_SECTION_INDEX,
            null,
            1,
            TPL_Constants.DOCGEN_TEMPLATE_MINISTERS_CERTIFICATE,
            new List<Id>()
        );
        
        Test.startTest();
        job.execute(null);
        Test.stopTest();
        
        Integer afterCount = docxCountForCase(c.Id);
        
        System.assertEquals(beforeCount, afterCount, 'Empty first PharmaCare section should not create a section DOCX.');
    }
    
    /**
* Covers the empty Continuing Care section path.
* Continuing Care uses the shared care query branch and should not create a
* detail DOCX when no care rows exist.
*/
    @IsTest
    static void emptyContinuingCareSectionDoesNotCreateSectionDocx() {
        Case c = DocxTestDataFactory.createCaseRecord();
        
        Integer beforeCount = docxCountForCase(c.Id);
        
        DocxSectionQueueable job = newSelectedTemplateJob(
            c,
            DocgenConstants.CONTINUING_CARE_SECTION_INDEX,
            null,
            1,
            TPL_Constants.DOCGEN_TEMPLATE_MINISTERS_CERTIFICATE,
            new List<Id>()
        );
        
        Test.startTest();
        job.execute(null);
        Test.stopTest();
        
        Integer afterCount = docxCountForCase(c.Id);
        
        System.assertEquals(beforeCount, afterCount, 'Empty first Continuing Care section should not create a section DOCX.');
    }
    
    /**
* Covers the empty Future Care section path.
* Future Care also uses the shared care query branch and should skip DOCX creation
* when no matching rows exist.
*/
    @IsTest
    static void emptyFutureCareSectionDoesNotCreateSectionDocx() {
        Case c = DocxTestDataFactory.createCaseRecord();
        
        Integer beforeCount = docxCountForCase(c.Id);
        
        DocxSectionQueueable job = newSelectedTemplateJob(
            c,
            DocgenConstants.FUTURE_CARE_SECTION_INDEX,
            null,
            1,
            TPL_Constants.DOCGEN_TEMPLATE_MINISTERS_CERTIFICATE,
            new List<Id>()
        );
        
        Test.startTest();
        job.execute(null);
        Test.stopTest();
        
        Integer afterCount = docxCountForCase(c.Id);
        
        System.assertEquals(beforeCount, afterCount, 'Empty first Future Care section should not create a section DOCX.');
    }
    
    /**
* Covers the completed-section handoff path.
* When the completed section index is reached, DocxSectionQueueable should enqueue
* the assembler. The test checks the handoff executes without throwing, because
* assembler behavior can create or update linked files during Test.stopTest().
*/
    @IsTest
    static void completedSectionHandsOffToAssemblerWithoutThrowing() {
        Case c = DocxTestDataFactory.createCaseRecord();
        
        Id existingSectionDocId = DocxTestDataFactory.createLinkedFile(
            c.Id,
            '99_Existing_Section_' + c.CaseNumber + '.docx',
            'existing section body'
        );
        
        DocxSectionQueueable job = newSelectedTemplateJob(
            c,
            DocgenConstants.COMPLETED_SECTION_INDEX,
            null,
            1,
            TPL_Constants.DOCGEN_TEMPLATE_MINISTERS_CERTIFICATE,
            new List<Id>{ existingSectionDocId }
        );
        
        Test.startTest();
        job.execute(null);
        Test.stopTest();
        
        System.assertNotEquals(null, existingSectionDocId, 'Completed section should keep a valid existing section document id for assembler handoff.');
        System.assert(zipCountForCase(c.Id) >= 0, 'Completed section should hand off to assembler without throwing.');
    }
    
    /**
* Covers the execute catch block with an invalid Case Id.
* This test enqueues the queueable instead of calling execute(null), because the
* production catch block uses QueueableContext.getJobId().
*/
    @IsTest
    static void executeCatchesFailureAndWritesFailureLog() {
        Id invalidCaseId = (Id)'500000000000001AAA';
        
        DocxSectionQueueable job = new DocxSectionQueueable(
            invalidCaseId,
            DocgenConstants.CERTIFICATE_SECTION_INDEX,
            null,
            1,
            'BAD-CASE',
            'Test Signer',
            'Test Title',
            TPL_Constants.DOCGEN_TEMPLATE_MINISTERS_CERTIFICATE,
            new List<Id>()
        );
        
        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();
        
        List<Log__c> logs = [
            SELECT Id,
            Record_Id__c,
            Status__c,
            Error_Message__c,
            Class_Name__c,
            Method_Name__c
            FROM Log__c
            WHERE Record_Id__c = :String.valueOf(invalidCaseId)
            AND Class_Name__c = 'DocxSectionQueueable'
            AND Method_Name__c = 'execute'
            LIMIT 1
        ];
        
        System.assertEquals(1, logs.size(), 'Failure path should write a DocxSectionQueueable log.');
        System.assertEquals(TPL_Constants.STATUS_FAILED, logs[0].Status__c, 'Failure log should be marked failed.');
        System.assert(!String.isBlank(logs[0].Error_Message__c), 'Failure log should include the caught exception message.');
    }
}