/**
* Author: Nikhil Jeenru
* Company: CGI
* Purpose:
* Provides XML rendering helpers used by DOCX generation classes.
*/
public class DocxXmlRenderService {
    /**
* Prevents this service class from being instantiated.
*/
    private DocxXmlRenderService() {}
    
    /**
Params: String value
* Escapes XML special characters. Returns the escaped XML.
*/
    public static String escXml(String value) {
        if (value == null) return '';
        String cleaned = value
            .replaceAll('[\\u0000-\\u0008]', '')
            .replaceAll('[\\u000B\\u000C]', '')
            .replaceAll('[\\u000E-\\u001F]', '');
        return cleaned.replace('&','&amp;').replace('<','&lt;').replace('>','&gt;')
            .replace('"','&quot;').replace('\'','&apos;');
    }
    
    /**
Params: Integer dayNumber
* Gets the ordinal suffix for a day number. Returns st, nd, rd, or th.
*/
    public static String daySuffix(Integer dayNumber) {
        if (dayNumber == 1 || dayNumber == 21 || dayNumber == 31) {
            return 'st';
        }
        if (dayNumber == 2 || dayNumber == 22) {
            return 'nd';
        }
        if (dayNumber == 3 || dayNumber == 23) {
            return 'rd';
        }
        return 'th';
    }
}