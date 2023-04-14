import { LightningElement, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getHealthcareCostsPharmacareForCase from '@salesforce/apex/HCCostCaseController.getHealthcareCostsPharmacareForCase';
import saveDraftValues from '@salesforce/apex/HCCCostController.saveDraftValues';
import deleteHCCRecord from '@salesforce/apex/HCCCostController.deleteHCCRecord';

const MANUAL_COLUMNS = [
    {
        label: 'Cost Include',
        fieldName: 'Cost_Include__c',
        type:'boolean',
        editable: true,
        sortable: true
    },
    {
        label: 'Cost Review',
        fieldName: 'Cost_Review__c',
        type:'boolean',
        editable:true,
        sortable: true
    },
    {
        label: 'Date of Service',
        fieldName: 'Date_of_Service__c',
        type:'date-local',
        typeAttributes:{ 
            day: "2-digit",
            month: "2-digit",
            year: "numeric"},
        sortable: true,
        editable: true
    }, 
    {
        label: 'Practitioner Name',
        fieldName: 'Practitioner_Name__c',
        type: 'text',
        editable: true,
        sortable: true
    },
    {
        label: 'DIN',
        fieldName: 'DIN__c',
        type: 'text',
        editable: true,
        sortable: true
    },
    {
        label: 'Name of Drug',
        fieldName: 'Name_of_Drug__c',
        type: 'text',
        editable: true,
        sortable: true
    },
    {
        label: 'Cost of Drug',
        fieldName: 'Cost_of_Drug__c',
        type: 'currency',
        editable: true,
        sortable: true
    },
    {
        label: 'Total Cost Override',
        fieldName: 'Total_Cost_Override__c',
        type: 'currency',
        editable: true,
        sortable: true
    },
    {
        label: 'Source System ID',
        fieldName: 'Source_System_ID__c',
        type: 'text',
        editable: true,
        sortable: true
    }
];
const INTEGRATION_COLUMNS = [
    {
        label: 'Cost Include',
        fieldName: 'Cost_Include__c',
        type:'boolean',
        editable: true,
        sortable: true
    },
    {
        label: 'Cost Review',
        fieldName: 'Cost_Review__c',
        type:'boolean',
        editable:true,
        sortable: true
    },
    {
        label: 'Date of Service',
        fieldName: 'Date_of_Service__c',
        type:'date-local',
        typeAttributes:{ 
            day: "2-digit",
            month: "2-digit",
            year: "numeric"},
        sortable: true,
        editable: false
    }, 
    {
        label: 'Practitioner Name',
        fieldName: 'Practitioner_Name__c',
        type: 'text',
        editable: false,
        sortable: true
    },
    {
        label: 'DIN',
        fieldName: 'DIN__c',
        type: 'text',
        editable: false,
        sortable: true
    },
    {
        label: 'Name of Drug',
        fieldName: 'Name_of_Drug__c',
        type: 'text',
        editable: false,
        sortable: true
    },
    {
        label: 'Cost of Drug',
        fieldName: 'Cost_of_Drug__c',
        type: 'currency',
        editable: false,
        sortable: true
    },
    {
        label: 'Total Cost Override',
        fieldName: 'Total_Cost_Override__c',
        type: 'currency',
        editable: true,
        sortable: true
    },
    {
        label: 'Source System ID',
        fieldName: 'Source_System_ID__c',
        type: 'text',
        editable: false,
        sortable: true
    }
];
export default class PharmacareRecordsCase extends LightningElement {
    @api recordId;
    column = INTEGRATION_COLUMNS;
    records = []; //All records available in the data table
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
    selectedFilter= 'All Records';
    filterOptions = [
        { label: 'All Records', value: 'All Records' },
        { label: 'Manual Records', value: 'Manual Records' },
        { label: 'Records Created Today', value: 'Records Created Today' }
    ];

    connectedCallback() {
        this.selectedFilter = 'All Records';
        this.hideDeleteButton = true;
        this.pageSize = this.pageSizeOptions[0]; 
        this.pageNumber = 1;
        this.onLoad();
      }
    
      disconnectedCallback() {
        clearInterval(this.event2);
      }

     onLoad(){
        return getHealthcareCostsPharmacareForCase({caseId: this.recordId, filterValue: this.selectedFilter, pageSize: this.pageSize, pageNumber: this.pageNumber})
        .then(result=>{
            this.wiredRecords = result.hccList;
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
         
                 console.log("Records to display : " + JSON.stringify(this.recordsToDisplay));
                 console.log('Total Count : ' + result.totalCount);
                 this.error = undefined;
                 
             }
             else{
                 this.records = [];
                 this.totalRecords = result.totalCount;
             }
        })
        .catch(error =>{
            console.log(error);
            this.records = []
            this.totalRecords = 0;
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
        console.log('Page Number : ' + this.pageNumber); 
        this.onLoad();
    }

    handleFilterChange(event) {
        this.selectedFilter = event.target.value;
        console.log('Selected Filter Value : ' + this.selectedFilter);
        
        if(this.selectedFilter == 'Manual Records')
        {
            this.hideDeleteButton = false;
            this.column = MANUAL_COLUMNS;    
        }
        else if(this.selectedFilter == 'Records Created Today'){
            this.hideDeleteButton = false;
            this.column = MANUAL_COLUMNS;  
        }
        else{
            this.hideDeleteButton = true;
            this.column = INTEGRATION_COLUMNS;
        }
        
        this.pageNumber = 1;
        this.onLoad();  
        console.log('Selected Filter Value : ' + this.selectedFilter);
               
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

    handleRefresh(){
        this.onLoad();
    }
    
    async handleSelect()
    {
        var el = this.template.querySelector('lightning-datatable');
        console.log(el);
        var selected = el.getSelectedRows();
        //console.log(selected);
        console.log('selectedRows : ' + selected);
        let selectedCostRecords = [];
        console.log('Selected Filter : ' + this.selectedFilter);
        selected.forEach(function(element){
        selectedCostRecords.push(element);
           console.log(element);   
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
                console.log('Result : ' + result);
               if(result == 'Passed'){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Selected Pharmacare record(s) deleted successfully',
                        variant: 'success'
                    })
                );    
                this.onLoad();
               }
                else if(result == 'Failed' || result == null){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Please select records for deletion. Only Manual Records can be deleted.',
                            variant: 'error'
                        })
                    );     
                }    
            })
            .catch(error => {
                console.log('error : ' + JSON.stringify(error));
            });
        }
       
    }

    async refresh(){
        await refreshApex(this.wiredRecords);
    }

    handleSave(event){
        var el = this.template.querySelector('lightning-datatable');
        console.log(''+ el);
        var selected = el.getSelectedRows();
        console.log(JSON.stringify(selected));
        console.log(JSON.stringify(event.detail.draftValues));

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
                         
                         if(event.detail.draftValues[j].Cost_Include__c != undefined || event.detail.draftValues[j].Cost_Include__c ){
                             if( selected[i].Cost_Include__c != event.detail.draftValues[j].Cost_Include__c){
                                 selected[i].Cost_Include__c = event.detail.draftValues[j].Cost_Include__c;
                             }
     
                         }
                        
                         if(event.detail.draftValues[j].Cost_Review__c != undefined || event.detail.draftValues[j].Cost_Review__c ){
                             if(selected[i].Cost_Review__c != event.detail.draftValues[j].Cost_Review__c){
                                 selected[i].Cost_Review__c = event.detail.draftValues[j].Cost_Review__c;
                             }
                           
                         }
                        
                         if(event.detail.draftValues[j].Date_of_Service__c != undefined || event.detail.draftValues[j].Date_of_Service__c == null ){
                             if(selected[i].Date_of_Service__c != event.detail.draftValues[j].Date_of_Service__c){
                                 selected[i].Date_of_Service__c = event.detail.draftValues[j].Date_of_Service__c;
                             }
                         
                         }
                      
                         if(event.detail.draftValues[j].Practitioner_Name__c != undefined || event.detail.draftValues[j].Practitioner_Name__c == ''){
                            
                             if(selected[i].Practitioner_Name__c != event.detail.draftValues[j].Practitioner_Name__c){
                                selected[i].Practitioner_Name__c = event.detail.draftValues[j].Practitioner_Name__c;
                             }
                            
                         }
                        
                         if(event.detail.draftValues[j].DIN__c != undefined || event.detail.draftValues[j].DIN__c == null){
                             if(selected[i].DIN__c != event.detail.draftValues[j].DIN__c){
                                 selected[i].DIN__c = event.detail.draftValues[j].DIN__c;
                             }
                            
                         }
                         if(event.detail.draftValues[j].Name_of_Drug__c != undefined || event.detail.draftValues[j].Name_of_Drug__c == null){
                            if(selected[i].Name_of_Drug__c != event.detail.draftValues[j].Name_of_Drug__c){
                                selected[i].Name_of_Drug__c = event.detail.draftValues[j].Name_of_Drug__c;
                            }
                           
                        }
                        if(event.detail.draftValues[j].Cost_of_Drug__c != undefined || event.detail.draftValues[j].Cost_of_Drug__c == null){
                            if(selected[i].Cost_of_Drug__c != event.detail.draftValues[j].Cost_of_Drug__c){
                                selected[i].Cost_of_Drug__c = event.detail.draftValues[j].Cost_of_Drug__c;
                            }
                           
                        }
                                              
                        if(event.detail.draftValues[j].Total_Cost_Override__c != undefined || event.detail.draftValues[j].Total_Cost_Override__c == null){
                             if(selected[i].Total_Cost_Override__c != event.detail.draftValues[j].Total_Cost_Override__c){
                                selected[i].Total_Cost_Override__c = event.detail.draftValues[j].Total_Cost_Override__c;    
                             }
                         }
                     
                       
                         if(event.detail.draftValues[j].Source_System_ID__c != undefined || event.detail.draftValues[j].Source_System_ID__c == ''){
                             if(selected[i].Source_System_ID__c != event.detail.draftValues[j].Source_System_ID__c){
                                 selected[i].Source_System_ID__c = event.detail.draftValues[j].Source_System_ID__c;
                             }       
                           
                         }
                         
                         console.log('Selected Value : ' + JSON.stringify(selected[i]));
         
                     }
                }
             } 
             saveDraftValues({data: selected, recordDisplay: this.recordsToDisplay })
            .then((data,error) => {
                this.updateMessage = data.actionMessage;
      
                var indexes = data.indexNumbers;
          
                console.log('passedResult : ' + data.passedResult);
                console.log( 'Toast Message : ' + this.updateMessage);
                console.log('Size of Index List : ' + indexes);
                       
                if(this.updateMessage){
                    this.updateMessage = this.updateMessage.replace(/\r\n/g, "<br />");
                    this.showErrorMessage = true;
                }
                
                if(data.passedResult == 'Passed'){
                    this.draftValues = [];  
                    this.onLoad();   
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'HealthCare Cost Pharmacare record(s) updated successfully',
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
                    this.onLoad();  
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
                console.log('error : ' + JSON.stringify(error));
            });
        }
        
        
    }
}