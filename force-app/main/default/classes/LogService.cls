/**
* Author: Nikhil Jeenru
* Company: CGI
* Purpose: Simple logging helper for async healthcare cost refresh jobs.
*/
public with sharing class LogService {
    
    private static final Integer MAX_ERROR_LENGTH =  32767;
    
    // Creates or resets the main async status log for a batch run.
    public static void initializeAsyncStatus(Id rootBatchJobId, Integer totalChunks) {
        if (rootBatchJobId == null) {
            return;
        }
        
        String rootBatchJobIdString = String.valueOf(rootBatchJobId);
        Id runningUserId = UserInfo.getUserId();
        
        List<Log__c> existingLogs = [
            SELECT Id
            FROM Log__c
            WHERE JobId__c = :rootBatchJobIdString
            AND Running_User__c = :runningUserId
            LIMIT 1
        ];
        
        Log__c logRecord;
        
        if (existingLogs.isEmpty()) {
            logRecord = new Log__c();
            logRecord.JobId__c = rootBatchJobIdString;
            logRecord.Running_User__c = runningUserId;
            logRecord.Class_Name__c = TPL_Constants.CLASS_HEALTH_IDEAS_API_INTEGRATION;
            logRecord.Method_Name__c = TPL_Constants.METHOD_ASYNC_HEALTHCARE_COST_REFRESH;
        } else {
            logRecord = existingLogs[0];
        }
        
        logRecord.Status__c = TPL_Constants.STATUS_PROCESSING;
        logRecord.Total_Chunks__c = totalChunks;
        logRecord.Completed_Chunks__c = 0;
        logRecord.Failed_Chunks__c = 0;
        logRecord.Error_Message__c = null;
        
        upsert logRecord;
    }
    
    // Updates the overall async status.
    public static void updateAsyncStatus(Id rootBatchJobId, String status) {
        if (rootBatchJobId == null) {
            return;
        }
        
        Log__c logRecord = getStatusLogForUpdate(rootBatchJobId);
        logRecord.Status__c = status;
        update logRecord;
    }
    
    // Adds an error message to the main async log.
    public static void appendAsyncError(Id rootBatchJobId, String errorMessage) {
        if (rootBatchJobId == null || String.isBlank(errorMessage)) {
            return;
        }
        
        Log__c logRecord = getStatusLogForUpdate(rootBatchJobId);
        logRecord.Error_Message__c = appendMessage(logRecord.Error_Message__c, errorMessage);
        update logRecord;
    }
    
    // Marks one queueable chunk as finished and updates final status if all chunks are done.
    public static void markChunkFinished(
        Id rootBatchJobId,
        Id queueableJobId,
        String errorMessage
    ) {
        if (rootBatchJobId == null) {
            return;
        }
        
        Log__c logRecord = getStatusLogForUpdate(rootBatchJobId);
        
        if (logRecord.Completed_Chunks__c == null) {
            logRecord.Completed_Chunks__c = 0;
        }
        
        logRecord.Completed_Chunks__c = logRecord.Completed_Chunks__c + 1;
        
        if (queueableJobId != null) {
            logRecord.Queueable_JobId__c = String.valueOf(queueableJobId);
        }
        
        if (!String.isBlank(errorMessage)) {
            logRecord.Error_Message__c = appendMessage(
                logRecord.Error_Message__c,
                errorMessage
            );
        }
        
        if (
            logRecord.Total_Chunks__c != null &&
            logRecord.Completed_Chunks__c >= logRecord.Total_Chunks__c
        ) {
            logRecord.Status__c =
                String.isBlank(logRecord.Error_Message__c)
                ? TPL_Constants.STATUS_COMPLETED
                : TPL_Constants.STATUS_COMPLETED_WITH_ERRORS;
        } else {
            logRecord.Status__c = TPL_Constants.STATUS_PROCESSING;
        }
        
        update logRecord;
    }
    
    // Marks the async process as failed.
    public static void markChunkFailed(
        Id rootBatchJobId,
        Id queueableJobId,
        String errorMessage
    ) {
        if (rootBatchJobId == null) {
            return;
        }
        
        Log__c logRecord = getStatusLogForUpdate(rootBatchJobId);
        
        if (logRecord.Failed_Chunks__c == null) {
            logRecord.Failed_Chunks__c = 0;
        }
        
        logRecord.Failed_Chunks__c = logRecord.Failed_Chunks__c + 1;
        
        if (queueableJobId != null) {
            logRecord.Queueable_JobId__c = String.valueOf(queueableJobId);
        }
        
        logRecord.Status__c = TPL_Constants.STATUS_FAILED;
        logRecord.Error_Message__c = errorMessage;
        
        update logRecord;
    }
    // Gets the status log and locks it so chunk updates do not overwrite each other.
    private static Log__c getStatusLogForUpdate(Id rootBatchJobId) {
        String rootBatchJobIdString = String.valueOf(rootBatchJobId);
        Id runningUserId = UserInfo.getUserId();
        
        List<Log__c> logs = [
            SELECT Id,
            JobId__c,
            Queueable_JobId__c,
            Running_User__c,
            Status__c,
            Total_Chunks__c,
            Completed_Chunks__c,
            Failed_Chunks__c,
            Error_Message__c
            FROM Log__c
            WHERE JobId__c = :rootBatchJobIdString
            AND Running_User__c = :runningUserId
            LIMIT 1
            FOR UPDATE
        ];
        
        if (!logs.isEmpty()) {
            return logs[0];
        }
        
        Log__c logRecord = new Log__c();
        logRecord.JobId__c = rootBatchJobIdString;
        logRecord.Running_User__c = runningUserId;
        logRecord.Class_Name__c = TPL_Constants.CLASS_HEALTH_IDEAS_API_INTEGRATION;
        logRecord.Method_Name__c = TPL_Constants.METHOD_ASYNC_HEALTHCARE_COST_REFRESH;
        logRecord.Status__c = TPL_Constants.STATUS_PROCESSING;
        insert logRecord;
        
        return [
            SELECT Id,
            JobId__c,
            Queueable_JobId__c,
            Running_User__c,
            Status__c,
            Total_Chunks__c,
            Completed_Chunks__c,
            Failed_Chunks__c,
            Error_Message__c
            FROM Log__c
            WHERE Id = :logRecord.Id
            LIMIT 1
            FOR UPDATE
        ];
    }
    
    // Appends a message while keeping it within the field size limit.
    public static String appendMessage(String existingMessage, String newMessage) {
        if (String.isBlank(newMessage)) {
            return existingMessage;
        }
        
        String combinedMessage;
        
        if (String.isBlank(existingMessage)) {
            combinedMessage = newMessage;
        } else {
            combinedMessage = existingMessage + '\n' + newMessage;
        }
        
        if (combinedMessage.length() > MAX_ERROR_LENGTH) {
            combinedMessage = combinedMessage.substring(0, MAX_ERROR_LENGTH);
        }
        
        return combinedMessage;
    }
    
    // Builds a Log__c record with common values populated.
    public static Log__c buildLog(
        String className,
        String methodName,
        String errorMessage,
        Id recordId,
        Integer lineNumber
    ) {
        Log__c logRecord = new Log__c();
        logRecord.Class_Name__c = className;
        logRecord.Method_Name__c = methodName;
        logRecord.Error_Message__c = errorMessage;
        logRecord.Record_Id__c = recordId == null ? null : String.valueOf(recordId);
        logRecord.Line_Number__c = lineNumber;
        logRecord.Running_User__c = UserInfo.getUserId();
        
        return logRecord;
    }
    
    // Inserts log records safely without stopping the main process.
     // Inserts log records in a separate batch transaction.
    public static void logErrors(List<Log__c> logs) {
        if (logs == null || logs.isEmpty()) {
            return;
        }

        Database.executeBatch(
            new LogInsertBatch(logs),
            200
        );
    }
    
    // Collects user-friendly messages and detailed logs for failed healthcare cost inserts.
    public static String appendHealthcareCostInsertMessages(
        String existingMessage,
        Database.SaveResult[] insertResults,
        List<Healthcare_Cost__c> recordsToInsert
    ) {
        if (insertResults == null || recordsToInsert == null) {
            return existingMessage;
        }
        
        Set<String> affectedDates = new Set<String>();
        List<Log__c> logsToInsert = new List<Log__c>();
        
        for (Integer i = 0; i < insertResults.size(); i++) {
            if (!insertResults[i].isSuccess()) {
                Healthcare_Cost__c failedRecord = recordsToInsert[i];
                
                for (Database.Error err : insertResults[i].getErrors()) {
                    if (err.getStatusCode() != StatusCode.DUPLICATE_VALUE) {
                        if (failedRecord.Date_of_Admission__c != null) {
                            String admissionDate = DateTime.newInstance(
                                failedRecord.Date_of_Admission__c,
                                Time.newInstance(0, 0, 0, 0)
                            ).format('MMMM d, yyyy');
                            
                            affectedDates.add(admissionDate);
                        }
                        
                        logsToInsert.add(
                            buildLog(
                                TPL_Constants.CLASS_LOG_SERVICE,
                                TPL_Constants.METHOD_APPEND_HEALTHCARE_COST_INSERT_MESSAGES,
                                TPL_Constants.ERROR_HEALTHCARE_COST_INSERT_FAILED +
                                String.valueOf(err.getStatusCode()) +
                                TPL_Constants.ERROR_MESSAGE_PREFIX +
                                err.getMessage(),
                                failedRecord.Id,
                                null
                            )
                        );
                    }
                }
            }
        }
        
        if (!logsToInsert.isEmpty()) {
            
            Database.executeBatch(
                new LogInsertBatch(logsToInsert),
                200
            );
        }
        
        String updatedMessage = existingMessage;
        
        for (String admissionDate : affectedDates) {
            updatedMessage = appendMessage(
                updatedMessage,
                Label.TPL_HI_Record_ErrorMessage + ' ' + admissionDate
            );
        }
        
        return updatedMessage;
    }
    
    
    // Checks if the async process has already failed.
    public static Boolean isAsyncFailed(Id rootBatchJobId) {
        if (rootBatchJobId == null) {
            return false;
        }
        
        String rootBatchJobIdString = String.valueOf(rootBatchJobId);
        Id runningUserId = UserInfo.getUserId();
        
        List<Log__c> logs = [
            SELECT Status__c
            FROM Log__c
            WHERE JobId__c = :rootBatchJobIdString
            AND Running_User__c = :runningUserId
            LIMIT 1
        ];
        
        return !logs.isEmpty() && logs[0].Status__c == TPL_Constants.STATUS_FAILED;
    }
}