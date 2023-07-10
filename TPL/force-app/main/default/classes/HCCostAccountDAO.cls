/*
* Company: CGI for BC Ministry of Health
* Date: April 12, 2023
* Author: Anudish Jinturkar
* Description: public with sharing class HCCostAccountDAO that implements on the database level queries for Healthcare Cost object at account level. 
This code contains the select operations based on various filters selected for the given Healthcare Cost. 
*    Methods:
*         getHCCostAccountRecords(String accId, String selectedFilterValue, Id recordTypeId, Integer startItemNumber, Integer pageSize, String fields, String sortOrder):
		  This method consist the query to retrieve healthcare cost records based on the parameters given for account Id, record type of Healthcare Cost, other items.
* History:
*     Initial version: April 12, 2023 - AJ
*     Update to codebase: June 12, 2023 - AJ
*     Update to codebase: July 06, 2023 - AJ
*/
public with sharing class HCCostAccountDAO {
     
    /*
* Description: List of Healthcare Cost method written to get the list of account records related to the given account ID, record type Id, and selected filter.
* Parameters:
*     String accId: It consist of the account ID associated with the Healthcare Cost Records
*     String selectedFilterValue: It depicts the filter selected on the UI to see the records
*     Id recordTypeId: It contains the ID of the selected Healthcare cost record type
*	  Integer startItemNumber: the start Number for the index to traverse from
*	  Integer pageSize:Page Size parameter gives the count of records displayed on the page
*	  String fields: Fields of the selected record type of Healthcare Cost used to query in SELECT part of query
*	  String sortOrder: sortOrder string states if the order is ascending or descending 
* Returns:
*     List<Healthcare_Cost__c>: Returns list of Healthcare Cost records as expected from the query
* 
*/
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
                        dateId = [SELECT dateId__c 
                                  FROM Healthcare_Cost__c 
                                  WHERE Account__c = :accId AND RecordTypeId = :recordTypeId 
                                  ORDER BY dateId__c DESC LIMIT 1 OFFSET 2000][0].dateId__c;
                        
                        itemsToRemove -= 2001;
                        while( itemsToRemove > 2000 )
                        {
                            dateId = [SELECT dateId__c 
                                      FROM Healthcare_Cost__c 
                                      WHERE Account__c = :accId AND RecordTypeId = :recordTypeId AND dateId__c < :dateId 
                                      ORDER BY dateId__c DESC LIMIT 1 OFFSET 2000][0].dateId__c;
                            itemsToRemove -= 2001;
                        }
                    }
                    if(itemsToRemove > 0){
                        dateId = [SELECT dateId__c 
                                  FROM Healthcare_Cost__c 
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
                        dateId = [SELECT dateId__c 
                                  FROM Healthcare_Cost__c 
                                  WHERE Account__c = :accId AND RecordTypeId = :recordTypeId 
                                  AND Cost_Include__c = false AND Cost_Review__c = false 
                                  ORDER BY dateId__c DESC LIMIT 1 OFFSET 2000][0].dateId__c;
                        
                        itemsToRemove -= 2001;
                        
                        while( itemsToRemove > 2000 )
                        {
                            dateId = [SELECT dateId__c 
                                      FROM Healthcare_Cost__c 
                                      WHERE Account__c = :accId AND RecordTypeId = :recordTypeId 
                                      AND Cost_Include__c = false AND Cost_Review__c = false AND dateId__c < :dateId 
                                      ORDER BY dateId__c DESC LIMIT 1 OFFSET 2000][0].dateId__c;
                            itemsToRemove -= 2001;
                        }
                    }
                    if(itemsToRemove > 0){
                        dateId = [SELECT dateId__c 
                                  FROM Healthcare_Cost__c 
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
                        dateId = [SELECT dateId__c 
                                  FROM Healthcare_Cost__c 
                                  WHERE Account__c = :accId AND RecordTypeId = :recordTypeId 
                                  ORDER BY dateId__c ASC LIMIT 1 OFFSET 2000][0].dateId__c;
                        
                        itemsToRemove -= 2001;
                        
                        while( itemsToRemove > 2000 )
                        {
                            dateId = [SELECT dateId__c 
                                      FROM Healthcare_Cost__c 
                                      WHERE Account__c = :accId AND RecordTypeId = :recordTypeId AND dateId__c > :dateId 
                                      ORDER BY dateId__c ASC LIMIT 1 OFFSET 2000][0].dateId__c;
                            
                            itemsToRemove -= 2001;
                        }
                    }
                    if(itemsToRemove > 0){
                        dateId = [SELECT dateId__c 
                                  FROM Healthcare_Cost__c 
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
                        dateId = [SELECT dateId__c 
                                  FROM Healthcare_Cost__c 
                                  WHERE Account__c = :accId AND RecordTypeId = :recordTypeId 
                                  AND Cost_Include__c = false AND Cost_Review__c = false 
                                  ORDER BY dateId__c ASC LIMIT 1 OFFSET 2000][0].dateId__c;
                        
                        itemsToRemove -= 2001;
                        while( itemsToRemove > 2000 )
                        {
                            dateId = [SELECT dateId__c 
                                      FROM Healthcare_Cost__c 
                                      WHERE Account__c = :accId AND RecordTypeId = :recordTypeId 
                                      AND Cost_Include__c = false AND Cost_Review__c = false AND dateId__c > :dateId 
                                      ORDER BY dateId__c ASC LIMIT 1 OFFSET 2000][0].dateId__c;
                            
                            itemsToRemove -= 2001;
                        }
                    }
                    if(itemsToRemove > 0){
                        dateId = [SELECT dateId__c 
                                  FROM Healthcare_Cost__c 
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