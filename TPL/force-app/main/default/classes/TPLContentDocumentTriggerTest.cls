@isTest
public class TPLContentDocumentTriggerTest {
    
    @testSetup
    static void setupTestData() {
        String uniqueSuffix = String.valueOf(System.currentTimeMillis());

        ContentWorkspace restrictedFolder = new ContentWorkspace(
            Name = 'Signed Certificates ' + uniqueSuffix
        );
        insert restrictedFolder;

        ContentWorkspace allowedFolder = new ContentWorkspace(
            Name = 'AllowedFolder ' + uniqueSuffix
        );
        insert allowedFolder;
    }

    @isTest
    static void testPreventDeletionInRestrictedFolder() {
        ContentWorkspace restrictedFolder = [SELECT Id FROM ContentWorkspace WHERE Name LIKE 'Signed Certificates%' LIMIT 1];

        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'test.txt',
            VersionData = Blob.valueOf('Test data')
        );
        insert cv;

        // Re-query the ContentVersion to retrieve the ContentDocumentId
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        ContentDocument doc = [SELECT Id FROM ContentDocument WHERE Id = :cv.ContentDocumentId LIMIT 1];

        ContentWorkspaceDoc folderDocLink = new ContentWorkspaceDoc(
            ContentWorkspaceId = restrictedFolder.Id,
            ContentDocumentId = doc.Id
        );
        insert folderDocLink;

        Test.startTest();

        try {
            delete doc;
            System.assert(false,'Signed Certificate got deleted');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains(Label.TPL_SignedCertDeletion), 'Expected error message not found');
        }

        Test.stopTest();
    }

    @isTest
    static void testAllowDeletionIfNotInRestrictedFolder() {
        ContentWorkspace allowedFolder = [SELECT Id FROM ContentWorkspace WHERE Name LIKE 'AllowedFolder%' LIMIT 1];

        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'test.txt',
            VersionData = Blob.valueOf('Test data')
        );
        insert cv;

        // Re-query the ContentVersion to retrieve the ContentDocumentId
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        ContentDocument doc = [SELECT Id FROM ContentDocument WHERE Id = :cv.ContentDocumentId LIMIT 1];

        ContentWorkspaceDoc folderDocLink = new ContentWorkspaceDoc(
            ContentWorkspaceId = allowedFolder.Id,
            ContentDocumentId = doc.Id
        );
        insert folderDocLink;

        delete doc;  // Deletion should proceed without error
    }
}