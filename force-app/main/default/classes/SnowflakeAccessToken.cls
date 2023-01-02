public class SnowflakeAccessToken {
    public PageReference getAuthCode(){
        Snowflake_Creds__mdt cred = [SELECT DeveloperName, MasterLabel, Client_Secret__c, Client_Id__c FROM Snowflake_Creds__mdt];
        //String authUrl = 'https://ww53743.europe-west4.gcp.snowflakecomputing.com/oauth/authorize?redirect_uri=https://katondirecttrial--dev1--c.sandbox.vf.force.com/apex/SnowflakeAccessTokenPage&response_type=code&client_id='+cred.Client_Id__c;
        String authUrl = 'https://kja38390.us-east-1.snowflakecomputing.com/oauth/authorize?redirect_uri=https://katondirecttrial--dev1--c.sandbox.vf.force.com/apex/SnowflakeAccessTokenPage&response_type=code&client_id='+EncodingUtil.urlEncode(cred.Client_Id__c, 'UTF-8');
        return new PageReference( authUrl );
    }
    public void getAccessToken(){
        String authCode =  apexpages.currentpage().getparameters().get('code');
        if( authCode != null && authCode != '' ){
            Snowflake_Creds__mdt cred = [SELECT DeveloperName, MasterLabel, Client_Secret__c, Refresh_Token__c, Client_Id__c, Access_Token__c FROM Snowflake_Creds__mdt];
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            //req.setEndPoint('https://ww53743.europe-west4.gcp.snowflakecomputing.com/oauth/token-request');
            req.setEndPoint('https://kja38390.us-east-1.snowflakecomputing.com/oauth/token-request');
            String payload = 'grant_type=authorization_code&code='+EncodingUtil.urlEncode(authCode, 'UTF-8')+'&client_secret='+EncodingUtil.urlEncode(cred.Client_Secret__c, 'UTF-8')+'&client_id='+EncodingUtil.urlEncode(cred.Client_Id__c, 'UTF-8')+'&redirect_uri=https://katondirecttrial--dev1--c.sandbox.vf.force.com/apex/SnowflakeAccessTokenPage';
            //String body = '{"grant_type" : "authorization_code","code":"'+authCode+'","client_secret":"'+cred.Client_Secret__c+'","client_id":"'+cred.Client_Id__c+'","redirect_uri":"https://katondirecttrial--dev1--c.sandbox.vf.force.com/apex/SnowflakeAccessTokenPage"}';
            req.setBody(payload);
            req.setHeader( 'Content-Type', 'application/x-www-form-urlencoded' );
            req.setMethod('POST');
            HttpResponse res= h.send(req);
            Map<String, Object> resBody = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            System.debug(res.getBody());
            System.debug(payload);
            cred.Access_Token__c = (String)resBody.get('access_token');
            //cred.Refresh_Token__c = (String)resBody.get('refresh_token');
            System.debug( 'AToken:'+resBody.get('access_token')+','+resBody.get('refresh_token') );
            if( !Test.isRunningTest())
              MetaDataUtility.upsertMetadata(cred);
        }
    }
    @AuraEnabled
    public void getAccessTokenUsingRToken(){
        /*Snowflake_Creds__mdt cred = [SELECT DeveloperName, MasterLabel, Client_Secret__c, Refresh_Token__c, Client_Id__c, Access_Token__c FROM Snowflake_Creds__mdt];
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndPoint('https://ww53743.europe-west4.gcp.snowflakecomputing.com/oauth/token-request');
        String payload = 'grant_type=refresh_token&refresh_token='+EncodingUtil.urlEncode(cred.Refresh_Token__c, 'UTF-8')+'&client_secret='+EncodingUtil.urlEncode(cred.Client_Secret__c, 'UTF-8')+'&client_id='+EncodingUtil.urlEncode(cred.Client_Id__c, 'UTF-8')+'&redirect_uri=https://katondirecttrial--dev1--c.sandbox.vf.force.com/apex/SnowflakeAccessTokenPage';
        //String body = '{"grant_type" : "authorization_code","code":"'+authCode+'","client_secret":"'+cred.Client_Secret__c+'","client_id":"'+cred.Client_Id__c+'","redirect_uri":"https://katondirecttrial--dev1--c.sandbox.vf.force.com/apex/SnowflakeAccessTokenPage"}';
        req.setBody(payload);
        req.setHeader( 'Content-Type', 'application/x-www-form-urlencoded' );
        req.setMethod('POST');
        HttpResponse res= h.send(req);
        Map<String, Object> resBody = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        System.debug(res.getBody());
        System.debug(payload);
        cred.Access_Token__c = (String)resBody.get('access_token');*/
        //cred.Refresh_Token__c = (String)resBody.get('refresh_token');
        //UPDATE cred;
    }
    @AuraEnabled
    public static String getLeadFromSnowflake( Integer ofValue, Integer limitRec ){
        Snowflake_Creds__mdt cred = [SELECT DeveloperName, MasterLabel, Client_Secret__c, Table__c, Schema__c, Database__c, Client_Id__c, Access_Token__c FROM Snowflake_Creds__mdt];
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer '+cred.Access_Token__c);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        System.debug( cred.Access_Token__c );
        //req.setEndpoint('https://ww53743.europe-west4.gcp.snowflakecomputing.com/api/v2/statements');
        req.setEndpoint('https://kja38390.us-east-1.snowflakecomputing.com/api/v2/statements');
        String body = '{"statement" : "select * from '+cred.Table__c+' order by LEADID limit '+limitRec+' OFFSET '+ofValue+'","timeout" : 60,"resultSetMetaData":{"format":"json"},"database" : "'+cred.Database__c+'","schema" : "'+cred.Schema__c+'","warehouse" : "COMPUTE_WH"}';
    	req.setBody(body);
        System.debug(body);
        HttpResponse res = h.send(req);
        System.debug(res.getBody());
        return res.getBody();
    }
    @AuraEnabled
    public static String getMatchNPILeads( String ids, Boolean colInclude ){
        System.debug( 'IDSS:'+ids );
        String stat = 'select LEADID';
        System.debug( colInclude );
        if( colInclude ){
            stat+= ', FIRSTNAME';
        }
        Snowflake_Creds__mdt cred = [SELECT DeveloperName, MasterLabel, Client_Secret__c, Table__c, Schema__c, Database__c, Client_Id__c, Access_Token__c FROM Snowflake_Creds__mdt];
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer '+cred.Access_Token__c);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        System.debug( cred.Access_Token__c );
        //req.setEndpoint('https://ww53743.europe-west4.gcp.snowflakecomputing.com/api/v2/statements');
        req.setEndpoint('https://kja38390.us-east-1.snowflakecomputing.com/api/v2/statements');
        String body = '{"statement" : "'+stat+' from '+cred.Table__c+' WHERE LEADID IN '+ids+'","timeout" : 60,"resultSetMetaData":{"format":"json"},"database" : "'+cred.Database__c+'","schema" : "'+cred.Schema__c+'","warehouse" : "COMPUTE_WH"}';
    	System.debug('BODY:'+body);
        req.setBody(body);
        System.debug(body);
        HttpResponse res = h.send(req);
        System.debug(res.getBody());
        return res.getBody();
    }
    @AuraEnabled
    public static Map<String, String> getLicenseType(){
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setHeader('Authorization', 'ApiKey 4UPoNhKq5hcnpW7SRqrJtJrc0h1dok0pGN6mAzsOsc0=');
        req.setHeader('Accept', 'application/json');
        req.setEndPoint( 'https://production-pagesvc.openposition.io/api/Lookup/GetByType?typeName=LicenseType' );
        req.setMethod( 'GET' );
        HttpResponse res = h.send( req );
        System.debug( res.getBody() );
        Map<String, String> licType = new Map<String, String>();
        List<Object> resJson = (List<Object>)JSON.deserializeUntyped( res.getBody() );
        system.debug('resJson==>'+resJson);
        for( Object resJ : resJson ){ //[{"id":{"Value":{"value":"test","name":"alok"}}]
            Map<String, Object> resV = (Map<String, Object>)resJ;
            system.debug('resV===>'+resV);
            Map<String, Object> value = (Map<String, Object>)resV.get('Value');
            system.debug('value====>'+value);
            licType.put( (String)(value.get('value')), (String)(value.get('name')) );
        }
        return licType;
    }
    @AuraEnabled
    public static String getAllInfo(){
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setHeader('Authorization', 'ApiKey +CjRVUWr9oI8m8lMus2Ro1+a+gS4wQNSkdr0znKog5w=');
        req.setHeader('Accept', 'application/json');
        req.setTimeout(20000);
        req.setEndPoint( 'https://production-mapleadsvc.openposition.io/api/MapLead/GetPracticeAreas' );
        req.setMethod( 'GET' );
        HttpResponse res = h.send( req );
        System.debug( res.getBody() );
        return res.getBody();
    }
    @AuraEnabled
    public static String getLeadsCount( String LType, String Parea, String Address, String MinStart, String MinEnd, String MinYear, String MaxYear, String Zip, String Setting, String NPI, String State, String County, String Location, Boolean Mile ){
        System.debug( '-->'+LType+'::'+Parea+'::'+Mile );
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setHeader('Authorization', 'ApiKey +CjRVUWr9oI8m8lMus2Ro1+a+gS4wQNSkdr0znKog5w=');
        req.setHeader('Accept', 'application/json');
        req.setHeader( 'Content-Type', 'application/json' );
        req.setTimeout(30000);
        req.setEndPoint( 'https://production-mapleadsvc.openposition.io/api/MapLead/CountMapLeads' );
        String body = '';
        body += '{"address": "'+Location+'"';
        body+= MinStart != null ? ',"driveTimeFrom": '+MinStart+'':'';
        body+= MinEnd!=null ? ',"driveTimeOrMiles": '+MinEnd+'':'';
        body+= LType!=null ? ',"licenseType": "'+LType+'"':'';
        body+= mile!=null ? ',"searchByMiles": '+mile:'';
        body+= ',"iscampaignbuilder": true';

        body+= Parea!=null ? ',"practiceArea": "'+Parea+'"':'';
        body+= MinYear!=null ? ',"minYears": '+MinYear:'';
        body+= MaxYear!=null ? ',"maxYears": '+MaxYear:'';
        body+= State!=null ? ',"states":[" '+State+'"]':'';
        body+= County!=null ? ',"counties":[" '+County+'"]':'';
        body+= Zip!=null ? ',"zip":[" '+Zip+'"]':'';
        body+= Setting!=null ? ',"settings":[" '+Setting+'"]':'';
        body+= Address!=null ? ',"commercialAddress":"'+Address+'"':'';
        body+= NPI!=null ? ',"originalPracticeAreas":[" '+NPI+'"]':'';
        body+='}';
        //"practiceArea":"'+Parea+'","minYears": '+MinYear+',  "maxYears": '+MaxYear+', "states": [ "'+State+'" ],  "counties": [  "'+County+'" ], "zip": [ "'+Zip+'" ], "settings": [ "'+Setting+'"  ],  "originalPracticeAreas": [ "'+NPI+'"  ], "commercialAddress": "'+Address+'"}';
        System.debug( 'BODY::'+body );
        req.setBody( body );
        req.setMethod( 'POST' );
        HttpResponse res = h.send( req );
        System.debug( res.getBody() );
        return res.getBody();
    }
}