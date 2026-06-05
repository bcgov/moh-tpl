/**
* Author: Nikhil Jeenru
* Company: CGI
* Purpose:
* This queueable inserts HealthIdeas pharmacare Healthcare Cost records, updates the async
* processing status, and starts the next HealthIdeas batch chunk when chaining is enabled.
*/
public with sharing class HealthIdeasPharmacareQueueable implements Queueable {
    
    @TestVisible
    private static Boolean allowNextBatchChaining = true;
    
    private Id accountId;
    private List<HealthIdeasApiIntegration.PharmacareHccRecord> pharmaList;
    private Id pharmaRecordTypeId;
    
    private Id rootBatchJobId;
    private String accumulatedErrorMessage;
    
    private String requesterUserName;
    private Date currentEndDate;
    
    public HealthIdeasPharmacareQueueable(
        Id accountId,
        List<HealthIdeasApiIntegration.PharmacareHccRecord> pharmaList,
        Id pharmaRecordTypeId,
        Id rootBatchJobId,
        String accumulatedErrorMessage,
        String requesterUserName,
        Date currentEndDate
    ) {
        this.accountId = accountId;
        this.pharmaList = pharmaList;
        this.pharmaRecordTypeId = pharmaRecordTypeId;
        this.rootBatchJobId = rootBatchJobId;
        this.accumulatedErrorMessage = accumulatedErrorMessage;
        this.requesterUserName = requesterUserName;
        this.currentEndDate = currentEndDate;
    }
    
    public void execute(QueueableContext context) {
        String errorMessage = accumulatedErrorMessage;
        
        try {
            List<HealthIdeasApiIntegration.PharmacareHccRecord> records =
                pharmaList == null
                ? new List<HealthIdeasApiIntegration.PharmacareHccRecord>()
                : pharmaList;
            
            if (!records.isEmpty()) {
                List<Healthcare_Cost__c> recordsToInsert =
                    HealthIdeasApiIntegration.buildPharmacareHealthcareCostRecords(
                        records,
                        accountId,
                        pharmaRecordTypeId
                    );
                
                if (!recordsToInsert.isEmpty()) {
                    Database.SaveResult[] insertResults =
                        Database.insert(recordsToInsert, false);
                    
                    errorMessage = LogService.appendHealthcareCostInsertMessages(
                        errorMessage,
                        insertResults,
                        recordsToInsert,
                        TPL_Constants.HCC_PHARMA_RECORDTYPE_NAME
                    ); 
                }
            }
            
            LogService.markChunkFinished(
                rootBatchJobId,
                context.getJobId(),
                errorMessage
            );
            
            if (
                allowNextBatchChaining &&
                !LogService.isAsyncFailed(rootBatchJobId) &&
                currentEndDate != null &&
                currentEndDate < Date.today()
            ) {
                Database.executeBatch(
                    new HealthIdeasApiCalloutBatch(
                        accountId,
                        currentEndDate,
                        requesterUserName,
                        rootBatchJobId
                    ),
                    1
                );
            }
        } catch (Exception e) {
            string stackTrace = e.getStackTraceString();
            LogService.markChunkFailed(
                rootBatchJobId,
                context.getJobId(),
                e.getMessage(),
                stackTrace,
                'HealthIdeasPharmacareQueueable',
                'execute'
            ); 
        }
    }
}