/**
* Author: Nikhil Jeenru
* Company: CGI
* Purpose:
* Provides shared DOCX formatting, filename, and ContentDocument helper methods.
*/
public class DocxFormatHelper {
    /**
* Prevents this helper class from being instantiated.
*/
    private DocxFormatHelper() {}
    
    /**
Params: Object value
* Converts an object to a null-safe string. Returns an empty string for null, otherwise String.valueOf(value).
*/
    public static String stringValue(Object value) {
        return value == null ? '' : String.valueOf(value);
    }
    
    /**
Params: Decimal value
* Converts a Decimal to a null-safe Decimal. Returns 0 for null, otherwise the original Decimal value.
*/
    public static Decimal decimalValue(Decimal value) {
        return value != null ? value : 0;
    }
    
    /**
Params: Date value
* Formats a Date for the DOCX. Returns an empty string for null, otherwise the formatted date String.
*/
    public static String formatDate(Date value) {
        if (value == null) return '';
        String yyyy = String.valueOf(value.year());
        String mm = String.valueOf(value.month()).leftPad(2, '0');
        String dd = String.valueOf(value.day()).leftPad(2, '0');
        return yyyy + '-' + mm + '-' + dd;
    }
    
    /**
Params: Decimal value
* Formats a Decimal as currency. Returns $0.00 for null, otherwise the formatted currency String.
*/
    public static String formatCurrency(Decimal value) {
        String formatted = ((value == null ? Decimal.valueOf(0) : value).setScale(2)).format();
        Integer dot = formatted.indexOf('.');
        return '$' + (dot < 0 ? formatted + '.00' : formatted + (formatted.length() - dot == 2 ? '0' : ''));
    }
    
    /**
* Gets the current month name. Returns the current month name String.
*/
    public static String currentMonthName() {
        return DateTime.newInstance(
            Date.today(),
            Time.newInstance(0, 0, 0, 0)
        ).format('MMMM');
    }
    
    
    /**
Params: String selectedTemplate, String fileExtension
* Builds the generated file name. Returns the selected template name plus the formatted timestamp and file extension.
*/
    public static String generatedFileName(String selectedTemplate, String fileExtension) {
        String filePrefix = String.isNotBlank(selectedTemplate) && selectedTemplate.contains(TPL_Constants.DOCGEN_TEMPLATE_CASE_HISTORY) ? TPL_Constants.DOCGEN_FILE_PREFIX_CASE_HISTORY : TPL_Constants.DOCGEN_FILE_PREFIX_MINISTERS_CERTIFICATE;
        return filePrefix + ' ' + Datetime.now().format('MMMM dd, yyyy') + '.' + fileExtension;
    }
    
    /**
Params: Id parentId, String fileName, Blob fileBody, Boolean isMajorVersion
* Creates a ContentVersion and links it to the parent record. Returns the created ContentDocumentId.
*/
    public static Id createContentDocument(Id parentId, String fileName, Blob fileBody, Boolean isMajorVersion) {
        ContentVersion cv = new ContentVersion();
        cv.Title                  = fileName;
        cv.PathOnClient           = fileName;
        cv.VersionData            = fileBody;
        cv.FirstPublishLocationId = parentId;
        cv.SharingPrivacy         = 'N';
        if (isMajorVersion != null) {
            cv.IsMajorVersion = isMajorVersion;
        }
        insert cv;
        
        return [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1].ContentDocumentId;
    }
    
}