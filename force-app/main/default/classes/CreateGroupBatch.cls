public class CreateGroupBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    List<Id> campaignIds = new List<Id>();
    MondayCreds__c mondayCred = new MondayCreds__c();
    public CreateGroupBatch( List<Id> campIds ){
        campaignIds = campIds;
        mondayCred = [SELECT Access_Token__c FROM MondayCreds__c LIMIT 1];
    }
    public Database.QueryLocator start( Database.BatchableContext bc ){
        return Database.getQueryLocator([SELECT Name, Folder_Link__c, Group_Id__c, OpportunityCamaign__r.Account.Board_Link__c, OpportunityCamaign__r.Account.Name FROM Board_Campaign__c WHERE Id IN :campaignIds ]);
    }
    public void execute( Database.BatchableContext bc, List<Board_Campaign__c> camps ){
        if( mondayCred != null ){
            String accessToken = mondayCred.Access_Token__c;
            System.debug(accessToken);
            if( accessToken != null ){
                System.debug('a:'+accessToken);
                for( Board_Campaign__c camp : camps ){
                    String boardId = camp.OpportunityCamaign__r.Account.Board_Link__c.substring( camp.OpportunityCamaign__r.Account.Board_Link__c.lastIndexOf( '/' )+1 );
                    Http h = new Http();
                    HttpRequest req = new HttpRequest();
                    req.setEndPoint('https://api.monday.com/v2');
                    System.debug('bId:'+boardId);
                    String body = '{"query":"mutation { create_group (board_id: '+boardId+', group_name: \\"'+camp.Name+'\\") { id }}"}';
                    req.setBody(body);
                    req.setMethod('POST');
                    req.setHeader('Content-Type', 'application/json');
                    req.setHeader('Authorization', accessToken);
                    HttpResponse res= h.send(req);
                    System.debug('reqBody:'+body);
                    Map<String, Object> resBody = (Map<String, Object>)JSON.deserializeUntyped( res.getBody() );
                    System.debug(res.getBody());
                    Map<String, Object> resData = (Map<String, Object>)resBody.get('data');
                    Map<String, Object> resCBoard = (Map<String, Object>)resData.get('create_group');
                    camp.Group_Id__c = (String)resCBoard.get('id');
                }
                UPDATE camps;
            }
        }  
    }
    public void finish( Database.BatchableContext bc ){
        
    }
}