trigger ContractTrigger on Contract (after insert, after update) {
    
    if( Trigger.isAfter ){
        if(  Trigger.isInsert ){
            List<Id> ioIdss = new List<Id>();
            ioIdss.addAll( Trigger.newMap.keySet() );
            Database.executeBatch(new CreateGDriveBatch( ioIdss, 'IO' ), 5);
            Set<Id> cotractIds = new Set<Id>();
            if( !CreateBoardBatch.cStart ){
                Set<Id> ioIds = new Set<Id>();
                for( Contract io : Trigger.New ){
                    if( io.Status == 'Accepted' ){
                          ioIds.add( io.Id );
                      }
                }
                //Database.executeBatch(new CreateBoardBatch( ioIds ), 5);
                Database.executeBatch(new CreateTTDAccs( ioIds ), 10);    
            }
            for(Contract io : Trigger.new){
                if(io.PO_Number__c != null){
                    cotractIds.add(io.Id);
                }
            }
            ContractTriggerHelper.updateIOInvoicesPONumber(cotractIds);
        } else if( Trigger.isUpdate ){
            if( !CreateBoardBatch.cStart ){
                Set<Id> ioIds = new Set<Id>();
                for( Id ioId : Trigger.NewMap.keySet() ){
                    if( Trigger.oldMap.get( ioId ).Status != Trigger.newMap.get( ioId ).Status &&
                       Trigger.newMap.get( ioId ).Status == 'Accepted'
                      ){
                          ioIds.add( ioId );
                      }
                }
                //Database.executeBatch(new CreateBoardBatch( ioIds ), 5);
                Database.executeBatch(new CreateTTDAccs( ioIds ), 10);    
            }
            Set<Id> cotractIds = new Set<Id>();
            for(Id iv : trigger.newMap.keyset()){
                    if(trigger.newMap.get(iv).PO_Number__c != trigger.oldMap.get(iv).PO_Number__c){
                        cotractIds.add(iv);
                    }
                }
            ContractTriggerHelper.updateIOInvoicesPONumber(cotractIds);
        }    
        
    }
}