public class JWTBearerFlow {

    public static String getAccessToken(String tokenEndpoint, JWT jwt, List<IDP_Jwt_Configuration__mdt> pemval) {
    
        String access_token = null;
        system.debug('jwt:' + jwt.issue());
        String body = 'grant_type=client_credentials&client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer&client_assertion=' + jwt.issue() +'';
        body += '&client_id=' + pemval[0].Iss__c + '&authority=' + pemval[0].Authority__c +'&scope=' + pemval[0].Scope__c + '&thumbprint=' + + pemval[0].thumbprint__c;
        
        HttpRequest req = new HttpRequest();                            
        req.setMethod('POST');
        req.setEndpoint(tokenEndpoint);
        req.setHeader('Content-type', 'application/x-www-form-urlencoded');
        
        req.setBody(body);
        Http http = new Http();
        system.debug('Headerpayload:' + req);
        system.debug('body:' + body);
                       
        HTTPResponse res = http.send(req);
        system.debug('req:' + req);

        system.debug('res:' + res);
        
        if ( res.getStatusCode() == 200 ) {
            System.JSONParser parser = System.JSON.createParser(res.getBody());
            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'access_token')) {
                    parser.nextToken();
                    access_token = parser.getText();
                    break;
                }
            }
        }
        return access_token;
        
    }

}