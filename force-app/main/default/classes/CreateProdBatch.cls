public class CreateProdBatch implements Database.Batchable<sObject>, Database.AllowsCallouts{
    Set<Id> productIds;
    public CreateProdBatch( Set<Id> prodIds ){
        System.debug('c:'+prodIds);
        productIds = prodIds;
    }
    public List<Product2> start(Database.BatchableContext bc){
        return [SELECT Id, Name FROM Product2 WHERE Id IN :productIds];
    }
    public void execute( Database.BatchableContext bc, List<Product2> products ){
        Quickbook_Creds__mdt cred = [SELECT Id, realmId__c, Client_Secret__c, MasterLabel, DeveloperName, Refresh_Token__c, redirect_uri__c, Client_Id__c, Access_Token__c, Endpoint__c FROM Quickbook_Creds__mdt WHERE DeveloperName = 'Creds'];
        Integer costOfGSoldAcc = 80;	//Change with account
        Integer incomeRef = 48; 
        Http h = new Http();
        String endpoint = cred.Endpoint__c+'/'+cred.realmId__c+'/item?minorversion=65';
        HttpRequest req = new HttpRequest();
        req.setEndPoint(endpoint);
        req.setHeader('Authorization', 'Bearer '+cred.Access_Token__c);
        req.setHeader( 'Content-Type', 'application/json' );
        req.setHeader('Accept', 'application/json');
        req.setMethod('POST');
        for( Product2 prod : products ){
            req.setBody('{"Name":"'+prod.Name+'","Type":"Service","ExpenseAccountRef":{"value":'+costOfGSoldAcc+'}, "IncomeAccountRef":{"value":'+incomeRef+'}}');
            HttpResponse res= h.send(req);
            Map<String, Object> resBody = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            System.debug(resBody);
            Map<String,Object> itemMap = (Map<String,Object>)resBody.get('Item');
            if( itemMap != null ){
            	prod.Product_Id__c = (String)itemMap.get( 'Id' );    
            }
        }
        productTriggerHelper.start = false;
        UPDATE products;
    }
    public void finish( Database.BatchableContext bc ){
        
    }
}