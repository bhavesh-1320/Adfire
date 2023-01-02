@isTest
public class GoogleDriveAccessTokenTestClass {
    
    @isTest
    public static void getAuthCodeTest(){
        GoogleDriveAccessToken GoogleDriveRef = new GoogleDriveAccessToken();
        GoogleDriveRef.getAuthCode();
    }
    
    @isTest
    public static void getAccessTokenTest(){
        GoogleDriveAccessToken GoogleDriveRef = new GoogleDriveAccessToken();
        ApexPages.currentPage().getParameters().put('code','a0AeTM1ieFt8bHdlBefVgGUEiJ8zlDoh9VlxF8AgRPqnZbyl1MUOuInhSZw_9oOSChOTq');
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new campaignFolderCreateClsMockCallout());
        GoogleDriveRef.getAccessToken();
        Test.stopTest();
    }
    
    @testSetup static void setup() {
        GoogleDriveCreds__c GD = new GoogleDriveCreds__c(AHM__c='1LvT9V1pb0gqhuAoZVvKNcTX00pDZAGaQ', AHR__c='1iKJZ_iwgZ58x7Y-Xr6zakGdqG4S_itt8', Client_Secret__c='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', MainFolderId__c='1g1UzqV35Dj_o9_2IOCGfdEGR98mNWYlw', Access_Token__c='ya29.a0AeTM1ieFt8bHdlBefVgGUEiJ8zlDoh9VlxF8AgRPqnZbyl1MUOuInhSZw_9oOSChOTq_-pBEwaqKi7xyOs-l3VO0O-9RT71DGa3fcGZkhJ0gcwzXk5RGFuE25WecfQ7rmq22Mn5S8RLFNpEWE4sv8ioEgbvyaCgYKAR8SARASFQHWtWOmRYX_0u8P8Zj5XZSZvgdpjA0163', Client_Id__c='417977852444-indnnundr7b3s1i380pjf4c2a2c6igco.apps.googleusercontent.com');
        insert GD;
    }

}