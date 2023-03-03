/**
  Custom Auth Provider for AIMS API Gateway

  Implements the Client Credentials flow which is intended for server-to-server integrations.

**/
public class JWTGenerateAuth extends Auth.AuthProviderPluginClass{

    public static final String RESOURCE_CALLBACK = '/services/authcallback/';
    public static final String DEFAULT_TOKEN_TYPE = 'Bearer';
    public static final String ENCODING_XML = 'application/x-www-form-urlencoded;charset=UTF-8';
    public static final String ENCODING_JSON = 'application/json';
    public static final String DUMMY_CODE = '999';
    public static final String DOUBLEQUOTE = '"';

    // This class is dependant on this Custom Metadata Type created to hold custom parameters
    public static final String CUSTOM_MDT_NAME = 'IDP_Jwt_Configuration__mdt'; 
    public static final String CMT_FIELD_CALLBACK_URL = 'Callback_URL__c';
    public static final String CMT_FIELD_PROVIDER_NAME = 'Auth_Provider_Name__c';
    public static final String CMT_FIELD_AUTHTOKEN_URL = 'Token_End_Point__c';
    public static final String CMT_FIELD_CLIENT_ID = 'Iss__c';
    public static final String CMT_FIELD_REFRESH_TOKEN= 'X5t__c';
    public static final String CMT_FIELD_USE_JSON = 'Use_JSON_Encoding__c';
    public static final String CMT_FIELD_SCOPE = 'Scope__c';

    public static final String GRANT_TYPE_PARAM = 'grant_type';
    public static final String CLIENT_ID_PARAM = 'client_id';
    public static final String CLIENT_ASSERTION_TYPE= 'client_assertion_type';
    public static final String SCOPE_PARAM = 'scope';
    public static final String GRANT_TYPE_CLIENT_CREDS = 'client_credentials';

    /**
     Added Constructor purely for debugging purposes to have visibility as to when the class
     is being instantiated.
    **/
    public JWTGenerateAuth() {
        super();
        System.debug('Constructor called');
    }
    
    
    /**
        Name of custom metadata type to store this auth provider configuration fields
        This method is required by its abstract parent class.

    **/
    public String getCustomMetadataType() {
        return CUSTOM_MDT_NAME;
    } 
    
    /**
    Initiate callback. No End User authorization required in this flow so skip straight to the Token request.
    The interface requires the callback url to be defined. 
    Eg: https://test.salesforce.com/services/authcallback/<authprovidername>
    **/
    public PageReference initiate(Map<string,string> config, String stateToPropagate) {
        System.debug('initiate');

        final PageReference pageRef = new PageReference(getCallbackUrl(config)); //NOSONAR
        pageRef.getParameters().put('state',stateToPropagate);
        pageRef.getParameters().put('code',DUMMY_CODE); // Empirically found this is required, but unused
        System.debug(pageRef.getUrl());
        return pageRef;
    } 
    
        /**
      This method composes the callback URL automatically UNLESS it has been overridden through Configuration.
      Normally one should not override the callback URL, but it's there in case the generated URL doesn't work.
    **/
    private String getCallbackUrl(Map<string,string> config) {
        // https://{salesforce-hostname}/services/authcallback/{urlsuffix}
        final String overrideUrl = config.get(CMT_FIELD_CALLBACK_URL);
        final String generatedUrl = URL.getSalesforceBaseUrl().toExternalForm() + RESOURCE_CALLBACK + config.get('Auth_Provider_Name__c');

        return String.isEmpty(overrideUrl) ? generatedUrl : overrideUrl;
    }

    
    /**
    Handle callback (from initial loop back "code" step in the flow).
    In the Client Credentials flow, this method retrieves the access token directly.

    Required by parent class.

    Error handling here is a bit painful as the UI never displays the exception or error message 
    supplied here.  The exception is thrown for Logging/Debugging purposes only. 
    **/
    public Auth.AuthProviderTokenResponse handleCallback(Map<string,string> config, Auth.AuthProviderCallbackState state ) {
        System.debug('handleCallback');
        //
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String guid = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);
        
        List<IDP_Jwt_Configuration__mdt> pemval = [
        SELECT PEM__c, Token_End_Point__c,Iss__c,Sub__c,X5t__c,Typ__c,Aud__c, Algorithm__c, Auth_Provider_Name__c, Callback_URL__c, Scope__c,
            thumbprint__c, DeveloperName, Authority__c
        FROM IDP_Jwt_Configuration__mdt 
        WHERE DeveloperName = 'HealthIdeas' Limit 1];
        JWT jwt = new JWT(pemval[0].Algorithm__c);
        jwt.pkcs8 = pemval[0].PEM__c;
        
        String tokenEndpoint = pemval[0].Token_End_Point__c;
        jwt.iss = pemval[0].Iss__c;
        jwt.sub = pemval[0].Sub__c;
        jwt.x5t = pemval[0].X5t__c;
        jwt.typ = pemval[0].Typ__c;
        jwt.jti = guid.Replace('-', '');
        jwt.aud = pemval[0].Aud__c;        
        String token = jwt.issue();    
        System.debug(token);
        System.debug(JWTBearerFlow.getAccessToken(tokenEndPoint, jwt, pemval));

        return new Auth.AuthProviderTokenResponse(config.get(CMT_FIELD_PROVIDER_NAME)
                                                  , JWTBearerFlow.getAccessToken(tokenEndPoint, jwt, pemval)
                                                  , config.get(CMT_FIELD_REFRESH_TOKEN) // No Refresh Token
                                                  , state.queryParameters.get('state'));
    } 
    
    /**
        Refresh is required by the parent class and it's used if the original Access Token has expired.
        In the Client Credentials flow, there is no Refresh token, so its implementation is exactly the
        same as the Initiate() step.
    **/
    public override Auth.OAuthRefreshResult refresh(Map<String,String> config, String refreshToken) {
        System.debug('refresh');
        final TokenResponse response = retrieveAuthToken(config);
        return new Auth.OAuthRefreshResult(response.access_token, response.token_type);
    }

       
    /**
        getUserInfo is required by the Parent class, but not fully supported by this provider.
        Effectively the Client Credentials flow is only useful for Server-to-Server API integrations
        and cannot be used for other contexts such as a Registration Handler for Communities.
     **/
    public Auth.UserData getUserInfo(Map<string,string> config, Auth.AuthProviderTokenResponse response) {
        System.debug('getUserInfo-was-called');
        final TokenResponse token = retrieveAuthToken(config);

        final Auth.UserData userData = new Auth.UserData(
              token.application_name // identifier
            , null // firstName
            , null // lastName
            , null // fullName
            , token.developer_email // email
            , null // link
            , token.developer_email // userName
            , null  //locale
            , config.get(CMT_FIELD_PROVIDER_NAME) //provider
            , null // siteLoginUrl
            , new Map<String,String>());


        return userData;
    }
    
    
    /**
       Private method that gets the Auth Token using the Client Credentials Flow.
    **/
     private TokenResponse retrieveAuthToken(Map<String,String> config) {
         
        System.debug('retrieveAuthToken');
        
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String guid = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);
        
        List<IDP_Jwt_Configuration__mdt> pemval = [
            SELECT PEM__c, Token_End_Point__c,Iss__c,Sub__c,X5t__c,Typ__c,Aud__c, Algorithm__c, Auth_Provider_Name__c, Callback_URL__c, Scope__c,
                thumbprint__c, DeveloperName, Authority__c 
            FROM IDP_Jwt_Configuration__mdt 
            WHERE DeveloperName = 'HealthIdeas' Limit 1];
        JWT jwt = new JWT(pemval[0].Algorithm__c);
        jwt.pkcs8 = pemval[0].PEM__c;
        
        String tokenEndpoint = pemval[0].Token_End_Point__c;
        jwt.iss = pemval[0].Iss__c;
        jwt.sub = pemval[0].Sub__c;
        jwt.x5t = pemval[0].X5t__c;
        jwt.typ = pemval[0].Typ__c;
        jwt.jti = guid.Replace('-', '');
        jwt.aud = pemval[0].Aud__c;        
        String jwtToken = jwt.issue();    
        System.debug(jwtToken );
        
        HttpRequest req = new HttpRequest();
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8');
        req.setHeader('Content-Length', '0');
        req.setMethod('POST');
        req.setEndpoint(pemval[0].Token_End_Point__c);
        String body = 'grant_type=client_credentials&client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer&client_assertion=' + jwtToken +'';
        body += '&client_id=' + pemval[0].Iss__c + '&authority=' + pemval[0].Authority__c +'&scope=' + pemval[0].Scope__c + '&thumbprint=' + + pemval[0].thumbprint__c;
        
        req.setBody(body);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug('Token Response Status: ' + res.getStatus() + ' ' + res.getStatusCode());
        final Integer statusCode = res.getStatusCode();

        if ( statusCode == 200) {
            TokenResponse token =  getAccessToken(tokenEndpoint, jwt, pemval);
            // Ensure values for key fields
            token.token_type = (token.token_type == null) ? DEFAULT_TOKEN_TYPE : token.token_type;
            
            System.debug(token);
            return token;

        } else  {
            return deserializeToken(res.getBody());
        }

    }
    
    //deserialise response and return token
    @testVisible
    private TokenResponse deserializeToken(String responseBody) {
        
        System.debug('token response:' +responseBody);
        
        // use default parsing for everything we can.
        TokenResponse parsedResponse = (TokenResponse) System.JSON.deserialize(responseBody, TokenResponse.class);
        // explicitly parse out the developer.email property because it's an illegal identifier
        Map<String,Object> props = (Map<String,Object>) System.JSON.deserializeUntyped(responseBody);
        parsedResponse.developer_email = (String) props.get('developer.email');
       
        return parsedResponse;
    }

    /**
        Conditionally encode parameters as URL-style or JSON
    **/
    @testVisible
    private String encodeParameters(Map<String,String> config,String encoding) {

        // Pull out the subset of configured parameters that will be sent
        Map<String,String> params = new Map<String,String>();
        params.put(GRANT_TYPE_PARAM,GRANT_TYPE_CLIENT_CREDS);
        params.put(CLIENT_ID_PARAM, config.get(CMT_FIELD_CLIENT_ID));
        final String scope = config.get(CMT_FIELD_SCOPE);
        if (!String.isEmpty(scope)) {
            params.put(SCOPE_PARAM,scope);
        }

        return encoding == ENCODING_JSON ? encodeAsJSON(params) : encodeAsURL(params);
    }

    private String encodeAsJSON(Map<String,String> params) {
        String output = '{';
        for (String key : params.keySet()) {
            output += (output == '{' ? '' : ', ');
            output += DOUBLEQUOTE + key + DOUBLEQUOTE + ':';
            output += DOUBLEQUOTE + params.get(key) + DOUBLEQUOTE;
        }
        output += '}';
        return output;
    }

    private String encodeAsURL(Map<String,String> params) {
        String output = '';
        for (String key : params.keySet()) {
            output += (String.isEmpty(output) ? '' : '&');
            output += key + '=' + params.get(key);
        }
        return output;
    }

    public class TokenResponse {
        public String refresh_token_expires_in {get;set;}
        public String api_product_list {get;set;}
        public List<String> api_product_list_json {get;set;}
        public String organization_name {get;set;}
        public String developer_email {get;set;}
        public String token_type {get;set;}
        public String issued_at {get;set;}
        public String client_id {get;set;}
        public String access_token {get;set;}
        public String application_name {get;set;}
        public String scope {get;set;}
        public String expires_in {get;set;}
        public String refresh_count {get;set;}
        public String status {get;set;}

        // Apigee Edge -- hosted version uses these fields for error handling
        public String ErrorCode {get; set;}
        public String Error {get; set;}

        // Apigee on premise version uses this Field for error handling
        public Fault fault {get; set;}

        public Boolean isError() {
            return Error != null || fault != null;
        }

        public String getErrorMessage() {
            if (Error != null) {
                return ErrorCode;
            }

            if (fault != null) {
                // Substitute the error code to compose
                return fault.faultString.replace('{0}',fault.detail.errorcode);
            }
            return null;
        }
    }

    public class Fault {
        public String faultstring {get;set;}
        public Detail detail {get;set;}
    }

    public class Detail {
        public String errorcode {get;set;}
    }

    /**
        Custom exception type so we can wrap and rethrow
    **/
    public class TokenException extends Exception {

    }
    
    public TokenResponse getAccessToken(String tokenEndpoint, JWT jwt, List<IDP_Jwt_Configuration__mdt> pemval) {
    
        String access_token = null;
        String token_type = null;
        String expires_in = null;
        String ext_expires_in = null;
        
        system.debug('jwt:' + jwt.issue());
        String body = 'grant_type=client_credentials&client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer&client_assertion=' + jwt.issue() +'';
        body += '&client_id=' + pemval[0].Iss__c + '&authority=' + pemval[0].Authority__c +'&scope=' + pemval[0].Scope__c + '&thumbprint=' + + pemval[0].thumbprint__c;

        HttpRequest req = new HttpRequest();                            
        req.setMethod('POST');
        req.setEndpoint(tokenEndpoint);
        req.setHeader('Content-type', 'application/x-www-form-urlencoded');
        TokenResponse token = new TokenResponse();
        
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
                    token.access_token = access_token;
                }
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'token_type')) {
                    parser.nextToken();
                    access_token = parser.getText();
                    token.token_type = token_type;
                }
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'expires_in')) {
                    parser.nextToken();
                    expires_in = parser.getText();
                    token.expires_in = expires_in;
                }
                token.status = res.getStatus();
            }                         
        } else {
            token.ErrorCode = String.valueOf(res.getStatusCode());
            token.Error = res.getStatus();
        }
        System.debug(res.getBody());
        return token;
    }
}