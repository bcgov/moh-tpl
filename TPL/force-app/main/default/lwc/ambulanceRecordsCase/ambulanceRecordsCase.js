/* eslint-disable guard-for-in */
/* eslint-disable no-prototype-builtins */
import { LightningElement, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import COST_INCLUDE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Cost_Include__c';
import COST_REVIEW_FIELD from '@salesforce/schema/Healthcare_Cost__c.Cost_Review__c';
import BASIC_AMOUNT_FIELD from '@salesforce/schema/Healthcare_Cost__c.Basic_Amount__c';
import TOTAL_COST_OVERRIDE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Total_Cost_Override__c';
import DATE_OF_SERVICE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Date_of_Service__c';
import LOCATION_RESPONDED_FIELD from '@salesforce/schema/Healthcare_Cost__c.Location_Responded__c';
import SITE_CODE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Site_Code__c';
import FACILITY_FIELD from '@salesforce/schema/Healthcare_Cost__c.Facility__c';
import FACILITY_NAME_FIELD from '@salesforce/schema/Healthcare_Cost__c.FacilityName__c';
import FIXED_WING_HELICOPTER_FIELD from '@salesforce/schema/Healthcare_Cost__c.Fixed_Wing_Helicopter__c';
import SOURCE_SYSTEM_ID_FIELD from '@salesforce/schema/Healthcare_Cost__c.Source_System_ID__c';
import COST_FIELD from '@salesforce/schema/Healthcare_Cost__c.Cost__c';
import SUB_TOTAL_FIELD from '@salesforce/schema/Healthcare_Cost__c.Sub_Total__c';
import getHealthcareCostsAmbulanceForCase from '@salesforce/apex/HCCCostAmbulanceRecord.getHealthcareCostsAmbulanceForCase';
import saveDraftValues from '@salesforce/apex/HCCCostController.saveDraftValues'; 
import deleteAmbulanceRecords from '@salesforce/apex/HCCCostAmbulanceRecord.deleteAmbulanceRecords';

const MANNUAL_COLUMNS = [
    {
        label: 'Cost Include',
        fieldName: COST_INCLUDE_FIELD.fieldApiName,
        type:'boolean',
        sortable: true,
        editable: true
    },
    {
        label: 'Cost Review',
        fieldName: COST_REVIEW_FIELD.fieldApiName,
        type:'boolean',
        sortable: true,
        editable:true
    },
    {
        label: 'Date of Service',
        fieldName: DATE_OF_SERVICE_FIELD.fieldApiName,
        sortable: true,
        editable: true
    }, 
    {
        label: 'Location Responded',
        fieldName: LOCATION_RESPONDED_FIELD.fieldApiName,
        editable: true,
        sortable:true
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
        fieldName: BASIC_AMOUNT_FIELD.fieldApiName,
        type: 'currency',
        sortable: true,
        editable: false
    },
    {
        label: 'Total Cost Override',
        fieldName: TOTAL_COST_OVERRIDE_FIELD.fieldApiName,
        type: 'currency',
        sortable: true,
        editable: true
    },
    {
        label: 'Fixed Wing/Helicopter',
        fieldName: FIXED_WING_HELICOPTER_FIELD.fieldApiName,
        type: 'currency',
        editable: true,
        sortable: false
    },
    {
        label: 'Source System ID',
        fieldName: SOURCE_SYSTEM_ID_FIELD.fieldApiName,
        type: 'text',
        editable: true,
        sortable: true
    }
    
];

const INTEGRATION_COLUMNS = [
    {
        label: 'Cost Include',
        fieldName: COST_INCLUDE_FIELD.fieldApiName,
        type:'boolean',
        sortable: true,
        editable: true
    },
    {
        label: 'Cost Review',
        fieldName: COST_REVIEW_FIELD.fieldApiName,
        type:'boolean',
        sortable: true,
        editable:true
    },
    {
        label: 'Date of Service',
        fieldName: DATE_OF_SERVICE_FIELD.fieldApiName,
        sortable: true,
        editable: false
    }, 
    {
        label: 'Location Responded',
        fieldName: LOCATION_RESPONDED_FIELD.fieldApiName,
        type: 'text',
        editable: false,
        sortable:false
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
        editable: false,
        sortable: true
    },
    {
        label: 'Basic Amount',
        fieldName: BASIC_AMOUNT_FIELD.fieldApiName,
        type: 'currency',
        sortable: true,
        editable: false
    },
    {
        label: 'Total Cost Override',
        fieldName: TOTAL_COST_OVERRIDE_FIELD.fieldApiName,
        type: 'currency',
        sortable: true,
        editable: true
    },
    {
        label: 'Fixed Wing/Helicopter',
        fieldName: FIXED_WING_HELICOPTER_FIELD.fieldApiName,
        type: 'currency',
        editable: false,
        sortable: false
    },
    {
        label: 'Source System ID',
        fieldName: SOURCE_SYSTEM_ID_FIELD.fieldApiName,
        type: 'text',
        editable: true,
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
    selectedRows = [];
    event2;
    costInclude = false;
    costReview = false;
    showSpinner = false;
    lastSavedData;
    privateChildren = {}; //used to get the datatable lookup as private childern of customDatatable
    wiredRecords;
    draftValues = [];
    selectedFilter= 'All Records';
    filterOptions = [
        { label: 'All Records', value: 'All Records' },
        { label: 'Manual Records', value: 'Manual Records' },
    ];

    connectedCallback() {
        this.selectedFilter = 'All Records';
        this.pageSize = this.pageSizeOptions[0]; 
        this.onLoad();
        this.event2 = setInterval(() => {
            this.refresh();
        }, 100);
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
        return getHealthcareCostsAmbulanceForCase({caseId: this.recordId, filterValue: this.selectedFilter})
        .then(result=>{
            this.wiredRecords = result;
            if(result != null && result){
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
            this.column = MANNUAL_COLUMNS;
        }
        else{
            this.column = INTEGRATION_COLUMNS;
        }
        this.onLoad();
        return this.refresh();
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
        
        switch (dataRecieved.label) {
            case 'Account':
                updatedItem = {
                    Id: dataRecieved.context,
                    Facility__c: dataRecieved.value
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
        this.updateDataValues(updatedItem);
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
        this.handleWindowOnclick('reset');
        this.draftValues = [];
        return this.refresh();
    }

    handleEdit(event) {
        event.preventDefault();
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
        console.log('Updated data values log');
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
        console.log('Update Draft values');
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
        await deleteAmbulanceRecords({deletionRecords: selectedCostRecords, filterOption: this.selectedFilter})
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
                        message: 'Only Manual Records can be deleted. Please select Manual records for deletion.',
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

    async handleSave(event){
        event.preventDefault();
        this.showSpinner = true;
        console.log(JSON.stringify(event.detail.draftValues));
        await saveDraftValues({data: event.detail.draftValues})
        .then((result) => {
            console.log("result : " + result);
            if(result == 'Passed'){
                this.draftValues = [];   
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'HealthCare Cost Ambulance record(s) updated successfully',
                        variant: 'success'
                    })
                );    
                
                //Get the updated list with refreshApex.
                refreshApex(this.wiredRecords).then(() => {
                this.records.forEach(record => {
                    record.accountNameClass = 'slds-cell-edit';
                });  
                    
                });    
                }
                else if(result == 'Failed' || result == null){
                    this.draftValues = [];   
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Record not saved successfully! Please check Healthcare Cost Ambulance record(s) while updating. Integration records cannot be modified',
                            variant: 'error'
                        })
                    );   
            }    
            return this.refresh();
            })
            .catch(error => {
                console.log('error : ' + JSON.stringify(error));
                this.showSpinner = false;
            });
            
    }
    
}