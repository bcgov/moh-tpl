/**
 * Author: Nikhil Jeenru
 * Company: CGI
 * Purpose:
 * Handles HealthIdeas API callouts for one configured date chunk.
 * This batch retrieves HealthIdeas data for the selected Account and date range,
 * parses the API response, and starts the MSP queueable chain when payload data exists.
 * The next date chunk is started later by the Pharmacare queueable after the current
 * queueable chain finishes.
 */
public with sharing class HealthIdeasApiCalloutBatch
implements Database.Batchable<SObject>, Database.AllowsCallouts {
    
    private Id accountId;
    private Date asOfDate;
    private String requesterUserName;
    private Id rootBatchJobId;
    
    public HealthIdeasApiCalloutBatch(
        Id accountId,
        Date asOfDate,
        String requesterUserName,
        Id rootBatchJobId
    ) {
        this.accountId = accountId;
        this.asOfDate = asOfDate;
        this.requesterUserName = requesterUserName;
        this.rootBatchJobId = rootBatchJobId;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, PHN__pc
            FROM Account
            WHERE Id = :accountId
        ]);
    }
    
    public void execute(Database.BatchableContext bc, List<Account> scope) {
        try {
            if (scope.isEmpty()) {
                LogService.markChunkFailed(
                    rootBatchJobId,
                    bc.getJobId(),
                    TPL_Constants.ERROR_NO_ACCOUNT_FOUND_HEALTH_IDEAS,
                    null,
                    'HealthIdeasApiCalloutBatch',
                    'execute'
                );
                return;
            }
            
            Date currentEndDate =
                HealthIdeasApiIntegration.getHealthIdeasChunkEndDate(asOfDate);
            
            HealthIdeasApiIntegration.IntegrationResult result = HealthIdeasApiIntegration.sendHealthIdeasRequest(
                requesterUserName,
                scope[0],
                asOfDate,
                currentEndDate
            );

            if (!result.success) {
                LogService.markChunkFailed(
                    rootBatchJobId,
                    bc.getJobId(),
                    result.errorMessage,
                    null,
                    'HealthIdeasApiCalloutBatch',
                    'execute'
                );
                return;
            }
            
            HealthIdeasApiIntegration.HealthIdeasBatchPayload payload =
                HealthIdeasApiIntegration.parseHealthIdeasPayload(result.responseBody);
            
            Map<String, Id> recordTypeIds =
                HealthIdeasApiIntegration.getHealthcareCostRecordTypeIds();
            Boolean hasPayloadData =
                payload != null &&
                (
                    (payload.msp != null && !payload.msp.isEmpty()) ||
                    (payload.hospitalizations != null && !payload.hospitalizations.isEmpty()) ||
                    (payload.pharmacare != null && !payload.pharmacare.isEmpty())
                );
            
            if (hasPayloadData) {
                System.enqueueJob(
                    new HealthIdeasMspQueueable(
                        accountId,
                        payload.msp,
                        recordTypeIds.get(TPL_Constants.HCC_MSP_RECORDTYPE_NAME),
                        payload.hospitalizations,
                        recordTypeIds.get(TPL_Constants.HCC_HOSP_RECORDTYPE_NAME),
                        payload.pharmacare,
                        recordTypeIds.get(TPL_Constants.HCC_PHARMA_RECORDTYPE_NAME),
                        rootBatchJobId,
                        null,
                        requesterUserName,
                        currentEndDate
                    )
                );
            } else {
                // If no payload data, still need to enqueue the next chunk to move the process forward
                System.enqueueJob(
                    new HealthIdeasPharmacareQueueable(
                        accountId,
                        null,
                        recordTypeIds.get(TPL_Constants.HCC_PHARMA_RECORDTYPE_NAME),
                        rootBatchJobId,
                        null,
                        requesterUserName,
                        currentEndDate
                    )
                );
            } 
        } 
             catch (Exception e) {
            string stackTrace = e.getStackTraceString();
            LogService.markChunkFailed(
                rootBatchJobId,
                bc.getJobId(),
                e.getMessage(),
                stackTrace,
                'HealthIdeasApiCalloutBatch',
                'execute'
            ); 
        }
    }
    
    public void finish(Database.BatchableContext bc) {

        LogService.logExtendedStatus(bc.getJobId(), rootBatchJobId);
    }
}