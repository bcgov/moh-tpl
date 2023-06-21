@isTest(seeAllData=true)
public with sharing class HCCostDocumentGenerationTest {
    @isTest
    static void testDocGenTPLAnalyst(){
        User u = [SELECT Alias, Id, Email, LastName, ProfileId, UserName from User where Email = 'anudish.jinturkar@gov.bc.ca' LIMIT 1];
        System.debug(u);
        
        Test.startTest();        
        System.runAs(u) {
            try{
                
                List<Case> caseDetails = [SELECT id,accountid,total_case_value__c,future_care_total2__c,pharmacare_total2__c,continuing_care_total2__c,claim_number__c,
                                          ambulance_total2__c,phn__c,incident_date__c,description,date_of_birth__c,msp_total2__c,casenumber,
                                          hospitalization_total2__c 
                                          FROM Case 
                                          WHERE (Id = '500Au000006tM2rIAE') LIMIT 50000];
                System.debug('Case : '+ caseDetails.size());
                List<Account> accountDetails = [SELECT id,description,name FROM Account WHERE (Id = '001Au00000FtkhoIAB') LIMIT 50000];
                System.debug('Account : ' + accountDetails.size());
                List<Healthcare_Cost__c> hccAmbulance = [SELECT id,recordtypename__c,case2__c,location_type_code__c,location_type_description2__c,
                                                         cost_include__c,cost_review__c,practitioner_name__c,cost__c,description_of_service2__c,
                                                         date_of_service__c,total_cost_override__c,service_type2__c,phn__c,facilityname__c,
                                                         location_responded__c,description__c,diagnostic_code__c,fee_item_code__c,name_of_drug__c,
                                                         date_of_admission__c,number_of_days__c,date_of_discharge__c,name 
                                                         FROM Healthcare_Cost__c 
                                                         WHERE (Case2__c = '500Au000006tM2rIAE' 
                                                                AND Cost_Include__c = true AND Cost_Review__c = true 
                                                                AND RecordTypeName__c = 'Ambulance') LIMIT 500000];
                System.debug('HCC Ambulance : ' + hccAmbulance.size());
                List<Healthcare_Cost__c> hccHospital = [SELECT id,recordtypename__c,case2__c,location_type_code__c,location_type_description2__c,
                                                        cost_include__c,cost_review__c,practitioner_name__c,cost__c,description_of_service2__c,
                                                        date_of_service__c,total_cost_override__c,service_type2__c,phn__c,facilityname__c,location_responded__c,
                                                        description__c,diagnostic_code__c,fee_item_code__c,name_of_drug__c,date_of_admission__c,number_of_days__c,
                                                        date_of_discharge__c,name 
                                                        FROM Healthcare_Cost__c 
                                                        WHERE (Case2__c = '500Au000006tM2rIAE' AND Cost_Include__c = true AND Cost_Review__c = true 
                                                               AND RecordTypeName__c = 'Hospitalization') LIMIT 50000];
                System.debug('HCC Hospital :' + hccHospital.size());
                List<Healthcare_Cost__c> hccMSP = [SELECT id,recordtypename__c,case2__c,location_type_code__c,location_type_description2__c,
                                                   cost_include__c,cost_review__c,practitioner_name__c,cost__c,description_of_service2__c,
                                                   date_of_service__c,total_cost_override__c,service_type2__c,phn__c,facilityname__c,location_responded__c,
                                                   description__c,diagnostic_code__c,fee_item_code__c,name_of_drug__c,date_of_admission__c,number_of_days__c,date_of_discharge__c,name 
                                                   FROM Healthcare_Cost__c 
                                                   WHERE (Case2__c = '500Au000006tM2rIAE' AND Cost_Include__c = true 
                                                          AND Cost_Review__c = true AND RecordTypeName__c = 'MSP') LIMIT 50000];                             
                System.debug('HCC MSP :' + hccMSP.size());
                List<Healthcare_Cost__c>  hccPharmacare = [SELECT id,recordtypename__c,case2__c,location_type_code__c,location_type_description2__c,
                                                           cost_include__c,cost_review__c,practitioner_name__c,cost__c,description_of_service2__c,date_of_service__c,
                                                           total_cost_override__c,service_type2__c,phn__c,facilityname__c,location_responded__c,description__c,
                                                           diagnostic_code__c,fee_item_code__c,name_of_drug__c,date_of_admission__c,number_of_days__c,date_of_discharge__c,name 
                                                           FROM Healthcare_Cost__c 
                                                           WHERE (Case2__c = '500Au000006tM2rIAE' AND Cost_Include__c = true AND Cost_Review__c = true 
                                                                  AND RecordTypeName__c = 'Pharmacare') LIMIT 50000];                          
                System.debug('HCC Pharmacare : ' + hccPharmacare.size());
                List<Healthcare_Cost__c> hccContinuingCare = [SELECT id,recordtypename__c,case2__c,location_type_code__c,location_type_description2__c,cost_include__c,
                                                              cost_review__c,practitioner_name__c,cost__c,description_of_service2__c,date_of_service__c,total_cost_override__c,
                                                              service_type2__c,phn__c,facilityname__c,location_responded__c,description__c,diagnostic_code__c,
                                                              fee_item_code__c,name_of_drug__c,date_of_admission__c,number_of_days__c,date_of_discharge__c,name 
                                                              FROM Healthcare_Cost__c 
                                                              WHERE (Case2__c = '500Au000006tM2rIAE' 
                                                                     AND RecordTypeName__c = 'Continuing_Care') LIMIT 50000];
                
                System.debug('HCC Continuing Care : ' + hccContinuingCare.size());
                List<Healthcare_Cost__c> hccFutureCare = [SELECT id,recordtypename__c,case2__c,location_type_code__c,location_type_description2__c,
                                                          cost_include__c,cost_review__c,practitioner_name__c,cost__c,description_of_service2__c,date_of_service__c,
                                                          total_cost_override__c,service_type2__c,phn__c,facilityname__c,location_responded__c,description__c,diagnostic_code__c,
                                                          fee_item_code__c,name_of_drug__c,date_of_admission__c,number_of_days__c,date_of_discharge__c,name 
                                                          FROM Healthcare_Cost__c 
                                                          WHERE (Case2__c = '500Au000006tM2rIAE' 
                                                                 AND RecordTypeName__c = 'Future_Care') LIMIT 50000];
                System.debug('HCC Future Care : ' + hccFutureCare.size());
            }
            catch(Exception e){
                System.debug(e.getMessage());
            }
        }
        Test.stopTest();
    }
    
    @isTest
    static void testDocGenManager(){
        User u = [SELECT Alias, Id, Email, LastName, ProfileId, UserName from User where Email = 'crystal.zhu@cgi.com' and Alias = 'crzh_2' LIMIT 1];
        System.debug(u);
        
        Test.startTest();
        System.runAs(u) {
            try{
                List<Case> caseDetails = [SELECT id,accountid,total_case_value__c,future_care_total2__c,pharmacare_total2__c,continuing_care_total2__c,claim_number__c,
                                          ambulance_total2__c,phn__c,incident_date__c,description,date_of_birth__c,msp_total2__c,casenumber,
                                          hospitalization_total2__c 
                                          FROM Case 
                                          WHERE (Id = '500Au000006tM2rIAE') LIMIT 50000];
                System.debug('Case : '+ caseDetails.size());
                List<Account> accountDetails = [SELECT id,description,name FROM Account WHERE (Id = '001Au00000FtkhoIAB') LIMIT 50000];
                System.debug('Account : ' + accountDetails.size());
                List<Healthcare_Cost__c> hccAmbulance = [SELECT id,recordtypename__c,case2__c,location_type_code__c,location_type_description2__c,
                                                         cost_include__c,cost_review__c,practitioner_name__c,cost__c,description_of_service2__c,
                                                         date_of_service__c,total_cost_override__c,service_type2__c,phn__c,facilityname__c,
                                                         location_responded__c,description__c,diagnostic_code__c,fee_item_code__c,name_of_drug__c,
                                                         date_of_admission__c,number_of_days__c,date_of_discharge__c,name 
                                                         FROM Healthcare_Cost__c 
                                                         WHERE (Case2__c = '500Au000006tM2rIAE' 
                                                                AND Cost_Include__c = true AND Cost_Review__c = true 
                                                                AND RecordTypeName__c = 'Ambulance') LIMIT 500000];
                System.debug('HCC Ambulance : ' + hccAmbulance.size());
                List<Healthcare_Cost__c> hccHospital = [SELECT id,recordtypename__c,case2__c,location_type_code__c,location_type_description2__c,
                                                        cost_include__c,cost_review__c,practitioner_name__c,cost__c,description_of_service2__c,
                                                        date_of_service__c,total_cost_override__c,service_type2__c,phn__c,facilityname__c,location_responded__c,
                                                        description__c,diagnostic_code__c,fee_item_code__c,name_of_drug__c,date_of_admission__c,number_of_days__c,
                                                        date_of_discharge__c,name 
                                                        FROM Healthcare_Cost__c 
                                                        WHERE (Case2__c = '500Au000006tM2rIAE' AND Cost_Include__c = true AND Cost_Review__c = true 
                                                               AND RecordTypeName__c = 'Hospitalization') LIMIT 50000];
                System.debug('HCC Hospital :' + hccHospital.size());
                List<Healthcare_Cost__c> hccMSP = [SELECT id,recordtypename__c,case2__c,location_type_code__c,location_type_description2__c,
                                                   cost_include__c,cost_review__c,practitioner_name__c,cost__c,description_of_service2__c,
                                                   date_of_service__c,total_cost_override__c,service_type2__c,phn__c,facilityname__c,location_responded__c,
                                                   description__c,diagnostic_code__c,fee_item_code__c,name_of_drug__c,date_of_admission__c,number_of_days__c,date_of_discharge__c,name 
                                                   FROM Healthcare_Cost__c 
                                                   WHERE (Case2__c = '500Au000006tM2rIAE' AND Cost_Include__c = true 
                                                          AND Cost_Review__c = true AND RecordTypeName__c = 'MSP') LIMIT 50000];                             
                System.debug('HCC MSP :' + hccMSP.size());
                List<Healthcare_Cost__c>  hccPharmacare = [SELECT id,recordtypename__c,case2__c,location_type_code__c,location_type_description2__c,
                                                           cost_include__c,cost_review__c,practitioner_name__c,cost__c,description_of_service2__c,date_of_service__c,
                                                           total_cost_override__c,service_type2__c,phn__c,facilityname__c,location_responded__c,description__c,
                                                           diagnostic_code__c,fee_item_code__c,name_of_drug__c,date_of_admission__c,number_of_days__c,date_of_discharge__c,name 
                                                           FROM Healthcare_Cost__c 
                                                           WHERE (Case2__c = '500Au000006tM2rIAE' AND Cost_Include__c = true AND Cost_Review__c = true 
                                                                  AND RecordTypeName__c = 'Pharmacare') LIMIT 50000];                          
                System.debug('HCC Pharmacare : ' + hccPharmacare.size());
                List<Healthcare_Cost__c> hccContinuingCare = [SELECT id,recordtypename__c,case2__c,location_type_code__c,location_type_description2__c,cost_include__c,
                                                              cost_review__c,practitioner_name__c,cost__c,description_of_service2__c,date_of_service__c,total_cost_override__c,
                                                              service_type2__c,phn__c,facilityname__c,location_responded__c,description__c,diagnostic_code__c,
                                                              fee_item_code__c,name_of_drug__c,date_of_admission__c,number_of_days__c,date_of_discharge__c,name 
                                                              FROM Healthcare_Cost__c 
                                                              WHERE (Case2__c = '500Au000006tM2rIAE' 
                                                                     AND RecordTypeName__c = 'Continuing_Care') LIMIT 50000];
                
                System.debug('HCC Continuing Care : ' + hccContinuingCare.size());
                List<Healthcare_Cost__c> hccFutureCare = [SELECT id,recordtypename__c,case2__c,location_type_code__c,location_type_description2__c,
                                                          cost_include__c,cost_review__c,practitioner_name__c,cost__c,description_of_service2__c,date_of_service__c,
                                                          total_cost_override__c,service_type2__c,phn__c,facilityname__c,location_responded__c,description__c,diagnostic_code__c,
                                                          fee_item_code__c,name_of_drug__c,date_of_admission__c,number_of_days__c,date_of_discharge__c,name 
                                                          FROM Healthcare_Cost__c 
                                                          WHERE (Case2__c = '500Au000006tM2rIAE' 
                                                                 AND RecordTypeName__c = 'Future_Care') LIMIT 50000];
                System.debug('HCC Future Care : ' + hccFutureCare.size());
            }
            catch(Exception e){
                System.debug(e.getMessage());
            }
        }
        Test.stopTest();
    }
}