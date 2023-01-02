public class BackupData implements Database.Batchable<sObject>, Database.AllowsCallouts {
    List<Id> campaignIds = new List<Id>();
    GoogleDriveCreds__c gDriveCred = new GoogleDriveCreds__c();
    public BackupData( List<Id> cIds ){
        campaignIds = cIds;
        gDriveCred = [SELECT Client_Secret__c, MainFolderId__c, Access_Token__c, Client_Id__c FROM GoogleDriveCreds__c LIMIT 1];
    }
    public Database.QueryLocator start( Database.BatchableContext bc ){
        return Database.getQueryLocator([SELECT Name, Folder_Link__c, CreatedById, CreatedBy.Name, CreatedBy.Google_Drive_Folder_Link__c FROM Board_Campaign__c WHERE Id IN :campaignIds ]);
    }
    public void execute( Database.BatchableContext bc, List<Board_Campaign__c> camps ){
        if( gDriveCred != null ){
            String accessToken = gDriveCred.Access_Token__c;
            if( accessToken != null ){
                List<User> userGDriveLink = new List<User>();
                for( Board_Campaign__c camp : camps ){
                    Http h = new Http();
                    HttpRequest req = new HttpRequest();
                    req.setEndPoint('https://www.googleapis.com/drive/v3/files');
                    String fId;
                    if( camp.CreatedBy.Google_Drive_Folder_Link__c == null ){
                    	String body = '{"mimeType" : "application/vnd.google-apps.folder","title":"'+camp.CreatedBy.Name+'","name":"'+camp.CreatedBy.Name+'", "parents":["'+gDriveCred.MainFolderId__c+'"]}';
                        req.setBody(body);
                        req.setMethod('POST');
                        req.setHeader('Content-Type', 'application/json');
                        req.setHeader('Authorization', 'Bearer '+accessToken);
                        req.setHeader('Accept', 'application/json');
                        HttpResponse res= h.send(req);
                        Map<String, Object> resBody = (Map<String, Object>)JSON.deserializeUntyped( res.getBody() );
                        System.debug(res.getBody());
                        System.debug(res.getBody());
                        if( (String)resBody.get('id') != null || (String)resBody.get('id')!='' ){
                            camp.CreatedBy.Google_Drive_Folder_Link__c = 'https://drive.google.com/drive/u/0/folders/'+(String)resBody.get('id');
                        	
                            User u = new USer( Id = camp.CreatedById, Google_Drive_Folder_Link__c='https://drive.google.com/drive/u/0/folders/'+(String)resBody.get('id') );
                        	fId = (String)resBody.get('id');
                            userGDriveLink.add( u );
                        }
                    }else{
                        fId = camp.CreatedBy.Google_Drive_Folder_Link__c.substring(camp.CreatedBy.Google_Drive_Folder_Link__c.lastIndexOf('/')+1);
                    }   
                    String body = '{"mimeType" : "application/vnd.google-apps.folder","title":"'+camp.Name+'","name":"'+camp.Name+'", "parents":["'+fId+'"]}';
                    req.setBody(body);
                    req.setMethod('POST');
                    req.setHeader('Content-Type', 'application/json');
                    req.setHeader('Authorization', 'Bearer '+accessToken);
                    req.setHeader('Accept', 'application/json');
                    HttpResponse res= h.send(req);
                    Map<String, Object> resBody = (Map<String, Object>)JSON.deserializeUntyped( res.getBody() );
                    System.debug(res.getBody());
                    if( (String)resBody.get('id') != null || (String)resBody.get('id')!='' ){
                        camp.Folder_Link__c = 'https://drive.google.com/drive/u/0/folders/'+(String)resBody.get('id');
                    }
                }
                UPDATE userGDriveLink;
                UPDATE camps;
            }
        }        
    }
    public void finish( Database.BatchableContext bc ){
        
    }

}