/**
 * DocxAssemblerQueueable
 * Final step in the section-ZIP async path.
 * Reads each section .docx Blob from ContentVersion, wraps them all into a
 * single .zip archive, stores it linked to the Case, then deletes the
 * individual section files.
 *
 * ── Heap profile ─────────────────────────────────────────────────────────────
 *   Each section .docx is ~0.4 MB compressed (XML ~90% compression ratio).
 *   Typical 13 sections × 0.4 MB = ~5.2 MB total Blob data read.
 *   ZipWriter output ≈ 5.2 MB.
 *   Peak: ~10.4 MB of 12 MB async limit ✓
 *
 *   For extreme cases (many MSP chunks): 20 sections × 0.4 MB = 8 MB still fits.
 */
public class DocxAssemblerQueueable implements Queueable {

    private Id       caseId;
    private List<Id> sectionDocIds;   // ContentDocumentIds from DocxSectionQueueable

    public DocxAssemblerQueueable(Id caseId, List<Id> sectionDocIds) {
        this.caseId        = caseId;
        this.sectionDocIds = sectionDocIds;
    }

    public void execute(QueueableContext ctx) {
        try {
            // Read all section .docx files in one query
            List<ContentVersion> sectionVersions = [
                SELECT ContentDocumentId, Title, VersionData
                FROM ContentVersion
                WHERE ContentDocumentId IN :sectionDocIds
                  AND IsLatest = true
                ORDER BY Title ASC   // alphabetical = numeric order (01_, 02_…)
            ];

            // Build the outer ZIP containing all section .docx files
            Compression.ZipWriter zip = new Compression.ZipWriter();
            for (ContentVersion cv : sectionVersions) {
                // Entry name is just the filename — no path prefix
                zip.addEntry(cv.Title, cv.VersionData);
            }
            Blob zipBlob = zip.getArchive();

            // Store the final .zip linked to the Case
            Case c = [SELECT CaseNumber FROM Case WHERE Id = :caseId LIMIT 1];
            String zipName = 'Ministers_Certificate_' + c.CaseNumber
                + '_' + Datetime.now().format('yyyyMMdd') + '.zip';

            ContentVersion finalCv = new ContentVersion();
            finalCv.Title                  = zipName;
            finalCv.PathOnClient           = zipName;
            finalCv.VersionData            = zipBlob;
            finalCv.FirstPublishLocationId = caseId;
            finalCv.SharingPrivacy         = 'N';
            finalCv.IsMajorVersion         = true;
            insert finalCv;

            // Delete the individual section files — user only needs the ZIP
            List<ContentDocument> toDelete = [
                SELECT Id FROM ContentDocument WHERE Id IN :sectionDocIds
            ];
            delete toDelete;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'DocxAssemblerQueueable failed: ' + e.getMessage()
                + '\n' + e.getStackTraceString());
        }
    }
}
