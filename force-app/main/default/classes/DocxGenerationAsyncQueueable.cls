/**
* Author: Nikhil Jeenru
* Company: CGI
* Purpose:
* Runs single DOCX generation asynchronously and updates the generation log.
*/
public with sharing class DocxGenerationAsyncQueueable implements Queueable {
    private Id caseId;
    private String selectedTemplate;
    private Id logId;
    private String documentTitle;
    
    
    /**
Params: Id caseId, String selectedTemplate, Id logId, String documentTitle
* Creates a queueable job for single DOCX generation.
*/
    public DocxGenerationAsyncQueueable(Id caseId, String selectedTemplate, Id logId, String documentTitle) {
        this.caseId = caseId;
        this.selectedTemplate = selectedTemplate;
        this.logId = logId;
        this.documentTitle = documentTitle;
    }
    
    
    /**
Params: QueueableContext context
* Runs the queueable job.
*/
    public void execute(QueueableContext context) {
        try {
            LogService.markDocxGenerationProcessingById(logId, context.getJobId());
            
            String contentDocumentId = DocxGeneratorController.generateSingleDocxFileSyncProcess(caseId, selectedTemplate, documentTitle);
            
            LogService.markDocxGenerationCompletedById(logId, context.getJobId(), contentDocumentId);
        } 
        catch (Exception e) {
            String stackTrace = e.getStackTraceString();
            LogService.markDocxGenerationFailed(Id.valueOf(logId),Id.valueOf(caseId),String.valueOf(context.getJobId()),DocxFormatHelper.friendlyErrorMessage(e),stackTrace,'DocxGenerationAsyncQueueable','execute');
        }
    }
}