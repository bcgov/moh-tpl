import { LightningElement, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import COST_INCLUDE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Cost_Include__c';
import COST_REVIEW_FIELD from '@salesforce/schema/Healthcare_Cost__c.Cost_Review__c';
import DATE_OF_SERVICE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Date_of_Service__c';
import TOTAL_COST_OVERRIDE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Total_Cost_Override__c';
import FACILITY_NAME_FIELD from '@salesforce/schema/Healthcare_Cost__c.FacilityName__c';
import FACILITY_TYPE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Facility_Type__c';
import DESCRIPTION_OF_SERVICE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Description_of_Service__c'
import FEE_ITEM_CODE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Fee_Item_Code__c';
import FEE_ITEM_TITLE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Fee_Item_Title__c';
import FEE_ITEM_DESCRIPTION_FIELD from '@salesforce/schema/Healthcare_Cost__c.Fee_Item_Description__c';
import PRACTITIONER_NUMBER_FIELD from '@salesforce/schema/Healthcare_Cost__c.Practitioner_Number__c';
import PRACTITIONER_NAME_FIELD from '@salesforce/schema/Healthcare_Cost__c.Practitioner_Name__c';
import DIAGNOSTIC_CODE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Diagnostic_Code__c';
import DIAGNOSTIC_DESCRIPTION_FIELD from '@salesforce/schema/Healthcare_Cost__c.Diagnostic_Description__c';
import AMOUNT_PAID_FIELD from '@salesforce/schema/Healthcare_Cost__c.Amount_Paid__c';
import SPECIALITY_CODE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Specialty_Code__c';
import SPECIALITY_DESCRIPTION_FIELD from '@salesforce/schema/Healthcare_Cost__c.Specialty_Description__c';
import PAYEE_NUMBER_FIELD from '@salesforce/schema/Healthcare_Cost__c.Payee_Number__c';
import PAYEE_DESCRIPTION_FIELD from '@salesforce/schema/Healthcare_Cost__c.Payee_Description__c';
import SERVICE_START_DATE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Service_Start_Date__c';
import SERVICE_FINISH_DATE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Service_Finish_Date__c'
import LOCATION_TYPE_CODE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Location_Type_Code__c';
import LOCATION_TYPE_DESCRIPTION_FIELD from '@salesforce/schema/Healthcare_Cost__c.Location_Type_Description__c';
import getHealthcareCostsMSPForCase from '@salesforce/apex/HCCCostMSPRecord.getHealthcareCostsMSPForCase';
import saveDraftValues from '@salesforce/apex/HCCCostController.saveDraftValues';

const COLUMNS = 
[
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
        editable: true,
        sortable: true
    },
    {
        label: 'Facility',
        fieldName: FACILITY_NAME_FIELD.fieldApiName,
        type: 'text',
        editable: false,
        sortable: false
    },
    {
        label: 'Facility Type',
        fieldName: FACILITY_TYPE_FIELD.fieldApiName,
        type: 'text',
        editable: true,
        sortable: false
    },
    {
        label: 'Descripiton of Service',
        fieldName: DESCRIPTION_OF_SERVICE_FIELD.fieldApiName,
        type: 'text',
        editable: true,
        sortable: false
    },
    {
        label: 'Fee Item Code',
        fieldName: FEE_ITEM_CODE_FIELD.fieldApiName,
        type: 'text',
        editable: true,
        sortable: true
    },
    {
        label: 'Fee Item Title',
        fieldName: FEE_ITEM_TITLE_FIELD.fieldApiName,
        type: 'text',
        editable: true,
        sortable: true
    },
    {
        label: 'Fee Item Description',
        fieldName: FEE_ITEM_DESCRIPTION_FIELD.fieldApiName,
        type: 'text',
        editable: true,
        sortable: true
    },
    {
        label: 'Practitioner Number',
        fieldName: PRACTITIONER_NUMBER_FIELD.fieldApiName,
        type: 'false',
        editable: true,
        sortable: true
    },
    {
        label: 'Practitioner Name',
        fieldName: PRACTITIONER_NAME_FIELD.fieldApiName,
        type: 'text',
        editable: true,
        sortable: true
    },
    {
        label: 'Diagnostic Code',
        fieldName: DIAGNOSTIC_CODE_FIELD.fieldApiName,
        type: 'text',
        editable: true,
        sortable: true
    },
    {
        label: 'Diagnostic Description',
        fieldName: DIAGNOSTIC_DESCRIPTION_FIELD.fieldApiName,
        type: 'text',
        editable: true,
        sortable: false
    },
    {
        label: 'Amount Paid',
        fieldName: AMOUNT_PAID_FIELD.fieldApiName,
        type: 'text',
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
        label: 'Speciality Code',
        fieldName: SPECIALITY_CODE_FIELD.fieldApiName,
        type: 'text',
        editable: true,
        sortable: true
    },
    {
        label: 'Speciality Description',
        fieldName: SPECIALITY_DESCRIPTION_FIELD.fieldApiName,
        type: 'text',
        editable: true,
        sortable: false
    },
    {
        label: 'Payee Number',
        fieldName: PAYEE_NUMBER_FIELD.fieldApiName,
        type: 'text',
        editable: true,
        sortable: true
    },
    {
        label: 'Payee Descripiton',
        fieldName: PAYEE_DESCRIPTION_FIELD.fieldApiName,
        type: 'text',
        editable: true,
        sortable: true
    },
    {
        label: 'Service Start Date',
        fieldName: SERVICE_START_DATE_FIELD.fieldApiName,
        editable: true,
        sortable: true
    },
    {
        label: 'Service Finish Date',
        fieldName: SERVICE_FINISH_DATE_FIELD.fieldApiName,
        editable: true,
        sortable: true
    },
    {
        label: 'Location Type Code',
        fieldName: LOCATION_TYPE_CODE_FIELD.fieldApiName,
        type: 'text',
        editable: true,
        sortable: true
    },
    {
        label: 'Location Type Description',
        fieldName: LOCATION_TYPE_DESCRIPTION_FIELD.fieldApiName,
        type: 'text',
        editable: true,
        sortable: false
    }
];

export default class MspRecordsCase extends LightningElement {
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

      @wire (getHealthcareCostsMSPForCase, { caseId: '$recordId' })
      healthcareCostsMSPForCase(result){
        this.wiredRecords = result;
        const {data, error} = result;

        if(data != null && data){
            console.log('Data of MSP Records --> ' + JSON.stringify(data));
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
                        message: 'HealthCare Cost MSP record(s) updated successfully',
                        variant: 'success'
                    })
                );    
            
               }
                else if(result == 'Failed'){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Record not saved successfully! Please check Healthcare Cost MSP record(s) while updating',
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