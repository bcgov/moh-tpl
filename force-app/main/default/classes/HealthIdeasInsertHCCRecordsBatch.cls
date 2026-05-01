/**
 * Author: Nikhil Jeenru
 * Company : CGI
 * Inserts Healthcare Cost records created from HealthIdeas response data.
 */
global class HealthIdeasInsertHCCRecordsBatch implements Database.Batchable<String> {

    private String jsonData;
    private Id accountId;
    private Map<String, Id> recordTypeIds;

    // Initializes batch input data and target record type mappings.
    global HealthIdeasInsertHCCRecordsBatch(String jsonData, Id accountId, Map<String, Id> recordTypeIds) {
        this.jsonData = jsonData;
        this.accountId = accountId;
        this.recordTypeIds = recordTypeIds;
    }

    // Starts the batch with the serialized payload as a single scope item.
    global Iterable<String> start(Database.BatchableContext bc) {
        return new List<String>{ jsonData };
    }

    // Deserializes payload, groups records by type, builds Healthcare Cost records, and inserts them.
    global void execute(Database.BatchableContext bc, List<String> scope) {

         HealthIdeasApiIntegration.HealthIdeasBatchPayload payload =
    (HealthIdeasApiIntegration.HealthIdeasBatchPayload)
    JSON.deserialize(scope[0], HealthIdeasApiIntegration.HealthIdeasBatchPayload.class);

    List<HealthIdeasApiIntegration.MspHccRecord> mspList =
        payload.msp == null
            ? new List<HealthIdeasApiIntegration.MspHccRecord>()
            : payload.msp;

    List<HealthIdeasApiIntegration.HospitalizationHccRecord> hospList =
        payload.hospitalizations == null
            ? new List<HealthIdeasApiIntegration.HospitalizationHccRecord>()
            : payload.hospitalizations;

    List<HealthIdeasApiIntegration.PharmacareHccRecord> pharmaList =
        payload.pharmacare == null
            ? new List<HealthIdeasApiIntegration.PharmacareHccRecord>()
            : payload.pharmacare;

        List<Healthcare_Cost__c> healthCareCostRecordsToInsertList = new List<Healthcare_Cost__c>();

        if (!mspList.isEmpty()) {
            healthCareCostRecordsToInsertList.addAll(HealthIdeasApiIntegration.buildMspHealthcareCostRecords(mspList, accountId, recordTypeIds.get('MSP')));
        }
        if (!hospList.isEmpty()) {
            healthCareCostRecordsToInsertList.addAll(HealthIdeasApiIntegration.buildHospitalizationHealthcareCostRecords(hospList, accountId, recordTypeIds.get('Hospitalization')));
        }
        if (!pharmaList.isEmpty()) {
            healthCareCostRecordsToInsertList.addAll(HealthIdeasApiIntegration.buildPharmacareHealthcareCostRecords(pharmaList, accountId, recordTypeIds.get('Pharmacare')));
        }

        if (!healthCareCostRecordsToInsertList.isEmpty()) {
            Database.insert(healthCareCostRecordsToInsertList, false);
        }
    }

    // No post-processing is needed after insert completes.
    global void finish(Database.BatchableContext bc) {}
}