import { LightningElement, wire, api } from 'lwc';
import getHealthcareCostsAmbulanceForAccount from '@salesforce/apex/HCCCostController.getHealthcareCostsAmbulanceForAccount';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import COST_INCLUDE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Cost_Include__c';
import COST_REVIEW_FIELD from '@salesforce/schema/Healthcare_Cost__c.Cost_Review__c';
import COST_FIELD from '@salesforce/schema/Healthcare_Cost__c.Cost__c';
import BASIC_AMOUNT_FIELD from '@salesforce/schema/Healthcare_Cost__c.Basic_Amount__c';
import TOTAL_OVERRIDE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Total_Override__c';
import DATE_OF_SERVICE_FIELD from '@salesforce/schema/Healthcare_Cost__c.Date_of_Service__c';
import LOCATION_RESPONDED_FIELD from '@salesforce/schema/Healthcare_Cost__c.Location_Responded__c';
import saveDraftValues from '@salesforce/apex/HCCCostController.saveDraftValues';

const COLS = [
    {
        label: 'HealthCare Cost Number',
        fieldName: 'linkName',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'Name' },
            target: '_self'
        }
    },
    {
        label: 'Case Number',
        fieldName: 'Case__c',
        type: 'lookup',
        typeAttributes: {
            placeholder: 'Choose Case',
            object: 'Healthcare_Cost__c',
            fieldName: 'Case__c',
            label: 'CaseNumber',
            value: { fieldName: 'Case__c'},
            context:{fieldName: 'Id'},
            variant: 'label-hidden',
            name: 'Case',
            fields: ['Case.CaseNumber'],
            target: '_self'
        },
        cellAttributes:{
            class: { fieldName: 'CaseNumberClass'}
        }
    },
    {
        label: 'Cost Include',
        fieldName: COST_INCLUDE_FIELD.fieldApiName,
        type:'boolean',
        editable: false
    },
    {
        label: 'Cost Review',
        fieldName: COST_REVIEW_FIELD.fieldApiName,
        type:'boolean',
        editable:false
    },
    {
        label: 'Date of Service',
        fieldName: DATE_OF_SERVICE_FIELD.fieldApiName,
        type: 'date',
        editable: false
    },
    {
        label: 'Basic Amount',
        fieldName: BASIC_AMOUNT_FIELD.fieldApiName,
        type: 'currency',
        editable: false
    },
    {
        label: 'Location Responded',
        fieldName: LOCATION_RESPONDED_FIELD.fieldApiName,
        type: 'text',
        editable: false
    },
    {
        label: 'Cost',
        fieldName: COST_FIELD.fieldApiName,
        type: 'currency',
        editable: false
    },
    {
        label: 'Total Override',
        fieldName: TOTAL_OVERRIDE_FIELD.fieldApiName,
        type: 'currency',
        editable: false
    }
];

export default class AmbulanceRecordsAccount extends LightningElement {
    @api recordId;
    column = COLS;
    isFirstPage = true;
    isLastPage = false;
    CaseNumber;
    totalRecords = 0; //Total no.of records
    totalPages; //Total no.of pages
    pageNumber = 1; //Page number
    pageSizeOptions = [5, 10, 25, 50, 75, 100, 150, 200, 500]; //Page size options
    records = []; //All records available in the data table
    pageSize; //No.of records to be displayed per page
    recordsToDisplay = []; //Records to be displayed on the page
    showSpinner = false;
    lastSavedData;
    privateChildren = {}; //used to get the datatable lookup as private childern of customDatatable
    wiredRecords;
    draftValues = [];

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

    @wire(getHealthcareCostsAmbulanceForAccount, { accId: '$recordId' })
    wiredHealthcareCostsAmbulanceForAccount(result){
        this.wiredRecords = result;
        const {data, error} = result;
        
        if(data != null && data){
            console.log('Data of Ambulance Records --> ' + JSON.stringify(data));
            this.records = JSON.parse(JSON.stringify(data));
            this.records.forEach(record => {
                record.linkName = '/' + record.Id;
                record.CaseNumberClass = 'slds-cell-edit';
            })
            this.totalRecords = data.length;
            this.pageSize = this.pageSizeOptions[0]; 
            this.paginationHelper(); // call helper menthod to update pagination logic
            this.error = undefined;
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
    
      // Event to register the datatable lookup mark up.
      handleItemRegister(event) {
        event.stopPropagation(); //stops the window click to propagate to allow to register of markup.
        const item = event.detail;
        if (!this.privateChildren.hasOwnProperty(item.name))
            this.privateChildren[item.name] = {};
        this.privateChildren[item.name][item.guid] = item;
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
    
    handleChange(event) {
        event.preventDefault();
        console.log('Inside Handle Change ');
        this.Case__c = event.target.value;
        this.showSpinner = true;
      
    }

    handleCancel(event) {
        event.preventDefault();
        this.records = JSON.parse(JSON.stringify(this.lastSavedData));
        this.handleWindowOnclick('reset');
        this.draftValues = [];
    }

    handleCellChange(event) {
        event.preventDefault();
        this.updateDraftValues(event.detail.draftValues[0]);
        console.log(' Handle Cell Change');
    }

    //Captures the changed lookup value and updates the records list variable.
    handleValueChange(event) {
        event.stopPropagation();
        console.log('Handle Value Change');
        let dataRecieved = event.detail.data;
        let updatedItem;
        switch (dataRecieved.label) {
            case 'CaseNumber':
                updatedItem = {
                    Id: dataRecieved.context,
                    Case__c: dataRecieved.value
                };
                // Set the cell edit class to edited to mark it as value changed.
                this.setClassesOnData(
                    dataRecieved.context,
                    'CaseNumberClass',
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

    handleEdit(event) {
        event.preventDefault();
        let dataRecieved = event.detail.data;
        this.handleWindowOnclick(dataRecieved.context);
        switch (dataRecieved.label) {
            case 'CaseNumber':
                this.setClassesOnData(
                    dataRecieved.context,
                    'CaseNumberClass',
                    'slds-cell-edit'
                );
                break;
            default:
                this.setClassesOnData(dataRecieved.context, '', '');
                break;
        };
        console.log('Inside handle edit method');
    }

    setClassesOnData(id, fieldName, fieldValue) {
        this.records = JSON.parse(JSON.stringify(this.records));
        this.records.forEach((detail) => {
            if (detail.Id === id) {
                detail[fieldName] = fieldValue;
            }
        });
    }
    
    handleSave(event) {
        event.preventDefault();
        this.showSpinner = true;
        // Update the draftvalues
        saveDraftValues({ data: this.draftValues })
            .then(() => {
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
                        record.CaseNumberClass = 'slds-cell-edit';
                    });
                    this.draftValues = [];
                });
            })
            .catch(error => {
                console.log('error : ' + JSON.stringify(error));
                this.showSpinner = false;
            });
    }

}