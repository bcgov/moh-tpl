public with sharing class HCCCostAmbulanceAccountHelper {
   
    private static Id getAmbulanceRecordId(){
        return Schema.SObjectType.Healthcare_Cost__c.getRecordTypeInfosByName().get('Ambulance').getRecordTypeId();
    }
    
    @AuraEnabled
    public static Integer getAmbulanceCountonAccount(String accId, String selectedFilterValue){
        Integer countAmbulanceAccount = 0;
        try {
            Id recordTypeId = getAmbulanceRecordId();
            if(selectedFilterValue == Label.TPL_All_Records){
                countAmbulanceAccount = [SELECT count() from Healthcare_Cost__c where Account__c = :accId and RecordTypeId = :recordTypeId];
            }
            else {
                countAmbulanceAccount = [SELECT count() from Healthcare_Cost__c where Account__c = :accId and RecordTypeId = :recordTypeId and Cost_Include__c = false and Cost_Review__c = false ];
            }

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        System.debug('Count of Ambulance records on Account  : ' + countAmbulanceAccount);
        return countAmbulanceAccount;
    }

    @AuraEnabled
    public static List <HCCCaseAssociationWrapper> getHealthcareCostsAmbulanceForAccount(String accId, String selectedFilterValue, Integer limitSize, Integer offsetSize)
    {
        List<Healthcare_Cost__c> hccCostList = new List<Healthcare_Cost__c> ();
        List<HCCCaseAssociationWrapper> hccCaseAssociation = new List<HCCCaseAssociationWrapper>();
        Set<Id> hccCaseId = new Set<Id>();
        Boolean costInclude, costReview;
        try{
        	Id recordTypeId = getAmbulanceRecordId();
            if(selectedFilterValue == Label.TPL_All_Records){
                hccCostList = [Select Id, Name, Case2__c, Case2__r.CaseNumber, Cost_Include__c, Cost_Review__c, Date_of_Service__c, Location_Responded__c, Basic_Amount__c, Cost__c, Total_Cost_Override__c, Site_Code__c, Facility__c, FacilityName__c, Fixed_Wing_Helicopter__c, Source_System_ID__c from Healthcare_Cost__c where Account__c = :accId and RecordTypeId = :recordTypeId ORDER BY Name LIMIT :limitSize OFFSET :offsetSize];
                System.debug('HCC Cost List Size : ' + hccCostList.size());
            }
            else{
                hccCostList = [Select Id, Name, Case2__c, Case2__r.CaseNumber, Cost_Include__c, Cost_Review__c,  Date_of_Service__c, Location_Responded__c, Basic_Amount__c, Cost__c, Total_Cost_Override__c, Site_Code__c, Facility__c, FacilityName__c, Fixed_Wing_Helicopter__c, Source_System_ID__c from Healthcare_Cost__c where Account__c = :accId and RecordTypeId = :recordTypeId and Cost_Include__c = false and Cost_Review__c = false ORDER BY Name LIMIT :limitSize OFFSET :offsetSize];        
                System.debug('HCC Cost List Size : ' + hccCostList.size());
            }
            
            for(Healthcare_Cost__c hcc: hccCostList){
                hccCaseId.add(hcc.Case2__c);
            }
            Map<Id,String> caseNumberMap = new Map<Id,String>();
            List<Case> caseList= HCCCostController.getCaseNumber(hccCaseId);
        
            for(Case c: caseList){
                    caseNumberMap.put(c.Id, c.CaseNumber);
                
            }
            for(Healthcare_Cost__c hcc: hccCostList){
                HCCCaseAssociationWrapper caseAssociation = new HCCCaseAssociationWrapper(); 
                caseAssociation.recordId = hcc.Id;
                caseAssociation.Name = hcc.Name;
                caseAssociation.CaseId = hcc.Case2__c;
                caseAssociation.caseNumber = caseNumberMap.get(hcc.Case2__c);
                caseAssociation.costIncluded = hcc.Cost_Include__c;
                caseAssociation.costReview = hcc.Cost_Review__c;
                caseAssociation.dateOfService = hcc.Date_of_Service__c;
                caseAssociation.facilityName = hcc.FacilityName__c;
                caseAssociation.fixedWingHelicopter = hcc.Fixed_Wing_Helicopter__c;
                caseAssociation.locationResponded = hcc.Location_Responded__c;
                caseAssociation.siteCode = hcc.Site_Code__c;
                caseAssociation.totalCostOverride = hcc.Total_Cost_Override__c;
                caseAssociation.basicAmount = hcc.Basic_Amount__c;
                caseAssociation.sourceSystemId = hcc.Source_System_ID__c;
                hccCaseAssociation.add(caseAssociation);
            
            }
        }
    
        catch(NullPointerException nullpointer){
            nullpointer.getMessage();
        }
        catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return hccCaseAssociation;
    }

    @AuraEnabled
    public static HCCostAccountCaseWrapper updateHCCCaseInformation (List<HCCCaseAssociationWrapper> hccList, String caseId, List<HCCCaseAssociationWrapper> recordDisplay){
        String giveStatus = null;
        String passMessage = null;
        Boolean checkFail = false;
        HCCostAccountCaseWrapper hac = new HCCostAccountCaseWrapper();
        List<Healthcare_Cost__c> updateHealthCareCost = new List<Healthcare_Cost__c>();
            
        if(caseId == null || caseId.length() == 0 || hccList.size() == 0){
                passMessage = Label.TPL_Empty_Selection;
        }
        else{
            for(HCCCaseAssociationWrapper hcc: hccList){
                if(hcc.costIncluded == true || hcc.costReview == true){
                    checkFail = true;
                    break;
                }
                else{
                    updateHealthCareCost.add(new Healthcare_Cost__c(Id = hcc.recordId, Case2__c = caseId));
                    checkFail = false;
                }      
            }
            
            System.debug('Records Display Length : ' + recordDisplay.size());
            if(!checkFail){ 
                Map<Id, Integer> rowCountMap = new Map<Id, Integer>();
                Integer index = 1;
                for(HCCCaseAssociationWrapper hcc: recordDisplay){
                    rowCountMap.put(hcc.recordId, index);
                    index++;
                }   
                try{
                    Database.SaveResult[] srList = Database.update(updateHealthCareCost, false);
                    Set<Id> caseIds = new Set<Id>();
                    String result = '';
                    caseIds.add(caseId);
                    List<Case> caseNum = HCCCostController.getCaseNumber(caseIds);
                    List<Integer> capturedIndex = new List<Integer>();
                    for (Database.SaveResult sr : srList){
                        if (sr.isSuccess()) {
                            capturedIndex.add(rowCountMap.get(sr.getId()));
                        }
                        else{
                            for(Database.Error err : sr.getErrors()) {
                              result += 'Row ' + rowCountMap.get(sr.getId()) + ' ' + err.getMessage() + '\n';
                            }
                           
                        }
                    }
                    if(capturedIndex.size() == updateHealthCareCost.size())
                    {
                        passMessage = Label.TPL_Passed;
                  
                    }
                    else if(capturedIndex.size()>0){
                        passMessage = 'Partial Success';
                        giveStatus = result;
                    }
                    else{
                        giveStatus = result;
                    }  
                    
                    
                } 
                catch(DmlException dml){
                    System.debug(dml.getMessage());
                    giveStatus = dml.getMessage();
                }
                catch(NullPointerException np){
                    System.debug(np.getMessage());
                    giveStatus = Label.TPL_Failed;
                }
            }
            else{
                passMessage = Label.TPL_Failed;
            }
            
            hac.updateMessage = giveStatus;
            hac.passMessage = passMessage;
        }
        return hac;
    }
         
       public class HCCCaseAssociationWrapper{
        @AuraEnabled public Id recordId {get;set;}
        @AuraEnabled public String Name {get;set;}
        @AuraEnabled public String CaseId {get;set;}
        @AuraEnabled public String caseNumber {get;set;}
        @AuraEnabled public boolean costIncluded{get;set;}
        @AuraEnabled public boolean costReview{get;set;}
        @AuraEnabled public Date dateOfService{get;set;}
        @AuraEnabled public String locationResponded{get;set;}
        @AuraEnabled public Decimal basicAmount{get;set;}
        @AuraEnabled public Decimal totalCostOverride{get;set;}
        @AuraEnabled public Decimal fixedWingHelicopter{get;set;}
        @AuraEnabled public String siteCode{get;set;}
        @AuraEnabled public string facilityName{get;set;}
        @AuraEnabled public String sourceSystemId {get;set;}       
    }

    public class HCCostAccountCaseWrapper{
        @AuraEnabled public String updateMessage {get;set;}
        @AuraEnabled public String passMessage {get;set;}
    }
}