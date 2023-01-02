public class GenerateQBInvoiceCls {
    public GenerateQBInvoiceCls( ApexPages.StandardController sc ){
        
    }
    @future(callout=true)
    public static void createInvoice( Set<Id> quoteIds ){
        List<QuoteLineItem> quoteLItems = [SELECT Discount, QuoteId, UnitPrice, Product2Id, Product2.Name, product2.Product_Id__c, Quantity, TotalPrice FROM QuoteLineItem WHERE QuoteId IN :quoteIds];
        List<Quote> quotes= [SELECT Invoice_Creation_Date__c, Budget_Confirmed__c, Flight_End_Date__c, Flight_Start_Date__c, Opportunity.Primary_contact__c, Opportunity.Primary_contact__r.Name, Opportunity.Primary_contact__r.Email, Opportunity.Primary_contact__r.QB_Customer_Id__c FROM Quote WHERE Id IN :quoteIds];
        Quickbook_Creds__mdt cred = [SELECT Id, realmId__c, Client_Secret__c, MasterLabel, DeveloperName, Refresh_Token__c, redirect_uri__c, Client_Id__c, Access_Token__c, Endpoint__c FROM Quickbook_Creds__mdt WHERE DeveloperName = 'Creds'];
        Map<Id, List<QuoteLineItem>> quoteIdLItemMap = new Map<Id, List<QuoteLineItem>>();
        for( QuoteLineItem qLItem : quoteLItems ){
            if( !quoteIdLItemMap.containsKey(qLItem.QuoteId) ){
                quoteIdLItemMap.put( qLItem.QuoteId, new List<QuoteLineItem>() );
            }
            quoteIdLItemMap.get(qLItem.QuoteId).add( qLItem );
        }
        List<Invoice_Line_Item__c> invLItems = new List<Invoice_Line_Item__c>();
        List<Invoice__c> invoices = new List<Invoice__c>();
        List<Contact> contacts = new List<Contact>();
        for( Quote quot : quotes ){
            Invoice__c invoice = new Invoice__c( Proposal__c = quot.Id );
            if( quoteIdLItemMap.containsKey(quot.Id) ){
                for( QuoteLineItem oppLItem : quoteIdLItemMap.get( quot.Id )){
                    Invoice_Line_Item__c invLItem = new Invoice_Line_Item__c();
                    invLItem.Discount__c = oppLItem.Discount;
                    invLItem.Invoice__r = invoice;
                    invLItem.Product__c = oppLItem.Product2Id;
                    invLItem.Quantity__c = oppLItem.Quantity;
                    invLItem.Sales_Price__c = oppLItem.UnitPrice;
                    invLItems.add( invLItem );
                } 
            }
            invoices.add( invoice );
            String cusId = quot.Opportunity.Primary_contact__r.QB_Customer_Id__c;
            Contact cont;
            if( quot.Opportunity.Primary_contact__r.QB_Customer_Id__c == null && quot.Opportunity.Primary_Contact__c != null ){
                Http h = new Http();
                String endpoint = cred.Endpoint__c+'/'+cred.realmId__c+'/customer?minorversion=65';
                HttpRequest req = new HttpRequest();
                req.setEndPoint(endpoint);
                req.setHeader('Authorization', 'Bearer '+cred.Access_Token__c);
                req.setHeader( 'Content-Type', 'application/json' );
                req.setHeader('Accept', 'application/json');
                req.setMethod('POST');
                req.setBody('{ "PrimaryEmailAddr": {"Address": "'+quot.Opportunity.Primary_contact__r.Email+'"}, "DisplayName": "'+quot.Opportunity.Primary_contact__r.Name+'"}');
                HttpResponse res= h.send(req);
                Map<String, Object> resBody = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                System.debug(resBody);
                Map<String,Object> cusMap = (Map<String,Object>)resBody.get('Customer');
                cont = new Contact( Id = quot.Opportunity.Primary_Contact__c, QB_Customer_Id__c = (String)cusMap.get('Id') );
                cusId = cont.QB_Customer_Id__c;
                contacts.add( cont );
            }
            if( cusId != null ){
                createQBInvoice( quot.Id, cusId, quoteIdLItemMap.get( quot.Id ) );
            }
            if( quot.Invoice_Creation_Date__c != null ){
                DateTime dt = quot.Flight_End_Date__c;
                Date d = Date.newInstance(dt.year(), dt.month(), dt.day());
                if( quot.Invoice_Creation_Date__c.addMonths(1) <= d ){
                    quot.Invoice_Creation_Date__c = quot.Invoice_Creation_Date__c.addMonths(30); 
                }else{
                    quot.Budget_Confirmed__c = false;
                }    
            }
        }
        if( quotes.size() > 0 ){
            UPDATE quotes;
        }
        if( contacts.size() > 0 ){
            UPDATE contacts;    
        }
        if( invoices.size() > 0 ){
            INSERT invoices;
            if( invLItems.size() > 0 ){
                for( Invoice_Line_Item__c invLineItem : invLItems ){
                    invLineItem.Invoice__c = invLineItem.invoice__r.Id;
                }
                INSERT invLItems;
            }           
        }
    }
    public static PageReference createQBUser(){
        Id quoteId = apexpages.currentpage().getparameters().get('id');
        Database.executeBatch(new CreateInvoiceBatchCls(new Set<Id>{quoteId}), 10);
        //createInvoice( new Set<Id>{quoteId}  );
        /*Invoice__c invoice = new Invoice__c( Proposal__c = quoteId );
        List<Invoice_Line_Item__c> invLItems = new List<Invoice_Line_Item__c>();
        for( QuoteLineItem oppLItem : [SELECT Discount, UnitPrice, Product2Id, Product2.Name, product2.Product_Id__c, Quantity, TotalPrice FROM QuoteLineItem WHERE QuoteId = :quoteId] ){
            Invoice_Line_Item__c invLItem = new Invoice_Line_Item__c();
            invLItem.Discount__c = oppLItem.Discount;
            invLItem.Invoice__r = invoice;
            invLItem.Product__c = oppLItem.Product2Id;
            invLItem.Quantity__c = oppLItem.Quantity;
            invLItem.Sales_Price__c = oppLItem.UnitPrice;
            invLItem.Total_Price__c = oppLItem.TotalPrice;
            invLItems.add( invLItem );
        }
        Quote quot = [SELECT Opportunity.Primary_contact__c, Opportunity.Primary_contact__r.Name, Opportunity.Primary_contact__r.Email, Opportunity.Primary_contact__r.QB_Customer_Id__c FROM Quote WHERE Id = :quoteId];
        Quickbook_Creds__mdt cred = [SELECT Id, realmId__c, Client_Secret__c, MasterLabel, DeveloperName, Refresh_Token__c, redirect_uri__c, Client_Id__c, Access_Token__c, Endpoint__c FROM Quickbook_Creds__mdt WHERE DeveloperName = 'Creds'];
        String cusId = quot.Opportunity.Primary_contact__r.QB_Customer_Id__c;
        Contact cont;
        if( quot.Opportunity.Primary_contact__r.QB_Customer_Id__c == null && quot.Opportunity.Primary_Contact__c != null ){
            Http h = new Http();
            String endpoint = cred.Endpoint__c+'/'+cred.realmId__c+'/customer?minorversion=65';
            HttpRequest req = new HttpRequest();
            req.setEndPoint(endpoint);
            req.setHeader('Authorization', 'Bearer '+cred.Access_Token__c);
            req.setHeader( 'Content-Type', 'application/json' );
            req.setHeader('Accept', 'application/json');
            req.setMethod('POST');
            req.setBody('{ "PrimaryEmailAddr": {"Address": "'+quot.Opportunity.Primary_contact__r.Email+'"}, "DisplayName": "'+quot.Opportunity.Primary_contact__r.Name+'"}');
            HttpResponse res= h.send(req);
            Map<String, Object> resBody = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            System.debug(resBody);
            Map<String,Object> cusMap = (Map<String,Object>)resBody.get('Customer');
            cont = new Contact( Id = quot.Opportunity.Primary_Contact__c, QB_Customer_Id__c = (String)cusMap.get('Id') );
            cusId = cont.QB_Customer_Id__c;
        }
        if( cusId != null ){
            createQBInvoice( quoteId, cusId );
            if( cont !=null ){
                UPDATE cont;    
                INSERT invoice;
                if( invLItems.size() > 0 ){
                    for( Invoice_Line_Item__c invLineItem : invLItems ){
                        invLineItem.Invoice__c = invLineItem.invoice__r.Id;
                    }
                    INSERT invLItems;
                }
            }
        }
        return new PageReference( '/'+quoteId );
        Id oppId = apexpages.currentpage().getparameters().get('id');
        Invoice__c invoice = new Invoice__c( Opportunity__c = oppId );
        List<Invoice_Line_Item__c> invLItems = new List<Invoice_Line_Item__c>();
        for( OpportunityLineItem oppLItem : [SELECT Discount, UnitPrice, Product2Id, Product2.Name, product2.Product_Id__c, Quantity, TotalPrice FROM OpportunityLineItem WHERE OpportunityId = :oppId] ){
            Invoice_Line_Item__c invLItem = new Invoice_Line_Item__c();
            invLItem.Discount__c = oppLItem.Discount;
            invLItem.Invoice__r = invoice;
            invLItem.Product__c = oppLItem.Product2Id;
            invLItem.Quantity__c = oppLItem.Quantity;
            invLItem.Sales_Price__c = oppLItem.UnitPrice;
            invLItem.Total_Price__c = oppLItem.TotalPrice;
            invLItems.add( invLItem );
        }
        Opportunity opp = [SELECT Primary_contact__c, Primary_contact__r.Name, Primary_contact__r.Email, Primary_contact__r.QB_Customer_Id__c FROM Opportunity WHERE Id = :oppId];
        Quickbook_Creds__mdt cred = [SELECT Id, realmId__c, Client_Secret__c, MasterLabel, DeveloperName, Refresh_Token__c, redirect_uri__c, Client_Id__c, Access_Token__c, Endpoint__c FROM Quickbook_Creds__mdt WHERE DeveloperName = 'Creds'];
        String cusId = opp.Primary_contact__r.QB_Customer_Id__c;
        Contact cont;
        if( opp.Primary_contact__r.QB_Customer_Id__c == null && opp.Primary_Contact__c != null ){
            Http h = new Http();
            String endpoint = cred.Endpoint__c+'/'+cred.realmId__c+'/customer?minorversion=65';
            HttpRequest req = new HttpRequest();
            req.setEndPoint(endpoint);
            req.setHeader('Authorization', 'Bearer '+cred.Access_Token__c);
            req.setHeader( 'Content-Type', 'application/json' );
            req.setHeader('Accept', 'application/json');
            req.setMethod('POST');
            req.setBody('{ "PrimaryEmailAddr": {"Address": "'+opp.Primary_contact__r.Email+'"}, "DisplayName": "'+opp.Primary_contact__r.Name+'"}');
            HttpResponse res= h.send(req);
            Map<String, Object> resBody = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            System.debug(resBody);
            Map<String,Object> cusMap = (Map<String,Object>)resBody.get('Customer');
            cont = new Contact( Id = opp.Primary_Contact__c, QB_Customer_Id__c = (String)cusMap.get('Id') );
            cusId = cont.QB_Customer_Id__c;
        }
        if( cusId != null ){
            createQBInvoice( oppId, cusId );
            if( cont !=null ){
                UPDATE cont;    
                INSERT invoice;
                if( invLItems.size() > 0 ){
                    for( Invoice_Line_Item__c invLineItem : invLItems ){
                        invLineItem.Invoice__c = invLineItem.invoice__r.Id;
                    }
                    INSERT invLItems;
                }
            }
        }*/
        return new PageReference( '/'+quoteId );
    }
    /*public static void createQBInvoice( Id oppId, String cId ){
        Opportunity opp = [SELECT Primary_contact__c, Primary_contact__r.Name, Primary_contact__r.Email, Primary_contact__r.QB_Customer_Id__c FROM Opportunity WHERE Id = :oppId];
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
        for( OpportunityLineItem oppLItem : [SELECT UnitPrice, Product2.Name, product2.Product_Id__c, Quantity, TotalPrice FROM OpportunityLineItem WHERE OpportunityId = :oppId] ){
            body+='{"DetailType": "SalesItemLineDetail", "SalesItemLineDetail": { "Qty": '+oppLItem.Quantity+', "UnitPrice": '+oppLItem.UnitPrice+', "ItemRef": {"name": "'+oppLItem.Product2.Name+'", "value": "'+oppLItem.product2.Product_Id__c+'"}}, "Amount": '+oppLItem.TotalPrice+'},';
        }
        body = body.substring(0, body.length()-1);
        body+='],"CustomerRef": {"value": "'+cId+'"}}';
        System.debug('Body:'+body);
        req.setBody(body);
        HttpResponse res= h.send(req);
        Map<String, Object> resBody = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        System.debug(resBody);
    }*/
    public static void createQBInvoice( Id quoteId, String cId, List<QuoteLineItem> quoteLItems ){
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
            for( QuoteLineItem oppLItem : quoteLItems ){
                body+='{"DetailType": "SalesItemLineDetail", "SalesItemLineDetail": { "Qty": '+oppLItem.Quantity+', "UnitPrice": '+oppLItem.UnitPrice+', "ItemRef": {"name": "'+oppLItem.Product2.Name+'", "value": "'+oppLItem.product2.Product_Id__c+'"}}, "Amount": '+oppLItem.TotalPrice+'},';
            }      
        }
        body = body.substring(0, body.length()-1);
        body+='],"CustomerRef": {"value": "'+cId+'"}}';
        System.debug('Body:'+body);
        req.setBody(body);
        HttpResponse res= h.send(req);
        Map<String, Object> resBody = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        System.debug(resBody);
    }
}