/**
* Author: Nikhil Jeenru
* Company: CGI
* Purpose:
* This queueable inserts HealthIdeas hospitalization Healthcare Cost records and then starts
* the pharmacare queueable when chaining is enabled.
*/
public with sharing class HealthIdeasHospitalizationQueueable implements Queueable {
    
    @TestVisible
    private static Boolean allowQueueableChaining = true;
    
    private Id accountId;
    private List<HealthIdeasApiIntegration.HospitalizationHccRecord> hospList;
    private Id hospRecordTypeId;
    
    private List<HealthIdeasApiIntegration.PharmacareHccRecord> pharmaList;
    private Id pharmaRecordTypeId;
    
    private Id rootBatchJobId;
    private String accumulatedErrorMessage;
    
    private String requesterUserName;
    private Date currentEndDate;
    
    public HealthIdeasHospitalizationQueueable(
        Id accountId,
        List<HealthIdeasApiIntegration.HospitalizationHccRecord> hospList,
        Id hospRecordTypeId,
        List<HealthIdeasApiIntegration.PharmacareHccRecord> pharmaList,
        Id pharmaRecordTypeId,
        Id rootBatchJobId,
        String accumulatedErrorMessage,
        String requesterUserName,
        Date currentEndDate
    ) {
        this.accountId = accountId;
        this.hospList = hospList;
        this.hospRecordTypeId = hospRecordTypeId;
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
            List<HealthIdeasApiIntegration.HospitalizationHccRecord> records =
                hospList == null
                ? new List<HealthIdeasApiIntegration.HospitalizationHccRecord>()
                : hospList;
            
            if (!records.isEmpty()) {
                List<Healthcare_Cost__c> recordsToInsert =
                    HealthIdeasApiIntegration.buildHospitalizationHealthcareCostRecords(
                        records,
                        accountId,
                        hospRecordTypeId
                    );
                
                if (!recordsToInsert.isEmpty()) {
                    Database.SaveResult[] insertResults =
                        Database.insert(recordsToInsert, false);
                    
                    errorMessage = LogService.appendHealthcareCostInsertMessages(
                        errorMessage,
                        insertResults,
                        recordsToInsert
                    );
                }
            }
            
            if (allowQueueableChaining) {
                System.enqueueJob(
                    new HealthIdeasPharmacareQueueable(
                        accountId,
                        pharmaList,
                        pharmaRecordTypeId,
                        rootBatchJobId,
                        errorMessage,
                        requesterUserName,
                        currentEndDate
                    )
                ); 
            }
        } catch (Exception e) {
            LogService.markChunkFailed(
                rootBatchJobId,
                context.getJobId(),
                e.getMessage()
            );
        }
    }
}