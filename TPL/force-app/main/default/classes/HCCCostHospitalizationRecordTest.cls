@isTest
public class HCCCostHospitalizationRecordTest {
    @isTest
    static void testHospitalizationRecordsonAccount(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Account facility = TestDataFactory.facilityAccount();
        insert facility;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;        
        Product2 pr = TestDataFactory.newProduct(facility.Id);
        insert pr;
        Healthcare_Cost__c hcc1 = TestDataFactory.hospitalizationCostRecord(acc.Id, c.Id, facility.Id, pr.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.hospitalizationCostRecord(acc.Id, c.Id, facility.Id, pr.Id);
        Healthcare_Cost__c hcc3 = TestDataFactory.hospitalizationCostRecord(acc.Id, c.Id, facility.Id, pr.Id);
        Healthcare_Cost__c hcc4 = TestDataFactory.hospitalizationCostRecord(acc.Id, c.Id, facility.Id, pr.Id);
        
        insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3, hcc4};

        Test.startTest();
        List <Healthcare_Cost__c> hccListforAccounts = HCCCostHospitalizationRecord.getHealthcareCostsHospitalForAccount(acc.Id);
        Test.stopTest();
        System.assertEquals(4, hccListforAccounts.size());
    }
       
    @isTest
    static void testHospitalizationRecordsCase(){
        Account acc = TestDataFactory.individualAccount();
        insert acc;
        Account facility = TestDataFactory.facilityAccount();
        insert facility;
        Case c = TestDataFactory.newCase(acc.Id);
        insert c;        
        Product2 pr = TestDataFactory.newProduct(facility.Id);
        insert pr;
        Healthcare_Cost__c hcc1 = TestDataFactory.hospitalizationCostRecord(acc.Id, c.Id, facility.Id, pr.Id);
        Healthcare_Cost__c hcc2 = TestDataFactory.hospitalizationCostRecord(acc.Id, c.Id, facility.Id, pr.Id);
        Healthcare_Cost__c hcc3 = TestDataFactory.hospitalizationCostRecord(acc.Id, c.Id, facility.Id, pr.Id);
        Healthcare_Cost__c hcc4 = TestDataFactory.hospitalizationCostRecord(acc.Id, c.Id, facility.Id, pr.Id);
        
        insert new Healthcare_Cost__c[] {hcc1, hcc2, hcc3, hcc4};
        Test.startTest();
        List <Healthcare_Cost__c> hccListforCases = HCCCostHospitalizationRecord.getHealthcareCostsHospitalForCase(c.Id);
        Test.stopTest();
        System.assertEquals(4, hccListforCases.size());
    
    }
    
}