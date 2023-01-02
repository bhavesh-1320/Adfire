trigger IOInvoiceTrigger on Invoice__c (after insert, after update) {
    if(!IOInvoiceTriggerHelper.firstcall){
        IOInvoiceTriggerHelper.firstcall = true;
        Set<Id> ivIds = new Set<Id>();
        if( Trigger.isAfter ){
            if( Trigger.isInsert ){
                //IOInvoiceTriggerHelper.createSegments( Trigger.NewMap );
                Set<Id> invIds = new Set<Id>();
                for(Invoice__c inv : trigger.new){
                    invIds.add(inv.Id);
                }
            }
            else if( Trigger.isUpdate ){
                /*for(Id iv : trigger.newMap.keyset()){
                    if(trigger.newMap.get(iv).PO_Number__c != trigger.oldMap.get(iv).PO_Number__c){
                        ivIds.add(iv);
                    }
                }
                IOInvoiceTriggerHelper.updateIOInvoicesPONumber(ivIds);*/
            }
        }
    }
}