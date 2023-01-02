public class GenerateInvoiceSch implements System.Schedulable, Database.AllowsCallouts {
    public List<Quote> quotes = new List<Quote>();
    public GenerateInvoiceSch(){
        quotes = [SELECT Id FROM Quote WHERE Invoice_Creation_Date__c = :Date.today()];
    }
    public void execute( SchedulableContext sc ){
        Set<Id> quoteIds = new Set<Id>();
        for( Quote q : quotes ){
            quoteIds.add( q.Id );
        }
        if( quoteIds.size() > 0 ){
            Database.executeBatch(new CreateInvoiceBatchCls( quoteIds ), 10);
        }
    }
}