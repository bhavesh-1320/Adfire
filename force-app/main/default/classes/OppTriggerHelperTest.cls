@isTest
public class OppTriggerHelperTest {
    
    @isTest
    public static void OppTriggerMethod(){
        
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
        
        PriceBook2 priceBook = new PriceBook2(Name = 'Adfire Health Marketing - HCP',isActive = true);
        insert priceBook;
        
        PricebookEntry objPBEntry = new PricebookEntry(Pricebook2Id = priceBook.Id, Product2Id=product.Id,UnitPrice=500,IsActive=true);
        Insert objPBEntry;
        
        Opportunity opp = new opportunity(Name= 'opp',CloseDate=date.today(), AccountId = acc.id, StageName='Needs Analysis', Audience_Type__C = 'HCP', Flight_Start_Date__c = date.today(), Flight_End_Date__c = endDate,RecordTypeID = RecordTypeId ,Direct__c=false,Google_Drive_Link__c='https://drive.google.com/drive/u/0/folders/1_3Z-hZ4H8onW0I4ccrmE5Z9j-kp1xxT9');
        insert opp;
        Contract con  = new Contract(name='contract1',AccountID = acc.id,status= 'Draft',Opportunity__c = opp.id);
        insert con;
       
        OpportunityLineItem OppLineItem = new OpportunityLineItem(PriceBookEntryId = objPBEntry.Id,OpportunityId=opp.Id,Quantity=5.00, UnitPrice = 500);
        insert OppLineItem;
        
        opp.stageName = 'Proposal';
        update opp;
       // campaignFolderCreateCls.createMondayBoard(new List<Id>{opp.Id});
        Test.stopTest();
    }

}