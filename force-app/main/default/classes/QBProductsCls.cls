public class QBProductsCls {
    public QBProductsCls( ApexPages.StandardSetController sc ){
        
    }
    public static PageReference getProducts(){
        Quickbook_Creds__mdt cred = [SELECT Id, realmId__c, Client_Secret__c, MasterLabel, DeveloperName, Refresh_Token__c, redirect_uri__c, Client_Id__c, Access_Token__c, Endpoint__c FROM Quickbook_Creds__mdt WHERE DeveloperName = 'Creds'];
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        String endpoint = cred.Endpoint__c+'/'+cred.realmId__c+'/query?query=select%20Name,UnitPrice%20from%20Item&minorversion=65';
        System.debug(endpoint);
        req.setEndPoint(endpoint);
        req.setHeader('Authorization', 'Bearer '+cred.Access_Token__c);
        req.setHeader('Accept', 'application/json');
        req.setMethod('GET');
        HttpResponse res= h.send(req);
        Map<String, Object> resBody = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        System.debug(resBody);
        Map<String, Object> qRes = (Map<String, Object>)resBody.get( 'QueryResponse' );
        List<Object> items = (List<Object>)qRes.get( 'Item' );
        List<Product2> prods = new List<Product2>();
        List<PricebookEntry> pEntries = new List<PricebookEntry>();
        Map<String, Id> prodIdRecId = new Map<String, Id>();
        for( Product2 p : [SELECT Id, Product_Id__c FROM Product2] ){
            prodIdRecId.put( p.Product_Id__c, p.Id );
        }
        Id pbId = [SELECT Id, Name FROM Pricebook2 WHERE Name = 'Standard Price Book' LIMIT 1].Id;
        Map<String, Id> prodIdPEId = new Map<String, Id>();
        for( PricebookEntry pEntry : [SELECT Id, Product2.Product_Id__c FROM PricebookEntry WHERE Pricebook2.Name = 'Standard Price Book'] ){
            prodIdPEId.put( pEntry.Product2.Product_Id__c, pEntry.Id );
        }
        for( Object item : items ){
            Map<String, Object> itemDetail = (Map<String, Object>)item;
            Product2 prod = new Product2();
            prod.Name = (String)itemDetail.get( 'Name' );
            prod.Product_Id__c = (String)itemDetail.get( 'Id' );
            prod.IsActive = true;
            prods.add( prod );
            PricebookEntry pEntry = new PricebookEntry();
            pEntry.UnitPrice = (Decimal)itemDetail.get( 'UnitPrice' );
            pEntry.Product2 = prod;
            pEntry.Pricebook2Id = pbId;
            pEntry.IsActive = true;
            if( prodIdPEId.containsKey( prod.Product_Id__c ) ){
                pEntry.Id = prodIdPEId.get( prod.Product_Id__c );
            }
            pEntries.add( pEntry );
        }
        Schema.SObjectField f = Product2.Fields.Product_Id__c;
        if(!prods.isEmpty())
        {
            Database.upsert(prods, f, true);
        }
        for( PricebookEntry pEntry : pEntries ){
            if( !prodIdPEId.containsKey( pEntry.Product2.Product_Id__c ) ){
            	pEntry.Product2Id = pEntry.Product2.Id; 	   
            }
        }
        UPSERT pEntries;
        Schema.DescribeSObjectResult result = Product2.SObjectType.getDescribe(); 
        PageReference pageRef = new PageReference('/' + result.getKeyPrefix()); 
        pageRef.setRedirect(true); 
        return pageRef; 
    }
}