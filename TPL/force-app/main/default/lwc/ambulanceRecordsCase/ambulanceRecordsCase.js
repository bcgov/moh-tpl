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
import HC_COST_NUMBER_FIELD from '@salesforce/schema/Healthcare_Cost__c.Name';
import FACILITY_NAME_FIELD from '@salesforce/schema/Healthcare_Cost__c.Facility__c';
import FIXED_WING_HELICOPTER_FIELD from '@salesforce/schema/Healthcare_Cost__c.Fixed_Wing_Helicopter__c';
import SOURCE_SYSTEM_ID_FIELD from '@salesforce/schema/Healthcare_Cost__c.Source_System_ID__c';
import COST_FIELD from '@salesforce/schema/Healthcare_Cost__c.Cost__c';
import SUB_TOTAL_FIELD from '@salesforce/schema/Healthcare_Cost__c.Sub_Total__c';
import getHealthcareCostsAmbulanceForCase from '@salesforce/apex/HCCCostAmbulanceRecord.getHealthcareCostsAmbulanceForCase';
import saveDraftValues from '@salesforce/apex/HCCCostController.saveDraftValues'; 
import updateCostInformation from '@salesforce/apex/HCCCostAmbulanceRecord.updateCostInformation';
const COLUMNS = [
    {
        label:'ID',
        fieldName:HC_COST_NUMBER_FIELD.fieldApiName,
        sortable: true,
        editable: false
    },
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
        type: 'text',
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
        editable: true
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
export default class AmbulanceRecordsCase extends LightningElement {
    @api recordId;
    column = COLUMNS;
    records = []; //All records available in the data table
    isFirstPage = true;
    isLastPage = false;
    totalRecords = 0; //Total no.of records
    totalPages; //Total no.of pages
    pageNumber = 1; //Page number
    pageSizeOptions = [5, 10, 25, 50, 75, 100]; //Page size options
    pageSize; //No.of records to be displayed per page
    recordsToDisplay = []; //Records to be displayed on the page
    wiredRecords;
    selectedRows = [];
    event2;
    costInclude = false;
    costReview = false;
    @api groupNumbers = ["All", "Manual Records"];
    showSpinner = false;
    lastSavedData;
    privateChildren = {}; //used to get the datatable lookup as private childern of customDatatable
    wiredRecords;
    draftValues = [];

    connectedCallback() {
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

    @wire(getHealthcareCostsAmbulanceForCase, { caseId: '$recordId' })
    healthcareCostsAmbulanceForCase(result){
        this.wiredRecords = result;
        const {data, error} = result;

        if(data != null && data){
            console.log('Data of Ambulance Records --> ' + JSON.stringify(data));
            this.records = JSON.parse(JSON.stringify(data));
            this.records.forEach(record =>{
                record.accountNameClass = 'slds-cell-edit';
            })
            this.totalRecords = data.length;
            this.pageSize = this.pageSizeOptions[0]; 
            this.paginationHelper(); // call helper menthod to update pagination logic
        }
        else if(error){
            console.error(error);
        }
        else if (error) {
            this.records = undefined;
            this.error = error;
        } else {
            this.error = undefined;
            this.records = undefined;
        }
        this.lastSavedData = this.records;
        this.showSpinner = false;
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
        await refreshApex(this.wiredRecords);
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

    handleCellChange(event) {
        event.preventDefault();
        this.updateDraftValues(event.detail.draftValues[0]);
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

    setClassesOnData(id, fieldName, fieldValue) {
        this.records = JSON.parse(JSON.stringify(this.records));
        this.records.forEach((detail) => {
            if (detail.Id === id) {
                detail[fieldName] = fieldValue;
            }
        });
    }

    handleCostInclude(event){
        this.costInclude = event.target.checked;
        console.log('Cost Include : ' + this.costInclude);
    }
    
    handleCostReview(event){
        this.costReview = event.target.checked;    
        console.log('Cost Review : ' + this.costReview);
    }

    handleRowSelection(event){
        this.selectedRows = event.detail.selectedRows;
    }

    async handleSelect(){
       // var el = this.template.querySelector('c-custom-data-table');
      //  console.log(el);
    //    var selected = el.getSelectedRows();
        //console.log(selected);
        console.log('selectedRows : ' + JSON.stringify(this.selectedRows));
      //  console.log('HandleSelect : ' + JSON.stringify(selected));

      let selectedCostRecords = [];
        
      this.selectedRows.forEach(function(element){
      selectedCostRecords.push(element);
         console.log(element);   
      });

      await updateCostInformation({ hccList: selectedCostRecords, costReviewValue: this.costReview, costIncludeValue: this.costInclude})
      .then(result => {
        console.log("Result : " + result);
        if(result == 'Failed'){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please ensure Cost Review or Cost Include are checked for the Ambulance Healthcare Cost record(s) you want to assign a case.',
                    variant: 'error'
                })
            );
        }
        else if(result == 'Passed'){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Cost Values assigned to Ambulance HealthCare Cost record(s) updated successfully.',
                    variant: 'success'
                })
            );    
        }
        else if(result == 'Empty Selection'){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select Cost Values and HCC Records to assign.',
                    variant: 'error'
                })
            );
        }
        else if(result == null){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Cost value assignment did not succeed. Please try again!',
                    variant: 'error'
                })
            ); 
        }
        //Get the updated list with refreshApex.
        return this.refresh();
       
      })
      .catch(error =>{
        console.log(JSON.stringify(error));
      })
    }

     async handleSave(event){
        console.log('Draft values to save : ' + JSON.stringify(event.detail.draftValues));
        await saveDraftValues({data: event.detail.draftValues})
        .then((result) => {
            console.log("result : " + result);
        // Clear all datatable draft values
            //this.draftValues = [];
                console.log('Result : ' + result);
               if(result == 'Passed'){
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
                this.draftValues = [];
                });    
                }
                else if(result == 'Failed' || result == null){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Record not saved successfully! Please check Healthcare Cost Ambulance record(s) while updating. Integration records cannot be modified',
                            variant: 'error'
                        })
                    );   
                //Get the updated list with refreshApex.
                this.draftValues = [];
                this.refresh();
               
                   
            }      
            })
            .catch(error => {
                console.log('error : ' + JSON.stringify(error));
            });
        
    }
    
}