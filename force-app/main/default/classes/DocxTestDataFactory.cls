@IsTest
public class DocxTestDataFactory {
    public static Case createCaseRecord() {
        Case c = new Case(
            Subject = 'Minister Certificate Test Case',
            Status = 'New',
            Origin = 'Phone'
        );
        insert c;

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
            WHERE Id = :c.Id
            LIMIT 1
        ];
    }

    public static Id createLinkedFile(Id parentId, String fileName, String body) {
        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = fileName;
        cv.VersionData = Blob.valueOf(body == null ? 'test body' : body);
        cv.FirstPublishLocationId = parentId;
        cv.SharingPrivacy = 'N';
        cv.IsMajorVersion = false;
        insert cv;

        return [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
            LIMIT 1
        ].ContentDocumentId;
    }
}