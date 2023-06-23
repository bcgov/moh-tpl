import { LightningElement, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getHealthcareCostsHospitalForAccount from '@salesforce/apex/HCCostAccountController.getHealthcareCostsHospitalForAccount';
import updateHCCCaseInformation from '@salesforce/apex/HCCCostController.updateHCCCaseInformation';
import assignAll from '@salesforce/apex/HCCostAccountController.assignAll';
import findIfUnderUpdate from '@salesforce/apex/HCCCostController.findIfUnderUpdate';
import userId from '@salesforce/user/Id';
const COLUMNS = [
    {
        label: 'Case Number',
        fieldName: 'Case_Number__c' ,
        type: 'text',
        editable: false,
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
        label: 'Location of Incident',
        fieldName: 'Location_of_Incident__c',
        type: 'text',
        editable: false
    },
    {
        label: 'Description of Incident',
        fieldName: 'Description_of_Incident__c',
        type: 'text',
        editable: false
    },
    {
        label: 'Intervention Code (CCI)',
        fieldName: 'Intervention_Code_CCI__c',
        type: 'text',
        editable: false
    },
    {
        label: 'CCI Level',
        fieldName: 'CCI_Level__c',
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
        fieldName: 'FacilityName__c',
        type: 'text',
        editable: false
    },
    {
        label: 'Date of Admission',
        fieldName: 'Date_of_Admission__c',
        type:'date-local',
        typeAttributes:{ 
            day: "2-digit",
            month: "2-digit",
            year: "numeric"},
        editable: false
    },
    {
        label: 'Date of Discharge',
        fieldName: 'Date_of_Discharge__c',
        type:'date-local',
        typeAttributes:{ 
            day: "2-digit",
            month: "2-digit",
            year: "numeric"},
        editable: false
    },
    {
        label: 'Number of Days',
        fieldName: 'Number_of_Days__c',
        editable: false
    },
    {
        label: ' Service Provided by Facility',
        fieldName: 'Service_Provider_Facility__c',
        editable: false
    },
    {
    
        label: 'Service Type',
        fieldName: 'Service_Type2__c',
        editable: false
    },
    {
        label: 'Standard Daily Rate',
        type: 'currency',
        fieldName: 'Standard_Daily_Rate__c',
        editable: false
    },
    {
        label: 'Total Cost Standard',
        fieldName: 'Total_Costs_Standard__c',
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
        label: 'Diagnostic Treatment Service',
        fieldName : 'Diagnostic_Treatment_Service2__c',
        type: 'text',
        editable: false
    },
    {
        label: 'Souce System ID',
        fieldName : 'Source_System_ID__c',
        type: 'text',
        editable: false
    }

];

export default class HospitalRecordsAccount extends LightningElement {
    @api recordId;
    column = COLUMNS;
    isFirstPage = true;
    isLastPage = false;
    sortSelection = 'asc'; // sort order
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
    updateHappening = false;
    updateTriggered = false;
    filterOptions = [
        { label: 'All Records', value: 'All Records' },
        { label: 'Both Unchecked', value: 'Both Unchecked'}
    ];

    connectedCallback(){
        this.selectedFilter = 'All Records';
        this.recordId;
        this.sortSelection = 'asc';
        this.pageNumber = 1;
        this.pageSize = this.pageSizeOptions[0]; 
        this.onLoad();
        this.checkIfUnderUpdate();
    }

    doSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortSelection = this.sortDirection;
        this.onLoad();
       // this.sortData(this.sortBy, this.sortDirection);
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

    onLoad(){
        return getHealthcareCostsHospitalForAccount({accId: this.recordId, selectedFilterValue: this.selectedFilter, pageNumber: this.pageNumber, pageSize: this.pageSize, sortOrder: this.sortSelection})
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
                    message: 'Some issues occured while loading Hospitalization Records. Please contact Administrator',
                    variant: 'error'
                })
            );    
        })
    }

    handleCaseSelection(event){
        this.selectedCase = event.target.value;  
    }
    handleUnassign(){
        this.checkIfUnderUpdate();
            if(!this.updateHappening){
                this.updateTriggered = true;
                assignAll({currentAccountId:this.recordId,newCaseId:this.selectedCase,currentRecords:this.recordsToDisplay,recordType:'Hospitalization'})
                .then(result=>{
                    this.onLoad();
                    this.checkIfUnderUpdate();
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
    checkIfUnderUpdate(){
        console.log('called');
       
            findIfUnderUpdate({userId:userId})
            .then(result=>{
                this.updateHappening = result;
                this.showMassUpdateSection = !result;
                if(result){
                    console.log('yes');
                    setTimeout(() => { this.checkIfUnderUpdate();}, 5000);
                    
                }
            })
            .catch(error=>{
                console.log(error);
            });
    }
    handleAssign(){
        
        if(!this.selectedCase){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select Case  to assign.',
                    variant: 'error'
                })
            );
        }else{
            this.checkIfUnderUpdate();
            if(!this.updateHappening){
                this.updateTriggered = true;
                assignAll({currentAccountId:this.recordId,newCaseId:this.selectedCase,currentRecords:this.recordsToDisplay,recordType:'Hospitalization'})
                .then(result=>{
                    this.onLoad();
                    this.checkIfUnderUpdate();
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
        }
    }
    handleFilterChange(event) {
        this.selectedFilter = event.target.value;
        this.pageNumber = 1;
        this.onLoad();             
    }

}