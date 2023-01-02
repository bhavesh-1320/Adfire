trigger IOInvoiceLineItemTrigger on Invoice_Line_Item__c (after insert) {
    if( Trigger.isAfter ){
        if( Trigger.isInsert ){
            IOInvoiceLineItemTriggerHelper.createSegments( Trigger.NewMap );
			IOInvoiceLineItemTriggerHelper.createInvoiceINQB( Trigger.New );    
            if( IOInvoiceLineItemTriggerHelper.start == false ){
                IOInvoiceLineItemTriggerHelper.createLineItemInNextInv( Trigger.NewMap );
            }
        }        
    }
}