public with sharing class HCCostAccountDAO {
public static List<Healthcare_Cost__c> getHCCostAccountRecords(String accId, String selectedFilterValue, Id recordTypeId, Integer startItemNumber, Integer pageSize, String fields, String sortOrder){
        
    Integer itemsToRemove = startItemNumber - 2;
    list<Healthcare_Cost__c> hccList = new list<Healthcare_Cost__c>();
    String dateId = '';
    String query = '';
    Boolean costValue = false;
    try{
        if(sortOrder == null || sortOrder == ''){
            sortOrder = 'asc';
        }
       
        if(sortOrder == Label.TPL_Descending){
        // Populate DateID to maximum value
            dateId = '99999999zz';
            if(selectedFilterValue == Label.TPL_All_Records){
                if(itemsToRemove > 2000)
                {
                    dateId = [SELECT dateId__c FROM Healthcare_Cost__c 
                    WHERE Account__c = :accId AND RecordTypeId = :recordTypeId 
                    ORDER BY dateId__c DESC LIMIT 1 OFFSET 2000][0].dateId__c;
                    
                    itemsToRemove -= 2001;
                    while( itemsToRemove > 2000 )
                    {
                        dateId = [SELECT dateId__c FROM Healthcare_Cost__c 
                        WHERE Account__c = :accId AND RecordTypeId = :recordTypeId AND dateId__c < :dateId 
                        ORDER BY dateId__c DESC LIMIT 1 OFFSET 2000][0].dateId__c;
                        itemsToRemove -= 2001;
                    }
                }
                if(itemsToRemove > 0){
                    dateId = [SELECT dateId__c FROM Healthcare_Cost__c 
                    WHERE Account__c = :accId AND RecordTypeId = :recordTypeId AND dateId__c < :dateId 
                    ORDER BY dateId__c DESC LIMIT 1 OFFSET :itemsToRemove][0].dateId__c;
                    itemsToRemove = 0;
                }
                query = 'SELECT ' + fields + ' FROM Healthcare_Cost__c WHERE Account__c = \'' + accId 
                + '\' AND RecordTypeId = \'' + recordTypeId + '\' AND dateId__c < \'' + dateId 
                + '\' ORDER BY dateId__c DESC LIMIT ' + pageSize;

                hccList = Database.query(query);
               
            }
            else {
                if(itemsToRemove > 2000)
                {
                    dateId = [SELECT dateId__c FROM Healthcare_Cost__c 
                    WHERE Account__c = :accId AND RecordTypeId = :recordTypeId 
                    AND Cost_Include__c = false AND Cost_Review__c = false 
                    ORDER BY dateId__c DESC LIMIT 1 OFFSET 2000][0].dateId__c;
                    
                    itemsToRemove -= 2001;
                    
                    while( itemsToRemove > 2000 )
                    {
                        dateId = [SELECT dateId__c FROM Healthcare_Cost__c 
                        WHERE Account__c = :accId AND RecordTypeId = :recordTypeId 
                        AND Cost_Include__c = false AND Cost_Review__c = false AND dateId__c < :dateId 
                        ORDER BY dateId__c DESC LIMIT 1 OFFSET 2000][0].dateId__c;
                        itemsToRemove -= 2001;
                    }
                }
                if(itemsToRemove > 0){
                    dateId = [SELECT dateId__c FROM Healthcare_Cost__c 
                    WHERE Account__c = :accId AND RecordTypeId = :recordTypeId 
                    AND Cost_Include__c = false AND Cost_Review__c = false AND dateId__c < :dateId 
                    ORDER BY dateId__c DESC LIMIT 1 OFFSET :itemsToRemove][0].dateId__c;
                    
                    itemsToRemove = 0;
                }
                query = 'SELECT ' + fields + ' FROM Healthcare_Cost__c WHERE Account__c = \'' + accId + '\' AND RecordTypeId = \'' 
                + recordTypeId + '\' AND Cost_Include__c = ' + costValue + ' AND Cost_Review__c = ' + costValue 
                + ' AND dateId__c < \'' + dateId + '\' ORDER BY dateId__c DESC LIMIT ' + pageSize;

                hccList = Database.query(query);
            }
        }
        else{
            if(selectedFilterValue == Label.TPL_All_Records){
                if(itemsToRemove > 2000)
                {
                    dateId = [SELECT dateId__c FROM Healthcare_Cost__c 
                    WHERE Account__c = :accId AND RecordTypeId = :recordTypeId 
                    ORDER BY dateId__c ASC LIMIT 1 OFFSET 2000][0].dateId__c;

                    itemsToRemove -= 2001;
                    
                    while( itemsToRemove > 2000 )
                    {
                        dateId = [SELECT dateId__c FROM Healthcare_Cost__c 
                        WHERE Account__c = :accId AND RecordTypeId = :recordTypeId AND dateId__c > :dateId 
                        ORDER BY dateId__c ASC LIMIT 1 OFFSET 2000][0].dateId__c;

                        itemsToRemove -= 2001;
                    }
                }
                if(itemsToRemove > 0){
                    dateId = [SELECT dateId__c FROM Healthcare_Cost__c 
                    WHERE Account__c = :accId AND RecordTypeId = :recordTypeId AND dateId__c > :dateId 
                    ORDER BY dateId__c ASC LIMIT 1 OFFSET :itemsToRemove][0].dateId__c;
                    
                    itemsToRemove = 0;
                }
                query = 'SELECT ' + fields + ' FROM Healthcare_Cost__c WHERE Account__c = \'' + accId 
                + '\' AND RecordTypeId = \'' + recordTypeId + '\' AND dateId__c > \'' + dateId 
                + '\' ORDER BY dateId__c ASC LIMIT ' + pageSize;

                hccList = Database.query(query);
            }
            else {
                if(itemsToRemove > 2000)
                {
                    dateId = [SELECT dateId__c FROM Healthcare_Cost__c 
                    WHERE Account__c = :accId AND RecordTypeId = :recordTypeId 
                    AND Cost_Include__c = false AND Cost_Review__c = false 
                    ORDER BY dateId__c ASC LIMIT 1 OFFSET 2000][0].dateId__c;

                    itemsToRemove -= 2001;
                    while( itemsToRemove > 2000 )
                    {
                        dateId = [SELECT dateId__c FROM Healthcare_Cost__c 
                        WHERE Account__c = :accId AND RecordTypeId = :recordTypeId 
                        AND Cost_Include__c = false AND Cost_Review__c = false AND dateId__c > :dateId 
                        ORDER BY dateId__c ASC LIMIT 1 OFFSET 2000][0].dateId__c;

                        itemsToRemove -= 2001;
                    }
                }
                if(itemsToRemove > 0){
                    dateId = [SELECT dateId__c FROM Healthcare_Cost__c 
                    WHERE Account__c = :accId AND RecordTypeId = :recordTypeId 
                    AND Cost_Include__c = false AND Cost_Review__c = false AND dateId__c > :dateId 
                    ORDER BY dateId__c ASC LIMIT 1 OFFSET :itemsToRemove][0].dateId__c;

                    itemsToRemove = 0;
                }

                query = 'SELECT ' + fields + ' FROM Healthcare_Cost__c WHERE Account__c = \'' + accId 
                + '\' AND RecordTypeId = \'' + recordTypeId + '\' AND Cost_Include__c = ' + costValue 
                + ' AND Cost_Review__c = ' + costValue + ' AND dateId__c > \'' + dateId 
                + '\' ORDER BY dateId__c ASC LIMIT ' + pageSize;

                hccList = Database.query(query);
            }

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