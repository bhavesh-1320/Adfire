public class GoogleDriveAccessToken {
    public PageReference getAuthCode(){
        GoogleDriveCreds__c cred = [SELECT Client_Secret__c, Client_Id__c FROM GoogleDriveCreds__c];
        String authUrl = 'https://accounts.google.com/o/oauth2/v2/auth?redirect_uri=https://katondirecttrial--dev1--c.sandbox.vf.force.com/apex/GoogleDriveAccessTokenPage&prompt=consent&response_type=code&client_id='+cred.Client_Id__c+'&scope=https://www.googleapis.com/auth/drive';
        return new PageReference( authUrl );
    }
    public void getAccessToken(){
        String authCode =  apexpages.currentpage().getparameters().get('code');
        GoogleDriveCreds__c cred = [SELECT Client_Secret__c, Client_Id__c, Access_Token__c FROM GoogleDriveCreds__c];
        system.debug('cred===>'+cred);
        if( authCode != null && authCode != '' ){
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndPoint('https://oauth2.googleapis.com/token');
            String body = '{"grant_type" : "authorization_code","code":"'+authCode+'","client_secret":"'+cred.Client_Secret__c+'","client_id":"'+cred.Client_Id__c+'","redirect_uri":"https://katondirecttrial--dev1--c.sandbox.vf.force.com/apex/GoogleDriveAccessTokenPage","scope":"https://www.googleapis.com/auth/drive"}';
            req.setBody(body);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            HttpResponse res= h.send(req);
            Map<String, Object> resBody = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            cred.Access_Token__c = (String)resBody.get('access_token');
            UPDATE cred;
        }
    }
}