import { LightningElement, wire, api } from 'lwc';
import getHealthcareCostsAmbulance from '@salesforce/apex/HCCCostController.getHealthcareCostsAmbulance';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import PHN_FIELD from '@salesforce/schema/Healthcare_Cost__c.PHN__c';
import ACCOUNT_NAME_FIELD from '@salesforce/schema/Healthcare_Cost__c.Account__c';
import RECORD_TYPE_FIELD from '@salesforce/schema/Healthcare_Cost__c.RecordTypeName__c';
import CASE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Case__c';
import COST_INCLUDE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Cost_Include__c';
import COST_REVIEW_FIELD from '@salesforce/schema/Healthcare_Cost__c.Cost_Review__c';
import COST_FIELD from '@salesforce/schema/Healthcare_Cost__c.Cost__c';
import BASIC_AMOUNT_FIELD from '@salesforce/schema/Healthcare_Cost__c.Basic_Amount__c';
import TOTAL_OVERRIDE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Total_Override__c'

const COLS = [
    {
        label: 'PHN',
        fieldName: PHN_FIELD.fieldApiName,
        editable: false
    },
    {
        label: 'Record Type',
        fieldName: RECORD_TYPE_FIELD.fieldApiName,
        editable: false
    },
    {
        label: 'Account Name',
        fieldName: ACCOUNT_NAME_FIELD.fieldApiName,
        editable: true
    },
    {
        label: 'Case Name',
        fieldName: CASE_FIELD.fieldApiName,
        editable: true
    },
    {
        label: 'Cost Include',
        fieldName: COST_INCLUDE_FIELD.fieldApiName,
        editable: true
    },
    {
        label: 'Cost Review',
        fieldName: COST_REVIEW_FIELD.fieldApiName,
        editable:true
    },
    {
        label: 'Basic Amount',
        fieldName: BASIC_AMOUNT_FIELD.fieldApiName,
        editable: true
    },
    {
        label: 'Cost',
        fieldName: COST_FIELD.fieldApiName,
        editable: true
    },
    {
        label: 'Total Override',
        fieldName: TOTAL_OVERRIDE_FIELD.fieldApiName,
        editable: true
    }
];

export default class AmbulanceRecords extends LightningElement {
    @api recordId;
    column = COLS;
    isFirstPage = true;
    isLastPage = false;
    totalRecords = 0;
    pageNumber = 1;
    totalPages = 0;

    @wire(getHealthcareCostsAmbulance, { accId: '$recordId' })
    healthcareCostsAmbulance;

     // Count Options
    get countOptions() {
    return [
        { label: '10', value: '10' },
        { label: '50', value: '50' },
        { label: '75', value: '75' },
        { label: '100', value: '100' },
    ];
    }

    handlePageLoad(){

    }
    
    updatePageButtons() {
        console.log('PageNumber:', this.pageNumber, 'total', this.totalPages);
        if (this.pageNumber === 1) {
          this.isFirstPage = true;
        } else {
          this.isFirstPage = false;
        }
        if (this.pageNumber >= this.totalPages) {
          this.isLastPage = true;
        } else {
          this.isLastPage = false;
        }
      }
    
    fetchAmbulanceRecords(){
        
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