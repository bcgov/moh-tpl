/**
* Author: Nikhil Jeenru
* Company: CGI
* Purpose:
* This queueable inserts HealthIdeas MSP Healthcare Cost records and then starts
* the hospitalization queueable when chaining is enabled.
*/
public with sharing class HealthIdeasMspQueueable implements Queueable {    
    @TestVisible
    private static Boolean allowQueueableChaining = true;
    
    private Id accountId;
    private List<HealthIdeasApiIntegration.MspHccRecord> mspList;
    private Id mspRecordTypeId;
    
    private List<HealthIdeasApiIntegration.HospitalizationHccRecord> hospList;
    private Id hospRecordTypeId;
    
    private List<HealthIdeasApiIntegration.PharmacareHccRecord> pharmaList;
    private Id pharmaRecordTypeId;
    
    private Id rootBatchJobId;
    private String accumulatedErrorMessage;
    
    private String requesterUserName;
    private Date currentEndDate;
    
    public HealthIdeasMspQueueable(
        Id accountId,
        List<HealthIdeasApiIntegration.MspHccRecord> mspList,
        Id mspRecordTypeId,
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
        this.mspList = mspList;
        this.mspRecordTypeId = mspRecordTypeId;
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
            List<HealthIdeasApiIntegration.MspHccRecord> records =
                mspList == null
                ? new List<HealthIdeasApiIntegration.MspHccRecord>()
                : mspList;
            
            if (!records.isEmpty()) {
                List<Healthcare_Cost__c> recordsToInsert =
                    HealthIdeasApiIntegration.buildMspHealthcareCostRecords(
                        records,
                        accountId,
                        mspRecordTypeId
                    );
                
                if (!recordsToInsert.isEmpty()) {
                    Database.SaveResult[] insertResults =
                        Database.insert(recordsToInsert, false);
                    
                    errorMessage = LogService.appendHealthcareCostInsertMessages(
                        errorMessage,
                        insertResults,
                        recordsToInsert,
                        TPL_Constants.HCC_MSP_RECORDTYPE_NAME
                    ); 
                }
            }
            
            if (allowQueueableChaining) {
                System.enqueueJob(
                    new HealthIdeasHospitalizationQueueable(
                        accountId,
                        hospList,
                        hospRecordTypeId,
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
                e.getMessage(),
                e.getStackTraceString(),
                'HealthIdeasMspQueueable',
                'execute'
            ); 
        } 
    }
}