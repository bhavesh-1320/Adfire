public class CreateInvoiceBatchCls implements Database.Batchable<sObject>, Database.AllowsCallouts {
    Set<Id> ioInvoiceIds = new Set<Id>();
    public CreateInvoiceBatchCls( Set<Id> qIds ){
        ioInvoiceIds = qIds;
    }
    public Database.QueryLocator start( Database.BatchableContext bc ){
        return Database.getQueryLocator([SELECT Start_Date__c, End_Date__c, IO__r.Proposal__r.Opportunity.Primary_contact__c FROM Invoice__c WHERE Id IN :ioInvoiceIds]);
    }
    public void execute( Database.BatchableContext bc, List<Invoice__c> ioInvoices ){
        Map<Id, Contact> cIdContactMap = new Map<Id, Contact>();
        Map<Id, Contact> invoiceContactMap = new Map<Id, Contact>();
        Set<Id> contactIds = new Set<Id>();
        for( Invoice__c inv : ioInvoices ){
            contactIds.add( inv.IO__r.Proposal__r.Opportunity.Primary_contact__c );
        }
        for( Contact cont : [SELECT Id, QB_Customer_Id__c, Email, Name FROM Contact WHERE Id IN :contactIds] ){
            cIdContactMap.put( cont.id, cont );
        }
        for( Invoice__c inv : ioInvoices ){
            if( cIdContactMap.containsKey(inv.IO__r.Proposal__r.Opportunity.Primary_contact__c) ){
                if( !invoiceContactMap.containsKey(inv.Id) ){
                	invoiceContactMap.put( inv.Id, new Contact() );    
                }
                invoiceContactMap.put( inv.Id, cIdContactMap.get(inv.IO__r.Proposal__r.Opportunity.Primary_contact__c) );    
            }
        }
        List<Invoice_Line_Item__c> quoteLItems = [SELECT Discount__c, Invoice__c, Sales_Price__c, Product__c, Product__r.Name, product__r.Product_Id__c, Quantity__c, Total_Price__c FROM Invoice_Line_Item__c WHERE Invoice__c IN :ioInvoiceIds];
        Quickbook_Creds__mdt cred = [SELECT Id, realmId__c, Client_Secret__c, MasterLabel, DeveloperName, Refresh_Token__c, redirect_uri__c, Client_Id__c, Access_Token__c, Endpoint__c FROM Quickbook_Creds__mdt WHERE DeveloperName = 'Creds'];
        Map<Id, List<Invoice_Line_Item__c>> quoteIdLItemMap = new Map<Id, List<Invoice_Line_Item__c>>();
        for( Invoice_Line_Item__c qLItem : quoteLItems ){
            if( !quoteIdLItemMap.containsKey(qLItem.Invoice__c) ){
                quoteIdLItemMap.put( qLItem.Invoice__c, new List<Invoice_Line_Item__c>() );
            }
            quoteIdLItemMap.get(qLItem.Invoice__c).add( qLItem );
        }
        List<Contact> contacts = new List<Contact>();
        for( Invoice__c quot : ioInvoices ){
            if( invoiceContactMap.containsKey(quot.Id) ){
                Contact cont = invoiceContactMap.get( quot.Id );
                String cusId = cont.QB_Customer_Id__c;
                if( cont.QB_Customer_Id__c == null ){
                    Http h = new Http();
                    String endpoint = cred.Endpoint__c+'/'+cred.realmId__c+'/customer?minorversion=65';
                    HttpRequest req = new HttpRequest();
                    req.setEndPoint(endpoint);
                    req.setHeader('Authorization', 'Bearer '+cred.Access_Token__c);
                    req.setHeader( 'Content-Type', 'application/json' );
                    req.setHeader('Accept', 'application/json');
                    req.setMethod('POST');
                    req.setBody('{ "PrimaryEmailAddr": {"Address": "'+cont.Email+'"}, "DisplayName": "'+cont.Name+'"}');
                    HttpResponse res= h.send(req);
                    Map<String, Object> resBody = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                    System.debug(resBody);
                    Map<String,Object> cusMap = (Map<String,Object>)resBody.get('Customer');
                    cont.QB_Customer_Id__c = (String)cusMap.get('Id');
                    cusId = cont.QB_Customer_Id__c;
                    contacts.add( cont );
                }
                if( cusId != null ){
                    createQBInvoice( quot.Id, cusId, quoteIdLItemMap.get( quot.Id ), quot.Start_Date__c, quot.End_Date__c );
                }    
            }
        }
        if( contacts.size() > 0 ){
            UPDATE contacts;    
        }
    }
    public static void createQBInvoice( Id quoteId, String cId, List<Invoice_Line_Item__c> quoteLItems, Date sDate, Date eDate ){
        Quickbook_Creds__mdt cred = [SELECT Id, realmId__c, Client_Secret__c, MasterLabel, DeveloperName, Refresh_Token__c, redirect_uri__c, Client_Id__c, Access_Token__c, Endpoint__c FROM Quickbook_Creds__mdt WHERE DeveloperName = 'Creds'];
        Http h = new Http();
        String endpoint = cred.Endpoint__c+'/'+cred.realmId__c+'/invoice?minorversion=65';
        HttpRequest req = new HttpRequest();
        req.setEndPoint(endpoint);
        req.setHeader('Authorization', 'Bearer '+cred.Access_Token__c);
        req.setHeader( 'Content-Type', 'application/json' );
        req.setHeader('Accept', 'application/json');
        req.setMethod('POST');
        String body = '{"Line": [';
        if( quoteLItems != null ){
            if( quoteLItems.size() > 0 ){
                for( Invoice_Line_Item__c oppLItem : quoteLItems ){
                    body+='{"DetailType": "SalesItemLineDetail", "SalesItemLineDetail": { "Qty": '+oppLItem.Quantity__c+', "UnitPrice": '+oppLItem.Sales_Price__c+', "ItemRef": {"name": "'+oppLItem.Product__r.Name+'", "value": "'+oppLItem.product__r.Product_Id__c+'"}}, "Amount": '+oppLItem.Total_Price__c+'},';
                }
                body = body.substring(0, body.length()-1);    
            }
        }
        body+='],"CustomerRef": {"value": "'+cId+'"},"DueDate" : "'+eDate+'","TxnDate":"'+sDate+'"}';
        System.debug('Body:'+body);
        req.setBody(body);
        HttpResponse res= h.send(req);
        Map<String, Object> resBody = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        System.debug(resBody);
    }
    public void finish( Database.BatchableContext bc ){
        
    }
}