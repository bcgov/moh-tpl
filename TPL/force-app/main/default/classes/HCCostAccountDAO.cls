public with sharing class HCCostAccountDAO {
    public static List<Healthcare_Cost__c> getHCCostAccountRecords(String accId, String selectedFilterValue, Id recordTypeId, Integer startItemNumber, Integer pageSize, String fields){
           
        Integer itemsToRemove = startItemNumber - 2;
        list<Healthcare_Cost__c> hccList = new list<Healthcare_Cost__c>();
        String dateId = '';
        String query = '';
        Boolean costValue = false;
        try{
           
            if(selectedFilterValue == Label.TPL_All_Records){
                if(itemsToRemove > 2000)
                {
                    dateId = [select dateId__c from Healthcare_Cost__c where Account__c = :accId and RecordTypeId = :recordTypeId ORDER BY dateId__c LIMIT 1 OFFSET 2000][0].dateId__c;
                    itemsToRemove -= 2001;
                    while( itemsToRemove > 2000 )
                    {
                        dateId = [select dateId__c from Healthcare_Cost__c where Account__c = :accId and RecordTypeId = :recordTypeId and dateId__c > :dateId order by dateId__c LIMIT 1 OFFSET 2000][0].dateId__c;
                        itemsToRemove -= 2001;
                    }
                }
                if(itemsToRemove > 0){
                    dateId = [select dateId__c from Healthcare_Cost__c where Account__c = :accId and RecordTypeId = :recordTypeId and dateId__c > :dateId ORDER BY dateId__c LIMIT 1 OFFSET :itemsToRemove][0].dateId__c;
                    itemsToRemove = 0;
                }
                query = 'SELECT ' + fields + ' FROM Healthcare_Cost__c WHERE Account__c = :accId and RecordTypeId = :recordTypeId and dateId__c > :dateId order by dateId__c LIMIT :pageSize';
                hccList = Database.query(query);
              //  hccList = [select Id, Name, Case2__c, Case2__r.CaseNumber, Case_Number__c, Cost_Include__c, Cost_Review__c, Date_of_Service__c, Location_Responded__c, Basic_Amount__c, Cost__c, Total_Cost_Override__c, Site_Code__c, Facility__c, FacilityName__c, Fixed_Wing_Helicopter__c, Source_System_ID__c, Service_Date_Index__c from Healthcare_Cost__c where Account__c = :accId and RecordTypeId = :recordTypeId and Id > :locationID order by Id LIMIT :pageSize];
            }
            else {
                if(itemsToRemove > 2000)
                {
                    dateId = [select dateId__c from Healthcare_Cost__c where Account__c = :accId and RecordTypeId = :recordTypeId and Cost_Include__c = false and Cost_Review__c = false ORDER BY dateId__c LIMIT 1 OFFSET 2000][0].dateId__c;
                    itemsToRemove -= 2001;
                    while( itemsToRemove > 2000 )
                    {
                        dateId = [select dateId__c from Healthcare_Cost__c where Account__c = :accId and RecordTypeId = :recordTypeId and Cost_Include__c = false and Cost_Review__c = false and dateId__c > :dateId order by dateId__c LIMIT 1 OFFSET 2000][0].dateId__c;
                        itemsToRemove -= 2001;
                    }
                }
                if(itemsToRemove > 0){
                    dateId = [select dateId__c from Healthcare_Cost__c where Account__c = :accId and RecordTypeId = :recordTypeId and Cost_Include__c = false and Cost_Review__c = false and dateId__c > :dateId ORDER BY dateId__c LIMIT 1 OFFSET :itemsToRemove][0].dateId__c;
                    itemsToRemove = 0;
                }
                query = 'SELECT ' + fields + ' FROM Healthcare_Cost__c WHERE Account__c = :accId and RecordTypeId = :recordTypeId and Cost_Include__c = :costValue and Cost_Review__c = :costValue and dateId__c > :dateId order by dateId__c LIMIT :pageSize';
                hccList = Database.query(query);
                //    hccList = [select Id, Name, Case2__c, Case2__r.CaseNumber, Case_Number__c, Cost_Include__c, Cost_Review__c, Date_of_Service__c, Location_Responded__c, Basic_Amount__c, Cost__c, Total_Cost_Override__c, Site_Code__c, Facility__c, FacilityName__c, Fixed_Wing_Helicopter__c, Source_System_ID__c, Service_Date_Index__c from Healthcare_Cost__c where Account__c = :accId and RecordTypeId = :recordTypeId and Cost_Include__c = false and Cost_Review__c = false and Id > :locationID order by Id LIMIT :pageSize];
            }
    
        }
        catch(LimitException l){
            System.debug(l.getMessage());
        }
        catch(ListException listexception){
            System.debug(listexception.getMessage());
        }
        catch(DmlException dml){
            System.debug(dml.getMessage());
        }
        system.debug(hccList+'last');
        return hccList;
    }
}