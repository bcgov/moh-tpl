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
    private String documentTitle;


    /**
    * Params: Id caseId, String selectedTemplate, Id logId
    * Creates a queueable job for single XLSX generation.
    */
    public XlsxGenerationAsyncQueueable(
        Id caseId,
        String selectedTemplate,
        Id logId,
        String documentTitle
    ) {
        this.caseId = caseId;
        this.logId = logId;
        this.selectedTemplate = selectedTemplate;
        this.documentTitle = documentTitle;
    }

    /**
    * Params: QueueableContext context
    * Runs the queueable job.
    */
    public void execute(QueueableContext context) {
        try {
            LogService.markDocxGenerationProcessingById(Id.valueOf(logId),String.valueOf(context.getJobId()));

            String contentDocumentId = DocxGeneratorController.generateSingleXlsxSyncProcess(caseId,selectedTemplate,documentTitle);

            LogService.markDocxGenerationCompletedById(Id.valueOf(logId),String.valueOf(context.getJobId()),contentDocumentId);
        } 
        catch (Exception e) {
            String stackTrace = e.getStackTraceString();
            LogService.markDocxGenerationFailed(Id.valueOf(logId),Id.valueOf(caseId),String.valueOf(context.getJobId()),DocxFormatHelper.friendlyErrorMessage(e),stackTrace,'XlsxGenerationAsyncQueueable','execute');
        }
    }
}