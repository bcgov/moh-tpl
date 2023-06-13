import { LightningElement, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getHealthcareCostsFCForAccount from '@salesforce/apex/HCCostAccountController.getHealthcareCostsFCForAccount';

const COLUMNS = [
    {
        label: 'Case',
        fieldName: 'Case_Number__c',
        type:'text',
        editable:false
    },
    {
        label: 'Description',
        fieldName: 'Description__c',
        type:'text',
        editable:false
    },
    {
        label: 'Cost',
        fieldName: 'Cost__c',
        type: 'currency',
        editable: false
    }
];

export default class FuturecareRecordsAccount extends LightningElement {
    @api recordId;
    column = COLUMNS;
    isFirstPage = true;
    isLastPage = false;
    hideDeleteButton = true;
    sortSelection = 'asc'; // sort order
    totalRecords = 0; //Total no.of records
    totalPages; //Total no.of pages
    pageNumber = 1; //Page number
    pageSizeOptions = [5, 10, 25, 50, 75, 100]; //Page size options
    pageSize; //No.of records to be displayed per page
    recordsToDisplay = []; //Records to be displayed on the page
    wiredRecords;
    updateMessage='';
    selectedFilter= 'All Records';
    filterOptions = [
        { label: 'All Records', value: 'All Records' }
    ];

    connectedCallback(){
        this.selectedFilter= 'All Records';
        this.hideDeleteButton = false;
        this.sortSelection = 'asc';
        this.pageSize = this.pageSizeOptions[0]; 
        this.pageNumber = 1;
        this.onLoad();
    } 

    doSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortSelection = this.sortDirection;
        this.onLoad();
       // this.sortData(this.sortBy, this.sortDirection);
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
        await refreshApex(this.records);
    }

    onLoad(){
        return getHealthcareCostsFCForAccount({accId: this.recordId, selectedFilterValue: this.selectedFilter, pageNumber: this.pageNumber, pageSize: this.pageSize, sortOrder: this.sortSelection})
        .then(result=>{
            this.recordsToDisplay = [];
 
            if(result.hccList != null && result.hccList){
                 this.records = JSON.parse(JSON.stringify(result.hccList));
                 this.totalRecords = result.totalCount;
                 this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
                 // set page number 
                 if (this.pageNumber <= 1) {
                     this.pageNumber = 1;
                 } else if (this.pageNumber >= this.totalPages) {
                     this.pageNumber = this.totalPages;
                 }
                  // set records to display on current page 
                 for(let i=0;i<this.records.length;i++){
                     if(i=== this.totalRecords){
                         break;
                     }
                     this.recordsToDisplay.push(this.records[i]);
                 }
         
                 this.error = undefined;
                 
             }
             else{
                 this.records = [];
                 this.totalRecords = result.totalCount;
             }
         })
         .catch(error =>{
             this.records = [];
             this.totalRecords = 0;
             this.dispatchEvent(
                 new ShowToastEvent({
                     title: 'Error',
                     message: 'Some issues occured while loading Future Care Records. Please contact Administrator',
                     variant: 'error'
                 })
             );    
         })
    }
    get bDisableFirst() {
        return this.pageNumber == 1;
    }
    get bDisableLast() {
        return this.pageNumber == this.totalPages;
    }
    
    handleRecordsPerPage(event) {
        this.pageSize = event.target.value;
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
        // set page number 
        if (this.pageNumber <= 1) {
            this.pageNumber = 1;
        } else if (this.pageNumber >= this.totalPages) {
            this.pageNumber = this.totalPages;
        }
       this.onLoad();
    }
    previousPage() {
        this.pageNumber = this.pageNumber - 1;
        this.showSection = false;
        this.draftValues = [];
        this.onLoad();
   
    }
    nextPage() {
        this.pageNumber = this.pageNumber + 1;
        this.showSection = false;
        this.draftValues = [];
       this.onLoad();
    }

    firstPage() {
        this.pageNumber = 1;
        this.showSection = false;
        this.draftValues = [];
        this.onLoad();
    }

    lastPage() {
        this.pageNumber = this.totalPages;
        this.showSection = false;
        this.draftValues = [];
        this.onLoad();
    }

    handleRefresh(){
        this.onLoad();
    }

}