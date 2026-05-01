/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : HealthIdeasApiIntegrationController
 * Author          : Ranadheer Reddy Gundla
 * Created Date    : Apr 8, 2026
 * Last Modified By: Ranadheer Reddy Gundla
 * Last Modified On: Apr 8, 2026
 * Description     : This class implements for Get Records Action in HealthIdeasApiIntegration Lightning Web Component.
 *                   It calls the method in HealthIdeasApiIntegration class to make the callout to external system and returns the response back to LWC.
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――― ――――――――――― ――――
 *  Apr 8, 2026  │ Ranadheer Reddy Gundla │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――― ――――――――――――――――――――
 */

public with sharing class HealthIdeasApiIntegrationController {
    @AuraEnabled
    public static String runGetCost(Id recordId, Date selectedDate) {
        if (recordId == null) {
            throw new AuraHandledException('Record Id is required.');
        }

        if (selectedDate == null) {
            throw new AuraHandledException('Date is required.');
        }

        try {
            HealthIdeasApiIntegration.IntegrationResult result =
                HealthIdeasApiIntegration.callGetCost(
                    recordId,
                    selectedDate,
                    'crystal.zhu@hi.com'
                );

            return 'Your transfer has been successful';

        } catch (System.CalloutException e) {
            String msg = e.getMessage();

            if (msg != null) {
                String lowerMsg = msg.toLowerCase();

                if (lowerMsg.contains('read timed out') ||
                    lowerMsg.contains('timeout') ||
                    lowerMsg.contains('timed out')) {
                    throw new AuraHandledException(
                        'Request failed because the integration timed out. Details: ' + msg
                    );
                }
            }

            throw new AuraHandledException(
                'Integration callout failed. Details: ' + msg
            );

        } catch (Exception e) {
            throw new AuraHandledException(
                'Get Records failed. Details: ' + e.getMessage()
            );
        }
    }
}
