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
}