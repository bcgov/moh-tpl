/*
* Company: CGI for BC Ministry of Health
* Date: May 30, 2023
* Author: Ahmed Shaik
* Description: Healthcare Cost object level trigger written to calculate the rollup summary total based on CRUD operations on HC Cost record.
Trigger covers after insert, after update, and after delete scenarios
* History:
*     Initial version: June 10, 2023 - AS
*     Revised version: Feb 03, 2025 - AJ
*/

trigger HealthcareCostTrigger on Healthcare_Cost__c (before insert, after insert,before update, after update, after delete) {

    if(Trigger.isBefore){
        
        if(Trigger.isInsert){
            HealthcareCostTriggerHandler.beforeInsertRecord(Trigger.new);
        }
        if(Trigger.isUpdate){
            HealthcareCostTriggerHandler.beforeUpdateRecord(Trigger.new, Trigger.oldmap);
        }
    }
    // AFTER logic: Handle insert, update, or delete of Healthcare_Cost__c
    if (Trigger.isAfter) {

        // Handle insert and update
        if (Trigger.isInsert || Trigger.isUpdate) {
            // If this is the first time the trigger is running, update rollups
            if (HealthcareCostTriggerHandler.isFirstTime) {
                HealthcareCostTriggerHandler.isFirstTime = false;
                HealthcareCostTriggerHandler.updateRollup(Trigger.new);
            }
        }

        // Handle delete
        if (Trigger.isDelete) {
            // If this is the first time the trigger is running for delete, update rollups
            if (HealthcareCostTriggerHandler.isFirstTime) {
                HealthcareCostTriggerHandler.isFirstTime = false;
                HealthcareCostTriggerHandler.updateRollup(Trigger.old);
            }
        }
    }
}