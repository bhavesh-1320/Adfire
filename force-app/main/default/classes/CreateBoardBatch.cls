public class CreateBoardBatch implements Database.Batchable<sObject>, Database.stateful, Database.AllowsCallouts {
    Set<Id> campaignIds = new Set<Id>();
    public static boolean cStart = false;
    MondayCreds__c mondayCred = new MondayCreds__c();
    //default constructor 
    public CreateBoardBatch(){
        mondayCred = [SELECT Access_Token__c, Board_Id__c, Closed_Won_Group_Id__c FROM MondayCreds__c LIMIT 1];                   
    }
    public CreateBoardBatch( Set<Id> cIds){
        campaignIds = cIds;
        mondayCred = [SELECT Access_Token__c, Board_Id__c, Closed_Won_Group_Id__c FROM MondayCreds__c LIMIT 1];
    }
    public Database.QueryLocator start( Database.BatchableContext bc ){
        return Database.getQueryLocator([SELECT ContractNumber, Status, Board_Sub_Item_Id__c, Opportunity__r.Account.Name, 
                                         Opportunity__r.SubClient_or_Manufacturer__r.Name, StartDate, EndDate, Audiences__c,
                                         Opportunity__r.Name FROM Contract WHERE Id IN :campaignIds ]);
    }
    public void execute( Database.BatchableContext bc, List<Contract> ios ){
        cStart = true;
        if( mondayCred != null ){
            String accessToken = mondayCred.Access_Token__c;
            System.debug(accessToken);
            if( accessToken != null ){
                List<Account> accs = new List<Account>();
                for( Contract io : ios ){
                    if( io.status == 'Accepted' /*&& io.Board_Sub_Item_Id__c == null*/ ){
                    	createSubItemInMonday( io );    
                    }
                }
                UPDATE ios; 
            }
        }        
    }
    public void createSubItemInMonday( Contract io ){
        String itemName = io.Opportunity__r.Account.Name + '-' + io.Opportunity__r.SubClient_or_Manufacturer__r.Name+'-'+ io.Opportunity__r.Name + '-' +io.ContractNumber;
		Http h = new Http();
        Map<String, String> mondayColNameIdMap = getMondayColMap();
        HttpRequest req = new HttpRequest();
        req.setEndPoint('https://api.monday.com/v2');
        String sfIOLink = URL.getSalesforceBaseUrl().toExternalForm()+'/'+io.Id;
        String body = '{"query":"mutation { create_item (board_id: '+mondayCred.Board_Id__c+', group_id: \\"'+mondayCred.Closed_Won_Group_Id__c+'\\", item_name: \\"'+itemName+'\\", column_values: \\"{\\\\\\"'+mondayColNameIdMap.get( 'Salesforce IO Link' )+'\\\\\\" : {\\\\\\"url\\\\\\" : \\\\\\"'+sfIOLink+'\\\\\\", \\\\\\"text\\\\\\" : \\\\\\"'+io.ContractNumber+'\\\\\\"},'+'\\\\\\"'+mondayColNameIdMap.get( 'Start Date' )+'\\\\\\" : \\\\\\"'+io.StartDate+'\\\\\\",';
        body+= '\\\\\\"'+mondayColNameIdMap.get( 'End Date' )+'\\\\\\" : \\\\\\"'+io.EndDate+'\\\\\\",';
        body+= '\\\\\\"'+mondayColNameIdMap.get( 'Account' )+'\\\\\\" : \\\\\\"'+io.Opportunity__r.Account.Name+'\\\\\\",';
        //body+= '\\\\\\"'+mondayColNameIdMap.get( 'Segments' )+'\\\\\\" : \\\\\\"'+io.Audiences__c+'\\\\\\",';
        body+= '\\\\\\"'+mondayColNameIdMap.get( 'SubClient' )+'\\\\\\" : \\\\\\"'+io.Opportunity__r.SubClient_or_Manufacturer__r.Name+'\\\\\\"';
        body+='}\\") { id }}"}';
        System.debug('body-->'+body);
        req.setBody(body);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', mondayCred.Access_Token__c);
        HttpResponse res= h.send(req);
        Map<String, Object> resBody = (Map<String, Object>)JSON.deserializeUntyped( res.getBody() );
        System.debug(res.getBody());
        if( resBody.containsKey('data') ){
            Map<String, Object> resData = (Map<String, Object>)resBody.get( 'data' );
            Map<String, Object> resItem = (Map<String, Object>)resData.get( 'create_item' );
            if( resItem.containsKey( 'id' ) ){
                io.Board_Sub_Item_Id__c = (String)resItem.get( 'id' );
            }
        }
    }
    public Map<string, string> getMondayColMap(){
        Map<string, string> mondayColNameIdMap = new Map<string, string>();
        for( MondayColumns__c monCols : [SELECT Name, Business_Type__c, Column_Id__c FROM MondayColumns__c]){
            mondayColNameIdMap.put( monCols.Name, monCols.Column_Id__c );
        }
        return mondayColNameIdMap;
    }
    public void getAllCols(){
    	Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndPoint('https://api.monday.com/v2');
        String body = '{"query":"query { boards (ids: '+mondayCred.Board_Id__c+') {owner{ id }  columns {   title   type   id}}}"}';
        req.setBody(body);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', mondayCred.Access_Token__c);
        HttpResponse res= h.send(req);
        Map<String, Object> resBody = (Map<String, Object>)JSON.deserializeUntyped( res.getBody() );
        System.debug(res.getBody()); 
        Map<String, Object> resData = (Map<String, Object>)resBody.get( 'data' );
        List<Object> resBoards = (List<Object>)resData.get( 'boards' );
        Map<String, Object> resTempCols = (Map<String, Object>)resBoards[0];
        List<Object> resCols = (List<Object>)resTempCols.get('columns');
        //Map<String, Object> resCols = (Map<String, Object>)resBoards.get( 'columns' );
        System.debug('resData-> '+ resData);
        System.debug('resBoards-> '+ resBoards);
        List<MondayColumns__c> insertMondayColumnsList = new List<MondayColumns__c>();
        for(Object obj : resCols){
            
            MondayColumns__c mc = new MondayColumns__c();
            Map<String, Object> col = (Map<String, Object>)obj;
            mc.Business_Type__c = 'Adfire Health Marketing';
            mc.Column_Id__c = (String)col.get('id');
            //mc.Column_Name__c = 'title';
            mc.Name = (String)col.get('title');
			insertMondayColumnsList.add(mc);            
        }
        Database.upsert(insertMondayColumnsList, MondayColumns__c.Column_Id__c) ;
    }
    public void finish( Database.BatchableContext bc ){
        
    }
}