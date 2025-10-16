import { LightningElement, wire, api, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getHealthcareCostsAmbulanceForCase from '@salesforce/apex/HCCostCaseController.getHealthcareCostsAmbulanceForCase';
import getHealthcareCostsAmbulanceForCaseSorted from '@salesforce/apex/HCCostCaseController.getHealthcareCostsAmbulanceForCaseSorted';
import saveDraftValues from '@salesforce/apex/HCCCostController.saveDraftValues'; 
import deleteHCCRecord from '@salesforce/apex/HCCCostController.deleteHCCRecord';
import getFacilityBySiteCode from '@salesforce/apex/HCCCostController.getFacilityBySiteCode';
import updateAll from '@salesforce/apex/HCCCostController.updateAll';
import findIfUnderUpdate from '@salesforce/apex/HCCCostController.findIfUnderUpdate';
import userId from '@salesforce/user/Id';

const MANUAL_COLUMNS = [
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
        editable: true
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
        editable: true
    },
    {
        label: 'Facility Code',
        fieldName: 'Site_Code__c',
        type: 'text',
        editable: false
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
        }
       
    },
    {
        label: 'Basic Amount',
        fieldName: 'Basic_Amount__c',
        type: 'currency',
        editable: false
    },
    {
        label: 'Total Cost Override',
        fieldName: 'Total_Cost_Override__c',
        type: 'currency',
        editable: true
    },
    {
        label: 'Fixed Wing/Helicopter',
        fieldName: 'Fixed_Wing_Helicopter__c',
        type: 'currency',
        editable: true
    },
    {
        label: 'Source System ID',
        fieldName: 'Source_System_ID__c',
        type: 'text',
        editable: false
    }
];

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
        editable: true
    },
    {
        label: 'Date of Service',
        fieldName: 'Date_of_Service__c',
        type:'date-local',
        typeAttributes:{ 
            day: "2-digit",
            month: "2-digit",
            year: "numeric"},
        editable: false,
        sortable: true
    },
    {
        label: 'Location Responded',
        fieldName: 'Location_Responded__c',
        type: 'text',
        editable: false
    },
    {
        label: 'Facility Code',
        fieldName: 'Site_Code__c',
        type: 'text',
        editable: false
    },
    {
        label: 'Facility',
        fieldName:'FacilityName__c',
        type: 'text',
        editable: false
    },
    {
        label: 'Basic Amount',
        fieldName: 'Basic_Amount__c',
        type: 'currency',
        editable: false
    },
    {
        label: 'Total Cost Override',
        fieldName: 'Total_Cost_Override__c',
        type: 'currency',
        editable: true
    },
    {
        label: 'Fixed Wing Helicopter',
        fieldName: 'Fixed_Wing_Helicopter__c',
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
export default class AmbulanceRecordsCase extends LightningElement {
    @api recordId;
    column = INTEGRATION_COLUMNS;
    records = []; //All records available in the data table
    isFirstPage = true;
    isLastPage = false;
    sortSelection = 'asc';
    totalRecords = 0; //Total no.of records
    totalPages; //Total no.of pages
    pageNumber = 1; //Page number
    pageSizeOptions = [25, 50, 75, 100]; //Page size options
    pageSize; //No.of records to be displayed per page
    recordsToDisplay = []; //Records to be displayed on the page
    hideDeleteButton = true;
    showSpinner = false;
    lastSavedData;
    privateChildren = {}; //used to get the datatable lookup as private childern of customDatatable
    wiredRecords;
    draftValues = [];
    // for partial success
    editedFieldKeys = new Set();
    successfullyUpdatedFields = new Set();
    showErrorMessage = false;
    updateMessage='';
    selectedFilter= 'All Records';
   // showModal = false;
   // modalAction = null;
    showSection = false;
    showMassUpdateSection = false;
    costReview = false;
    costInclude = false;
    updateHappening = false;
    updateTriggered = false;
    
    filterOptions = [
        { label: 'All Records', value: 'All Records' },
        { label: 'Manual Records', value: 'Manual Records' },
        { label: 'Records Created Today', value: 'Records Created Today' }
    ];
    errorFields = [];
    
    getCellClass(rowIndex, fieldName) {
        const recordId = this.recordsToDisplay[rowIndex]?.Id;
        const key = `${recordId}.${fieldName}`;
        return this.editedFieldKeys.has(key) ? 'error-cell' : '';
    }

    connectedCallback() {
        this.selectedFilter = 'All Records';
        this.sortSelection = 'asc';
        this.hideDeleteButton = true;
        this.pageSize = this.pageSizeOptions[0]; 
        this.pageNumber = 1;
        this.onLoad();
        this.checkIfUnderUpdate();
       
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
        return getHealthcareCostsAmbulanceForCase({
            caseId: this.recordId, 
            filterValue: this.selectedFilter, 
            pageSize: this.pageSize, 
            pageNumber: this.pageNumber, 
            sortOrder: this.sortSelection})
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
    handleMassUpdate(){
       if(this.showMassUpdateSection){
            this.showMassUpdateSection = false;
       }else{
            this.showMassUpdateSection = true;
       }
    }
    get bDisableFirst() {
        return this.pageNumber == 1;
    }
    get bDisableLast() {
        return this.pageNumber == this.totalPages;
    }
    changeCostReview(event){
        this.costReview = event.target.checked;
        
    }
    changeCostInclude(event){
        this.costInclude = event.target.checked;
        
    }
    checkIfUnderUpdate(){
            findIfUnderUpdate({userId:userId})
            .then(result=>{
                this.updateHappening = result;
                this.showMassUpdateSection = !result;
                if(result){
                   setTimeout(() => { this.checkIfUnderUpdate();}, 5000);     
                }
            })
            .catch(error=>{
                console.log(error);
            });
        
        
    }
    // Made changes to updateAll so that whenever we click on the Go button it should uncheck the checkboxes of CostInclude and/or CostReview if checked
    updateAll() {
        this.checkIfUnderUpdate();
    
        if (!this.updateHappening) {
            this.updateTriggered = true;
    
            let updateCostInclude = this.costInclude;
            let updateCostReview = this.costReview;
    
            let updatedRecords = this.recordsToDisplay.map(record => {
                let updateNeeded = false;
                let updatedRecord = { Id: record.Id };
    
                // Handle both checked and unchecked cases
            if (updateCostInclude === true || updateCostInclude === false) {
                updatedRecord.Cost_Include__c = updateCostInclude;
                updateNeeded = true;
            }

            if (updateCostReview === true || updateCostReview === false) {
                updatedRecord.Cost_Review__c = updateCostReview;
                updateNeeded = true;
            }
    
                return updateNeeded ? updatedRecord : null;
            }).filter(record => record !== null);
    
            if (updatedRecords.length === 0) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'No Records Updated',
                    message: 'No changes applied.',
                    variant: 'info'
                }));
                return;
            }
            
            updateAll({
                caseId: this.recordId,
                costReview: updateCostReview,
                costInclude: updateCostInclude,
                currentRecords: updatedRecords,
                recordType: 'Ambulance'
            })
            .then(() => {
                this.onLoad();
                this.checkIfUnderUpdate();
                //this.costInclude = false;
                //this.costReview = false;
    
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Mass update completed successfully.',
                    variant: 'success'
                }));
            })
            .catch(error => {
                console.error('Update error:', error);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'Failed to update records. Please contact Administrator.',
                    variant: 'error'
                }));
            });
        }
    }

    // for the separate GO functionality:
    updateCostReviewOnly() {
    this.checkIfUnderUpdate();
    if (!this.updateHappening && (this.costReview === true || this.costReview === false)) {
        let updatedRecords = this.recordsToDisplay.map(record => ({
            Id: record.Id,
            Cost_Review__c: this.costReview
        }));

        updateAll({
            caseId: this.recordId,
            costReview: this.costReview,
            costInclude: null,
            currentRecords: updatedRecords,
            recordType: 'Ambulance'
        })
        .then(() => {
            this.onLoad();
            //this.costReview = false; // commenting to check the reload 
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Cost Review updated successfully.',
                variant: 'success'
            }));
        })
        .catch(() => {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Failed to update Cost Review.',
                variant: 'error'
            }));
        });
    }
}

updateCostIncludeOnly() {
    this.checkIfUnderUpdate();
    if (!this.updateHappening && (this.costInclude === true || this.costInclude === false)) {
        let updatedRecords = this.recordsToDisplay.map(record => ({
            Id: record.Id,
            Cost_Include__c: this.costInclude
        }));

        updateAll({
            caseId: this.recordId,
            costReview: null,
            costInclude: this.costInclude,
            currentRecords: updatedRecords,
            recordType: 'Ambulance'
        })
        .then(() => {
            this.onLoad();
            //this.costInclude = false; // commenting to check the reload 
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Cost Include updated successfully.',
                variant: 'success'
            }));
        })
        .catch(() => {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Failed to update Cost Include.',
                variant: 'error'
            }));
        });
    }
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
       this.onLoadSort();
    }
    previousPage() {
        this.pageNumber = this.pageNumber - 1;
        this.showSection = false;
        this.draftValues = [];
        this.onLoadSort();
   
    }
    nextPage() {
        this.pageNumber = this.pageNumber + 1;
        this.showSection = false;
        this.draftValues = [];
        this.onLoadSort();
    }

    firstPage() {
        this.pageNumber = 1;
        this.showSection = false;
        this.draftValues = [];
        this.onLoadSort();
    }

    lastPage() {
        this.pageNumber = this.totalPages;
        this.showSection = false;
        this.draftValues = [];
        this.onLoadSort();
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
        this.onLoadSort();  
       
    }


    doSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortSelection = this.sortDirection;
        this.pageNumber = 1;            
        this.draftValues = [];          
        this.showSection = false;
        this.onLoadSort();
       // this.sortData(this.sortBy, this.sortDirection);
    }

    //Adding onloadsort function to sort data
    onLoadSort(){
          return getHealthcareCostsAmbulanceForCaseSorted({
          caseId: this.recordId,
          filterValue: this.selectedFilter,
          pageSize: this.pageSize,
          pageNumber: this.pageNumber,
          sortOrder: this.sortSelection,
          sortBy: this.sortBy
        })
          .then((result) => {
            this.wiredRecords = result.hccList;
            this.recordsToDisplay = [];
            if (result.hccList != null && result.hccList) {
              this.records = JSON.parse(JSON.stringify(result.hccList));
              this.records.forEach((record) => {
                record.accountNameClass = "slds-cell-edit";
              });
              this.totalRecords = result.totalCount;
              this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
              // set page number
              if (this.pageNumber <= 1) {
                this.pageNumber = 1;
              } else if (this.pageNumber >= this.totalPages) {
                this.pageNumber = this.totalPages;
              }
              // set records to display on current page
              for (let i = 0; i < this.records.length; i++) {
                if (i === this.totalRecords) {
                  break;
                }
                this.recordsToDisplay.push(this.records[i]);
              }
    
              this.error = undefined;
            } else {
              this.records = [];
              this.totalRecords = result.totalCount;
            }
            this.lastSavedData = this.records;
            this.showSpinner = false;
          })
          .catch((error) => {
            this.records = [];
            this.totalRecords = 0;
            this.dispatchEvent(
              new ShowToastEvent({
                title: "Error",
                message:
                  "Some issues occured while loading Hospitalization Records. Please contact Administrator",
                variant: "error",
              })
            );
          });
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
        let dataReceived = event.detail.data;
    
        if (dataReceived.label === 'Account') {
            let updatedItem = {
                Id: dataReceived.context,
                Facility__c: dataReceived.value || ''
            };
    
            // Update recordsToDisplay
            this.recordsToDisplay = this.recordsToDisplay.map(record =>
                record.Id === updatedItem.Id ? { ...record, ...updatedItem } : record
            );
    
            this.updateDraftValues(updatedItem);
    
            // Force UI refresh
            this.recordsToDisplay = [...this.recordsToDisplay];
        }
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
    handleCellChange(event) {
        this.showSection = true;
        var siteCodeIds = [];
    
        event.detail.draftValues.forEach(draft => {
            let index = this.draftValues.findIndex(e => e.Id === draft.Id);
    
            if (draft.Site_Code__c !== undefined) {
                siteCodeIds.push({ id: draft.Id, siteCode: draft.Site_Code__c });
            }
    
            if (index > -1) {
                Object.keys(draft).forEach(field => {
                    if (field !== 'Facility__c') {  // Prevent Facility__c from being erased incorrectly
                        this.draftValues[index][field] = draft[field];
                    }
                });
            } else {
                let newDraft = { ...draft };
                delete newDraft.Facility__c;  // Prevent Facility__c from being erased incorrectly
                this.draftValues.push(newDraft);
            }
        });
    
        // Ensure lookup field is also tracked
        this.recordsToDisplay = this.recordsToDisplay.map(record => {
            let matchingDraft = this.draftValues.find(d => d.Id === record.Id);
            if (matchingDraft) {
                return { ...record, ...matchingDraft };
            }
            return record;
        });
    
        this.recordsToDisplay = [...this.recordsToDisplay]; // Force UI update
    
        // Fetch updated Facility__c only when Site_Code__c is changed
        if (siteCodeIds.length > 0) {
            getFacilityBySiteCode({ siteCodeIds: siteCodeIds })
                .then(response => {
                    response.forEach(updatedRecord => {
                        let recordIndex = this.recordsToDisplay.findIndex(r => r.Id === updatedRecord.Id);
                        if (recordIndex !== -1) {
                            this.recordsToDisplay[recordIndex].Facility__c = updatedRecord.Facility__c;
                        }
                    });
                    this.recordsToDisplay = [...this.recordsToDisplay]; // Refresh UI
                })
                .catch(error => {
                    console.error("Error fetching facility by site code:", error);
                });
        }
    }
    
    handleChange(event) {
        event.preventDefault();
       this.Facility__c = event.target.value;
        this.showSpinner = true;
      
    }

    handleCancel(event) {
        event.preventDefault();
        //  Reset error message
        this.updateMessage = '';
        this.showErrorMessage = false;
        this.showSection = false;
    
        // Reset to last saved state
        this.records = JSON.parse(JSON.stringify(this.lastSavedData));
        this.recordsToDisplay = JSON.parse(JSON.stringify(this.lastSavedData));
    
        // Ensure Facility__c is restored properly
        this.recordsToDisplay.forEach(record => {
            record.Facility__c = this.lastSavedData.find(r => r.Id === record.Id)?.Facility__c || '';
        });
    
        //Clear field highlights and success tracker
        this.draftValues = [];
        this.editedFieldKeys = new Set();
        this.successfullyUpdatedFields = new Set();

    
        this.recordsToDisplay = [...this.recordsToDisplay];
    
        // Reset lookup UI interactions
        this.handleWindowOnclick('reset');
        this.onLoad();
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

    handleSave(event) {
        event.preventDefault();
        this.showSpinner = true;
    
        let finalDrafts = this.draftValues.map(draft => ({
            Id: draft.Id,
            Site_Code__c: draft.Site_Code__c !== undefined ? draft.Site_Code__c : undefined,  // Only update Site_Code__c when changed
            Facility__c: draft.Facility__c !== undefined ? draft.Facility__c : undefined, // Only update Facility__c when changed
            ...draft
        }));

        //for partial success
        this.editedFieldKeys = new Set();
        finalDrafts.forEach(draft => {
        const recordId = draft.Id;
            Object.keys(draft).forEach(field => {
                if (field !== 'Id') {
                 this.editedFieldKeys.add(`${recordId}.${field}`);
                }
            });
        });
    
        saveDraftValues({ data: finalDrafts, recordDisplay: this.recordsToDisplay, recordType: 'Ambulance' })
            .then(data => {
                this.updateMessage = data.actionMessage;
                if (data.passedResult === 'Passed') {
                    this.draftValues = [];
                    // Merge updated records into the existing table instead of replacing
                    const updatedMap = new Map(data.updatedRecords.map(r => [r.Id, r]));

                    this.recordsToDisplay = this.recordsToDisplay.map(existing => {
                    const updated = updatedMap.get(existing.Id);
                    return updated ? { ...existing, ...updated } : existing;
                    });

                    this.showSection = false;
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Success',
                        message: 'HealthCare Cost for Ambulance record(s) updated successfully',
                        variant: 'success'
                    }));
                } else {
                    this.showSection = true; // stay in edit mode  
                }
                
    
                if (this.updateMessage) {
                    // Split by line breaks and remove duplicate lines
                    let lines = this.updateMessage.split(/\r?\n/);
                    // remove duplicates and empty lines
                    let uniqueLines = [...new Set(lines)].filter(Boolean); 
                    this.updateMessage = uniqueLines.join('<br />');
                    this.showErrorMessage = true;
                     //  Parse the error lines to extract row/field for highlighting
                    this.errorFields = uniqueLines.map(line => {
                    return null;
                    }).filter(Boolean);
                }
                
    
                //  Handle result based on passedResult
                if (data.passedResult === 'Passed') {
                    this.showSection = false;
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Success',
                        message: 'HealthCare Cost Ambulance record(s) updated successfully',
                        variant: 'success'
                    }));
                } 
                else if (data.passedResult === 'Failed' || data.passedResult == null) {
                    this.showSection = true;
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: 'Please review the error message shown below and try again!',
                        variant: 'error'
                    }));
                }
                    // working
                else if (data.passedResult === 'Partial Success') {
                    // Merge updated records into the existing table instead of replacing
                    const updatedMap = new Map(data.updatedRecords.map(r => [r.Id, r]));

                    this.recordsToDisplay = this.recordsToDisplay.map(existing => {
                    const updated = updatedMap.get(existing.Id);
                    return updated ? { ...existing, ...updated } : existing;
                    });
                
                    this.successfullyUpdatedFields = new Set();
                
                    // Reapply failed draft values to recordsToDisplay
                    const failedDraftMap = new Map(this.draftValues.map(d => [d.Id, d]));
                        this.recordsToDisplay = this.recordsToDisplay.map(existing => {
                        if (failedDraftMap.has(existing.Id)) {
                        return { ...existing, ...failedDraftMap.get(existing.Id) };
                        }
                    return existing;
                    });
                    this.draftValues = this.draftValues.filter(
                        draft=>data.failedRecordIds.includes(draft.Id)
                    );
                
                    // Important: Update lastSavedData so cancel works correctly
                    this.lastSavedData = JSON.parse(JSON.stringify(this.recordsToDisplay));
                
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Warning',
                            message: 'Few Ambulance record(s) updated successfully. Errors on remaining shown below!',
                            variant: 'Warning'
                        })
                    );
                
                    this.showSection = true; // stay in edit mode
                    
                }
                return this.refresh();
                 
          
             })
            .catch(error => {
                this.showSection = true;
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'An issue occurred while saving. Please contact support.',
                    variant: 'error'
                }));
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    handleRefresh(){
        this.onLoad();
    }     
}