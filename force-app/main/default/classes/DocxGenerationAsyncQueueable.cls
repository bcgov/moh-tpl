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
    
    /**
Params: Id caseId, String selectedTemplate
* Creates a queueable job for single DOCX generation.
*/
    public DocxGenerationAsyncQueueable(Id caseId, String selectedTemplate) {
        this(caseId, selectedTemplate, null);
    }
    
    /**
Params: Id caseId, String selectedTemplate, Id logId
* Creates a queueable job for single DOCX generation.
*/
    public DocxGenerationAsyncQueueable(Id caseId, String selectedTemplate, Id logId) {
        this.caseId = caseId;
        this.selectedTemplate = selectedTemplate;
        this.logId = logId;
    }
    
    
    /**
Params: QueueableContext context
* Runs the queueable job.
*/
    public void execute(QueueableContext context) {
        try {
            LogService.markDocxGenerationProcessingById(logId, context.getJobId());
            
            String contentDocumentId = DocxGeneratorController.generateSingleDocxFileSyncProcess(caseId, selectedTemplate);
            
            LogService.markDocxGenerationCompletedById(logId, context.getJobId(), contentDocumentId);
        } catch (Exception e) {
            String stackTrace = e.getStackTraceString();
            LogService.markDocxGenerationFailed(
                Id.valueOf(logId),
                Id.valueOf(caseId),
                String.valueOf(context.getJobId()),
                String.valueOf(e.getMessage()),
                stackTrace,
                'DocxSyncQueueable',
                'execute'
            );
        }
    }
}