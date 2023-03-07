import { LightningElement, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import updateHCCCaseInformation from '@salesforce/apex/HCCCostAmbulanceRecord.updateHCCCaseInformation';
import getHealthcareCostsAmbulanceForAccount from '@salesforce/apex/HCCCostAmbulanceRecord.getHealthcareCostsAmbulanceForAccount';
import getAmbulanceCountonAccount from '@salesforce/apex/HCCCostAmbulanceRecord.getAmbulanceCountonAccount';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import COST_INCLUDE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Cost_Include__c';
import COST_REVIEW_FIELD from '@salesforce/schema/Healthcare_Cost__c.Cost_Review__c';
import CASE_NUMBER_FIELD from '@salesforce/schema/Healthcare_Cost__c.Case_Number__c';
import BASIC_AMOUNT_FIELD from '@salesforce/schema/Healthcare_Cost__c.Basic_Amount__c';
import TOTAL_COST_OVERRIDE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Total_Cost_Override__c';
import DATE_OF_SERVICE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Date_of_Service__c';
import LOCATION_RESPONDED_FIELD from '@salesforce/schema/Healthcare_Cost__c.Location_Responded__c';
import SITE_CODE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Site_Code__c';
import FACILITY_NAME_FIELD from '@salesforce/schema/Healthcare_Cost__c.FacilityName__c';
import FIXED_WING_HELICOPTER_FIELD from '@salesforce/schema/Healthcare_Cost__c.Fixed_Wing_Helicopter__c';
import COST_FIELD from '@salesforce/schema/Healthcare_Cost__c.Cost__c';
import SUB_TOTAL_FIELD from '@salesforce/schema/Healthcare_Cost__c.Sub_Total__c';

const COLUMNS = [
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
        editable: false,
        sortable: true
    },
    {
        label: 'Cost Review',
        fieldName: COST_REVIEW_FIELD.fieldApiName,
        type:'boolean',
        editable:false,
        sortable: true
    },
    {
        label: 'Date of Service',
        fieldName: DATE_OF_SERVICE_FIELD.fieldApiName,
        editable: false,
        sortable: true
    },
    {
        label: 'Location Responded',
        fieldName: LOCATION_RESPONDED_FIELD.fieldApiName,
        type: 'text',
        editable: false,
        sortable: true
    },
    {
        label: 'Site Code',
        fieldName: SITE_CODE_FIELD.fieldApiName,
        type: 'text',
        editable: false,
        sortable: true
    },
    {
        label: 'Facility',
        fieldName: FACILITY_NAME_FIELD.fieldApiName,
        type: 'text',
        editable: false,
        sortable: true
    },
    {
        label: 'Basic Amount',
        fieldName: BASIC_AMOUNT_FIELD.fieldApiName,
        type: 'currency',
        editable: false,
        sortable: true
    },
    {
        label: 'Total Cost Override',
        fieldName: TOTAL_COST_OVERRIDE_FIELD.fieldApiName,
        type: 'currency',
        editable: false,
        sortable: true
    }
];

export default class AmbulanceRecordsAccount extends LightningElement {
    @api recordId;
    column = COLUMNS;
    isFirstPage = true;
    isLastPage = false;
    totalRecords = 0; //Total no.of records
    totalPages; //Total no.of pages
    pageNumber = 1; //Page number
    pageSizeOptions = [5, 10, 25, 50, 75, 100]; //Page size options
    records = []; //All records available in the data table
    pageSize; //No.of records to be displayed per page
    recordsToDisplay = []; //Records to be displayed on the page
    wiredRecords;
    selectedCase;
    selectedRows = [];
    limitSize = 0;
    rowSize = 0;
    costInclude;
    costReview;
    selectAll = true;

    connectedCallback(){
        this.onLoad();
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
        
        let selectedCostRecords = [];
        
        selected.forEach(function(element){
        selectedCostRecords.push(element);
           console.log(element);   
        });

        await updateHCCCaseInformation({ caseId: this.selectedCase, hccList: selectedCostRecords})
        .then((result) => {
            console.log("Result : " + result);
            if(result == 'Failed'){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please ensure cost review and cost include are unchecked for the Ambulance Healthcare Cost record(s) you want to assign a case.',
                        variant: 'error'
                    })
                );
            }
            else if(result == 'Passed'){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Case assigned to Ambulance HealthCare Cost record(s) updated successfully.',
                        variant: 'success'
                    })
                );    
            }
            else if(result == 'Empty Selection'){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please select Case and HCC Records to map.',
                        variant: 'error'
                    })
                );
            }
            else if(result == null){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Case assignment did not succeed. Please try again!',
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
    async refresh(){
        await refreshApex(this.wiredRecords);
    }
 
    onLoad(){
        return getHealthcareCostsAmbulanceForAccount({accId: this.recordId, costIncludeValue: this.costInclude, costReviewValue: this.costReview})
        .then(result=>{
            console.log('Length of records : ' + result.length);
            console.log('Cost Review : ' + this.costReview + ", Cost Include : " + this.costInclude);
            this.wiredRecords = result;
            if(result != null && result){
//                console.log('Data of Ambulance Records --> ' + JSON.stringify(result));
                this.records = JSON.parse(JSON.stringify(result));
                this.totalRecords = result.length;
                this.pageSize = this.pageSizeOptions[0]; 
                this.paginationHelper(); // call helper menthod to update pagination logic
                this.error = undefined;
            }
        })
        .catch(error =>{
            this.error = error;
            this.records = [];
        })
    }

    loadCount()
    {
        return getAmbulanceCountonAccount({accId: this.recordId})
        .then(result =>{
            if(result != null && result){
                console.log('Result (Count of Records) : ' + result);
                this.totalRecords = result;
            }

        })
        .catch(error =>{
            this.error = error;
            this.totalRecords = 0;
        });
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

    calculateLimitAndOffset(){
        this.limitValue = this.pageSize;
        this.rowSize = (this.pageNumber - 1) * this.pageSize
    }

    // JS function to handel pagination logic 
    paginationHelper() {
        console.log('records : ' + JSON.stringify(this.records));
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
        console.log("Records to display : " + JSON.stringify(this.recordsToDisplay));
    }

    handleCostIncludeChange(event){
            this.costInclude = event.target.checked;
            if(!this.costInclude)
            {
                this.costInclude == null;
            }    
            getHealthcareCostsAmbulanceForAccount({accId: this.recordId, costIncludeValue: this.costInclude, costReviewValue: this.costReview})
            .then(result=>{
                this.recordsToDisplay = result;
             //   this.paginationHelper();
                this.wiredRecords;
                console.log(JSON.stringify(this.recordsToDisplay));
                return this.refresh();
            })

    }

    handleCostReviewChange(event){
        this.costReview = event.target.checked;
        if(!this.costReview)
        {
            this.costReview == null;
        } 
        getHealthcareCostsAmbulanceForAccount({accId: this.recordId, costIncludeValue: this.costInclude, costReviewValue: this.costReview})
        .then(result=>{
            this.recordsToDisplay = result;
          //  this.paginationHelper();
            this.wiredRecords;
            console.log(JSON.stringify(this.recordsToDisplay));
            return this.refresh();
        })
        
    }

    handleSelectAllChange(event){
        this.selectAll = event.target.checked;
        console.log('Select All Value : ' + this.selectAll);
        if(this.selectAll){
            getHealthcareCostsAmbulanceForAccount({accId: this.recordId, costIncludeValue: null, costReviewValue: null})
            .then(result=>{
                this.recordsToDisplay = result;
             //   this.paginationHelper();
                this.wiredRecords;
                console.log(JSON.stringify(this.recordsToDisplay));
                return this.refresh();
            })
        }
        else{
            if(!this.selectAll){
                if((this.costInclude || !this.costInclude) && (this.costReview || !this.costReview)){
                    this.costInclude = false;
                    this.costReview = false;
                   
                }
            }
            getHealthcareCostsAmbulanceForAccount({accId: this.recordId, costIncludeValue: this.costInclude, costReviewValue: this.costReview})
            .then(result=>{
                this.recordsToDisplay = result;
               // this.paginationHelper();
                this.wiredRecords;
                console.log(JSON.stringify(this.recordsToDisplay));
                return this.refresh();
            });
            
        }
    }
}