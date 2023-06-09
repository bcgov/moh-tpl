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