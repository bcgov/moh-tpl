/**
* Author: Nikhil Jeenru
* Company: CGI
* Purpose:
* This batch deletes eligible Healthcare Cost records before starting the
* HealthIdeas API callout batch for refreshed Healthcare Cost data.
*/
public with sharing class HealthIdeasHCCRecordsDeleteBatch
    implements Database.Batchable<SObject> {

    private Id accountId;
    private Date asOfDate;
    private String requesterUserName;

    public HealthIdeasHCCRecordsDeleteBatch(
        Id accountId,
        Date asOfDate,
        String requesterUserName
    ) {
        this.accountId = accountId;
        this.asOfDate = asOfDate;
        this.requesterUserName = requesterUserName;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Map<String, Id> recordTypeIds =
            HealthIdeasApiIntegration.getHealthcareCostRecordTypeIds();

        return Database.getQueryLocator([
            SELECT Id
            FROM Healthcare_Cost__c
            WHERE Account__c = :accountId
            AND RecordTypeId IN :recordTypeIds.values()
            AND (
                Date_of_Service__c < :asOfDate
                OR Date_of_Admission__c < :asOfDate
            )
            AND Cost_Review__c = false
            AND Cost_Include__c = false
            AND (Case2__c = null OR Case2__c = '')
        ]);
    }

    public void execute(
        Database.BatchableContext bc,
        List<Healthcare_Cost__c> scope
    ) {
        Database.DeleteResult[] deleteResults =
            Database.delete(scope, false);

        for (Integer i = 0; i < deleteResults.size(); i++) {
            if (!deleteResults[i].isSuccess()) {
                for (Database.Error err : deleteResults[i].getErrors()) {
                    LogService.appendAsyncError(
                        bc.getJobId(),
                        TPL_Constants.ERROR_DELETE_FAILED_HEALTHCARE_COST +
                        String.valueOf(scope[i].Id) +
                        ': ' +
                        err.getMessage()
                    );
                }
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        LogService.updateAsyncStatus(
            bc.getJobId(),
            TPL_Constants.STATUS_PROCESSING
        );

        Database.executeBatch(
            new HealthIdeasApiCalloutBatch(
                accountId,
                asOfDate,
                requesterUserName,
                bc.getJobId()
            ),
            1
        );
    }
}