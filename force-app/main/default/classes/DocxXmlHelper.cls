/**
* Author: Nikhil Jeenru
* Company: CGI
* Purpose:
* Provides reusable WordprocessingML snippets for DOCX table and paragraph formatting.
*/
public class DocxXmlHelper {
    /**
    * Prevents this helper class from being instantiated.
    */
    private DocxXmlHelper() {}

    /**
    Params: String value
    * Builds justification XML. Returns the generated XML.
    */
    public static String jc(String value) {
        return '<w:jc w:val="' + value + '"/>';
    }

    /**
    Params: String styleName
    * Builds paragraph style XML. Returns the generated XML.
    */
    public static String paragraphStyle(String styleName) {
        return '<w:pStyle w:val="' + styleName + '"/>';
    }

    /**
    * Builds zero-after spacing XML. Returns the generated XML.
    */
    public static String spacingAfterZero() {
        return '<w:spacing w:after="0"/>';
    }

    /**
    * Builds single-line spacing XML. Returns the generated XML.
    */
    public static String spacingSingleLine() {
        return '<w:spacing w:after="0" w:line="' + DocgenConstants.WORD_LINE_SPACING_SINGLE_DXA + '" w:lineRule="auto"/>';
    }

    /**
    Params: Integer width
    * Builds table cell width XML. Returns the generated XML.
    */
    public static String cellWidth(Integer width) {
        return '<w:tcW w:w="' + width + '" w:type="' + DocgenConstants.WORD_TYPE_DXA + '"/>';
    }

    /**
    Params: List<Integer> widths
    * Builds table grid column XML. Returns the generated XML.
    */
    public static String gridCols(List<Integer> widths) {
        String grid = '';
        for (Integer width : widths) {
            grid += '<w:gridCol w:w="' + width + '"/>';
        }
        return grid;
    }

    /**
    * Builds table look XML. Returns the generated XML.
    */
    public static String tableLook() {
        return '<w:tblLook w:val="' + DocgenConstants.WORD_TBL_LOOK_DEFAULT + '" w:firstRow="1" w:lastRow="0" w:firstColumn="1" w:lastColumn="0" w:noHBand="0" w:noVBand="1"/>';
    }

    /**
    Params: String side, String value, Integer size
    * Builds border XML for one side. Returns the generated XML.
    */
    public static String border(String side, String value, Integer size) {
        return '<w:' + side + ' w:val="' + value + '" w:sz="' + size + '" w:space="0" w:color="' + DocgenConstants.WORD_COLOR_AUTO + '"/>';
    }

    /**
    Params: String value, Integer size
    * Builds table borders XML. Returns the generated XML.
    */
    public static String tableBorders(String value, Integer size) {
        String borders = '';
        for (String side : new List<String>{ 'top', 'left', 'bottom', 'right', 'insideH', 'insideV' }) {
            borders += border(side, value, size);
        }
        return borders;
    }

    /**
    Params: String value, Integer size
    * Builds outside border XML. Returns the generated XML.
    */
    public static String outsideBorders(String value, Integer size) {
        String borders = '';
        for (String side : new List<String>{ 'top', 'left', 'bottom', 'right' }) {
            borders += border(side, value, size);
        }
        return borders;
    }

    /**
    * Builds summary cell margin XML. Returns the generated XML.
    */
    public static String summaryCellMargins() {
        return '<w:tcMar><w:top w:w="' + DocgenConstants.WORD_CELL_MARGIN_SUMMARY_VERTICAL_DXA + '" w:type="dxa"/>'
            + '<w:bottom w:w="' + DocgenConstants.WORD_CELL_MARGIN_SUMMARY_VERTICAL_DXA + '" w:type="dxa"/>'
            + '<w:left w:w="' + DocgenConstants.WORD_CELL_MARGIN_SUMMARY_HORIZONTAL_DXA + '" w:type="dxa"/>'
            + '<w:right w:w="' + DocgenConstants.WORD_CELL_MARGIN_SUMMARY_HORIZONTAL_DXA + '" w:type="dxa"/></w:tcMar>';
    }
}