@isTest
public class IterableWebhooktest {

    static testMethod void  testAccountTest(){
        Lead leadRecord = new Lead(email='abc@gmail.com',Status='New',LastName='sharma',Company='Cyntexa');
        insert leadRecord;
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        String str = '{"email": "abc@gmail.com", "eventName":"party"}';
        req.requestURI = '/services/apexrest/getLeadHistory/';  
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(str);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        IterableWebhook.testAccount();
        Test.stopTest();
    }
    
    private static testMethod void createMondayBoardTest2(){
        
    }
    
}