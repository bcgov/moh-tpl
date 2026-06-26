/**
 * DocxSingleDocumentQueueable
 * Async path for Minister's Certificate generation.
 *
 * Builds the same single printable .docx produced by the synchronous controller
 * path, but in a Queueable transaction. This avoids the previous async behavior
 * where the output was a .zip containing separate section documents, which did
 * not match the printing workflow and could appear to contain no printable data.
 */
public class DocxSingleDocumentQueueable implements Queueable {
    private Id caseId;

    public DocxSingleDocumentQueueable(Id caseId) {
        this.caseId = caseId;
    }

    public void execute(QueueableContext context) {
        try {
            DocxGeneratorController.generateSync(caseId);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'DocxSingleDocumentQueueable failed for Case ' + caseId + ': ' +
                e.getMessage() + '\n' + e.getStackTraceString());
            throw e;
        }
    }
}
