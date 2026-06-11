/**
* Author: Nikhil Jeenru
* Company: CGI
* Purpose:
* This class returns the current HealthIdeas async job status to the UI,
* including total chunks, completed chunks, failed chunks, and error messages.
*/
public with sharing class HealthIdeasJobStatusController {
    
    public class JobStatusResponse {
        @AuraEnabled public String status;
        @AuraEnabled public Integer totalChunks;
        @AuraEnabled public Integer completedChunks;
        @AuraEnabled public Integer failedChunks;
        @AuraEnabled public String queueableJobId;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public Boolean isDone;
        @AuraEnabled public String exceptionMessage;
    }
    
    @AuraEnabled(cacheable=false)
    public static JobStatusResponse getStatus(Id batchId) {
        JobStatusResponse response = new JobStatusResponse();
        
        if (batchId == null) {
            response.status = TPL_Constants.ASYNC_STATUS_NOT_STARTED;
            response.totalChunks = 0;
            response.completedChunks = 0;
            response.failedChunks = 0;
            response.isDone = false;
            return response;
        }
        
        String batchIdString = String.valueOf(batchId);
        Id runningUserId = UserInfo.getUserId();
        
        List<Log__c> logs = [
            SELECT Status__c,
            Total_Chunks__c,
            Completed_Chunks__c,
            Failed_Chunks__c,
            Queueable_JobId__c,
            Error_Message__c
            FROM Log__c
            WHERE JobId__c = :batchIdString
            AND Running_User__c = :runningUserId
            WITH SYSTEM_MODE
            LIMIT 1
        ];
        
        if (logs.isEmpty()) {
            response.status = TPL_Constants.ASYNC_STATUS_STARTING;
            response.totalChunks = 0;
            response.completedChunks = 0;
            response.failedChunks = 0;
            response.isDone = false;
            return response;
        }
        
        Log__c logRecord = logs[0];
        
        response.status = logRecord.Status__c;
        
        response.totalChunks = logRecord.Total_Chunks__c == null
            ? 0
            : logRecord.Total_Chunks__c.intValue();
        
        response.completedChunks = logRecord.Completed_Chunks__c == null
            ? 0
            : logRecord.Completed_Chunks__c.intValue();
        
        response.failedChunks = logRecord.Failed_Chunks__c == null
            ? 0
            : logRecord.Failed_Chunks__c.intValue();
        
        response.queueableJobId = logRecord.Queueable_JobId__c;
        response.errorMessage = logRecord.Error_Message__c;
        
        response.isDone =
            response.status == TPL_Constants.STATUS_COMPLETED ||
            response.status == TPL_Constants.STATUS_COMPLETED_WITH_ERRORS ||
            response.status == TPL_Constants.STATUS_FAILED;
        
        return response;
    }
}