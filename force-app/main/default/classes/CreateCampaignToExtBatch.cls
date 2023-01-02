public class CreateCampaignToExtBatch implements Database.Batchable<sObject>, Database.AllowsCallouts{
    List<Invoice__c> ioInvoices = new List<Invoice__c>();
    public CreateCampaignToExtBatch( List<Invoice__c> campNames ){
        ioInvoices = campNames;
    }
    public List<Invoice__c> start( Database.BatchableContext bc ){
        return ioInvoices;
    }	
    public void execute( Database.BatchableContext bc, List<Invoice__c> ioInvoicesIte ){
        Map<String, String> cNameIterableIdMap = new Map<String, String>();
        Set<String> campaignsName = new Set<String>();
        List<Invoice_Line_Item__c> invLItems = new List<Invoice_Line_Item__c>();
        for( Invoice__c inv : ioInvoicesIte){
            for( Invoice_Line_Item__c invLItem : inv.Invoice_Line_Items__r ){
                if( invLItem.Iterable_Campaign_Id__c == null )
                    campaignsName.add( inv.IO__r.Campaign_Name__c+'-'+invLItem.Product__r.Name+'-IO#'+inv.IO__r.ContractNumber ); 	   
            }
        }
        for( String cName : campaignsName ){
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://api.iterable.com/api/campaigns/create');
            req.setMethod('POST');
            req.setHeader('Api_Key', '32ff9424befa448ab59848bc48305267');
            req.setBody('{"name": "'+cName+'","listIds": [1861940],"templateId": 6775759}');
            HttpResponse res = h.send( req );
            System.debug(res.getBody());
            Map<String, Object> resMap = ( Map<String, Object> )JSON.deserializeUntyped(res.getBody());
            Integer cId = (Integer)resMap.get( 'campaignId' );
            cNameIterableIdMap.put( cName, String.valueOf(cId) );
        }
        for( Invoice__c inv : ioInvoicesIte){
            for( Invoice_Line_Item__c invLItem : inv.Invoice_Line_Items__r ){
                if( cNameIterableIdMap.containsKey( inv.IO__r.Campaign_Name__c+'-'+invLItem.Product__r.Name+'-IO#'+inv.IO__r.ContractNumber ) ){
                    invLItem.Iterable_Campaign_Id__c = cNameIterableIdMap.get( inv.IO__r.Campaign_Name__c+'-'+invLItem.Product__r.Name+'-IO#'+inv.IO__r.ContractNumber );
                    invLItems.add( invLItem ); 	   
                }
            }
        }
        if( invLItems.size() > 0 ){
            UPDATE invLItems;
        }
    }	
    public void finish( Database.BatchableContext bc ){
        
    }
}