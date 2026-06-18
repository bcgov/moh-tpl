import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import generateDocument from '@salesforce/apex/DocxGeneratorController.generateDocument';
import pollDocument     from '@salesforce/apex/DocxGeneratorController.pollDocument';

const POLL_INTERVAL_MS = 3000;   // wait 3s between polls
const MAX_POLL_TRIES   = 120;    // give up after 6 minutes

export default class GenerateDocxButton extends LightningElement {

    @api recordId;
    @track isGenerating  = false;
    @track downloadUrl   = null;
    @track statusMessage = '';

    _pollCount = 0;
    _jobId     = null;     // AsyncApexJob Id (section-ZIP path only)
    _pollTimer = null;
    _polling   = false;    // in-flight guard

    async handleGenerate() {
        this.isGenerating   = true;
        this.downloadUrl    = null;
        this._pollCount     = 0;
        this._jobId         = null;
        this._polling       = false;
        this.statusMessage  = 'Preparing\u2026';

        try {
            const result = await generateDocument({ caseId: this.recordId });

            if (result && result.startsWith('ASYNC:')) {
                // Section-ZIP path — poll for completion
                this._jobId = result.substring(6);
                this.statusMessage = 'Building large certificate \u2014 this takes a minute\u2026';
                this._schedulePoll();
            } else {
                // Sync path — result is ContentDocumentId, done immediately
                this.isGenerating = false;
                this.downloadUrl  = `/lightning/r/ContentDocument/${result}/view`;
                this._toast('Document ready', "Certificate generated and saved to Files.", 'success');
            }
        } catch (error) {
            this.isGenerating = false;
            const msg = error?.body?.message || 'Generation failed. Check Files in a few minutes.';
            this._toast('Generation failed', msg, 'error', 'sticky');
        }
    }

    _schedulePoll() {
        // Recursive setTimeout — each poll fires only after the previous one completes,
        // preventing concurrent Apex calls and duplicate toast notifications.
        this._pollTimer = setTimeout(() => this._poll(), POLL_INTERVAL_MS);
    }

    async _poll() {
        if (this._polling) return;
        this._polling = true;
        this._pollCount++;

        if (this._pollCount > MAX_POLL_TRIES) {
            this.isGenerating = false;
            this._polling     = false;
            this._toast(
                'Still generating',
                'The certificate is taking longer than expected. Check Files on this record in a few minutes.',
                'warning', 'sticky'
            );
            return;
        }

        try {
            const contentDocumentId = await pollDocument({
                caseId: this.recordId,
                jobId:  this._jobId
            });

            if (contentDocumentId) {
                this.isGenerating = false;
                this.downloadUrl  = `/lightning/r/ContentDocument/${contentDocumentId}/view`;
                this._toast('Document ready', 'Certificate package generated and saved to Files.', 'success');
            } else {
                this._polling = false;
                this._schedulePoll();
            }
        } catch (error) {
            this.isGenerating = false;
            this._polling     = false;
            const msg = error?.body?.message || 'An unexpected error occurred. Check Files in a few minutes.';
            this._toast('Generation error', msg, 'error', 'sticky');
        }
    }

    _toast(title, message, variant, mode = 'dismissable') {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant, mode }));
    }

    disconnectedCallback() {
        if (this._pollTimer) {
            clearTimeout(this._pollTimer);
            this._pollTimer = null;
        }
    }
}
