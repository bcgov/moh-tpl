import { LightningElement, wire, api, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getHealthcareCostsAmbulanceForCase from '@salesforce/apex/HCCostCaseController.getHealthcareCostsAmbulanceForCase';
import saveDraftValues from '@salesforce/apex/HCCCostController.saveDraftValues'; 
import deleteHCCRecord from '@salesforce/apex/HCCCostController.deleteHCCRecord';

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
        editable: false,
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
        editable: false,
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
                console.log('Ambulance List :' + JSON.stringify(result.hccList));
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
        
                console.log("Records to display : " + JSON.stringify(this.recordsToDisplay));
                console.log('Total Count : ' + result.totalCount);
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
            console.log(error);
            this.records = []
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
    
     // Event to register the datatable lookup mark up.
     handleItemRegister(event) {
        event.stopPropagation(); //stops the window click to propagate to allow to register of markup.
        const item = event.detail;
        console.log('Handle Item Register');
        if (!this.privateChildren.hasOwnProperty(item.name))
            this.privateChildren[item.name] = {};
        this.privateChildren[item.name][item.guid] = item;
    }

      //Captures the changed lookup value and updates the records list variable.
      handleValueChange(event) {
        event.stopPropagation();
        let dataRecieved = event.detail.data;
        let updatedItem;
       
        console.log('Line 368 handle value change' + JSON.stringify(dataRecieved.value));
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
                console.log('At 376');
                this.setClassesOnData(
                    dataRecieved.context,
                    'accountNameClass',
                    'slds-cell-edit slds-is-edited'
                );
                break;
            default:
                this.setClassesOnData(dataRecieved.context, '', '');
                console.log('At 384' + JSON.stringify(this.draftValues));
                break;
        }
        this.updateDraftValues(updatedItem);
       // this.updateDataValues(updatedItem);
    }
    handleCellChange(event){
        console.log(JSON.stringify(event)+'---- '+JSON.stringify(this.draftValues));
        console.log( this.draftValues.findIndex(e=>e.Id === event.detail.draftValues[0].Id));
        for(let i = 0 ; i < event.detail.draftValues.length;i++){
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
                if(event.detail.draftValues[i].Site_Code__c){
                    this.draftValues[index].Site_Code__c = event.detail.draftValues[i].Site_Code__c;
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
        
                console.log(JSON.stringify(this.draftValues[i]));
            }else{
                var obj ={
                    Id : event.detail.draftValues[i].Id,
                    Cost_Review__c:event.detail.draftValues[i].Cost_Review__c,
                    Cost_Include__c:event.detail.draftValues[i].Cost_Include__c,
                    Date_of_Service__c:event.detail.draftValues[i].Date_of_Service__c,
                    Location_Responded__c:event.detail.draftValues[i].Location_Responded__c,
                    Site_Code__c:event.detail.draftValues[i].Site_Code__c,
                    Basic_Amount__c:event.detail.draftValues[i].Basic_Amount__c,
                    Total_Cost_Override__c:event.detail.draftValues[i].Total_Cost_Override__c,
                    Fixed_Wing_Helicopter__c:event.detail.draftValues[i].Fixed_Wing_Helicopter__c,
                };
                console.log('before in');
              
                console.log(JSON.stringify(obj));
                this.draftValues.push(obj);
            }
            
        }
    }

    handleChange(event) {
        event.preventDefault();
        console.log('Inside Handle Change ');
        this.Facility__c = event.target.value;
        this.showSpinner = true;
      
    }

    handleCancel(event) {
        event.preventDefault();
        this.records = JSON.parse(JSON.stringify(this.lastSavedData));
        console.log('Inside handle cancel');
        this.handleWindowOnclick('reset');
        this.draftValues = [];
        return this.refresh();
    }

      handleEdit(event) {
        event.preventDefault();
        let dataRecieved = event.detail.data;
        console.log('Handle edit draft values : ' + JSON.stringify(this.draftValues));
        this.handleWindowOnclick(dataRecieved.context);
        console.log('At 412  handle edit:' + JSON.stringify(event.detail.data));
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
        console.log('Updated data values log' );
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
        console.log('draft'+JSON.stringify(this.draftValues));
        let draftValueChanged = false;
        let copyDraftValues = JSON.parse(JSON.stringify(this.draftValues));
        console.log('At 442 ' + JSON.stringify(updateItem));
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
        console.log('Update Draft values' + JSON.stringify(this.draftValues));
        console.log('Update Draft values' + JSON.stringify(this.recordsToDisplay));
    }

    setClassesOnData(id, fieldName, fieldValue) {
        console.log('Set classes on data');
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
        event.preventDefault();
        this.showSpinner = true;
        var el = this.template.querySelector('c-custom-data-table');
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
               
                let index = this.draftValues.findIndex(e=>e.Id === selected[i].Id);
                if(index > -1 ){
                    if( selected[i].Cost_Include__c != this.draftValues[index].Cost_Include__c){
                        selected[i].Cost_Include__c = this.draftValues[index].Cost_Include__c;
                    }
                    if(selected[i].Cost_Review__c != this.draftValues[index].Cost_Review__c){
                        selected[i].Cost_Review__c = this.draftValues[index].Cost_Review__c;
                    }
                    if(selected[i].Date_of_Service__c != this.draftValues[index].Date_of_Service__c){
                        selected[i].Date_of_Service__c = this.draftValues[index].Date_of_Service__c;
                    }
                    if(selected[i].Location_Responded__c != this.draftValues[index].Location_Responded__c){
                        selected[i].Location_Responded__c = this.draftValues[index].Location_Responded__c;
                    }
                    if(selected[i].Facility__c != this.draftValues[index].Facility__c){
                        selected[i].Facility__c = this.draftValues[index].Facility__c;
                    }
                    if(selected[i].Basic_Amount__c != this.draftValues[index].Basic_Amount__c){
                        selected[i].Basic_Amount__c = this.draftValues[index].Basic_Amount__c;
                    }
                    if(selected[i].Total_Cost_Override__c != this.draftValues[index].Total_Cost_Override__c){
                        selected[i].Total_Cost_Override__c = this.draftValues[index].Total_Cost_Override__c;
                    }
                    if(selected[i].Fixed_Wing_Helicopter__c != this.draftValues[index].Fixed_Wing_Helicopter__c) {
                        selected[i].Fixed_Wing_Helicopter__c = this.draftValues[index].Fixed_Wing_Helicopter__c;
                    }
                    if(selected[i].Source_System_ID__c != this.draftValues[index].Source_System_ID__c) {
                        selected[i].Source_System_ID__c = this.draftValues[index].Source_System_ID__c;
                    }
                }
            } 
        
        saveDraftValues({data: selected, recordDisplay: this.recordsToDisplay})
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
                        message: 'HealthCare Cost Ambulance record(s) updated successfully',
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
            return this.refresh();
            })
        }
            
    }
    handleSuccess(){
        if(this.recordId !== null){
            this.dispatchEvent(new ShowToastEvent({
                    title: "SUCCESS!",
                    message: "New record has been created.",
                   variant: "success",
                }),  
           );    
         }
       //  this.onLoad();
         this.onLoad();
    }
   
    handleRefresh(){
        this.onLoad();
    }
 
    
}