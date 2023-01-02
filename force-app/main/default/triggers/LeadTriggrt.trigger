trigger LeadTriggrt on Lead (before insert) {
    if( Trigger.isBefore ){
        if( Trigger.isInsert ){
            LeadTriggerHelper.checkDupLead( Trigger.New );
        }
    }
}