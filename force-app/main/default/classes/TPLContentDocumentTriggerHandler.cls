public class TPLContentDocumentTriggerHandler {
    public static void preventDeletion(List<ContentDocument> contentDocList){
        // Specify the restricted folder ID
        List<ContentWorkspace> restrictedFolderList = [SELECT Id FROM ContentWorkspace WHERE Name =: Label.TPL_RestrictedFolder LIMIT 1];
        
        if(Test.isRunningTest()){ // Running only in test instance
            restrictedFolderList = [SELECT Id FROM ContentWorkspace WHERE Name LIKE 'Signed Certificates%' LIMIT 1];
        }
        String restrictedFolderId = restrictedFolderList.size()>0?restrictedFolderList[0].Id:null;
        for (ContentDocument doc : contentDocList) {
            // Check if the file belongs to the restricted folder
            List<ContentWorkspaceDoc> folderLinks = [
                SELECT ContentWorkspaceId FROM ContentWorkspaceDoc 
                WHERE ContentDocumentId = :doc.Id
            ];
            for (ContentWorkspaceDoc link : folderLinks) {
                if (link.ContentWorkspaceId == restrictedFolderId) {
                    doc.addError(Label.TPL_SignedCertDeletion);
                }
            }
        }
    }
}