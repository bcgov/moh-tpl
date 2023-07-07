/*
* Company: CGI for BC Ministry of Health
* Date: May 30, 2023
* Author: Ahmed Shaik
* Description: Healthcare Cost object level trigger written to calculate the rollup summary total based on CRUD operations on HC Cost record.
Trigger covers after insert, after update, and after delete scenarios
* History:
*     Initial version: June 10, 2023 - AS
*/

trigger HealthcareCostTrigger on Healthcare_Cost__c (after insert,after update, after delete) {
    if(Trigger.isAfter){
        if(Trigger.isInsert || Trigger.isUpdate ){
            if(HealthcareCostTriggerHandler.isFirstTime){
                HealthcareCostTriggerHandler.isFirstTime = false;
                HealthcareCostTriggerHandler.updateRollup(Trigger.new);
            }
            
        }
    }
    if(Trigger.isAfter && Trigger.isDelete){
        if(HealthcareCostTriggerHandler.isFirstTime){
            HealthcareCostTriggerHandler.isFirstTime = false;  
            HealthcareCostTriggerHandler.updateRollup(Trigger.old);
        }
    }
    
}