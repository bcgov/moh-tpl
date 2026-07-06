/**
* Author: Nikhil Jeenru
* Company: CGI
* Purpose:
* Assembles generated DOCX section files into ZIP files and marks document generation complete.
*/
public class DocxAssemblerQueueable implements Queueable {
    
    private Id caseId;
    private List<Id> sectionDocIds;  // All section ContentDocumentIds, ordered by title during assembly.
    private Integer batchIndex;      // Batch this Queueable execution is building.
    private List<Id> zipDocIds;      // ContentDocumentIds of completed ZIPs.
    private List<Id> cleanupDocIds;  // Original section ContentDocumentIds to delete at the end.
    private String selectedTemplate;
    
    /**
Params: Id caseId, List<Id> sectionDocIds
* Creates an assembler job for generated DOCX section files.
*/
    public DocxAssemblerQueueable(Id caseId, List<Id> sectionDocIds) {
        this(caseId, sectionDocIds, TPL_Constants.DOCGEN_TEMPLATE_MINISTERS_CERTIFICATE);
    }
    
    /**
Params: Id caseId, List<Id> sectionDocIds, String selectedTemplate
* Creates an assembler job for generated DOCX section files.
*/
    public DocxAssemblerQueueable(Id caseId, List<Id> sectionDocIds, String selectedTemplate) {
        this(caseId, sectionDocIds, 0, new List<Id>(), sectionDocIds, selectedTemplate);
    }
    
    /**
Params: Id caseId, List<Id> sectionDocIds, Integer batchIndex, List<Id> zipDocIds, List<Id> cleanupDocIds, String selectedTemplate
* Initializes an assembler queueable for an internal ZIP batch.
*/
    private DocxAssemblerQueueable(
        Id caseId,
        List<Id> sectionDocIds,
        Integer batchIndex,
        List<Id> zipDocIds,
        List<Id> cleanupDocIds,
        String selectedTemplate
    ) {
        this.caseId = caseId;
        this.sectionDocIds = sectionDocIds;
        this.batchIndex = batchIndex;
        this.zipDocIds = zipDocIds;
        this.cleanupDocIds = cleanupDocIds;
        this.selectedTemplate = selectedTemplate == null
            ? TPL_Constants.DOCGEN_TEMPLATE_MINISTERS_CERTIFICATE
            : selectedTemplate;
    }
    
    /**
Params: QueueableContext ctx
* Runs the queueable job.
*/
    public void execute(QueueableContext ctx) {
        try {
            Map<Id, ContentDocument> docsById = new Map<Id, ContentDocument>();
            
            for (ContentDocument doc : [
                SELECT Id, ContentSize, Title
                FROM ContentDocument
                WHERE Id IN :sectionDocIds
            ]) {
                docsById.put(doc.Id, doc);
            }
            
            List<ContentDocument> docsInSectionOrder = new List<ContentDocument>();
            
            for (Id docId : sectionDocIds) {
                if (docsById.containsKey(docId)) {
                    docsInSectionOrder.add(docsById.get(docId));
                }
            }
            
            List<List<Id>> batches = partitionBySize(docsInSectionOrder);
            Integer totalBatches = batches.size();
            List<Id> thisBatch = batches[batchIndex];
            
            logDebug(
                'Starting ZIP assembly. batchIndex=' + batchIndex
                + ', totalBatches=' + totalBatches
                + ', thisBatchSize=' + thisBatch.size()
                + ', priorZipCount=' + zipDocIds.size()
            );
            
            Compression.ZipWriter zip = new Compression.ZipWriter();
            List<Id> remainingDocIds = new List<Id>();
            Boolean deferredForHeap = false;
            Integer addedCount = 0;
            
            for (Integer i = 0; i < thisBatch.size(); i++) {
                if (addedCount > 0 && Limits.getHeapSize() >= DocgenConstants.ASYNC_HEAP_SOFT_LIMIT_BYTES) {
                    appendRemainingIds(remainingDocIds, thisBatch, i);
                    deferredForHeap = true;
                    break;
                }
                
                ContentVersion cv = [
                    SELECT ContentDocumentId, Title, VersionData
                    FROM ContentVersion
                    WHERE ContentDocumentId = :thisBatch[i]
                    AND IsLatest = true
                    LIMIT 1
                ];
                
                if (addedCount > 0 && Limits.getHeapSize() >= DocgenConstants.ASYNC_HEAP_SOFT_LIMIT_BYTES) {
                    appendRemainingIds(remainingDocIds, thisBatch, i);
                    deferredForHeap = true;
                    break;
                }
                
                zip.addEntry(cv.Title, cv.VersionData);
                addedCount++;
                
                if (Limits.getHeapSize() >= DocgenConstants.ASYNC_HEAP_SOFT_LIMIT_BYTES && i + 1 < thisBatch.size()) {
                    appendRemainingIds(remainingDocIds, thisBatch, i + 1);
                    deferredForHeap = true;
                    break;
                }
            }
            
            if (deferredForHeap) {
                appendRemainingBatches(remainingDocIds, batches, batchIndex + 1);
            }
            
            Blob zipBlob = zip.getArchive();
            String fileName = DocxFormatHelper.generatedFileName(selectedTemplate, 'zip');
            Id zipDocId = DocxFormatHelper.createContentDocument(caseId, fileName, zipBlob, true);
            
            List<Id> updatedZipDocIds = new List<Id>(zipDocIds);
            updatedZipDocIds.add(zipDocId);
            
            logDebug(
                'ZIP assembly completed. zipDocId=' + zipDocId
                + ', addedCount=' + addedCount
                + ', deferredForHeap=' + deferredForHeap
                + ', remainingDocCount=' + remainingDocIds.size()
                + ', heapSize=' + Limits.getHeapSize()
            );
            if (deferredForHeap && !remainingDocIds.isEmpty()) {
                System.enqueueJob(new DocxAssemblerQueueable(
                    caseId,
                    remainingDocIds,
                    0,
                    updatedZipDocIds,
                    cleanupDocIds,
                    selectedTemplate
                ));
            } else if (batchIndex + 1 < totalBatches) {
                System.enqueueJob(new DocxAssemblerQueueable(
                    caseId,
                    sectionDocIds,
                    batchIndex + 1,
                    updatedZipDocIds,
                    cleanupDocIds,
                    selectedTemplate
                ));
            } else {
                LogService.markLatestDocxGenerationCompleted(caseId, updatedZipDocIds);
                try {
                    deleteSectionFiles();
                } catch (Exception cleanupEx) {
                    System.debug(
                        LoggingLevel.WARN,
                        'Section file cleanup failed: ' + cleanupEx.getMessage()
                    );
                }
            }
        } catch (Exception e) {
            String stackTrace = e.getStackTraceString();
            System.debug(
                LoggingLevel.ERROR,
                'DocxAssemblerQueueable failed (batch ' + batchIndex + '): '
                + e.getMessage() + '\n' + stackTrace
            );
            LogService.markDocxGenerationFailed(
                null,
                Id.valueOf(caseId),
                String.valueOf(ctx.getJobId()),
                String.valueOf(e.getMessage()),
                stackTrace,
                'DocxAssemblerQueueable',
                'execute'
            );
        }
    }
    
    /**
Params: List<Id> target, List<Id> source, Integer startIndex
* Adds the remaining ids to the target list.
*/
    private void appendRemainingIds(List<Id> target, List<Id> source, Integer startIndex) {
        for (Integer r = startIndex; r < source.size(); r++) {
            target.add(source[r]);
        }
    }
    
    /**
Params: List<Id> target, List<List<Id>> batches, Integer startBatchIndex
* Adds ids from the remaining batches to the target list.
*/
    private void appendRemainingBatches(List<Id> target, List<List<Id>> batches, Integer startBatchIndex) {
        for (Integer b = startBatchIndex; b < batches.size(); b++) {
            for (Id remainingId : batches[b]) {
                target.add(remainingId);
            }
        }
    }
    
    /**
Params: List<ContentDocument> docs
* Groups ContentDocumentIds into heap-safe batches and returns the batch list.
*/
    private List<List<Id>> partitionBySize(List<ContentDocument> docs) {
        List<List<Id>> batches = new List<List<Id>>();
        List<Id> current = new List<Id>();
        Integer runningSum = 0;
        
        for (ContentDocument doc : docs) {
            Integer sizeInBytes = doc.ContentSize != null ? (Integer) doc.ContentSize : 0;
            if (!current.isEmpty() && runningSum + sizeInBytes > DocgenConstants.ZIP_BATCH_BYTES) {
                batches.add(current);
                current = new List<Id>();
                runningSum = 0;
            }
            
            current.add(doc.Id);
            runningSum += sizeInBytes;
        }
        
        if (!current.isEmpty()) {
            batches.add(current);
        }
        
        return batches;
    }
    
    /**
* Deletes temporary section files after the final output is created.
*/
    private void deleteSectionFiles() {
        if (cleanupDocIds == null || cleanupDocIds.isEmpty()) {
            return;
        }
        
        Set<Id> toDeleteIds = new Set<Id>(cleanupDocIds);
        if (toDeleteIds.isEmpty()) {
            return;
        }
        
        List<ContentDocument> toDelete = [
            SELECT Id
            FROM ContentDocument
            WHERE Id IN :toDeleteIds
        ];
        
        if (toDelete.isEmpty()) {
            return;
        }
        
        Database.DeleteResult[] results = Database.delete(
            toDelete,
            false,
            AccessLevel.SYSTEM_MODE
        );
        
        for (Database.DeleteResult result : results) {
            if (!result.isSuccess()) {
                for (Database.Error err : result.getErrors()) {
                    System.debug(
                        LoggingLevel.WARN,
                        'Failed to delete temporary section ContentDocument: ' + err.getMessage()
                    );
                }
            }
        }
    }
    
    /**
Params: String message
* Writes a debug log entry.
*/
    private void logDebug(String message) {
        System.debug(LoggingLevel.DEBUG, 'DocxAssemblerQueueable: ' + message);
    }
}