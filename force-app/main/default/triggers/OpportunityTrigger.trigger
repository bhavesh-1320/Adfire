trigger OpportunityTrigger on Opportunity (after insert, after update, before insert, before Update) {
    if( Trigger.isBefore ){
        if( Trigger.isInsert ){
            Map<String, Id> rTypeMap = new Map<String, Id>();
            Map<Id, String> rTypeIdMap = new Map<Id, String>();
            for( RecordType rType : [SELECT Id, Name FROM RecordType WHERE 
                                     Name = 'Adfire Health Recruit' OR 
                                     Name = 'Adfire Health Marketing'
                                    ] ){
                rTypeMap.put( rType.Name, rType.Id );
				rTypeIdMap.put( rType.Id, rType.Name );
            }
            
            Map<String, Id> pTypeMap = new Map<String, Id>();
            for( Pricebook2 rType : [SELECT Id, Name FROM Pricebook2 WHERE 
                                     Name = 'Adfire Health Recruit - HCP' OR 
                                     Name = 'Adfire Health Marketing - HCP' OR
                                     Name = 'Adfire Health Marketing - Consumer' OR
                                     Name = 'Adfire Health Marketing - HCP'
                                    ] ){
                pTypeMap.put( rType.Name, rType.Id );
            }
            for( Opportunity opp : Trigger.new ){
                if( opp.Primary_KPI__c == 'CPA' || opp.Primary_KPI__c == 'Time Spent/Bounce Rate/Pageviews' || opp.Primary_KPI__c == 'CPA + CTR' || opp.Primary_KPI__c == 'CTR/Landing Page' ||
                   opp.Primary_KPI__c == 'Views - Landing Page' || opp.Primary_KPI__c == 'CPC + CPA' || opp.Primary_KPI__c == 'CPA + CPL'
                  ){
                      opp.TTD_Conversion_Goal__c = 'Conversion';
                  } 
                else if( opp.Primary_KPI__c == 'CPC' || opp.Primary_KPI__c == 'Clicks' || opp.Primary_KPI__c == 'Video Completions' || opp.Primary_KPI__c == 'Audio Completions' ||
                        opp.Primary_KPI__c == 'CTR - 0.15%' || opp.Primary_KPI__c == 'CTR + Viewability' || opp.Primary_KPI__c == 'CTR + Reach' || opp.Primary_KPI__c == 'CPC + Reach/Match Rates' ||
                        opp.Primary_KPI__c == 'CTR + Deliverability' || opp.Primary_KPI__c == 'CTR' || opp.Primary_KPI__c == 'VCR'
                       ){
                           opp.TTD_Conversion_Goal__c = 'Consideration';
                       }
                else if( opp.Primary_KPI__c == 'Deliver in FULL' || opp.Primary_KPI__c == 'Reach/High Match' ){
                    opp.TTD_Conversion_Goal__c = 'Awareness';
                }
                if( opp.Business_Type__c != null ){
                    if( rTypeMap.containsKey( opp.Business_Type__c ) )
                    opp.RecordTypeId = rTypeMap.get( opp.Business_Type__c );
                }
                if( opp.RecordTypeId != null && opp.Audience_Type__c != null ){
                    if( rTypeIdMap.containsKey( opp.RecordTypeId ) ){
                    	String pName = rTypeIdMap.get( opp.RecordTypeId );
                        if( pTypeMap.containsKey( pName+ ' - ' + opp.Audience_Type__c ) )	
                            opp.Pricebook2Id = pTypeMap.get( pName+ ' - ' + opp.Audience_Type__c );
                    }
                    
                }
                if( opp.StageName == 'Verbal' ){
                    opp.addError( 'Please add at least one product' );
                }
            }
        }else if( Trigger.isUpdate ){
            Map<Id, String> rTypeIdMap = new Map<Id, String>();
            for( RecordType rType : [SELECT Id, Name FROM RecordType WHERE 
                                     Name = 'Adfire Health Recruit' OR 
                                     Name = 'Adfire Health Marketing'
                                    ] ){
                rTypeIdMap.put( rType.Id, rType.Name );
            }
            Map<String, Id> pTypeMap = new Map<String, Id>();
            for( Pricebook2 rType : [SELECT Id, Name FROM Pricebook2 WHERE 
                                     Name = 'Adfire Health Recruit - HCP' OR 
                                     Name = 'Adfire Health Marketing - HCP' OR
                                     Name = 'Adfire Health Marketing - Consumer' OR
                                     Name = 'Adfire Health Marketing - HCP'
                                    ] ){
                pTypeMap.put( rType.Name, rType.Id );
            }
            Map<Id, Integer> oppProds = new Map<Id, Integer>();
            Map<Id, Integer> oppSegs = new Map<Id, Integer>();
            for( Opportunity opp : [SELECT Id, (SELECT Id FROM OpportunityLineItems), (SELECT Id FROM Opportunity_Segments__r) FROM Opportunity 
                                    WHERE Id IN :Trigger.NewMap.keySet() 
                                    ] ){
                                        System.debug('==>'+oppProds);
                                        if( !oppProds.containsKey( opp.id ) ){
                                            oppProds.put( opp.Id, 0 );
                                        }
                                        if( !oppSegs.containsKey( opp.id ) ){
                                            oppSegs.put( opp.Id, 0 );
                                        }
                                        System.debug('==>'+oppProds);
                                        System.debug(opp.OpportunityLineItems);
                                        if( opp.OpportunityLineItems.size() > 0 ){
                                            oppProds.put( opp.Id, opp.OpportunityLineItems.size() );   
                                        }
                                        if(opp.Opportunity_Segments__r.size() > 0){
                                            oppSegs.put(opp.Id, opp.Opportunity_Segments__r.size());
                                        }
            }
            System.debug('Ou:'+oppProds);
            for( Id recId : Trigger.newMap.keySet() ){
                Opportunity opp = Trigger.newMap.get( recId );
                if( opp.Primary_KPI__c == 'CPA' || opp.Primary_KPI__c == 'Time Spent/Bounce Rate/Pageviews' || opp.Primary_KPI__c == 'CPA + CTR' || opp.Primary_KPI__c == 'CTR/Landing Page' ||
                   opp.Primary_KPI__c == 'Views - Landing Page' || opp.Primary_KPI__c == 'CPC + CPA' || opp.Primary_KPI__c == 'CPA + CPL'
                  ){
                      opp.TTD_Conversion_Goal__c = 'Conversion';
                  } 
                else if( opp.Primary_KPI__c == 'CPC' || opp.Primary_KPI__c == 'Clicks' || opp.Primary_KPI__c == 'Video Completions' || opp.Primary_KPI__c == 'Audio Completions' ||
                        opp.Primary_KPI__c == 'CTR - 0.15%' || opp.Primary_KPI__c == 'CTR + Viewability' || opp.Primary_KPI__c == 'CTR + Reach' || opp.Primary_KPI__c == 'CPC + Reach/Match Rates' ||
                        opp.Primary_KPI__c == 'CTR + Deliverability' || opp.Primary_KPI__c == 'CTR' || opp.Primary_KPI__c == 'VCR'
                       ){
                           opp.TTD_Conversion_Goal__c = 'Consideration';
                       }
                else if( opp.Primary_KPI__c == 'Deliver in FULL' || opp.Primary_KPI__c == 'Reach/High Match' ){
                    opp.TTD_Conversion_Goal__c = 'Awareness';
                }
                
                if( Trigger.newMap.get( recId ).Audience_Type__c != null &&
                  	( Trigger.newMap.get( recId ).Audience_Type__c != Trigger.oldMap.get( recId ).Audience_Type__c )
                  ){
                      if( rTypeIdMap.containsKey( Trigger.newMap.get( recId ).RecordTypeId ) ){
                          String pName =  rTypeIdMap.get( Trigger.newMap.get( recId ).RecordTypeId );
                          System.debug('pName:'+pName+' - ' + Trigger.newMap.get( recId ).Audience_Type__c );
                          if( pTypeMap.containsKey( pName+ ' - ' + Trigger.newMap.get( recId ).Audience_Type__c ) )	
                              Trigger.newMap.get( recId ).Pricebook2Id = pTypeMap.get( pName+ ' - ' + Trigger.newMap.get( recId ).Audience_Type__c );   
                      }
                }
                
                if( Trigger.newMap.get( recId ).stageName == 'Verbal' && 
                   Trigger.oldMap.get( recId ).stageName != 'Verbal' ){
                       if( oppProds.containsKey( recId )){
                           System.debug('-->'+oppProds);
                           if( oppProds.get( recId ) < 1 ){
                        		Trigger.newMap.get( recId ).addError( 'Please add at least one product' );       
                           }
                       }
                       if( oppSegs.containsKey( recId ) ){
                           if(oppSegs.get( recId ) < 1){
                               Trigger.newMap.get( recId ).addError( 'Please add at least one Opportunity Segment' );       
                           }
                       }
                }
            }
        }
    } 
    else if( Trigger.isAfter ){
        if( Trigger.isInsert ){
            List<Opportunity> opps = new List<Opportunity>();
            Set<Id> oppId = new Set<Id>();
            for( Opportunity opp : Trigger.new ){
                if( opp.StageName == 'Verbal' ){
                    opps.add( opp );
                    oppId.add( opp.Id );
                }
            }
            OppTriggerHelper.createIos( opps, oppId );
        }else if( Trigger.isUpdate ){
            List<Opportunity> opps = new List<Opportunity>();
            Set<Id> oppId = new Set<Id>();
            for( Id recId : Trigger.newMap.keySet() ){
                if( Trigger.newMap.get( recId ).stageName == 'Verbal' && 
                   Trigger.oldMap.get( recId ).stageName != 'Verbal' ){
                    opps.add( Trigger.newMap.get( recId ) );
                    oppId.add( recId );
                }
            }
            OppTriggerHelper.createIos( opps, oppId );
        }
    }
}