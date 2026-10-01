import { LightningElement, api, wire } from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import generateDocument from '@salesforce/apex/DocxGeneratorController.generateDocument';
import getEligibleHccCountForPrint from '@salesforce/apex/DocxGeneratorController.getEligibleHccCountForPrint';
import pollDocument from '@salesforce/apex/DocxGenrationStatusController.pollDocument';
import TPL_DocGen_Ministry_Certificate_Title from '@salesforce/label/c.TPL_DocGen_Ministry_Certificate_Title';
import TPL_DocGen_MC_Select_Template from '@salesforce/label/c.TPL_DocGen_MC_Select_Template';
import TPL_DocGen_MC_Document_Name from '@salesforce/label/c.TPL_DocGen_MC_Document_Name';
import TPL_DocGen_MC_Attached_File_Format from '@salesforce/label/c.TPL_DocGen_MC_Attached_File_Format';
import TPL_DocGen_MC_Download_Document from '@salesforce/label/c.TPL_DocGen_MC_Download_Document';
import TPL_DocGen_MC_Sign_Certificate from '@salesforce/label/c.TPL_DocGen_MC_Sign_Certificate';
import TPL_DocGen_MC_Go_To_Files_Tab from '@salesforce/label/c.TPL_DocGen_MC_Go_To_Files_Tab';
import TPL_DocGen_MC_Upload_Signed_Cert from '@salesforce/label/c.TPL_DocGen_MC_Upload_Signed_Cert';
import TPL_DocGen_MC_Upload_From_Library from '@salesforce/label/c.TPL_DocGen_MC_Upload_From_Library';
import TPL_DocGen_MC_Delete_Permission from '@salesforce/label/c.TPL_DocGen_MC_Delete_Permission';
import TPL_DocGen_Case_History_Title from '@salesforce/label/c.TPL_DocGen_Case_History_Title';
import TPL_DocGen_CH_Select_Template from '@salesforce/label/c.TPL_DocGen_CH_Select_Template';
import TPL_DocGen_CH_Document_Name from '@salesforce/label/c.TPL_DocGen_CH_Document_Name';
import TPL_DocGen_CH_Attached_File_Format from '@salesforce/label/c.TPL_DocGen_CH_Attached_File_Format';
import TPL_DocGen_CH_Download_Document from '@salesforce/label/c.TPL_DocGen_CH_Download_Document';
import TPL_DocGen_Start_Button from '@salesforce/label/c.TPL_DocGen_Start_Button';
import TPL_DocGen_Next_Button from '@salesforce/label/c.TPL_DocGen_Next_Button';
import TPL_DocGen_Previous_Button from '@salesforce/label/c.TPL_DocGen_Previous_Button';
import TPL_DocGen_Pick_Template_Title from '@salesforce/label/c.TPL_DocGen_Pick_Template_Title';
import TPL_DocGen_Table_Select_Header from '@salesforce/label/c.TPL_DocGen_Table_Select_Header';
import TPL_DocGen_Table_Name_Header from '@salesforce/label/c.TPL_DocGen_Table_Name_Header';
import TPL_DocGen_Table_Version_Number_Header from '@salesforce/label/c.TPL_DocGen_Table_Version_Number_Header';
import TPL_DocGen_Table_Template_Type_Header from '@salesforce/label/c.TPL_DocGen_Table_Template_Type_Header';
import TPL_DocGen_Steps_Title from '@salesforce/label/c.TPL_DocGen_Steps_Title';
import TPL_DocGen_Generation_Options_Title from '@salesforce/label/c.TPL_DocGen_Generation_Options_Title';
import TPL_DocGen_Response_Message_Title from '@salesforce/label/c.TPL_DocGen_Response_Message_Title';
import TPL_DocGen_Output_File_Format_Label from '@salesforce/label/c.TPL_DocGen_Output_File_Format_Label';
import TPL_DocGen_Document_Title_Label from '@salesforce/label/c.TPL_DocGen_Document_Title_Label';
import TPL_DocGen_Generating_Document_Alt from '@salesforce/label/c.TPL_DocGen_Generating_Document_Alt';
import TPL_DocGen_Remove_Button from '@salesforce/label/c.TPL_DocGen_Remove_Button';
import TPL_DocGen_Template_Ministers_Cert from '@salesforce/label/c.TPL_DocGen_Template_Ministers_Cert';
import TPL_DocGen_Template_Case_History from '@salesforce/label/c.TPL_DocGen_Template_Case_History';
import TPL_DocGen_Template_Type_Word from '@salesforce/label/c.TPL_DocGen_Template_Type_Word';
import TPL_DocGen_Output_Label_Word from '@salesforce/label/c.TPL_DocGen_Output_Label_Word';
import TPL_DocGen_Output_Label_Word_Disabled from '@salesforce/label/c.TPL_DocGen_Output_Label_Word_Disabled';
import TPL_DocGen_Status_Generating from '@salesforce/label/c.TPL_DocGen_Status_Generating';
import TPL_DocGen_Status_Async_Progress from '@salesforce/label/c.TPL_DocGen_Status_Async_Progress';
import TPL_DocGen_Status_Success from '@salesforce/label/c.TPL_DocGen_Status_Success';
import TPL_DocGen_Status_Timeout from '@salesforce/label/c.TPL_DocGen_Status_Timeout';
import TPL_DocGen_Status_Failed from '@salesforce/label/c.TPL_DocGen_Status_Failed';
import TPL_DocGen_Validation_Select_Template from '@salesforce/label/c.TPL_DocGen_Validation_Select_Template';
import TPL_DocGen_Download_Word from '@salesforce/label/c.TPL_DocGen_Download_Word';
import TPL_DocGen_Download_Excel from '@salesforce/label/c.TPL_DocGen_Download_Excel';
import TPL_DocGen_Generated_Document from '@salesforce/label/c.TPL_DocGen_Generated_Document';
import TPL_DocGen_Word_File_Alt from '@salesforce/label/c.TPL_DocGen_Word_File_Alt';
import TPL_DocGen_Excel_File_Alt from '@salesforce/label/c.TPL_DocGen_Excel_File_Alt';
import TPL_DocGen_Output_Label_Excel from '@salesforce/label/c.TPL_DocGen_Output_Label_Excel';

const POLL_INTERVAL_MS = 3000;
const MAX_POLLS = 80;
const ASYNC_PREFIX = 'ASYNC:';
const MISSING_RECORD_ID_MESSAGE = 'Case record Id is missing. Please refresh the Case record page and try again.';
// Mirrors DocxGeneratorController.WORD_UNAVAILABLE_ROW_THRESHOLD — keep the two in sync.
const WORD_UNAVAILABLE_ROW_THRESHOLD = 2500;

const STEP = Object.freeze({
    INSTRUCTIONS: 'instructions',
    PICK_TEMPLATE: 'pickTemplate',
    GENERATION_OPTIONS: 'generationOptions',
    RESPONSE: 'response'
});

const OUTPUT_FORMAT = Object.freeze({
    DOCX: 'docx',
    XLSX: 'xlsx'
});

const TEMPLATE = Object.freeze({
    MINISTERS_CERTIFICATE_ID: 'ministersCertificate',
    CASE_HISTORY_ID: 'caseHistory'
});

export default class GenerateDocxButton extends LightningElement {
    @api recordId;

    label = {
        ministryCertificateTitle: TPL_DocGen_Ministry_Certificate_Title,
        ministryCertificateSelectTemplate: TPL_DocGen_MC_Select_Template,
        ministryCertificateDocumentName: TPL_DocGen_MC_Document_Name,
        ministryCertificateAttachedFileFormat: TPL_DocGen_MC_Attached_File_Format,
        ministryCertificateDownloadDocument: TPL_DocGen_MC_Download_Document,
        ministryCertificateSignCertificate: TPL_DocGen_MC_Sign_Certificate,
        ministryCertificateGoToFilesTab: TPL_DocGen_MC_Go_To_Files_Tab,
        ministryCertificateUploadSignedCertificate: TPL_DocGen_MC_Upload_Signed_Cert,
        ministryCertificateUploadFromLibrary: TPL_DocGen_MC_Upload_From_Library,
        ministryCertificateDeletePermission: TPL_DocGen_MC_Delete_Permission,
        caseHistoryTitle: TPL_DocGen_Case_History_Title,
        caseHistorySelectTemplate: TPL_DocGen_CH_Select_Template,
        caseHistoryDocumentName: TPL_DocGen_CH_Document_Name,
        caseHistoryAttachedFileFormat: TPL_DocGen_CH_Attached_File_Format,
        caseHistoryDownloadDocument: TPL_DocGen_CH_Download_Document,
        startButton: TPL_DocGen_Start_Button,
        nextButton: TPL_DocGen_Next_Button,
        previousButton: TPL_DocGen_Previous_Button,
        pickTemplateTitle: TPL_DocGen_Pick_Template_Title,
        tableSelectHeader: TPL_DocGen_Table_Select_Header,
        tableNameHeader: TPL_DocGen_Table_Name_Header,
        tableVersionNumberHeader: TPL_DocGen_Table_Version_Number_Header,
        tableTemplateTypeHeader: TPL_DocGen_Table_Template_Type_Header,
        stepsTitle: TPL_DocGen_Steps_Title,
        generationOptionsTitle: TPL_DocGen_Generation_Options_Title,
        responseMessageTitle: TPL_DocGen_Response_Message_Title,
        outputFileFormatLabel: TPL_DocGen_Output_File_Format_Label,
        outputLabelExcel: TPL_DocGen_Output_Label_Excel,
        documentTitleLabel: TPL_DocGen_Document_Title_Label,
        generatingDocumentAlt: TPL_DocGen_Generating_Document_Alt,
        removeButton: TPL_DocGen_Remove_Button
    };

    downloadLinks = [];
    currentStep = STEP.INSTRUCTIONS;
    selectedTemplate = '';
    selectedTemplateName = '';
    documentTitle = '';
    outputFileFormat = OUTPUT_FORMAT.DOCX;
    isGenerating = false;
    statusMessage = '';
    validationMessage = '';
    pollCount = 0;
    pollTimer;
    showModal = false;
    eligibleRecordCount;

    templates = [
        { id: TEMPLATE.MINISTERS_CERTIFICATE_ID, name: TPL_DocGen_Template_Ministers_Cert, versionNumber: '1', templateType: TPL_DocGen_Template_Type_Word },
        { id: TEMPLATE.CASE_HISTORY_ID, name: TPL_DocGen_Template_Case_History, versionNumber: '3', templateType: TPL_DocGen_Template_Type_Word }
    ];

    @wire(getEligibleHccCountForPrint, { caseId: '$recordId' })
    wiredEligibleRecordCount({ data }) {
        if (data === undefined || data === null) {
            return;
        }
        this.eligibleRecordCount = data;
        // If Word was selected (the default) before the count came back and the case
        // turns out to be over the threshold, fall back to Excel automatically rather
        // than leaving a now-disabled option selected.
        if (this.isWordDisabled && this.outputFileFormat === OUTPUT_FORMAT.DOCX) {
            this.outputFileFormat = OUTPUT_FORMAT.XLSX;
        }
    }

    get isWordDisabled() {
        return this.eligibleRecordCount != null && this.eligibleRecordCount > WORD_UNAVAILABLE_ROW_THRESHOLD;
    }

    get wordOptionLabel() {
        return this.isWordDisabled ? TPL_DocGen_Output_Label_Word_Disabled : TPL_DocGen_Output_Label_Word;
    }

    get isWordSelected() {
        return this.outputFileFormat === OUTPUT_FORMAT.DOCX;
    }

    get isExcelSelected() {
        return this.outputFileFormat === OUTPUT_FORMAT.XLSX;
    }

    get isInstructionsStep() {
        return this.currentStep === STEP.INSTRUCTIONS;
    }

    get isPickTemplateStep() {
        return this.currentStep === STEP.PICK_TEMPLATE;
    }

    get isGenerationOptionsStep() {
        return this.currentStep === STEP.GENERATION_OPTIONS;
    }

    get isResponseStep() {
        return this.currentStep === STEP.RESPONSE;
    }

    get hasDownloads() {
        return this.downloadLinks && this.downloadLinks.length > 0;
    }

    get filteredTemplates() {
        return this.templates.map((template) => ({
            ...template,
            checked: template.id === this.selectedTemplate
        }));
    }

    get pickTemplateStepClass() {
        return this.stepClass(STEP.PICK_TEMPLATE);
    }

    get generationOptionsStepClass() {
        return this.stepClass(STEP.GENERATION_OPTIONS);
    }

    get responseStepClass() {
        if (this.currentStep === STEP.RESPONSE && !this.isGenerating && this.hasDownloads) {
            return 'step-item active complete';
        }
        return this.stepClass(STEP.RESPONSE);
    }

    disconnectedCallback() {
        this.stopPolling();
    }

    handleStart() {
      //  console.log('[GenerateDocxButton] Start clicked', {recordId: this.recordId,currentStep: this.currentStep,showModal: this.showModal});
        this.showModal = true;
        this.currentStep = STEP.PICK_TEMPLATE;
        this.validationMessage = '';
       // console.log('[GenerateDocxButton] Modal opened and step changed', {recordId: this.recordId,currentStep: this.currentStep,showModal: this.showModal});
    }

    handleCloseModal() {
        this.showModal = false;
        this.currentStep = STEP.INSTRUCTIONS;
        this.validationMessage = '';
    }

    handleTemplateSelect(event) {
        this.selectedTemplate = event.target.value;
        const selected = this.templates.find((template) => template.id === this.selectedTemplate);
        this.selectedTemplateName = selected ? selected.name : '';
        this.documentTitle = this.buildDefaultDocumentTitle(this.selectedTemplateName);
        this.validationMessage = '';
       // console.log('[GenerateDocxButton] Template selected', {recordId: this.recordId,selectedTemplate: this.selectedTemplate,selectedTemplateName: this.selectedTemplateName,documentTitle: this.documentTitle});
    }

    handlePickNext() {
        //console.log('[GenerateDocxButton] Pick Template Next clicked', { recordId: this.recordId,selectedTemplate: this.selectedTemplate, selectedTemplateName: this.selectedTemplateName});
        if (!this.selectedTemplate) {
            this.validationMessage = TPL_DocGen_Validation_Select_Template;
            console.warn('[GenerateDocxButton] Pick Template validation failed - no template selected', {
                recordId: this.recordId
            });
            return;
        }
        this.currentStep = STEP.GENERATION_OPTIONS;
        this.validationMessage = '';
        if (!this.documentTitle) {
            this.documentTitle = this.buildDefaultDocumentTitle(this.selectedTemplateName);
        }
       // console.log('[GenerateDocxButton] Moved to Generation Options', {recordId: this.recordId, currentStep: this.currentStep, selectedTemplateName: this.selectedTemplateName, documentTitle: this.documentTitle});
    }

    handlePreviousToPick() {
        this.currentStep = STEP.PICK_TEMPLATE;
        this.validationMessage = '';
    }

    handleOutputFormatChange(event) {
        this.outputFileFormat = event.target.value;
    }

    handleDocumentTitleChange(event) {
        this.documentTitle = event.target.value;
    }

    async handleGenerate() {
       // console.log('[GenerateDocxButton] Generate clicked - before Apex call', {recordId: this.recordId,selectedTemplate: this.selectedTemplate, selectedTemplateName: this.selectedTemplateName,documentTitle: this.documentTitle,outputFileFormat: this.outputFileFormat,currentStep: this.currentStep,showModal: this.showModal});

        // Word may have been selected before the eligible-record-count wire resolved;
        // don't submit a request for a format the UI has since disabled.
        if (this.isWordDisabled && this.outputFileFormat === OUTPUT_FORMAT.DOCX) {
            this.outputFileFormat = OUTPUT_FORMAT.XLSX;
        }

        if (!this.recordId) {
           // console.error('[GenerateDocxButton] Missing recordId. Apex generateDocument was not called.', {recordId: this.recordId,selectedTemplateName: this.selectedTemplateName});
            this.validationMessage =  MISSING_RECORD_ID_MESSAGE;
            return;
        }

        if (!this.selectedTemplateName) {
           // console.error('[GenerateDocxButton] Missing selectedTemplateName. Apex generateDocument was not called.', {recordId: this.recordId,selectedTemplate: this.selectedTemplate,selectedTemplateName: this.selectedTemplateName});
            this.validationMessage = TPL_DocGen_Validation_Select_Template;
            return;
        }

        this.stopPolling();
        this.downloadLinks = [];
        this.isGenerating = true;
        this.currentStep = STEP.RESPONSE;
        this.statusMessage = TPL_DocGen_Status_Generating;
        this.pollCount = 0;
        this.validationMessage = '';

        try {
            const requestPayload = {
                caseId: this.recordId,
                selectedTemplate: this.selectedTemplateName,
                outputFormat: this.outputFileFormat
            };
           // console.log('[GenerateDocxButton] Calling generateDocument Apex', requestPayload);

            const result = await generateDocument(requestPayload);

            if (result === '')
            {
                throw new Error(TPL_DocGen_Status_Failed);
            }

            // console.log('[GenerateDocxButton] generateDocument Apex returned', {result});

            if (typeof result === 'string' && result.startsWith(ASYNC_PREFIX)) {
                const jobId = result.substring(ASYNC_PREFIX.length);
                this.statusMessage = TPL_DocGen_Status_Async_Progress;
                this.startPolling(jobId);
                return;
            }

            this.completeGenerationFromResult(result, 'generateDocument');
        } catch (error) {
            this.handleError(error);
        }
    }

    startPolling(jobId) {
      //  console.log('[GenerateDocxButton] Starting polling', {recordId: this.recordId,jobId });
        this.pollTimer = window.setInterval(async () => {
            this.pollCount += 1;

            try {
                const pollPayload = { caseId: this.recordId, jobId };
               // console.log('[GenerateDocxButton] Calling pollDocument Apex', {...pollPayload,pollCount: this.pollCount });

                const result = await pollDocument(pollPayload);

               // console.log('[GenerateDocxButton] pollDocument Apex returned', {result,pollCount: this.pollCount });

                // What it needs to be:
                if ( this.isFailedPollResult( result ) ){
                    const errorMessage = this.getPollResultMessage( result ) || TPL_DocGen_Status_Failed;
                    this.statusMessage = errorMessage;
                    this.isGenerating = false;
                    this.stopPolling();
                    this.showErrorToast( errorMessage );   // <-- add this line
                    return;
                }

                if (this.hasGeneratedFileIds(result)) {
                    this.completeGenerationFromResult(result, 'pollDocument');
                    this.stopPolling();
                    return;
                }

                if (this.pollCount >= MAX_POLLS) {
                    this.statusMessage = TPL_DocGen_Status_Timeout;
                    this.isGenerating = false;
                    this.stopPolling();
                }
            } catch (error) {
                this.handleError(error);
            }
        }, POLL_INTERVAL_MS);
    }

    stopPolling() {
        if (this.pollTimer) {
            window.clearInterval(this.pollTimer);
            this.pollTimer = undefined;
        }
    }

    buildLinks(contentDocumentIds) {
        const ids = this.parseContentDocumentIds(contentDocumentIds);

        return ids.map((id) => this.buildDownloadLink(id));
    }

    completeGenerationFromResult(result, source) {
        const generatedFileIds = this.getGeneratedFileIds(result);
       // console.log('[GenerateDocxButton] Completing generation from result', {source, result,generatedFileIds});

        this.downloadLinks = this.buildLinks(generatedFileIds);
        this.statusMessage = TPL_DocGen_Status_Success;
        this.isGenerating = false;
        this.showSuccessToast(this.statusMessage);
    }

    hasGeneratedFileIds(result) {
        const generatedFileIds = this.getGeneratedFileIds(result);
        if (Array.isArray(generatedFileIds)) {
            return generatedFileIds.length > 0;
        }
        return !!generatedFileIds;
    }

    getGeneratedFileIds(result) {
        if (!result) {
            return '';
        }

        if (typeof result === 'string') {
            return result;
        }

        return result.generatedFileIds
            || result.contentDocumentIds
            || result.contentDocumentId
            || result.fileIds
            || result.fileId
            || '';
    }

    isFailedPollResult(result) {
        if (!result || typeof result === 'string') {
            return false;
        }

        const status = result.status ? result.status.toLowerCase() : '';
        return status === 'failed' || status === 'failure' || status === 'error';
    }

    getPollResultMessage(result) {
        if (!result || typeof result === 'string') {
            return '';
        }

        return result.message || result.errorMessage || result.statusMessage || '';
    }

    parseContentDocumentIds(contentDocumentIds) {
        if (!contentDocumentIds) {
            return [];
        }

        if (Array.isArray(contentDocumentIds)) {
            return contentDocumentIds
                .map((id) => id && String(id).trim())
                .filter((id) => id);
        }

        return String(contentDocumentIds)
            .split('|')
            .map((id) => id && id.trim())
            .filter((id) => id);
    }

    buildDownloadLink(id) {
        return {
            id,
            label: this.downloadLabel(),
            fileName: this.downloadFileName(),
            iconName: this.downloadIconName(),
            iconAlternativeText: this.downloadIconAlternativeText(),
            url: `/sfc/servlet.shepherd/document/download/${id}`
        };
    }

    get isExcelFormat() {
        return this.outputFileFormat === OUTPUT_FORMAT.XLSX;
    }

    downloadLabel() {
        return this.isExcelFormat ? TPL_DocGen_Download_Excel : TPL_DocGen_Download_Word;
    }

    downloadFileName() {
        const title = this.documentTitle || this.selectedTemplateName || TPL_DocGen_Generated_Document;
        return `${title}.${this.outputFileFormat}`;
    }

    downloadIconName() {
        return this.isExcelFormat ? 'doctype:excel' : 'doctype:word';
    }

    downloadIconAlternativeText() {
        return this.isExcelFormat ? TPL_DocGen_Excel_File_Alt : TPL_DocGen_Word_File_Alt;
    }


    buildDefaultDocumentTitle(templateName) {
        if (!templateName) {
            return '';
        }

        const today = new Date();
        const month = today.toLocaleString('en-US', { month: 'long' });
        return `${templateName} ${month} ${today.getDate()}, ${today.getFullYear()}`;
    }

    stepClass(stepName) {
        const order = [STEP.PICK_TEMPLATE, STEP.GENERATION_OPTIONS, STEP.RESPONSE];
        const currentIndex = order.indexOf(this.currentStep);
        const stepIndex = order.indexOf(stepName);

        if (currentIndex === stepIndex) {
            return 'step-item active';
        }
        if (currentIndex > stepIndex) {
            return 'step-item complete';
        }
        return 'step-item';
    }

    handleError(error) {
        console.error('[GenerateDocxButton] DocGen error', {recordId: this.recordId,selectedTemplate: this.selectedTemplate,selectedTemplateName: this.selectedTemplateName,currentStep: this.currentStep,errorBody: error && error.body ? error.body : undefined, errorMessage: error && error.message ? error.message : undefined,fullError: error});
        this.stopPolling();
        this.isGenerating = false;
        this.currentStep = STEP.RESPONSE;
        const message = error && error.body && error.body.message
            ? error.body.message
            : TPL_DocGen_Status_Failed;
        this.statusMessage = message;
        this.showErrorToast(message);
    }

    showErrorToast (message)
    {
        this.dispatchEvent(
            new ShowToastEvent( {
                title: TPL_DocGen_Status_Failed,
                message: message,
                variant: 'error',
                mode: 'sticky'
            } )
        );
    }

    showSuccessToast(message)
    {
        this.dispatchEvent(
            new ShowToastEvent( {
                title: TPL_DocGen_Status_Success,
                variant: 'success',
                mode: 'dismissable'
            } )
        );
    }
}