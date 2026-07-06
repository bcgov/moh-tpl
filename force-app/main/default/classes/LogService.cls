/**
* Author: Nikhil Jeenru
* Company: CGI
* Purpose: Simple logging helper for async healthcare cost refresh jobs.
*/
public without sharing class LogService {
    
    private static final Integer MAX_ERROR_LENGTH =  32767;
    
    // Creates or resets the main async status log for a batch run.
    public static void initializeAsyncStatus(Id rootBatchJobId, Integer totalChunks, string className, string methodName) {
        if (rootBatchJobId == null) {
            return;
        }
        
        String rootBatchJobIdString = String.valueOf(rootBatchJobId);
        Id runningUserId = getRunningUserId();
        
        List<Log__c> existingLogs = [
            SELECT Id, JobId__c
            FROM Log__c
            WHERE JobId__c = :rootBatchJobIdString
            AND Running_User__c = :runningUserId
            WITH SYSTEM_MODE
             LIMIT 1 
        ];
        
        Log__c logRecord;
        
        if (existingLogs.isEmpty()) {
            logRecord = new Log__c();
            logRecord.JobId__c = rootBatchJobIdString;
            logRecord.Running_User__c = runningUserId;
            logRecord.Class_Name__c = className;
            logRecord.Method_Name__c = methodName;
        } else {
            logRecord = existingLogs[0];
        }
        
        logRecord.Status__c = TPL_Constants.STATUS_PROCESSING;
        logRecord.Total_Chunks__c = totalChunks;
        logRecord.Completed_Chunks__c = 0;
        logRecord.Failed_Chunks__c = 0;
        logRecord.Error_Message__c = null;
        
        upsertLogsInSystemMode(new List<Log__c>{ logRecord });
    }
    
    // Updates the overall async status.
    public static void updateAsyncStatus(Id rootBatchJobId, String status) {
        if (rootBatchJobId == null) {
            return;
        }
        
        Log__c logRecord = getStatusLogForUpdate(rootBatchJobId);
        logRecord.Status__c = status;
        updateLogsInSystemMode(new List<SObject>{logRecord});
    }
    
    // Adds an error message to the main async log.
    public static void appendAsyncError(Id rootBatchJobId, String errorMessage) {
        if (rootBatchJobId == null || String.isBlank(errorMessage)) {
            return;
        }
        
        Log__c logRecord = getStatusLogForUpdate(rootBatchJobId);
        logRecord.Error_Message__c = appendMessage(logRecord.Error_Message__c, errorMessage);
        
        updateLogsInSystemMode(new List<SObject>{logRecord});
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
        
         updateLogsInSystemMode(new List<SObject>{logRecord});
    }
    
    // Marks the async process as failed.
    public static void markChunkFailed(
        Id rootBatchJobId,
        Id queueableJobId,
        String errorMessage,
        String stackTrace,
        String className,
        String methodName
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
        logRecord.Stack_Trace__c = stackTrace;
        logRecord.Class_Name__c = className;
        logRecord.Method_Name__c = methodName;
        updateLogsInSystemMode(new List<SObject>{logRecord});
        
     }
    // Gets the status log and locks it so chunk updates do not overwrite each other.
    private static Log__c getStatusLogForUpdate(Id rootBatchJobId) {
        String rootBatchJobIdString = String.valueOf(rootBatchJobId);
        Id runningUserId = getRunningUserId();
        
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
            WITH SYSTEM_MODE
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

         insertLogsInSystemMode(new List<SObject>{logRecord});
        
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
            WITH SYSTEM_MODE
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
        Id recordId) {
        Log__c logRecord = new Log__c();
        logRecord.Class_Name__c = className;
        logRecord.Method_Name__c = methodName;
        logRecord.Error_Message__c = errorMessage;
        logRecord.Record_Id__c = recordId == null ? null : String.valueOf(recordId);
        logRecord.Running_User__c = getRunningUserId();
        
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
        List<Healthcare_Cost__c> recordsToInsert,
        string hccType
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
                        Date affectedDate = failedRecord.Date_of_Admission__c != null ? failedRecord.Date_of_Admission__c : failedRecord.Date_of_Service__c;
                        affectedDates.add(HealthIdeasApiIntegration.formatDateForDisplay(affectedDate));
                        logsToInsert.add(
                            buildLog(
                                TPL_Constants.CLASS_LOG_SERVICE,
                                TPL_Constants.METHOD_APPEND_HEALTHCARE_COST_INSERT_MESSAGES,
                                TPL_Constants.ERROR_HEALTHCARE_COST_INSERT_FAILED +
                                String.valueOf(err.getStatusCode()) +
                                TPL_Constants.ERROR_MESSAGE_PREFIX +
                                err.getMessage(),
                                failedRecord.Id
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
        
        for (String affectedDate : affectedDates) {
            updatedMessage = appendMessage(
                updatedMessage,
              Label.TPL_HI_Record_ErrorMessage + ' ' + hccType + TPL_Constants.TPL_HI_RECORDS_FOR_SUFFIX + affectedDate
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
        Id runningUserId = getRunningUserId();
        
        List<Log__c> logs = [
            SELECT Status__c
            FROM Log__c
            WHERE JobId__c = :rootBatchJobIdString
            AND Running_User__c = :runningUserId
            WITH SYSTEM_MODE
            LIMIT 1
        ];
        
        return !logs.isEmpty() && logs[0].Status__c == TPL_Constants.STATUS_FAILED;
    }

    /**
     *Helper to get the running user ID.
    */ 
    public static Id getRunningUserId() {
        return  UserInfo.getUserId();
    }

    /**
     * Upserts records in system mode and returns the results.
     */
    public static Database.SaveResult[] upsertLogsInSystemModeWithReturnValue(List<SObject> recordsToInsert) {
        if (recordsToInsert == null || recordsToInsert.isEmpty()) {
            return new List<Database.SaveResult>();
        }

        return Database.insert(
            recordsToInsert,
            false,
            AccessLevel.SYSTEM_MODE
        );
    }

    /**
     * Inserts records in system mode.
     */
   public static void insertLogsInSystemMode(List<SObject> recordsToInsert) {
        if (recordsToInsert == null || recordsToInsert.isEmpty()) {
            return;
        }

        Database.insert(
            recordsToInsert,
            AccessLevel.SYSTEM_MODE
        );
    }
     
    /**
     * Updates log records in system mode.
     */
    public static void updateLogsInSystemMode(List<SObject> recordsToUpdate) {
        if (recordsToUpdate == null || recordsToUpdate.isEmpty()) {
            return;
        }

        Database.update(
            recordsToUpdate,
            AccessLevel.SYSTEM_MODE
        );
    }

    /**
     * Upserts log records in system mode.
     */
    public static void upsertLogsInSystemMode(List<SObject> recordsToUpsert) {
        if (recordsToUpsert == null || recordsToUpsert.isEmpty()) {
            return;
        }


        Database.UpsertResult[] results =
        Database.upsert(recordsToUpsert, false, AccessLevel.SYSTEM_MODE);

    for (Integer i = 0; i < results.size(); i++) {
        if (!results[i].isSuccess()) {
            SObject failedRecord = recordsToUpsert[i];

            for (Database.Error err : results[i].getErrors()) {
                System.debug(
                    LoggingLevel.ERROR,
                    'Log upsert failed. ' +
                    'RecordType=' + String.valueOf(failedRecord.getSObjectType()) +
                    ', RecordId=' + String.valueOf(failedRecord.get('Id')) +
                    ', StatusCode=' + String.valueOf(err.getStatusCode()) +
                    ', Message=' + err.getMessage() +
                    ', Fields=' + String.valueOf(err.getFields())
                );
            }
        }
    }
}


    /**
     * Builds a DOCX generation Log__c record with common values populated.
     */
    public static Log__c buildGenerationLog(Id caseId, String jobId, String status, String message) {
        Log__c logRecord = new Log__c();
        logRecord.JobId__c = jobId;
        logRecord.Record_Id__c = String.valueOf(caseId);
        logRecord.Running_User__c = UserInfo.getUserId();
        logRecord.Class_Name__c = TPL_Constants.CLASS_DOCX_GENERATOR_CONTROLLER;
        logRecord.Method_Name__c = TPL_Constants.METHOD_GENERATE_DOCUMENT;
        logRecord.Status__c = status;
        logRecord.Error_Message__c = message;
        return logRecord;
    }

    /**
     * Writes a DOCX generation log record.
     */
    public static void writeGenerationLog(Id caseId, String jobId, String status, String message) {
        upsertLogsInSystemMode(new List<SObject>{ buildGenerationLog(caseId, jobId, status, message) });
    }

    /**
     * Loads a DOCX generation log by Id.
     */
    public static Log__c getGenerationLogById(Id logId) {
        if (logId == null) return null;

        List<Log__c> logs = [
            SELECT Id, JobId__c, Record_Id__c, Running_User__c, Class_Name__c, Method_Name__c,
                   Status__c, Error_Message__c, Generated_File_Ids__c
            FROM Log__c
            WHERE Id = :logId
            WITH SYSTEM_MODE
            LIMIT 1
        ];

        return logs.isEmpty() ? null : logs[0];
    }

    /**
     * Loads the latest DOCX generation log for the current user and Case.
     */
    public static Log__c getLatestGenerationLog(Id caseId) {
        String caseIdString = String.valueOf(caseId);
        List<Log__c> logs = [
            SELECT Id, JobId__c, Record_Id__c, Running_User__c, Class_Name__c, Method_Name__c, Status__c, Error_Message__c, Generated_File_Ids__c
            FROM Log__c
            WHERE Record_Id__c = :caseIdString
              AND Running_User__c = :UserInfo.getUserId()
              AND Class_Name__c = :TPL_Constants.CLASS_DOCX_GENERATOR_CONTROLLER
              AND Method_Name__c = :TPL_Constants.METHOD_GENERATE_DOCUMENT
            WITH SYSTEM_MODE
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        return logs.isEmpty() ? buildGenerationLog(caseId, null, null, null) : logs[0];
    }

    /**
     * Updates an existing DOCX generation log record.
     */
    public static void updateGenerationLog(Log__c logRecord, String jobId, String status, String message) {
        if (logRecord == null) return;

        if (jobId != null) {
            logRecord.JobId__c = jobId;
        }
        logRecord.Status__c = status;
        logRecord.Error_Message__c = message;
        upsertLogsInSystemMode(new List<SObject>{ logRecord });
    }

    /**
     * Marks an existing DOCX generation log as processing without changing its message fields.
     */
    public static void markDocxGenerationProcessingById(Id logId, String jobId) {
        Log__c logRecord = getGenerationLogById(logId);
        if (logRecord == null) return;

        if (jobId != null) {
            logRecord.JobId__c = jobId;
        }
        logRecord.Status__c = TPL_Constants.STATUS_PROCESSING;
        upsertLogsInSystemMode(new List<SObject>{ logRecord });
    }

    /**
     * Marks an existing DOCX generation log as completed and stores the generated ContentDocumentId.
     */
    public static void markDocxGenerationCompletedById(Id logId, String jobId, String contentDocumentId) {
        Log__c logRecord = getGenerationLogById(logId);
        if (logRecord == null) return;

        if (jobId != null) {
            logRecord.JobId__c = jobId;
        }

        logRecord.Status__c = TPL_Constants.STATUS_COMPLETED;
        logRecord.Generated_File_Ids__c = contentDocumentId;
        logRecord.Error_Message__c = null;
        upsertLogsInSystemMode(new List<SObject>{ logRecord });
    }

    /**
     * Marks the latest DOCX generation log for the current Case/user as completed and stores generated file ids.
     */
    public static void markLatestDocxGenerationCompleted(Id caseId, List<Id> contentDocumentIds) {
        List<String> idStrings = new List<String>();
        for (Id contentDocumentId : contentDocumentIds) {
            idStrings.add(String.valueOf(contentDocumentId));
        }

        Log__c logRecord = getLatestGenerationLog(caseId);
        if (logRecord == null) return;

        logRecord.Status__c = TPL_Constants.STATUS_COMPLETED;
        logRecord.Generated_File_Ids__c = String.join(idStrings, DocgenConstants.PIPE_DELIMITER);
        logRecord.Error_Message__c = null;
        upsertLogsInSystemMode(new List<SObject>{ logRecord });
    }

    /**
     * Marks the latest DOCX generation log for the current Case/user as failed with a generic UI message and stack trace.
     */
    public static void markLatestDocxGenerationFailed(
        Id caseId,
        String jobId,
        String errorMessage,
        String stackTrace,
        String className,
        String methodName
    ) {
        try {
            Log__c latestLog = getLatestGenerationLog(caseId);
            markDocxGenerationFailed(
                latestLog == null ? null : latestLog.Id,
                caseId,
                jobId,
                errorMessage,
                stackTrace,
                className,
                methodName
            );
        } catch (Exception loggingException) {
            System.debug(LoggingLevel.ERROR,
                'LogService: could not mark latest DOCX generation log failed: '
                + loggingException.getMessage());
        }
    }

    /**
     * Applies DOCX failure fields to an already resolved generation log.
     */
    public static void markDocxGenerationFailed(
        Id logId,
        Id caseId,
        String jobId,
        String errorMessage,
        String stackTrace,
        String className,
        String methodName
    ) {
        Log__c logRecord;

        if (logId != null) {
            logRecord = [
                SELECT Id, JobId__c, Record_Id__c, Running_User__c, Class_Name__c, Method_Name__c,
                    Status__c, Error_Message__c, Stack_Trace__c
                FROM Log__c
                WHERE Id = :logId
                WITH SYSTEM_MODE
                LIMIT 1
            ];
        } else {
            logRecord = buildGenerationLog(caseId, jobId, TPL_Constants.STATUS_FAILED, errorMessage);
        }

        logRecord.Status__c = TPL_Constants.STATUS_FAILED;
        logRecord.Error_Message__c = errorMessage;
        logRecord.Stack_Trace__c = stackTrace;
        logRecord.Class_Name__c = className;
        logRecord.Method_Name__c = methodName;
        logRecord.Record_Id__c = caseId == null ? null : String.valueOf(caseId);
        logRecord.JobId__c = jobId;
        upsertLogsInSystemMode(new List<SObject>{ logRecord });
    }

    public static void logExtendedStatus(Id batchId, Id rootBatchJobId) {
        AsyncApexJob job = [
            SELECT Status, ExtendedStatus
            FROM AsyncApexJob
            WHERE Id = :batchId
            LIMIT 1
        ];

        if (job.Status ==  TPL_Constants.STATUS_COMPLETED && !String.isBlank(job.ExtendedStatus)) {
            LogService.markChunkFailed(
                rootBatchJobId,
                batchId,
                job.ExtendedStatus,
                null,
                'HealthIdeasApiCalloutBatch',
                'execute'
            );
        }
    }

}