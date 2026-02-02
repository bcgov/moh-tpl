/*
* Company: CGI for BC Ministry of Health
* Date: June 10, 2023
* Author: Ahmed Shaik
* Description: public with sharing class HealthcareCostTriggerHandler implements the rollup summary concept on the case object. Whenever the Healthcare Cost record associated with the case is updated. It updates the respective associated total sum values
*    Methods:
*         updateRollup(List<Healthcare_Cost__c> hccList): Method to calculate the sum of cost parameter used in the object grouped by record types
* History:
*     Initial version: June 10, 2023 - AS
*/

public with sharing class HealthcareCostTriggerHandler {
    public static Boolean isFirstTime = true;
    
    
    public static void beforeInsertRecord(List<Healthcare_Cost__c> hccList){
        Data_Migration_Check__c dmc = Data_Migration_Check__c.getInstance();
        if (dmc == null || dmc.Bypass_Flow_Validations__c != true) {
            Set<Id> productIds = new Set<Id>();
            for (Healthcare_Cost__c hccRecord : hccList){
                if (hccRecord.Service_Provided_by_Facility__c != null && hccRecord.RecordTypeName__c == 'Hospitalization'){
                    productIds.add(hccRecord.Service_Provided_by_Facility__c);
                }
            }
            Id tplPricebookId;

            List<Pricebook2> pbList = [
                SELECT Id
                FROM Pricebook2
                WHERE Name = 'TPL Price Book'
                AND IsActive = true
                LIMIT 1
            ];
            
            if (!pbList.isEmpty()) {
                tplPricebookId = pbList[0].Id;
            }
            
            Map<Id, PricebookEntry> productToPbeMap = new Map<Id, PricebookEntry>();

            if (tplPricebookId != null && !productIds.isEmpty()) {
                for (PricebookEntry pbe : [
                    SELECT Id, Product2Id, UnitPrice
                    FROM PricebookEntry
                    WHERE Product2Id IN :productIds
                    AND Pricebook2Id = :tplPricebookId
                ]) {
                    productToPbeMap.put(pbe.Product2Id, pbe);
                }
            }
            
            for (Healthcare_Cost__c hcc : hccList) {
                if (
                    hcc.Service_Provided_by_Facility__c != null && hcc.RecordTypeName__c == 'Hospitalization' &&
                    productToPbeMap.containsKey(hcc.Service_Provided_by_Facility__c)
                ) {
                    hcc.Standard_Daily_Rate__c =
                        productToPbeMap.get(hcc.Service_Provided_by_Facility__c).UnitPrice;
                }
            }
            
        }
    }
    
    public static void beforeUpdateRecord(List<Healthcare_Cost__c> hccList, Map<Id,Healthcare_Cost__c> oldHccMap){
        Data_Migration_Check__c dmc = Data_Migration_Check__c.getInstance();
        if (dmc == null || dmc.Bypass_Flow_Validations__c != true) {
            for (Healthcare_Cost__c hccRecord : hccList) {
                Healthcare_Cost__c oldRec = oldHccMap.get(hccRecord.Id);
                if (
                    hccRecord.Service_Provided_by_Facility__c != null &&
                    hccRecord.RecordTypeName__c == 'Hospitalization' &&
                    (
                        hccRecord.Date_of_Admission__c        != oldRec.Date_of_Admission__c ||
                        hccRecord.Date_of_Discharge__c        != oldRec.Date_of_Discharge__c ||
                        hccRecord.Service_Provided_by_Facility__c != oldRec.Service_Provided_by_Facility__c
                    )
                ) {
                    hccRecord.Total_Cost_Override__c = null;
                }
            }
        }
    }
    
    /*
* Description: Method to calculate the sum of cost parameter used in the object grouped by record types
* Parameters:
*     List<Healthcare_Cost__c> hccList: It contains the list of Healthcare cost records associated with the given case
* 
*/
    public static void updateRollup(List<Healthcare_Cost__c> hccList){
        Set<Id> caseIds = new set<Id>();
        Map<Id,case> caseMap = new Map<Id,case>();
        for(Healthcare_Cost__c hcc : hccList){
            caseIds.add(hcc.Case2__c);
        }
        for(Id caseId: caseIds){
            Case c = new Case();
            c.Id = caseId;
            c.Pharmacare_Total2__c = 0.00;
            c.Continuing_Care_Total2__c = 0.00;
            c.Ambulance_Total2__c = 0.00;
            c.Future_Care_Total2__c = 0.00;
            c.Hospitalization_Total2__c = 0.00;
            c.MSP_Total2__c = 0.00;
            c.Ambulance_Total_ClassAction__c = 0.00;
            c.Continuing_Care_Total_ClassAction__c = 0.00;
            c.Future_Care_Total_ClassAction__c = 0.00;
            c.Hospitalization_Total_ClassAction__c = 0.00;
            c.MSP_Total_ClassAction__c = 0.00;
            c.Pharmacare_Total_ClassAction__c = 0.00;
            c.Related_Cases_Recovery_Amount__c = 0.00;
            caseMap.put(caseId, c);
        }
        Map<Id, Decimal> caseVsStandardCostMap = new Map<Id, Decimal>();
        List<AggregateResult> groupedStandardCostResults = [SELECT SUM(Total_Costs_Standard__c)totStandard,case2__c,RecordType.DeveloperName FROM Healthcare_Cost__c WHERE Case2__c IN:caseIds AND (Cost_Include__c = true AND Cost_Review__c = true AND RecordType.DeveloperName='Hospitalization' AND Total_Cost_Override__c =null AND Total_Costs_Standard__c !=null AND Case2__c !=null)  GROUP BY case2__c,RecordType.DeveloperName];
        for(AggregateResult agg : groupedStandardCostResults){
            caseVsStandardCostMap.put((String)agg.get('case2__c'), (Decimal)agg.get('totStandard'));
        }
        List<AggregateResult> groupedResults = [SELECT SUM(Total_Cost_Override__c)tot,case2__c,RecordType.DeveloperName,sum(Cost__c)costSum FROM Healthcare_Cost__c WHERE Case2__c IN:caseIds AND ((Cost_Include__c = true AND Cost_Review__c = true) OR (RecordType.DeveloperName IN ('Continuing_Care','Future_Care'))) GROUP BY case2__c,RecordType.DeveloperName] ;
        List<Case> caseUpdateList = new List<Case>();
        for(AggregateResult agg : groupedResults){
            Case c = new Case();
            if(caseMap.containsKey((String)agg.get('case2__c'))){
                c = caseMap.get((String)agg.get('case2__c'));
            }
            if((String)agg.get('DeveloperName') == 'Pharmacare'){
                c.Pharmacare_Total2__c = (Decimal)agg.get('tot');
            }
            if((String)agg.get('DeveloperName') == 'Continuing_Care'){
                c.Continuing_Care_Total2__c = (Decimal)agg.get('costSum');
            }
            if((String)agg.get('DeveloperName') == 'Ambulance'){
                c.Ambulance_Total2__c = (Decimal)agg.get('tot');
            }
            if((String)agg.get('DeveloperName') == 'Future_Care'){
                c.Future_Care_Total2__c = (Decimal)agg.get('costSum');
            }
            if((String)agg.get('DeveloperName') == 'Hospitalization'){
                c.Hospitalization_Total2__c = ((Decimal)agg.get('tot')!=null ? (Decimal)agg.get('tot') : 0.0 ) + (caseVsStandardCostMap.containsKey((String)agg.get('case2__c')) ? caseVsStandardCostMap.get((String)agg.get('case2__c')) : 0);
            }
            if((String)agg.get('DeveloperName') == 'MSP'){
                c.MSP_Total2__c = (Decimal)agg.get('tot');
            }
            caseMap.put(c.id,c); 
        }

         // Ensure fields are not null before update
         for (Case c : caseMap.values()) {
            if (c.Pharmacare_Total2__c == null) c.Pharmacare_Total2__c = 0.00;
            if (c.Continuing_Care_Total2__c == null) c.Continuing_Care_Total2__c = 0.00;
            if (c.Ambulance_Total2__c == null) c.Ambulance_Total2__c = 0.00;
            if (c.Future_Care_Total2__c == null) c.Future_Care_Total2__c = 0.00;
            if (c.Hospitalization_Total2__c == null) c.Hospitalization_Total2__c = 0.00;
            if (c.MSP_Total2__c == null) c.MSP_Total2__c = 0.00;
            if (c.Ambulance_Total_ClassAction__c == null) c.Ambulance_Total_ClassAction__c = 0.00;
            if (c.Continuing_Care_Total_ClassAction__c == null) c.Continuing_Care_Total_ClassAction__c = 0.00;
            if (c.Future_Care_Total_ClassAction__c == null) c.Future_Care_Total_ClassAction__c = 0.00;
            if (c.Hospitalization_Total_ClassAction__c == null) c.Hospitalization_Total_ClassAction__c = 0.00;
            if (c.MSP_Total_ClassAction__c == null) c.MSP_Total_ClassAction__c = 0.00;
            if (c.Pharmacare_Total_ClassAction__c == null) c.Pharmacare_Total_ClassAction__c = 0.00;
            if (c.Related_Cases_Recovery_Amount__c == null) c.Related_Cases_Recovery_Amount__c = 0.00;
        }


        try{
            update caseMap.values();
        }Catch(Exception e){
            System.debug('error message in updateRollup method '+e.getMessage()+ ' line:->>>'+e.getLineNumber());
        }
    }
}