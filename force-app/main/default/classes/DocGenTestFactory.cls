/**
 * DocGenTestFactory
 * Test data factory — aligned to moh-tpl-main data model.
 *
 * Key data model facts (confirmed from field metadata):
 *
 * CASE formula fields — READ-ONLY, never set in DML:
 *   PHN__c           formula: IF(Account.IsPersonAccount, Account.PersonContact.PHN__c, NULL)
 *   Date_of_Birth__c formula: Account.PersonContact.Date_of_Birth__c
 *   ContactName__c   formula: Account.PersonContact.FirstName & ' ' & LastName
 *   Total_Case_Value__c formula: sum of cost rollups
 *
 *   These resolve automatically once a PersonAccount with a contact is linked.
 *   Tests that need them populated must create a PersonAccount with Contact fields set.
 *
 * HEALTHCARE_COST__c formula fields — READ-ONLY, never set in DML:
 *   RecordTypeName__c   formula: RecordType.DeveloperName → set RecordTypeId instead
 *   FacilityName__c     formula: Facility__r.Facility_Name__c → set Facility_Name__c instead
 *   Number_of_Days__c   formula: date diff of Admission/Discharge → set dates, reads automatically
 *   Total_Costs_Standard__c formula: Number_of_Days__c * Standard_Daily_Rate__c → auto-computed
 */
@IsTest
public class DocGenTestFactory {

    // ── RecordType helper ──────────────────────────────────────────────────────
    /**
     * Returns the RecordTypeId for Healthcare_Cost__c by DeveloperName.
     * RecordTypeName__c is a formula field — never write it directly.
     * Available DeveloperNames: Ambulance, Hospitalization, MSP, Pharmacare,
     *                           Continuing_Care, Future_Care
     */
    @TestVisible
    private static Id hcRecordTypeId(String developerName) {
        List<RecordType> rts = [
            SELECT Id FROM RecordType
            WHERE SObjectType = 'Healthcare_Cost__c'
              AND DeveloperName = :developerName
            LIMIT 1
        ];
        return rts.isEmpty() ? null : rts[0].Id;
    }

    // ── Account / PersonAccount ────────────────────────────────────────────────
    /**
     * Creates a PersonAccount. In this org Case.PHN__c, Date_of_Birth__c and
     * ContactName__c are formulas that resolve from Account.PersonContact.
     * For tests only asserting document structure (not token values), a plain
     * Account is sufficient. For tests asserting specific formula field values,
     * use createPersonAccount() instead.
     */
    public static Account createAccount() {
        return new Account(
            LastName = 'Test Claimant',    // required for PersonAccount
            RecordTypeId = personAccountRecordTypeId()
        );
    }

    private static Id personAccountRecordTypeId() {
        List<RecordType> rts = [
            SELECT Id FROM RecordType
            WHERE SObjectType = 'Account' AND IsPersonType = true
            LIMIT 1
        ];
        // Fall back to a standard account if PersonAccount not enabled in test org
        return rts.isEmpty() ? null : rts[0].Id;
    }

    // ── Case ──────────────────────────────────────────────────────────────────
    /**
     * Creates a Case with all writable custom fields set.
     * Formula fields (PHN__c, Date_of_Birth__c, ContactName__c, Total_Case_Value__c)
     * are NOT set here — they are computed automatically from related records.
     * Total_Case_Value__c will compute once the cost rollup fields are populated.
     */
    public static Case createCase(Id accountId) {
        Case c = new Case();
        c.AccountId                 = accountId;
        c.Status                    = 'New';
        c.Origin                    = 'Web';
        // Writable fields
        c.Claim_Number__c           = 'MV-2024-00001';
        c.Incident_Date__c          = Date.newInstance(2024, 3, 10);
        c.Ambulance_Total2__c       = 3000.00;
        c.Hospitalization_Total2__c = 16000.00;
        c.MSP_Total2__c             = 1800.00;
        c.Pharmacare_Total2__c      = 200.00;
        c.Continuing_Care_Total2__c = 6000.00;
        c.Future_Care_Total2__c     = 8000.00;
        // Note: Total_Case_Value__c is a formula = sum of above — do not set directly
        // Note: PHN__c, Date_of_Birth__c, ContactName__c are formulas from PersonContact
        return c;
    }

    // ── Healthcare_Cost__c ────────────────────────────────────────────────────

    /**
     * Ambulance records.
     * RecordTypeName__c is a formula — set RecordTypeId instead.
     * FacilityName__c is a formula (Facility__r.Facility_Name__c) — set Facility_Name__c instead.
     * Cost_Include__c and Cost_Review__c must be true to appear in the certificate.
     */
    public static List<Healthcare_Cost__c> createAmbulanceRecords(Id caseId, Integer count) {
        List<Healthcare_Cost__c> recs = new List<Healthcare_Cost__c>();
        Id rtId = hcRecordTypeId('Ambulance');
        for (Integer i = 0; i < count; i++) {
            recs.add(new Healthcare_Cost__c(
                Case2__c              = caseId,
                RecordTypeId          = rtId,
                Cost_Include__c       = true,
                Cost_Review__c        = true,
                Date_of_Service__c    = Date.newInstance(2024, 3, 10 + i),
                Location_Responded__c = '123 Test Street, Vancouver BC',
                Facility_Name__c      = 'BC Ambulance Destination ' + i,  // writable; FacilityName__c resolves from this if Facility lookup set
                Total_Cost_Override__c = 1000.00 + (i * 100)
            ));
        }
        return recs;
    }

    /** Ambulance record with Cost_Include = false — excluded by controller query */
    public static Healthcare_Cost__c createExcludedAmbulanceRecord(Id caseId) {
        return new Healthcare_Cost__c(
            Case2__c              = caseId,
            RecordTypeId          = hcRecordTypeId('Ambulance'),
            Cost_Include__c       = false,
            Cost_Review__c        = true,
            Date_of_Service__c    = Date.newInstance(2024, 3, 10),
            Total_Cost_Override__c = 500.00
        );
    }

    /**
     * Hospitalization records.
     * FacilityName__c is a formula — set Facility_Name__c instead.
     * Number_of_Days__c is a formula (Discharge - Admission) — set the dates, it auto-computes.
     * Total_Costs_Standard__c is a formula (Number_of_Days__c * Standard_Daily_Rate__c) — auto-computes.
     */
    public static List<Healthcare_Cost__c> createHospitalRecords(Id caseId, Integer count) {
        List<Healthcare_Cost__c> recs = new List<Healthcare_Cost__c>();
        Id rtId = hcRecordTypeId('Hospitalization');
        for (Integer i = 0; i < count; i++) {
            recs.add(new Healthcare_Cost__c(
                Case2__c              = caseId,
                RecordTypeId          = rtId,
                Cost_Include__c       = true,
                Cost_Review__c        = true,
                Date_of_Admission__c  = Date.newInstance(2024, 3, 11 + i),
                Date_of_Discharge__c  = Date.newInstance(2024, 3, 15 + i), // Number_of_Days__c = 4 (formula)
                Facility_Name__c      = 'Vancouver General Hospital',
                Service_Type2__c      = 'Acute',
                Total_Cost_Override__c = 8000.00 + (i * 500)
                // Number_of_Days__c auto-computed from dates
                // Total_Costs_Standard__c auto-computed from days * daily rate
            ));
        }
        return recs;
    }

    /** Hospital record where Total_Cost_Override__c is null — falls back to Total_Costs_Standard__c */
    public static Healthcare_Cost__c createHospitalRecordNullOverride(Id caseId) {
        return new Healthcare_Cost__c(
            Case2__c              = caseId,
            RecordTypeId          = hcRecordTypeId('Hospitalization'),
            Cost_Include__c       = true,
            Cost_Review__c        = true,
            Date_of_Admission__c  = Date.newInstance(2024, 4, 1),
            Date_of_Discharge__c  = Date.newInstance(2024, 4, 5),
            Facility_Name__c      = 'Surrey Memorial Hospital',
            Service_Type2__c      = 'Rehabilitation',
            Total_Cost_Override__c = null  // null → DocxBuilder falls back to Total_Costs_Standard__c
        );
    }

    /** MSP records */
    public static List<Healthcare_Cost__c> createMSPRecords(Id caseId, Integer count) {
        List<Healthcare_Cost__c> recs = new List<Healthcare_Cost__c>();
        Id rtId = hcRecordTypeId('MSP');
        for (Integer i = 0; i < count; i++) {
            recs.add(new Healthcare_Cost__c(
                Case2__c                      = caseId,
                RecordTypeId                  = rtId,
                Cost_Include__c               = true,
                Cost_Review__c                = true,
                Date_of_Service__c            = Date.newInstance(2024, 4, 1 + i),
                Location_Type_Code__c         = '12' + i,
                Location_Type_Description2__c = 'Test Location ' + i,
                Description_of_Service2__c    = 'Service description ' + i,
                Fee_Item_Title__c             = 'Fee ' + i,
                Diagnostic_Description__c     = 'Diag ' + i,
                Total_Cost_Override__c        = 400.00 + (i * 50),
                Practitioner_Name__c          = 'Dr Test ' + i
            ));
        }
        return recs;
    }

    /** Pharmacare records */
    public static List<Healthcare_Cost__c> createPharmaRecords(Id caseId, Integer count) {
        List<Healthcare_Cost__c> recs = new List<Healthcare_Cost__c>();
        Id rtId = hcRecordTypeId('Pharmacare');
        for (Integer i = 0; i < count; i++) {
            recs.add(new Healthcare_Cost__c(
                Case2__c               = caseId,
                RecordTypeId           = rtId,
                Cost_Include__c        = true,
                Cost_Review__c         = true,
                Date_of_Service__c     = Date.newInstance(2024, 5, 1 + i),
                Name_of_Drug__c        = 'Ibuprofen ' + i,
                Total_Cost_Override__c = 50.00 + (i * 10),
                Practitioner_Name__c   = 'Dr Pharma ' + i
            ));
        }
        return recs;
    }

    /**
     * Continuing Care records.
     * No Cost_Include/Cost_Review filter in the DR — all CC records appear.
     */
    public static List<Healthcare_Cost__c> createContinuingCareRecords(Id caseId, Integer count) {
        List<Healthcare_Cost__c> recs = new List<Healthcare_Cost__c>();
        Id rtId = hcRecordTypeId('Continuing_Care');
        for (Integer i = 0; i < count; i++) {
            recs.add(new Healthcare_Cost__c(
                Case2__c          = caseId,
                RecordTypeId      = rtId,
                Description__c    = 'Continuing Care benefit ' + i,
                Cost__c           = 700.00 + (i * 100)
            ));
        }
        return recs;
    }

    /**
     * Future Care records.
     * No Cost_Include/Cost_Review filter in the DR — all FC records appear.
     */
    public static List<Healthcare_Cost__c> createFutureCareRecords(Id caseId, Integer count) {
        List<Healthcare_Cost__c> recs = new List<Healthcare_Cost__c>();
        Id rtId = hcRecordTypeId('Future_Care');
        for (Integer i = 0; i < count; i++) {
            recs.add(new Healthcare_Cost__c(
                Case2__c          = caseId,
                RecordTypeId      = rtId,
                Description__c    = 'Future Care item ' + i,
                Cost__c           = 1000.00 + (i * 200)
            ));
        }
        return recs;
    }

    // ── Signing Authority ──────────────────────────────────────────────────────
    public static TPL_DocGen_Signature__c createSigningAuthority() {
        return new TPL_DocGen_Signature__c(
            Name    = 'TPL DocGen Signature (Profile)',
            Name__c = 'Jane Smith',
            Title__c = 'Deputy Minister'
        );
    }

    // ── Composite setups ───────────────────────────────────────────────────────

    /** Inserts a complete test case with all six HC record types. Returns Case Id. */
    public static Id insertFullTestCase() {
        Account acc = createAccount();
        insert acc;
        Case c = createCase(acc.Id);
        insert c;
        insert createSigningAuthority();

        List<Healthcare_Cost__c> allRecs = new List<Healthcare_Cost__c>();
        allRecs.addAll(createAmbulanceRecords(c.Id, 2));
        allRecs.addAll(createHospitalRecords(c.Id, 2));
        allRecs.addAll(createMSPRecords(c.Id, 3));
        allRecs.addAll(createPharmaRecords(c.Id, 2));
        allRecs.addAll(createContinuingCareRecords(c.Id, 2));
        allRecs.addAll(createFutureCareRecords(c.Id, 2));
        insert allRecs;
        return c.Id;
    }

    /** Inserts a Case with no HC records — tests empty-section behaviour. */
    public static Id insertEmptyCase() {
        Account acc = createAccount();
        insert acc;
        Case c = createCase(acc.Id);
        insert c;
        insert createSigningAuthority();
        return c.Id;
    }
}
