@isTest
public class ProposalIOInvoiceTest1 {
    /* @isTest
       public static void getQuoteInvoiceMethod(){
            Account acc = new Account(name='acc1');
            insert acc;
            id accountID = acc.id;
            Profile profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
            User u = new user();
            u.LastName = 'Test Code';
            u.Email = 'test@test.com';
            u.Alias = 'Tcode';
            u.Username = 'aloktest1234444@test.com';
            u.CommunityNickname = 'test12';
            u.LocaleSidKey = 'en_US';
            u.TimeZoneSidKey = 'GMT';
            u.ProfileID = profileId.Id;
            u.LanguageLocaleKey = 'en_US';
            u.EmailEncodingKey = 'UTF-8';
            //insert u;
            Opportunity opp = new opportunity(Name= 'opp1',CloseDate=date.today(), AccountId = accountID, StageName='Closed Won', Audience_Type__C = 'HCP', Flight_Start_Date__c = date.today(), Flight_End_Date__c = date.today());
            insert opp;
            Id oppId= opp.Id;
            system.debug(oppId);
            Quote q = new Quote(name='qq1', OpportunityId = oppId, Flight_End_Date__c= date.today(), Flight_Start_Date__c = date.today());
            insert q;
            Id QuoteId = q.id;
            ProposalIOInvoiceCls.getQuoteInvoice(QuoteId);
}*/
    
    @isTest
    public static void getContractInvoiceTest1(){
        Contract con = [select id, AccountID, Status from Contract limit 1];
        ProposalIOInvoiceCls.getContractInvoice(con.id);
    }
    
    @isTest
    public static void saveIOInvoiceTest1(){
        Account acc = new Account(name='acc1');
        insert acc;
        Product2 product = new Product2(Name='EmailExample', isActive=true);
        
        Test.startTest();
        // OppSegTriggerHelper.createAudienceInIterable();
        Test.setMock(HttpCalloutMock.class, new OppSegTriggerHelperMockCallout());
        insert product;
        Date endDate = date.today().addMonths(2);
        Opportunity opp = new opportunity(Name= 'opp',CloseDate=date.today(), AccountId = acc.id, StageName='Needs Analysis', Audience_Type__C = 'HCP', Flight_Start_Date__c = date.today(), Flight_End_Date__c = endDate ,Direct__c=false,Google_Drive_Link__c='https://drive.google.com/drive/u/0/folders/1_3Z-hZ4H8onW0I4ccrmE5Z9j-kp1xxT9');
        insert opp;
        Contract con  = new Contract(name='contract1',AccountID = acc.id,status= 'Draft',Opportunity__c = opp.id);
        insert con;
        Invoice__c Inv = new Invoice__c(IO__c = con.id,Start_Date__c = date.today(), End_Date__c = date.today().addMonths(1));
        insert Inv;
        Segment__c seg = new Segment__c(Name = 'Segment1');
        insert seg;
        Audience__c Audi =  new Audience__c(First_Name__c='Audi1',Segment__c = seg.id);
        insert Audi;
        Invoice_Line_Item__c  InvoiceLine = new Invoice_Line_Item__c(Invoice__c = Inv.Id,Product__c=product.id, Sales_Price__c=9000.00);
        insert InvoiceLine;
        Opportunity_Segment__c OppSegment = new Opportunity_Segment__c(Opportunity__c = opp.id,Segment__c = seg.id,IO_Invoice_Line_Item__c=InvoiceLine.id);
        insert OppSegment;
        ProposalIOInvoiceCls.saveIOInvoice(new List<Invoice__c> {Inv}, new List<Invoice_Line_Item__c>{InvoiceLine}, new List<Id>{Inv.id}, new List<Opportunity_Segment__c>{OppSegment}, new List<String>{'one','two','three'});
        Test.stopTest();
        
    }
    @isTest
    public static void saveIOInvoiceTest2(){
        /*Contract con = [select Id, AccountID, status from Contract];
        Invoice__c Inv = [Select IO__c,Start_Date__c, End_Date__c from Invoice__c];
        Invoice_Line_Item__c InvLineItem = [select Invoice__c, Sales_Price__c from Invoice_Line_Item__c];
        Opportunity_Segment__c OppSegment = [select Segment__c, IO_Invoice_Line_Item__c from Opportunity_Segment__c];
        
        Invoice__c InvTemp = new Invoice__c(IO__c = con.id,Start_Date__c = date.today(), End_Date__c = date.today().addMonths(1));
        ProposalIOInvoiceCls.saveIOInvoice(new List<Invoice__c> {InvTemp}, new List<Invoice_Line_Item__c>{InvLineItem}, new List<Id>{Inv.id}, new List<Opportunity_Segment__c>{OppSegment}, new List<String>{'one','two','three'}); */
        }
    
    @isTest
    public static void getResultsTest(){
        Segment__c seg = new Segment__c(Name = 'AlokSegment1');
        insert seg;
        ProposalIOInvoiceCls.getResults('Invoice__c','Name','Alok',new list<Id>{seg.id});
    }
    
    @isTest
    public static void getContractInvoiceStartEndTest(){
        Account acc = new Account(name='acc1');
        insert acc;
        Product2 product = new Product2(Name='EmailExample', isActive=true);
        insert product;
        Date endDate = date.today().addMonths(2);
        Opportunity opp = new opportunity(Name= 'opp',CloseDate=date.today(), AccountId = acc.id, StageName='Needs Analysis', Audience_Type__C = 'HCP', Flight_Start_Date__c = date.today(), Flight_End_Date__c = endDate ,Direct__c=false,Google_Drive_Link__c='https://drive.google.com/drive/u/0/folders/1_3Z-hZ4H8onW0I4ccrmE5Z9j-kp1xxT9');
        insert opp;
        Contract con  = new Contract(name='contract1',AccountID = acc.id,status= 'Draft',Opportunity__c = opp.id);
        insert con;
       ProposalIOInvoiceCls.getContractInvoiceStartEnd(con.id,Date.today(),Date.today().addMonths(1));
        
    }
    
    @isTest
    public static void getAllSegmentsTest1(){
        Segment__c seg1 = new Segment__c(Name = 'AlokSegment1');
        insert seg1;
        Segment__c seg2 = new Segment__c(Name = 'PawanSegment1');
        insert seg2;
        String ids = seg2.id;
        ProposalIOInvoiceCls.getAllSegments('Alok', new List<String>{ids});
    }
    
    @isTest
    public static void getAllSegmentsTest2(){
        ProposalIOInvoiceCls.getAllSegments('', null);
    }
    @isTest
    public static void SObjectResultTest(){
        Segment__c seg2 = new Segment__c(Name = 'PawanSegment1');
        insert seg2;
        Id ids = seg2.id;
        ProposalIOInvoiceCls.SObJectResult soBJ = New ProposalIOInvoiceCls.SObJectResult('Alok',ids);
    }
    
    @testSetup static void setup() {
       /* Account acc = new Account(name='acc1');
        insert acc;
        Product2 product = new Product2(Name='EmailExample', isActive=true);
        insert product;
        Date endDate = date.today().addMonths(2);
        Opportunity opp = new opportunity(Name= 'opp',CloseDate=date.today(), AccountId = acc.id, StageName='Needs Analysis', Audience_Type__C = 'HCP', Flight_Start_Date__c = date.today(), Flight_End_Date__c = endDate ,Direct__c=false,Google_Drive_Link__c='https://drive.google.com/drive/u/0/folders/1_3Z-hZ4H8onW0I4ccrmE5Z9j-kp1xxT9');
        insert opp;
        Contract con  = new Contract(name='contract1',AccountID = acc.id,status= 'Draft',Opportunity__c = opp.id);
        insert con;
        Invoice__c Inv = new Invoice__c(IO__c = con.id,Start_Date__c = date.today(), End_Date__c = date.today().addMonths(1));
        insert Inv;
        Segment__c seg = new Segment__c(Name = 'Segment1');
        insert seg;
        Audience__c Audi =  new Audience__c(First_Name__c='Audi1',Segment__c = seg.id);
        insert Audi;
        Invoice_Line_Item__c  InvoiceLine = new Invoice_Line_Item__c(Invoice__c = Inv.Id,Product__c=product.id, Sales_Price__c=9000.00);
        insert InvoiceLine;
        Opportunity_Segment__c OppSegment = new Opportunity_Segment__c(Opportunity__c = opp.id,Segment__c = seg.id,IO_Invoice_Line_Item__c=InvoiceLine.id);
        insert OppSegment;*/
    }
}