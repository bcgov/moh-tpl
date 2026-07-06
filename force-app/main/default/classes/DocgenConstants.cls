/**
* Author: Nikhil Jeenru
* Company: CGI
* Purpose:
* Stores shared document generation constants and metadata-backed configuration values.
*/
public class DocgenConstants {
    /**
    * Prevents this constants class from being instantiated.
    */
    private DocgenConstants() {}
   
    public static final String TEMPLATE_MINISTERS_CERTIFICATE_ID = 'ministersCertificate';
    public static final String TEMPLATE_CASE_HISTORY_ID = 'caseHistory';
    public static final String ASYNC_RESPONSE_PREFIX = 'ASYNC:';
    public static final String PIPE_DELIMITER = '|';

    public static final String XML_DECLARATION = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>';

    public static final Integer DOCX_TABLE_COLUMN_WIDTH_COUNT = 18;
    public static final Integer DOCX_TABLE_TEXT_SIZE_HALF_POINTS = 20;
    public static final String TABLE_HORIZONTAL_ALIGN_LEFT = 'left';
    public static final String TABLE_HORIZONTAL_ALIGN_RIGHT = 'right';
    public static final String TABLE_VERTICAL_ALIGN_TOP = 'top';
    public static final String TABLE_VERTICAL_ALIGN_CENTER = 'center';
    public static final String TABLE_VERTICAL_ALIGN_BOTTOM = 'bottom';

    public static final List<Integer> CASE_APPENDIX_TABLE_COLUMN_WIDTHS = new List<Integer>{ 4322, 4318, 3780 };
    public static final List<Integer> CASE_DETAIL_TABLE_COLUMN_WIDTHS = new List<Integer>{ 4322, 3868, 4860 };
    public static final List<Integer> PAST_AND_FUTURE_CARE_TABLE_COLUMN_WIDTHS = new List<Integer>{ 6475, 2700 };
    public static final List<Integer> AMBULANCE_TABLE_COLUMN_WIDTHS = new List<Integer>{ 1792, 3690, 4320, 2520 };
    public static final List<Integer> HOSPITAL_TABLE_COLUMN_WIDTHS = new List<Integer>{ 1526, 1526, 2520, 2880, 1526, 2434 };
    public static final List<Integer> MSP_TABLE_COLUMN_WIDTHS = new List<Integer>{ 1786, 2160, 2434, 2160, 1627, 1080, 2160 };
    public static final List<Integer> PHARMACARE_TABLE_COLUMN_WIDTHS = new List<Integer>{ 2146, 4507, 2347, 4406 };
    public static final List<Integer> CONTINUING_AND_FUTURE_CARE_TABLE_COLUMN_WIDTHS = new List<Integer>{ 8902, 3690 };
    public static final String ARIAL_FONT_NAME = 'Arial';
    public static final String TIMES_NEW_ROMAN_FONT_NAME = 'Times New Roman';
    public static final Integer BODY_TEXT_SIZE_HALF_POINTS = 24;
    public static final Integer TITLE_TEXT_SIZE_HALF_POINTS = 28;
    public static final Integer SMALL_TEXT_SIZE_HALF_POINTS = 22;
    public static final Integer DOCX_DXA_ZERO = 0;
    public static final Integer DOCX_DXA_ONE_INCH = 1440;
    public static final String WORD_TYPE_DXA = 'dxa';
    public static final String WORD_TYPE_AUTO = 'auto';
    public static final String WORD_COLOR_AUTO = 'auto';
    public static final String WORD_TBL_LOOK_DEFAULT = '04A0';
    public static final Integer WORD_ZERO = DOCX_DXA_ZERO;
    public static final Integer WORD_CELL_MARGIN_SUMMARY_VERTICAL_DXA = 40;
    public static final Integer WORD_CELL_MARGIN_DETAIL_DXA = 45;
    public static final Integer WORD_CELL_MARGIN_SUMMARY_HORIZONTAL_DXA = 120;
    public static final Integer WORD_SECTION_LABEL_SPACING_BEFORE_DXA = 80;
    public static final Integer WORD_LINE_SPACING_SINGLE_DXA = 240;
    public static final Integer WORD_INDENT_HANGING_DXA = 360;
    public static final Integer WORD_INDENT_FIRST_LINE_DXA = 720;
    public static final Integer WORD_SIGNATURE_INDENT_LEFT_DXA = 5040;
    public static final Integer WORD_SECTION_COLUMNS_SPACE_DXA = 708;
    public static final Integer WORD_DOC_GRID_LINE_PITCH_DXA = 360;
    public static final Integer WORD_BORDER_SIZE_OUTSET = 6;
    public static final Integer WORD_BORDER_SIZE_HAIRLINE = 2;
    public static final Integer WORD_DETAIL_TABLE_WIDTH_DXA = 13050;
    public static final Integer PAGE1_WIDTH_DXA = 12240;
    public static final Integer PAGE1_HEIGHT_DXA = 15840;
    public static final Integer PAGE1_MARGIN_TOP_DXA = DOCX_DXA_ONE_INCH;
    public static final Integer PAGE1_MARGIN_BOTTOM_DXA = DOCX_DXA_ONE_INCH;
    public static final Integer PAGE1_MARGIN_LEFT_DXA = 1134;
    public static final Integer PAGE1_MARGIN_RIGHT_DXA = 1797;
    public static final Integer PAGE1_FOOTER_MARGIN_DXA = 576;
    public static final Integer PAGE2_WIDTH_DXA = 15840;
    public static final Integer PAGE2_HEIGHT_DXA = 12240;
    public static final Integer PAGE2_MARGIN_TOP_DXA = 1134;
    public static final Integer PAGE2_MARGIN_BOTTOM_DXA = 1797;
    public static final Integer PAGE2_MARGIN_LEFT_RIGHT_DXA = DOCX_DXA_ONE_INCH;
    public static final Integer PAGE2_FOOTER_MARGIN_DXA = 576;
    public static final String DEFAULT_LOGO_STATIC_RESOURCE = 'BC_MInistry_LOGO';
    public static final String LANDSCAPE_WATERMARK_HEADER_REL_ID = 'rId4';
    public static final String EMPTY_HEADER_REL_ID = 'rId5';
    public static final Integer ZIP_BATCH_BYTES = 3500000;
    public static final Integer ASYNC_HEAP_SOFT_LIMIT_BYTES = 9000000;
    public static final Integer TARGET_DOCX_SECTION_XML_SIZE_PER_FILE_BYTES = 2000000;
    public static final Integer MIN_ROWS_PER_DOCX_SECTION_FILE = 200;
    public static final Integer MAX_ROWS_PER_DOCX_SECTION_FILE = 1000;
    public static final Integer AMBULANCE_ROW_XML_SIZE_BYTES = 2000;
    public static final Integer HOSPITAL_ROW_XML_SIZE_BYTES = 2500;
    public static final Integer MSP_ROW_XML_SIZE_BYTES = 3000;
    public static final Integer PHARMACARE_ROW_XML_SIZE_BYTES = 2000;
    public static final Integer CONTINUING_AND_FUTURE_CARE_ROW_XML_SIZE_BYTES = 1000;
    public static final Integer CERTIFICATE_SECTION_INDEX = 0;
    public static final Integer AMBULANCE_SECTION_INDEX = 1;
    public static final Integer HOSPITAL_SECTION_INDEX = 2;
    public static final Integer MSP_SECTION_INDEX = 3;
    public static final Integer PHARMACARE_SECTION_INDEX = 4;
    public static final Integer CONTINUING_CARE_SECTION_INDEX = 5;
    public static final Integer FUTURE_CARE_SECTION_INDEX = 6;
    public static final Integer COMPLETED_SECTION_INDEX = 7;

}