/**
 * @purpose
 * This class provides Callable Apex methods for OmniStudio to retrieve and filter 
 * Healthcare Cost records related to a Case based on date range and Future Care criteria.
 */
global without sharing class TPL_CaseOmniService implements Callable{
    
    global Object call(String action, Map<String, Object> args) {
        
        Map<String, Object> input = (Map<String, Object>) args.get('input');
        Map<String, Object> output = (Map<String, Object>) args.get('output');
        Map<String, Object> options = (Map<String, Object>) args.get('options');
        
        return invokeMethod(action, input, output, options);
    }
    
    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        Boolean result = true;
        
        try{
            switch on methodName {
                when 'getHealthCareCostRecords'{
                    this.getHealthCareCostRecords(inputMap, outMap);
                }
                when 'getHealthCareCostRecordsInDateRange'{
                    this.getHealthCareCostRecordsInDateRange(inputMap, outMap);
                }
                when else {
                    result = false;
                    throw new ExtensionMalformedCallException('Method not implemented');
                }
            }
            
            return result;
        }catch(Exception e){
            throw new ExtensionMalformedCallException(e.getMessage());
        }
    }
   
    public void getHealthCareCostRecords(Map<String,Object> inputMap, Map<String,Object> outMap){
        List<Id> hcIdList  = new List<Id>();
        
        String caseId = String.valueOf(inputMap.get('caseId'));
        String birthDateStr = String.valueOf(inputMap.get('birthDate'));
        
        Date birthDate = birthDateStr.contains('T') 
            ? DateTime.valueOf(birthDateStr).date() 
            : Date.valueOf(birthDateStr);
        
        for(Healthcare_Cost__c hc : [
            Select Id,
                   Cost_Include__c,
                   Cost_Review__c,
                   RecordType.DeveloperName,
                   Case2__r.Include_Future_Care__c
            FROM Healthcare_Cost__c
            WHERE Case2__c = :caseId
            AND ((Date_of_Service__c >= :birthDate
            AND Date_of_Service__c <= TODAY) OR (Date_of_Admission__c >= :birthDate AND Date_of_Admission__c <= TODAY))
        ]){
            if(hc.RecordType.DeveloperName == 'Future_Care' || 
               hc.RecordType.DeveloperName == 'Continuing_Care'){
                
                if(hc.Cost_Include__c == hc.Case2__r.Include_Future_Care__c || 
                   hc.Cost_Review__c == hc.Case2__r.Include_Future_Care__c){
                    
                    hcIdList.add(hc.Id);
                }
            }else{
                hcIdList.add(hc.Id);
            }
        }
        
        outMap.put('hcCount', hcIdList.size());
    }
    
    public void getHealthCareCostRecordsInDateRange(Map<String,Object> inputMap, Map<String,Object> outMap){
        List<Id> hcIdList  = new List<Id>();
        
        String caseId = String.valueOf(inputMap.get('ContextId'));
        String startStr = String.valueOf(inputMap.get('startDate'));
        String endStr = String.valueOf(inputMap.get('endDate'));
        Boolean isFutureCare = Boolean.valueOf(inputMap.get('includeFuture'));
        
        Date startDate = startStr.contains('T') 
            ? DateTime.valueOf(startStr).date() 
            : Date.valueOf(startStr);
            
        Date endDate = endStr.contains('T') 
            ? DateTime.valueOf(endStr).date() 
            : Date.valueOf(endStr);
        
        for(Healthcare_Cost__c hc : [
            Select Id,
                   Cost_Include__c,
                   Cost_Review__c,
                   RecordType.DeveloperName,
                   Case2__r.Include_Future_Care__c
            FROM Healthcare_Cost__c
            WHERE Case2__c = :caseId
            AND ((Date_of_Service__c >= :startDate
            AND Date_of_Service__c <= :endDate) OR (Date_of_Admission__c >= :startDate AND Date_of_Admission__c <= TODAY))
        ]){
            if(hc.RecordType.DeveloperName == 'Future_Care' || 
               hc.RecordType.DeveloperName == 'Continuing_Care'){
                
                if(hc.Cost_Include__c == isFutureCare || 
                   hc.Cost_Review__c == isFutureCare){
                    
                    hcIdList.add(hc.Id);
                }
            }else{
                hcIdList.add(hc.Id);
            }
        }
        
        outMap.put('hcFilterCount', hcIdList.size());
    }

    public class ExtensionMalformedCallException extends Exception {}
}