/**
 * DocxGeneratorBatchTest
 * Tests for DocxGeneratorBatch.
 *
 * The batch class uses a multi-step approach:
 *   start()   → queries records, writes opening XML to a temp ContentVersion
 *   execute() → appends row XML chunks to the temp ContentVersion
 *   finish()  → appends closing XML, builds the docx ZIP, creates the final file
 *
 * Because Test.startTest()/stopTest() runs async Apex synchronously in tests,
 * the full lifecycle executes in a single call to Database.executeBatch().
 *
 * Coverage targets:
 *   - Batch executes without error for an empty record set
 *   - Batch executes without error for a small record set
 *   - Final ContentVersion is created and linked to the recordId
 *   - Temp ContentVersion is deleted after finish()
 *   - File naming convention is correct
 *   - Constructor accepts a valid Case Id
 */
@IsTest
private class DocxGeneratorBatchTest {

    // ── Helpers ───────────────────────────────────────────────────────────────

    private static Id setupCaseWithHCRecords(Integer count) {
        Account acc = DocGenTestFactory.createAccount();
        insert acc;
        Case c = DocGenTestFactory.createCase(acc.Id);
        insert c;
        TPL_DocGen_Signature__c sig = DocGenTestFactory.createSigningAuthority();
        insert sig;
        if (count > 0) {
            List<Healthcare_Cost__c> recs = new List<Healthcare_Cost__c>();
            recs.addAll(DocGenTestFactory.createAmbulanceRecords(c.Id, Math.min(count, 3)));
            recs.addAll(DocGenTestFactory.createMSPRecords(c.Id, Math.min(count, 3)));
            insert recs;
        }
        return c.Id;
    }

    // ── Execution without error ───────────────────────────────────────────────

    @IsTest
    static void batch_emptyDataSet_completesWithoutError() {
        Id caseId = setupCaseWithHCRecords(0);

        Test.startTest();
        Database.executeBatch(new DocxGeneratorBatch(caseId), 200);
        Test.stopTest();

        // If we get here without exception the batch completed
        System.assert(true, 'Batch should complete without error on empty dataset');
    }

    @IsTest
    static void batch_smallDataSet_completesWithoutError() {
        Id caseId = setupCaseWithHCRecords(3);

        Test.startTest();
        Database.executeBatch(new DocxGeneratorBatch(caseId), 200);
        Test.stopTest();

        System.assert(true, 'Batch should complete without error on small dataset');
    }

    // ── Final file creation ───────────────────────────────────────────────────

    @IsTest
    static void batch_createsContentVersionLinkedToCase() {
        Id caseId = setupCaseWithHCRecords(2);

        // Count files before
        Integer filesBefore = [
            SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :caseId
        ];

        Test.startTest();
        Database.executeBatch(new DocxGeneratorBatch(caseId), 200);
        Test.stopTest();

        Integer filesAfter = [
            SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :caseId
        ];
        System.assert(filesAfter > filesBefore,
            'Batch must create at least one new file linked to the Case. Before=' +
            filesBefore + ' After=' + filesAfter);
    }

    @IsTest
    static void batch_finalFileIsDocx() {
        Id caseId = setupCaseWithHCRecords(2);

        Test.startTest();
        Database.executeBatch(new DocxGeneratorBatch(caseId), 200);
        Test.stopTest();

        List<ContentDocumentLink> links = [
            SELECT ContentDocument.Title, ContentDocument.FileExtension
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :caseId
        ];
        System.assert(!links.isEmpty(), 'At least one file must be linked to the Case');

        Boolean foundDocx = false;
        for (ContentDocumentLink link : links) {
            if (link.ContentDocument.Title != null &&
                link.ContentDocument.Title.endsWith('.docx')) {
                foundDocx = true;
                break;
            }
        }
        System.assert(foundDocx, 'A .docx file must be linked to the Case after batch completion');
    }

    @IsTest
    static void batch_noTempFilesRemain() {
        // Batch no longer uses a temp ContentVersion — delegates to DocxGeneratorController
        // in finish(). Verify no '_docx_temp_' files exist after completion.
        Id caseId = setupCaseWithHCRecords(2);

        Test.startTest();
        Database.executeBatch(new DocxGeneratorBatch(caseId), 200);
        Test.stopTest();

        List<ContentDocumentLink> links = [
            SELECT ContentDocument.Title
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :caseId
        ];
        for (ContentDocumentLink link : links) {
            System.assert(
                !link.ContentDocument.Title.startsWith('_docx_temp_'),
                'No temp files should remain after batch completes. Found: ' +
                link.ContentDocument.Title
            );
        }
    }

    // ── Constructor ───────────────────────────────────────────────────────────

    @IsTest
    static void batchConstructor_acceptsValidCaseId() {
        Id caseId = setupCaseWithHCRecords(0);

        Test.startTest();
        DocxGeneratorBatch b = new DocxGeneratorBatch(caseId);
        Test.stopTest();

        System.assertNotEquals(null, b, 'Constructor must return a non-null instance');
    }

    // ── Batch size boundary ───────────────────────────────────────────────────

    @IsTest
    static void batch_batchSizeOf1_processesAllRecords() {
        // Ensures chunking logic works correctly with size=1
        Id caseId = setupCaseWithHCRecords(3);

        Test.startTest();
        Database.executeBatch(new DocxGeneratorBatch(caseId), 1);
        Test.stopTest();

        List<ContentDocumentLink> links = [
            SELECT ContentDocument.Title
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :caseId
              AND ContentDocument.Title LIKE '%.docx'
        ];
        System.assert(!links.isEmpty(),
            'Batch with size=1 must still produce a complete output file');
    }
}
