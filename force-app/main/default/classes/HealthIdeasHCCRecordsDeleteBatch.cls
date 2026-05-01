/**
 * Author: Nikhil Jeenru
 * Company : CGI
 * Deletes eligible Healthcare Cost records, then starts the insert batch
 * to reload refreshed HealthIdeas data.
 */
global class HealthIdeasHCCRecordsDeleteBatch implements Database.Batchable<SObject>, Database.Stateful {

    private Id accountId;
    private Date asOfDate;
    private String jsonData;
    private Map<String, Id> recordTypeIds;

    // Initializes values needed for delete and insert processing.
    global HealthIdeasHCCRecordsDeleteBatch(Id accountId, Date asOfDate,
                                  String jsonData,
                                  Map<String, Id> recordTypeIds) {
        this.accountId = accountId;
        this.asOfDate = asOfDate;
        this.jsonData = jsonData;
        this.recordTypeIds = recordTypeIds;
    }

    // Selects Healthcare Cost records that should be deleted.
    global Database.QueryLocator start(Database.BatchableContext bc) {
         return Database.getQueryLocator([
            SELECT Id
            FROM Healthcare_Cost__c
            WHERE Account__c = :accountId
              AND RecordTypeId IN :new List<Id>{
                  recordTypeIds.get('Pharmacare'),
                  recordTypeIds.get('Hospitalization'),
                  recordTypeIds.get('MSP')
              }
              AND Date_of_Service__c < :asOfDate
              AND Cost_Review__c = false
              AND Cost_Include__c = false
              AND (Case2__c = null OR Case2__c = '')
        ]);
    }

    // Deletes the current batch of records.
    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        delete scope;
    }

    // Starts the insert batch after deletion completes.
    global void finish(Database.BatchableContext bc) {

        Database.executeBatch(
            new HealthIdeasInsertHCCRecordsBatch(jsonData, accountId, recordTypeIds),
            200
        );
    }
}