/**
* Author: Nikhil Jeenru
* Company: CGI
* Purpose:
* Test coverage for DocxBuilder document creation scenarios, including full DOCX generation,
* split document generation, healthcare detail sections, fallback values, template options,
* continuation chunk behavior, and shared DOCX constants.
*/
@IsTest
private class DocxBuilderTest {
    
    @IsTest
    static void buildCreatesDocxBlobWithoutHealthcareRows() {
        // Verifies the most basic happy path: a Case can produce a DOCX even when
        // there are no healthcare cost rows to render in the detail sections.
        Case c = DocxTestDataFactory.createCaseRecord();
        
        Test.startTest();
        Blob docx = baseBuilder(c).build();
        Test.stopTest();
        
        System.assertNotEquals(null, docx, 'DocxBuilder should return a non-null DOCX blob.');
        System.assert(docx.size() > 0, 'DocxBuilder should generate a non-empty DOCX blob.');
    }
    
    @IsTest
    static void splitBuildMethodsCreateDocxBlobsWithoutHealthcareRows() {
        // Confirms the split-output entry points still generate valid files when
        // the document has only Case/signature data and no healthcare detail rows.
        Case c = DocxTestDataFactory.createCaseRecord();
        
        Test.startTest();
        Blob certificateDocx = baseBuilder(c).buildCertificateOnly();
        Blob totalsDocx = baseBuilder(c).buildTotalsOnly();
        Blob detailsDocx = baseBuilder(c).buildDetailsOnly();
        Test.stopTest();
        
        System.assertNotEquals(null, certificateDocx, 'Certificate-only DOCX should be generated.');
        System.assertNotEquals(null, totalsDocx, 'Totals-only DOCX should be generated.');
        System.assertNotEquals(null, detailsDocx, 'Details-only DOCX should be generated.');
        System.assert(certificateDocx.size() > 0, 'Certificate-only DOCX should not be empty.');
        System.assert(totalsDocx.size() > 0, 'Totals-only DOCX should not be empty.');
        System.assert(detailsDocx.size() > 0, 'Details-only DOCX should not be empty.');
    }
    
    @IsTest
    static void buildWithAllHealthcareCostTypesCreatesAllDetailSections() {
        // Covers the full healthcare-detail scenario where every supported cost type
        // has at least one row, so the generated XML should include every section.
        Case c = DocxTestDataFactory.createCaseRecord();
        
        DocxBuilder builder = baseBuilder(c)
            .setAmbulanceRecords(ambulanceRows())
            .setHospitalRecords(hospitalRows())
            .setMSPRecords(mspRows())
            .setPharmaRecords(pharmaRows())
            .setContinuingCareRecords(continuingCareRows())
            .setFutureCareRecords(futureCareRows());
        
        Test.startTest();
        String xml = builder.buildAllDetailSectionsXml();
        Blob fullDocx = builder.build();
        Blob detailsDocx = builder.buildDetailsOnly();
        Test.stopTest();
        
        System.assertNotEquals(null, xml, 'Detail XML should be generated.');
        System.assert(xml.contains(System.Label.TPL_DocGen_Doc_Section_Ambulance), 'Ambulance section should be included.');
        System.assert(xml.contains(System.Label.TPL_DocGen_Doc_Section_Hospital), 'Hospital section should be included.');
        System.assert(xml.contains(System.Label.TPL_DocGen_Doc_Section_Medical), 'MSP/Medical section should be included.');
        System.assert(xml.contains(System.Label.TPL_DocGen_Doc_Section_Pharmacare), 'PharmaCare section should be included.');
        System.assert(xml.contains(System.Label.TPL_DocGen_Doc_Section_Continuing_Care), 'Continuing Care section should be included.');
        System.assert(xml.contains(System.Label.TPL_DocGen_Doc_Section_Future_Care), 'Future Care section should be included.');
        
        // These assertions check the human-facing values that should appear in the DOCX XML,
        // including XML escaping and trimmed/fallback display text.
        System.assert(xml.contains('Scene &amp; Road'), 'Ambulance origin should be XML escaped and included.');
        System.assert(xml.contains('Facility Text'), 'Hospital fallback facility should be included.');
        System.assert(xml.contains('Clinic'), 'MSP location type should be trimmed and included.');
        System.assert(xml.contains('Drug &amp; A'), 'PharmaCare drug should be XML escaped and included.');
        System.assert(xml.contains('Home support'), 'Continuing Care row should be included.');
        System.assert(xml.contains('Future rehab'), 'Future Care row should be included.');
        
        System.assert(fullDocx.size() > 0, 'Full DOCX should be generated with healthcare rows.');
        System.assert(detailsDocx.size() > 0, 'Details-only DOCX should be generated with healthcare rows.');
    }
    
    @IsTest
    static void individualSectionBuildersReturnOnlyWhenRowsExist() {
        // First verifies that empty section inputs do not create blank headings/tables,
        // then verifies each section renders once matching rows are supplied.
        Case c = DocxTestDataFactory.createCaseRecord();
        
        System.assertEquals('', baseBuilder(c).buildAmbulanceSectionXml(), 'Empty ambulance records should not render a section.');
        System.assertEquals('', baseBuilder(c).buildHospitalSectionXml(), 'Empty hospital records should not render a section.');
        System.assertEquals('', baseBuilder(c).buildMedicalSectionXml(), 'Empty MSP records should not render a section.');
        System.assertEquals('', baseBuilder(c).buildPharmacareSectionXml(), 'Empty PharmaCare records should not render a section.');
        System.assertEquals('', baseBuilder(c).buildContinuingCareSectionXml(), 'Empty Continuing Care records should not render a section.');
        System.assertEquals('', baseBuilder(c).buildFutureCareSectionXml(), 'Empty Future Care records should not render a section.');
        
        System.assertNotEquals('', baseBuilder(c).setAmbulanceRecords(ambulanceRows()).buildAmbulanceSectionXml(), 'Ambulance records should render.');
        System.assertNotEquals('', baseBuilder(c).setHospitalRecords(hospitalRows()).buildHospitalSectionXml(), 'Hospital records should render.');
        System.assertNotEquals('', baseBuilder(c).setMSPRecords(mspRows()).buildMedicalSectionXml(), 'MSP records should render.');
        System.assertNotEquals('', baseBuilder(c).setPharmaRecords(pharmaRows()).buildPharmacareSectionXml(), 'PharmaCare records should render.');
        System.assertNotEquals('', baseBuilder(c).setContinuingCareRecords(continuingCareRows()).buildContinuingCareSectionXml(), 'Continuing Care records should render.');
        System.assertNotEquals('', baseBuilder(c).setFutureCareRecords(futureCareRows()).buildFutureCareSectionXml(), 'Future Care records should render.');
    }
    
    @IsTest
    static void templateTypeAndWatermarkScenariosBuildSuccessfully() {
        // Exercises the template-selection paths that change document wording/structure,
        // while also confirming watermark flags do not break generation.
        Case c = DocxTestDataFactory.createCaseRecord();
        
        DocxBuilder defaultTemplate = baseBuilder(c).setDocumentType(null).setUseWatermark(true);
        DocxBuilder ministryTemplate = baseBuilder(c).setDocumentType(System.Label.TPL_DocGen_Template_Ministers_Cert).setUseWatermark(false);
        DocxBuilder caseHistoryTemplate = baseBuilder(c)
            .setDocumentType(System.Label.TPL_DocGen_Template_Case_History)
            .setUseWatermark(true)
            .setAmbulanceRecords(ambulanceRows());
        
        Test.startTest();
        String defaultOpeningXml = defaultTemplate.buildOpeningXml();
        Blob ministryDocx = ministryTemplate.build();
        Blob caseHistoryDocx = caseHistoryTemplate.build();
        String caseHistoryDetails = caseHistoryTemplate.buildAllDetailSectionsXml();
        Test.stopTest();
        
        System.assert(defaultOpeningXml.contains(System.Label.TPL_DocGen_Doc_Title_Appendix_A), 'Opening XML should include Appendix A.');
        System.assert(ministryDocx.size() > 0, 'Ministry certificate template should build.');
        System.assert(caseHistoryDocx.size() > 0, 'Case history template should build.');
        System.assert(caseHistoryDetails.contains(System.Label.TPL_DocGen_Doc_CH_Section_16_1), 'Case history detail notes should render.');
        System.assert(caseHistoryDetails.contains(System.Label.TPL_DocGen_Doc_CH_Section_16_2), 'Case history detail notes should render.');
    }
    
    @IsTest
    static void nullAndFallbackSetterScenariosBuildSuccessfully() {
        // Simulates defensive-input cases that can happen from UI/controller flows:
        // null flags, blank logo resource names, and records missing preferred display fields.
        Case c = DocxTestDataFactory.createCaseRecord();
        
        List<Healthcare_Cost__c> fallbackRows = new List<Healthcare_Cost__c>{
            new Healthcare_Cost__c(
                Date_of_Service__c = Date.today(),
                Location_Responded__c = null,
                //  FacilityName__c = null,
                Facility_Name__c = 'Fallback Destination',
                Total_Cost_Override__c = null
            )
                };
                    
                    List<Healthcare_Cost__c> hospitalFallbackRows = new List<Healthcare_Cost__c>{
                        new Healthcare_Cost__c(
                            Date_of_Admission__c = Date.today(),
                            Date_of_Discharge__c = Date.today().addDays(1),
                            // FacilityName__c = null,
                            Facility_Name__c = 'Fallback Hospital',
                            Service_Type2__c = null,
                            //  Number_of_Days__c = null,
                            Total_Cost_Override__c = null
                            //  Total_Costs_Standard__c = 321
                        )
                            };
                                
                                DocxBuilder builder = new DocxBuilder()
                                .setCaseData(c)
                                .setSigningAuthority(null, null)
                                .setDocumentType('')
                                .setUseWatermark(null)
                                .setIncludeDetailSectionHeader(null)
                                .setIncludeDetailSectionTotal(null)
                                .setIncludeDetailSectionLabel(null)
                                .setIncludeDetailColumnHeader(null)
                                .setLogoStaticResourceName('   ')
                                .setAmbulanceRecords(fallbackRows)
                                .setHospitalRecords(hospitalFallbackRows)
                                .setMSPRecords(new List<Healthcare_Cost__c>{ new Healthcare_Cost__c(Location_Type_Description2__c = null) })
                                .setPharmaRecords(new List<Healthcare_Cost__c>{ new Healthcare_Cost__c() })
                                .setContinuingCareRecords(new List<Healthcare_Cost__c>{ new Healthcare_Cost__c() })
                                .setFutureCareRecords(new List<Healthcare_Cost__c>{ new Healthcare_Cost__c() });
        
        Test.startTest();
        String xml = builder.buildAllDetailSectionsXml();
        Blob docx = builder.build();
        Test.stopTest();
        
        System.assert(xml.contains('Fallback Destination'), 'Ambulance Facility_Name__c fallback should be used.');
        System.assert(xml.contains('Fallback Hospital'), 'Hospital Facility_Name__c fallback should be used.');
        System.assert(xml.contains('Fallback Hospital'), 'Hospital standard-cost fallback scenario should build successfully.');
        System.assert(docx.size() > 0, 'Builder should handle null setter inputs and blank logo resource.');
    }
    
    @IsTest
    static void detailHeaderCanBeSuppressedForContinuationChunks() {
        // When a large details document is split into chunks, only the first chunk
        // should show the overall healthcare-costs heading.
        Case c = DocxTestDataFactory.createCaseRecord();
        
        String firstChunkXml = baseBuilder(c)
            .setHospitalRecords(hospitalRows())
            .setIncludeDetailSectionHeader(true)
            .buildAllDetailSectionsXml();
        
        String continuationChunkXml = baseBuilder(c)
            .setHospitalRecords(hospitalRows())
            .setIncludeDetailSectionHeader(false)
            .buildAllDetailSectionsXml();
        
        System.assert(firstChunkXml.contains(System.Label.TPL_DocGen_Doc_Title_Healthcare_Services_Costs_Record), 'First chunk should include the detail section header.');
        System.assert(!continuationChunkXml.contains(System.Label.TPL_DocGen_Doc_Title_Healthcare_Services_Costs_Record), 'Continuation chunks should suppress the repeated detail section header.');
        System.assert(continuationChunkXml.contains(System.Label.TPL_DocGen_Doc_Section_Hospital), 'Continuation chunks should still include section details.');
    }
    
    @IsTest
    static void detailTotalCanBeSuppressedUntilFinalChunk() {
        // Section totals should wait until the final chunk so users do not see
        // repeated or misleading totals in the middle of a split details document.
        Case c = DocxTestDataFactory.createCaseRecord();
        
        String nonFinalChunkXml = baseBuilder(c)
            .setHospitalRecords(hospitalRows())
            .setIncludeDetailSectionTotal(false)
            .buildAllDetailSectionsXml();
        
        String finalChunkXml = baseBuilder(c)
            .setHospitalRecords(hospitalRows())
            .setIncludeDetailSectionTotal(true)
            .buildAllDetailSectionsXml();
        
        System.assert(!nonFinalChunkXml.contains(System.Label.TPL_DocGen_Doc_Total_Prefix + ' ' + System.Label.TPL_DocGen_Doc_Section_Hospital), 'Non-final chunks should suppress the repeated section total.');
        System.assert(finalChunkXml.contains(System.Label.TPL_DocGen_Doc_Total_Prefix + ' ' + System.Label.TPL_DocGen_Doc_Section_Hospital), 'Final chunk should include the section total.');
        System.assert(nonFinalChunkXml.contains(System.Label.TPL_DocGen_Doc_Section_Hospital), 'Non-final chunks should still include section details.');
    }
    
    @IsTest
    static void detailSectionLabelCanBeSuppressedForContinuationChunks() {
        // In continuation chunks, the section table should continue without repeating
        // the section label above every split piece.
        Case c = DocxTestDataFactory.createCaseRecord();
        
        String firstChunkXml = baseBuilder(c)
            .setHospitalRecords(hospitalRows())
            .setIncludeDetailSectionLabel(true)
            .buildAllDetailSectionsXml();
        
        String continuationChunkXml = baseBuilder(c)
            .setHospitalRecords(hospitalRows())
            .setIncludeDetailSectionLabel(false)
            .buildAllDetailSectionsXml();
        
        System.assert(firstChunkXml.contains(System.Label.TPL_DocGen_Doc_Section_Hospital), 'First chunk should include the section label.');
        System.assert(!continuationChunkXml.contains('<w:t xml:space="preserve">' + System.Label.TPL_DocGen_Doc_Section_Hospital + '</w:t>'), 'Continuation chunks should suppress the repeated section label.');
        System.assert(continuationChunkXml.contains(System.Label.TPL_DocGen_Doc_Col_Admit), 'Continuation chunks should still include the detail table.');
    }
    
    @IsTest
    static void detailColumnHeaderCanBeSuppressedForContinuationChunks() {
        // Continuation chunks should not repeat column headers, but the actual
        // healthcare data rows must still be present.
        Case c = DocxTestDataFactory.createCaseRecord();
        
        String firstChunkXml = baseBuilder(c)
            .setHospitalRecords(hospitalRows())
            .setIncludeDetailColumnHeader(true)
            .buildAllDetailSectionsXml();
        
        String continuationChunkXml = baseBuilder(c)
            .setHospitalRecords(hospitalRows())
            .setIncludeDetailColumnHeader(false)
            .buildAllDetailSectionsXml();
        
        System.assert(firstChunkXml.contains(System.Label.TPL_DocGen_Doc_Col_Admit), 'First chunk should include the detail column headers.');
        System.assert(!continuationChunkXml.contains(System.Label.TPL_DocGen_Doc_Col_Admit), 'Continuation chunks should suppress repeated detail column headers.');
        System.assert(continuationChunkXml.contains('Inpatient'), 'Continuation chunks should still include detail records.');
    }
    
    @IsTest
    static void detailDataRowsUseCantSplitWithoutLengthHeuristic() {
        // Protects the Word XML behavior for detail rows: rows should stay together
        // using cantSplit, without adding keepNext chaining based on text length.
        Case c = DocxTestDataFactory.createCaseRecord();
        
        String xml = baseBuilder(c)
            .setHospitalRecords(hospitalRows())
            .buildAllDetailSectionsXml();
        
        System.assert(xml.contains('<w:cantSplit/>'), 'Detail data rows should use row no-split XML without checking text length.');
        System.assert(!xml.contains('<w:keepNext/>'), 'Detail row no-split should not add keepNext chaining XML.');
    }
    
    @IsTest
    static void sharedConstantsRemainAlignedForDocx() {
        // Simple guardrail test for shared labels/constants used across the DOCX builder
        // and async document generation flow.
        System.assert(String.isNotBlank(System.Label.TPL_DocGen_Doc_Label_Case_Number), 'Shared case-number label should be available.');
        System.assert(String.isNotBlank(System.Label.TPL_DocGen_Doc_Section_Ambulance), 'Shared ambulance section label should be available.');
        System.assert(String.isNotBlank(System.Label.TPL_DocGen_Doc_Col_Service_Date), 'Shared service-date column header should be available.');
        System.assertEquals('ASYNC:', DocgenConstants.ASYNC_RESPONSE_PREFIX, 'Async response prefix must remain unchanged.');
    }
    
    private static DocxBuilder baseBuilder(Case c) {
        // Shared builder setup used by most tests so each scenario starts with
        // clean empty healthcare lists and predictable signer/logo values.
        return new DocxBuilder()
            .setCaseData(c)
            .setAmbulanceRecords(new List<Healthcare_Cost__c>())
            .setHospitalRecords(new List<Healthcare_Cost__c>())
            .setMSPRecords(new List<Healthcare_Cost__c>())
            .setPharmaRecords(new List<Healthcare_Cost__c>())
            .setContinuingCareRecords(new List<Healthcare_Cost__c>())
            .setFutureCareRecords(new List<Healthcare_Cost__c>())
            .setSigningAuthority('Test Signer', 'Test Title')
            .setLogoStaticResourceName('Missing_Test_Logo_Resource');
    }
    
    private static List<Healthcare_Cost__c> ambulanceRows() {
        // Ambulance row includes an ampersand so tests can confirm XML escaping,
        // and a fallback destination value for rendering.
        return new List<Healthcare_Cost__c>{
            new Healthcare_Cost__c(
                Date_of_Service__c = Date.today(),
                Location_Responded__c = 'Scene & Road',
                //  FacilityName__c = 'Display Destination',
                Facility_Name__c = 'Fallback Destination',
                Total_Cost_Override__c = 125.50
            )
                };
                    }
    
    private static List<Healthcare_Cost__c> hospitalRows() {
        // Hospital rows cover both a populated override-cost row and a second row
        // with null override cost to keep fallback/blank-value rendering covered.
        return new List<Healthcare_Cost__c>{
            new Healthcare_Cost__c(
                Date_of_Admission__c = Date.today().addDays(-2),
                Date_of_Discharge__c = Date.today(),
                //   FacilityName__c = 'Facility Display',
                Facility_Name__c = 'Facility Text',
                Service_Type2__c = 'Inpatient',
                //  Number_of_Days__c = 2,
                Total_Cost_Override__c = 2500
                // Total_Costs_Standard__c = 3000
            ),
                new Healthcare_Cost__c(
                    Date_of_Admission__c = Date.today().addDays(-4),
                    Date_of_Discharge__c = Date.today().addDays(-3),
                    //  FacilityName__c = null,
                    Facility_Name__c = 'Facility Text',
                    Service_Type2__c = 'Acute',
                    //  Number_of_Days__c = null,
                    Total_Cost_Override__c = null
                    //  Total_Costs_Standard__c = 111
                )
                };
                    }
    
    private static List<Healthcare_Cost__c> mspRows() {
        // MSP row includes extra spaces around the location type so the test can
        // verify trimming before the value is written into the document XML.
        return new List<Healthcare_Cost__c>{
            new Healthcare_Cost__c(
                Date_of_Service__c = Date.today(),
                Location_Type_Description2__c = ' Clinic ',
                Description_of_Service2__c = 'Consultation',
                Fee_Item_Title__c = 'Fee Item',
                Diagnostic_Description__c = 'Diagnosis',
                Total_Cost_Override__c = 44.25,
                Practitioner_Name__c = 'Dr. Test'
            )
                };
                    }
    
    private static List<Healthcare_Cost__c> pharmaRows() {
        // PharmaCare row includes an ampersand in the drug name so XML escaping
        // is covered for prescription detail values.
        return new List<Healthcare_Cost__c>{
            new Healthcare_Cost__c(
                Date_of_Service__c = Date.today(),
                Name_of_Drug__c = 'Drug & A',
                Total_Cost_Override__c = 55.75,
                Practitioner_Name__c = 'Dr. Pharma'
            )
                };
                    }
    
    private static List<Healthcare_Cost__c> continuingCareRows() {
        // Minimal Continuing Care row used to prove that this section renders
        // when only description and cost are provided.
        return new List<Healthcare_Cost__c>{
            new Healthcare_Cost__c(
                Description__c = 'Home support',
                Cost__c = 600
            )
                };
                    }
    
    private static List<Healthcare_Cost__c> futureCareRows() {
        // Minimal Future Care row used to prove future-cost details are included
        // in the combined healthcare details XML.
        return new List<Healthcare_Cost__c>{
            new Healthcare_Cost__c(
                Description__c = 'Future rehab',
                Cost__c = 700
            )
                };
                    }
}