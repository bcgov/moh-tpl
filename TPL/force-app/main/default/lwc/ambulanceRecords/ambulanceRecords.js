import { LightningElement, wire, api } from 'lwc';
import getHealthcareCostsAmbulanceForAccount from '@salesforce/apex/HCCCostController.getHealthcareCostsAmbulanceForAccount';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CASE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Case__c';
import COST_INCLUDE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Cost_Include__c';
import COST_REVIEW_FIELD from '@salesforce/schema/Healthcare_Cost__c.Cost_Review__c';
import COST_FIELD from '@salesforce/schema/Healthcare_Cost__c.Cost__c';
import BASIC_AMOUNT_FIELD from '@salesforce/schema/Healthcare_Cost__c.Basic_Amount__c';
import TOTAL_OVERRIDE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Total_Override__c';
import getCountofAmbulanceRecords from '@salesforce/apex/HCCCostController.getCountofAmbulanceRecords';

const COLS = [
    {
        label: 'Case Name',
        fieldName: CASE_FIELD.fieldApiName,
        type: 'lookup',
        editable: true
    },
    {
        label: 'Cost Include',
        fieldName: COST_INCLUDE_FIELD.fieldApiName,
        type:'boolean',
        editable: false
    },
    {
        label: 'Cost Review',
        fieldName: COST_REVIEW_FIELD.fieldApiName,
        type:'boolean',
        editable:false
    },
    {
        label: 'Basic Amount',
        fieldName: BASIC_AMOUNT_FIELD.fieldApiName,
        type: 'currency',
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
     pageNumber = 1;
    totalPage = 0;
    @api recordSize = 5;
    
    @wire(getHealthcareCostsAmbulanceForAccount, { accId: '$recordId' })
    healthcareCostsAmbulanceForAccount;   

    @wire(getCountofAmbulanceRecords,{ accId: '$recordId'})
    countOfAmbulanceRecords;

    handlePageLoad(){
        this.totalRecords = countOfAmbulanceRecords
        this.recordSize = Number(this.recordSize)
        this.totalPage = Math.ceil(this.totalRecords/this.recordSize)

    }

    get disablePrevious(){ 
        return this.currentPage<=1
    }

    get disableNext(){ 
        return this.currentPage>=this.totalPage
    }

    previousHandler(){ 
        if(this.currentPage>1){
            this.currentPage = this.currentPage-1
            this.updateRecords()
        }
    }

    nextHandler(){
        if(this.currentPage < this.totalPage){
            this.currentPage = this.currentPage+1
            this.updateRecords()
        }
    }

    updateRecords(){ 
        const start = (this.currentPage-1)*this.recordSize
        const end = this.recordSize*this.currentPage
        this.visibleRecords = this.totalRecords.slice(start, end)
        this.dispatchEvent(new CustomEvent('update',{ 
            detail:{ 
                records:this.visibleRecords
            }
        }))
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