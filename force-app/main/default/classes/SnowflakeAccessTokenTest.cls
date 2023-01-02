@isTest
public class SnowflakeAccessTokenTest {
    
    @isTest
    public static void getAuthCodeTest(){
        SnowflakeAccessToken SnowFlake = new SnowflakeAccessToken();
        SnowFlake.getAuthCode();
    }
    
    @isTest
    public static void getAccessTokenTest(){
        ApexPages.currentPage().getParameters().put('code','a0AeTM1ieFt8bHdlBefVgGUEiJ8zlDoh9VlxF8AgRPqnZbyl1MUOuInhSZw_9oOSChOTq');
        SnowflakeAccessToken SnowFlake = new SnowflakeAccessToken();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new campaignFolderCreateClsMockCallout());
        SnowFlake.getAccessToken();
        test.stopTest();
    }
    
    @isTest
    public static void getLeadFromSnowflakeTest(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new campaignFolderCreateClsMockCallout());
        SnowflakeAccessToken.getLeadFromSnowflake(2, 4);
        Test.stopTest();   
    }
    
    @isTest
    public static void getMatchNPILeadsTest(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new campaignFolderCreateClsMockCallout());
        SnowflakeAccessToken.getMatchNPILeads('12345678910', true);
        Test.stopTest(); 
    }
    
    @isTest
    public static void getLicenseTypeTest(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SnowflakeAccessTokenMockCallout());
        SnowflakeAccessToken.getLicenseType();
        Test.stopTest();
    }
    
    @isTest
    public static void getAllInfoTest(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new campaignFolderCreateClsMockCallout());
        SnowflakeAccessToken.getAllInfo();
        Test.stopTest();
    }
    
    @isTest
    public static void getLeadsCountTest(){
       Test.startTest();
       Test.setMock(HttpCalloutMock.class, new campaignFolderCreateClsMockCallout());
       SnowflakeAccessToken.getLeadsCount('ABC', 'BCD', 'Jaipur', 'AB', 'CD', '1998', '2025', 'zip', 'Setting', 'NPI', 'State', 'County', 'India',true);
       Test.stopTest(); 
    }

}