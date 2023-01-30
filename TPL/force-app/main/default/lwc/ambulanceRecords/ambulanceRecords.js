import { LightningElement, wire, api } from 'lwc';
import getHealthcareCostsAmbulanceForAccount from '@salesforce/apex/HCCCostController.getHealthcareCostsAmbulanceForAccount';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CASE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Case__c';
import ACCOUNT_FIELD from '@salesforce/schema/Healthcare_Cost__c.Account__c';
import COST_INCLUDE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Cost_Include__c';
import COST_REVIEW_FIELD from '@salesforce/schema/Healthcare_Cost__c.Cost_Review__c';
import COST_FIELD from '@salesforce/schema/Healthcare_Cost__c.Cost__c';
import BASIC_AMOUNT_FIELD from '@salesforce/schema/Healthcare_Cost__c.Basic_Amount__c';
import TOTAL_OVERRIDE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Total_Override__c';
import DATE_OF_SERVICE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Date_of_Service__c';
import LOCATION_RESPONDED_FIELD from '@salesforce/schema/Healthcare_Cost__c.Location_Responded__c';
import relatedCaseRecords from '@salesforce/apex/HCCCostController.caseListIndividual';
import relatedAccountRecords from '@salesforce/apex/HCCCostController.listOfIndividualAccounts';
import CaseNumber from '@salesforce/schema/Case.CaseNumber';
const COLS = [
    
    {
        label: 'HealthCare Cost Number',
        fieldName: 'linkName',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'Name' },
            target: '_self'
        }
    },
    {
        label: 'Case Number',
        fieldName: CASE_FIELD.fieldApiName,
        type: 'lookup',
        typeAttributes: {
            placeholder: 'Choose Case',
            object: 'Healthcare_Cost__c',
            fieldName: CASE_FIELD.fieldApiName,
            label: 'CaseNumber',
            value: { fieldName: CASE_FIELD.fieldApiName},
            context:{fieldName: 'Id'},
            variant: 'label-hidden',
            name: 'Case',
            fields: ['Case.CaseNumber'],
            target: '_self'
        },
        editable: true,
        cellAttributes:{
            class: { fieldName: 'CaseNumberClass'}
        }
    },
    {
        label: 'Cost Include',
        fieldName: COST_INCLUDE_FIELD.fieldApiName,
        type:'boolean',
        editable: true
    },
    {
        label: 'Cost Review',
        fieldName: COST_REVIEW_FIELD.fieldApiName,
        type:'boolean',
        editable:true
    },
    {
        label: 'Date of Service',
        fieldName: DATE_OF_SERVICE_FIELD.fieldApiName,
        type: 'date',
        editable: false
    },
    {
        label: 'Basic Amount',
        fieldName: BASIC_AMOUNT_FIELD.fieldApiName,
        type: 'currency',
        editable: false
    },
    {
        label: 'Location Responded',
        fieldName: LOCATION_RESPONDED_FIELD.fieldApiName,
        type: 'text',
        editable: false
    },
    {
        label: 'Cost',
        fieldName: COST_FIELD.fieldApiName,
        type: 'currency',
        editable: false
    },
    {
        label: 'Total Override',
        fieldName: TOTAL_OVERRIDE_FIELD.fieldApiName,
        type: 'currency',
        editable: false
    }
];

export default class AmbulanceRecords extends LightningElement {
    @api recordId;
    column = COLS;
    isFirstPage = true;
    isLastPage = false;
    totalRecords = 0; //Total no.of records
    totalPages; //Total no.of pages
    pageNumber = 1; //Page number
    pageSizeOptions = [5, 10, 25, 50, 75, 100, 150, 200, 500]; //Page size options
    records = []; //All records available in the data table
    pageSize; //No.of records to be displayed per page
    recordsToDisplay = []; //Records to be displayed on the page

    @wire(getHealthcareCostsAmbulanceForAccount, { accId: '$recordId' })
    healthcareCostsAmbulanceForAccount({error,data}){
        if(data != null && data){
            console.log('Data of Ambulance Records --> ' + JSON.stringify(data));
            this.records = JSON.parse(JSON.stringify(data));
            this.records.forEach(record => {
                record.linkName = '/' + record.Id;
                record.CaseNumberClass = 'slds-cell-edit';
            })
            this.totalRecords = data.length;
            this.pageSize = this.pageSizeOptions[0]; 
            this.paginationHelper(); // call helper menthod to update pagination logic
            this.error = undefined;
        }
        else if(error){
            this.records = undefined;
            this.error = error;
            console.error(error);
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
    
    async handleSave(event){
        
        // Convert datatable draft values into record objects
        const records = event.detail.draftValues.slice().map((draftValue) => {
            const fields = Object.assign({}, draftValue);
            return { fields };
        });

        // Clear all datatable draft values
        this.draftValues = [];

        try {
            // Update all records in parallel thanks to the UI API
            const recordUpdatePromises = records.map((record) =>
                updateRecord(record)
            );
            await Promise.all(recordUpdatePromises);

            // Report success with a toast
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Healthcare Costs Ambulance updated',
                    variant: 'success'
                })
            );

            // Display fresh data in the datatable
            await refreshApex(this.healthcareCostsAmbulance);
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error updating or reloading Healthcare Costs',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        }
    }
}