public class IOInvoiceLineItemTriggerHelper {
    public static boolean start = false;
    public static void createInvoiceINQB( List<Invoice_Line_Item__c> newIoInvoices ){
        
    }
    public static void createSegments( Map<Id,Invoice_Line_Item__c> invsMap ){
        system.debug('invsMap===>'+invsMap);
        Set<Id> oppIds = new Set<ID>();
        List<Invoice_Line_Item__c> invs = [SELECT Invoice__r.IO__r.Opportunity__c FROM Invoice_Line_Item__c WHERE Id IN :invsMap.keySet()];
        system.debug('invs===>'+invs);
        for( Invoice_Line_Item__c inv : invs ){
            oppIds.add( inv.Invoice__r.IO__r.Opportunity__c );
        }
        system.debug('oppIds===>'+oppIds);
        Map<Id, List<Opportunity_Segment__c> > oppIdSegMap = new Map<Id, List<Opportunity_Segment__c> >();
        for( Opportunity opp : [SELECT Id, ( SELECT Segment__c, Opportunity__c, IO_Invoice__c FROM Opportunity_Segments__r ) 
                                FROM Opportunity WHERE ID IN :oppIds] ){
                                    oppIdSegMap.put( opp.Id, opp.Opportunity_Segments__r );
                                }
        system.debug('oppIdSegMap===>'+oppIdSegMap);
        List<Opportunity_Segment__c> newSegs = new List<Opportunity_Segment__c>();
        for( Invoice_Line_Item__c inv : invs ){
            if( oppIdSegMap.containsKey( inv.Invoice__r.IO__r.Opportunity__c ) ){
                for( Opportunity_Segment__c oppSeg : oppIdSegMap.get(inv.Invoice__r.IO__r.Opportunity__c) ){
                    Opportunity_Segment__c opS = new Opportunity_Segment__c( Segment__c=oppSeg.Segment__c, IO_Invoice_Line_Item__c = inv.Id );
                    newSegs.add( opS );
                } 	   
            }
        }
        if( newSegs.size() > 0 ){
            INSERT newSegs;
        }
    }
    public static void createLineItemInNextInv( Map<Id,Invoice_Line_Item__c> invsMap ){
        List<Invoice_Line_Item__c> newIoInvoices = [SELECT Id, Sales_Price__c, Product__c, Invoice__c,
                                                    Counts__c, CPM__c, Impression__c, 
                                                    Monthly_Frequency__c  
                                                    FROM Invoice_Line_Item__c 
                                                    WHERE Id IN :invsMap.keySet()
                                                   ];
        Map<Id, List<Invoice_Line_Item__c>> invIdLItemMap = new Map<Id, List<Invoice_Line_Item__c>>();
        Map<Id, List<Id>> ioIdInvIdsMap = new Map<Id, List<Id>>();
        Map<Id, List<Id>> invIdNextInvIdMap = new Map<Id, List<Id>>();
        Set<Id> invIds = new Set<Id>();
        Set<Id> ioIds = new Set<Id>();
        for( Invoice_Line_Item__c ioInv : newIoInvoices ){
            invIds.add( ioInv.Invoice__c );
            if( !invIdLItemMap.containsKey(ioInv.Invoice__c) ){
                invIdLItemMap.put( ioInv.Invoice__c, new List<Invoice_Line_Item__c>() );
            }
            invIdLItemMap.get( ioInv.Invoice__c ).add( ioInv );
        }
        for( Invoice__c inv : [SELECT Id, IO__c FROM Invoice__c WHERE Id IN :invIds] ){
            ioIds.add( inv.IO__c );
        }
        for( Contract cont : [SELECT Id, (SELECT Id FROM Contract_Invoices__r) FROM Contract WHERE Id IN :ioIds] ){
            ioIdInvIdsMap.put( cont.Id, new List<Id>() );
            for( Invoice__c inv : cont.Contract_Invoices__r ){
            	ioIdInvIdsMap.get( cont.Id ).add( inv.Id );    
            }
        }
        for( Id ioId : ioIdInvIdsMap.keySet() ){
            boolean found = false;
            for( Id invId : ioIdInvIdsMap.get( ioId ) ){
                if( invIdLItemMap.containsKey( invId ) ){
                    invIdNextInvIdMap.put( invId, new List<Id>() );
                    fillNextInvIds( ioIdInvIdsMap.get( ioId ), invIdNextInvIdMap, invId );
                }
            }
        }
        system.debug('invIdNextInvIdMap==>'+invIdNextInvIdMap);
        List<Invoice_Line_Item__c> newInvLItems = new List<Invoice_Line_Item__c>();
        for( Id invId : invIdLItemMap.keySet() ){
            for( Invoice_Line_Item__c invLItem : invIdLItemMap.get( invId ) ){
                for( Id nextInvId : invIdNextInvIdMap.get( invId ) ){
                    System.debug('==>>'+nextInvId);
                    Invoice_Line_Item__c newInvLItem = new Invoice_Line_Item__c( Invoice__c = nextInvId, 
                                                                                Sales_Price__c = invLItem.Sales_Price__c, 
                                                                                Product__c = invLItem.Product__c, 
                                                                                Counts__c = invLItem.Counts__c,
                                                                                CPM__c = invLItem.CPM__c, 
                                                                                Monthly_Frequency__c = invLItem.Monthly_Frequency__c
                                                                               );
                    newInvLItems.add( newInvLItem );
                }
            }
        }
        sYSTEM.debug('---------');
        System.debug(newInvLItems);
        System.debug(invIdNextInvIdMap);
        System.debug(ioIdInvIdsMap);
        System.debug(invIdLItemMap);
        if( newInvLItems.size() > 0 && start == false ){
            start = true;
            INSERT newInvLItems;
        }
    }
    static void fillNextInvIds( List<Id> invIds, Map<Id, List<Id>> invIdNextInvIdMap, Id invId ){
        for( Id invId1 : invIds ){
            if( invId1 > invId ){
                invIdNextInvIdMap.get( invId ).add( invId1 );
            }
        }
    }
}