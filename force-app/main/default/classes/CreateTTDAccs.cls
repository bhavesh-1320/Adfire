public class CreateTTDAccs implements Database.Batchable<sObject>, Database.AllowsCallouts {
    Set<Id> ioIds = new Set<Id>();
    TradeDeskCreds__c ttdCred = new TradeDeskCreds__c();
    Map<String, String> campNameTTDId = new Map<String, String>(); 
    public String accessToken;
    List<Account> accountAdIds = new List<Account>();
    public CreateTTDAccs( Set<Id> cIds ){
        ioIds = cIds;
        ttdCred = [SELECT Password__c, Username__c, PartnerId__c FROM TradeDeskCreds__c LIMIT 1];
    }
    public Database.QueryLocator start( Database.BatchableContext bc ){
        return Database.getQueryLocator([SELECT Id, ContractNumber, opportunity__r.Primary_KPI__c, opportunity__r.Account.Name, opportunity__r.Account.Website,
                                         opportunity__r.Name, opportunity__r.Account.Trade_Desk_Advertiser__c, opportunity__r.Account.Trade_Desk_Advertiser_Id__c, opportunity__r.TTD_Conversion_Goal__c, 
                                         opportunity__r.Direct__c, opportunity__r.AccountId, opportunity__r.SubClient_or_Manufacturer__r.Name, 
                                         opportunity__r.Audience_Type__c, opportunity__r.Account.Parent.Name
                                         FROM Contract WHERE Id IN :ioIds]);
    }
    public void execute( Database.BatchableContext bc, List<Contract> conts ){
        getAccessToken();
        Map<Id, List<Invoice_Line_Item__c>> ioIdLineItemMap = new Map<Id, List<Invoice_Line_Item__c>>();
        Set<Id> ioInvoiceIds = new Set<Id>();
        
        Map<Id, List<String>> invItemIdOppSegMap = new Map<Id, List<String>>();
        Set<Id> invLItemIds = new Set<Id>();
        
        for( Invoice__c inv : [SELECT Id, Io__c FROM Invoice__c WHERE IO__c IN :ioIds] ){
            ioInvoiceIds.add( inv.Id );
        }
        for( Invoice_Line_Item__c invLItem : [SELECT Id, Invoice__r.IO__c, Product__r.Name, Product__c, 
                                              Product__r.AdGroups__c, Campaign_Id__c, Trade_Desk_Campaign__c,
                                              Invoice__r.Total_Price__c, Invoice__r.End_Date__c, Invoice__r.Start_Date__c, 
                                              Product__r.Platform_Details__c
                                              FROM Invoice_Line_Item__c
                                              WHERE Invoice__c IN :ioInvoiceIds
                                             ] )
        {
            if( !ioIdLineItemMap.containsKey( invLItem.Invoice__r.IO__c ) ){
                ioIdLineItemMap.put( invLItem.Invoice__r.IO__c, new List<Invoice_Line_Item__c>() );
            }
            ioIdLineItemMap.get( invLItem.Invoice__r.IO__c ).add( invLItem );
            invLItemIds.add( invLItem.Id );
        }
        for( Opportunity_Segment__c oppSeg : [SELECT IO_Invoice_Line_Item__c, Segment__r.Name FROM 
                                              Opportunity_Segment__c WHERE 
                                              IO_Invoice_Line_Item__c IN :invLItemIds
                                             ] )
        {
            if( !invItemIdOppSegMap.containsKey( oppSeg.IO_Invoice_Line_Item__c ) ){
                invItemIdOppSegMap.put( oppSeg.IO_Invoice_Line_Item__c, new List<String>() );
            }	            
            invItemIdOppSegMap.get( oppSeg.IO_Invoice_Line_Item__c ).add( oppSeg.Segment__r.Name );
        }
        for( Contract cont : conts ){
            String adId = createAdvertiseAcc( cont );
            System.debug('ad:'+adId);
            List<Invoice_Line_Item__c> invLItem;
            List<String> oppSegs;
            if( ioIdLineItemMap.containsKey( cont.Id ) ){
                invLItem = ioIdLineItemMap.get( cont.Id );
            }
            createCampaign(adId, cont, invLItem, invItemIdOppSegMap);
        }
        if( accountAdIds.size() > 0 ){
            UPDATE accountAdIds;
        }
    }
    public void finish( Database.BatchableContext bc ){
        
    }
    public void getAccessToken(){
        if( ttdCred.Password__c != null ){
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://api.thetradedesk.com/v3/authentication');
            req.setBody('{"Login" : "'+ttdCred.Username__c+'", "Password":"'+ttdCred.Password__c+'"}');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            HttpResponse res = h.send(req);
            System.debug(res.getBody());
            Map<String, Object> resBody = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            if( resBody.containsKey('Token') ){
                accessToken = (String)resBody.get( 'Token' );
                System.debug('->'+accessToken);
            }
        }        
    }
    String createAdvertiseAcc( Contract cont ){
        String adId;
        if(cont.opportunity__r.Account.ParentId != null){
            if( cont.opportunity__r.Account.Parent.Trade_Desk_Advertiser__c != null ){
                adId = cont.opportunity__r.Account.Trade_Desk_Advertiser__c;
                adId = adId.substring(adId.lastIndexOf('/')+1);
                return adId;
            }
        } else {
            if( cont.opportunity__r.Account.Trade_Desk_Advertiser__c != null ){
                adId = cont.opportunity__r.Account.Trade_Desk_Advertiser__c;
                adId = adId.substring(adId.lastIndexOf('/')+1);
                return adId;
            }
        }
        
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.thetradedesk.com/v3/advertiser');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('TTD-Auth', accessToken);
        //https://www.domain.com
        String reqBody;
        if(cont.opportunity__r.Account.ParentId != null){
            reqBody = '{"PartnerId": "'+ttdCred.PartnerId__c+'","AdvertiserName": "'+cont.opportunity__r.Account.Parent.Name+'","Description": "New Advertiser","CurrencyCode": "USD","AttributionClickLookbackWindowInSeconds": 5184000,"AttributionImpressionLookbackWindowInSeconds": 5184000,"ClickDedupWindowInSeconds": 7,"ConversionDedupWindowInSeconds": 60,"DefaultRightMediaOfferTypeId": 13,"IndustryCategoryId": 84,"DomainAddress": "'+cont.opportunity__r.Account.Website+'"}';
        }else{
            reqBody = '{"PartnerId": "'+ttdCred.PartnerId__c+'","AdvertiserName": "'+cont.opportunity__r.Account.Name+'","Description": "New Advertiser","CurrencyCode": "USD","AttributionClickLookbackWindowInSeconds": 5184000,"AttributionImpressionLookbackWindowInSeconds": 5184000,"ClickDedupWindowInSeconds": 7,"ConversionDedupWindowInSeconds": 60,"DefaultRightMediaOfferTypeId": 13,"IndustryCategoryId": 84,"DomainAddress": "'+cont.opportunity__r.Account.Website+'"}';
        }
        req.setBody(reqBody);
        HttpResponse res = h.send( req );
        System.debug('-->'+res.getBody());
        Map<String, Object> resBody = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        if( resBody.containsKey( 'AdvertiserId' ) ){
            if(cont.opportunity__r.Account.ParentId != null){
                accountAdIds.add( new Account( Id = cont.opportunity__r.Account.ParentId, Trade_Desk_Advertiser_Id__c = (String)resBody.get( 'AdvertiserId' ), Trade_Desk_Advertiser__c = 'https://desk.thetradedesk.com/app/advertiser/'+(String)resBody.get( 'AdvertiserId' ) ) );
            }else{
                accountAdIds.add( new Account( Id = cont.opportunity__r.AccountId, Trade_Desk_Advertiser_Id__c = (String)resBody.get( 'AdvertiserId' ), Trade_Desk_Advertiser__c = 'https://desk.thetradedesk.com/app/advertiser/'+(String)resBody.get( 'AdvertiserId' ) ) );
            }
            return (String)resBody.get( 'AdvertiserId' );
        }
        return adId;
    }
    void createCampaign( String adId, Contract cont, List<Invoice_Line_Item__c> invLItems, Map<Id, List<String>> invItemIdOppSegMap ){
        for( Invoice_Line_Item__c invLItem : invLItems ){
            if( invLItem.Product__r.Platform_Details__c == 'TTD' ){
                String segs = '';
                if( invItemIdOppSegMap.containsKey( invLItem.Id ) ){
                    if( invItemIdOppSegMap.get( invLItem.Id ).size() > 0 ){
                        segs = String.join(invItemIdOppSegMap.get( invLItem.Id ), ',');
                    }
                }
                Http h = new Http();
                HttpRequest req = new HttpRequest();
                req.setEndpoint('https://api.thetradedesk.com/v3/campaign');
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');
                req.setHeader('TTD-Auth', accessToken);
                Integer amount = 500000;
                if( invLItem.Product__r.AdGroups__c != null ){
                    if( invLItem.Product__r.AdGroups__c.contains('InApp') ){
                        amount = 250000;
                    }    
                }
                String campName;
                if(cont.opportunity__r.Account.ParentId != null){
                    campName = cont.opportunity__r.Account.Name+' - '+cont.Opportunity__r.Name+' - '+cont.opportunity__r.Audience_Type__c+' - ';
                } else {
                    campName = 'Direct - '+cont.Opportunity__r.Name+' - '+cont.opportunity__r.Audience_Type__c+'-';
                }
                //String campName = cont.opportunity__r.SubClient_or_Manufacturer__r.Name+'-'+cont.Opportunity__r.Name+'-'+cont.opportunity__r.Audience_Type__c+'-';
                if( segs != '' ){
                    campName+=segs+'-';
                }
                campName+= invLItem.Product__r.Name+'-'+cont.ContractNumber;
                if( campNameTTDId.containsKey(campName) ){
                    invLItem.Trade_Desk_Campaign__c = 'https://desk.thetradedesk.com/app/advertiser/'+adId+'/buy/campaign/'+campNameTTDId.get( campName )+'/details';
                    invLItem.Campaign_Id__c = campNameTTDId.get( campName );
                    createFlight( campNameTTDId.get( campName ), invLItem, amount );
                }else{
                    //String reqBody = '{"AdvertiserId":"'+adId+'","CampaignName":"'+campName+'","Objective":"'+cont.opportunity__r.TTD_Conversion_Goal__c+'","IncludeDefaultsFromAdvertiser":"true","AutoAllocatorEnabled":"true","AutoPrioritizationEnabled":"true","PacingMode":"PaceAhead","PrimaryChannel":"Display","PrimaryGoal":{"MaximizeReach":true},"CampaignConversionReportingColumns":null,';
                    String reqBody = '{"AdvertiserId":"'+adId+'","CampaignName":"'+campName+'","Objective":"'+cont.opportunity__r.TTD_Conversion_Goal__c+'","IncludeDefaultsFromAdvertiser":"true","AutoAllocatorEnabled":"true","AutoPrioritizationEnabled":"true","PacingMode":"PaceAhead","PrimaryChannel":"Display",';
                    if( cont.opportunity__r.Primary_KPI__c == 'CPA' ){
                        reqBody += '"PrimaryGoal":{"CPAInAdvertiserCurrency":{"Amount": 28.00,"CurrencyCode": "USD"}},"SecondaryGoal":{"CTRInPercent":true},"TertiaryGoal":{"CPC/Reach":true},';
                    }else if( cont.opportunity__r.Primary_KPI__c == 'CTR' ){
                        reqBody += '"PrimaryGoal":{"CTRInPercent":true},"SecondaryGoal":{"CPCInAdvertiserCurrency":true},"TertiaryGoal":{"MaximizeReach":true},';
                    }else if( cont.opportunity__r.Primary_KPI__c == 'Reach/High Match' ){
                        reqBody += '"PrimaryGoal":{"CPCInAdvertiserCurrency":true},"SecondaryGoal":{"CTRInPercent":true},"TertiaryGoal":{"MaximizeReach":true},';
                    }
                    reqBody+='"CampaignConversionReportingColumns":null,"StartDate":"'+invLItem.Invoice__r.Start_Date__c+'","EndDate":"'+invLItem.Invoice__r.End_Date__c+'","Budget":{"Amount": '+amount+',"CurrencyCode": "USD"}}';
                    req.setBody(reqBody);
                    HttpResponse res = h.send(req);
                    System.debug('__+>'+reqBody);
                    System.debug('-->'+res.getBody());
                    Map<String, Object> campaignMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                    if( campaignMap.containsKey('CampaignId') ){
                        if( campaignMap.containsKey('CampaignFlights') ){
                            List<Object> flights = (List<Object>)campaignMap.get('CampaignFlights');
                            if( flights.size() > 0 ){
                                Map<String, Object> flightObj = (Map<String, Object>)flights[0];
                                if( flightObj.containsKey('CampaignFlightId') ){
                                    createAdGroups( (String)campaignMap.get('CampaignId'), (Integer)flightObj.get('CampaignFlightId'), invLItem.product__c, segs, cont.ContractNumber );             
                                }
                            }
                        } 
                        invLItem.Trade_Desk_Campaign__c = 'https://desk.thetradedesk.com/app/advertiser/'+adId+'/buy/campaign/'+(String)campaignMap.get('CampaignId')+'/details';
                        invLItem.Campaign_Id__c = (String)campaignMap.get('CampaignId');
                        campNameTTDId.put( campName, (String)campaignMap.get('CampaignId') );
                    }    
                }
            }    
        }
        UPDATE invLItems;
    }
    void createFlight( String cId, Invoice_Line_Item__c invLItem, Integer amount ){
        
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.thetradedesk.com/v3/campaignflight');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('TTD-Auth', accessToken);
        //https://www.domain.com
        String reqBody = '{"CampaignId": "'+cId+'","StartDateInclusiveUTC": "'+invLItem.Invoice__r.Start_Date__c+'","EndDateExclusiveUTC": "'+invLItem.Invoice__r.End_Date__c+'","BudgetInAdvertiserCurrency": '+amount+'}';
        req.setBody(reqBody);
        HttpResponse res = h.send( req );
        System.debug('-->'+res.getBody());
    }
    void createAdGroups( String campId, Integer flightId, Id prodId, String segs, String ioNum ){
        if( prodId != null && campId != null ){
            Product2 prod = [SELECT Id,  Channel__c, Name, Platform_Details__c, AdGroups__c FROM Product2 WHERE Id = :prodId ];
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://api.thetradedesk.com/v3/adgroup');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('TTD-Auth', accessToken);
            if( prod.AdGroups__c != null ){
                List<String> adGroupNames = prod.AdGroups__c.split( ',' );
                for( String adGroupName : adGroupNames ){
                    String ttdAdGroupName = prod.Name+'-'+adGroupName;
                    if( segs!= '' ){
                        ttdAdGroupName+='-'+segs;
                    }
                    ttdAdGroupName+='-'+ioNum;
                    Integer budget = 500000;
                    if( adGroupName == 'InApp' ){
                        budget = 250000;
                    }
                    String reqBody = '{"CampaignId":"'+campId+'","AdGroupName":"'+ttdAdGroupName+'","IndustryCategoryId":84,"UseIdentityAlliance":true,"PredictiveClearingEnabled":true,"RTBAttributes":{"ROIGoal":{"CPAInAdvertiserCurrency":{"Amount":0.2,"CurrencyCode":"USD"}},"AudienceTargeting":{"AudienceBoosterEnabled":true, "AudienceExcluderEnabled":true},"BudgetSettings":{"AdGroupFlights":[{"AdGroupId":null,"CampaignFlightId":'+flightId+',"BudgetInAdvertiserCurrency":'+budget+'}],"PacingMode":"PaceAhead"},';
                    reqBody+='"BaseBidCPM":{"Amount":1.0,"CurrencyCode":"USD"},"MaxBidCPM":{"Amount":5.0,"CurrencyCode":"USD"}}}';
                    req.setBody(reqBody);
                    HttpResponse res = h.send(req);
                    System.debug('=->'+reqBody);
                    System.debug('-_->'+res.getBody());
                    //Map<String, Object> campaignMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                }    
            }
        }
    }
}