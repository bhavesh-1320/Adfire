public class ContractTriggerHelper {
    @future(Callout=true)
    public static void createTradeDeskRecs( List<Id> ioIds ){
        //Creating Trade desk records
        //Database.executeBatch(new CreateTTDAccs( ioIds ), 10);
    }
    /*public static Boolean start = true;
    public static void changeOppStage( Set<Id> ioIds ){
        List<Opportunity> oppStages = new List<Opportunity>();
        for( Contract cont : [SELECT Id, Proposal__r.OpportunityId, Status FROM Contract WHERE Id IN :Trigger.newMap.keySet()] ){
            Opportunity opp = new Opportunity();
            System.debug(cont.Proposal__r.OpportunityId);
            if( cont.Status == 'Accepted' ){
                opp.Id = cont.Proposal__r.OpportunityId;
                opp.StageName = 'Closed Won';
                oppStages.add( opp );
            }else if( cont.Status == 'Denied' ){
                opp.Id = cont.Proposal__r.OpportunityId;
                opp.StageName = 'Closed Lost';
                oppStages.add( opp );
            }
        }
        if( oppStages.size() > 0 ){
            UPDATE oppStages;
        }
    }   
    public static void checkIncreement( Map<Id, Contract> newContractsMap, Map<Id, Contract> oldContractsMap ){
        List<Contract> contWithOpp = [SELECT Proposal__r.OpportunityId FROM Contract WHERE Id IN :newContractsMap.keySet()];
        Set<Id> oppIds = new Set<Id>();
        Map<Id, Id> proOppIdsMap = new Map<Id, Id>();
        List<Invoice_Line_Item__c> invLItems = new List<Invoice_Line_Item__c>();
        List<Invoice__c> invoices = new List<Invoice__c>();
        Map<Id, List<OpportunityLineItem>> propIdOppLItemMap = new Map<Id, List<OpportunityLineItem>>();
        for( Contract cont : contWithOpp ){
            oppIds.add( cont.Proposal__r.OpportunityId );
            proOppIdsMap.put( cont.Proposal__r.OpportunityId, cont.Id );
        }
        for( OpportunityLineItem oppLItem : [SELECT Discount, OpportunityId, UnitPrice, PricebookEntryId, Product2Id, Product2.Name, product2.Product_Id__c, Quantity, TotalPrice FROM OpportunityLineItem WHERE OpportunityId IN :oppIds] ){
            if( !propIdOppLItemMap.containsKey(proOppIdsMap.get( oppLItem.OpportunityId )) ){
                propIdOppLItemMap.put( proOppIdsMap.get( oppLItem.OpportunityId ), new List<OpportunityLineItem>() );
            }
            propIdOppLItemMap.get(proOppIdsMap.get( oppLItem.OpportunityId )).add( oppLItem );
        }
        for( Id cId : newContractsMap.keySet() ){
            if( newContractsMap.get( cId ).ContractTerm	!= oldContractsMap.get(cId).ContractTerm ){
                Contract newCont = newContractsMap.get( cId );
                Contract oldCont = oldContractsMap.get(cId);
                Integer inc = newCont.ContractTerm - oldCont.ContractTerm;
                DateTime dt = oldCont.EndDate;
                if( dt.day() == 31 || dt.day() == 30 || dt.day() == 29 || dt.day() == 28 ){
                    dt = dt.addMonths(1);    
                }
                System.debug(dt);
                System.debug(dt.year()+' '+dt.month());
                Date startDate = Date.newInstance(dt.year(), dt.month(), 1);
                System.debug(startDate);
                Date endDate = Date.newInstance(dt.year(), dt.month(), 1);
                for( Integer i = 0; i<inc; i++ ){
                    Integer numberOfDays = Date.daysInMonth(startDate.year(), startDate.month());
                    endDate = startDate.addDays(numberOfDays - startDate.day());
                    System.debug('->'+startDate);
                    Invoice__c invoice = new Invoice__c( IO__c = cId, Start_Date__c = startDate, End_Date__c = endDate );
                    startDate = endDate.addDays( 1 );
                    if( propIdOppLItemMap.containsKey( cId ) ){
                        for( OpportunityLineItem pItem : propIdOppLItemMap.get(cId) ){
                            Invoice_Line_Item__c invLItem = new Invoice_Line_Item__c();
                            invLItem.Discount__c = pItem.Discount;
                            invLItem.Invoice__r = invoice;
                            invLItem.Product__c = pItem.Product2Id;
                            invLItem.Quantity__c = pItem.Quantity;
                            invLItem.Sales_Price__c = pItem.UnitPrice;
                            invLItems.add( invLItem );
                        }    
                    }
                    invoices.add( invoice );
                }
            }
        }
        if( invoices.size() > 0 ){
            INSERT invoices;
            Set<Id> invoiceIds = new Set<Id>();
            for( Invoice__c inv : invoices ){
                invoiceIds.add( inv.Id );
            }
            if( invLItems.size() > 0 ){
                for( Invoice_Line_Item__c invLItem : invLItems ){
                    invLItem.Invoice__c = invLItem.Invoice__r.id;
                }
                INSERT invLItems;
            }
            System.debug('Creating Invoice In QB');
            Database.executeBatch(new CreateInvoiceBatchCls(invoiceIds), 10);
        }
    }
    public static void createInvoiceInQB( Map<Id, Contract> newIoMap, List<Contract> newContracts ){
        Map<Id, List<Proposal_Invoice__c>> quoteIdPInvoiceMap = new Map<Id, List<Proposal_Invoice__c>>();
        Map<Id, List<QuoteLineItem>> pInvIdPItemMap = new Map<Id, List<QuoteLineItem>>();
        Set<Id> proposalIds = new Set<Id>();
        List<Quote> proposals = [ SELECT Id, Status, Pricebook2Id, OpportunityId, Flight_Start_Date__c, Flight_End_Date__c, Opportunity.AccountId, Opportunity.Primary_Contact__c FROM Quote WHERE Id IN :proposalIds ];
        Set<Id> pInvoiceIds = new Set<Id>();
        List<Invoice__c> invoices = new List<Invoice__c>();
        List<Invoice_Line_Item__c> invLItems = new List<Invoice_Line_Item__c>();
        for( Id ioId : newIoMap.keySet() ){
            proposalIds.add( newIoMap.get(ioId).Proposal__c );
        }
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
        //Creating Orders/Invoice and Invoice Line Items
        for( Contract cont : newContracts ){
            if( quoteIdPInvoiceMap.containsKey( cont.proposal__c ) ){
                List<Proposal_Invoice__c> proInvs = quoteIdPInvoiceMap.get( cont.proposal__c );
                for( Proposal_Invoice__c proInv : proInvs ){
                    Invoice__c invoice = new Invoice__c( IO__c = cont.Id, Start_Date__c = proInv.Start_Date__c, End_Date__c = proInv.End_Date__c );   
                    if( pInvIdPItemMap.containsKey(proInv.Id) ){
                        for( QuoteLineItem pItem : pInvIdPItemMap.get(proInv.Id) ){
                            Invoice_Line_Item__c invLItem = new Invoice_Line_Item__c();
                            invLItem.Discount__c = pItem.Discount;
                            invLItem.Ad_Sizes__c = pItem.Ad_Sizes__c;
                            invLItem.Counts__c = pItem.Quantity;
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
            }    
        }    
        if( invoices.size() > 0 ){ 
            INSERT invoices;
            Set<Id> invoiceIds = new Set<Id>();
            for( Invoice__c inv : invoices ){
                invoiceIds.add( inv.Id );
            }
            if( invLItems.size() > 0 ){
                for( Invoice_Line_Item__c invLItem : invLItems ){
                    invLItem.Invoice__c = invLItem.Invoice__r.Id;
                }
                INSERT invLItems;
            }
            System.debug('Creating Invoice In QB');
            Database.executeBatch(new CreateInvoiceBatchCls(invoiceIds), 10);
        }
    }
    public static void createBillContacts( List<Contract> newContracts ){
        Set<Id> proposalIds = new Set<Id>(); 
        for( Contract cont : newContracts ){
            proposalIds.add( cont.Proposal__c );
        }
        List<Proposal_IO_Billing_Contact__c> billContacts = [SELECT Proposal__c, RecordTypeId, Contact__c, IO__c, Role__c FROM Proposal_IO_Billing_Contact__c WHERE Proposal__c IN :proposalIds];
        List<Proposal_IO_Billing_Contact__c> newBillContacts = new List<Proposal_IO_Billing_Contact__c>();
        Map<Id, List<Proposal_IO_Billing_Contact__c>> pIdBillMap = new Map<Id, List<Proposal_IO_Billing_Contact__c>>();
        for( Proposal_IO_Billing_Contact__c bCont : billContacts ){
            if( !pIdBillMap.containsKey( bCont.Proposal__c ) )
            	pIdBillMap.put( bCont.Proposal__c, new List<Proposal_IO_Billing_Contact__c>() );
            pIdBillMap.get( bCont.Proposal__c ).add( bCont );
        }
        Id ioRecTypeId = Schema.SObjectType.Proposal_IO_Billing_Contact__c.getRecordTypeInfosByName().get('IO').getRecordTypeId();
        for( Contract cont : newContracts ){
            if( pIdBillMap.containsKey( cont.Proposal__c ) ){
                List<Proposal_IO_Billing_Contact__c> pBillConts = pIdBillMap.get( cont.Proposal__c );
                for( Proposal_IO_Billing_Contact__c pBillCont : pBillConts ){
                    pBillCont.Proposal__c = null;
                    pBillCont.IO__c = cont.Id;
                    pBillCont.RecordTypeId = ioRecTypeId;
                    pBillCont.Id = null;
                    newBillContacts.add( pBillCont );
                }
            }
        }
        if( newBillContacts.size() > 0 ){
            INSERT newBillContacts;
        }
    }*/
    
    public static void updateIOInvoicesPONumber(Set<Id> ivIds){
        List<Contract> ioList = [Select PO_Number__c, LastModifiedDate, (Select PO_Number__c, End_Date__c from Contract_Invoices__r) FROM Contract Where Id IN :ivIds];
        List<Invoice__c> invList = new List<Invoice__c>();
        for(Contract io : ioList){
            for(Invoice__c inv : io.Contract_Invoices__r){
                if(inv.End_Date__c > io.LastModifiedDate ){
                    inv.PO_Number__c = io.PO_Number__c;
                    invList.add(inv);
                }
            }
        }
        update invList;
    }
}