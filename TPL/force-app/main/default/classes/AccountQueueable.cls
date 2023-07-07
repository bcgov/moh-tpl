/*
* Company: CGI for BC Ministry of Health
* Date: May 30, 2023
* Author: Ahmed Shaik
* Description: public with sharing class AccountQueueable that implements the Queueable functionality for Account level grids
*    Methods:
*         execute(QueueableContext context) : executes the Queueable Context where a batch update is performed on Healthcare Cost Records
* History:
*     Initial version: June 10, 2023 - AS
*/

public with sharing class AccountQueueable implements Queueable {
    private List<Healthcare_cost__c> hccupdateList;
    Integer BatchSize = 200;
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
        Database.saveResult[] sr = database.update(activeBatch,false); 
        if (followupJob != null) {
            if(!Test.isRunningTest()) {                        
                System.enqueueJob(followupJob);
            }
        }
    }
}