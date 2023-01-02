public class campaignFolderCreateCls {
    
    @InvocableMethod( callout=true )
    public static void createMondayBoard( List<Id> campaignIds ){
        system.debug('campaignIds===>'+campaignIds);
        List<Id> noBoardCampIds = new List<Id>();
        List<Id> boardCampIds = new List<Id>();
        //Database.executeBatch(new CreateGDriveBatch( campaignIds ), 25);
        String sObjName = campaignIds[0].getSObjectType().getDescribe().getName();
        system.debug('sObjeName===>'+sObjName);
        if( sObjName == 'Opportunity' ){
            Database.executeBatch(new CreateGDriveBatch( campaignIds, 'Opportunity' ), 10);
            //Creating Trade desk records
            //Database.executeBatch(new CreateTTDAccs( campaignIds ), 10);
        }/*else if( sObjName == 'Board_Campaign__c' ){
            for(Board_Campaign__c bCampaign : [SELECT Name, OpportunityCamaign__r.Account.Board_Link__c FROM Board_Campaign__c WHERE Id IN :campaignIds]){
                if( bCampaign.OpportunityCamaign__r.Account.Board_Link__c == null ){
                    noBoardCampIds.add( bCampaign.Id );
                }else{
                    boardCampIds.add( bCampaign.Id );
                }
            }
            Database.executeBatch(new CreateBoardBatch( noBoardCampIds, boardCampIds ), 50); 	
        }*/   
    }
    @AuraEnabled
    public static List<Object> getFilesOfFolder( String folderId ){
        GoogleDriveCreds__c gDriveCred = [SELECT Client_Secret__c, Access_Token__c, Client_Id__c FROM GoogleDriveCreds__c LIMIT 1];
        system.debug('gDriveCred--->'+gDriveCred);
        if( gDriveCred != null ){
            String accessToken = gDriveCred.Access_Token__c;
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            System.debug('FolderId:'+folderId);
            //req.setEndPoint('https://www.googleapis.com/drive/v3/files?q=\''+folderId+'\'+in+parents');
            req.setEndPoint('callout:GoogleDrive/drive/v3/files?q=\''+folderId+'\'+in+parents');
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json');
            //req.setHeader('Authorization', 'Bearer '+accessToken);
            req.setHeader('Accept', 'application/json');
            HttpResponse res= h.send(req);
            System.debug('FolderFiles:'+res.getBody());
            Map<String, Object> resBody = (Map<String, Object>)JSON.deserializeUntyped( res.getBody() );
            List<Object> files = (List<Object>)resBody.get( 'files' );
            system.debug('files--->'+files);
            return files;
        }
        return null;
    }
    @AuraEnabled
    public static List<Object> getFileNames( Id campaignId, String objName ){
        List<sObject> camp = Database.query('SELECT Name, Google_Drive_Link_Formula__c, Google_Drive_Link__c FROM '+objName+' WHERE Id = :campaignId LIMIT 1');
        system.debug('camp--->'+camp);
        if( camp!=null ){
            if( camp.size() > 0 ){
                String gLink = (String)camp[0].get('Google_Drive_Link_Formula__c');
                String fId = gLink.substring( gLink.lastIndexOf('/')+1 );
                system.debug(fId);
                List<Object> files = getFilesOfFolder(fId);
                return files;        
            }else{
                return null;
            }
        }
        return null;
    }
}