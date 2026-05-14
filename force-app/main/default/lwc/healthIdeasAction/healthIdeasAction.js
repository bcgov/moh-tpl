import { LightningElement, api } from 'lwc';
import runGetCost from '@salesforce/apex/HealthIdeasApiIntegration.getHealthcareCostsForAccountandSetDate';
import isBatchInProgress from '@salesforce/apex/HealthIdeasApiIntegration.isBatchInProgress';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import dateSelectionMessage from '@salesforce/label/c.TPL_HI_Date_Selection_Message';
import partialSuccessText from '@salesforce/label/c.TPL_HI_Partial_Success_Text';
import toastSuccessMessage from '@salesforce/label/c.TPL_HI_Toast_SuccessMessage';
import transferSuccessMessage from '@salesforce/label/c.TPL_HI_Transfer_SuccessMessage';
import unexpectedErrorMessage from '@salesforce/label/c.TPL_HI_Unexpected_Error_Message';

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
    messages = [];

    connectedCallback ()
    {
        this.selectedDate = this.getTodayLocal();
    }

    disconnectedCallback ()
    {
        this.clearBatchTimer();
    }

    get hasMessages ()
    {
        return this.messages && this.messages.length > 0;
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
            this.showError( dateSelectionMessage );
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

            this.messages = response?.messages || [];

            if ( !response?.success )
            {
                this.showError( response?.errorMessage || unexpectedErrorMessage );
                return;
            }

            if ( this.messages.length > 0 )
            {
                this.showCompletedWithNotedErrors();
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
            this.showError( error?.body?.message || unexpectedErrorMessage );
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
                if ( this.messages.length > 0 )
                {
                    this.showCompletedWithNotedErrors();
                    return;
                }

                this.showSuccess();
            }
        }
        catch ( error )
        {
            this.showError( error?.body?.message || unexpectedErrorMessage );
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

    // Shows success message and stops loading.
    showSuccess ()
    {
        this.clearBatchTimer();
        this.isLoading = false;
        this.result = transferSuccessMessage;
        this.error = undefined;
        this.dispatchEvent(
            new ShowToastEvent( {
                title: 'Success',
                message: toastSuccessMessage,
                variant: 'success'
            } )
        );
    }

    // Shows completed message and keeps noted errors visible in the panel.
    showCompletedWithNotedErrors ()
    {
        this.clearBatchTimer();
        this.isLoading = false;
        this.result = transferSuccessMessage;
        this.error = undefined;

        this.dispatchEvent(
            new ShowToastEvent( {
                title: 'Success',
                message: toastSuccessMessage,
                variant: 'success'
            } )
        );
    }

    // Shows an error toast, stores the error, and stops loading.
    showError ( message )
    {
        this.clearBatchTimer();
        this.isLoading = false;
        this.result = undefined;
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
        this.messages = [];
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