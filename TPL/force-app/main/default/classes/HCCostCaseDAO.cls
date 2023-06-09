public with sharing class HCCostCaseDAO {
    public static List<Healthcare_Cost__c> getHCCostCaseRecords(String caseId, String filterValue, Id recordTypeId, Integer startItemNumber, Integer pageSize, String fields){
        Integer itemsToRemove = startItemNumber - 2;
        System.debug(itemsToRemove);
        list<Healthcare_Cost__c> hccList = new list<Healthcare_Cost__c>();
        String dateId = '';
        String query = '';
        String sourceSystemId = null;
        Boolean costValue = false;
        try{
           
            if(filterValue == Label.TPL_Manual_Records){
                if(itemsToRemove > 2000)
                {
                    dateId = [select dateId__c from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId and Source_System_ID__c = :sourceSystemId ORDER BY dateId__c LIMIT 1 OFFSET 2000][0].dateId__c;
                    itemsToRemove -= 2001;
                    while( itemsToRemove > 2000 )
                    {
                        dateId = [select dateId__c from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId  and Source_System_ID__c = :sourceSystemId and dateId__c > :dateId order by dateId__c LIMIT 1 OFFSET 2000][0].dateId__c;
                        itemsToRemove -= 2001;
                    }
                }
                if(itemsToRemove > 0){
                    dateId = [select dateId__c from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId  and Source_System_ID__c = :sourceSystemId and dateId__c > :dateId ORDER BY dateId__c LIMIT 1 OFFSET :itemsToRemove][0].dateId__c;
                    itemsToRemove = 0;
                }
               
                query = 'SELECT ' + fields + ' FROM Healthcare_Cost__c WHERE Case2__c = :caseId and RecordTypeId = :recordTypeId and Source_System_ID__c = :sourceSystemId and dateId__c > :dateId order by dateId__c LIMIT :pageSize';
                hccList = Database.query(query);
         
            }
            else if(filterValue == Label.TPL_Records_Created_Today) {
                if(itemsToRemove > 2000)
                {
                    dateId = [select dateId__c from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId and Source_System_ID__c = :sourceSystemId and CreatedDate = TODAY  ORDER BY dateId__c LIMIT 1 OFFSET 2000][0].dateId__c;
                    itemsToRemove -= 2001;
                    while( itemsToRemove > 2000 )
                    {
                        dateId = [select dateId__c from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId and Source_System_ID__c = :sourceSystemId and CreatedDate = TODAY  and dateId__c > :dateId order by dateId__c LIMIT 1 OFFSET 2000][0].dateId__c;
                        itemsToRemove -= 2001;
                    }
                }
                if(itemsToRemove > 0){
                    dateId = [select dateId__c from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId and Source_System_ID__c = :sourceSystemId and CreatedDate = TODAY  and dateId__c > :dateId ORDER BY dateId__c LIMIT 1 OFFSET :itemsToRemove][0].dateId__c;
                    itemsToRemove = 0;
                }
                query = 'SELECT ' + fields + ' FROM Healthcare_Cost__c WHERE Case2__c = :caseId and RecordTypeId = :recordTypeId and Source_System_ID__c = :sourceSystemId and CreatedDate = TODAY and dateId__c > :dateId order by dateId__c LIMIT :pageSize';
                hccList = Database.query(query);
         
            }
            else {
                if(itemsToRemove > 2000)
                {
                    dateId = [select dateId__c from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId ORDER BY dateId__c LIMIT 1 OFFSET 2000][0].dateId__c;
                    itemsToRemove -= 2001;
                    while( itemsToRemove > 2000 )
                    {
                        dateId = [select dateId__c from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId and dateId__c > :dateId order by dateId__c LIMIT 1 OFFSET 2000][0].dateId__c;
                        itemsToRemove -= 2001;
                    }
                }
                if(itemsToRemove > 0){
                    dateId = [select dateId__c from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId and dateId__c > :dateId ORDER BY dateId__c LIMIT 1 OFFSET :itemsToRemove][0].dateId__c;
                    itemsToRemove = 0;
                }
                query = 'SELECT ' + fields + ' FROM Healthcare_Cost__c WHERE Case2__c = :caseId and RecordTypeId = :recordTypeId and dateId__c > :dateId order by dateId__c LIMIT :pageSize';
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
       
        return hccList;
   }
}