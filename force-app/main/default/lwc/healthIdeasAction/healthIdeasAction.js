import { LightningElement, api } from 'lwc';
import runGetCost from '@salesforce/apex/HealthIdeasApiIntegrationController.runGetCost';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class HealthIdeasAction extends LightningElement {
    @api recordId;

    selectedDate;
    result;
    error;
    isLoading = false;

    connectedCallback() {
        this.selectedDate = this.getTodayLocal();
    }

    handleDateChange(event) {
        this.selectedDate = event.target.value;
    }

    async handleRun() {
        this.result = null;
        this.error = null;

        if (!this.selectedDate) {
            this.error = 'Please select a date.';
            return;
        }

        this.isLoading = true;

        try {
            const response = await runGetCost({
                recordId: this.recordId,
                selectedDate: this.selectedDate
            });

            this.result = response;

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Get Records executed successfully.',
                    variant: 'success'
                })
            );
        } catch (e) {
            this.error =
                e?.body?.message ||
                e?.message ||
                'Unknown error';

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.error,
                    variant: 'error',
                    mode: 'sticky'
                })
            );
        } finally {
            this.isLoading = false;
        }
    }

    getTodayLocal() {
        const today = new Date();
        const yyyy = today.getFullYear();
        const mm = String(today.getMonth() + 1).padStart(2, '0');
        const dd = String(today.getDate()).padStart(2, '0');
        return `${yyyy}-${mm}-${dd}`;
    }
}