@isTest
public class CreateGDriveBatchTest {
    
    @isTest
    public static void CreateGDriveBatchTestMethod(){
        Account acc  = new Account(Name='acc1');
        insert acc; 
        Date endDate = date.today().addMonths(2);
        System.debug('ee:'+endDate);
        
        ID RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Adfire Health Marketing').getRecordTypeId();
        system.debug('Record Type Id==>'+RecordTypeId);
        Product2 product = new Product2(Name='ProductExample', isActive=true);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new campaignFolderCreateClsMockCallout());
        insert product;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = product.Id,
        UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        
        PriceBook2 priceBook = new PriceBook2(Name = 'Adfire Health Marketing',isActive = true);
        insert priceBook;
        
        PricebookEntry objPBEntry = new PricebookEntry(Pricebook2Id = priceBook.Id, Product2Id=product.Id,UnitPrice=500,IsActive=true);
        Insert objPBEntry;
        
        Opportunity opp = new opportunity(Name= 'opp',CloseDate=date.today(), AccountId = acc.id, StageName='Needs Analysis', Audience_Type__C = 'HCP', Flight_Start_Date__c = date.today(), Flight_End_Date__c = endDate,RecordTypeID = RecordTypeId ,Direct__c=false,Google_Drive_Link__c='https://drive.google.com/drive/u/0/folders/1_3Z-hZ4H8onW0I4ccrmE5Z9j-kp1xxT9');
        insert opp;
        Contract con  = new Contract(name='contract1',AccountID = acc.id,status= 'Draft',Opportunity__c = opp.id);
        insert con;
        
        OpportunityLineItem OppLineItem = new OpportunityLineItem(PriceBookEntryId = objPBEntry.Id,OpportunityId=opp.Id,Quantity=5.00, UnitPrice = 500);
        insert OppLineItem;
        CreateGDriveBatch GDriveBatch = new CreateGDriveBatch(new List<ID>{opp.id});
        database.executeBatch(GDriveBatch);
        Test.stopTest();  
    }
    
    @testSetup static void setup() {
        GoogleDriveCreds__c GD = new GoogleDriveCreds__c(AHM__c='1LvT9V1pb0gqhuAoZVvKNcTX00pDZAGaQ', AHR__c='1iKJZ_iwgZ58x7Y-Xr6zakGdqG4S_itt8', Client_Secret__c='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', MainFolderId__c='1g1UzqV35Dj_o9_2IOCGfdEGR98mNWYlw', Access_Token__c='ya29.a0AeTM1ieFt8bHdlBefVgGUEiJ8zlDoh9VlxF8AgRPqnZbyl1MUOuInhSZw_9oOSChOTq_-pBEwaqKi7xyOs-l3VO0O-9RT71DGa3fcGZkhJ0gcwzXk5RGFuE25WecfQ7rmq22Mn5S8RLFNpEWE4sv8ioEgbvyaCgYKAR8SARASFQHWtWOmRYX_0u8P8Zj5XZSZvgdpjA0163', Client_Id__c='417977852444-indnnundr7b3s1i380pjf4c2a2c6igco.apps.googleusercontent.com');
        insert GD;
    }
}