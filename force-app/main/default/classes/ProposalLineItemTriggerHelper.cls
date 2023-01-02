public class ProposalLineItemTriggerHelper {
    public static void addTotalPrice( List<QuoteLineItem> lItems ){
        Set<Id> pInvoiceIds = new Set<Id>();
        for( QuoteLineItem qLItem : lItems ){
            pInvoiceIds.add( qLItem.Proposal_Invoice__c );
        }
        List<Proposal_Invoice__c> pInvoices = [ SELECT Total_Price__c, (SELECT TotalPrice FROM Proposal_Line_Items__r) FROM Proposal_Invoice__c WHERE Id IN :pInvoiceIds ];
        for( Proposal_Invoice__c pInvoice : pInvoices ){
            if( pInvoice.Proposal_Line_Items__r.size() > 0 ){
                Decimal tPrice = 0;
                for( QuoteLineItem pLItem : pInvoice.Proposal_Line_Items__r ){
                    tPrice += pLItem.TotalPrice;
                }
                pInvoice.Total_Price__c = tPrice;
            }
        }
        if( pInvoices.size() > 0 ){
            UPDATE pInvoices;
        }
    }
}