trigger ProposalTrigger on Quote (before insert, before update, after insert, after update) {
    if( Trigger.isAfter ){
        /*if( Trigger.isInsert || Trigger.isUpdate ){
            	ProposalTriggerHelper.createIO( Trigger.new );
        }*/
        if( Trigger.isInsert ){
            ProposalTriggerHelper.createProposalInvoices( Trigger.new );
        } else if( Trigger.isUpdate ){
            ProposalTriggerHelper.createIO(Trigger.new, Trigger.oldMap);
        }
    }
    /*if( Trigger.isBefore ){
        if( Trigger.isInsert ){
            for( Quote q : Trigger.New ){
                if( q.Budget_Confirmed__c == true ){
                    DateTime dt = q.Flight_Start_Date__c;
                    Date d = Date.newInstance(dt.year(), dt.month(), dt.day());
                    q.Invoice_Creation_Date__c = d;
                }else{
                    q.Invoice_Creation_Date__c = null;
                }
            }
        } else if( Trigger.isUpdate ){
            for( Quote q : Trigger.New ){
                if( Trigger.newMap.get(q.Id).Budget_Confirmed__c == true && Trigger.oldMap.get(q.Id).Budget_Confirmed__c == false ){
                    DateTime dt = q.Flight_Start_Date__c;
                    Date d = Date.newInstance(dt.year(), dt.month(), dt.day());
                    q.Invoice_Creation_Date__c = d;
                }else if(Trigger.newMap.get(q.Id).Budget_Confirmed__c  == false){
                    q.Invoice_Creation_Date__c = null;
                }
            }
        }
    }*/
}