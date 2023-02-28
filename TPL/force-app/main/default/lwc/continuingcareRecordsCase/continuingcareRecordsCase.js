import { LightningElement, wire, api } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getHealthcareCostsCCForCase from '@salesforce/apex/HCCCostCCRecord.getHealthcareCostsCCForCase';
import getContinuingCareCountonCase from '@salesforce/apex/HCCCostCCRecord.getContinuingCareCountonCase';
import deleteContinuingCareRecords from '@salesforce/apex/HCCCostCCRecord.deleteContinuingCareRecords';
import saveDraftValues from '@salesforce/apex/HCCCostController.saveDraftValues'; 
import COST_FIELD from '@salesforce/schema/Healthcare_Cost__c.Cost__c';
import DESCRIPTION_FIELD from '@salesforce/schema/Healthcare_Cost__c.Description__c';

const COLUMNS = [
    
    {
        label: 'Description',
        fieldName: DESCRIPTION_FIELD.fieldApiName,
        type:'text',
        sortable: true,
        editable:true
    },
    {
        label: 'Cost',
        fieldName: COST_FIELD.fieldApiName,
        type: 'currency',
        sortable: true,
        editable: true
    }
];


export default class ContinuingcareRecordsCase extends LightningElement {
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

      @wire(getHealthcareCostsCCForCase, { caseId: '$recordId' })
      healthcareCostsCCForCase(result){
          this.wiredRecords = result;
          const {data, error} = result;
  
          if(data != null && data){
              console.log('Data of Continuing Care Records --> ' + JSON.stringify(data));
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

    async refresh(){
        await refreshApex(this.wiredRecords);
    }

    async handleSelect(){
        var el = this.template.querySelector('lightning-datatable');
        console.log(el);
        var selected = el.getSelectedRows();
        //console.log(selected);
        console.log('selectedRows : ' + selected);
        let selectedCostRecords = [];
        
        selected.forEach(function(element){
        selectedCostRecords.push(element);
           console.log(element);   
        });
        await deleteContinuingCareRecords({deletionRecords: selectedCostRecords})
        .then((result) => {
            console.log('Result : ' + result);
           if(result == 'Passed'){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Selected  Continuing Care record(s) deleted successfully',
                    variant: 'success'
                })
            );    
        
           }
            else if(result == 'Failed'){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please select record(s) for deletion',
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
    
    async handleSave(event){
       await saveDraftValues({data: event.detail.draftValues})
            .then((result) => {
                console.log('Result : ' + result);
               if(result == 'Passed'){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'HealthCare Cost Continuing record(s) updated successfully',
                        variant: 'success'
                    })
                );    
            
               }
                else if(result == 'Failed'){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Record not saved successfully! Please check Healthcare Cost Continuing Care record(s) while updating',
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