@IsTest
public with sharing class TestDataFactory {
    
    /*
		Method Name:individualAccount
		Parameters: n/a
		Description: Test method used to return an individual account for creating the record
	*/
    // public static Account individualAccount(){
    //     Account acc = new Account();
    //     acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Individual').getRecordTypeId();
    //     acc.FirstName = 'David';
    //     acc.LastName = 'Scott';
    //     acc.Type = 'Hospital';
    //     acc.Date_of_Birth__pc = Date.newInstance(1996, 11, 14);
    //     return acc;
    // }
    
    public static Account individualAccount() {
    Account acc = new Account();
    acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Individual').getRecordTypeId();
    acc.Type = 'Hospital';
 
    if (Schema.SObjectType.Account.fields.getMap().containsKey('IsPersonAccount')) {
        acc.put('IsPersonAccount', true);
    }
 
    if (Schema.SObjectType.Account.fields.getMap().containsKey('FirstName')) {
        acc.put('FirstName', 'David');
    }
 
    if (Schema.SObjectType.Account.fields.getMap().containsKey('LastName')) {
        acc.put('LastName', 'Scott');
    }
 
    if (Schema.SObjectType.Account.fields.getMap().containsKey('Date_of_Birth__pc')) {
        acc.put('Date_of_Birth__pc', Date.newInstance(1996, 11, 14));
    }
 
  
    return acc;
    }
    
     /*
		Method Name:facilityAccount
		Parameters: n/a
		Description: Test method used to return a facility account for creating the record
	*/
    public static Account facilityAccount(){
        Account acc = new Account();
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Facility').getRecordTypeId();
        acc.Site_Code__c = '123';
        acc.Name = 'Facility Account';
        acc.Status__c = true;
        return acc;
    }
      /*
		Method Name:newBatch
		Description: Test method used to return a batch
	*/
    public static Batch__c newBatch(){
        Batch__c batch = new Batch__c();
        batch.Batch_Status__c = 'Open';
        batch.Batch_Type__c = 'Private';
        batch.Batch_Date__c = System.now();
        return batch;
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
		Method Name:newClassActionCase
		Parameters: Account ID
		Description: Test method used to return a new Class Action Case having an account associated for creating the record
	*/
    public static Case newClassActionCase(String accountId){
        Case c = new Case();
        c.AccountId = accountId;
        c.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Class Action').getRecordTypeId();
        c.Status = 'Open';
        c.Priority = 'Medium';
        c.Incident_Date__c = Date.newInstance(2022, 09, 16);
        return c;     
    }

    /*
		Method Name:new Product
		Parameters: Account ID
		Description: Test method used to return a case having an account associated for creating the record
	*/
         public static Product2 newProduct(String accountId){
         Product2 pr = new Product2();
         pr.Account__c = accountId;
         pr.IsActive = true;
         pr.Name = 'test';
         pr.Family = 'Specific';
         pr.Description = 'Product Description';
         pr.Service_Type__c = 'Acute';
         pr.Effective_Start_Date__c = Date.today();
         pr.Effective_End_Date__c = Date.newInstance(2100, 12, 12);
         pr.Effective_year__c = '2023';
         return pr;     
       }
    public static Product2 newGenericProduct(String accountId){
         Product2 pr = new Product2();
         pr.IsActive = true;
         pr.Name = 'test';
         pr.Family = 'Generic';
         pr.Description = 'Product Description';
         pr.Service_Type__c = 'Extended Care';
         pr.Effective_Start_Date__c = Date.today();
         pr.Effective_End_Date__c = Date.newInstance(2100, 12, 31);
         pr.Effective_year__c = '1900';
         return pr;     
       }
    /*
		Method Name:ambulanceCostRecord
		Parameters: Account ID, Case ID
		Description: Test method used to return a list having ambulance Healthcare cost records having an account and case associated with it
	*/
    public static Healthcare_Cost__c ambulanceCostRecord(String accountId, String caseId){
        Healthcare_Cost__c hcc = new Healthcare_Cost__c();
        Id recordTypeId = Schema.SObjectType.Healthcare_Cost__c.getRecordTypeInfosByName().get('Ambulance').getRecordTypeId();

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
        Id recordTypeId = Schema.SObjectType.Healthcare_Cost__c.getRecordTypeInfosByName().get('Continuing Care').getRecordTypeId();
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
        Id recordTypeId = Schema.SObjectType.Healthcare_Cost__c.getRecordTypeInfosByName().get('Future Care').getRecordTypeId(); 
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
    public static Healthcare_Cost__c hospitalizationCostRecord(String accountId, String caseId, String facilityId, String serviceProviderFacility, String serviceType){
        Healthcare_Cost__c hcc = new Healthcare_Cost__c();
        Id recordTypeId = Schema.SObjectType.Healthcare_Cost__c.getRecordTypeInfosByName().get('Hospitalization').getRecordTypeId();
        hcc.RecordTypeId = recordTypeId;
        hcc.Account__c = accountId;
        hcc.Case2__c = caseId;
        hcc.Cost_Include__c = true;
        hcc.Cost_Review__c = true;
        hcc.Date_of_Admission__c = Date.newInstance(2023, 2, 18);
        hcc.Date_of_Discharge__c = Date.newInstance(2023, 2, 25);
        hcc.Location_of_Incident__c = 'Vancouver General Hospital';
        hcc.Standard_Daily_Rate__c = 4500;
        hcc.Total_Cost_Override__c = 6000;
        hcc.Service_Provided_by_Facility__c = serviceProviderFacility;
        hcc.Service_Type2__c = serviceType;
        hcc.Diagnostic_Treatment_Service2__c = 'Testing Hospital Services';
        return hcc;
    }

     /*
		Method Name:MSPCostRecord
		Parameters: Account ID, Case ID
		Description: Test method used to return a list having MSP Healthcare cost records having an account and case associated with it
	*/
    public static Healthcare_Cost__c mspCostRecord(String accountId, String caseId){
        Healthcare_Cost__c hcc = new Healthcare_Cost__c();
        Id recordTypeId = Schema.SObjectType.Healthcare_Cost__c.getRecordTypeInfosByName().get('MSP').getRecordTypeId();
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
    public static Healthcare_Cost__c pharmacareCostRecord(String accountId, String caseId){
        Healthcare_Cost__c hcc = new Healthcare_Cost__c();
        Id recordTypeId = Schema.SObjectType.Healthcare_Cost__c.getRecordTypeInfosByName().get('Pharmacare').getRecordTypeId();
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
    
    public Static Payment__c newPayments(Id caseId, Integer paymentAmt, String paymentMethod, Id batchId){
        Payment__c payment = new Payment__c();
        payment.Case_Number__c = caseId;
        payment.Payment_Amount__c = paymentAmt;
        payment.Payment_Method__c = paymentMethod;
        payment.Batch_Number__c = batchId;
        return payment;
    }
}