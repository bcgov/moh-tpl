import { LightningElement, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getHealthcareCostsHospitalForCase from '@salesforce/apex/HCCostCaseController.getHealthcareCostsHospitalForCase';
import saveDraftValues from '@salesforce/apex/HCCCostController.saveDraftValues'; 

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
        editable: false,
        sortable: true
    },
    {
        label: 'Location of Incident',
        fieldName: 'Location_of_Incident__c',
        type: 'text',
        editable: false,
        sortable: true
    },
    {
        label: 'Description of Incident',
        fieldName: 'Description_of_Incident__c',
        type: 'text',
        editable: false,
        sortable: true,
    },
    {
        label: 'Intervention Code (CCI)',
        fieldName: 'Intervention_Code_CCI__c',
        type: 'text',
        editable: false,
        sortable: true,
    },
    {
        label: 'CCI Level',
        fieldName: 'CCI_Level__c',
        type: 'text',
        editable: false,
        sortable: true,
    },
    {
        label: 'Site Code',
        fieldName: 'Site_Code__c',
        type: 'text',
        editable: false,
        sortable: false
    },
    {
        label: 'Facility',
        fieldName: 'FacilityName__c',
        type: 'text',
        editable: false,
        sortable: false
    },
    {
        label: 'Date of Admission',
        fieldName:'Date_of_Admission__c',
        editable: false,
        sortable: true
    },
    {
        label: 'Date of Discharge',
        fieldName:'Date_of_Discharge__c',
        editable: true,
        sortable: true
    },
    {
        label: 'Number of Days',
        fieldName: 'Number_of_Days__c',
        editable: false,
        sortable: true
    },
    {
        label: ' Service Provided by Facility',
        fieldName: 'Service_Provider_Facility__c',
        editable: false,
        sortable: true
    },
    {
    
        label: 'Service Type',
        fieldName: 'Service_Type2__c',
        editable: false,
        sortable: true
    },
    {
        label: 'Standard Daily Rate',
        type: 'currency',
        fieldName: 'Standard_Daily_Rate__c',
        editable: false,
        sortable: true
    },
    {
        label: 'Total Cost Standard',
        fieldName: 'Total_Costs_Standard__c',
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
        label: 'Diagnostic Treatment Service',
        fieldName :'Diagnostic_Treatment_Service2__c',
        type: 'text',
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
        editable: true,
        sortable: true
    },
    {
        label: 'Location of Incident',
        fieldName: 'Location_of_Incident__c',
        type: 'text',
        editable: true,
        sortable: true
    },
    {
        label: 'Description of Incident',
        fieldName: 'Description_of_Incident__c',
        type: 'text',
        editable: true,
        sortable: true,
    },
    {
        label: 'Intervention Code (CCI)',
        fieldName: 'Intervention_Code_CCI__c',
        type: 'text',
        editable: true,
        sortable: true,
    },
    {
        label: 'CCI Level',
        fieldName: 'CCI_Level__c',
        type: 'text',
        editable: false,
        sortable: true,
    },
    {
        label: 'Site Code',
        fieldName: 'Site_Code__c',
        type: 'text',
        editable: false,
        sortable: false
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
        label: 'Date of Admission',
        fieldName:'Date_of_Admission__c',
        type:'date-local',
        typeAttributes:{ 
            day: "2-digit",
            month: "2-digit",
            year: "numeric"},
        editable: true,
        sortable: true
    },
    {
        label: 'Date of Discharge',
        fieldName:'Date_of_Discharge__c',
        type:'date-local',
        typeAttributes:{ 
            day: "2-digit",
            month: "2-digit",
            year: "numeric"},
        editable: true,
        sortable: true
    },
    {
        label: 'Number of Days',
        fieldName: 'Number_of_Days__c',
        type: 'Number',
        editable: true,
        sortable: true
    },
    {
        label: ' Service Provided by Facility',
        fieldName: 'Service_Provider_Facility__c',
        editable: false,
        sortable: true
    },
    {
    
        label: 'Service Type',
        fieldName: 'Service_Type2__c',
        editable: false,
        sortable: true
    },
    {
        label: 'Standard Daily Rate',
        type: 'currency',
        fieldName: 'Standard_Daily_Rate__c',
        editable: true,
        sortable: true
    },
    {
        label: 'Total Cost Standard',
        fieldName: 'Total_Costs_Standard__c',
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
        label: 'Diagnostic Treatment Service',
        fieldName :'Diagnostic_Treatment_Service2__c',
        type: 'text',
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
export default class HospitalRecordsCase extends LightningElement {
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
        return getHealthcareCostsHospitalForCase({caseId: this.recordId, filterValue: this.selectedFilterValue, pageNumber: this.pageNumber, pageSize: this.pageSize})
        .then(result => {
            this.wiredRecords = result.hccList;
            this.recordsToDisplay = [];
            if(result.hccList != null && result.hccList){
                console.log('Hospitalization List :' + JSON.stringify(result.hccList));
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
    
    async refresh(){
        await refreshApex(this.wiredRecords);
    }

    async handleSave(event){
        await saveDraftValues({data: event.detail.draftValues})
        .then((result) => {
        // Clear all datatable draft values
            this.draftValues = [];
                console.log('Result : ' + result);
               if(result == 'Passed'){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'HealthCare Cost Hospitalization record(s) updated successfully',
                        variant: 'success'
                    })
                );    
            
               }
                else if(result == 'Failed'){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Record not saved successfully! Please check Healthcare Cost Hospitalization record(s) while updating',
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