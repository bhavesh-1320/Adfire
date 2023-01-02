trigger ContentDocumentLinkTrigger on ContentDocumentLink (after insert) {
	uploadFileToDriveBatch callbatch = new uploadFileToDriveBatch(Trigger.NewMap.KeySet());
    Database.executeBatch(callbatch, 1);
}