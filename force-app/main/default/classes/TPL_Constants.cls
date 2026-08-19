/**
* Author: Nikhil Jeenru
* Company: CGI
* Purpose:
* This class stores shared constants used across the org.
*/
public with sharing class TPL_Constants {
    
    public static final String STATUS_PROCESSING = 'Processing';
    public static final String STATUS_COMPLETED = 'Completed';
    public static final String STATUS_COMPLETED_WITH_ERRORS = 'Completed With Errors';
    public static final String STATUS_FAILED = 'Failed';
    public static final Integer MAX_ATTEMPTS = 3;
    public static final String TIMEOUT_ERROR_MESSAGE = 'Read timed out';
    public static final String TIMEOUT_FIELD_NAME = 'Time_Out_Value_MilliSeconds__c';
    public static final Integer DEFAULT_TIMEOUT_VALUE = 120000;

    public static final String CLASS_DOCX_GENERATOR_CONTROLLER = 'DocxGeneratorController';
    public static final String METHOD_GENERATE_DOCUMENT = 'generateDocument';
    public static final String TPL_DOCGEN_SIGNATURE_PROFILE_NAME = 'TPL DocGen Signature (Profile)';
    public static final String DOCGEN_TEMPLATE_MINISTERS_CERTIFICATE = 'Minister\'s Certificate';
    public static final String DOCGEN_TEMPLATE_CASE_HISTORY = 'Case History';
    public static final String DOCGEN_FILE_PREFIX_MINISTERS_CERTIFICATE = 'Minister\'s Certificate';
    public static final String DOCGEN_FILE_PREFIX_CASE_HISTORY = 'Case_History_';
    public static final String OUTPUT_FORMAT_PDF = 'pdf';
    public static final String OUTPUT_FORMAT_DOCX = 'docx';
    public static final String ASYNC_JOB_STATUS_FAILED = 'Failed';
    public static final String ASYNC_JOB_STATUS_ABORTED = 'Aborted';
    public static final String HCC_AMB_RECORDTYPE_NAME = 'Ambulance';
    public static final String HCC_CC_RECORDTYPE_NAME = 'Continuing_Care';
    public static final String HCC_FC_RECORDTYPE_NAME = 'Future_Care';
    
    public static final String CLASS_HEALTH_IDEAS_API_INTEGRATION = 'HealthIdeasApiIntegration';
    public static final String CLASS_LOG_SERVICE = 'LogService';
    
    public static final String METHOD_ASYNC_HEALTHCARE_COST_REFRESH = 'Async Healthcare Cost Refresh';
    public static final String METHOD_APPEND_HEALTHCARE_COST_INSERT_MESSAGES = 'appendHealthcareCostInsertMessages';
    
    public static final String ERROR_HEALTHCARE_COST_INSERT_FAILED = 'Healthcare_Cost__c insert failed. Status Code: ';
    public static final String ERROR_FAILED_TO_INSERT_LOG = 'Failed to insert Log__c: ';
    public static final String ERROR_FAILED_TO_INSERT_LOG_RECORDS = 'Failed to insert Log__c records: ';
    public static final String ERROR_FIELDS = ' Fields: ';
    public static final String ERROR_MESSAGE_PREFIX = '. Message: ';
    public static final String ERROR_NO_ACCOUNT_FOUND_HEALTH_IDEAS ='No Account found for HealthIdeas callout.';
    public static final String ERROR_HEALTH_IDEAS_API_CALLOUT_FAILED = 'HealthIdeas API Call failed: ';
    
    public static final String HCC_HOSP_RECORDTYPE_NAME = 'Hospitalization';
    public static final String HCC_PHARMA_RECORDTYPE_NAME = 'Pharmacare';
    public static final String HCC_MSP_RECORDTYPE_NAME = 'MSP';
    public static final String RESPONSE_HOSPITALIZATIONS = 'hospitalizations';
    public static final String HI_API_FAILURE_MESSAGE = 'HealthIdeas API Call failed: ';
    
    public static final String SERVICE_TYPE_DAY_SURGERY = 'Day Surgery';
    public static final String SERVICE_TYPE_ACUTE_CARE = 'Acute Care';
    public static final String SERVICE_TYPE_SURGICAL_DAY_CARE = 'Surgical Day Care';
    public static final String SERVICE_TYPE_ACUTE = 'Acute';
    public static final String ASYNC_STATUS_NOT_STARTED = 'Not Started';
    public static final String ASYNC_STATUS_STARTING = 'Starting';
    
    public static final String ERROR_DELETE_FAILED_HEALTHCARE_COST = 'Delete failed for Healthcare_Cost__c Id ';
    public static final String HI_BATCH_CONFIGURATION_RECORD_NAME = 'BatchSize';
    public static final String TPL_HI_RECORDS_FOR_SUFFIX = ' records for ';
}