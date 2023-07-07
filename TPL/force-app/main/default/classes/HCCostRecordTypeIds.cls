/*
* Company: CGI for BC Ministry of Health
* Date: April 12, 2023
* Author: Anudish Jinturkar
* Description: public with sharing class HCCostRecordTypeIds that is implemented to return the respective record type Id's based on the Record Type Name of Healthcare Cost object
*    Methods:
*         getAmbulanceRecordId: This method returns the ID of Ambulance record type of Healthcare Cost object
*         getContinuingCareRecordId: This method returns the ID of Continuing Care record type of Healthcare Cost object
*         getFutureCareRecordId: This method returns the ID of Future Care record type of Healthcare Cost object
*         getHospitalRecordId:  This method returns the ID of Hospitalization record type of Healthcare Cost object
*         getMSPRecordId: This method returns the ID of MSP record type of Healthcare Cost object
*         getPharmacareRecordId: This method returns the ID of Pharmacare record type of Healthcare Cost object

* History:
*     Initial version: April 12, 2023 - AJ
*/
public with sharing class HCCostRecordTypeIds {
    
    /*
* Description: Method returns the ID of Ambulance record type of Healthcare Cost object
* Returns:
*     ID: Returns the ID of Ambulance record type of Healthcare Cost object
* 
*/
    public static Id getAmbulanceRecordId(){
        return Schema.SObjectType.Healthcare_Cost__c.getRecordTypeInfosByName().get('Ambulance').getRecordTypeId();
    }
    
    /*
* Description: Method returns the ID of Continuing Care record type of Healthcare Cost object
* Returns:
*     ID: Returns the ID of Continuing Care record type of Healthcare Cost object
* 
*/
    public static Id getContinuingCareRecordId(){
        return Schema.SObjectType.Healthcare_Cost__c.getRecordTypeInfosByName().get('Continuing Care').getRecordTypeId();
    }
    
    /*
* Description: Method returns the ID of Future Care record type of Healthcare Cost object
* Returns:
*     ID: Returns the ID of Future Care record type of Healthcare Cost object
* 
*/
    public static Id getFutureCareRecordId(){
        return Schema.SObjectType.Healthcare_Cost__c.getRecordTypeInfosByName().get('Future Care').getRecordTypeId(); 
    }
    
    /*
* Description: Method returns the ID of Hospitalization record type of Healthcare Cost object
* Returns:
*     ID: Returns the ID of Hospitalization record type of Healthcare Cost object
* 
*/
    public static Id getHospitalRecordId(){
        return Schema.SObjectType.Healthcare_Cost__c.getRecordTypeInfosByName().get('Hospitalization').getRecordTypeId();
    }
    
    /*
* Description: Method returns the ID of MSP record type of Healthcare Cost object
* Returns:
*     ID: Returns the ID of MSP record type of Healthcare Cost object
* 
*/
    public static Id getMSPRecordId(){
        return Schema.SObjectType.Healthcare_Cost__c.getRecordTypeInfosByName().get('MSP').getRecordTypeId();
    }
    
    /*
* Description: Method returns the ID of Pharmacare record type of Healthcare Cost object
* Returns:
*     ID: Returns the ID of Pharmacare record type of Healthcare Cost object
* 
*/
    public static Id getPharmacareRecordId(){
        return Schema.SObjectType.Healthcare_Cost__c.getRecordTypeInfosByName().get('Pharmacare').getRecordTypeId();
    }
}