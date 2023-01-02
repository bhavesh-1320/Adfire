public with sharing class ProposalIOInvoiceCls {
    
    @AuraEnabled
    public static List<Proposal_Invoice__c> getQuoteInvoice( Id quoteId ){
        System.debug('quoteId'+quoteId);
        try {
            return [SELECT Id, End_Date__c, Start_Date__c, Proposal__r.Opportunity.Segment_Name__c, Proposal__r.Flight__c, Proposal__r.Campaign_Name__c, Client_Campaign_Name__c,
                    ( SELECT UnitPrice, Product2.name, Quantity, 
                    CPM__c, Impression__c, Monthly_Frequency__c, PricebookEntryId,
                    Proposal_Invoice__c FROM Proposal_Line_Items__r )
                    FROM Proposal_Invoice__c WHERE 
                    Proposal__c = :quoteId 
                   ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static List<Opportunity_Segment__c> getOppSegments( Id quoteId, String objName ){
        if( objName == 'Contract' ){
            Contract q = [SELECT Opportunity__c FROM Contract WHERE Id = :quoteId];
            return  [SELECT Segment__r.Name, Segment__c, Start_Date__c, End_Date__c FROM Opportunity_Segment__c WHERE 
                     Opportunity__c = :q.Opportunity__c 
                    ];    
        }
        Quote q = [SELECT OpportunityId FROM Quote WHERE Id = :quoteId];
        return [ SELECT Segment__r.Name FROM Opportunity_Segment__c WHERE Opportunity__c = :q.OpportunityId ];
    }
    @AuraEnabled
    public static Map<String, Map<String, List<sObject> >> getContractInvoice( Id contractId ){
        try {
            Map<String, Map<String, List<sObject> >> allRecordMap = new Map<String, Map<String, List<sObject> >>();
            Map<String, List<sObject>> invRecMap = new Map<String, List<sObject>>();
            invRecMap.put( 'Invoices', [ SELECT Id, IO__r.Opportunity__r.Segment_Name__c, End_Date__c, Start_Date__c, Proposal__c, IO__r.Flight__c, IO__r.Campaign_Name__c,
                Client_Campaign_Name__c,
                ( SELECT Sales_Price__c, Data_Source__c, Product__r.name, Invoice__c,
                Counts__c, CPM__c, Impression__c, Monthly_Frequency__c, Trade_Desk_Campaign__c
                FROM Invoice_Line_Items__r ),
                ( SELECT Segment__r.Name 
                FROM Opportunity_Segments__r )
                FROM Invoice__c WHERE 
                IO__c = :contractId 
                ORDER BY End_Date__c
            ] );
            Set<Id> ioLItemIds = new Set<Id>();
            Set<Id> invIds = new Set<Id>();
            system.debug(contractId);
            for( Invoice__c inv : [SELECT Id FROM Invoice__c WHERE IO__c = :contractId ] ){
                system.debug(contractId);
                invIds.add( inv.Id );
            }
            for( Invoice_Line_Item__c invL : [SELECT Id FROM Invoice_Line_Item__c WHERE Invoice__c IN :invIds]  ){
                ioLItemIds.add( invL.Id );
            }
            Map<String, List<sObject>> ioSegmentsMap = new Map<String, List<sObject>>();
            for( Opportunity_Segment__c oppSeg :[SELECT Id, Segment__r.Name, IO_Invoice_Line_Item__c FROM Opportunity_Segment__c 
                                                 WHERE IO_Invoice_Line_Item__c IN :ioLItemIds
                                                ] ){
                                                    if( !ioSegmentsMap.containsKey( oppSeg.IO_Invoice_Line_Item__c ) ){
                                                        ioSegmentsMap.put( oppSeg.IO_Invoice_Line_Item__c, new List<sObject>() );
                                                    }
                                                    ioSegmentsMap.get(oppSeg.IO_Invoice_Line_Item__c).add( oppSeg );
            }
            allRecordMap.put( 'Invoice Recs', invRecMap );
            allRecordMap.put( 'Segments', ioSegmentsMap );
            return allRecordMap;
            /* return [ SELECT Id, IO__r.Opportunity__r.Segment_Name__c, End_Date__c, Start_Date__c, Proposal__c, IO__r.Flight__c, IO__r.Campaign_Name__c,
                     Client_Campaign_Name__c,
                     ( SELECT Sales_Price__c, Product__r.name, Invoice__c,
                     Counts__c, CPM__c, Impression__c, Monthly_Frequency__c 
                     FROM Invoice_Line_Items__r ),
                     ( SELECT Segment__r.Name 
                     FROM Opportunity_Segments__r )
                     FROM Invoice__c WHERE 
                     IO__c = :contractId 
                     ORDER BY End_Date__c
                    ]; */
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static String saveInvoice( List<Proposal_Invoice__c> invRecs, List<QuoteLineItem> lItemRecs, List<Id> delRecsIds ){
        System.debug( invRecs );
        System.debug(  lItemRecs );
        Map<Id, Proposal_Invoice__c> idPInvoiceMap = new Map<Id, Proposal_Invoice__c>();
        Map<String, Proposal_Invoice__c> newIdPInvoiceMap = new Map< String, Proposal_Invoice__c >(); 
        for( Proposal_Invoice__c pInvoice : invRecs ){
            try{
                idPInvoiceMap.put( pInvoice.Id, pInvoice );
            }catch( Exception e ){
                String i = String.valueOf(pInvoice.Id);
                newIdPInvoiceMap.put( i, pInvoice );
                pInvoice.Id = null;
            }
        }
        System.debug( newIdPInvoiceMap );
        for( QuoteLineItem lItem : lItemRecs ){
            if( newIdPInvoiceMap.containsKey( String.valueOf(lItem.Proposal_Invoice__c) ) ){
                lItem.Proposal_Invoice__r = newIdPInvoiceMap.get( String.valueOf(lItem.Proposal_Invoice__c) );
                lItem.Proposal_Invoice__c = null;
            } 
        }
        if( invRecs.size() > 0 ){
            UPSERT invRecs;
        }
        if( lItemRecs.size() > 0 ){
            for( QuoteLineItem lItem : lItemRecs ){
                if( lItem.Proposal_Invoice__c == null ){
                    lItem.Proposal_Invoice__c = lItem.Proposal_Invoice__r.Id;
                }
            }
            UPSERT lItemRecs;
        }
        
        if( delRecsIds.size() > 0 ){
            DELETE [SELECT Id FROM QuoteLineItem WHERE Id IN :delRecsIds];
        }
        return 'Success';
    }
    @AuraEnabled
    public static Map<String, Id> saveIOInvoice(List<Invoice__c> invRecs, List<Invoice_Line_Item__c> lItemRecs, List<Id> delRecsIds, List<Opportunity_Segment__c> newSegs, List<String> nProdSeg ){
        System.debug( ';;'+nProdSeg );
        try{
            //List<Opportunity_Segment__c> nSegments = (List<Opportunity_Segment__c>) System.JSON.deserialize(newSegs, List<Opportunity_Segment__c>.Class);
            Map<Id, Invoice__c> idPInvoiceMap = new Map<Id, Invoice__c>();
            Map<String, Invoice__c> newIdPInvoiceMap = new Map< String, Invoice__c >();
            Map<String, Invoice_Line_Item__c> lItemIdMap = new Map<String, Invoice_Line_Item__c>();
            Map<String, Id> lItemIdMap2 = new Map<String, Id>();
            System.debug(newSegs);

            for( Invoice__c pInvoice : invRecs ){
                try{
                    idPInvoiceMap.put( pInvoice.Id, pInvoice );
                }catch( Exception e ){
                    String i = String.valueOf(pInvoice.Id);
                    newIdPInvoiceMap.put( i, pInvoice );
                    pInvoice.Id = null;
                }
            }
            System.debug( newIdPInvoiceMap );
            for( Invoice_Line_Item__c lItem : lItemRecs ){
                String lItemId = lItem.Id+'';
                System.debug(lItemId);
                if( lItemId.length() < 10 ){
                    lItemIdMap.put( lItemId, lItem );
                    lItem.Id = null;
                }
                if( newIdPInvoiceMap.containsKey( String.valueOf(lItem.Invoice__c) ) ){
                    lItem.Invoice__r = newIdPInvoiceMap.get( String.valueOf(lItem.Invoice__c) );
                    System.debug( '--------' );
                    System.debug( lItem.Invoice__c );
                    System.debug( lItem.Id );
                    lItem.Invoice__c = null;
                } 
            }
            for( Opportunity_Segment__c lItem : newSegs ){
                if( newIdPInvoiceMap.containsKey( String.valueOf(lItem.IO_Invoice__c) ) ){
                    lItem.IO_Invoice__r = newIdPInvoiceMap.get( String.valueOf(lItem.IO_Invoice__c) );
                    lItem.IO_Invoice__c = null;
                } 
            }
            if( invRecs.size() > 0 ){
                UPSERT invRecs;
            }
            if( lItemRecs.size() > 0 ){
                for( Invoice_Line_Item__c lItem : lItemRecs ){
                    if( lItem.Invoice__c == null ){
                        lItem.Invoice__c = lItem.Invoice__r.Id;
                    }
                }
                UPSERT lItemRecs;
                for( String i : lItemIdMap.keySet() ){
                    Invoice_Line_Item__c invL = lItemIdMap.get( i );
                    lItemIdMap2.put( i, invL.Id );
                }
            } 
            if( newSegs.size() > 0 ){
                for( Opportunity_Segment__c lItem : newSegs ){
                    if( lItem.IO_Invoice__c == null ){
                        lItem.IO_Invoice__c = lItem.IO_Invoice__r.Id;
                    }
                }
                System.debug(newSegs);
                UPSERT newSegs;
            } 
            if( delRecsIds.size() > 0 ){
                DELETE [SELECT Id FROM Invoice_Line_Item__c WHERE Id IN :delRecsIds];
            }
            return lItemIdMap2;
        }catch( AuraHandledException e ){
            System.debug( e.getMessage() );
            throw new AuraHandledException(e.getMessage());
        }
        
        /* try {
            if( invRecs.size() > 0 ){
                UPSERT invRecs;
            }
            if( lItemRecs.size() > 0 ){
                UPSERT lItemRecs;
            }
            return 'Success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        } */
    }
    @AuraEnabled
    public static List<Product2> getProducts( Id quoteId, String objName ){
        try {
            if( objName == 'Quote' ){
                Quote cont = [ SELECT Opportunity.Pricebook2Id FROM Quote WHERE Id = :quoteId ];
                if( cont.Opportunity.Pricebook2Id != null ){
                    Set<Id> prodIds = new Set<Id>();
                    for( PricebookEntry pEntry : [SELECT Id, Name, Product2Id, UnitPrice from PricebookEntry WHERE Pricebook2Id = :cont.Opportunity.Pricebook2Id] ){
                        prodIds.add( pEntry.Product2Id );
                    }
                    return [SELECT Name FROM Product2 WHERE Id IN :prodIds];
                }
            }else{
                Contract cont = [ SELECT Opportunity__r.Pricebook2Id FROM Contract WHERE Id = :quoteId ];
                if( cont.Opportunity__r.Pricebook2Id != null ){
                    Set<Id> prodIds = new Set<Id>();
                    for( PricebookEntry pEntry : [SELECT Id, Name, Product2Id, UnitPrice from PricebookEntry WHERE Pricebook2Id = :cont.Opportunity__r.Pricebook2Id] ){
                        prodIds.add( pEntry.Product2Id );
                    }
                    return [SELECT Name FROM Product2 WHERE Id IN :prodIds];
                }
            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static List<OpportunityLineItem> getOppProds(Id quoteId, String objName){
        try {
            if( objName == 'Quote' ){
                Quote q = [SELECT Id, OpportunityId FROM Quote WHERE Id = :quoteId LIMIT 1];
                return  [SELECT Id, UnitPrice, ListPrice, Product2.Name,
                        Quantity, Monthly_Frequency__c, Impression__c 
                        FROM OpportunityLineItem
                        WHERE OpportunityId = :q.OpportunityId
                        ];
            }else{
                Contract q = [SELECT Id, Opportunity__c FROM Contract WHERE Id = :quoteId LIMIT 1];
                return  [SELECT Id, UnitPrice, ListPrice, Product2.Name,
                        Quantity, Monthly_Frequency__c, Impression__c 
                        FROM OpportunityLineItem
                        WHERE OpportunityId = :q.Opportunity__c
                        ];
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    //For multiple lookup

    @AuraEnabled(cacheable=true)
    public static List<SObJectResult> getAllSegments( String value, List<String> selectedRecId ) {
        List<SObJectResult> sObjectResultList = new List<SObJectResult>();
        System.debug( 'VALS:'+selectedRecId+', ->'+value );
        if(selectedRecId == null)
            selectedRecId = new List<String>();
        /* system.debug(fieldName+'-------------'+ObjectName+'---++----------'+value+'====='+selectedRecId);
        

        if(String.isNotEmpty(value)) {
            String query = 'Select Id';
            if(useFilterCriteria){
                query = query+ fieldName+' FROM '+ObjectName+' WHERE NAME LIKE \'%' + value.trim() + '%\' and ID NOT IN: selectedRecId ';
                query = query+' and '+filterField+'= \''+filterFieldValue+'\'';

            }else{
                query = query+', Name FROM '+ObjectName+' WHERE NAME LIKE \'%' + value.trim() + '%\' and ID NOT IN: selectedRecId';
            }
            system.debug(query);
            String fieldvalue = ''; */
            String query='';
        if(String.isNotEmpty(value)) {  
            query = 'SELECT Id, Name FROM Segment__c WHERE NAME LIKE \'%' + value.trim() + '%\' and ID NOT IN: selectedRecId';
        }else{
            query = 'SELECT Id, Name FROM Segment__c WHERE ID NOT IN: selectedRecId';
        }
        for(sObject so : Database.Query(query)) {
            String fieldvalue = (String)so.get('Name');
            sObjectResultList.add(new SObjectResult(fieldvalue, so.Id));
        }
        return sObjectResultList;
    }

    @AuraEnabled
    public static List<Invoice__c> getContractInvoiceStartEnd( Id contractId, Date sDate, Date eDate ){
        try {   
            System.debug( '-->'+sDate+':'+ eDate );
            return [ SELECT Id, IO__r.Opportunity__r.Segment_Name__c, End_Date__c, Start_Date__c, Proposal__c, IO__r.Flight__c, IO__r.Campaign_Name__c,
                     Client_Campaign_Name__c,
                     ( SELECT Sales_Price__c, Product__r.name, Invoice__c,
                     Counts__c, CPM__c, Impression__c, Monthly_Frequency__c 
                     FROM Invoice_Line_Items__r )
                     FROM Invoice__c WHERE 
                     IO__c = :contractId AND Start_Date__c >= :sDate AND End_Date__c <=:eDate
                    ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<SObJectResult> getResults(String ObjectName, String fieldName, String value, List<String> selectedRecId) {
        List<SObJectResult> sObjectResultList = new List<SObJectResult>();
        if(String.isNotEmpty(value)) {
            String query = 'Select Id, Name FROM Segment__c WHERE Name LIKE \'%' + value.trim() + '%\'';
            system.debug(query);
            for(sObject so : Database.Query(query)) {
                String fieldvalue = (String)so.get('Name');
                sObjectResultList.add(new SObjectResult(fieldvalue, so.Id));
            }
        }
        return sObjectResultList;
    }
    @AuraEnabled
    public static void createNewSegments( String newSegs ){
        try {
            System.debug( 'SS:'+newSegs );
            Map<String, Object> resMap = (Map<String, Object>)json.deserializeUntyped(newSegs);
            List<Opportunity_Segment__c> oppSegs = new List<Opportunity_Segment__c>();
            Set<Id> invIds = new Set<Id>();
            for( String key : resMap.keySet() ){
                List<Object> oppSegs2 = (List<Object>) resMap.get( key );
                for( Object opS : oppSegs2 ){
                    Map<string, Object> oppSe = (Map<string, Object>) opS;
                    String oppSegId = (String)oppSe.get('IO_Invoice_Line_Item__c');
                    if( oppSegId.length() > 10 ){
                        invIds.add( (Id)oppSe.get('IO_Invoice_Line_Item__c') );
                        if( (String)oppSe.get('Segment__c') != null ){
                            oppSegs.add( new Opportunity_Segment__c(Segment__c=(String)oppSe.get('Segment__c'), IO_Invoice_Line_Item__c = (Id)oppSe.get('IO_Invoice_Line_Item__c') ));
                        }    
                    }
                } 
            }
            if( invIds.size() > 0 ){
                System.debug('-->:'+oppSegs);
                DELETE [SELECT Id FROM Opportunity_Segment__c WHERE IO_Invoice_Line_Item__c IN :invIds];
                System.debug('Deleted');
                Set<Id> remInvId = new Set<Id>();
                for( Invoice_Line_Item__c invL : [SELECT Id FROM Invoice_Line_Item__c WHERE Id IN :invIds] ){
                    remInvId.add( invL.Id );
                }
                List<Opportunity_Segment__c> newOppSegs = new List<Opportunity_Segment__c>();
                for( Opportunity_Segment__c oppseg : oppSegs ){
                    if( remInvId.contains( oppseg.IO_Invoice_Line_Item__c ) ){
                        newOppSegs.add( oppseg );
                    }
                }
                if( newOppSegs.size() > 0 ){
                    System.debug('-->:'+newOppSegs);
                    INSERT newOppSegs;
                }
            }
            System.debug( oppSegs + '-->'+ invIds );
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    public class SObjectResult {
        @AuraEnabled
        public String recName;
        @AuraEnabled
        public Id recId;
        
        public SObJectResult(String recNameTemp, Id recIdTemp) {
            recName = recNameTemp;
            recId = recIdTemp;
        }
        public SObJectResult() {
          
        }
    }
}