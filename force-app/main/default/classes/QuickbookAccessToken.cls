public class QuickbookAccessToken {
    public PageReference getAuthCode(){
        Quickbook_Creds__mdt cred = [SELECT Client_Secret__c, Client_Id__c, redirect_uri__c FROM Quickbook_Creds__mdt];
        String authUrl = 'https://appcenter.intuit.com/connect/oauth2?redirect_uri='+cred.redirect_uri__c+'&scope=com.intuit.quickbooks.accounting&response_type=code&state=test&client_id='+cred.Client_Id__c;
        return new PageReference( authUrl );
    }
    public void getAccessToken(){
        String authCode = apexpages.currentpage().getparameters().get('code');
        String rId = apexpages.currentpage().getparameters().get('realmId');
        if( authCode != null && authCode != '' ){
            Quickbook_Creds__mdt cred = [SELECT Id, realmId__c, Client_Secret__c, MasterLabel, DeveloperName, Refresh_Token__c, redirect_uri__c, Client_Id__c, Access_Token__c FROM Quickbook_Creds__mdt WHERE DeveloperName = 'Creds'];
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndPoint('https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer');
            String payload = 'grant_type=authorization_code&code='+EncodingUtil.urlEncode(authCode, 'UTF-8')+'&client_secret='+EncodingUtil.urlEncode(cred.Client_Secret__c, 'UTF-8')+'&client_id='+EncodingUtil.urlEncode(cred.Client_Id__c, 'UTF-8')+'&redirect_uri='+cred.redirect_uri__c;
            req.setBody(payload);
            req.setHeader( 'Content-Type', 'application/x-www-form-urlencoded' );
            req.setMethod('POST');
            HttpResponse res= h.send(req);
            Map<String, Object> resBody = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            System.debug(res.getBody());
            System.debug(payload);
            cred.Access_Token__c = (String)resBody.get('access_token');
            cred.Refresh_Token__c = (String)resBody.get('refresh_token');
            cred.realmId__c = rId;
            if( !Test.isRunningTest())
              MetaDataUtility.upsertMetadata(cred);
        }
    }
    public static void getAccessTokenUsingRToken(){
        Quickbook_Creds__mdt cred = [SELECT Id, realmId__c, Client_Secret__c, MasterLabel, DeveloperName, Refresh_Token__c, redirect_uri__c, Client_Id__c, Access_Token__c FROM Quickbook_Creds__mdt WHERE DeveloperName = 'Creds'];
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndPoint('https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer');
        String payload = 'grant_type=refresh_token&refresh_token='+EncodingUtil.urlEncode(cred.Refresh_Token__c, 'UTF-8')+'&client_secret='+EncodingUtil.urlEncode(cred.Client_Secret__c, 'UTF-8')+'&client_id='+EncodingUtil.urlEncode(cred.Client_Id__c, 'UTF-8')+'&redirect_uri='+cred.redirect_uri__c;
        //String body = '{"grant_type" : "authorization_code","code":"'+authCode+'","client_secret":"'+cred.Client_Secret__c+'","client_id":"'+cred.Client_Id__c+'","redirect_uri":"https://katondirecttrial--dev1--c.sandbox.vf.force.com/apex/SnowflakeAccessTokenPage"}';
        req.setBody(payload);
        req.setHeader( 'Content-Type', 'application/x-www-form-urlencoded' );
        req.setMethod('POST');
        HttpResponse res= h.send(req);
        Map<String, Object> resBody = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        System.debug(res.getBody());
        System.debug(payload);
        cred.Access_Token__c = (String)resBody.get('access_token');
        cred.Refresh_Token__c = (String)resBody.get('refresh_token');
        if( !Test.isRunningTest())
              MetaDataUtility.upsertMetadata(cred);
    }
}