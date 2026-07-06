/**
* Author: Nikhil Jeenru
* Company: CGI
* Purpose:
* Builds standalone DOCX section files and chains section generation for large documents.
*/
public class DocxSectionQueueable implements Queueable {
    
    
    private class SectionConfig {
        private String hcType;
        private String fileLabel;
        private Integer bytesPerRow;
        
        /**
Params: String hcType, String fileLabel, Integer bytesPerRow
* Stores the section type, file label, and row-size estimate.
*/
        private SectionConfig(String hcType, String fileLabel, Integer bytesPerRow) {
            this.hcType = hcType;
            this.fileLabel = fileLabel;
            this.bytesPerRow = bytesPerRow;
        }
    }
    
    /**
* Builds the section configuration map and returns it by section index.
*/
    private static Map<Integer, SectionConfig> sectionConfigByIndex() {
        return new Map<Integer, SectionConfig>{
            DocgenConstants.AMBULANCE_SECTION_INDEX   => new SectionConfig(TPL_Constants.HCC_AMB_RECORDTYPE_NAME,    TPL_Constants.HCC_AMB_RECORDTYPE_NAME,    DocgenConstants.AMBULANCE_ROW_XML_SIZE_BYTES),
                DocgenConstants.HOSPITAL_SECTION_INDEX  => new SectionConfig(TPL_Constants.HCC_HOSP_RECORDTYPE_NAME,   System.Label.TPL_DocGen_Doc_Section_Hospital,         DocgenConstants.HOSPITAL_ROW_XML_SIZE_BYTES),
                DocgenConstants.MSP_SECTION_INDEX   => new SectionConfig(TPL_Constants.HCC_MSP_RECORDTYPE_NAME,    TPL_Constants.HCC_MSP_RECORDTYPE_NAME,    DocgenConstants.MSP_ROW_XML_SIZE_BYTES),
                DocgenConstants.PHARMACARE_SECTION_INDEX => new SectionConfig(TPL_Constants.HCC_PHARMA_RECORDTYPE_NAME, TPL_Constants.HCC_PHARMA_RECORDTYPE_NAME, DocgenConstants.PHARMACARE_ROW_XML_SIZE_BYTES),
                DocgenConstants.CONTINUING_CARE_SECTION_INDEX    => new SectionConfig(TPL_Constants.HCC_CC_RECORDTYPE_NAME,     TPL_Constants.HCC_CC_RECORDTYPE_NAME,     DocgenConstants.CONTINUING_AND_FUTURE_CARE_ROW_XML_SIZE_BYTES),
                DocgenConstants.FUTURE_CARE_SECTION_INDEX    => new SectionConfig(TPL_Constants.HCC_FC_RECORDTYPE_NAME,     TPL_Constants.HCC_FC_RECORDTYPE_NAME,     DocgenConstants.CONTINUING_AND_FUTURE_CARE_ROW_XML_SIZE_BYTES)
                };
                    }
    private Id      caseId;
    private Integer sectionIndex;        // current section being built
    private String  lastProcessedDateId; // keyset cursor (DateId__c) within current section
    private Integer chunkWithinSection;  // 1-based, for file naming (MSP Part 1, Part 2…)
    private String  caseNumber;
    private String  sigName;
    private String  sigTitle;
    private String  selectedTemplate;
    private List<Id> sectionDocIds;
    
    /**
Params: Id caseId, Integer sectionIndex, String lastProcessedDateId, Integer chunkWithinSection, String caseNumber, String sigName, String sigTitle, String selectedTemplate, List<Id> sectionDocIds
* Initializes a section queueable for the selected template.
*/
    public DocxSectionQueueable(
        Id caseId, Integer sectionIndex, String lastProcessedDateId, Integer chunkWithinSection,
        String caseNumber, String sigName, String sigTitle,
        String selectedTemplate, List<Id> sectionDocIds) {
            this.caseId              = caseId;
            this.sectionIndex        = sectionIndex;
            this.lastProcessedDateId = lastProcessedDateId;
            this.chunkWithinSection  = chunkWithinSection;
            this.caseNumber          = caseNumber;
            this.sigName             = sigName;
            this.sigTitle            = sigTitle;
            this.selectedTemplate    = selectedTemplate == null ? TPL_Constants.DOCGEN_TEMPLATE_MINISTERS_CERTIFICATE : selectedTemplate;
            this.sectionDocIds       = sectionDocIds == null ? new List<Id>() : sectionDocIds;
        }
    
    /**
Params: Id caseId, Integer sectionIndex, String lastProcessedDateId, Integer chunkWithinSection, String caseNumber, String contactName, String phn, String claimNumber, String incidentDate, String birthDate, String sigName, String sigTitle, String ambulanceTotal, String hospitalTotal, String medicalTotal, String pharmacyTotal, String continuingCareTotal, String futureCareTotal, String pastServicesTotal, String futureServicesTotal, String totalCost, List<Id> sectionDocIds
* Initializes the legacy section queueable constructor.
*/
    public DocxSectionQueueable(
        Id caseId, Integer sectionIndex, String lastProcessedDateId, Integer chunkWithinSection,
        String caseNumber, String contactName, String phn, String claimNumber,
        String incidentDate, String birthDate, String sigName, String sigTitle,
        String ambulanceTotal, String hospitalTotal, String medicalTotal,
        String pharmacyTotal, String continuingCareTotal, String futureCareTotal,
        String pastServicesTotal, String futureServicesTotal, String totalCost,
        List<Id> sectionDocIds) {
            this(caseId, sectionIndex, lastProcessedDateId, chunkWithinSection,
                 caseNumber, sigName, sigTitle,
                 TPL_Constants.DOCGEN_TEMPLATE_MINISTERS_CERTIFICATE, sectionDocIds);
        }
    
    /**
Params: Id caseId, Integer sectionIndex, String lastProcessedDateId, Integer chunkWithinSection, String caseNumber, String contactName, String phn, String claimNumber, String incidentDate, String birthDate, String sigName, String sigTitle, String ambulanceTotal, String hospitalTotal, String medicalTotal, String pharmacyTotal, String continuingCareTotal, String futureCareTotal, String pastServicesTotal, String futureServicesTotal, String totalCost, String selectedTemplate, List<Id> sectionDocIds
* Initializes the legacy section queueable constructor with a selected template.
*/
    public DocxSectionQueueable(
        Id caseId, Integer sectionIndex, String lastProcessedDateId, Integer chunkWithinSection,
        String caseNumber, String contactName, String phn, String claimNumber,
        String incidentDate, String birthDate, String sigName, String sigTitle,
        String ambulanceTotal, String hospitalTotal, String medicalTotal,
        String pharmacyTotal, String continuingCareTotal, String futureCareTotal,
        String pastServicesTotal, String futureServicesTotal, String totalCost,
        String selectedTemplate, List<Id> sectionDocIds) {
            this(caseId, sectionIndex, lastProcessedDateId, chunkWithinSection,
                 caseNumber, sigName, sigTitle, selectedTemplate, sectionDocIds);
        }
    
    /**
Params: QueueableContext ctx
* Runs the queueable job.
*/
    public void execute(QueueableContext ctx) {
        try {
            executeSection();
        } catch (Exception e) {
            String stackTrace = e.getStackTraceString();
            System.debug(LoggingLevel.ERROR,
                         'DocxSectionQueueable failed (section ' + sectionIndex + '): '
                         + e.getMessage() + '\n' + stackTrace);
            LogService.markDocxGenerationFailed(
                null,
                Id.valueOf(caseId),
                String.valueOf(ctx.getJobId()),
                String.valueOf(e.getMessage()),
                stackTrace,
                'DocxSectionQueueable',
                'execute'
            );
        }
    }
    
    /**
* Builds the current section and queues the next step when needed.
*/
    private void executeSection() {
        if (sectionIndex == DocgenConstants.CERTIFICATE_SECTION_INDEX) {
            Case c = buildCaseShell();
            List<Id> nextIds = new List<Id>(sectionDocIds);
            if (!(String.isNotBlank(selectedTemplate) && selectedTemplate.contains(TPL_Constants.DOCGEN_TEMPLATE_CASE_HISTORY))) {
                nextIds.add(buildCertificateDoc(c));
            }
            nextIds.add(buildTotalsDoc(c));
            System.enqueueJob(makeNext(DocgenConstants.AMBULANCE_SECTION_INDEX, null, 1, nextIds));
            return;
        }
        if (sectionIndex == DocgenConstants.COMPLETED_SECTION_INDEX) {
            System.enqueueJob(new DocxAssemblerQueueable(caseId, sectionDocIds, selectedTemplate));
            return;
        }
        
        String hcType = sectionHcType(sectionIndex);
        List<Healthcare_Cost__c> rows = queryRows(hcType);
        if (rows.isEmpty() && chunkWithinSection == 1) {
            System.enqueueJob(makeNext(sectionIndex + 1, null, 1, sectionDocIds));
            return;
        }
        
        Integer rowsLimit = rowsPerDocForSection(sectionIndex);
        Boolean isLastChunk = rows.size() < rowsLimit;
        String newLastDateId = rows.isEmpty() ? null : rows[rows.size() - 1].DateId__c;
        Id docId = buildSectionDoc(hcType, rows, isLastChunk);
        
        List<Id> nextIds = new List<Id>(sectionDocIds);
        nextIds.add(docId);
        
        if (!isLastChunk) {
            System.enqueueJob(makeNext(sectionIndex, newLastDateId, chunkWithinSection + 1, nextIds));
        } else {
            System.enqueueJob(makeNext(sectionIndex + 1, null, 1, nextIds));
        }
    }
    
    /**
* Builds the Minister's Certificate page as a standalone .docx.
* Async detail section files should not repeat this page.
*/
    private Id buildCertificateDoc(Case c) {
        Blob docx = baseBuilder(c).buildCertificateOnly();
        
        return saveSection(docx, '01_Ministers_Certificate_Summary');
    }
    
    /**
* Builds the Appendix A totals/summary page as a standalone .docx.
* Async detail section files should not repeat this page.
*/
    private Id buildTotalsDoc(Case c) {
        Blob docx = baseBuilder(c).buildTotalsOnly();
        
        return saveSection(docx, '02_Totals');
    }
    
    /**
* Builds one section .docx containing only the section detail for one HC type
* (up to the BPR-based row limit). Certificate and totals pages are generated once
* as separate files at the start of the async chain.
* For multi-chunk types (e.g. MSP with 8,000 rows), each chunk becomes a
* separate .docx named MSP_Part1, MSP_Part2 etc.
*/
    private Id buildSectionDoc(String hcType, List<Healthcare_Cost__c> rows, Boolean isFinalChunk) {
        DocxBuilder builder = baseBuilder(buildCaseShell())
            .setIncludeDetailSectionHeader(chunkWithinSection == 1)
            .setIncludeDetailSectionTotal(isFinalChunk)
            .setIncludeDetailSectionLabel(chunkWithinSection == 1)
            .setIncludeDetailColumnHeader(chunkWithinSection == 1);
        
        applyRowsToBuilder(builder, hcType, rows);
        
        Blob docx = builder.buildDetailsOnly();
        
        String sectionLabel = sectionFileLabel(hcType);
        String chunkSuffix  = chunkWithinSection > 1 || !isFinalChunk
            ? '_Part' + String.valueOf(chunkWithinSection).leftPad(2, '0')
            : '';
        return saveSection(docx, sectionLabel + chunkSuffix);
    }
    
    
    
    /**
Params: DocxBuilder builder, String hcType, List<Healthcare_Cost__c> rows
* Applies the section rows to the matching builder section.
*/
    private void applyRowsToBuilder(DocxBuilder builder, String hcType, List<Healthcare_Cost__c> rows) {
        if (hcType == TPL_Constants.HCC_AMB_RECORDTYPE_NAME) {
            builder.setAmbulanceRecords(rows);
        } else if (hcType == TPL_Constants.HCC_HOSP_RECORDTYPE_NAME) {
            builder.setHospitalRecords(rows);
        } else if (hcType == TPL_Constants.HCC_MSP_RECORDTYPE_NAME) {
            builder.setMSPRecords(rows);
        } else if (hcType == TPL_Constants.HCC_PHARMA_RECORDTYPE_NAME) {
            builder.setPharmaRecords(rows);
        } else if (hcType == TPL_Constants.HCC_CC_RECORDTYPE_NAME) {
            builder.setContinuingCareRecords(rows);
        } else if (hcType == TPL_Constants.HCC_FC_RECORDTYPE_NAME) {
            builder.setFutureCareRecords(rows);
        }
    }
    
    /**
Params: Case c
* Builds the base DOCX builder for the Case. Returns the configured DocxBuilder instance.
*/
    private DocxBuilder baseBuilder(Case c) {
        return new DocxBuilder()
            .setCaseData(c)
            .setSigningAuthority(sigName, sigTitle)
            .setDocumentType(selectedTemplate);
    }
    
    /**
* Loads the Case fields required by DocxBuilder for the current queueable execution.
*/
    private Case buildCaseShell() {
        return [
            SELECT Id,
            CaseNumber,
            Claim_Number__c,
            ContactName__c,
            PHN__c,
            Incident_Date__c,
            Date_of_Birth__c,
            Ambulance_Total2__c,
            Hospitalization_Total2__c,
            MSP_Total2__c,
            Pharmacare_Total2__c,
            Continuing_Care_Total2__c,
            Future_Care_Total2__c,
            Total_Case_Value__c
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
    }
    
    /**
Params: Blob docx, String sectionLabel
* Saves a generated section DOCX file. Returns the created ContentDocumentId.
*/
    private Id saveSection(Blob docx, String sectionLabel) {
        String prefix   = String.valueOf(sectionIndex).leftPad(2, '0');
        String fileName = prefix + '_' + sectionLabel + '_' + caseNumber + '.docx';
        return DocxFormatHelper.createContentDocument(caseId, fileName, docx, false);
    }
    
    /**
Params: String hcType
* Queries Healthcare Cost rows for the current section. Returns the matching Healthcare Cost records.
*/
    private List<Healthcare_Cost__c> queryRows(String hcType) {
        Integer rowsLimit = rowsPerDocForSection(sectionIndex);
        if (hcType == TPL_Constants.HCC_AMB_RECORDTYPE_NAME) {
            return queryAmbulanceRows(hcType, rowsLimit);
        } else if (hcType == TPL_Constants.HCC_HOSP_RECORDTYPE_NAME) {
            return queryHospitalRows(hcType, rowsLimit);
        } else if (hcType == TPL_Constants.HCC_MSP_RECORDTYPE_NAME) {
            return queryMspRows(hcType, rowsLimit);
        } else if (hcType == TPL_Constants.HCC_PHARMA_RECORDTYPE_NAME) {
            return queryPharmaRows(hcType, rowsLimit);
        }
        return queryCareRows(hcType, rowsLimit);
    }
    
    /**
Params: String hcType, Integer rowsLimit
* Queries ambulance Healthcare Cost rows. Returns the matching Healthcare Cost records.
*/
    private List<Healthcare_Cost__c> queryAmbulanceRows(String hcType, Integer rowsLimit) {
        return lastProcessedDateId == null
            ? [SELECT Id, DateId__c, Date_of_Service__c, Location_Responded__c,
               FacilityName__c, Facility_Name__c, Total_Cost_Override__c
               FROM Healthcare_Cost__c
               WHERE Case2__c = :caseId AND RecordTypeName__c = :hcType
               AND Cost_Include__c = true AND Cost_Review__c = true
               ORDER BY DateId__c ASC LIMIT :rowsLimit]
            : [SELECT Id, DateId__c, Date_of_Service__c, Location_Responded__c,
               FacilityName__c, Facility_Name__c, Total_Cost_Override__c
               FROM Healthcare_Cost__c
               WHERE Case2__c = :caseId AND RecordTypeName__c = :hcType
               AND Cost_Include__c = true AND Cost_Review__c = true
               AND DateId__c > :lastProcessedDateId
               ORDER BY DateId__c ASC LIMIT :rowsLimit];
                   }
    
    /**
Params: String hcType, Integer rowsLimit
* Queries hospital Healthcare Cost rows. Returns the matching Healthcare Cost records.
*/
    private List<Healthcare_Cost__c> queryHospitalRows(String hcType, Integer rowsLimit) {
        return lastProcessedDateId == null
            ? [SELECT Id, DateId__c, Date_of_Admission__c, Date_of_Discharge__c,
               FacilityName__c, Facility_Name__c, Service_Type2__c,
               Number_of_Days__c, Total_Cost_Override__c, Total_Costs_Standard__c
               FROM Healthcare_Cost__c
               WHERE Case2__c = :caseId AND RecordTypeName__c = :hcType
               AND Cost_Include__c = true AND Cost_Review__c = true
               ORDER BY DateId__c ASC LIMIT :rowsLimit]
            : [SELECT Id, DateId__c, Date_of_Admission__c, Date_of_Discharge__c,
               FacilityName__c, Facility_Name__c, Service_Type2__c,
               Number_of_Days__c, Total_Cost_Override__c, Total_Costs_Standard__c
               FROM Healthcare_Cost__c
               WHERE Case2__c = :caseId AND RecordTypeName__c = :hcType
               AND Cost_Include__c = true AND Cost_Review__c = true
               AND DateId__c > :lastProcessedDateId
               ORDER BY DateId__c ASC LIMIT :rowsLimit];
                   }
    
    /**
Params: String hcType, Integer rowsLimit
* Queries MSP Healthcare Cost rows. Returns the matching Healthcare Cost records.
*/
    private List<Healthcare_Cost__c> queryMspRows(String hcType, Integer rowsLimit) {
        return lastProcessedDateId == null
            ? [SELECT Id, DateId__c, Date_of_Service__c, Location_Type_Code__c,
               Location_Type_Description2__c, Description_of_Service2__c,
               Fee_Item_Title__c, Diagnostic_Description__c,
               Total_Cost_Override__c, Practitioner_Name__c
               FROM Healthcare_Cost__c
               WHERE Case2__c = :caseId AND RecordTypeName__c = :hcType
               AND Cost_Include__c = true AND Cost_Review__c = true
               ORDER BY DateId__c ASC LIMIT :rowsLimit]
            : [SELECT Id, DateId__c, Date_of_Service__c, Location_Type_Code__c,
               Location_Type_Description2__c, Description_of_Service2__c,
               Fee_Item_Title__c, Diagnostic_Description__c,
               Total_Cost_Override__c, Practitioner_Name__c
               FROM Healthcare_Cost__c
               WHERE Case2__c = :caseId AND RecordTypeName__c = :hcType
               AND Cost_Include__c = true AND Cost_Review__c = true
               AND DateId__c > :lastProcessedDateId
               ORDER BY DateId__c ASC LIMIT :rowsLimit];
                   }
    
    /**
Params: String hcType, Integer rowsLimit
* Queries PharmaCare Healthcare Cost rows. Returns the matching Healthcare Cost records.
*/
    private List<Healthcare_Cost__c> queryPharmaRows(String hcType, Integer rowsLimit) {
        return lastProcessedDateId == null
            ? [SELECT Id, DateId__c, Date_of_Service__c, Name_of_Drug__c,
               Total_Cost_Override__c, Practitioner_Name__c
               FROM Healthcare_Cost__c
               WHERE Case2__c = :caseId AND RecordTypeName__c = :hcType
               AND Cost_Include__c = true AND Cost_Review__c = true
               ORDER BY DateId__c ASC LIMIT :rowsLimit]
            : [SELECT Id, DateId__c, Date_of_Service__c, Name_of_Drug__c,
               Total_Cost_Override__c, Practitioner_Name__c
               FROM Healthcare_Cost__c
               WHERE Case2__c = :caseId AND RecordTypeName__c = :hcType
               AND Cost_Include__c = true AND Cost_Review__c = true
               AND DateId__c > :lastProcessedDateId
               ORDER BY DateId__c ASC LIMIT :rowsLimit];
                   }
    
    /**
Params: String hcType, Integer rowsLimit
* Queries continuing/future care Healthcare Cost rows. Returns the matching Healthcare Cost records.
*/
    private List<Healthcare_Cost__c> queryCareRows(String hcType, Integer rowsLimit) {
        return lastProcessedDateId == null
            ? [SELECT Id, DateId__c, Description__c, Cost__c FROM Healthcare_Cost__c
               WHERE Case2__c = :caseId AND RecordTypeName__c = :hcType
               ORDER BY DateId__c ASC LIMIT :rowsLimit]
            : [SELECT Id, DateId__c, Description__c, Cost__c FROM Healthcare_Cost__c
               WHERE Case2__c = :caseId AND RecordTypeName__c = :hcType
               AND DateId__c > :lastProcessedDateId
               ORDER BY DateId__c ASC LIMIT :rowsLimit];
                   }
    
    /**
Params: Integer idx
* Calculates rows per DOCX section file. Returns the bounded row count for the section index.
*/
    private static Integer rowsPerDocForSection(Integer idx) {
        SectionConfig config = sectionConfigByIndex().get(idx);
        return config == null ? DocgenConstants.MAX_ROWS_PER_DOCX_SECTION_FILE : boundedRows(config.bytesPerRow);
    }
    
    /**
Params: Integer bytesPerRow
* Calculates the row count from target XML size and bytes per row. Returns a value between the configured minimum and maximum rows per section file.
*/
    private static Integer boundedRows(Integer bytesPerRow) {
        Integer calculatedRows = DocgenConstants.TARGET_DOCX_SECTION_XML_SIZE_PER_FILE_BYTES / bytesPerRow;
        if (calculatedRows < DocgenConstants.MIN_ROWS_PER_DOCX_SECTION_FILE) return DocgenConstants.MIN_ROWS_PER_DOCX_SECTION_FILE;
        if (calculatedRows > DocgenConstants.MAX_ROWS_PER_DOCX_SECTION_FILE) return DocgenConstants.MAX_ROWS_PER_DOCX_SECTION_FILE;
        return calculatedRows;
    }
    
    private DocxSectionQueueable makeNext(Integer nextIdx, String nextLastDateId,
                                          Integer nextChunk, List<Id> nextDocIds) {
                                              return new DocxSectionQueueable(
                                                  caseId, nextIdx, nextLastDateId, nextChunk,
                                                  caseNumber, sigName, sigTitle, selectedTemplate, nextDocIds
                                              );
                                          }
    
    /**
Params: Integer idx
* Resolves the Healthcare Cost type for a section index. Returns the Healthcare Cost type.
*/
    private String sectionHcType(Integer idx) {
        SectionConfig config = sectionConfigByIndex().get(idx);
        return config == null ? TPL_Constants.HCC_FC_RECORDTYPE_NAME : config.hcType;
    }
    
    /**
Params: String hcType
* Builds the generated section file label. Returns the section file label.
*/
    private String sectionFileLabel(String hcType) {
        for (SectionConfig config : sectionConfigByIndex().values()) {
            if (config.hcType == hcType) {
                return config.fileLabel;
            }
        }
        return TPL_Constants.HCC_FC_RECORDTYPE_NAME;
    }
    
    
}