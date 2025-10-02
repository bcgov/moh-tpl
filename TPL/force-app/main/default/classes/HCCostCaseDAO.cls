/*
* Company: CGI for BC Ministry of Health
* Date: April 12, 2023
* Author: Anudish Jinturkar
* Description: public with sharing class HCCostCaseDAO that implements on the database level queries for Healthcare Cost object at case level. 
This code contains the select operations based on various filters selected for the given Healthcare Cost. 
*    Methods:
*         getHCCostCaseRecords(String caseId, String filterValue, Id recordTypeId, Integer startItemNumber, Integer pageSize, String fields, String sortOrder):
		  This method consist the query to retrieve healthcare cost records based on the parameters given for case Id, record type of Healthcare Cost, other items.
* History:
*     Initial version: April 12, 2023 - AJ
*     Update to codebase: June 12, 2023 - AJ
*     Update to codebase: July 06, 2023 - AJ
*/
public with sharing class HCCostCaseDAO {
        /*
* Description: List of Healthcare Cost method written to get the list of case records related to the given case ID, record type Id, and selected filter.
* Parameters:
*     String caseId: It consist of the caseID associated with the Healthcare Cost Records
*     String filterValue: It depicts the filter selected on the UI to see the records
*     Id recordTypeId: It contains the ID of the selected Healthcare cost record type
*	  Integer startItemNumber: the start Number for the index to traverse from
*	  Integer pageSize:Page Size parameter gives the count of records displayed on the page
*	  String fields: Fields of the selected record type of Healthcare Cost used to query in SELECT part of query
*	  String sortOrder: sortOrder string states if the order is ascending or descending 
* Returns:
*     List<Healthcare_Cost__c>: Returns list of Healthcare Cost records as expected from the query
* 
*/
    public static List<Healthcare_Cost__c> getHCCostCaseRecords(String caseId, String filterValue, Id recordTypeId, Integer startItemNumber, Integer pageSize, String fields, String sortOrder){
        Integer itemsToRemove = startItemNumber - 2;
        
        list<Healthcare_Cost__c> hccList = new list<Healthcare_Cost__c>();
        String dateId = '';
        String query = '';
        String sourceSystemId = null;
        Boolean costValue = false;
        try{
            if(sortOrder == null || sortOrder == ''){
                sortOrder = 'asc';
            }
            
            if(sortOrder == Label.TPL_Descending){
                // Populate DateID to maximum value
                dateId = '99999999zz';
                if(filterValue == Label.TPL_Manual_Records){
                    
                    if(itemsToRemove > 2000)
                    {
                        dateId = [SELECT dateId__c 
                                  FROM Healthcare_Cost__c 
                                  WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId AND Source_System_ID__c = :sourceSystemId 
                                  ORDER BY dateId__c DESC LIMIT 1 OFFSET 2000][0].dateId__c;
                        itemsToRemove -= 2001;
                        while( itemsToRemove > 2000 )
                        {
                            dateId = [SELECT dateId__c 
                                      FROM Healthcare_Cost__c 
                                      WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId  
                                      AND Source_System_ID__c = :sourceSystemId AND dateId__c < :dateId 
                                      ORDER BY dateId__c DESC LIMIT 1 OFFSET 2000][0].dateId__c;
                            itemsToRemove -= 2001;
                        }
                        
                    }
                    
                    if(itemsToRemove > 0){
                        
                        dateId = [SELECT dateId__c 
                                  FROM Healthcare_Cost__c 
                                  WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId 
                                  AND Source_System_ID__c = :sourceSystemId AND dateId__c < :dateId 
                                  ORDER BY dateId__c DESC LIMIT 1 OFFSET :itemsToRemove][0].dateId__c;
                        itemsToRemove = 0;
                    }
                    
                    query = 'SELECT ' + fields + ' FROM Healthcare_Cost__c WHERE Case2__c = \'' + caseId + '\' AND RecordTypeId = \'' 
                        + recordTypeId +'\' AND Source_System_ID__c = ' + sourceSystemId + ' AND dateId__c < \'' + dateId 
                        + '\' ORDER BY dateId__c DESC LIMIT ' + pageSize;
                    
                    hccList = Database.query(query);
                    
                }
                
                else if(filterValue == Label.TPL_Records_Created_Today) {
                    if(itemsToRemove > 2000)
                    {
                        dateId = [SELECT dateId__c 
                                  FROM Healthcare_Cost__c 
                                  WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId 
                                  AND Source_System_ID__c = :sourceSystemId AND CreatedDate = TODAY 
                                  ORDER BY dateId__c DESC LIMIT 1 OFFSET 2000][0].dateId__c;
                        itemsToRemove -= 2001;
                        while( itemsToRemove > 2000 )
                        {
                            dateId = [SELECT dateId__c 
                                      FROM Healthcare_Cost__c 
                                      WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId 
                                      AND Source_System_ID__c = :sourceSystemId AND CreatedDate = TODAY AND dateId__c < :dateId 
                                      ORDER BY dateId__c DESC LIMIT 1 OFFSET 2000][0].dateId__c;
                            itemsToRemove -= 2001;
                        }
                    }
                    
                    if(itemsToRemove > 0){
                        dateId = [SELECT dateId__c 
                                  FROM Healthcare_Cost__c 
                                  WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId 
                                  AND Source_System_ID__c = :sourceSystemId AND CreatedDate = TODAY  AND dateId__c < :dateId 
                                  ORDER BY dateId__c DESC LIMIT 1 OFFSET :itemsToRemove][0].dateId__c;
                        itemsToRemove = 0;
                    }
                    
                    query = 'SELECT ' + fields + ' FROM Healthcare_Cost__c WHERE Case2__c = \''+ caseId + '\' AND RecordTypeId = \'' 
                        + recordTypeId +'\' AND Source_System_ID__c = ' + sourceSystemId +' AND CreatedDate = TODAY AND dateId__c < \''+ dateId 
                        +'\' ORDER BY dateId__c DESC LIMIT '+ pageSize;
                    
                    hccList = Database.query(query);
                    
                }
                
                else {
                    if(itemsToRemove > 2000)
                    {
                        dateId = [SELECT dateId__c 
                                  FROM Healthcare_Cost__c 
                                  WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId 
                                  ORDER BY dateId__c DESC LIMIT 1 OFFSET 2000][0].dateId__c;
                        itemsToRemove -= 2001;
                        while( itemsToRemove > 2000 )
                        {
                            dateId = [SELECT dateId__c 
                                      FROM Healthcare_Cost__c 
                                      WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId AND dateId__c < :dateId 
                                      ORDER BY dateId__c DESC LIMIT 1 OFFSET 2000][0].dateId__c;
                            itemsToRemove -= 2001;
                        }
                    }
                    if(itemsToRemove > 0){
                        dateId = [SELECT dateId__c 
                                  FROM Healthcare_Cost__c 
                                  WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId AND dateId__c < :dateId 
                                  ORDER BY dateId__c DESC LIMIT 1 OFFSET :itemsToRemove][0].dateId__c;
                        itemsToRemove = 0;
                    }
                    
                    query = 'SELECT ' + fields + ' FROM Healthcare_Cost__c WHERE Case2__c = \'' + caseId + '\' AND RecordTypeId = \'' 
                        + recordTypeId + '\' AND dateId__c < \'' + dateId +'\' ORDER BY dateId__c DESC LIMIT ' + pageSize;
                    
                    hccList = Database.query(query);
                }
                
            }
            
            else
            {
                if(filterValue == Label.TPL_Manual_Records){
                    if(itemsToRemove > 2000)
                    {
                        dateId = [SELECT dateId__c 
                                  FROM Healthcare_Cost__c 
                                  WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId 
                                  AND Source_System_ID__c = :sourceSystemId 
                                  ORDER BY dateId__c ASC LIMIT 1 OFFSET 2000][0].dateId__c;
                        itemsToRemove -= 2001;
                        while( itemsToRemove > 2000 )
                        {
                            dateId = [SELECT dateId__c 
                                      FROM Healthcare_Cost__c 
                                      WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId  
                                      AND Source_System_ID__c = :sourceSystemId AND dateId__c > :dateId 
                                      ORDER BY dateId__c ASC LIMIT 1 OFFSET 2000][0].dateId__c;
                            itemsToRemove -= 2001;
                        }
                    }
                    if(itemsToRemove > 0){
                        dateId = [SELECT dateId__c 
                                  FROM Healthcare_Cost__c 
                                  WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId 
                                  AND Source_System_ID__c = :sourceSystemId AND dateId__c > :dateId 
                                  ORDER BY dateId__c ASC LIMIT 1 OFFSET :itemsToRemove][0].dateId__c;
                        itemsToRemove = 0;
                    }
                    
                    query = 'SELECT ' + fields + ' FROM Healthcare_Cost__c WHERE Case2__c = \''+caseId + '\' AND RecordTypeId = \''
                        + recordTypeId + '\' AND Source_System_ID__c = '+ sourceSystemId +' AND dateId__c > \'' + dateId + '\' ORDER BY dateId__c ASC LIMIT '+ pageSize;
                    
                    hccList = Database.query(query);
                    
                }
                
                else if(filterValue == Label.TPL_Records_Created_Today) {
                    if(itemsToRemove > 2000)
                    {
                        dateId = [SELECT dateId__c 
                                  FROM Healthcare_Cost__c 
                                  WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId 
                                  AND Source_System_ID__c = :sourceSystemId AND CreatedDate = TODAY 
                                  ORDER BY dateId__c ASC LIMIT 1 OFFSET 2000][0].dateId__c;
                        itemsToRemove -= 2001;
                        while( itemsToRemove > 2000 )
                        {
                            dateId = [SELECT dateId__c 
                                      FROM Healthcare_Cost__c 
                                      WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId 
                                      AND Source_System_ID__c = :sourceSystemId AND CreatedDate = TODAY  AND dateId__c > :dateId 
                                      ORDER BY dateId__c ASC LIMIT 1 OFFSET 2000][0].dateId__c;
                            itemsToRemove -= 2001;
                        }
                    }
                    
                    if(itemsToRemove > 0){
                        dateId = [SELECT dateId__c 
                                  FROM Healthcare_Cost__c
                                  WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId 
                                  AND Source_System_ID__c = :sourceSystemId AND CreatedDate = TODAY  AND dateId__c > :dateId 
                                  ORDER BY dateId__c ASC LIMIT 1 OFFSET :itemsToRemove][0].dateId__c;
                        itemsToRemove = 0;
                    }
                    
                    query = 'SELECT ' + fields + ' FROM Healthcare_Cost__c WHERE Case2__c = \'' + caseId +'\' AND RecordTypeId = \'' 
                        + recordTypeId +'\' AND Source_System_ID__c = ' + sourceSystemId + ' AND CreatedDate = TODAY AND dateId__c > \'' + dateId 
                        +'\' ORDER BY dateId__c ASC LIMIT ' + pageSize;
                    
                    hccList = Database.query(query);
                    
                }
                
                else {
                    if(itemsToRemove > 2000)
                    {
                        dateId = [SELECT dateId__c 
                                  FROM Healthcare_Cost__c 
                                  WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId 
                                  ORDER BY dateId__c ASC LIMIT 1 OFFSET 2000][0].dateId__c;
                        itemsToRemove -= 2001;
                        while( itemsToRemove > 2000 )
                        {
                            dateId = [SELECT dateId__c 
                                      FROM Healthcare_Cost__c 
                                      WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId AND dateId__c > :dateId 
                                      ORDER BY dateId__c ASC LIMIT 1 OFFSET 2000][0].dateId__c;
                            itemsToRemove -= 2001;
                        }
                    }
                    if(itemsToRemove > 0){
                        dateId = [SELECT dateId__c 
                                  FROM Healthcare_Cost__c 
                                  WHERE Case2__c = :caseId AND RecordTypeId = :recordTypeId AND dateId__c > :dateId 
                                  ORDER BY dateId__c ASC LIMIT 1 OFFSET :itemsToRemove][0].dateId__c;
                        itemsToRemove = 0;
                    }
                    
                    query = 'SELECT ' + fields + ' FROM Healthcare_Cost__c WHERE Case2__c = \'' + caseId + '\' AND RecordTypeId = \''
                        + recordTypeId + '\' AND dateId__c > \'' + dateId + '\' ORDER BY dateId__c ASC LIMIT ' + pageSize;
                    
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

    @AuraEnabled(cacheable=true)
public static List<Healthcare_Cost__c> getHCCostCaseRecordsWithSortBy(
    Id caseId,
    String filterValue,
    Id recordTypeId,
    Integer offsetRows,
    Integer limitRows,
    String fieldListCsv,
    String sortOrder,   // "asc" | "desc"
    String sortBy       // e.g., "Date_of_Service__c"
){
    // Whitelist allowed sort fields
    Set<String> allowedSorts = new Set<String>{
        'Date_of_Service__c',
        'Location_Responded__c',
        'Site_Code__c',
        'Facility__c',
        'Basic_Amount__c',
        'Total_Cost_Override__c',
        'Fixed_Wing_Helicopter__c',
        'Source_System_ID__c',
        'CreatedDate',
        'LastModifiedDate'
    };
    if (String.isBlank(sortBy) || !allowedSorts.contains(sortBy)) {
        sortBy = 'Date_of_Service__c';
    }
    String direction = (sortOrder == 'desc') ? 'DESC' : 'ASC';

    // IMPORTANT: use the correct Case lookup field on Healthcare_Cost__c
    List<String> whereParts = new List<String>();
    whereParts.add('Case2__c = :caseId');     // <-- not Case__c
    whereParts.add('RecordTypeId = :recordTypeId');

    if (filterValue == 'Manual Records') {
        whereParts.add('Source_System_ID__c = NULL');
    } else if (filterValue == 'Records Created Today') {
        whereParts.add('CreatedDate = TODAY');
    }
    String whereSoql = ' WHERE ' + String.join(whereParts, ' AND ');

    // Fields to select
    String selectFields = String.isBlank(fieldListCsv) ? 'Id' : fieldListCsv;

    // Normalize LIMIT/OFFSET (OFFSET is zero-based)
    Integer safeLimit  = (limitRows == null || limitRows <= 0) ? 25 : limitRows;
    Integer safeOffset = Math.max(0, (offsetRows == null) ? 0 : offsetRows - 1);

    String soql =
        'SELECT ' + selectFields +
        ' FROM Healthcare_Cost__c' +
        whereSoql +
        ' ORDER BY ' + sortBy + ' ' + direction + ' NULLS LAST' +
        ' LIMIT :safeLimit OFFSET :safeOffset';

    try {
        return Database.query(soql);
    } catch (Exception e) {
        System.debug('HCCostCaseDAO.getHCCostCaseRecordsWithSortBy ERROR: ' + e.getMessage());
        return new List<Healthcare_Cost__c>();
    }
}


}