/**
 * @description  TPL_CaseOmniService provides Callable Apex methods for OmniStudio
 *               to retrieve and filter Healthcare Cost records related to a Case
 *               based on date range and Future Care criteria.
 *
 * @author       Sunny
 * @developer    Sunny
 * @created      2026-05-05
 */
global without sharing class TPL_CaseOmniService implements Callable{
    
    public Object call(String action, Map<String, Object> args) {
        if(args == null || args.isEmpty()){
            return null;
        }       
        Map<String, Object> input = (Map<String, Object>) args.get('input');
        Map<String, Object> output = (Map<String, Object>) args.get('output');
        Map<String, Object> options = (Map<String, Object>) args.get('options');
        
        return invokeMethod(action, input, output, options);
    }
    
    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
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
    /*
      @Purpose: To check the count of Healthcare cost records based on account's birthday,
                  date of service and date of admission.
      @Parameters : This is called from remote action within an omniscript.
                    inputMap holds the params passed from omniscript,
                    outMap holds the values to be passed to omniscript.  
    */
   
    public void getHealthCareCostRecords(Map<String,Object> inputMap, Map<String,Object> outMap){

        if(!inputMap.containsKey('caseId') || !inputMap.containsKey('birthDate')) {
            return;
            }
        List<Id> hcIdList  = new List<Id>();
        String  caseId  = String.valueOf(inputMap.get('caseId'));
        String birthDateStr = String.valueOf(inputMap.get('birthDate'));
        if(String.isBlank(birthDateStr)){
            return;
       }
        
        Date birthDate = birthDateStr.contains('T') 
            ? DateTime.valueOf(birthDateStr).date() 
            : Date.valueOf(birthDateStr);
       
        for(Healthcare_Cost__c hc : [
            Select Id,
                   Cost_Include__c,
                   Cost_Review__c,
                   RecordType.DeveloperName,
                   Case2__r.Include_Future_Care__c,
                   Date_of_Service__c,
                   Date_of_Admission__c 
            FROM Healthcare_Cost__c
            WHERE Case2__c = :caseId

        ]){
            if(hc.RecordType.DeveloperName == 'Future_Care' || hc.RecordType.DeveloperName == 'Continuing_Care'){
                hcIdList.add(hc.Id);
            }else if((hc.Date_of_Service__c >= birthDate && hc.Date_of_Service__c <= date.TODAY()) || (hc.Date_of_Admission__c >= birthDate && hc.Date_of_Admission__c <= date.TODAY())){
                hcIdList.add(hc.Id);
            }
        }
        
        outMap.put('hcCount', hcIdList.size());
    }
    
    /*
      @Purpose: To check the count of Healthcare cost records based on the 
                 date input fields from omniscript
      @Parameters : This is called from remote action within an omniscript.
                    inputMap holds the params passed from omniscript,
                    outMap holds the values to be passed to omniscript.  
    */ 
    public void getHealthCareCostRecordsInDateRange(Map<String,Object> inputMap, Map<String,Object> outMap){
       if (inputMap == null || inputMap.isEmpty() ||(!inputMap.containsKey('ContextId') && !inputMap.containsKey('startDate') && !inputMap.containsKey('endStr') && !inputMap.containsKey('includeFuture'))){
        return;
        }
        List<Id> hcIdList  = new List<Id>();
        
        String caseId = String.valueOf(inputMap.get('ContextId'));
        String startStr = String.valueOf(inputMap.get('startDate'));
        String endStr = String.valueOf(inputMap.get('endDate'));
        Boolean isFutureCare = Boolean.valueOf(inputMap.get('includeFuture'));
        if(String.isBlank(startStr) || String.isBlank(endStr)){
            return;
        }
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
                   Case2__r.Include_Future_Care__c,
                   Date_of_Admission__c ,
                   Date_of_Service__c 
            FROM Healthcare_Cost__c
            WHERE Case2__c = :caseId]){

            if(hc.RecordType.DeveloperName == 'Future_Care' || 
               hc.RecordType.DeveloperName == 'Continuing_Care'){
                   if(isFutureCare){
                       hcIdList.add(hc.Id);
                   }
               }else if(hc.Cost_Include__c == true && hc.Cost_Review__c == true && ((hc.Date_of_Service__c >= startDate && hc.Date_of_Service__c <= endDate) 
                           || (hc.Date_of_Admission__c >= startDate && hc.Date_of_Admission__c <= endDate))){
                   hcIdList.add(hc.Id);
               }
        }
        
        outMap.put('hcFilterCount', hcIdList.size());
    }

    public class ExtensionMalformedCallException extends Exception {}
}