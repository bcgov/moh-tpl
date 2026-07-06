/**
* Author: Nikhil Jeenru
* Company: CGI
* Purpose:
* Polls document generation status and returns generated document readiness details.
*/
public with sharing class DocxGenrationStatusController {
    
    @TestVisible private static String testAsyncJobStatus;
    @TestVisible private static String testAsyncJobExtendedStatus;
    
    
    
    /**
* Response returned to LWC while polling document generation status.
*/
    public class PollDocumentResponse {
        @AuraEnabled public String status;
        @AuraEnabled public String generatedFileIds;
        @AuraEnabled public String errorMessage;
    }
    
    /**
* Polls for completion of an async document generation job.
* The LWC calls this when generateDocument returned 'ASYNC:jobId'.
*
* Returns status, generated file ids when done, and message when failed.
* Completion is tracked on Log__c; no temporary completion file is created.
*/
    @AuraEnabled(cacheable=false)
    public static PollDocumentResponse pollDocument(Id caseId, String jobId) {
        try {
            List<Log__c> logs;
            String caseIdString = String.valueOf(caseId);
            
            if (String.isNotBlank(jobId)) {
                logs = [
                    SELECT Id, Status__c, Error_Message__c, Generated_File_Ids__c
                    FROM Log__c
                    WHERE JobId__c = :jobId
                    AND Running_User__c = :UserInfo.getUserId()
                    WITH SYSTEM_MODE
                    LIMIT 1
                ];
                
                if (logs.isEmpty()) {
                    logs = [
                        SELECT Id, Status__c, Error_Message__c, Generated_File_Ids__c
                        FROM Log__c
                        WHERE Record_Id__c = :caseIdString
                        AND Running_User__c = :UserInfo.getUserId()
                        AND Class_Name__c = :TPL_Constants.CLASS_DOCX_GENERATOR_CONTROLLER
                        AND Method_Name__c = :TPL_Constants.METHOD_GENERATE_DOCUMENT
                        WITH SYSTEM_MODE
                        ORDER BY CreatedDate DESC
                        LIMIT 1
                    ];
                }
            } else {
                logs = [
                    SELECT Id, Status__c, Error_Message__c, Generated_File_Ids__c
                    FROM Log__c
                    WHERE Record_Id__c = :caseIdString
                    AND Running_User__c = :UserInfo.getUserId()
                    AND Class_Name__c = :TPL_Constants.CLASS_DOCX_GENERATOR_CONTROLLER
                    AND Method_Name__c = :TPL_Constants.METHOD_GENERATE_DOCUMENT
                    WITH SYSTEM_MODE
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
            }
            
            if (logs.isEmpty()) {
                return buildResponse(TPL_Constants.STATUS_PROCESSING, null, null);
            }
            
            if (logs[0].Status__c == TPL_Constants.STATUS_FAILED) {
                String msg = String.isBlank(logs[0].Error_Message__c) ? System.Label.TPL_DocGen_Status_Failed : logs[0].Error_Message__c;
                return buildResponse(TPL_Constants.STATUS_FAILED, null, msg);
            }
            
            if (logs[0].Status__c == TPL_Constants.STATUS_COMPLETED) {
                String generatedFileIds = logs[0].Generated_File_Ids__c;
                
                if (String.isBlank(generatedFileIds) || !contentDocumentsReady(generatedFileIds)) {
                    return buildResponse(TPL_Constants.STATUS_PROCESSING, null, null);
                }
                
                return buildResponse(TPL_Constants.STATUS_COMPLETED, generatedFileIds, null);
            }
            
            if (String.isNotBlank(jobId)) {
                String asyncJobStatus;
                String asyncJobExtendedStatus;
                
                if (Test.isRunningTest() && String.isNotBlank(testAsyncJobStatus)) {
                    asyncJobStatus = testAsyncJobStatus;
                    asyncJobExtendedStatus = testAsyncJobExtendedStatus;
                } else {
                    List<AsyncApexJob> jobs = [
                        SELECT Id, Status, ExtendedStatus
                        FROM AsyncApexJob
                        WHERE Id = :jobId
                        LIMIT 1
                    ];
                    
                    if (!jobs.isEmpty()) {
                        asyncJobStatus = jobs[0].Status;
                        asyncJobExtendedStatus = jobs[0].ExtendedStatus;
                    }
                }
                
                if (asyncJobStatus == TPL_Constants.ASYNC_JOB_STATUS_FAILED || asyncJobStatus == TPL_Constants.ASYNC_JOB_STATUS_ABORTED) {
                    String msg = String.isBlank(asyncJobExtendedStatus) ? System.Label.TPL_DocGen_Status_Failed : asyncJobExtendedStatus;
                    
                    logs[0].Status__c = TPL_Constants.STATUS_FAILED;
                    logs[0].Error_Message__c = msg;
                    logs[0].Generated_File_Ids__c = null;
                    LogService.upsertLogsInSystemMode(new List<SObject>{ logs[0] });
                    
                    return buildResponse(TPL_Constants.STATUS_FAILED, null, msg);
                }
            }
            
            return buildResponse(TPL_Constants.STATUS_PROCESSING, null, null);
        } catch (Exception e) {
            return buildResponse(TPL_Constants.STATUS_FAILED, null, 'Poll failed: ' + e.getMessage());
        }
    }
    
    /**
Params: String status, String generatedFileIds, String errorMessage
* Builds the document generation polling response. Returns the polling response object.
*/
    private static PollDocumentResponse buildResponse(String status, String generatedFileIds, String errorMessage) {
        PollDocumentResponse response = new PollDocumentResponse();
        response.status = status;
        response.generatedFileIds = generatedFileIds;
        response.errorMessage = errorMessage;
        return response;
    }
    
    /**
Params: String fileIds
* Checks whether generated content documents are ready. Returns true when all files are available, otherwise false.
*/
    private static Boolean contentDocumentsReady(String fileIds) {
        Set<Id> ids = new Set<Id>();
        
        try {
            for (String token : fileIds.split('\\|')) {
                if (String.isNotBlank(token)) {
                    ids.add((Id) token.trim());
                }
            }
        } catch (Exception e) {
            return false;
        }
        
        if (ids.isEmpty()) {
            return false;
        }
        
        return [SELECT COUNT() FROM ContentDocument WHERE Id IN :ids] == ids.size();
    }
}