@isTest
public class QuickbookAccessTokenTest {
    
    @isTest
    public static void getAuthCodeTest(){
        QuickbookAccessToken QuickbookRef = new QuickbookAccessToken();
        //Quickbook_Creds__mdt QC = new Quickbook_Creds__mdt(Client_Secret__c='tpk0bDu7yGDAmU655kCiefGsb0UeuR06gDKIIjpL', Client_Id__c='ABSq2CZ1asSiLtarwbTLv0xibNcRpNjRT2KlEUUBJyFv8k76cr', redirect_uri__c='https://katondirecttrial--dev1--c.sandbox.vf.force.com/apex/QuickbooksAccessTokenPage');
        //insert QC;
        QuickbookRef.getAuthCode();
    }
    
    @isTest
    public static void getAccessTokenUsingRTokenTest(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new campaignFolderCreateClsMockCallout());
        QuickbookAccessToken.getAccessTokenUsingRToken();        
        Test.stopTest();
    }
    
    @isTest
    public static void getAccessTokenTest(){
        QuickbookAccessToken Quickbook = new QuickbookAccessToken();
        ApexPages.currentPage().getParameters().put('code','a0AeTM1ieFt8bHdlBefVgGUEiJ8zlDoh9VlxF8AgRPqnZbyl1MUOuInhSZw_9oOSChOTq');
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new campaignFolderCreateClsMockCallout());
        Quickbook.getAccessToken();
        Test.stopTest();
    }
    
    @testSetup static void setup() {
        
    }

}