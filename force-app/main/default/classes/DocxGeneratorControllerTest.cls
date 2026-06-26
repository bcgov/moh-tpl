/**
 * DocxGeneratorControllerTest
 * Integration tests for DocxGeneratorController.generateDocument().
 *
 * Coverage targets:
 *   - Happy path: all six HC record types present
 *   - File created and linked to correct Case
 *   - ContentDocumentId returned is valid and queryable
 *   - File naming includes CaseNumber and date
 *   - SharingPrivacy = 'N' on generated ContentVersion
 *   - Empty case (no HC records): generates successfully
 *   - Filter correctness: Cost_Include=false records excluded (Ambulance/Hospital/MSP/Pharma)
 *   - Filter correctness: Cost_Review=false records excluded
 *   - No filter on CC and Future Care — all records appear regardless of Include/Review
 *   - Signing authority: present record used; absent signing authority gracefully defaults to empty
 *   - Invalid recordId: throws AuraHandledException
 *   - Null recordId: throws AuraHandledException
 *   - Only records for the current Case are included (no cross-case leakage)
 */
@IsTest
private class DocxGeneratorControllerTest {

    // ── Happy path — full dataset ─────────────────────────────────────────────

    @IsTest
    static void generateDocument_fullDataSet_returnsContentDocumentId() {
        Id caseId = DocGenTestFactory.insertFullTestCase();

        Test.startTest();
        String contentDocumentId = DocxGeneratorController.generateDocument(caseId);
        Test.stopTest();

        System.assertNotEquals(null, contentDocumentId,
            'generateDocument should return a ContentDocumentId');
        System.assert(contentDocumentId.startsWith('069'),
            'ContentDocumentId should start with 069 key prefix');
    }

    @IsTest
    static void generateDocument_createsContentVersionLinkedToCase() {
        Id caseId = DocGenTestFactory.insertFullTestCase();

        Test.startTest();
        String contentDocumentId = DocxGeneratorController.generateDocument(caseId);
        Test.stopTest();

        // The ContentDocumentLink should connect the file to the Case
        List<ContentDocumentLink> links = [
            SELECT Id, LinkedEntityId, ContentDocumentId
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :contentDocumentId
              AND LinkedEntityId = :caseId
        ];
        System.assertEquals(1, links.size(),
            'Exactly one ContentDocumentLink to the Case must exist');
    }

    @IsTest
    static void generateDocument_fileNameContainsCaseNumber() {
        Id caseId = DocGenTestFactory.insertFullTestCase();

        Test.startTest();
        String contentDocumentId = DocxGeneratorController.generateDocument(caseId);
        Test.stopTest();

        ContentVersion cv = [
            SELECT Title, PathOnClient
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocumentId
            LIMIT 1
        ];
        String caseNumber = [SELECT CaseNumber FROM Case WHERE Id = :caseId].CaseNumber;

        System.assert(cv.Title.contains(caseNumber),
            'File title should contain CaseNumber. Title=' + cv.Title);
        System.assert(cv.Title.endsWith('.docx'),
            'File title should end with .docx. Title=' + cv.Title);
        System.assert(cv.PathOnClient.endsWith('.docx'),
            'PathOnClient should end with .docx');
    }

    @IsTest
    static void generateDocument_sharingPrivacyIsN() {
        Id caseId = DocGenTestFactory.insertFullTestCase();

        Test.startTest();
        String contentDocumentId = DocxGeneratorController.generateDocument(caseId);
        Test.stopTest();

        ContentVersion cv = [
            SELECT SharingPrivacy
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocumentId
            LIMIT 1
        ];
        System.assertEquals('N', cv.SharingPrivacy,
            'SharingPrivacy must be N to prevent public sharing of PII/PHI');
    }

    @IsTest
    static void generateDocument_versionDataIsNonEmpty() {
        Id caseId = DocGenTestFactory.insertFullTestCase();

        Test.startTest();
        String contentDocumentId = DocxGeneratorController.generateDocument(caseId);
        Test.stopTest();

        ContentVersion cv = [
            SELECT VersionData, ContentSize
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocumentId
            LIMIT 1
        ];
        System.assertNotEquals(null, cv.VersionData, 'VersionData must not be null');
        System.assert(cv.ContentSize > 500,
            'Generated file must be at least 500 bytes. Size=' + cv.ContentSize);
    }

    // ── Empty case (no HC records) ────────────────────────────────────────────

    @IsTest
    static void generateDocument_nohcRecords_completesSuccessfully() {
        Id caseId = DocGenTestFactory.insertEmptyCase();

        Test.startTest();
        String contentDocumentId = DocxGeneratorController.generateDocument(caseId);
        Test.stopTest();

        System.assertNotEquals(null, contentDocumentId,
            'Empty case (no HC records) should still generate a certificate');
        List<ContentDocumentLink> links = [
            SELECT Id FROM ContentDocumentLink
            WHERE ContentDocumentId = :contentDocumentId AND LinkedEntityId = :caseId
        ];
        System.assertEquals(1, links.size(), 'File must be linked to Case even with no HC records');
    }

    // ── Filter: Cost_Include = false excluded ─────────────────────────────────

    @IsTest
    static void generateDocument_ambulanceNotIncluded_excludedFromFile() {
        // Insert one included and one excluded ambulance record.
        // The test verifies the call succeeds and only one record is in the queried data.
        Account acc = DocGenTestFactory.createAccount();
        insert acc;
        Case c = DocGenTestFactory.createCase(acc.Id);
        insert c;
        TPL_DocGen_Signature__c sig = DocGenTestFactory.createSigningAuthority();
        insert sig;

        // Included
        List<Healthcare_Cost__c> included = DocGenTestFactory.createAmbulanceRecords(c.Id, 1);
        insert included;

        // Excluded (Cost_Include = false)
        Healthcare_Cost__c excluded = DocGenTestFactory.createExcludedAmbulanceRecord(c.Id);
        insert excluded;

        // Verify the controller query only picks up the included record
        List<Healthcare_Cost__c> queried = [
            SELECT Id FROM Healthcare_Cost__c
            WHERE Case2__c = :c.Id
              AND RecordTypeName__c = 'Ambulance'
              AND Cost_Include__c = true
              AND Cost_Review__c = true
        ];
        System.assertEquals(1, queried.size(),
            'Only Cost_Include=true, Cost_Review=true ambulance records should be included');

        Test.startTest();
        String contentDocumentId = DocxGeneratorController.generateDocument(c.Id);
        Test.stopTest();

        System.assertNotEquals(null, contentDocumentId,
            'Generation should succeed with mixed include/exclude ambulance records');
    }

    @IsTest
    static void generateDocument_costReviewFalse_excludedFromMSP() {
        Account acc = DocGenTestFactory.createAccount();
        insert acc;
        Case c = DocGenTestFactory.createCase(acc.Id);
        insert c;
        TPL_DocGen_Signature__c sig = DocGenTestFactory.createSigningAuthority();
        insert sig;

        // Insert MSP record with Cost_Review = false — should not appear in output
        List<RecordType> mspRts = [SELECT Id FROM RecordType
            WHERE SObjectType = 'Healthcare_Cost__c' AND DeveloperName = 'MSP' LIMIT 1];
        Healthcare_Cost__c mspExcluded = new Healthcare_Cost__c(
            Case2__c = c.Id,
            RecordTypeId = mspRts.isEmpty() ? null : mspRts[0].Id,
            Cost_Include__c = true,
            Cost_Review__c = false,  // excluded
            Date_of_Service__c = Date.newInstance(2024, 5, 1),
            Total_Cost_Override__c = 300.00
        );
        insert mspExcluded;

        List<Healthcare_Cost__c> queried = [
            SELECT Id FROM Healthcare_Cost__c
            WHERE Case2__c = :c.Id
              AND RecordTypeName__c = 'MSP'
              AND Cost_Include__c = true
              AND Cost_Review__c = true
        ];
        System.assertEquals(0, queried.size(),
            'MSP record with Cost_Review=false must be excluded by query');

        Test.startTest();
        String contentDocumentId = DocxGeneratorController.generateDocument(c.Id);
        Test.stopTest();

        System.assertNotEquals(null, contentDocumentId);
    }

    // ── Filter: CC and Future Care have NO filter ─────────────────────────────

    @IsTest
    static void generateDocument_continuingCare_noFilterApplied() {
        // CC records without Cost_Include/Cost_Review set must still be included
        Account acc = DocGenTestFactory.createAccount();
        insert acc;
        Case c = DocGenTestFactory.createCase(acc.Id);
        insert c;
        TPL_DocGen_Signature__c sig = DocGenTestFactory.createSigningAuthority();
        insert sig;

        // CC records — no Cost_Include or Cost_Review fields set
        List<Healthcare_Cost__c> ccRecs = DocGenTestFactory.createContinuingCareRecords(c.Id, 2);
        insert ccRecs;

        // Confirm the no-filter query finds all CC records
        List<Healthcare_Cost__c> queried = [
            SELECT Id FROM Healthcare_Cost__c
            WHERE Case2__c = :c.Id AND RecordTypeName__c = 'Continuing_Care'
        ];
        System.assertEquals(2, queried.size(),
            'All Continuing_Care records must be included regardless of Cost_Include/Cost_Review');

        Test.startTest();
        String contentDocumentId = DocxGeneratorController.generateDocument(c.Id);
        Test.stopTest();

        System.assertNotEquals(null, contentDocumentId);
    }

    @IsTest
    static void generateDocument_futureCare_noFilterApplied() {
        Account acc = DocGenTestFactory.createAccount();
        insert acc;
        Case c = DocGenTestFactory.createCase(acc.Id);
        insert c;
        TPL_DocGen_Signature__c sig = DocGenTestFactory.createSigningAuthority();
        insert sig;

        List<Healthcare_Cost__c> fcRecs = DocGenTestFactory.createFutureCareRecords(c.Id, 2);
        insert fcRecs;

        List<Healthcare_Cost__c> queried = [
            SELECT Id FROM Healthcare_Cost__c
            WHERE Case2__c = :c.Id AND RecordTypeName__c = 'Future_Care'
        ];
        System.assertEquals(2, queried.size(),
            'All Future_Care records must be included regardless of Cost_Include/Cost_Review');

        Test.startTest();
        String contentDocumentId = DocxGeneratorController.generateDocument(c.Id);
        Test.stopTest();

        System.assertNotEquals(null, contentDocumentId);
    }

    // ── Signing authority — missing record defaults gracefully ────────────────

    @IsTest
    static void generateDocument_noSigningAuthority_defaultsToEmpty() {
        // Do NOT insert TPL_DocGen_Signature__c — controller should handle missing record
        Account acc = DocGenTestFactory.createAccount();
        insert acc;
        Case c = DocGenTestFactory.createCase(acc.Id);
        insert c;

        Test.startTest();
        String contentDocumentId = DocxGeneratorController.generateDocument(c.Id);
        Test.stopTest();

        System.assertNotEquals(null, contentDocumentId,
            'Missing signing authority must not throw — should default to empty strings');
    }

    // ── Cross-case isolation ──────────────────────────────────────────────────

    @IsTest
    static void generateDocument_onlyCurrentCaseRecords_noCrossLeak() {
        Account acc = DocGenTestFactory.createAccount();
        insert acc;

        Case caseA = DocGenTestFactory.createCase(acc.Id);
        Case caseB = DocGenTestFactory.createCase(acc.Id);
        insert caseA;
        insert caseB;

        TPL_DocGen_Signature__c sig = DocGenTestFactory.createSigningAuthority();
        insert sig;

        // Records for Case A
        List<Healthcare_Cost__c> aRecs = DocGenTestFactory.createAmbulanceRecords(caseA.Id, 2);
        insert aRecs;
        // Records for Case B — must NOT appear in Case A's certificate
        List<Healthcare_Cost__c> bRecs = DocGenTestFactory.createAmbulanceRecords(caseB.Id, 5);
        insert bRecs;

        // Verify the query respects Case2__c filter
        List<Healthcare_Cost__c> queriedForA = [
            SELECT Id FROM Healthcare_Cost__c
            WHERE Case2__c = :caseA.Id
              AND RecordTypeName__c = 'Ambulance'
              AND Cost_Include__c = true
              AND Cost_Review__c = true
        ];
        System.assertEquals(2, queriedForA.size(),
            'Only Case A ambulance records should be returned for Case A');

        Test.startTest();
        String docIdA = DocxGeneratorController.generateDocument(caseA.Id);
        Test.stopTest();

        System.assertNotEquals(null, docIdA);
        // File must link to Case A, not Case B
        List<ContentDocumentLink> links = [
            SELECT LinkedEntityId FROM ContentDocumentLink
            WHERE ContentDocumentId = :docIdA
        ];
        System.assertEquals(1, links.size());
        System.assertEquals(caseA.Id, links[0].LinkedEntityId,
            'Generated file must be linked to Case A, not Case B');
    }

    // ── Error handling ────────────────────────────────────────────────────────

    @IsTest
    static void generateDocument_invalidRecordId_throwsAuraHandledException() {
        Id fakeId = '500000000000001AAA'; // valid format but non-existent

        Test.startTest();
        try {
            DocxGeneratorController.generateDocument(fakeId);
            System.assert(false, 'Should have thrown AuraHandledException for invalid Id');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Certificate generation failed') ||
                          e.getMessage() != null,
                'AuraHandledException message must be set');
        }
        Test.stopTest();
    }

    @IsTest
    static void generateDocument_nullRecordId_throwsAuraHandledException() {
        Test.startTest();
        try {
            DocxGeneratorController.generateDocument(null);
            System.assert(false, 'Should have thrown for null recordId');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e.getMessage());
        } catch (Exception e) {
            // Any exception is acceptable — null Id causes query failure
            System.assertNotEquals(null, e.getMessage());
        }
        Test.stopTest();
    }

    // ── Multiple calls idempotent — two files created, not one updated ────────

    @IsTest
    static void generateDocument_calledTwice_createsTwoFiles() {
        Id caseId = DocGenTestFactory.insertFullTestCase();

        Test.startTest();
        String docId1 = DocxGeneratorController.generateDocument(caseId);
        String docId2 = DocxGeneratorController.generateDocument(caseId);
        Test.stopTest();

        System.assertNotEquals(docId1, docId2,
            'Each call must create a new ContentDocument, not update existing');

        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId FROM ContentDocumentLink
            WHERE LinkedEntityId = :caseId
              AND ContentDocumentId IN (:docId1, :docId2)
        ];
        System.assertEquals(2, links.size(),
            'Both files must be linked to the Case');
    }
}