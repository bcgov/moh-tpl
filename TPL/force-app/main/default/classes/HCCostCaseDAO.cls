public with sharing class HCCostCaseDAO {
    public static List<Healthcare_Cost__c> getHCCostCaseRecords(String caseId, String filterValue, Id recordTypeId, Integer startItemNumber, Integer pageSize, String fields){
        Integer itemsToRemove = startItemNumber - 2;
        list<Healthcare_Cost__c> hccList = new list<Healthcare_Cost__c>();
        String locationID = '';
        String sourceSystemId = null;
        String query = '';
        try{
          
            if(filterValue == Label.TPL_Manual_Records){
                if(itemsToRemove > 2000)
                {
                    locationID = [select Id from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId and Source_System_ID__c = :sourceSystemId and Id > :locationID ORDER BY Id LIMIT 1 OFFSET 2000][0].Id;
                    itemsToRemove -= 2001;
                    while( itemsToRemove > 2000 )
                    {
                        locationID = [select Id from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId and Source_System_ID__c = :sourceSystemId and Id > :locationID order by Id LIMIT 1 OFFSET 2000][0].Id;
                        itemsToRemove -= 2001;
                    }
                }
                if(itemsToRemove > 0){
                    locationID = [select Id from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId and Source_System_ID__c = :sourceSystemId and Id > :locationID ORDER BY Id LIMIT 1 OFFSET :itemsToRemove][0].Id;
                    itemsToRemove = 0;
                }
                query = 'SELECT ' + fields + ' FROM Healthcare_Cost__c WHERE Case2__c = :caseId and RecordTypeId = :recordTypeId and Source_System_ID__c = :sourceSystemId and Id > :locationID ORDER BY Id LIMIT :pageSize';
                hccList = Database.query(query);
                //                hccList = [select Id,Cost_Include__c, Cost_Review__c, Name, Date_of_Service__c, Location_Responded__c, Basic_Amount__c, Cost__c, Total_Cost_Override__c, Fixed_Wing_Helicopter__c, Site_Code__c, Facility__c, FacilityName__c, Sub_Total__c, Source_System_ID__c from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId and Source_System_ID__c = :sourceSystemId and Id > :locationID order by Id LIMIT :pageSize];
            }
            else if(filterValue == Label.TPL_Records_Created_Today){
                if(itemsToRemove > 2000)
                {
                    locationID = [select Id from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId and Source_System_ID__c = :sourceSystemId and CreatedDate = TODAY and Id > :locationID ORDER BY Id LIMIT 1 OFFSET 2000][0].Id;
                    itemsToRemove -= 2001;
                    while( itemsToRemove > 2000 )
                    {
                        locationID = [select Id from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId and Source_System_ID__c = :sourceSystemId and CreatedDate = TODAY and Id > :locationID order by Id LIMIT 1 OFFSET 2000][0].Id;
                        itemsToRemove -= 2001;
                    }
                }
                if(itemsToRemove > 0){
                    locationID = [select Id from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId and Source_System_ID__c = :sourceSystemId and CreatedDate = TODAY and Id > :locationID ORDER BY Id LIMIT 1 OFFSET :itemsToRemove][0].Id;
                    itemsToRemove = 0;
                }
    
                query = 'SELECT ' + fields + ' FROM Healthcare_Cost__c WHERE Case2__c = :caseId and RecordTypeId = :recordTypeId and Source_System_ID__c = :sourceSystemId and CreatedDate = TODAY and Id > :locationID order by Id LIMIT :pageSize';
                hccList = Database.query(query);
//                hccList = [select Id,Cost_Include__c, Cost_Review__c, Name, Date_of_Service__c, Location_Responded__c, Basic_Amount__c, Cost__c, 
//                Total_Cost_Override__c, Fixed_Wing_Helicopter__c, Site_Code__c, Facility__c, FacilityName__c, Sub_Total__c, Source_System_ID__c, CreatedDate from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId and Source_System_ID__c = :sourceSystemId and CreatedDate = TODAY and Id > :locationID order by Id LIMIT :pageSize];
            }
            else {
                if(itemsToRemove > 2000)
                {
                    locationID = [select Id from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId and Id > :locationID ORDER BY Id LIMIT 1 OFFSET 2000][0].Id;
                    itemsToRemove -= 2001;
                    while( itemsToRemove > 2000 )
                    {
                        locationID = [select Id from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId and Id > :locationID order by Id LIMIT 1 OFFSET 2000][0].Id;
                        itemsToRemove -= 2001;
                    }
                }
                if(itemsToRemove > 0){
                    locationID = [select Id from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId and Id > :locationID ORDER BY Id LIMIT 1 OFFSET :itemsToRemove][0].Id;
                    itemsToRemove = 0;
                }
                query = 'SELECT ' + fields + ' FROM Healthcare_Cost__c WHERE Case2__c = :caseId and RecordTypeId = :recordTypeId and Id > :locationID order by Id LIMIT :pageSize';
                hccList = Database.query(query);    
//                hccList = [select Id,Cost_Include__c, Cost_Review__c, Name, Date_of_Service__c, Location_Responded__c, Basic_Amount__c, Cost__c, 
//                Total_Cost_Override__c, Fixed_Wing_Helicopter__c, Site_Code__c, Facility__c, FacilityName__c, Sub_Total__c, Source_System_ID__c from Healthcare_Cost__c where Case2__c = :caseId and RecordTypeId = :recordTypeId and Id > :locationID order by Id LIMIT :pageSize];
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
        system.debug(hccList);
        return hccList;
   }
}