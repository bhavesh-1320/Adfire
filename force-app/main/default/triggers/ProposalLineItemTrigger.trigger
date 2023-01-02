trigger ProposalLineItemTrigger on QuoteLineItem (after insert, after update, after delete) {
    if( Trigger.isAfter ){
        if( Trigger.isInsert || Trigger.isUpdate ){
       		 ProposalLineItemTriggerHelper.addTotalPrice( Trigger.new );     
        }else if( Trigger.isDelete ){
            ProposalLineItemTriggerHelper.addTotalPrice( Trigger.old );     
        }
    }
}