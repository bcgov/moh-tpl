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
import FACILITY_NAME_FIELD from '@salesforce/schema/Healthcare_Cost__c.FacilityName__c';
import FIXED_WING_HELICOPTER_FIELD from '@salesforce/schema/Healthcare_Cost__c.Fixed_Wing_Helicopter__c';
import SOURCE_SYSTEM_ID_FIELD from '@salesforce/schema/Healthcare_Cost__c.Source_System_ID__c';
import COST_FIELD from '@salesforce/schema/Healthcare_Cost__c.Cost__c';
import SUB_TOTAL_FIELD from '@salesforce/schema/Healthcare_Cost__c.Sub_Total__c';
import getHealthcareCostsAmbulanceForCase from '@salesforce/apex/HCCCostAmbulanceRecord.getHealthcareCostsAmbulanceForCase';
import saveDraftValues from '@salesforce/apex/HCCCostController.saveDraftValues'; 

const COLUMNS = [
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
        fieldName: FACILITY_NAME_FIELD.fieldApiName,
        editable: false,
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

    connectedCallback() {
        this.event2 = setInterval(() => {
            this.refresh();
        }, 100);
      }
    
      disconnectedCallback() {
        clearInterval(this.event2);
      }

    @wire(getHealthcareCostsAmbulanceForCase, { caseId: '$recordId' })
    healthcareCostsAmbulanceForCase(result){
        this.wiredRecords = result;
        const {data, error} = result;

        if(data != null && data){
            console.log('Data of Ambulance Records --> ' + JSON.stringify(data));
            this.records = data;
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

    /*async handleSelect(){
        var el = this.template.querySelector('lightning-datatable');
        console.log(el);
        var selected = el.getSelectedRows();
        //console.log(selected);
        console.log('selectedRows : ' + selected);
        let selectedCostIds = [];
        
        selected.forEach(function(element){
        selectedCostIds.push(element);
           console.log(element);   
        });

        await updateHCCRecordInformation({ hccIds: selectedCostIds})
        .then((result) => {
            console.log('Result : ' + result);
           if(result == 'Passed'){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Cases having Cost Review and Cost Include unchecked are delinked from HealthCare Cost Ambulance record(s) successfully',
                    variant: 'success'
                })
            );    
        
           }
            else if(result == 'Failed'){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please uncheck Cost Review and Cost Include of Healthcare Cost Ambulance record(s) whose Cases are to be delinked',
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
    } */

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
                        message: 'HealthCare Cost Ambulance record(s) updated successfully',
                        variant: 'success'
                    })
                );    
            
               }
                else if(result == 'Failed'){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Record not saved successfully! Please check Healthcare Cost Ambulance record(s) while updating',
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