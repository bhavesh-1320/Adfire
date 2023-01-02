global class uploadFileToDriveBatch implements Database.Batchable<sObject>, Database.stateful, Database.AllowsCallouts{
    public uploadFileToDriveBatch(Set<Id> contVerId){
        cvIdSet = contVerId;
    }
    public final Set<Id> cvIdSet;
    Map<Id, String> contVersionProIdMap = new Map<Id, String>();
    global Database.QueryLocator start(Database.BatchableContext bc){
        // Get the Map of Schema of ContentVersion SObject
        Set<Id> contDocIds = new Set<Id>();
        Set<Id> linkedEntId = new Set<Id>();
        Map<Id, Id> oppIdVersionId = new Map<Id, Id>(); 
        for( ContentDocumentLink cDL : [SELECT Id, ContentDocumentId, ContentDocument.LatestPublishedVersionId, LinkedEntityId FROM ContentDocumentLink WHERE Id IN :cvIdSet] ){
            contDocIds.add( cDL.ContentDocumentId );
            linkedEntId.add( cDL.LinkedEntityId );
            oppIdVersionId.put( cDL.LinkedEntityId, cDL.ContentDocument.LatestPublishedVersionId );
        }
        Map<id, String> oppIdMap = new Map<id, string>();
        for(Opportunity opp : [SELECT Id, Google_Drive_Proposal_Id__c, Proposal_Link__c FROM Opportunity WHERE Id IN :linkedEntId ]){
            //oppIdMap.put( opp.Id, opp.Google_Drive_Proposal_Id__c );
            if( oppIdVersionId.containsKey( opp.Id ) ){
                if( opp.Proposal_Link__c != null ){
                    String pId = opp.Proposal_Link__c.substring( opp.Proposal_Link__c.lastIndexOf( '/' )+1 );
                	contVersionProIdMap.put( oppIdVersionId.get( opp.Id ), pId );    
                }
            }
        }
        Map<String, Schema.SObjectField> fieldMap = ContentVersion.sObjectType.getDescribe().fields.getMap();
        System.debug('cvIdSet--> '+cvIdSet);
        // Get all of the fields on the object
        Set<String> setFieldNames = fieldMap.keySet();
        list<String> lstFieldNames = new List<String>(setFieldNames);
        String query = 'SELECT ' + String.join(lstFieldNames, ',') + ' FROM ContentVersion Where ContentDocumentId in :contDocIds';
        return Database.getQueryLocator(query) ;
    }
    global void execute(Database.BatchableContext bc, List<ContentVersion> cvs){
        System.debug('-->>'+contVersionProIdMap);
        for( ContentVersion cv : cvs ){
            System.debug('Databse list ' + cv);
            if( cv.Title.contains( 'RFP' ) ){
                String boundary = '----------9889464542212';
                String delimiter = '\r\n--' + boundary +'\r\n';
                String close_delim = '\r\n--' + boundary + '--'; 
                Blob fileInBlob  = cv.VersionData;
                Id OpportunityId = cv.FirstPublishLocationId;
                String FileExe = cv.FileExtension; 
                String filetype = '';
                System.debug('contentVersion =>'+ cv.VersionData);
                System.debug('FileExtension =>'+ cv.FileExtension);
                System.debug('filetype =>'+ cv.fileType);
                System.debug('title =>'+ cv.Title);
                //String FolderId = '1g1UzqV35Dj_o9_2IOCGfdEGR98mNWYlw';
                String FolderId = contVersionProIdMap.get( cv.Id );
                String bodyEncoded  = System.EncodingUtil.base64Encode(fileInBlob);
                // Blob bdata  = system.EncodingUtil.base64Decode(bodyEncoded);
                //System.debug('debug for parent Id => '+ gcfolder[0].Folder_Id__c);
                //String bolbdata = bdata.toString();
                String filename = cv.Title;
                string mimeTypeVer = 'text/plain';
                if( cv.FileExtension == 'png' )	mimeTypeVer = 'image/jpeg';
                String body=delimiter+'Content-Type: application/json; charset=UTF-8\r\n\r\n'+'{ "name" : "'+filename+'",'+ ' "mimeType" : "'+ mimeTypeVer+ '",' + '"parents":["'+FolderId+'"] }'+delimiter+'Content-Type: ' + filetype + '\r\n'+'Content-Transfer-Encoding: base64\r\n'+'\r\n'+bodyEncoded+close_delim;
                System.debug('body => ' +body);
                
                Http http = new Http();
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:GoogleDrive/upload/drive/v3/files?uploadType=multipart&convert=true');
                // req.setHeader('Authorization', 'Bearer ' +access_token);
                req.setHeader('Content-Type', 'multipart/mixed; boundary="'+boundary+'"');
                req.setHeader('Content-length', String.valueOf(body.length()));
                req.setBody(body);
                req.setMethod('POST');
                //req.setTimeout(60*1000);
                System.debug(req);
                HttpResponse response = http.send(req);
                System.debug('-->'+response.getBody());
                if(response.getStatusCode() != 200) {
                    System.debug('The status code returned was not expected: ' + response.getStatusCode() + ' ' + response.getStatus());
                } else {
                    System.debug(response.getBody());
                }    
            }     
        }  
    }  
    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }    
}