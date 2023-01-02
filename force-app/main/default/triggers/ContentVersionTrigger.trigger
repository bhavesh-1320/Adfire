trigger ContentVersionTrigger on ContentVersion (after insert) {
    Set<Id> cvIdSet = new Set<Id>();
    for(ContentVersion cv : trigger.new){
            cvIdSet.add(cv.id);
    }
    uploadFileToDriveBatch callbatch = new uploadFileToDriveBatch(cvIdSet);
    //Database.executeBatch(callbatch, 1);
}