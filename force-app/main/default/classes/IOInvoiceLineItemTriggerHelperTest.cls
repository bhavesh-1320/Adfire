@isTest
public class IOInvoiceLineItemTriggerHelperTest {

    @isTest
    public static void IOInvoiceLineItemTriggerHelperTestMethod(){
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
        Test.stopTest();
    }
}