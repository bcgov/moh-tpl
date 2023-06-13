public with sharing class HCCostCaseDAO {
public static List<Healthcare_Cost__c> getHCCostCaseRecords(String caseId, String filterValue, Id recordTypeId, Integer startItemNumber, Integer pageSize, String fields, String sortOrder){
Integer itemsToRemove = startItemNumber - 2;
System.debug(itemsToRemove);
list<Healthcare_Cost__c> hccList = new list<Healthcare_Cost__c>();
String dateId = '';
String query = '';
String sourceSystemId = null;
Boolean costValue = false;
try{
    if(sortOrder == null || sortOrder == ''){
        sortOrder = 'asc';
    }
    System.debug('sortOrder : ' + sortOrder);
    if(sortOrder == Label.TPL_Descending){
    // Populate DateID to maximum value
        dateId = '99999999zz';
        if(filterValue == Label.TPL_Manual_Records){
            
            if(itemsToRemove > 2000)
            {
                dateId = [SELECT dateId__c FROM Healthcare_Cost__c 
                WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId AND Source_System_ID__c = :sourceSystemId 
                ORDER BY dateId__c DESC LIMIT 1 OFFSET 2000][0].dateId__c;
                itemsToRemove -= 2001;
                while( itemsToRemove > 2000 )
                {
                    dateId = [SELECT dateId__c FROM Healthcare_Cost__c WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId  AND Source_System_ID__c = :sourceSystemId AND dateId__c < :dateId ORDER BY dateId__c DESC LIMIT 1 OFFSET 2000][0].dateId__c;
                    itemsToRemove -= 2001;
                }
                System.debug('Items to remove : ' + itemsToRemove);
            }
            
            if(itemsToRemove > 0){
                
                dateId = [SELECT dateId__c FROM Healthcare_Cost__c 
                WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId  AND Source_System_ID__c = :sourceSystemId AND dateId__c < :dateId 
                ORDER BY dateId__c DESC LIMIT 1 OFFSET :itemsToRemove][0].dateId__c;
                itemsToRemove = 0;
            }

            query = 'SELECT ' + fields + ' FROM Healthcare_Cost__c WHERE Case2__c = \'' + caseId + '\' AND RecordTypeId = \'' 
            + recordTypeId +'\' AND Source_System_ID__c = ' + sourceSystemId + ' AND dateId__c < \'' + dateId 
            + '\' ORDER BY dateId__c DESC LIMIT ' + pageSize;
            System.debug('Query : ' + query);
            hccList = Database.query(query);
            System.debug('List Size ' + hccList.size());
        }

    else if(filterValue == Label.TPL_Records_Created_Today) {
        if(itemsToRemove > 2000)
        {
        dateId = [SELECT dateId__c FROM Healthcare_Cost__c WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId AND Source_System_ID__c = :sourceSystemId AND CreatedDate = TODAY ORDER BY dateId__c DESC LIMIT 1 OFFSET 2000][0].dateId__c;
            itemsToRemove -= 2001;
            while( itemsToRemove > 2000 )
            {
                dateId = [SELECT dateId__c FROM Healthcare_Cost__c WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId AND Source_System_ID__c = :sourceSystemId AND CreatedDate = TODAY  AND dateId__c < :dateId ORDER BY dateId__c DESC LIMIT 1 OFFSET 2000][0].dateId__c;
                itemsToRemove -= 2001;
            }
        }

        if(itemsToRemove > 0){
            dateId = [SELECT dateId__c FROM Healthcare_Cost__c WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId AND Source_System_ID__c = :sourceSystemId AND CreatedDate = TODAY  AND dateId__c < :dateId ORDER BY dateId__c DESC LIMIT 1 OFFSET :itemsToRemove][0].dateId__c;
            itemsToRemove = 0;
        }
        
        query = 'SELECT ' + fields + ' FROM Healthcare_Cost__c WHERE Case2__c = \''+ caseId + '\' AND RecordTypeId = \'' 
        + recordTypeId +'\' AND Source_System_ID__c = ' + sourceSystemId +' AND CreatedDate = TODAY AND dateId__c < \''+ dateId 
        +'\' ORDER BY dateId__c DESC LIMIT '+ pageSize;
        System.debug('Query : ' + query);
        hccList = Database.query(query);

    }

        else {
            if(itemsToRemove > 2000)
            {
                dateId = [SELECT dateId__c FROM Healthcare_Cost__c WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId ORDER BY dateId__c DESC LIMIT 1 OFFSET 2000][0].dateId__c;
                itemsToRemove -= 2001;
                while( itemsToRemove > 2000 )
                {
                    dateId = [SELECT dateId__c FROM Healthcare_Cost__c WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId AND dateId__c < :dateId ORDER BY dateId__c DESC LIMIT 1 OFFSET 2000][0].dateId__c;
                    itemsToRemove -= 2001;
                }
            }
            if(itemsToRemove > 0){
                dateId = [SELECT dateId__c FROM Healthcare_Cost__c WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId AND dateId__c < :dateId ORDER BY dateId__c DESC LIMIT 1 OFFSET :itemsToRemove][0].dateId__c;
                itemsToRemove = 0;
            }
    
            query = 'SELECT ' + fields + ' FROM Healthcare_Cost__c WHERE Case2__c = \'' + caseId + '\' AND RecordTypeId = \'' 
            + recordTypeId + '\' AND dateId__c < \'' + dateId +'\' ORDER BY dateId__c DESC LIMIT ' + pageSize;
            System.debug('Query : ' + query);
            hccList = Database.query(query);
        }
        System.debug('Start Item Number : ' + startItemNumber + ', Items to remove : ' + itemsToRemove +', Page Size : ' + pageSize +', List Size : ' + hccList.size());
    }
    
    else
    {
        if(filterValue == Label.TPL_Manual_Records){
            if(itemsToRemove > 2000)
            {
                dateId = [SELECT dateId__c FROM Healthcare_Cost__c WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId AND Source_System_ID__c = :sourceSystemId ORDER BY dateId__c ASC LIMIT 1 OFFSET 2000][0].dateId__c;
                itemsToRemove -= 2001;
                while( itemsToRemove > 2000 )
                {
                    dateId = [SELECT dateId__c FROM Healthcare_Cost__c WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId  AND Source_System_ID__c = :sourceSystemId AND dateId__c > :dateId ORDER BY dateId__c ASC LIMIT 1 OFFSET 2000][0].dateId__c;
                    itemsToRemove -= 2001;
                }
            }
            if(itemsToRemove > 0){
                dateId = [SELECT dateId__c FROM Healthcare_Cost__c WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId  AND Source_System_ID__c = :sourceSystemId AND dateId__c > :dateId ORDER BY dateId__c ASC LIMIT 1 OFFSET :itemsToRemove][0].dateId__c;
                itemsToRemove = 0;
            }
        
            query = 'SELECT ' + fields + ' FROM Healthcare_Cost__c WHERE Case2__c = \''+caseId + '\' AND RecordTypeId = \''
            + recordTypeId + '\' AND Source_System_ID__c = '+ sourceSystemId +' AND dateId__c > \'' + dateId + '\' ORDER BY dateId__c ASC LIMIT '+ pageSize;
            System.debug('Query : ' + query);
            hccList = Database.query(query);
            
        }
    
        else if(filterValue == Label.TPL_Records_Created_Today) {
            if(itemsToRemove > 2000)
            {
                dateId = [SELECT dateId__c FROM Healthcare_Cost__c WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId AND Source_System_ID__c = :sourceSystemId AND CreatedDate = TODAY  ORDER BY dateId__c ASC LIMIT 1 OFFSET 2000][0].dateId__c;
                itemsToRemove -= 2001;
                while( itemsToRemove > 2000 )
                {
                    dateId = [SELECT dateId__c FROM Healthcare_Cost__c WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId AND Source_System_ID__c = :sourceSystemId AND CreatedDate = TODAY  AND dateId__c > :dateId ORDER BY dateId__c ASC LIMIT 1 OFFSET 2000][0].dateId__c;
                    itemsToRemove -= 2001;
                }
            }
        
            if(itemsToRemove > 0){
                dateId = [SELECT dateId__c FROM Healthcare_Cost__c WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId AND Source_System_ID__c = :sourceSystemId AND CreatedDate = TODAY  AND dateId__c > :dateId ORDER BY dateId__c ASC LIMIT 1 OFFSET :itemsToRemove][0].dateId__c;
                itemsToRemove = 0;
            }
            
            query = 'SELECT ' + fields + ' FROM Healthcare_Cost__c WHERE Case2__c = \'' + caseId +'\' AND RecordTypeId = \'' 
            + recordTypeId +'\' AND Source_System_ID__c = ' + sourceSystemId + ' AND CreatedDate = TODAY AND dateId__c > \'' + dateId 
            +'\' ORDER BY dateId__c ASC LIMIT ' + pageSize;
            System.debug('Query : ' + query);
            hccList = Database.query(query);
    
        }
    
        else {
            if(itemsToRemove > 2000)
            {
                dateId = [SELECT dateId__c FROM Healthcare_Cost__c WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId ORDER BY dateId__c ASC LIMIT 1 OFFSET 2000][0].dateId__c;
                itemsToRemove -= 2001;
                while( itemsToRemove > 2000 )
                {
                    dateId = [SELECT dateId__c FROM Healthcare_Cost__c WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId AND dateId__c > :dateId ORDER BY dateId__c ASC LIMIT 1 OFFSET 2000][0].dateId__c;
                    itemsToRemove -= 2001;
                }
            }
            if(itemsToRemove > 0){
                dateId = [SELECT dateId__c FROM Healthcare_Cost__c WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId AND dateId__c > :dateId ORDER BY dateId__c ASC LIMIT 1 OFFSET :itemsToRemove][0].dateId__c;
                itemsToRemove = 0;
            }
        
            query = 'SELECT ' + fields + ' FROM Healthcare_Cost__c WHERE Case2__c = \'' + caseId + '\' AND RecordTypeId = \''
            + recordTypeId + '\' AND dateId__c > \'' + dateId + '\' ORDER BY dateId__c ASC LIMIT ' + pageSize;
            System.debug('Query : ' + query);
            hccList = Database.query(query);
        }
        System.debug('Start Item Number : ' + startItemNumber + ', Items to remove : ' + itemsToRemove +', Page Size : ' + pageSize +', List Size : ' + hccList.size());
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