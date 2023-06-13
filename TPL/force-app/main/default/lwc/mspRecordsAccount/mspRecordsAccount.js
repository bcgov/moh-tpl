import { LightningElement, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getHealthcareCostsMSPForAccount from '@salesforce/apex/HCCostAccountController.getHealthcareCostsMSPForAccount';
import updateHCCCaseInformation from '@salesforce/apex/HCCCostController.updateHCCCaseInformation';
import assignAll from '@salesforce/apex/HCCostAccountController.assignAll';

const COLUMNS = [
    {
        label: 'Case Number',
        fieldName: 'Case_Number__c',
        type:'text',
        editable: false
    },
    {
        label: 'Cost Include',
        fieldName: 'Cost_Include__c',
        type:'boolean',
        editable: false
    },
    {
        label: 'Cost Review',
        fieldName: 'Cost_Review__c',
        type:'boolean',
        editable:false
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
        label: 'Facility',
        fieldName: 'FacilityName__c',
        type: 'text',
        editable: false
    },
    {
        label: 'Facility Type',
        fieldName: 'Facility_Type__c',
        type: 'text',
        editable: false
    },
    {
        label: 'Descripiton of Service',
        fieldName: 'Description_of_Service2__c',
        type: 'text',
        editable: false
    },
    {
        label: 'Fee Item Code',
        fieldName: 'Fee_Item_Code__c',
        type: 'text',
        editable: false
    },
    {
        label: 'Fee Item Title',
        fieldName: 'Fee_Item_Title__c',
        type: 'text',
        editable: false
    },
    {
        label: 'Fee Item Description',
        fieldName: 'Fee_Item_Description__c',
        type: 'text',
        editable: false
    },
    {
        label: 'Practitioner Number',
        fieldName: 'Practitioner_Number__c',
        type: 'false',
        editable: true
    },
    {
        label: 'Practitioner Name',
        fieldName: 'Practitioner_Name__c',
        type: 'text',
        editable: false
    },
    {
        label: 'Diagnostic Code',
        fieldName: 'Diagnostic_Code__c',
        type: 'text',
        editable: false
    },
    {
        label: 'Diagnostic Description',
        fieldName: 'Diagnostic_Description__c',
        type: 'text',
        editable: false
    },
    {
        label: 'Amount Paid',
        fieldName: 'Amount_Paid__c',
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
        label: 'Speciality Code',
        fieldName: 'Specialty_Code__c',
        type: 'text',
        editable: false
    },
    {
        label: 'Speciality Description',
        fieldName: 'Specialty_Description2__c',
        type: 'text',
        editable: false
    },
    {
        label: 'Payee Number',
        fieldName: 'Payee_Number__c',
        type: 'text',
        editable: false
    },
    {
        label: 'Payee Descripiton',
        fieldName: 'Payee_Description__c',
        type: 'text',
        editable: false
    },
    {
        label: 'Service Start Date',
        fieldName: 'Service_Start_Date__c',
        type:'date-local',
        typeAttributes:{ 
            day: "2-digit",
            month: "2-digit",
            year: "numeric"},
        editable: false
    },
    {
        label: 'Service Finish Date',
        fieldName: 'Service_Finish_Date__c',
        type:'date-local',
        typeAttributes:{ 
            day: "2-digit",
            month: "2-digit",
            year: "numeric"},
        editable: false
    },
    {
        label: 'Location Type Code',
        fieldName: 'Location_Type_Code__c',
        type: 'text',
        editable: false,
        sortable: true
    },
    {
        label: 'Location Type Description',
        fieldName: 'Location_Type_Description2__c',
        type: 'text',
        editable: false
    },
    {
        label: 'Source System ID',
        fieldName: 'Source_System_ID__c',
        type: 'text',
        editable: false
    }
];

export default class MspRecordsAccount extends LightningElement {
    @api recordId;
    column = COLUMNS;
    isFirstPage = true;
    isLastPage = false;
    totalRecords = 0; //Total no.of records
    totalPages; //Total no.of pages
    pageNumber = 1; //Page number
    pageSizeOptions = [5, 10, 25, 50, 75, 100]; //Page size options
    records = []; //All records available in the data table
    pageSize; //No.of records to be displayed per page
    recordsToDisplay = []; //Records to be displayed on the page
    wiredRecords;
    selectedCase;
    selectedRows = [];
    showErrorMessage = false;
    displayMessage='';
    selectedFilter= 'All Records';
    filterOptions = [
        { label: 'All Records', value: 'All Records' },
        { label: 'Both Unchecked', value: 'Both Unchecked'}
    ];


    connectedCallback(){
        this.selectedFilter = 'All Records';
        this.recordId;
        this.pageNumber = 1;
        this.pageSize = this.pageSizeOptions[0]; 
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

    handleCaseSelection(event){
        this.selectedCase = event.target.value;  
    }
     
    handleSelect(){
        var el = this.template.querySelector('lightning-datatable');
        var selected = el.getSelectedRows();
        
        let selectedCostRecords = [];
        if(selected.length==0){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select Case to assign/unassign.',
                    variant: 'error'
                })
            );
        }
        else{
                    
            selected.forEach(function(element){
                selectedCostRecords.push(element);  
                });
                 
                
                    console.log('else');
                    return updateHCCCaseInformation({ caseId: this.selectedCase, hccList: selectedCostRecords, recordDisplay: this.recordsToDisplay})
                    .then((data,error) => {
                        this.displayMessage = data.updateMessage;
                    if(this.displayMessage){
                            this.displayMessage = this.displayMessage.replace(/\r\n/g, "<br />");
                            this.showErrorMessage = true;
                        }
                        
                        if(this.displayMessage || data.passMessage){
                            if(data.passMessage == 'Passed'){
                                this.onLoad();
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: 'Success',
                                        message: 'Case assigned to Hospital HealthCare Cost record(s) updated successfully.',
                                        variant: 'success'
                                    })
                                );    
                            }
                            else if(data.passMessage == 'Failed')
                            {
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: 'Error',
                                        message: 'Please ensure cost review and cost include are unchecked for the Hospital Healthcare Cost record(s) you want to assign a case.',
                                        variant: 'error'
                                    })
                                );
                            }
                            else if(data.passMessage == 'Empty Selection')
                            {
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: 'Error',
                                        message: 'Please select Case and HCC Records to map.',
                                        variant: 'error'
                                    })
                                );
                            }
                            else if(data.passMessage == 'Partial Success'){
                                this.onLoad();
                                this.dispatchEvent(
                                    new ShowToastEvent({
                                        title: 'Warning',
                                        message: 'Case update on few records successful with validation issue on others as displayed below.',
                                        variant: 'warning'
                                    })
                                ); 
                            }
                        }
                        else{
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error',
                                    message: 'Please select Case and Hospital Records together to assign.',
                                    variant: 'error'
                                })
                            ); 
                        }
                    });
                }
        }

    async refresh(){
        await refreshApex(this.wiredRecords);
    }

    onLoad(){
        return getHealthcareCostsMSPForAccount({accId: this.recordId, selectedFilterValue: this.selectedFilter, pageNumber: this.pageNumber, pageSize: this.pageSize})
        .then(result =>{
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
         
                 this.error = undefined;
                 
             }
             else{
                 this.records = [];
                 this.totalRecords = result.totalCount;
             }
        })
        .catch(error =>{
            this.totalRecords = 0;
            this.records = [];
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Some issues occured while loading MSP Records. Please contact Administrator',
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
        this.onLoad();
    }

    handleAssign(){
        
            assignAll({currentAccountId:this.recordId,newCaseId:this.selectedCase,currentRecords:this.recordsToDisplay})
            .then(result=>{
                this.onLoad();
            })
            .catch(error =>{
                this.records = []
                this.totalRecords = 0;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Some issues occured while loading MSP Records. Please contact Administrator',
                        variant: 'error'
                    })
                );    
            });
        

    }
    handleUnassign(){
        assignAll({currentAccountId:this.recordId,newCaseId:this.selectedCase,currentRecords:this.recordsToDisplay})
            .then(result=>{
                this.onLoad();
            })
            .catch(error =>{
                this.records = []
                this.totalRecords = 0;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Some issues occured while loading MSP Records. Please contact Administrator',
                        variant: 'error'
                    })
                );    
            });
        
    } 
    handleFilterChange(event) {
        this.selectedFilter = event.target.value;
        this.pageNumber = 1;
        this.onLoad();  
               
    }
}