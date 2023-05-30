public with sharing class HealthcareCostTriggerHandler {
    public static Boolean isFirstTime = true;
    public static void updateRollup(List<Healthcare_Cost__c> hccList){
        System.debug(hccList);
        set<Id> caseIds = new set<Id>();
        for(Healthcare_Cost__c hcc : hccList){
            caseIds.add(hcc.Case2__c);
        }
        System.debug(caseIds);
        List<Healthcare_Cost__c> hccSumList = [select id,Total_Cost_Override__c,case2__c,RecordTypeName__c,Cost__c,Cost_Include__c,Cost_Review__c from Healthcare_Cost__c where 
                                               case2__c IN:caseIds];
        System.debug(hccSumList);
        List<Case> caseUpdateList = new List<Case>();
        Decimal totalCostOverride =0;
        Decimal totalCost = 0;
        Map<Id,Case> caseMap = new Map<Id,Case>();
        Map<Id,Integer> totalCostMap = new Map<Id,Integer>();
        Map<Id,Map<String,Decimal>> caseIdRecordTypeSumMap = new Map<Id,Map<String,Decimal>>();
        Map<Id,Map<String,Decimal>> caseIdRecordTypeCostMap = new Map<Id,Map<String,Decimal>>();
        
        for(Healthcare_Cost__c hcc : hccSumList){
            System.debug(hcc);
            if(hcc.RecordTypeName__c != 'Continuing_Care' && hcc.RecordTypeName__c != 'Future_Care'){
                if(caseIdRecordTypeSumMap.containsKey(hcc.Case2__c)){
                    if(hcc.Cost_Include__c && hcc.Cost_Review__c){
                        Map<String,Decimal> tempMap = caseIdRecordTypeSumMap.get(hcc.Case2__c);
                        System.debug(tempMap);
                        if(tempMap.containskey(hcc.RecordTypeName__c)){
                            totalCostOverride = tempMap.get(hcc.RecordTypeName__c);
                            totalCostOverride = Integer.valueof(totalCostOverride + hcc.Total_Cost_Override__c);
                            tempMap.put(hcc.RecordTypeName__c,totalCostOverride);
                        }else{
                            tempMap.put(hcc.RecordTypeName__c,hcc.Total_Cost_Override__c);
                        } 
                        caseIdRecordTypeSumMap.put(hcc.Case2__c,tempMap);
                    }
                    
                }else{
                    Map<String,Decimal> tempMap = new Map<String,Decimal>();
                    if(hcc.Cost_Include__c && hcc.Cost_Review__c){
                        tempMap.put(hcc.RecordTypeName__c,hcc.Total_Cost_Override__c);
                        System.debug(hcc.Id+'    ');
                        caseIdRecordTypeSumMap.put(hcc.Case2__c,tempMap);
                    }else{
                        tempMap.put(hcc.RecordTypeName__c,0);
                        System.debug(hcc.Id+'    ');
                        caseIdRecordTypeSumMap.put(hcc.Case2__c,tempMap);
                    }
                }
                
            }else{
                if(caseIdRecordTypeCostMap.containsKey(hcc.Case2__c)){
                    Map<String,Decimal> tempMap = caseIdRecordTypeCostMap.get(hcc.Case2__c);
                    if(tempMap.containskey(hcc.RecordTypeName__c)){
                        System.debug(hcc.RecordTypeName__c);
                        totalCost = tempMap.get(hcc.RecordTypeName__c);
                        totalCost = Integer.valueof(totalCost + hcc.Cost__c);
                        tempMap.put(hcc.RecordTypeName__c,totalCost);
                    }else{
                        tempMap.put(hcc.RecordTypeName__c,hcc.Cost__c);
                    } 
                    caseIdRecordTypeCostMap.put(hcc.Case2__c,tempMap);
                }else{
                    Map<String,Decimal> tempMap = new Map<String,Decimal>();
                    tempMap.put(hcc.RecordTypeName__c,hcc.Cost__c);
                    caseIdRecordTypeCostMap.put(hcc.Case2__c,tempMap);
                }
            }  
        }
        System.debug(caseIdRecordTypeSumMap);
        Map<Id,Case> caseUpdateMap = new Map<Id,Case>();
        for(Id key : caseIdRecordTypeSumMap.keySet()){
            Case c = new Case();
            c.id = key;
            Map<String,Decimal> tempMap = caseIdRecordTypeSumMap.get(key);
            for(String recordType : tempMap.keySet()){
                if(recordType == 'Ambulance'){
                    c.Ambulance_Total2__c = tempMap.get(recordType);
                }else if(recordType == 'Pharmacare'){
                    c.Pharmacare_Total2__c = tempMap.get(recordType);
                }else if(recordType == 'Hospitalization'){
                    c.Hospitalization_Total2__c = tempMap.get(recordType);                   
                }
                else if(recordType == 'MSP'){
                    c.MSP_Total2__c = tempMap.get(recordType);
                }
            }    
            caseUpdateMap.put(c.id,c);
        }
        for(Id key : caseIdRecordTypeCostMap.keySet()){
            Case c = new Case();
            c.id = key;
            Map<String,Decimal> tempMap = caseIdRecordTypeCostMap.get(key);
            for(String recordType : tempMap.keySet()){
                if(recordType == 'Continuing_Care'){
                    c.Continuing_Care_Total2__c = tempMap.get(recordType);
                }
                if(recordType == 'Future_Care'){
                    c.Future_Care_Total2__c = tempMap.get(recordType);
                }
            }    
            Case c1 = caseUpdateMap.get(c.Id);
            c1.Continuing_Care_Total2__c = c.Continuing_Care_Total2__c;
            c1.Future_Care_Total2__c = c.Future_Care_Total2__c;
            caseUpdateMap.put(c1.id,c1);
        }
        try{
            update caseUpdateMap.values();
        }catch(Exception e){
            System.debug(e.getMessage());
        }
        
    } 
    public static void updateRollupDelete(List<Healthcare_Cost__c> hccList){
        System.debug(hccList);
        set<Id> caseIds = new set<Id>();
        for(Healthcare_Cost__c hcc : hccList){
            caseIds.add(hcc.Case2__c);
        }
        System.debug(caseIds);
        List<Case> caseList = [select id,Ambulance_Total2__c,Pharmacare_Total2__c,Hospitalization_Total2__c,MSP_Total2__c,Continuing_Care_Total2__c,Future_Care_Total2__c from case where id IN: caseIds];
        Map<Id,Case> caseMap = new Map<Id,Case>();
        for(Case c : caseList){
            caseMap.put(c.id,c);
        }
        for(Healthcare_Cost__c hcc : hccList){
            if(hcc.RecordTypeName__c != 'Continuing_Care' && hcc.RecordTypeName__c != 'Future_Care'){
                
                if(hcc.Cost_Include__c && hcc.Cost_Review__c){
                    Case c = caseMap.get(hcc.Case2__c);
                    if(hcc.RecordTypeName__c == 'Ambulance'){
                        c.Ambulance_Total2__c = c.Ambulance_Total2__c - hcc.Total_Cost_Override__c;
                    }
                    if(hcc.RecordTypeName__c == 'Pharmacare'){
                        c.Pharmacare_Total2__c = c.Pharmacare_Total2__c - hcc.Total_Cost_Override__c;
                    }
                    if(hcc.RecordTypeName__c == 'Hospitalization'){
                        c.Hospitalization_Total2__c = c.Hospitalization_Total2__c - hcc.Total_Cost_Override__c;
                    }
                    if(hcc.RecordTypeName__c == 'MSP'){
                        c.MSP_Total2__c = c.MSP_Total2__c - hcc.Total_Cost_Override__c;
                    }
                    caseMap.put(c.Id,c);
                    
                }
            }else{
                System.debug('149');
                Case c = caseMap.get(hcc.Case2__c);
                if(hcc.RecordTypeName__c == 'Continuing_Care'){
                    c.Continuing_Care_Total2__c = c.Continuing_Care_Total2__c - hcc.Cost__c;
                }
                if(hcc.RecordTypeName__c == 'Future_Care'){
                    c.Future_Care_Total2__c = c.Future_Care_Total2__c - hcc.Cost__c;
                }
                caseMap.put(c.Id,c);	
            }
        }
        try{
            System.debug(caseMap.values());
            update caseMap.values();
        }Catch(Exception e){
            System.debug(e.getCause());
        }
    }
}