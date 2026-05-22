/**
 * Author: Nikhil Jeenru
 * Company: CGI
 * Purpose:
 * Inserts Log__c records in separate batch transactions so logging does not
 * consume the main queueable transaction's DML row limits.
 */
public with sharing class LogInsertBatch implements Database.Batchable<Log__c> {

    private List<Log__c> logs;

    public LogInsertBatch(List<Log__c> logs) {
        this.logs = logs == null ? new List<Log__c>() : logs;
    }

    public Iterable<Log__c> start(Database.BatchableContext bc) {
        return logs;
    }

    public void execute(Database.BatchableContext bc, List<Log__c> scope) {
        if (scope == null || scope.isEmpty()) {
            return;
        }

        try {
             Database.SaveResult[] results =  LogService.upsertLogsInSystemModeWithReturnValue(scope);

            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    for (Database.Error err : results[i].getErrors()) {
                        System.debug(
                            LoggingLevel.ERROR,
                            TPL_Constants.ERROR_FAILED_TO_INSERT_LOG +
                            err.getMessage() +
                            TPL_Constants.ERROR_FIELDS +
                            String.valueOf(err.getFields())
                        );
                    }
                }
            }
        } catch (Exception e) {
            System.debug(
                LoggingLevel.ERROR,
                TPL_Constants.ERROR_FAILED_TO_INSERT_LOG_RECORDS + e.getMessage()
            );
        }
    }

    public void finish(Database.BatchableContext bc) {
    }
}