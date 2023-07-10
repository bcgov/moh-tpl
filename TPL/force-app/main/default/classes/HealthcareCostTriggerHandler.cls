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
    
    /*
* Description: Method to calculate the sum of cost parameter used in the object grouped by record types
* Parameters:
*     List<Healthcare_Cost__c> hccList: It contains the list of Healthcare cost records associated with the given case
* 
*/
    public static void updateRollup(List<Healthcare_Cost__c> hccList){
        set<Id> caseIds = new set<Id>();
        for(Healthcare_Cost__c hcc : hccList){
            caseIds.add(hcc.Case2__c);
        }
        List<AggregateResult> groupedResults = [SELECT SUM(Total_Cost_Override__c)tot,case2__c,RecordType.DeveloperName,sum(Cost__c)costSum FROM Healthcare_Cost__c WHERE Case2__c IN:caseIds AND ((Cost_Include__c = true AND Cost_Review__c = true) OR (RecordType.DeveloperName IN ('Continuing_Care','Future_Care'))) GROUP BY case2__c,RecordType.DeveloperName] ;
        List<Case> caseUpdateList = new List<Case>();
        Map<Id,case> caseMap = new Map<Id,case>();
        for(AggregateResult agg : groupedResults){
            Case c = new Case();
            if(caseMap.containsKey((String)agg.get('case2__c'))){
                c = caseMap.get((String)agg.get('case2__c'));
            }else{
                c.id = (String)agg.get('case2__c');
                c.Pharmacare_Total2__c = 0.0;
                c.Continuing_Care_Total2__c =0.0;
                c.Ambulance_Total2__c = 0.0;
                c.Future_Care_Total2__c = 0.0;
                c.Hospitalization_Total2__c = 0.0;
                c.MSP_Total2__c = 0.0;
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
                c.Hospitalization_Total2__c = (Decimal)agg.get('tot');
            }
            if((String)agg.get('DeveloperName') == 'MSP'){
                c.MSP_Total2__c = (Decimal)agg.get('tot');
            }
            caseMap.put(c.id,c); 
        }
        try{
            update caseMap.values();
        }Catch(Exception e){
            System.debug(e.getMessage());
        }
    }
}