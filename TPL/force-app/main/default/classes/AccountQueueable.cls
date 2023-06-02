public with sharing class AccountQueueable implements Queueable {
    private List<Healthcare_cost__c> hccupdateList;
    Integer BatchSize = 5000;
    private AccountQueueable followupJob;
    public AccountQueueable(List<Healthcare_cost__c> hccList){
        this.hccupdateList = hccList;

    }
    public void execute(QueueableContext context) {
        Integer counter = 0;
        List<Healthcare_cost__c> hccupdateListOf200 = new List<Healthcare_cost__c>();
        Integer size = this.hccupdateList.size();
        Schema.SObjectType sObjectType = hccupdateList.getSObjectType();
        List<SObject> activeBatch = (List<SObject>)Type.forName('List<' + sObjectType + '>').newInstance();
        if (size > BatchSize) {
            // take the last <BatchSize> records from the top and put the rest in the next queueable
            for (Integer i = size-1; i > size-BatchSize; i--) {
                activeBatch.add(this.hccupdateList.remove(i));
            }
            followupJob = new AccountQueueable( this.hccupdateList);
    
        } else {
            activeBatch = this.hccupdateList;
        }
        System.debug(LoggingLevel.INFO, 'Updating ' + activeBatch.size() + ' ' + sObjectType + ' records.');
        Database.saveResult[] sr = database.update(activeBatch,false); 
        if (followupJob != null) {
            if(!Test.isRunningTest()) {                        
                System.enqueueJob(followupJob);
            }
        }
        System.debug(activeBatch);      
    }
}