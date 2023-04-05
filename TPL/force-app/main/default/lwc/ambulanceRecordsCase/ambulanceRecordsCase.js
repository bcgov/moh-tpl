import { LightningElement, wire, api, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getHealthcareCostsAmbulanceForCase from '@salesforce/apex/HCCCostAmbulanceRecord.getHealthcareCostsAmbulanceForCase';
import saveDraftValues from '@salesforce/apex/HCCCostController.saveDraftValues'; 
import deleteHCCRecord from '@salesforce/apex/HCCCostController.deleteHCCRecord';
import getAmbulanceCountonCase from '@salesforce/apex/HCCCostAmbulanceRecord.getAmbulanceCountonCase';

const MANNUAL_COLUMNS = [
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
    recordsCount = 0; //Total count of records
    totalPages; //Total no.of pages
    pageNumber = 1; //Page number
    pageSizeOptions = [5, 10, 25, 50, 75, 100]; //Page size options
    pageSize; //No.of records to be displayed per page
    recordsToDisplay = []; //Records to be displayed on the page
    hideDeleteButton = true;
    limitValue = 0;
    offsetValue = 0;
    recordsCount = 0; //Total count of records
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
        this.limitValue = 5;
        this.offsetValue = 0;
        this.hideDeleteButton = true;
        this.pageSize = this.pageSizeOptions[0]; 
        this.pageNumber = 1;
        this.loadCount();
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

    loadCount()
    {
        return getAmbulanceCountonCase({caseId: this.recordId, filterValue: this.selectedFilter})
        .then(result =>{
            console.log('Result : ' + result);
            if(result == 0 || (result != null && result)){
                this.recordsCount = result;
                console.log('Records Count :' + this.recordsCount);
            }
            this.onLoad();
        })
        .catch(error =>{
            console.log(error);
            this.recordsCount = 0;
        });
       
    } 
    onLoad(){
        return getHealthcareCostsAmbulanceForCase({caseId: this.recordId, filterValue: this.selectedFilter, limitSize: this.limitValue, offsetSize: this.offsetValue})
        .then(result=>{
            this.wiredRecords = result;
            if(result != null && result){
                console.log(result.length);
                console.log('Data of Ambulance Records --> ' + JSON.stringify(result));
                this.records = JSON.parse(JSON.stringify(result));
                this.records.forEach(record =>{
                    record.accountNameClass = 'slds-cell-edit';
                })
                this.totalRecords = result.length;
                this.paginationHelper(); // call helper menthod to update pagination logic
            }

            this.lastSavedData = this.records;
            this.showSpinner = false;
        })
        .catch(error =>{
            console.log(error); 
        });
    }

    get bDisableFirst() {
        return this.pageNumber == 1;
    }
    get bDisableLast() {
        return this.pageNumber == this.totalPages;
    }
    
    handleFilterChange(event) {
        this.selectedFilter = event.target.value;
        console.log('Selected Filter Value : ' + this.selectedFilter);
        
        if(this.selectedFilter == 'Manual Records')
        {
            this.hideDeleteButton = false;
            this.column = MANNUAL_COLUMNS;    
        }
        else if(this.selectedFilter == 'Records Created Today'){
            this.hideDeleteButton = false;
            this.column = MANNUAL_COLUMNS;  
            console.log('Inside records created today');
        }
        else{
            this.hideDeleteButton = true;
            this.column = INTEGRATION_COLUMNS;
        }
        
        this.pageNumber = 1;
        this.calculateLimitAndOffset();
        this.loadCount();
        console.log(this.selectedFilter + ' ' + this.recordsCount);
       // this.onLoad();
    }

    handleRecordsPerPage(event) {
        this.pageSize = event.target.value;
       // this.paginationHelper();
        this.pageNumber = 1;
        this.calculateLimitAndOffset();
        this.onLoad();
    }
    previousPage() {
        this.pageNumber = this.pageNumber - 1;
        this.calculateLimitAndOffset();
        this.onLoad();
        //  this.paginationHelper();
    }
    nextPage() {
        this.pageNumber = this.pageNumber + 1;
        this.calculateLimitAndOffset();
        this.onLoad();
        //  this.paginationHelper();
    }
    firstPage() {
        this.pageNumber = 1;
        this.calculateLimitAndOffset();
        this.onLoad();
      //  this.paginationHelper();
    }
    lastPage() {
        this.pageNumber = this.totalPages;
        this.calculateLimitAndOffset();
        this.onLoad();
        //  this.paginationHelper();
    }

    calculateLimitAndOffset(){
        this.limitValue = this.pageSize;
        if(this.pageSize > this.recordsCount){
            this.offsetValue = 0;
        }
        else{
            this.offsetValue = (this.pageNumber - 1) * this.pageSize
        }
    }
        // JS function to handel pagination logic 
    paginationHelper() {
        this.recordsToDisplay = [];
        // calculate total pages
        console.log('Inside Pagination Helper');
        this.totalPages = Math.ceil(this.recordsCount / this.pageSize);
        // set page number 
        if (this.pageNumber <= 1) {
            this.pageNumber = 1;
        } else if (this.pageNumber >= this.totalPages) {
            this.pageNumber = this.totalPages;
        }
        console.log('Page Number : ' + this.pageNumber + ', Page Size : ' + this.pageSize + ', Records Count :' + this.recordsCount);
        // set records to display on current page 
       /* for (let i = (this.pageNumber - 1) * this.pageSize; i < this.pageNumber * this.pageSize; i++) {
            if (i === this.totalRecords) {
                break;
            }
            this.recordsToDisplay.push(this.records[i]);
        } */
        for(let i=0;i<this.records.length;i++){
            if(i=== this.recordsCount){
                break;
            }
            console.log('inside for');
            this.recordsToDisplay.push(this.records[i]);
        }
        console.log('Records Display : ' + JSON.stringify(this.recordsToDisplay));
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
       
        console.log('Line 368 handle value change' + JSON.stringify(dataRecieved));
        switch (dataRecieved.label) {
            case 'Account':
                updatedItem = {
                    Id: dataRecieved.context,
                    Facility__c: dataRecieved.value
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
        this.updateDataValues(updatedItem);
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
                if(event.detail.draftValues[i].Source_System_ID__c){
                    this.draftValues[index].Source_System_ID__c = event.detail.draftValues[i].Source_System_ID__c;
                }
                if(event.detail.draftValues[i].Location_Responded__c){
                    this.draftValues[index].Location_Responded__c = event.detail.draftValues[i].Location_Responded__c;
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
                    Source_System_ID__c:event.detail.draftValues[i].Source_System_ID__c,
                    Location_Responded__c:event.detail.draftValues[i].Location_Responded__c
                };
                console.log('before in');
              
                console.log(JSON.stringify(obj));
                this.draftValues.push(obj);
            }
            
        }
       /* updateItem ={
            
        }
        copyDraftValues.forEach((item) => {
            if (item.Id === updateItem.Id) {
                for (let field in updateItem) {
                    item[field] = updateItem[field];
                }
                draftValueChanged = true;
            }
        });*/
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

  /*handleCellChange(event) {
        event.preventDefault();
        var el = this.template.querySelector('c-custom-data-table');
        console.log(el);
        var selected = el.getSelectedRows();
        console.log(JSON.stringify(selected));
        console.log('Event Detail : ' + JSON.stringify(event.detail));
        for(var i=0; i<selected.length;i++){
         }
        console.log('Handle cell change :' + JSON.stringify(event.detail.draftValues[0]));
        this.updateDraftValues(event.detail.draftValues);
    } 
 */
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
                this.loadCount();
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
                 
                    if(event.detail.draftValues[j].Location_Responded__c != undefined || event.detail.draftValues[j].Location_Responded__c == ''){
                       
                        if(selected[i].Location_Responded__c != event.detail.draftValues[j].Location_Responded__c){
                           selected[i].Location_Responded__c = event.detail.draftValues[j].Location_Responded__c;
                        }
                       
                    }
                   
                    if(event.detail.draftValues[j].Facility__c != undefined || event.detail.draftValues[j].Facility__c == null){
                        if(selected[i].Facility__c != event.detail.draftValues[j].Facility__c){
                            selected[i].Facility__c = event.detail.draftValues[j].Facility__c;
                        }
                       
                    }
                  
                    if(event.detail.draftValues[j].Total_Cost_Override__c != undefined || event.detail.draftValues[j].Total_Cost_Override__c == null){
                        if(selected[i].Total_Cost_Override__c != event.detail.draftValues[j].Total_Cost_Override__c){
                           selected[i].Total_Cost_Override__c = event.detail.draftValues[j].Total_Cost_Override__c;    
                        }
                    }
                
                    if(event.detail.draftValues[j].Fixed_Wing_Helicopter__c != undefined || event.detail.draftValues[j].Fixed_Wing_Helicopter__c == null){
                        if( selected[i].Fixed_Wing_Helicopter__c != event.detail.draftValues[j].Fixed_Wing_Helicopter__c){
                           selected[i].Fixed_Wing_Helicopter__c = event.detail.draftValues[j].Fixed_Wing_Helicopter__c;
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
         this.loadCount();
    }
   
    handleRefresh(){
        this.loadCount();
    }
   /* handleSubmit(event){
        event.preventDefault();
        const fields = event.detail.fields;
        fields.Case2__c = this.caseId;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
        console.log(JSON.stringify(event.detail));
    } */
    
}