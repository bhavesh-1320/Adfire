public class AudienceTriggerHelper {
    @future(callout=true)
    public static void createAudienceInIterable( Set<Id> audIds ){
        List<Audience__c> newAudiences = [SELECT Id, Email__c, Address_Line_1__c, Address_Line_2__c,
                                          City__c, Zip__c, state__c, Last_Name__c, First_Name__c
                                          FROM Audience__c WHERE Id IN :audIds];
        String resBody = '{"users":[';
        for( Audience__c audience : newAudiences ){
            resBody += '{"email":"'+audience.Email__c+'", "dataFields":{';
            resBody += '"addressLine1":"'+audience.Address_Line_1__c+'",';
            resBody += '"emailListIds": [1951381],"addressLine2": "'+audience.Address_Line_2__c+'",';
            resBody += '"city": "'+audience.City__c+'","zipcode": "'+audience.Zip__c+'","state": "'+audience.state__c+'","lastName": "'+audience.Last_Name__c+'","firstName": "'+audience.First_Name__c+'"}},';
        }
        resBody = resBody.substring(0, resBody.length()-1);
        resBody += ']}';
        System.debug('body:'+resBody);
        HttpRequest req = new HttpRequest();
        req.setBody(resBody);
        req.setHeader('API_Key', '1789943a29aa48a7870cf3f1de85152f');
        req.setEndpoint('https://api.iterable.com/api/users/bulkUpdate');
        req.setMethod('POST');
        Http h = new Http();
        HttpResponse res = h.send(req);
        System.debug('resBody:'+res.getBody());
    }
}