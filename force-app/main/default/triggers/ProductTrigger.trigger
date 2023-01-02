trigger ProductTrigger on Product2 (after insert, after Update) {
    if( Trigger.isAfter && productTriggerHelper.start ){
        if( Trigger.isInsert )
        productTriggerHelper.createProdInQb( Trigger.NewMap.keySet() );
    }
}