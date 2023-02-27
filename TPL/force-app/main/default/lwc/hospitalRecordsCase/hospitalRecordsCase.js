import { LightningElement, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import COST_INCLUDE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Cost_Include__c';
import COST_REVIEW_FIELD from '@salesforce/schema/Healthcare_Cost__c.Cost_Review__c';
import DATE_OF_SERVICE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Date_of_Service__c';
import LOCATION_OF_INCIDENT_FIELD from '@salesforce/schema/Healthcare_Cost__c.Location_of_Incident__c';
import DESCRIPTION_OF_INCIDENT_FIELD from '@salesforce/schema/Healthcare_Cost__c.Description_of_Incident__c';
import INTERVENTION_CODE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Intervention_Code_CCI__c';
import CCI_LEVEL_FIELD from '@salesforce/schema/Healthcare_Cost__c.CCI_Level__c';
import NAME_FIELD from '@salesforce/schema/Healthcare_Cost__c.Name';
import CASE_NUMBER_FIELD from '@salesforce/schema/Healthcare_Cost__c.Case_Number__c';
import SITE_CODE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Site_Code__c';
import FACILITY_NAME_FIELD from '@salesforce/schema/Healthcare_Cost__c.FacilityName__c';
import DATE_OF_ADMISSION_FIELD from '@salesforce/schema/Healthcare_Cost__c.Date_of_Admission__c';
import DATE_OF_DISCHARGE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Date_of_Discharge__c';
import NUMBER_OF_DAYS_FIELD from '@salesforce/schema/Healthcare_Cost__c.Number_of_Days__c';
import SERVICE_PROVIDER_FIELD from '@salesforce/schema/Healthcare_Cost__c.Service_Provider_Facility__c';
import SERVICE_TYPE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Service_Type2__c';
import STANDARD_DAILY_RATE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Standard_Daily_Rate__c';
import TOTAL_COST_STADARD_FIELD from '@salesforce/schema/Healthcare_Cost__c.Total_Costs_Standard__c';
import TOTAL_COST_OVERRIDE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Total_Cost_Override__c';
import DIAGNOSTIC_TREATMENT_SERVICE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Diagnostic_Treatment_Service__c'
import getHealthcareCostsHospitalForCase from '@salesforce/apex/HCCCostHospitalizationRecord.getHealthcareCostsHospitalForCase';
import saveDraftValues from '@salesforce/apex/HCCCostController.saveDraftValues'; 

const COLUMNS = [
    {
        label: 'Cost Include',
        fieldName: COST_INCLUDE_FIELD.fieldApiName,
        type:'boolean',
        editable: true,
        sortable: true
    },
    {
        label: 'Cost Review',
        fieldName: COST_REVIEW_FIELD.fieldApiName,
        type:'boolean',
        editable:true,
        sortable: true
    },
    {
        label: 'Date of Service',
        fieldName: DATE_OF_SERVICE_FIELD.fieldApiName,
        type: 'date',
        typeAttributes:{year: "numeric",month: "2-digit",day: "2-digit"},
        editable: true,
        sortable: true
    },
    {
        label: 'Location of Incident',
        fieldName: LOCATION_OF_INCIDENT_FIELD.fieldApiName,
        type: 'text',
        editable: true,
        sortable: true
    },
    {
        label: 'Description of Incident',
        fieldName: DESCRIPTION_OF_INCIDENT_FIELD.fieldApiName,
        type: 'text',
        editable: true,
        sortable: true,
    },
    {
        label: 'Intervention Code (CCI)',
        fieldName: INTERVENTION_CODE_FIELD.fieldApiName,
        type: 'text',
        editable: true,
        sortable: true,
    },
    {
        label: 'CCI Level',
        fieldName: CCI_LEVEL_FIELD.fieldApiName,
        type: 'text',
        editable: true,
        sortable: true,
    },
    {
        label: 'Site Code',
        fieldName: SITE_CODE_FIELD.fieldApiName,
        type: 'text',
        editable: false,
        sortable: false
    },
    {
        label: 'Facility',
        fieldName: FACILITY_NAME_FIELD.fieldApiName,
        type: 'text',
        editable: false,
        sortable: false
    },
    {
        label: 'Date of Admission',
        fieldName:DATE_OF_ADMISSION_FIELD.fieldApiName,
        type: 'date',
        typeAttributes:{year: "numeric",month: "2-digit",day: "2-digit"},
        editable: true,
        sortable: true
    },
    {
        label: 'Date of Discharge',
        fieldName:DATE_OF_DISCHARGE_FIELD.fieldApiName,
        type: 'date',
        typeAttributes:{year: "numeric",month: "2-digit",day: "2-digit"},
        editable: true,
        sortable: true
    },
    {
        label: 'Number of Days',
        fieldName: NUMBER_OF_DAYS_FIELD.fieldApiName,
        editable: true,
        sortable: true
    },
    {
        label: ' Service Provided by Facility',
        fieldName: SERVICE_PROVIDER_FIELD.fieldApiName,
        editable: false,
        sortable: true
    },
    {
    
        label: 'Service Type',
        fieldName: SERVICE_TYPE_FIELD.fieldApiName,
        editable: false,
        sortable: true
    },
    {
        label: 'Standard Daily Rate',
        type: 'currency',
        fieldName: STANDARD_DAILY_RATE_FIELD.fieldApiName,
        editable: true,
        sortable: true
    },
    {
        label: 'Total Cost Standard',
        fieldName: TOTAL_COST_STADARD_FIELD.fieldApiName,
        type: 'currency',
        editable: true,
        sortable: true
    },
    {
        label: 'Total Cost Override',
        fieldName: TOTAL_COST_OVERRIDE_FIELD.fieldApiName,
        type: 'currency',
        editable: true,
        sortable: true
    },
    {
        label: 'Diagnostic Treatment Service',
        fieldName : DIAGNOSTIC_TREATMENT_SERVICE_FIELD.fieldApiName,
        type: 'text',
        editable: true,
        sortable: true
    }
];

export default class HospitalRecordsCase extends LightningElement {
    @api recordId;
    column = COLUMNS;
    records = []; //All records available in the data table
    isFirstPage = true;
    isLastPage = false;
    totalRecords = 0; //Total no.of records
    totalPages; //Total no.of pages
    pageNumber = 1; //Page number
    pageSizeOptions = [5, 10, 25, 50, 75, 100]; //Page size options
    pageSize; //No.of records to be displayed per page
    recordsToDisplay = []; //Records to be displayed on the page
    wiredRecords;
    selectedRows = [];
    event2;

    connectedCallback() {
        this.event2 = setInterval(() => {
            this.refresh();
        }, 100);
      }
    
      disconnectedCallback() {
        clearInterval(this.event2);
      }

      @wire (getHealthcareCostsHospitalForCase, { caseId: '$recordId' })
      healthcareCostsHospitalForCase(result){
        this.wiredRecords = result;
        const {data, error} = result;

        if(data != null && data){
            console.log('Data of Hospitalization Records --> ' + JSON.stringify(data));
            this.records = data;
            this.totalRecords = data.length;
            this.pageSize = this.pageSizeOptions[0]; 
            this.paginationHelper(); // call helper menthod to update pagination logic
        }
        else if(error){
            console.error(error);
        }
        else if (error) {
            this.records = undefined;
            this.error = error;
        } else {
            this.error = undefined;
            this.records = undefined;
        }
      }

      get bDisableFirst() {
        return this.pageNumber == 1;
    }
    get bDisableLast() {
        return this.pageNumber == this.totalPages;
    }
    
    handleRecordsPerPage(event) {
        this.pageSize = event.target.value;
        this.paginationHelper();
    }
    previousPage() {
        this.pageNumber = this.pageNumber - 1;
        this.paginationHelper();
    }
    nextPage() {
        this.pageNumber = this.pageNumber + 1;
        this.paginationHelper();
    }
    firstPage() {
        this.pageNumber = 1;
        this.paginationHelper();
    }
    lastPage() {
        this.pageNumber = this.totalPages;
        this.paginationHelper();
    }

        // JS function to handel pagination logic 
    paginationHelper() {
        this.recordsToDisplay = [];
        // calculate total pages
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
        // set page number 
        if (this.pageNumber <= 1) {
            this.pageNumber = 1;
        } else if (this.pageNumber >= this.totalPages) {
            this.pageNumber = this.totalPages;
        }
        // set records to display on current page 
        for (let i = (this.pageNumber - 1) * this.pageSize; i < this.pageNumber * this.pageSize; i++) {
            if (i === this.totalRecords) {
                break;
            }
            this.recordsToDisplay.push(this.records[i]);
        }
    }

    doSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }

    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.recordsToDisplay));
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1: -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        this.recordsToDisplay = parseData;
    }    

    
    async refresh(){
        await refreshApex(this.wiredRecords);
    }

    async handleSave(event){
        await saveDraftValues({data: event.detail.draftValues})
        .then((result) => {
        // Clear all datatable draft values
            this.draftValues = [];
                console.log('Result : ' + result);
               if(result == 'Passed'){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'HealthCare Cost Hospitalization record(s) updated successfully',
                        variant: 'success'
                    })
                );    
            
               }
                else if(result == 'Failed'){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Record not saved successfully! Please check Healthcare Cost Hospitalization record(s) while updating',
                            variant: 'error'
                        })
                    );   
                 
                }    
               
                //Get the updated list with refreshApex.
                return this.refresh();    
            })
            .catch(error => {
                console.log('error : ' + JSON.stringify(error));
            });
        
    }
}