public class CreateCampaignToExt {
    public CreateCampaignToExt( ApexPages.StandardController sc ){
        
    }
    public PageReference createIterableCampaign(){
        Id ioId = ApexPages.currentPage().getparameters().get('id');
        Database.executeBatch(new CreateCampaignToExtBatch( [SELECT Id, IO__r.ContractNumber, IO__r.Campaign_Name__c, 
                                                             ( SELECT Product__r.Name, Iterable_Campaign_Id__c FROM Invoice_Line_Items__r ) 
                                                             FROM Invoice__c WHERE IO__c = :ioId
                                                            ] ), 5);
        return new PageReference( '/lightning/r/contract/'+ioId+'/view' );
    }
}