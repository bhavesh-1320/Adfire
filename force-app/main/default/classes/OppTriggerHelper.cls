public class OppTriggerHelper {
    public static void createIos( List<Opportunity> opps, Set<Id> oppIds ){
        Map<Id, List<OpportunityLineItem>> oppProdsMap = new Map<Id, List<OpportunityLineItem>>();
        List<Contract> contracts = new List<Contract>();
        List<Invoice_Line_Item__c> invLItems = new List<Invoice_Line_Item__c>();
        List<Invoice__c> invoices = new List<Invoice__c>();
        List<Opportunity_Segment__c> oppSegs = new List<Opportunity_Segment__c>(); 
        boolean first = false;
        for( Opportunity oppProd : [SELECT Id, Pricebook2Id, AccountId, 
                                    Flight_Start_Date__c, Flight_End_Date__c, 
                                    ( SELECT Discount, Ad_Sizes__c, OpportunityId, 
                                     ListPrice, Monthly_Frequency__c, UnitPrice, PricebookEntryId, 
                                     Product2Id, Product2.Name, product2.Product_Id__c, 
                                     Quantity, TotalPrice FROM OpportunityLineItems ),
                                    ( SELECT Segment__c, Opportunity__c, IO_Invoice__c FROM Opportunity_Segments__r ) FROM Opportunity WHERE Id IN :oppIds ] ){
            oppProdsMap.put( oppProd.Id, oppProd.OpportunityLineItems );
            List<OpportunityLineItem> opplItems = oppProd.OpportunityLineItems;
            List<Opportunity_Segment__c> oppSegments = oppProd.Opportunity_Segments__r;
            Date startDate = oppProd.Flight_Start_Date__c;
            Date endDate = oppProd.Flight_End_Date__c;
            Integer contractTerm = startDate.monthsBetween(endDate);
            Contract invoice = new Contract( Pricebook2Id = oppProd.Pricebook2Id, StartDate = startDate, ContractTerm = contractTerm, AccountId = oppProd.AccountId, Opportunity__c = oppProd.Id );
            contracts.add( invoice );
            for( Integer i = 0; i<contractTerm; i++ ){
                Integer numberOfDays = Date.daysInMonth(startDate.year(), startDate.month());
                endDate = startDate.addDays(numberOfDays - startDate.day());
                Invoice__c inv = new Invoice__c( IO__r = invoice, Start_Date__c = startDate, End_Date__c = endDate );		
                invoices.add( inv );
                startDate = endDate.addDays( 1 );
                if( opplItems != null && !first ){
                    for( OpportunityLineItem pItem : opplItems ){
                        Invoice_Line_Item__c invLItem = new Invoice_Line_Item__c();
                        invLItem.Discount__c = pItem.Discount;
                        invLItem.Invoice__r = inv;
                        invLItem.Counts__c = pItem.Quantity;
                        invLItem.Monthly_Frequency__c = pItem.Monthly_Frequency__c;
                        invLItem.CPM__c = pItem.ListPrice;
                        invLItem.Ad_Sizes__c = pItem.Ad_Sizes__c;
                        invLItem.Product__c = pItem.Product2Id;
                        invLItem.Sales_Price__c = pItem.UnitPrice;
                        invLItems.add( invLItem );
                    }   
                    first = true;
                }
                /*if( oppSegments != null ){
                    System.debug('->'+inv);
                    for( Opportunity_Segment__c oppSeg : oppSegments ){
                        System.debug('!!::'+inv);
                        Opportunity_Segment__c oS = new Opportunity_Segment__c( IO_Invoice__r = inv, Segment__c = oppSeg.Segment__c );
                        oppSegs.add( oS );
                    }
                }*/
            }
        }
        if( contracts.size() > 0 ){
            INSERT contracts;
            //Creating Trade desk records
            List<Id> ioIds = new List<Id>();
            for( contract cont : contracts ){
                ioIds.add( cont.id );
            }
            //Database.executeBatch(new CreateTTDAccs( ioIds ), 10);
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
                /*System.debug('ONVS:'+invoices);
                if( oppSegs.size() > 0 ){
                    for( Opportunity_Segment__c oppSe : oppSegs ){
                        System.debug('----'+oppSe.IO_Invoice__r);
                        oppSe.IO_Invoice__c = oppSe.IO_Invoice__r.Id;
                    }
                    System.debug(oppSegs);
                    INSERT oppSegs;
                }*/
            }
            
        }
    }
}