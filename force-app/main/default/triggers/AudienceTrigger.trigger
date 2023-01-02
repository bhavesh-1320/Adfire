trigger AudienceTrigger on Audience__c (after insert, after update) {
    if( Trigger.isAfter ){
        if( Trigger.isUpdate || Trigger.isInsert ){}
	        //AudienceTriggerHelper.createAudienceInIterable( Trigger.NewMap.keySet() );
    }
}