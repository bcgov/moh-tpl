import { LightningElement, wire, api } from 'lwc';
import getHealthcareCostsAmbulanceForAccount from '@salesforce/apex/HCCCostController.getHealthcareCostsAmbulanceForAccount';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import COST_INCLUDE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Cost_Include__c';
import COST_REVIEW_FIELD from '@salesforce/schema/Healthcare_Cost__c.Cost_Review__c';
import COST_FIELD from '@salesforce/schema/Healthcare_Cost__c.Cost__c';
import CASE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Case2__c';
import CASE_NUMBER_FIELD from '@salesforce/schema/Healthcare_Cost__c.Case_Number__c';
import BASIC_AMOUNT_FIELD from '@salesforce/schema/Healthcare_Cost__c.Basic_Amount__c';
import TOTAL_COST_OVERRIDE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Total_Cost_Override__c';
import DATE_OF_SERVICE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Date_of_Service__c';
import LOCATION_RESPONDED_FIELD from '@salesforce/schema/Healthcare_Cost__c.Location_Responded__c';
import updateHCCCaseInformation from '@salesforce/apex/HCCCostController.updateHCCCaseInformation';
import getCaseListIndividual from '@salesforce/apex/HCCCostController.getCaseListIndividual';
import { refreshApex } from '@salesforce/apex';

const COLS = [
    {
        label: 'HealthCare Cost Number',
        fieldName: 'linkName',
        type: 'url',
        sortable: true,
        typeAttributes: {
            label: { fieldName: 'Name' },
            target: '_self'
        }
    },
    {
        label: 'Case Number',
        fieldName: CASE_NUMBER_FIELD.fieldApiName,
        type: 'text',
        sortable: true,
        editable: false,
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
        label: 'Date of Service',
        fieldName: DATE_OF_SERVICE_FIELD.fieldApiName,
        type: 'date',
        editable: false,
        sortable: true
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
        label: 'Total Cost Override',
        fieldName: TOTAL_COST_OVERRIDE_FIELD.fieldApiName,
        type: 'currency',
        editable: false
    }
];

export default class AmbulanceRecordsAccount extends LightningElement {
    @api recordId;
    column = COLS;
    isFirstPage = true;
    isLastPage = false;
    totalRecords = 0; //Total no.of records
    totalPages; //Total no.of pages
    pageNumber = 1; //Page number
    pageSizeOptions = [5, 10, 25, 50, 75, 100, 150, 200]; //Page size options
    records = []; //All records available in the data table
    pageSize; //No.of records to be displayed per page
    recordsToDisplay = []; //Records to be displayed on the page
    wiredRecords;
    selectedCase;

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

    handleCaseSelection(event){
        this.selectedCase = event.target.value;  
     }
     
     async handleSelect(){
     var el = this.template.querySelector('lightning-datatable');
        console.log(el);
        var selected = el.getSelectedRows();
        //console.log(selected);
        console.log('selectedRows : ' + selected);
        console.log('Selected Case ID : ' + this.selectedCase);
        
        let selectedCostIds = [];
        
        selected.forEach(function(element){
        selectedCostIds.push(element.Id);
           console.log(element.Id);   
        });

        await updateHCCCaseInformation({ caseId: this.selectedCase, hccIds: selectedCostIds})
        .then(() => {
            if(this.selectedCase == null){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please select Case and HCC Records to map',
                        variant: 'error'
                    })
                );
            }
            else{
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'HealthCare Cost Ambulance record(s) updated successfully',
                        variant: 'success'
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
    async refresh(){
        await refreshApex(this.wiredRecords);
    }

    @wire(getHealthcareCostsAmbulanceForAccount, { accId: '$recordId' })
    wiredHealthcareCostsAmbulanceForAccount(result){
        this.wiredRecords = result;
        const {data, error} = result;
        
        if(data != null && data){
            console.log('Data of Ambulance Records --> ' + JSON.stringify(data));
            this.records = JSON.parse(JSON.stringify(data));
            this.records.forEach(record => {
                record.linkName = '/' + record.Id;
            })
            this.totalRecords = data.length;
            this.pageSize = this.pageSizeOptions[0]; 
            this.paginationHelper(); // call helper menthod to update pagination logic
            this.error = undefined;
        }
        else if (error) {
            this.records = undefined;
            this.error = error;
        } else {
            this.error = undefined;
            this.records = undefined;
        }
    }

    @wire (getCaseListIndividual,{accId: '$recordId'})
    wiredCaseListIndividual(result){
        const {data, error} = result; 
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

}