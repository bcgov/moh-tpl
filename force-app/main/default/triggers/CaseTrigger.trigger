/*
* Company: CGI for BC Ministry of Health
* Date: April 16, 2025
* Author: Ranadheer Reddy
* Description: This is created to make sure the the default values for the below fields will be always 0.00 instead of blank values
*
*/
trigger CaseTrigger on Case (before insert, before update, after insert, after update) {

    // BEFORE: Initialize default child and parent totals
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        for (Case c : Trigger.new) {
            if (c.Pharmacare_Total2__c == null) c.Pharmacare_Total2__c = 0.00;
            if (c.Continuing_Care_Total2__c == null) c.Continuing_Care_Total2__c = 0.00;
            if (c.Ambulance_Total2__c == null) c.Ambulance_Total2__c = 0.00;
            if (c.Future_Care_Total2__c == null) c.Future_Care_Total2__c = 0.00;
            if (c.Hospitalization_Total2__c == null) c.Hospitalization_Total2__c = 0.00;
            if (c.MSP_Total2__c == null) c.MSP_Total2__c = 0.00;
            if (c.Related_Cases_Recovery_Amount__c == null) c.Related_Cases_Recovery_Amount__c = 0.00;

            if (c.Ambulance_Total_ClassAction__c == null) c.Ambulance_Total_ClassAction__c = 0.00;
            if (c.Continuing_Care_Total_ClassAction__c == null) c.Continuing_Care_Total_ClassAction__c = 0.00;
            if (c.Future_Care_Total_ClassAction__c == null) c.Future_Care_Total_ClassAction__c = 0.00;
            if (c.Hospitalization_Total_ClassAction__c == null) c.Hospitalization_Total_ClassAction__c = 0.00;
            if (c.MSP_Total_ClassAction__c == null) c.MSP_Total_ClassAction__c = 0.00;
            if (c.Pharmacare_Total_ClassAction__c == null) c.Pharmacare_Total_ClassAction__c = 0.00;
        }
    }

    // AFTER: Recalculate parent aggregates
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        CaseTriggerHandler.handleAggregateToParent(Trigger.new);
    }
}