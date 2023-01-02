public class SyncLeadIterable {
    public SyncLeadIterable( ApexPages.StandardController sc ){
        
    } 
    public PageReference syncingIterable(){
        Id recId = ApexPages.currentPage().getParameters().get('id');
        System.debug('rId:'+recId);
        if( recId != null ){
            Lead l = [SELECT Id, Name, LastName, FirstName, Email FROM Lead WHERE Id = :recId];
            HttpRequest req = new HttpRequest();
            req.setHeader('API_Key', '1789943a29aa48a7870cf3f1de85152f');
            req.setEndpoint('https://api.iterable.com/api/users/update');
            req.setMethod('POST');
            req.setBody('{"email":"'+l.Email+'", "dataFields": {"firstName": "'+l.FirstName+'","lastName": "'+l.LastName+'"}}');
            Http h = new Http();
            HttpResponse res = h.send(req);
            Map<String, Object> resMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            //lId = (Integer)resMap.get( 'listId' );
            //seg.List_Id__c = lId;
            System.debug('resMap:'+resMap);
        }
        return new Pagereference( '/'+recId );
    }
}