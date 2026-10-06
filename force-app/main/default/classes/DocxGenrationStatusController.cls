/**
* Author: Nikhil Jeenru
* Company: CGI
* Purpose:
* Polls document generation status and returns generated document readiness details.
*/
public with sharing class DocxGenrationStatusController {
    
    @TestVisible private static String testAsyncJobStatus;
    @TestVisible private static String testAsyncJobExtendedStatus;

    // The fallback lookup (used when the JobId__c match misses) has to recognize every
    // Class_Name__c/Method_Name__c stamp a Log__c can carry over its lifecycle - not just
    // the one it was created with. LogService overwrites these fields to the ASYNC
    // queueable's own class/method when it marks a job Processing/Completed/Failed, so a
    // filter that only matched the original DocxGeneratorController.generateDocument stamp
    // was structurally blind to every async DOCX/XLSX outcome. Keep this list in sync with
    // whatever (class, method) pairs LogService.markDocxGeneration*(...) is ever called with.
    private static final Set<String> TRACKED_CLASS_NAMES = new Set<String>{
        TPL_Constants.CLASS_DOCX_GENERATOR_CONTROLLER,   // 'DocxGeneratorController' - sync path / initial log creation
        'DocxGenerationAsyncQueueable',                  // async DOCX job
        'XlsxGenerationAsyncQueueable'                   // async XLSX job
    };
    private static final Set<String> TRACKED_METHOD_NAMES = new Set<String>{
        TPL_Constants.METHOD_GENERATE_DOCUMENT,          // 'generateDocument' - sync path / initial log creation
        'execute'                                        // Queueable.execute(), shared by both async classes
    };
    
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
            String normalizedJobId = normalizeJobId(jobId);
            
            if (String.isNotBlank(normalizedJobId)) {
                logs = [
                    SELECT Id, Status__c, Error_Message__c, Generated_File_Ids__c
                    FROM Log__c
                    WHERE JobId__c = :normalizedJobId
                    AND Running_User__c = :UserInfo.getUserId()
                    WITH SYSTEM_MODE
                    LIMIT 1
                ];
                
                if (logs.isEmpty()) {
                    logs = queryLatestLogFallback(caseIdString);
                }
            } else {
                logs = queryLatestLogFallback(caseIdString);
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
            
            if (String.isNotBlank(normalizedJobId)) {
                String asyncJobStatus;
                String asyncJobExtendedStatus;
                
                if (Test.isRunningTest() && String.isNotBlank(testAsyncJobStatus)) {
                    asyncJobStatus = testAsyncJobStatus;
                    asyncJobExtendedStatus = testAsyncJobExtendedStatus;
                } else {
                    List<AsyncApexJob> jobs = [
                        SELECT Id, Status, ExtendedStatus
                        FROM AsyncApexJob
                        WHERE Id = :normalizedJobId
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
    Params: String caseIdString
    * Fallback lookup used when there's no jobId, or the JobId__c match missed.
    * Matches on every Class_Name__c/Method_Name__c stamp a Log__c can carry - the
    * original DocxGeneratorController.generateDocument stamp it's created with, AND
    * the DocxGenerationAsyncQueueable/XlsxGenerationAsyncQueueable.execute stamp
    * LogService overwrites it with once the async job starts updating it. Without the
    * IN-set match here, this query was structurally unable to find any async job that
    * had reached Processing/Completed/Failed, and would silently fall back to an older,
    * unrelated log instead.
    * Returns the most recently created matching Log__c, if any.
    */
    private static List<Log__c> queryLatestLogFallback(String caseIdString) {
        return [
            SELECT Id, Status__c, Error_Message__c, Generated_File_Ids__c
            FROM Log__c
            WHERE Record_Id__c = :caseIdString
            AND Running_User__c = :UserInfo.getUserId()
            AND Class_Name__c IN :TRACKED_CLASS_NAMES
            AND Method_Name__c IN :TRACKED_METHOD_NAMES
            WITH SYSTEM_MODE
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
    }

    /**
    Params: String jobId
    * Normalizes a job id to its 18-character case-safe form so JobId__c comparisons
    * can't miss on a 15-vs-18-character mismatch. Returns null for blank/invalid input
    * instead of throwing, so callers can treat it the same as "no jobId supplied".
    */
    private static String normalizeJobId(String jobId) {
        if (String.isBlank(jobId)) {
            return null;
        }
        try {
            return String.valueOf((Id) jobId);
        } catch (Exception e) {
            return jobId;
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