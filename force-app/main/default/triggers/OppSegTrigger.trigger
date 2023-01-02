trigger OppSegTrigger on Opportunity_Segment__c (after insert, after update, after delete) {
    if( Trigger.isAfter ){
        if( Trigger.isInsert ){
			OppSegTriggerHelper.createAudienceInIterable( Trigger.NewMap.keySet() );            
			OppSegTriggerHelper.updateOppAud( Trigger.New );
            OppSegTriggerHelper.updateIOAud( Trigger.New );
        }else if( Trigger.isUpdate ){
            OppSegTriggerHelper.updateOppAud( Trigger.New );
            OppSegTriggerHelper.updateIOAud( Trigger.New );
        }else if( Trigger.isDelete ){
            OppSegTriggerHelper.updateOppAud( Trigger.old );
            OppSegTriggerHelper.updateIOAud( Trigger.New );
        }
    }
}