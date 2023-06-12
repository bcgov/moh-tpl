import { LightningElement, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getHealthcareCostsPharmacareForCase from '@salesforce/apex/HCCostCaseController.getHealthcareCostsPharmacareForCase';
import saveDraftValues from '@salesforce/apex/HCCCostController.saveDraftValues';
import deleteHCCRecord from '@salesforce/apex/HCCCostController.deleteHCCRecord';
import updateAll from '@salesforce/apex/HCCCostController.updateAll';


const INTEGRATION_COLUMNS = [
    {
        label: 'Cost Include',
        fieldName: 'Cost_Include__c',
        type:'boolean',
        editable: true
    },
    {
        label: 'Cost Review',
        fieldName: 'Cost_Review__c',
        type:'boolean',
        editable:true
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
        editable: false
    },
    {
        label: 'DIN',
        fieldName: 'DIN__c',
        type: 'text',
        editable: false
    },
    {
        label: 'Name of Drug',
        fieldName: 'Name_of_Drug__c',
        type: 'text',
        editable: false
    },
    {
        label: 'Cost of Drug',
        fieldName: 'Cost_of_Drug__c',
        type: 'currency',
        editable: false
    },
    {
        label: 'Total Cost Override',
        fieldName: 'Total_Cost_Override__c',
        type: 'currency',
        editable: false
    },
    {
        label: 'Source System ID',
        fieldName: 'Source_System_ID__c',
        type: 'text',
        editable: false
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
    draftValues = [];
    updateMessage='';
    selectedFilter= 'All Records';
    showSection = false;
    showErrorMessage = false;
    showMassUpdateSection = false;
    costReview = false;
    costInclude = false;
    lastSavedData;
    filterOptions = [
        { label: 'All Records', value: 'All Records' }
    ];

    connectedCallback() {
        this.selectedFilter = 'All Records';
        this.hideDeleteButton = true;
        this.pageSize = this.pageSizeOptions[0]; 
        this.pageNumber = 1;
        this.onLoad();
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
                 this.lastSavedData = this.records;
                 this.error = undefined;
                 
             }
             else{
                 this.records = [];
                 this.totalRecords = result.totalCount;
             }
        })
        .catch(error =>{
            this.records = []
            this.totalRecords = 0;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Some issues occured while loading Pharmacare Records. Please contact Administrator',
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
    handleMassUpdate(){
        if(this.showMassUpdateSection){
             this.showMassUpdateSection = false;
        }else{
             this.showMassUpdateSection = true;
        }
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
        var el = this.template.querySelector('c-custom-data-table');
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

    async refresh(){
        await refreshApex(this.wiredRecords);
    }

    handleCancel(event) {
        event.preventDefault();
        this.showSection = false;
        this.records = JSON.parse(JSON.stringify(this.lastSavedData));
        this.draftValues = [];
        return this.refresh();
    }

    handleEdit(event) {
        event.preventDefault();
        this.showSection = true;
    }

    handleCellChange(event){
        this.showSection = true;
        for(let i = 0 ; i < event.detail.draftValues.length;i++){
            let index = this.draftValues.findIndex(e=>e.Id === event.detail.draftValues[i].Id);
            if(index > -1 ){
                if(event.detail.draftValues[i].Cost_Include__c != null){
                    this.draftValues[index].Cost_Include__c = event.detail.draftValues[i].Cost_Include__c;
                }
                if(event.detail.draftValues[i].Cost_Review__c != null){
                    this.draftValues[index].Cost_Review__c = event.detail.draftValues[i].Cost_Review__c;
                }
                if(event.detail.draftValues[i].Source_System_ID__c) {
                    this.draftValues[index].Source_System_ID__c = event.detail.draftValues[i].Source_System_ID__c;
                }
        
            }else{
                var obj ={
                    Id : event.detail.draftValues[i].Id,
                    Cost_Review__c:event.detail.draftValues[i].Cost_Review__c,
                    Cost_Include__c:event.detail.draftValues[i].Cost_Include__c,
                    Source_System_ID__c: event.detail.draftValues[i].Source_System_ID__c,
                };          
                this.draftValues.push(obj);
            }
            
        }
    }
    changeCostReview(event){
        this.costReview = event.target.checked;
        console.log(this.costReview);
    }
    changeCostInclude(event){
        this.costInclude = event.target.checked;
        console.log(this.costInclude);
    }
    updateAll(){
        updateAll({caseId: this.recordId,costReview:this.costReview,costInclude:this.costInclude,currentRecords:this.recordsToDisplay})
        .then(result=>{
            this.onLoad();
        })
        .catch(error =>{
            this.records = []
            this.totalRecords = 0;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Some issues occured while loading Pharmacare Records. Please contact Administrator',
                    variant: 'error'
                })
            );    
        });
    }
    handleSave(){
        var el = this.template.querySelector('c-custom-data-table');
        var selected = el.getSelectedRows();
        selected = this.draftValues;
       
        for(var i =0; i < selected.length;i++){ 
            let index = this.draftValues.findIndex(e=>e.Id === selected[i].Id);
            if(index > -1 ){
                if( selected[i].Cost_Include__c != this.draftValues[index].Cost_Include__c){
                    selected[i].Cost_Include__c = this.draftValues[index].Cost_Include__c;
                }
                if(selected[i].Cost_Review__c != this.draftValues[index].Cost_Review__c){
                    selected[i].Cost_Review__c = this.draftValues[index].Cost_Review__c;
                }
                   
                if(selected[i].Source_System_ID__c != this.draftValues[index].Source_System_ID__c) {
                    selected[i].Source_System_ID__c = this.draftValues[index].Source_System_ID__c;
                }
            }
        }

        saveDraftValues({data: selected, recordDisplay: this.recordsToDisplay, recordType: 'Pharmacare' })
        .then((data,error) => {
            this.updateMessage = data.actionMessage;
            this.recordsToDisplay = data.updatedRecords;
            this.draftValues = [];  
            this.showSection = false;
            if(this.updateMessage){
                this.updateMessage = this.updateMessage.replace(/\r\n/g, "<br />");
                this.showErrorMessage = true;
            }
            this.recordsToDisplay = updatedRecords;
            if(data.passedResult == 'Passed'){
               
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'HealthCare Cost Pharmacare record(s) updated successfully',
                        variant: 'success'
                    })
                );    
                               
            }
            else if(data.passedResult == 'Failed' || data.passedResult == null){
              
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please review the error message shown below and try again!',
                        variant: 'error'
                    })
                );   
            } 
        
            else if(data.passedResult == 'Partial Success'){
             
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Warning',
                        message: 'Few Healthcare Cost record(s) updated successfully. Errors on remaining shown below!',
                        variant: 'Warning'
                    })
                );
            }   
            if(error){
              
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
        });
    }
           
}