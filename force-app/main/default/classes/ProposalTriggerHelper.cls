public class ProposalTriggerHelper {
    public static void createProposalInvoices( List<Quote> proposals ){
        Set<Id> oppIds = new Set<Id>();
        List<Opportunity> oppStageChange = new List<Opportunity>();
        List<Proposal_Invoice__c> invoices = new List<Proposal_Invoice__c>();
        List<QuoteLineItem> invLItems = new List<QuoteLineItem>();
        for( Quote proposal : proposals ){
            oppIds.add( proposal.OpportunityId );
        }
        Map<Id, List<OpportunityLineItem>> oppLItemMap = new Map<Id, List<OpportunityLineItem>>();
        for( OpportunityLineItem oppLItem : [SELECT Discount, Ad_Sizes__c, OpportunityId, ListPrice, Monthly_Frequency__c, UnitPrice, PricebookEntryId, Product2Id, Product2.Name, product2.Product_Id__c, Quantity, TotalPrice FROM OpportunityLineItem WHERE OpportunityId IN :oppIds] ){
            if( !oppLItemMap.containsKey(oppLItem.OpportunityId) ){
                oppLItemMap.put( oppLItem.OpportunityId, new List<OpportunityLineItem>() );
            }
            oppLItemMap.get(oppLItem.OpportunityId).add( oppLItem );
        }
        for( Quote proposal : proposals ){
            //Change opp stage
            Opportunity opp = new Opportunity( Id = proposal.OpportunityId, StageName='Proposal' );
            oppStageChange.add( opp );
            
            //Create IO
            DateTime dt = proposal.Flight_Start_Date__c;
            Date startDate = Date.newInstance(dt.year(), dt.month(), dt.day());
            dt = proposal.Flight_End_Date__c;
            Date endDate = Date.newInstance(dt.year(), dt.month(), dt.day());
            Integer contractTerm = startDate.monthsBetween(endDate);
            
            List<OpportunityLineItem> opplItems = oppLItemMap.get( proposal.OpportunityId );
            
            for( integer i = 0; i<contractTerm; i++ ){
                Integer numberOfDays = Date.daysInMonth(startDate.year(), startDate.month());
                endDate = startDate.addDays(numberOfDays - startDate.day());
                Proposal_Invoice__c invoice = new Proposal_Invoice__c( Proposal__c = proposal.Id, Start_Date__c = startDate, End_Date__c = endDate );
                startDate = endDate.addDays( 1 );
                
                if( opplItems != null ){
                    for( OpportunityLineItem pItem : opplItems ){
                        QuoteLineItem invLItem = new QuoteLineItem();
                        invLItem.Discount = pItem.Discount;
                        invLItem.Proposal_Invoice__r = invoice;
                        invLItem.Quantity = pItem.Quantity;
                        invLItem.Monthly_Frequency__c = pItem.Monthly_Frequency__c;
                        invLItem.CPM__c = pItem.ListPrice;
                        invLItem.Ad_Sizes__c = pItem.Ad_Sizes__c;
                        invLItem.Product2Id = pItem.Product2Id;
                        //invLItem.Quantity = pItem.Quantity;
                        invLItem.UnitPrice = pItem.UnitPrice;
                        invLItem.QuoteId = proposal.Id;
                        invLItem.PricebookEntryId = pItem.PricebookEntryId;
                        invLItems.add( invLItem );
                    }   
                }
                invoices.add( invoice );
            }
        }
        if( oppStageChange.size() > 0 ){
            UPDATE oppStageChange;
        }
        
        if( invoices.size() > 0 ){
            INSERT invoices;
            if( invLItems.size() > 0 ){
                for( QuoteLineItem invLItem : invLItems ){
                    invLItem.Proposal_Invoice__c = invLItem.Proposal_Invoice__r.Id;
                }
                INSERT invLItems;
            }
        }
        
    }
    static void createInovices( String lineItemPObj, List<sObject> proposals, String lItemCopy ){
        /*Set<Id> proposalIds = new Set<Id>();
List<sObject> contracts = new List<sObject>();
List<sObject> invoices = new List<sObject>();
List<sObject> invLItems = new List<sObject>();
//Creating map of Proposal Id and Line items
for( Quote proposal : proposals ){
proposalIds.add( proposal.OpportunityId );
}
Map<Id, List<sObject>> quoteIdLItemMap = new Map<Id, List<sObject>>();
proposals = Database.query('[ SELECT Id, Status, Pricebook2Id, OpportunityId, Flight_Start_Date__c, Flight_End_Date__c, Opportunity.AccountId, Opportunity.Primary_Contact__c FROM Quote WHERE Id IN :proposalIds ]');
for( QuoteLineItem qLItem : [SELECT Discount, QuoteId, UnitPrice, PricebookEntryId, Product2Id, Product2.Name, product2.Product_Id__c, Quantity, TotalPrice FROM QuoteLineItem WHERE QuoteId IN :proposalIds] ){
if( !quoteIdLItemMap.containsKey(qLItem.QuoteId) ){
quoteIdLItemMap.put( qLItem.QuoteId, new List<QuoteLineItem>() );
}
quoteIdLItemMap.get(qLItem.QuoteId).add( qLItem );
}

for( Quote proposal : proposals ){
if( proposal.Status == 'Accepted' ){
//Change opp stage
Opportunity opp = new Opportunity( Id = proposal.OpportunityId, StageName='Closed Won' );
oppStageChange.add( opp );

//Create IO
DateTime dt = proposal.Flight_Start_Date__c;
Date startDate = Date.newInstance(dt.year(), dt.month(), dt.day());
dt = proposal.Flight_End_Date__c;
Date endDate = Date.newInstance(dt.year(), dt.month(), dt.day());
Integer contractTerm = startDate.monthsBetween(endDate);
Contract cont = new Contract( AccountId = proposal.Opportunity.AccountId, StartDate = startDate, ContractTerm = contractTerm, CustomerSignedId = proposal.Opportunity.Primary_Contact__c, Proposal__c = proposal.Id ); 
contracts.add( cont );

//Creating Orders/Invoice and Invoice Line Items
List<QuoteLineItem> proposalItems = quoteIdLItemMap.get( proposal.Id );
for( integer i = 0; i<contractTerm; i++ ){
Invoice__c invoice = new Invoice__c( IO__r = cont, Start_Date__c = startDate );
startDate = startDate.addMonths( 1 );
invoice.End_Date__c = startDate.addDays(-1);   
for( QuoteLineItem pItem : proposalItems ){
Invoice_Line_Item__c invLItem = new Invoice_Line_Item__c();
invLItem.Discount__c = pItem.Discount;
invLItem.Invoice__r = invoice;
invLItem.Product__c = pItem.Product2Id;
invLItem.Quantity__c = pItem.Quantity;
invLItem.Sales_Price__c = pItem.UnitPrice;
invLItem.Total_Price__c = pItem.TotalPrice;
invLItems.add( invLItem );
}
invoices.add( invoice );
}
}
}
if( oppStageChange.size() > 0 ){
UPDATE oppStageChange;
}
if( contracts.size() > 0 ){
INSERT contracts;
if( invoices.size() > 0 ){
for( Invoice__c invoice : invoices ){
invoice.IO__c = invoice.IO__r.Id;
}
INSERT invoices;
if( invLItems.size() > 0 ){
for( Invoice_Line_Item__c invLItem : invLItems ){
invLItem.Invoice__c = invLItem.Invoice__r.Id;
}
INSERT invLItems;
}
}
}*/
    }
    public static void createIO( List<Quote> proposals, Map<Id, Quote> proposalMap ){
        List<Opportunity> oppStageChange = new List<Opportunity>();
        Set<Id> proposalIds = new Set<Id>();
        Set<Id> pInvoiceIds = new Set<Id>();
        List<Contract> contracts = new List<Contract>();
        List<Invoice__c> invoices = new List<Invoice__c>();
        List<Invoice_Line_Item__c> invLItems = new List<Invoice_Line_Item__c>();
        //Creating map of Proposal Id and Line items
        for( Quote proposal : proposals ){
            if( proposal.Status == 'Accepted' && proposalMap.get( proposal.Id ).Status != 'Accepted' ){
                proposalIds.add( proposal.Id );
                Opportunity opp = new Opportunity( Id = proposal.OpportunityId, StageName='IO Initiated' );
                oppStageChange.add( opp );
            }else if( proposal.Status == 'Denied' && proposalMap.get( proposal.Id ).Status != 'Denied' ){
                Opportunity opp = new Opportunity( Id = proposal.OpportunityId, StageName='Closed Lost' );
                oppStageChange.add( opp );
            }
        }
        Map<Id, List<QuoteLineItem>> quoteIdLItemMap = new Map<Id, List<QuoteLineItem>>();
        Map<Id, List<Proposal_Invoice__c>> quoteIdPInvoiceMap = new Map<Id, List<Proposal_Invoice__c>>();
        Map<Id, List<QuoteLineItem>> pInvIdPItemMap = new Map<Id, List<QuoteLineItem>>();
        
        proposals = [ SELECT Id, Status, Pricebook2Id, OpportunityId, Flight_Start_Date__c, Flight_End_Date__c, Opportunity.AccountId, Opportunity.Primary_Contact__c FROM Quote WHERE Id IN :proposalIds ];
        
        for( Proposal_Invoice__c pInvoice : [SELECT Start_Date__c, Proposal__c, End_Date__c FROM Proposal_Invoice__c WHERE Proposal__c IN :proposalIds] ){
            if( !quoteIdPInvoiceMap.containsKey(pInvoice.Proposal__c) ){
                quoteIdPInvoiceMap.put( pInvoice.Proposal__c, new List<Proposal_Invoice__c>() );
            }
            pInvoiceIds.add( pInvoice.Id );
            quoteIdPInvoiceMap.get(pInvoice.Proposal__c).add( pInvoice );
        }
        for( QuoteLineItem qLItem : [SELECT Discount, CPM__c, Monthly_Frequency__c, Ad_Sizes__c, Proposal_Invoice__c, QuoteId, UnitPrice, PricebookEntryId, Product2Id, Product2.Name, product2.Product_Id__c, Quantity, TotalPrice FROM QuoteLineItem WHERE Proposal_Invoice__c IN :pInvoiceIds] ){
            if( !pInvIdPItemMap.containsKey(qLItem.Proposal_Invoice__c) ){
                pInvIdPItemMap.put( qLItem.Proposal_Invoice__c, new List<QuoteLineItem>() );
            }
            pInvIdPItemMap.get(qLItem.Proposal_Invoice__c).add( qLItem );
        }
        for( Quote proposal : proposals ){
            if( proposal.Status == 'Accepted' && proposalMap.get( proposal.Id ).Status != 'Accepted' ){
                
                //Create IO
                DateTime dt = proposal.Flight_Start_Date__c;
                Date startDate = Date.newInstance(dt.year(), dt.month(), dt.day());
                dt = proposal.Flight_End_Date__c;
                Date endDate = Date.newInstance(dt.year(), dt.month(), dt.day());
                Integer contractTerm = startDate.monthsBetween(endDate);
                Contract cont = new Contract( AccountId = proposal.Opportunity.AccountId, Opportunity__c = proposal.OpportunityId, StartDate = startDate, ContractTerm = contractTerm, CustomerSignedId = proposal.Opportunity.Primary_Contact__c, Proposal__c = proposal.Id ); 
                contracts.add( cont );
                
                //Creating Orders/Invoice and Invoice Line Items
                /*if( quoteIdPInvoiceMap.containsKey( proposal.Id ) ){
                    List<Proposal_Invoice__c> proInvs = quoteIdPInvoiceMap.get( proposal.Id );
                    for( Proposal_Invoice__c proInv : proInvs ){
                        Invoice__c invoice = new Invoice__c( IO__r = cont, Start_Date__c = proInv.Start_Date__c, End_Date__c = proInv.End_Date__c );   
                        if( pInvIdPItemMap.containsKey(proInv.Id) ){
                            for( QuoteLineItem pItem : pInvIdPItemMap.get(proInv.Id) ){
                                Invoice_Line_Item__c invLItem = new Invoice_Line_Item__c();
                                invLItem.Discount__c = pItem.Discount;
                                invLItem.Ad_Sizes__c = pItem.Ad_Sizes__c;
                                invLItem.Counts__c = pItem.Counts__c;
                                invLItem.CPM__c = pItem.CPM__c;
                                invLItem.Monthly_Frequency__c = pItem.Monthly_Frequency__c;
                                invLItem.Invoice__r = invoice;
                                invLItem.Product__c = pItem.Product2Id;
                                invLItem.Quantity__c = pItem.Quantity;
                                invLItem.Sales_Price__c = pItem.UnitPrice;
                                invLItems.add( invLItem );
                            }    
                        }
                        invoices.add( invoice );       
                    }    
                }*/
            }
        }
        if( oppStageChange.size() > 0 ){
            UPDATE oppStageChange;
        }
        if( contracts.size() > 0 ){
            INSERT contracts;
            /*if( invoices.size() > 0 ){
                for( Invoice__c invoice : invoices ){
                    invoice.IO__c = invoice.IO__r.Id;
                }
                INSERT invoices;
                if( invLItems.size() > 0 ){
                    for( Invoice_Line_Item__c invLItem : invLItems ){
                        invLItem.Invoice__c = invLItem.Invoice__r.Id;
                    }
                    INSERT invLItems;
                }
            }*/
        }
    }
}