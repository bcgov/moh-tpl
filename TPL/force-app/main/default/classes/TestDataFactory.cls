@IsTest
public with sharing class TestDataFactory {
    
    /*
		Method Name:individualAccount
		Parameters: n/a
		Description: Test method used to return an account for creating the record
	*/
    public static Account individualAccount(){
        Account acc = new Account();
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Individual').getRecordTypeId();
        acc.FirstName = 'David';
        acc.LastName = 'Scott';
        acc.PHN__pc = '7867561283';
        acc.Date_of_Birth__pc = Date.newInstance(1996, 11, 14);
        return acc;
    }
    
    /*
		Method Name:newCase
		Parameters: Account ID
		Description: Test method used to return a case having an account associated for creating the record
	*/
    public static Case newCase(String accountId){
        Case c = new Case();
        c.AccountId = accountId;
        c.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Individual').getRecordTypeId();
        c.Status = 'Open';
        c.Priority = 'Medium';
        c.Incident_Date__c = Date.newInstance(2022, 09, 16);
        c.Claim_Number__c = '456784';
        return c;     
    }

    /*
		Method Name:ambulanceCostRecord
		Parameters: Account ID, Case ID
		Description: Test method used to return a list having ambulance Healthcare cost records having an account and case associated with it
	*/
    public static Healthcare_Cost__c ambulanceCostRecord(String accountId, String caseId){
        Healthcare_Cost__c hcc = new Healthcare_Cost__c();
        Id recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Ambulance' AND sObjectType = 'Healthcare_Cost__c'].Id;
        hcc.RecordTypeId = recordTypeId;
        hcc.Account__c = accountId;
        hcc.Case2__c = caseId;
        hcc.Date_of_Service__c = Date.newInstance(1995, 06, 08);
       	hcc.Cost_Include__c = true;
        hcc.Cost_Review__c = true;
        hcc.Total_Cost_Override__c = 1000;
        return hcc;
    }

 /*
		Method Name:continuingcareCostRecord
		Parameters: Account ID, Case ID
		Description: Test method used to return a list having Continuing Care Healthcare cost records having an account and case associated with it
	*/
    public static Healthcare_Cost__c continuingcareCostRecord(String accountId, String caseId){
        Healthcare_Cost__c hcc = new Healthcare_Cost__c();
        Id recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Continuing_Care' AND sObjectType = 'Healthcare_Cost__c'].Id;
        hcc.RecordTypeId = recordTypeId;
        hcc.Account__c = accountId;
        hcc.Case2__c = caseId;
        hcc.Description__c = 'Test Continuing Care';
        hcc.Cost__c = 500;
        return hcc;
    }

    /*
		Method Name:futurecareCostRecord
		Parameters: Account ID, Case ID
		Description: Test method used to return a list having Future Care Healthcare cost records having an account and case associated with it
	*/
    public static Healthcare_Cost__c futurecareCostRecord(String accountId, String caseId){
        Healthcare_Cost__c hcc = new Healthcare_Cost__c();
        Id recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Future_Care' AND sObjectType = 'Healthcare_Cost__c'].Id;
        hcc.RecordTypeId = recordTypeId;
        hcc.Account__c = accountId;
        hcc.Case2__c = caseId;
        hcc.Description__c = 'Test Future Care';
        hcc.Cost__c = 200;
        return hcc;
    }

    /*
		Method Name:hospitalizationCostRecord
		Parameters: Account ID, Case ID
		Description: Test method used to return a list having Hospitalization Healthcare cost records having an account and case associated with it
	*/
    public static Healthcare_Cost__c hospitalizationCostRecord(String accountId, String caseId){
        Healthcare_Cost__c hcc = new Healthcare_Cost__c();
        Id recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Hospitalization' AND sObjectType = 'Healthcare_Cost__c'].Id;
        hcc.RecordTypeId = recordTypeId;
        hcc.Account__c = accountId;
        hcc.Case2__c = caseId;
        hcc.Cost_Include__c = true;
        hcc.Cost_Review__c = true;
        hcc.Date_of_Service__c = Date.newInstance(2023, 2, 17);
        hcc.Date_of_Admission__c = Date.newInstance(2023, 2, 18);
        hcc.Date_of_Discharge__c = Date.newInstance(2023, 2, 25);
        hcc.Location_of_Incident__c = 'Vancouver General Hospital';
        hcc.Intervention_Code_CCI__c = '1AE54LAJA';
        hcc.CCI_Level__c = 'High';
        hcc.Standard_Daily_Rate__c = 4500;
        hcc.Total_Cost_Override__c = 6000;
        hcc.Diagnostic_Treatment_Service2__c = 'Testing Hospital Services';
        return hcc;
    }

     /*
		Method Name:MSPCostRecord
		Parameters: Account ID, Case ID
		Description: Test method used to return a list having MSP Healthcare cost records having an account and case associated with it
	*/
    public static Healthcare_Cost__c MSPCostRecord(String accountId, String caseId){
        Healthcare_Cost__c hcc = new Healthcare_Cost__c();
        Id recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'MSP' AND sObjectType = 'Healthcare_Cost__c'].Id;
        hcc.RecordTypeId = recordTypeId;
        hcc.Account__c = accountId;
        hcc.Case2__c = caseId;
        hcc.Cost_Include__c = true;
        hcc.Cost_Review__c = true;
        hcc.Date_of_Service__c = Date.newInstance(2023, 2, 17);
        hcc.Description_of_Service2__c = 'Test MSP Service';
        hcc.Practitioner_Number__c = '234A';
        hcc.Practitioner_Name__c = 'Test Practitioner';
        hcc.Amount_Paid__c = 500;
        hcc.Total_Cost_Override__c = 6000;
        return hcc;
    }

     /*
		Method Name:PharmacareCostRecord
		Parameters: Account ID, Case ID
		Description: Test method used to return a list having Pharmacare Healthcare cost records having an account and case associated with it
	*/
    public static Healthcare_Cost__c PharmacareCostRecord(String accountId, String caseId){
        Healthcare_Cost__c hcc = new Healthcare_Cost__c();
        Id recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Pharmacare' AND sObjectType = 'Healthcare_Cost__c'].Id;
        hcc.RecordTypeId = recordTypeId;
        hcc.Account__c = accountId;
        hcc.Case2__c = caseId;
        hcc.Cost_Include__c = true;
        hcc.Cost_Review__c = true;
        hcc.Date_of_Service__c = Date.newInstance(2023, 2, 17);
        hcc.Practitioner_Name__c = 'Test Practitioner';
        hcc.DIN__c = '23478921';
        hcc.Name_of_Drug__c = 'Tylenol';
        hcc.Cost_of_Drug__c = 500;
        hcc.Total_Cost_Override__c = 6000;
        return hcc;
    }
}