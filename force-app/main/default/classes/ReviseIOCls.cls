public with sharing class ReviseIOCls {
    @AuraEnabled
    public static List<OpportunityLineItem> getProductsOfIO( Id ioId ){
        try {
            Contract io = [SELECT Proposal__r.OpportunityId FROM Contract WHERE Id = :ioId LIMIT 1];
            return [SELECT Product2Id, Product2.Name, UnitPrice, ListPrice, Quantity, Monthly_Frequency__c, Impression__c FROM OpportunityLineItem WHERE OpportunityId = :io.Proposal__r.OpportunityId];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static List<Product2> getProducts( Id ioId ){
        try {
            Contract cont = [ SELECT Proposal__r.Opportunity.Pricebook2Id FROM Contract WHERE Id = :ioId ];
            if( cont.Proposal__r.Opportunity.Pricebook2Id != null ){
                Set<Id> prodIds = new Set<Id>();
                for( PricebookEntry pEntry : [SELECT Id, Name, Product2Id, UnitPrice from PricebookEntry WHERE Pricebook2Id = :cont.Proposal__r.Opportunity.Pricebook2Id] ){
                    prodIds.add( pEntry.Product2Id );
                }
                return [SELECT Name FROM Product2 WHERE Id IN :prodIds];
            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static Id createNewIO( List<OpportunityLineItem> upItems, DateTime startDate1, DateTime endDate1, Id ioId ){
        try {
            Contract c = [SELECT Id, Proposal__r.Opportunity.AccountId, Proposal__r.Opportunity.Pricebook2Id,
                          proposal__r.Opportunity.Primary_Contact__c, Proposal__c, Opportunity__c
                          FROM Contract WHERE Id = :ioId];
            List<Proposal_IO_Billing_Contact__c> ioBillContacts = new List<Proposal_IO_Billing_Contact__c>();
            Set<Id> productIds = new Set<Id>();
            for( OpportunityLineItem pItem : upItems ){
                productIds.add( pItem.Product2Id );
            } 
            Map<Id, Decimal> pIdCPM = new Map<Id, Decimal>();
            for( PricebookEntry pEntry : [SELECT Id, Name, Product2Id, UnitPrice from PricebookEntry WHERE Pricebook2Id = :c.Proposal__r.Opportunity.Pricebook2Id AND Product2Id IN :productIds] ){
                pIdCPM.put( pEntry.Product2Id, pEntry.UnitPrice );
            }
            DateTime dt = startDate1;
            Date startDate = Date.newInstance(dt.year(), dt.month(), dt.day());
            dt = endDate1;
            Date endDate = Date.newInstance(dt.year(), dt.month(), dt.day());
            Integer contractTerm = startDate.monthsBetween(endDate);
            Contract cont = new Contract( Opportunity__c = c.Opportunity__c, AccountId = c.proposal__r.Opportunity.AccountId, StartDate = startDate, ContractTerm = contractTerm, CustomerSignedId = c.proposal__r.Opportunity.Primary_Contact__c, Proposal__c = c.Proposal__c ); 
            ContractTriggerHelper.start = false;
            INSERT cont;
            for( Proposal_IO_Billing_Contact__c billCont : [SELECT Proposal__c, RecordTypeId, Contact__c, IO__c, Role__c FROM Proposal_IO_Billing_Contact__c WHERE IO__c = :ioId] ){
                billCont.IO__c = cont.Id;
                billCont.Id = null;
                ioBillContacts.add( billCont );
            }
            if( ioBillContacts.size() > 0 ){
                INSERT ioBillContacts;
            }
            List<Invoice__c> invoices = new List<Invoice__c>();
            List<Invoice_Line_Item__c> invLItems = new List<Invoice_Line_Item__c>();
            
            for( integer i = 0; i<contractTerm; i++ ){
                Integer numberOfDays = Date.daysInMonth(startDate.year(), startDate.month());
                endDate = startDate.addDays(numberOfDays - startDate.day());
                Invoice__c invoice = new Invoice__c( IO__c = cont.Id, Start_Date__c = startDate, End_Date__c = endDate );   
                startDate = endDate.addDays( 1 );
                
                if( upItems != null ){
                    for( OpportunityLineItem pItem : upItems ){
                        Invoice_Line_Item__c invLItem = new Invoice_Line_Item__c();
                        invLItem.Invoice__r = invoice;
                        invLItem.Product__c = pItem.Product2Id;
                        invLItem.Quantity__c = 1;
                        invLItem.Counts__c = pItem.Quantity;
                        invLItem.Monthly_Frequency__c = pItem.Monthly_Frequency__c;
                        invLItem.CPM__c = pIdCPM.get( pItem.Product2Id ); 
                        invLItem.Sales_Price__c = pItem.UnitPrice;
                        invLItems.add( invLItem );
                    }   
                }
                invoices.add( invoice );
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
                Database.executeBatch(new CreateInvoiceBatchCls(invoiceIds), 10);
            }
            return cont.Id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}