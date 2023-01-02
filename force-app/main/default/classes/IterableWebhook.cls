/*
	This class is used to fetch leads history from iterable
*/
@RestResource( urlMapping='/getLeadHistory' )
global class IterableWebhook {
    @HttpPost
    global static void testAccount(){
        try{
            RestRequest req = RestContext.request;
            Blob body = req.requestBody;
            String requestString = body.toString();
            //Now as you have the request string You can parse it in APex
            System.debug(requestString);
            Map<string, Object> rw = (Map<string, Object>)JSON.deserializeUntyped(requestString);
            System.debug(rw);
            if( rw.containsKey( 'email' ) && rw.containsKey( 'eventName' ) ){
                String eName = (String)rw.get( 'eventName' );
                String email = (String)rw.get( 'email' );
                system.debug('Email==>'+email);
                List<Lead> leadRec = [SELECT Id, OwnerId FROM Lead WHERE Email = :email];
                system.debug('leadRec===>'+leadRec);
                if( leadRec.size() > 0 ){
                    if( eName == 'emailUnSubscribe' || eName == 'emailSubscribe' ){
                        if( rw.containsKey( 'dataFields' ) ){
                            Map<String, Object> dataFieldMap = ( Map<String, Object> )rw.get( 'dataFields' );
                            if( dataFieldMap.containsKey('channelIds') ){
                                List<Object> cIds = (List<Object>)dataFieldMap.get( 'channelIds' );
                                if( cIds.size() > 0 ){
                                    Integer cId = (Integer)cIds[0];
                                    Http h = new Http();
                                    HttpRequest req1 = new HttpRequest();
                                    req1.setEndpoint( 'https://api.iterable.com/api/channels' );
                                    req1.setMethod( 'GET' );
                                    req1.setHeader( 'API_Key', '1789943a29aa48a7870cf3f1de85152f' );
                                    HttpResponse res = h.send(req1);
                                    Map<String, Object> channelResMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                                    System.debug('-->'+channelResMap);
                                    if( channelResMap.containsKey( 'channels' ) ){
                                    	List<Object> channels = (List<Object>)channelResMap.get( 'channels' );
                                        for( Object channel : channels ){
                                            Map<String, Object> channelMap = (Map<String, Object>)channel;
                                            Integer channelId = (Integer)channelMap.get( 'id' );
                                            if( channelId == cId ){
                                                Event newTask = new Event();
                                                newTask.OwnerId = leadRec[0].OwnerId;
                                                newTask.WhoId = leadRec[0].Id;
                                                newTask.Subject = (String)channelMap.get( 'name' );
                                                if( eName == 'emailUnSubscribe' )	newTask.Subject+=' Unsubscribe';
                                                else	newTask.Subject+=' Subscribe';
                                                newTask.StartDateTime = DateTime.now();
                                                newTask.EndDateTime = DateTime.now();
                                                INSERT newTask;
                                                break;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }else{
                    	Event newTask = new Event();
                        newTask.OwnerId = leadRec[0].OwnerId;
                        newTask.WhoId = leadRec[0].Id;
                        newTask.Subject = (String)rw.get( 'eventName' );
                        newTask.StartDateTime = DateTime.now();
                        newTask.EndDateTime = DateTime.now();
                        INSERT newTask; 	   
                    }
                }
            }
        }catch(Exception e){
            System.debug(e);
        }
    }
}