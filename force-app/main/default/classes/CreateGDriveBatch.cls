public class CreateGDriveBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.stateful {
    List<Id> oppIds = new List<Id>();
    GoogleDriveCreds__c gDriveCred = new GoogleDriveCreds__c();
    String oppOrIO = '';
    Map<Id, String> oppIdIoNum = new Map<Id, String>();
    public CreateGDriveBatch( List<Id> cIds, String diff ){
        oppIds = cIds;
        oppOrIO = diff;
        gDriveCred = [SELECT AHM__c, AHR__c, Client_Secret__c, MainFolderId__c, Access_Token__c, Client_Id__c FROM GoogleDriveCreds__c LIMIT 1];
    }
    public Database.QueryLocator start( Database.BatchableContext bc ){
        if( oppOrIO == 'IO' ){
            for( Contract cont : [SELECT ContractNumber, Opportunity__c FROM Contract WHERE ID IN :oppIds] ){
                oppIdIoNum.put( cont.Opportunity__c, cont.ContractNumber );
            }
            System.debug('--?'+oppIdIONum);
            oppIds = new List<Id>();
            oppIds.addAll( oppIdIoNum.keySet() );
        }
        return Database.getQueryLocator([SELECT Proposal_Link__c, Name, RecordType.Name, Direct__c, Google_Drive_Link__c, AccountId, SubClient_or_Manufacturer__r.Name, Account.Name,Account.Parent.Name, Account.Google_Drive_Link__c, 
                                         SubClient_or_Manufacturer__c, SubClient_or_Manufacturer__r.Google_Drive_Link__c, Drive_Link__c
                                         FROM Opportunity WHERE Id IN :oppIds ]);
    }
    public void execute( Database.BatchableContext bc, List<Opportunity> opps ){
        if( oppOrIO == 'Opportunity' ){
            createProposalFolders( opps );    
        } else if( oppOrIO == 'IO' ){
            changeNameFolders( opps );
        }
    }
    void changeNameFolders( List<Opportunity> opps ){
        for( Opportunity opp : opps ){
            if( opp.Proposal_Link__c != null ){
                String rId = opp.Drive_Link__c.substring( opp.Drive_Link__c.lastIndexOf('/')+1 );
                
                Http h = new Http();
                HttpRequest req = new HttpRequest();
                req.setEndPoint('callout:GoogleDrive/drive/v3/files/fileId?fileId='+rId);
                //req.setEndPoint('https://www.googleapis.com/drive/v3/files/fileId?fileId='+rId);
                req.setMethod('PATCH');
                req.setHeader('Content-Type', 'application/json');
                //req.setHeader('Authorization', 'Bearer '+accessToken);
                
                System.debug('oppIdIONum:'+oppIdIONum);
                String body = '{"name" : "'+oppIdIONum.get( opp.Id )+' | '+ opp.Name +'"}';
                req.setBody(body);
                req.setHeader('Accept', 'application/json');
                HttpResponse resp1 = h.send(req);
                System.debug('RR'+resp1.getBody());
                renameFolder( rId, opp );                
            }
        }
    }
    void renameFolder( String rId, Opportunity opp ){
        Http h3 = new Http();
        HttpRequest req3 = new HttpRequest();
        //req3.setEndPoint('https://www.googleapis.com/drive/v3/files?q=\''+rId+'\'+in+parents');
        req3.setEndPoint('callout:GoogleDrive/drive/v3/files?q=\''+rId+'\'+in+parents');
        req3.setMethod('GET');
        req3.setHeader('Content-Type', 'application/json');
        //req3.setHeader('Authorization', 'Bearer '+accessToken);
        req3.setHeader('Accept', 'application/json');
        
        HttpResponse resp2= h3.send(req3);
        System.debug('RR'+resp2.getBody());
        Map<String, Object> resBody3 = (Map<String, Object>)JSON.deserializeUntyped( resp2.getBody() );
        List<Object> pFiles2 = (List<Object>) resBody3.get( 'files' );
        Map<String, String> folderNameIdMap2 = new Map<String, String>(); 
        for( Object pFile : pFiles2 ){
            Map<String, Object> pFileMap = (Map<String, Object>)pFile;
            //folderNameIdMap2.put( (String)pFileMap.get('name'), (String)pFileMap.get('id') );
            System.debug('--->'+pFileMap.get('name'));
            
            Http h2 = new Http();
            HttpRequest req2 = new HttpRequest();
            //req2.setEndPoint('https://www.googleapis.com/drive/v3/files/fileId?fileId='+(String)pFileMap.get('id'));
            req2.setEndPoint('callout:GoogleDrive/drive/v3/files/fileId?fileId='+(String)pFileMap.get('id'));
            req2.setMethod('PATCH');
            req2.setHeader('Content-Type', 'application/json');
            //req2.setHeader('Authorization', 'Bearer '+accessToken);
            
            String n = (String)pFileMap.get('name');
            String newName = n.substring(0, n.indexOf('|'));
            
            
            if( newName == 'Creatives ' || newName == 'Reporting' ){
                System.debug('Hellooo');
                renameFolder( (String)pFileMap.get('id'), opp );
            } 
            if( newName == 'Assets ' || newName == 'Sales ' || newName == 'Reports ' || newName == 'Archive ' || newName == 'Creatives ' ||
               newName == 'Target Lists ' || newName == 'Screenshots ' || newName == 'Proposals ' || newName == 'Reporting '
              ){
                  newName += '| '+oppIdIONum.get( opp.Id )+' | '+ opp.Name;
                  String body2 = '{"name" : "'+newName+'"}';
                  req2.setBody(body2);
                  req2.setHeader('Accept', 'application/json');
                  HttpResponse resp3 = h2.send(req2);
                  System.debug('RR'+resp3.getBody());
                  System.debug('..>'+n);   
              }
        }
    }
    void createProposalFolders( List<Opportunity> opps ){
        List<Account> accountGDriveLink = new List<Account>();
        
        List<Contract> contracts = new List<Contract>();
        
        for( Opportunity opp : opps ){
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            //req.setEndPoint('https://www.googleapis.com/drive/v3/files');
            req.setEndPoint('callout:GoogleDrive/drive/v3/files');
            String fId;
            String sId;
            String ioId;
            Boolean hasParentAccount = false;
            if(opp.Account.ParentId != null){
                hasParentAccount = true;
            }
            
            String rId = '';
            if( opp.RecordType.Name == 'Adfire Health Recruit' ){
                rId = gDriveCred.AHR__c;
            }else if( opp.RecordType.Name == 'Adfire Health Marketing' ){
                rId = gDriveCred.AHM__c;
            }
            Http h3 = new Http();
            HttpRequest req3 = new HttpRequest();
            //req3.setEndPoint('https://www.googleapis.com/drive/v3/files?q=\''+rId+'\'+in+parents');
            req3.setEndPoint('callout:GoogleDrive/drive/v3/files?q=\''+rId+'\'+in+parents');
            req3.setMethod('GET');
            req3.setHeader('Content-Type', 'application/json');
            //req3.setHeader('Authorization', 'Bearer '+accessToken);
            req3.setHeader('Accept', 'application/json');
            
            HttpResponse resp2= h3.send(req3);
            System.debug('RR'+resp2.getBody());
            Map<String, Object> resBody3 = (Map<String, Object>)JSON.deserializeUntyped( resp2.getBody() );
            List<Object> pFiles2 = (List<Object>) resBody3.get( 'files' );
            Map<String, String> folderNameIdMap2 = new Map<String, String>(); 
            for( Object pFile : pFiles2 ){
                Map<String, Object> pFileMap = (Map<String, Object>)pFile;
                folderNameIdMap2.put( (String)pFileMap.get('name'), (String)pFileMap.get('id') );
            }
            System.debug('folderNameIdMap2.containsKey( opp.Account.Name ) '+folderNameIdMap2.containsKey( opp.Account.Name ));
            System.debug('folderNameIdMap2.containsKey( opp.Account.Parent?.Name ) '+folderNameIdMap2.containsKey( opp.Account.Parent?.Name ));
            System.debug(' parent addvertiser account--> '+ opp.Account.Parent.Name);
            System.debug('has parent'+ opp.Account.Parent.Name);
            System.debug('Account Name--> '+ opp.Account.Name);
            
            
            //new condition starts from here
            if(hasParentAccount){
                String body;
                if(!folderNameIdMap2.containsKey( opp.Account.Parent.Name )){
                    body = '{"mimeType" : "application/vnd.google-apps.folder","title":"'+opp.Account.Parent.Name+'","name":"'+opp.Account.Parent.Name+'", "parents":["'+rId+'"]}';
                    req.setBody(body);
                    req.setMethod('POST');
                    req.setHeader('Content-Type', 'application/json');
                    //req.setHeader('Authorization', 'Bearer '+accessToken);
                    req.setHeader('Accept', 'application/json');
                    HttpResponse res= h.send(req);
                    Map<String, Object> resBody = (Map<String, Object>)JSON.deserializeUntyped( res.getBody() );
                    System.debug(res.getBody());
                    System.debug(res.getBody());
                    if( (String)resBody.get('id') != null || (String)resBody.get('id')!='' ){
                        // opp.Account.Google_Drive_Link__c = 'https://drive.google.com/drive/u/0/folders/'+(String)resBody.get('id');
                        if( opp.RecordType.Name == 'Adfire Health Recruit' ){
                            Account acc = new Account( Id = opp.AccountId, Adfire_Health_Recruit_Drive_Link__c='https://drive.google.com/drive/u/0/folders/'+(String)resBody.get('id') );    
                            accountGDriveLink.add(acc);
                        }else if( opp.RecordType.Name == 'Adfire Health Marketing' ){
                            Account acc = new Account( Id = opp.AccountId, Adfire_Health_Marketing_Drive_Link__c='https://drive.google.com/drive/u/0/folders/'+(String)resBody.get('id') );    
                            accountGDriveLink.add(acc);
                        }
                        fId = (String)resBody.get('id');  
                    }
                } else{
                    fId = folderNameIdMap2.get(opp.Account.Parent.Name);
                }
            } else{
                String body;
                if( ! folderNameIdMap2.containsKey( opp.Account.Name ) ){
                    body = '{"mimeType" : "application/vnd.google-apps.folder","title":"'+opp.Account.Name+'","name":"'+opp.Account.Name+'", "parents":["'+rId+'"]}';
                    req.setBody(body);
                    req.setMethod('POST');
                    req.setHeader('Content-Type', 'application/json');
                    //req.setHeader('Authorization', 'Bearer '+accessToken);
                    req.setHeader('Accept', 'application/json');
                    HttpResponse res= h.send(req);
                    Map<String, Object> resBody = (Map<String, Object>)JSON.deserializeUntyped( res.getBody() );
                    System.debug(res.getBody());
                    System.debug(res.getBody());
                    if( (String)resBody.get('id') != null || (String)resBody.get('id')!='' ){
                        // opp.Account.Google_Drive_Link__c = 'https://drive.google.com/drive/u/0/folders/'+(String)resBody.get('id');
                        if( opp.RecordType.Name == 'Adfire Health Recruit' ){
                            Account acc = new Account( Id = opp.AccountId, Adfire_Health_Recruit_Drive_Link__c='https://drive.google.com/drive/u/0/folders/'+(String)resBody.get('id') );    
                            accountGDriveLink.add(acc);
                        }else if( opp.RecordType.Name == 'Adfire Health Marketing' ){
                            Account acc = new Account( Id = opp.AccountId, Adfire_Health_Marketing_Drive_Link__c='https://drive.google.com/drive/u/0/folders/'+(String)resBody.get('id') );    
                            accountGDriveLink.add(acc);
                        }
                        fId = (String)resBody.get('id');  
                    }
                } else{
                    fId = folderNameIdMap2.get( opp.Account.Name );
                }
            } 
            // new condition end here
            
            /*if( folderNameIdMap2.containsKey( opp.Account.Name ) && ! folderNameIdMap2.containsKey( opp.Account.Parent.Name )){
String body = '';
if(opp.Account.Parent.Name != null){
body = '{"mimeType" : "application/vnd.google-apps.folder","title":"'+opp.Account.Parent.Name+'","name":"'+opp.Account.Parent.Name+'", "parents":["'+rId+'"]}';
} else{
body = '{"mimeType" : "application/vnd.google-apps.folder","title":"'+opp.Account.Name+'","name":"'+opp.Account.Name+'", "parents":["'+rId+'"]}';
}
req.setBody(body);
req.setMethod('POST');
req.setHeader('Content-Type', 'application/json');
//req.setHeader('Authorization', 'Bearer '+accessToken);
req.setHeader('Accept', 'application/json');
HttpResponse res= h.send(req);
Map<String, Object> resBody = (Map<String, Object>)JSON.deserializeUntyped( res.getBody() );
System.debug(res.getBody());
System.debug(res.getBody());
if( (String)resBody.get('id') != null || (String)resBody.get('id')!='' ){
// opp.Account.Google_Drive_Link__c = 'https://drive.google.com/drive/u/0/folders/'+(String)resBody.get('id');
if( opp.RecordType.Name == 'Adfire Health Recruit' ){
Account acc = new Account( Id = opp.AccountId, Adfire_Health_Recruit_Drive_Link__c='https://drive.google.com/drive/u/0/folders/'+(String)resBody.get('id') );    
accountGDriveLink.add(acc);
}else if( opp.RecordType.Name == 'Adfire Health Marketing' ){
Account acc = new Account( Id = opp.AccountId, Adfire_Health_Marketing_Drive_Link__c='https://drive.google.com/drive/u/0/folders/'+(String)resBody.get('id') );    
accountGDriveLink.add(acc);
}

fId = (String)resBody.get('id');  
}
}else{
if( folderNameIdMap2.containsKey( opp.Account.Name )){
fId = folderNameIdMap2.get( opp.Account.Name );
} else if( folderNameIdMap2.containsKey( opp.Account.Parent?.Name )){
fId = folderNameIdMap2.get( opp.Account.Parent.Name );
}  
}*/
            String subClName = '';
            if( opp.Account.ParentId == null ){
                subClName = opp.Account.Name + ' - Direct';
            } else{
                subClName = opp.Account.Parent.Name +' - '+ opp.Account.Name;
            }
            system.debug('fileId--> '+fId);
            Http h2 = new Http();
            HttpRequest req2 = new HttpRequest();
            //req2.setEndPoint('https://www.googleapis.com/drive/v3/files?q=\''+fId+'\'+in+parents');
            req2.setEndPoint('callout:GoogleDrive/drive/v3/files?q=\''+fId+'\'+in+parents');
            req2.setMethod('GET');
            req2.setHeader('Content-Type', 'application/json');
            //req2.setHeader('Authorization', 'Bearer '+accessToken);
            req2.setHeader('Accept', 'application/json');
            
            HttpResponse resp= h2.send(req2);
            System.debug('RR'+resp.getBody());
            Map<String, Object> resBody2 = (Map<String, Object>)JSON.deserializeUntyped( resp.getBody() );
            List<Object> pFiles = (List<Object>) resBody2.get( 'files' );
            System.debug('resBody2-->  '+resBody2);
            System.debug('pFiles--> '+pFiles);
            Map<String, String> folderNameIdMap = new Map<String, String>(); 
            Set<String> pFolderFileName = new Set<String>();
            for( Object pFile : pFiles ){
                Map<String, Object> pFileMap = (Map<String, Object>)pFile;
                folderNameIdMap.put( (String)pFileMap.get('name'), (String)pFileMap.get('id') );
            }
            if( ! folderNameIdMap.containsKey( subClName ) ){
                String body1 = '{"mimeType" : "application/vnd.google-apps.folder","title":"'+subClName+'","name":"'+subClName+'", "parents":["'+fId+'"]}';
                req.setBody(body1);
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');
                //req.setHeader('Authorization', 'Bearer '+accessToken);
                req.setHeader('Accept', 'application/json');
                HttpResponse res1= h.send(req);
                Map<String, Object> resBody1 = (Map<String, Object>)JSON.deserializeUntyped( res1.getBody() );
                System.debug(res1.getBody());
                if( (String)resBody1.get('id') != null || (String)resBody1.get('id')!='' ){
                    // opp.SubClient_or_Manufacturer__r.Google_Drive_Link__c = 'https://drive.google.com/drive/u/0/folders/'+(String)resBody1.get('id');
                    // Account acc1 = new Account( Id = opp.SubClient_or_Manufacturer__c, Google_Drive_Link__c='https://drive.google.com/drive/u/0/folders/'+(String)resBody1.get('id') );
                    sId = (String)resBody1.get('id');
                    // accountGDriveLink.add(acc1);
                }
            }else{
                sId = folderNameIdMap.get( subClName );
            }
            if( opp.Proposal_Link__c == null ){
                List<String> innerFolders;
                if( opp.RecordType.Name == 'Adfire Health Recruit' ){
                    innerFolders = new List<string>{'Assets', 'Sales', 'Proposals', 'Reports', 'Archive', 'Creatives'};
                        }else if( opp.RecordType.Name == 'Adfire Health Marketing' ){
                            innerFolders = new List<string>{'Target Lists', 'Screenshots', 'Creatives', 'Proposals', 'Archive', 'Reporting'};
                                }
                String body = '{"mimeType" : "application/vnd.google-apps.folder","title":"'+opp.Name+'","name":"'+opp.Name+'", "parents":["'+sId+'"]}';
                req.setBody(body);
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');
                //req.setHeader('Authorization', 'Bearer '+accessToken);
                req.setHeader('Accept', 'application/json');
                HttpResponse res= h.send(req);
                Map<String, Object> resBody = (Map<String, Object>)JSON.deserializeUntyped( res.getBody() );
                System.debug(res.getBody());
                if( (String)resBody.get('id') != null || (String)resBody.get('id')!='' ){
                    String opCId = (String)resBody.get('id');
                    //Inner folders target list, etc.
                    for( String inn : innerFolders ){
                        String body2 = '{"mimeType" : "application/vnd.google-apps.folder","title":"'+inn+' | '+opp.Name+'","name":"'+inn+' | '+opp.Name+'", "parents":["'+opCId+'"]}';
                        req.setBody(body2);
                        req.setMethod('POST');
                        req.setHeader('Content-Type', 'application/json');
                        //req.setHeader('Authorization', 'Bearer '+accessToken);
                        req.setHeader('Accept', 'application/json');
                        HttpResponse res2= h.send(req);
                        if( opp.RecordType.Name == 'Adfire Health Recruit' && inn == 'Creatives' ){
                            List<String> crInn = new List<String>{'Email', 'Direct Mail', 'Display Ads'};
                                resBody2 = (Map<String, Object>)JSON.deserializeUntyped( res2.getBody() );
                            System.debug(res2.getBody());
                            if( (String)resBody2.get('id') != null || (String)resBody2.get('id')!='' ){
                                String opCId2 = (String)resBody2.get('id');
                                //Inner folders target list, etc.
                                for( String crIn : crInn ){
                                    String body3 = '{"mimeType" : "application/vnd.google-apps.folder","title":"'+crIn+' | '+opp.Name+'","name":"'+crIn+' | '+opp.Name+'", "parents":["'+opCId2+'"]}';
                                    req3.setBody(body3);
                                    req3.setMethod('POST');
                                    req3.setHeader('Content-Type', 'application/json');
                                    //req3.setHeader('Authorization', 'Bearer '+accessToken);
                                    req3.setHeader('Accept', 'application/json');
                                    HttpResponse res3 = h2.send(req3);
                                }
                            }
                        }
                        else if( opp.RecordType.Name == 'Adfire Health Marketing' && inn == 'Creatives' ){
                            List<String> crInn = new List<String>{'Pixels'};
                                resBody2 = (Map<String, Object>)JSON.deserializeUntyped( res2.getBody() );
                            System.debug(res2.getBody());
                            if( (String)resBody2.get('id') != null || (String)resBody2.get('id')!='' ){
                                String opCId2 = (String)resBody2.get('id');
                                //Inner folders target list, etc.
                                for( String crIn : crInn ){
                                    String body3 = '{"mimeType" : "application/vnd.google-apps.folder","title":"'+crIn+' | '+opp.Name+'","name":"'+crIn+' | '+opp.Name+'", "parents":["'+opCId2+'"]}';
                                    req3.setBody(body3);
                                    req3.setMethod('POST');
                                    req3.setHeader('Content-Type', 'application/json');
                                    //req3.setHeader('Authorization', 'Bearer '+accessToken);
                                    req3.setHeader('Accept', 'application/json');
                                    HttpResponse res3 = h2.send(req3);
                                }
                            }
                        }
                        else if( opp.RecordType.Name == 'Adfire Health Marketing' && inn == 'Reporting' ){
                            List<String> crInn = new List<String>{'HCP Reports'};
                                resBody2 = (Map<String, Object>)JSON.deserializeUntyped( res2.getBody() );
                            System.debug(res2.getBody());
                            if( (String)resBody2.get('id') != null || (String)resBody2.get('id')!='' ){
                                String opCId2 = (String)resBody2.get('id');
                                //Inner folders target list, etc.
                                for( String crIn : crInn ){
                                    String body3 = '{"mimeType" : "application/vnd.google-apps.folder","title":"'+crIn+' | '+opp.Name+'","name":"'+crIn+' | '+opp.Name+'", "parents":["'+opCId2+'"]}';
                                    req3.setBody(body3);
                                    req3.setMethod('POST');
                                    req3.setHeader('Content-Type', 'application/json');
                                    //req3.setHeader('Authorization', 'Bearer '+accessToken);
                                    req3.setHeader('Accept', 'application/json');
                                    HttpResponse res3 = h2.send(req3);
                                }
                            }
                        }
                        else if( inn == 'Proposals' ){
                            resBody2 = (Map<String, Object>)JSON.deserializeUntyped( res2.getBody() );
                            System.debug(res2.getBody());
                            if( (String)resBody2.get('id') != null || (String)resBody2.get('id')!='' ){
                                String opCId2 = (String)resBody2.get('id');
                                opp.Proposal_Link__c = 'https://drive.google.com/drive/u/0/folders/'+opCId2;
                            }
                        }
                        
                    }
                    opp.Drive_Link__c = 'https://drive.google.com/drive/u/0/folders/'+(String)resBody.get('id');
                }
            }
        }
        UPDATE accountGDriveLink;
        UPDATE opps;
    }
    public void finish( Database.BatchableContext bc ){
        
    }
}