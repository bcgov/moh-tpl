import { LightningElement, wire, api } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getHealthcareCostsCCForCase from '@salesforce/apex/HCCostCaseController.getHealthcareCostsCCForCase';
import deleteHCCRecord from '@salesforce/apex/HCCCostController.deleteHCCRecord';
import saveDraftValues from '@salesforce/apex/HCCCostController.saveDraftValues'; 

const COLUMNS = [
    
    {
        label: 'Description',
        fieldName: 'Description__c',
        type:'text',
        sortable: true,
        editable:true
    },
    {
        label: 'Cost',
        fieldName: 'Cost__c',
        type: 'currency',
        sortable: true,
        editable: true
    }
];


export default class ContinuingcareRecordsCase extends LightningElement {
    @api recordId;
    column = COLUMNS;
    isFirstPage = true;
    isLastPage = false;
    hideDeleteButton = true;
    totalRecords = 0; //Total no.of records
    totalPages; //Total no.of pages
    pageNumber = 1; //Page number
    pageSizeOptions = [5, 10, 25, 50, 75, 100]; //Page size options
    pageSize; //No.of records to be displayed per page
    recordsToDisplay = []; //Records to be displayed on the page
    wiredRecords;
    updateMessage='';
    selectedFilter= 'Manual Records';
    filterOptions = [
        { label: 'Manual Records', value: 'Manual Records' },
        { label: 'Records Created Today', value: 'Records Created Today' }
    ];

    connectedCallback(){
        this.selectedFilter= 'Manual Records';
        this.hideDeleteButton = false;
        this.pageSize = this.pageSizeOptions[0]; 
        this.pageNumber = 1;
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
    
    async refresh(){
        await refreshApex(this.records);
    }
 
    onLoad(){
        return getHealthcareCostsCCForCase({caseId: this.recordId, filterValue: this.selectedFilter ,pageNumber: this.pageNumber, pageSize: this.pageSize})
        .then(result =>{
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
                    message: 'Some issues occured while loading Continuing Care Records. Please contact Administrator',
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
        this.onLoad();
   
    }
    nextPage() {
        this.pageNumber = this.pageNumber + 1;
       this.onLoad();
    }

    firstPage() {
        this.pageNumber = 1;
        this.onLoad();
    }

    lastPage() {
        this.pageNumber = this.totalPages;
        this.onLoad();
    }

    handleRefresh(){
        this.onLoad();
    }

    handleFilterChange(event) {
        this.selectedFilter = event.target.value;
        
        if(this.selectedFilter == 'Manual Records')
        {
            this.hideDeleteButton = false;    
        }
        else if(this.selectedFilter == 'Records Created Today'){
            this.hideDeleteButton = false;
        }
        else{
            this.hideDeleteButton = true;
        }
        
        this.pageNumber = 1;
        this.onLoad();  
               
    }

    async handleSelect()
    {
        var el = this.template.querySelector('lightning-datatable');
        var selected = el.getSelectedRows();
        let selectedCostRecords = [];
        selected.forEach(function(element){
        selectedCostRecords.push(element);
        });
        if(!selected || !selectedCostRecords){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select records for deletion!',
                    variant: 'error'
                })
            );    
        }
        else{
            await deleteHCCRecord({deletionRecords: selectedCostRecords, filterOption: this.selectedFilter})
            .then((result) => {
               if(result == 'Passed'){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Selected Continuing Care record(s) deleted successfully',
                        variant: 'success'
                    })
                );    
                this.onLoad();
               }
                else if(result == 'Failed' || result == null){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Please select records for deletion.',
                            variant: 'error'
                        })
                    );     
                }  
                else if(result == 'Insufficient Privileges'){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Insufficient Privileges for record deletion. Please contact Administrator',
                            variant: 'error'
                        })
                    );  
                }       
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Insufficient Privileges for record deletion. Please contact Administrator',
                        variant: 'error'
                    })
                );  
            });
        }
       
    }
    
    handleSave(event){
        var el = this.template.querySelector('lightning-datatable');
        var selected = el.getSelectedRows();
        selected = this.draftValues;
        if(selected.length <= 0){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Review',
                    message: 'Please select the record being edited before continuing to save',
                    variant: 'warning'
                })
            );    
        }
        else{
            for(var i =0; i < selected.length;i++){ 
                for(var j=0;j<event.detail.draftValues.length;j++){
                     if(selected[i].Id == event.detail.draftValues[j].Id){
                         
                         if(event.detail.draftValues[j].Cost__c != undefined || event.detail.draftValues[j].Cost__c ){
                             if( selected[i].Cost__c != event.detail.draftValues[j].Cost__c){
                                 selected[i].Cost__c = event.detail.draftValues[j].Cost__c;
                             }
     
                         }
                        
                         if(event.detail.draftValues[j].Description__c != undefined || event.detail.draftValues[j].Description__c == null ){
                             if(selected[i].Description__c != event.detail.draftValues[j].Description__c){
                                 selected[i].Description__c = event.detail.draftValues[j].Description__c;
                             }
                           
                         }
                        
                     }
                }
             } 
             saveDraftValues({data: selected, recordDisplay: this.recordsToDisplay })
            .then((data,error) => {
                this.updateMessage = data.actionMessage;
                this.onLoad();

                if(this.updateMessage){
                    this.updateMessage = this.updateMessage.replace(/\r\n/g, "<br />");
                    this.showErrorMessage = true;
                }
                
                if(data.passedResult == 'Passed'){
                    this.draftValues = [];  
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'HealthCare Cost Continuing Care record(s) updated successfully',
                            variant: 'success'
                        })
                    );    
                                 
                }
                else if(data.passedResult == 'Failed' || data.passedResult == null){
                    this.draftValues = [];   
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Please review the error message shown below and try again!',
                            variant: 'error'
                        })
                    );   
                } 
                else if(data.passedResult == 'Partial Success'){
                    this.draftValues = [];
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Warning',
                            message: 'Few Healthcare Cost record(s) updated successfully. Errors on remaining shown below!',
                            variant: 'Warning'
                        })
                    );
                }   
                if(error){
                    this.draftValues = [];
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: error,
                            variant: 'error'
                        })
                    ); 
                }
                //Get the updated list with refreshApex.
                return this.refresh();    
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Some issues occured while saving Continuing Care Records. Please contact Administrator',
                        variant: 'error'
                    })
                );    
            });
        }
               
    }
}