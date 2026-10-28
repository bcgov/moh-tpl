/*
* Company: CGI for BC Ministry of Health
* Date: April 16, 2025
* Author: Ranadheer Reddy
* Description: As the total cost are saved, identify if any parent case associated with the child case. If yes, update all the total cost respectively in the parent case and display the updated record. Analysis in progress.
*
*/
public class CaseTriggerHandler {

    public static void handleAggregateToParent(List<Case> newCases) {
        try {
            Set<Id> parentIds = new Set<Id>();
            Set<Id> oldParentIds = new Set<Id>();

            Map<Id, Case> oldCaseMap = Trigger.isUpdate ? (Map<Id, Case>) Trigger.oldMap : new Map<Id, Case>();

            for (Case c : newCases) {
                if (c.RecordTypeId != null && c.ParentId != null) {
                    parentIds.add(c.ParentId);
                }

                Case oldCase = oldCaseMap.get(c.Id);
                if (oldCase != null && oldCase.ParentId != null && oldCase.ParentId != c.ParentId) {
                    oldParentIds.add(oldCase.ParentId);
                }
            }

            Set<Id> allParentIds = new Set<Id>();
            allParentIds.addAll(parentIds);
            allParentIds.addAll(oldParentIds);

            if (allParentIds.isEmpty()) return;

            List<Case> allChildCases = [
                SELECT Id, ParentId,
                    Ambulance_Total2__c,
                    Hospitalization_Total2__c,
                    MSP_Total2__c,
                    Pharmacare_Total2__c,
                    Continuing_Care_Total2__c,
                    Future_Care_Total2__c,
                    Recovery_Amount__c
                FROM Case
                WHERE ParentId IN :allParentIds
            ];

            Map<Id, Case> parentUpdates = new Map<Id, Case>();

            for (Case child : allChildCases) {
                Id parentId = child.ParentId;
                if (!parentUpdates.containsKey(parentId)) {
                    parentUpdates.put(parentId, new Case(
                        Id = parentId,
                        Ambulance_Total_ClassAction__c = 0,
                        Hospitalization_Total_ClassAction__c = 0,
                        MSP_Total_ClassAction__c = 0,
                        Pharmacare_Total_ClassAction__c = 0,
                        Continuing_Care_Total_ClassAction__c = 0,
                        Future_Care_Total_ClassAction__c = 0,
                        Related_Cases_Recovery_Amount__c = 0
                    ));
                }

                Case parent = parentUpdates.get(parentId);
                parent.Ambulance_Total_ClassAction__c += child.Ambulance_Total2__c != null ? child.Ambulance_Total2__c : 0;
                parent.Hospitalization_Total_ClassAction__c += child.Hospitalization_Total2__c != null ? child.Hospitalization_Total2__c : 0;
                parent.MSP_Total_ClassAction__c += child.MSP_Total2__c != null ? child.MSP_Total2__c : 0;
                parent.Pharmacare_Total_ClassAction__c += child.Pharmacare_Total2__c != null ? child.Pharmacare_Total2__c : 0;
                parent.Continuing_Care_Total_ClassAction__c += child.Continuing_Care_Total2__c != null ? child.Continuing_Care_Total2__c : 0;
                parent.Future_Care_Total_ClassAction__c += child.Future_Care_Total2__c != null ? child.Future_Care_Total2__c : 0;
                parent.Related_Cases_Recovery_Amount__c += child.Recovery_Amount__c != null ? child.Recovery_Amount__c : 0;
            }

            if (!parentUpdates.isEmpty()) {
                update parentUpdates.values();
            }

        } catch (Exception e) {
            System.debug('Error in CaseTriggerHandler: ' + e.getMessage());
        }
    }
}