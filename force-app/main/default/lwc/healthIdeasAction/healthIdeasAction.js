import { LightningElement, api } from 'lwc';
import runGetCost from '@salesforce/apex/HealthIdeasApiIntegration.getHealthcareCostsForAccountandSetDate';
import isBatchInProgress from '@salesforce/apex/HealthIdeasApiIntegration.isBatchInProgress';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Interval used to poll batch job status.
const POLL_INTERVAL_MS = 3000;

export default class HealthIdeasAction extends LightningElement
{
    @api recordId;
    selectedDate;
    isASyncCall = false;
    result;
    error;
    isLoading = false;
    batchId;
    poller;

    connectedCallback ()
    {
        this.selectedDate = this.getTodayLocal();
    }

    disconnectedCallback ()
    {
        this.clearBatchTimer();
    }

    handleDateChange ( event )
    {
        this.selectedDate = event.target.value;
    }

    handleAsyncCheckboxChange ( event )
    {
        this.isASyncCall = event.target.checked;
    }

    async handleRun ()
    {
        this.clearState();

        if ( !this.selectedDate )
        {
            this.showError( 'Please select a date.' );
            return;
        }

        this.isLoading = true;

        try
        {
            const response = await runGetCost( {
                accountId: this.recordId,
                asOfDate: this.selectedDate,
                isASyncCall: this.isASyncCall
            } );

            if ( !response?.success )
            {
                this.showError( response?.errorMessage || 'Unexpected error occurred.' );
                return;
            }

            if ( !this.isASyncCall )
            {
                this.showSuccess();
                return;
            }

            this.batchId = response?.batchId;

            if ( !this.batchId )
            {
                this.showSuccess();
                return;
            }

            this.startBatchCheck();
        }
        catch ( error )
        {
            this.showError( error?.body?.message || 'Unexpected error occurred.' );
        }
    }

    // Starts polling the batch job status.
    startBatchCheck ()
    {
        this.clearBatchTimer();
        this.poller = setInterval( () => this.checkBatchStatus(), POLL_INTERVAL_MS );
    }

    // Checks whether the batch job is still running.
    async checkBatchStatus ()
    {
        try
        {
            const inProgress = await isBatchInProgress( { batchId: this.batchId } );

            if ( !inProgress )
            {
                this.showSuccess();
            }
        }
        catch ( error )
        {
            this.showError( error?.body?.message || 'Unexpected error occurred.' );
        }
    }

    // Clears the polling timer if it exists.
    clearBatchTimer ()
    {
        if ( this.poller )
        {
            clearInterval( this.poller );
            this.poller = undefined;
        }
    }

    // Shows a success toast and stops loading.
    showSuccess ()
    {
        this.clearBatchTimer();
        this.isLoading = false;
        this.result = 'Your transfer has been successful';

        this.dispatchEvent(
            new ShowToastEvent( {
                title: 'Success',
                message: 'Get Records executed successfully.',
                variant: 'success'
            } )
        );
    }

    // Shows an error toast, stores the error, and stops loading.
    showError ( message )
    {
        this.clearBatchTimer();
        this.isLoading = false;
        this.error = message;

        this.dispatchEvent(
            new ShowToastEvent( {
                title: 'Error',
                message,
                variant: 'error',
                mode: 'sticky'
            } )
        );
    }

    // Resets component state before starting a new run.
    clearState ()
    {
        this.clearBatchTimer();
        this.result = undefined;
        this.error = undefined;
        this.batchId = undefined;
    }

    // Returns today's date in YYYY-MM-DD format for local time.
    getTodayLocal ()
    {
        const today = new Date();
        const yyyy = today.getFullYear();
        const mm = String( today.getMonth() + 1 ).padStart( 2, '0' );
        const dd = String( today.getDate() ).padStart( 2, '0' );
        return `${ yyyy }-${ mm }-${ dd }`;
    }
}