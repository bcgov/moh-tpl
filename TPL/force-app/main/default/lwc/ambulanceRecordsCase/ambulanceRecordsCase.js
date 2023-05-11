import { LightningElement, wire, api, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getHealthcareCostsAmbulanceForCase from '@salesforce/apex/HCCostCaseController.getHealthcareCostsAmbulanceForCase';
import saveDraftValues from '@salesforce/apex/HCCCostController.saveDraftValues'; 
import deleteHCCRecord from '@salesforce/apex/HCCCostController.deleteHCCRecord';
import getFacilityBySiteCode from '@salesforce/apex/HCCCostController.getFacilityBySiteCode';

const MANUAL_COLUMNS = [
    {
        label: 'Cost Include',
        fieldName: 'Cost_Include__c',
        type:'boolean',
        sortable: true,
        editable: true
    },
    {
        label: 'Cost Review',
        fieldName: 'Cost_Review__c',
        type:'boolean',
        sortable: true,
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
        editable: true
    }, 
    {
        label: 'Location Responded',
        fieldName: 'Location_Responded__c',
        type:'text',
        editable: true,
        sortable:true
    },
    {
        label: 'Site Code',
        fieldName: 'Site_Code__c',
        type: 'text',
        editable: true,
        sortable: true
    },
    {
        label: 'Facility',
        fieldName: 'Facility__c',
        type:'lookup',
        typeAttributes: {
            placeholder: 'Choose Facility Account',
            object: 'Healthcare_Cost__c',
            fieldName: 'Facility__c',
            label: 'Account',
            value: { fieldName: 'Facility__c'},
            context:{fieldName: 'Id'},
            variant: 'label-hidden',
            name: 'Account',
            fields: ['Account.Name'],
            target: '_self'
        },
        cellAttributes:{
            class: { fieldName: 'accountNameClass'}
        },
        sortable: true
    },
    {
        label: 'Basic Amount',
        fieldName: 'Basic_Amount__c',
        type: 'currency',
        sortable: true,
        editable: false
    },
    {
        label: 'Total Cost Override',
        fieldName: 'Total_Cost_Override__c',
        type: 'currency',
        sortable: true,
        editable: true
    },
    {
        label: 'Fixed Wing/Helicopter',
        fieldName: 'Fixed_Wing_Helicopter__c',
        type: 'currency',
        editable: true,
        sortable: false
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
        editable: true,
        sortable: true
    },
    {
        label: 'Date of Service',
        fieldName: 'Date_of_Service__c',
        type: 'date',
        editable: false,
        sortable: true
    },
    {
        label: 'Location Responded',
        fieldName: 'Location_Responded__c',
        type: 'text',
        editable: false,
        sortable: true
    },
    {
        label: 'Site Code',
        fieldName: 'Site_Code__c',
        type: 'text',
        editable: false,
        sortable: true
    },
    {
        label: 'Facility',
        fieldName:'FacilityName__c',
        type: 'text',
        editable: false,
        sortable: true
    },
    {
        label: 'Basic Amount',
        fieldName: 'Basic_Amount__c',
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
        label: 'Fixed Wing Helicopter',
        fieldName: 'Fixed_Wing_Helicopter__c',
        type: 'currency',
        editable: false,
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
export default class AmbulanceRecordsCase extends LightningElement {
    @api recordId;
    column = INTEGRATION_COLUMNS;
    records = []; //All records available in the data table
    isFirstPage = true;
    isLastPage = false;
    totalRecords = 0; //Total no.of records
    totalPages; //Total no.of pages
    pageNumber = 1; //Page number
    pageSizeOptions = [5, 10, 25, 50, 75, 100]; //Page size options
    pageSize; //No.of records to be displayed per page
    recordsToDisplay = []; //Records to be displayed on the page
    hideDeleteButton = true;
    showSpinner = false;
    lastSavedData;
    privateChildren = {}; //used to get the datatable lookup as private childern of customDatatable
    wiredRecords;
    draftValues = [];
    showErrorMessage = false;
    updateMessage='';
    selectedFilter= 'All Records';
    showSection = false;
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
    
      renderedCallback() {
        if (!this.isComponentLoaded) {
            /* Add Click event listener to listen to window click to reset the lookup selection 
            to text view if context is out of sync*/
            window.addEventListener('click', (evt) => {
                this.handleWindowOnclick(evt);
            });
            this.isComponentLoaded = true;
        }
    }

    disconnectedCallback() {
        clearInterval(this.event2);
        window.removeEventListener('click', () => { });
    }
    
    handleWindowOnclick(context) {
        this.resetPopups('c-datatable-lookup', context);
    }

      //create object value of datatable lookup markup to allow to call callback function with window click event listener
      resetPopups(markup, context) {
        let elementMarkup = this.privateChildren[markup];
        if (elementMarkup) {
            Object.values(elementMarkup).forEach((element) => {
                element.callbacks.reset(context);
            });
        }
    }

    onLoad(){
        return getHealthcareCostsAmbulanceForCase({caseId: this.recordId, filterValue: this.selectedFilter, pageSize: this.pageSize, pageNumber: this.pageNumber})
        .then(result=>{
            this.wiredRecords = result.hccList;
            this.recordsToDisplay = [];
           
            if(result.hccList != null && result.hccList){
                this.records = JSON.parse(JSON.stringify(result.hccList));
                this.records.forEach(record =>{
                    record.accountNameClass = 'slds-cell-edit';
                })
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
            this.lastSavedData = this.records;
            this.showSpinner = false;
        })
        .catch(error =>{
            this.records = []
            this.totalRecords = 0;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Some issues occured while loading Ambulance Records. Please contact Administrator',
                    variant: 'error'
                })
            );    
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

    handleFilterChange(event) {
        this.selectedFilter = event.target.value;
               
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
    
     // Event to register the datatable lookup mark up.
     handleItemRegister(event) {
        event.stopPropagation(); //stops the window click to propagate to allow to register of markup.
        const item = event.detail;
        if (!this.privateChildren.hasOwnProperty(item.name))
            this.privateChildren[item.name] = {};
        this.privateChildren[item.name][item.guid] = item;
    }

      //Captures the changed lookup value and updates the records list variable.
      handleValueChange(event) {
        event.stopPropagation();
  
        let dataRecieved = event.detail.data;
        let updatedItem;
       
       if(!dataRecieved.value){
            dataRecieved.value ='';
        }
        switch (dataRecieved.label) {
            case 'Account':
                updatedItem = {
                    Id: dataRecieved.context,
                    Facility__c: dataRecieved.value,
                    
                };
                // Set the cell edit class to edited to mark it as value changed.
                this.setClassesOnData(
                    dataRecieved.context,
                    'accountNameClass',
                    'slds-cell-edit slds-is-edited'
                );
                break;
            default:
                this.setClassesOnData(dataRecieved.context, '', '');
                break;
        }
        this.updateDraftValues(updatedItem);
       // this.updateDataValues(updatedItem);
    }
     handleEdit(event) {
        event.preventDefault();
        this.showSection = true;
        let dataRecieved = event.detail.data;
        this.handleWindowOnclick(dataRecieved.context);
        switch (dataRecieved.label) {
            case 'Account':
                this.setClassesOnData(
                    dataRecieved.context,
                    'accountNameClass',
                    'slds-cell-edit'
                );
                break;
            default:
                this.setClassesOnData(dataRecieved.context, '', '');
                break;
        };
    }
    handleCellChange(event){
    
        var siteCodeIds = [];
        this.showSection = true;
        for(let i = 0 ; i < event.detail.draftValues.length;i++){
            siteCodeIds.push({id:event.detail.draftValues[i].Id,siteCode:event.detail.draftValues[i].Site_Code__c});
            let index = this.draftValues.findIndex(e=>e.Id === event.detail.draftValues[i].Id);
            if(index > -1 ){
                if(event.detail.draftValues[i].Cost_Include__c != null){
                    this.draftValues[index].Cost_Include__c = event.detail.draftValues[i].Cost_Include__c;
                }
                if(event.detail.draftValues[i].Cost_Review__c != null){
                    this.draftValues[index].Cost_Review__c = event.detail.draftValues[i].Cost_Review__c;
                }
                
                if(event.detail.draftValues[i].Date_of_Service__c){
                    this.draftValues[index].Date_of_Service__c = event.detail.draftValues[i].Date_of_Service__c;
                }
                if(event.detail.draftValues[i].Location_Responded__c){
                    this.draftValues[index].Location_Responded__c = event.detail.draftValues[i].Location_Responded__c;
                }
               
                if(event.detail.draftValues[i].Basic_Amount__c){
                    this.draftValues[index].Basic_Amount__c = event.detail.draftValues[i].Basic_Amount__c;
                }
                if(event.detail.draftValues[i].Total_Cost_Override__c){
                    this.draftValues[index].Total_Cost_Override__c = event.detail.draftValues[i].Total_Cost_Override__c;
                }
                if(event.detail.draftValues[i].Fixed_Wing_Helicopter__c){
                    this.draftValues[index].Fixed_Wing_Helicopter__c = event.detail.draftValues[i].Fixed_Wing_Helicopter__c;
                }
                if(event.detail.draftValues[i].Source_System_ID__c) {
                    this.draftValues[index].Source_System_ID__c = event.detail.draftValues[i].Source_System_ID__c;
                }
        
            }else{
                var obj ={
                    Id : event.detail.draftValues[i].Id,
                    Cost_Review__c:event.detail.draftValues[i].Cost_Review__c,
                    Cost_Include__c:event.detail.draftValues[i].Cost_Include__c,
                    Date_of_Service__c:event.detail.draftValues[i].Date_of_Service__c,
                    Location_Responded__c:event.detail.draftValues[i].Location_Responded__c,
                    Basic_Amount__c:event.detail.draftValues[i].Basic_Amount__c,
                    Total_Cost_Override__c:event.detail.draftValues[i].Total_Cost_Override__c,
                    Fixed_Wing_Helicopter__c:event.detail.draftValues[i].Fixed_Wing_Helicopter__c,
                    Source_System_ID__c: event.detail.draftValues[i].Source_System_ID__c,
                };
               
                this.draftValues.push(obj);
            }
            
        }

        getFacilityBySiteCode({siteCodeIds:siteCodeIds}).then(response=>{       
        }).catch(error=>{
        })
    }

    handleChange(event) {
        event.preventDefault();
       this.Facility__c = event.target.value;
        this.showSpinner = true;
      
    }

    handleCancel(event) {
        event.preventDefault();
        this.showSection = false;
        this.records = JSON.parse(JSON.stringify(this.lastSavedData));
        this.handleWindowOnclick('reset');
        this.draftValues = [];
        return this.refresh();
    }

    handleEdit(event) {
        event.preventDefault();
        this.showSection = true;
        let dataRecieved = event.detail.data;
        this.handleWindowOnclick(dataRecieved.context);
        switch (dataRecieved.label) {
            case 'Account':
                this.setClassesOnData(
                    dataRecieved.context,
                    'accountNameClass',
                    'slds-cell-edit'
                );
                break;
            default:
                this.setClassesOnData(dataRecieved.context, '', '');
                break;
        };
    }

    updateDataValues(updateItem) {
        let copyData = JSON.parse(JSON.stringify(this.records));
        copyData.forEach((item) => {
            if (item.Id === updateItem.Id) {
                for (let field in updateItem) {
                    item[field] = updateItem[field];
                }
            }
        });
        this.records = [...copyData];
       
       
    }

    updateDraftValues(updateItem) {
        let draftValueChanged = false;
        let copyDraftValues = JSON.parse(JSON.stringify(this.draftValues));
        copyDraftValues.forEach((item) => {
            if (item.Id === updateItem.Id) {
                for (let field in updateItem) {
                    item[field] = updateItem[field];
                    
                }
                draftValueChanged = true;
            }
        });
        if (draftValueChanged) {
            this.draftValues = [...copyDraftValues];
        } else {
            this.draftValues = [...copyDraftValues, updateItem];
        }
    }

    setClassesOnData(id, fieldName, fieldValue) {
        this.records = JSON.parse(JSON.stringify(this.records));
        this.records.forEach((detail) => {
            if (detail.Id === id) {
                detail[fieldName] = fieldValue;
            }
        });
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
                        message: 'Selected Ambulance record(s) deleted successfully',
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
            }
            )
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

    handleSave(event){
        
        event.preventDefault();
        this.showSpinner = true;
        let saveRows = [];
        var el = this.template.querySelector('c-custom-data-table');
        var selected = el.getSelectedRows();
        saveRows = this.draftValues;

        for(var i =0; i < saveRows.length;i++){ 
               
                let index = this.draftValues.findIndex(e=>e.Id === saveRows[i].Id);
                if(index > -1 ){
                    if( saveRows[i].Cost_Include__c != this.draftValues[index].Cost_Include__c){
                        saveRows[i].Cost_Include__c = this.draftValues[index].Cost_Include__c;
                    }
                    if(saveRows[i].Cost_Review__c != this.draftValues[index].Cost_Review__c){
                        saveRows[i].Cost_Review__c = this.draftValues[index].Cost_Review__c;
                    }
                    if(saveRows[i].Date_of_Service__c != this.draftValues[index].Date_of_Service__c){
                        saveRows[i].Date_of_Service__c = this.draftValues[index].Date_of_Service__c;
                    }
                    if(saveRows[i].Location_Responded__c != this.draftValues[index].Location_Responded__c){
                        saveRows[i].Location_Responded__c = this.draftValues[index].Location_Responded__c;
                    }
                    if(saveRows[i].Facility__c != this.draftValues[index].Facility__c){
                        saveRows[i].Facility__c = this.draftValues[index].Facility__c;
                    }
                    if(saveRows[i].Basic_Amount__c != this.draftValues[index].Basic_Amount__c){
                        saveRows[i].Basic_Amount__c = this.draftValues[index].Basic_Amount__c;
                    }
                    if(saveRows[i].Total_Cost_Override__c != this.draftValues[index].Total_Cost_Override__c){
                        saveRows[i].Total_Cost_Override__c = this.draftValues[index].Total_Cost_Override__c;
                    }
                    if(saveRows[i].Fixed_Wing_Helicopter__c != this.draftValues[index].Fixed_Wing_Helicopter__c) {
                        saveRows[i].Fixed_Wing_Helicopter__c = this.draftValues[index].Fixed_Wing_Helicopter__c;
                    }
                    if(saveRows[i].Source_System_ID__c != this.draftValues[index].Source_System_ID__c) {
                        saveRows[i].Source_System_ID__c = this.draftValues[index].Source_System_ID__c;
                    }
                
        } 
  
        saveDraftValues({data: saveRows, recordDisplay: this.recordsToDisplay, recordType:'Ambulance'})
        .then((data,error) => {
            this.updateMessage = data.actionMessage;
  
            this.recordsToDisplay = data.updatedRecords;

            if(this.updateMessage){
                this.updateMessage = this.updateMessage.replace(/\r\n/g, "<br />");
                this.showErrorMessage = true;
            }
            
            if(data.passedResult == 'Passed'){
                this.showSection = false;
                this.draftValues = [];  
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'HealthCare Cost Ambulance record(s) updated successfully',
                        variant: 'success'
                    })
                );    
                             
            }
            else if(data.passedResult == 'Failed' || data.passedResult == null){
                this.showSection = false;
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
                this.showSection = false;
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
            return this.refresh();
            })
        }
            
    }
   
    handleRefresh(){
        this.onLoad();
    }
 
    
}