/**
* Author: Nikhil Jeenru
* Company: CGI
* Purpose:
* Runs single XLSX generation asynchronously and updates the generation log.
*/
public with sharing class XlsxGenerationAsyncQueueable implements Queueable {
    private Id caseId;
    private Id logId;
    private String selectedTemplate;

    /**
    * Params: Id caseId, String selectedTemplate
    * Creates a queueable job for single XLSX generation with a selected template.
    */
    public XlsxGenerationAsyncQueueable(Id caseId, String selectedTemplate) {
        this(caseId, selectedTemplate, null);
    }

    /**
    * Params: Id caseId, Id logId
    * Creates a queueable job for single XLSX generation against an existing log record.
    */
    public XlsxGenerationAsyncQueueable(Id caseId, Id logId) {
        this(caseId, null, logId);
    }

    /**
    * Params: Id caseId, String selectedTemplate, Id logId
    * Creates a queueable job for single XLSX generation.
    */
    public XlsxGenerationAsyncQueueable(
        Id caseId,
        String selectedTemplate,
        Id logId
    ) {
        this.caseId = caseId;
        this.logId = logId;
        this.selectedTemplate = selectedTemplate;
    }

    /**
    * Params: QueueableContext context
    * Runs the queueable job.
    */
    public void execute(QueueableContext context) {
        try {
            LogService.markDocxGenerationProcessingById(Id.valueOf(logId),String.valueOf(context.getJobId()));

            String contentDocumentId = DocxGeneratorController.generateSingleXlsxSyncProcess(caseId,selectedTemplate);

            LogService.markDocxGenerationCompletedById(Id.valueOf(logId),String.valueOf(context.getJobId()),contentDocumentId);
        } 
        catch (Exception e) {
            String stackTrace = e.getStackTraceString();
            LogService.markDocxGenerationFailed(Id.valueOf(logId),Id.valueOf(caseId),String.valueOf(context.getJobId()),DocxFormatHelper.friendlyErrorMessage(e),stackTrace,'XlsxGenerationAsyncQueueable','execute');
        }
    }
}