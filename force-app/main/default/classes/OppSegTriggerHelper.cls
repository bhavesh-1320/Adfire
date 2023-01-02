public class OppSegTriggerHelper {
    
    @future(callout=true)
    public static void createAudienceInIterable( Set<Id> oppSegId ){
        Set<Id> emailSegId = new Set<Id>();
        List<Segment__c> oppSegs = new List< Segment__c >();
        Map<id, List<String>> segIdNameMap = new Map<id, List<String>>();
        Map<String, Integer> iterableSegIdNameMap = new Map<String, Integer>();
        for(Opportunity_Segment__c oppSeg : [SELECT Id, IO_Invoice_Line_Item__r.Invoice__r.IO__r.Opportunity__r.Name,
                                             IO_Invoice_Line_Item__r.Invoice__r.IO__r.ContractNumber,
                                             IO_Invoice_Line_Item__r.Product__r.Name, Segment__c, Segment__r.Name 
                                             FROM Opportunity_Segment__c 
                                             WHERE Id IN :oppSegId AND IO_Invoice_Line_Item__r.Product__r.Name LIKE '%Email%' 
                                            ]){
                                                emailSegId.add( oppSeg.Segment__c ); 
                                                if( !segIdNameMap.containsKey( oppSeg.Segment__c ) ){
                                                    segIdNameMap.put( oppSeg.Segment__c, new List<String>() );
                                                } 
                                                segIdNameMap.get( oppSeg.Segment__c ).add( oppSeg.Segment__r.Name+' | '+ oppSeg.IO_Invoice_Line_Item__r.Invoice__r.IO__r.ContractNumber+' | '+ oppSeg.IO_Invoice_Line_Item__r.Invoice__r.IO__r.Opportunity__r.Name);
                                            }
        if( emailSegId.size()>0 ){
            HttpRequest req1 = new HttpRequest();
            req1.setHeader('API_Key', '1789943a29aa48a7870cf3f1de85152f');
            req1.setEndpoint('https://api.iterable.com/api/lists');
            req1.setMethod('GET');
            Http h1 = new Http();
            HttpResponse res1 = h1.send(req1);
            System.debug('resBody:'+res1.getBody());
            Map<String, Object> resMap1 = (Map<String, Object>)JSON.deserializeUntyped( res1.getBody() );
            List<Object> resObj1 = (List<Object>)resMap1.get( 'lists' );
            for( Object o : resObj1 ){
                Map<String, Object> resL = (Map<String, Object>)o;
                iterableSegIdNameMap.put( (String)resL.get( 'name' ), (Integer)resL.get( 'id' ) );
            }
            for( Segment__c seg : [SELECT Name, List_Id__c, (SELECT Id, Email__c, Address_Line_1__c, Address_Line_2__c,
                                                             City__c, Zip__c, state__c, Last_Name__c, First_Name__c
                                                             FROM Audiences__r) FROM Segment__c WHERE Id IN :emailSegId] ){
                                                                 if( segIdNameMap.containsKey( seg.Id ) ){
                                                                     for( String segName : segIdNameMap.get( seg.Id ) ){
                                                                         Integer lId;
                                                                         if( !iterableSegIdNameMap.containsKey(segName) ){
                                                                             HttpRequest req = new HttpRequest();
                                                                             req.setBody('{"name":"'+segName+'"}');
                                                                             req.setHeader('API_Key', '1789943a29aa48a7870cf3f1de85152f');
                                                                             req.setEndpoint('https://api.iterable.com/api/lists');
                                                                             req.setMethod('POST');
                                                                             Http h = new Http();
                                                                             HttpResponse res = h.send(req);
                                                                             Map<String, Object> resMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                                                                             lId = (Integer)resMap.get( 'listId' );
                                                                             seg.List_Id__c = lId;
                                                                             System.debug('resMap:'+resMap);
                                                                         }else{
                                                                             lId = (Integer)iterableSegIdNameMap.get(segName);
                                                                         }
                                                                         List<Audience__c> newAudiences = seg.Audiences__r;
                                                                         String resBody = '{"users":[';
                                                                         for( Audience__c audience : newAudiences ){
                                                                             resBody += '{"email":"'+audience.Email__c+'", "dataFields":{';
                                                                             resBody += '"addressLine1":"'+audience.Address_Line_1__c+'",';
                                                                             resBody += '"emailListIds": ['+lId+'],"addressLine2": "'+audience.Address_Line_2__c+'",';
                                                                             resBody += '"city": "'+audience.City__c+'","zipcode": "'+audience.Zip__c+'","state": "'+audience.state__c+'","lastName": "'+audience.Last_Name__c+'","firstName": "'+audience.First_Name__c+'"}},';
                                                                         }
                                                                         resBody = resBody.substring(0, resBody.length()-1);
                                                                         resBody += ']}';
                                                                         System.debug('body:'+resBody);
                                                                         HttpRequest req = new HttpRequest();
                                                                         req.setBody(resBody);
                                                                         req.setHeader('API_Key', '1789943a29aa48a7870cf3f1de85152f');
                                                                         req.setEndpoint('https://api.iterable.com/api/users/bulkUpdate');
                                                                         req.setMethod('POST');
                                                                         Http h = new Http();
                                                                         HttpResponse res = h.send(req);
                                                                         System.debug('resBody:'+res.getBody());
                                                                         oppSegs.add( seg );
                                                                     }
                                                                 } 
                                                             }
        }
        
    }
    public static void updateOppAud( List<Opportunity_Segment__c> newOppSegs ){
        System.debug(newOppSegs);
        List<Opportunity> opps = new List<Opportunity>();
        Set<Id> oppIds = new Set<Id>();
        Map<Id, Set<String>> oppSegMap = new Map<Id, Set<String>>();
        for( Opportunity_Segment__c oppSeg : newOppSegs ){
            if( oppSeg.Opportunity__c != null ){
                oppIds.add( oppSeg.Opportunity__c );
            }
        }
        for( Opportunity_Segment__c oppSeg : [SELECT Segment__r.Name, IsDeleted, Opportunity__c FROM Opportunity_Segment__c WHERE Opportunity__c IN :oppIds ALL ROWS] ){
            if( oppSeg.Opportunity__c != null ){
                oppIds.add( oppSeg.Opportunity__c );
                if( !oppSegMap.containsKey( oppSeg.Opportunity__c ) ){
                    oppSegMap.put( oppSeg.Opportunity__c, new Set<String>() );
                }
                if( !oppSeg.IsDeleted )	oppSegMap.get( oppSeg.Opportunity__c ).add( oppSeg.Segment__r.Name );
            }
        }
        System.debug(oppSegMap);
        for( Id oppId : oppSegMap.keySet() ){
            Opportunity opp = new Opportunity( Id = oppId );
            String s = '';
            for( String seg : oppSegMap.get( oppId ) ){
                s+=seg+',';
            }
            System.debug(s.length());
            if( s.length() > 0 )	s = s.substring(0, s.length()-1);
            else	s = ' ';
            System.debug(s);
            opp.Audiences__c = s;
            opps.add( opp );
        }
        if( opps.size() > 0 ){
            UPDATE opps;
        }
    }
    public static void updateIOAud( List<Opportunity_Segment__c> newOppSegs ){
        System.debug(newOppSegs);
        if( newOppSegs != null ){
            List<Invoice_Line_Item__c> invLItems = new List<Invoice_Line_Item__c>();
            Set<Id> ioIds = new Set<Id>();
            Map<Id, Set<String>> oppSegMap = new Map<Id, Set<String>>();
            for( Opportunity_Segment__c oppSeg : newOppSegs ){
                if( oppSeg.IO_Invoice_Line_Item__c != null ){
                    ioIds.add( oppSeg.IO_Invoice_Line_Item__c );
                }
            }
            for( Opportunity_Segment__c oppSeg : [SELECT Segment__r.Name, IsDeleted, Opportunity__c, IO_Invoice_Line_Item__c FROM Opportunity_Segment__c WHERE IO_Invoice_Line_Item__c IN :ioIds ALL ROWS] ){
                if( oppSeg.IO_Invoice_Line_Item__c != null ){
                    ioIds.add( oppSeg.IO_Invoice_Line_Item__c );
                    if( !oppSegMap.containsKey( oppSeg.IO_Invoice_Line_Item__c ) ){
                        oppSegMap.put( oppSeg.IO_Invoice_Line_Item__c, new Set<String>() );
                    }
                    if( !oppSeg.IsDeleted )	oppSegMap.get( oppSeg.IO_Invoice_Line_Item__c ).add( oppSeg.Segment__r.Name );
                }
            }
            for( Id ioInvLItemId : oppSegMap.keySet() ){
                Invoice_Line_Item__c invLItem = new Invoice_Line_Item__c( Id = ioInvLItemId );
                String s = '';
                for( String seg : oppSegMap.get( ioInvLItemId ) ){
                    s+=seg+',';
                }
                System.debug(s.length());
                if( s.length() > 0 )	s = s.substring(0, s.length()-1);
                else	s = ' ';
                System.debug('AUD:'+s);
                invLItem.Audience__c = s;
                invLItems.add( invLItem );    
            }
            if( invLItems.size() > 0 ){
                UPDATE invLItems;
            }    
        }
    }
}