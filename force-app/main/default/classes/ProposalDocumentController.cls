public class ProposalDocumentController {

    public ProposalDocumentController(ApexPages.StandardController controller) {}

    public Id RecordId {get;set;}    
    public List<OpportunityLineItem> results{get;set;}
    
    
    public pageReference getProcessing()
    {
        return null;
    }
    
    public PageReference getResourceList() {
        RecordId  = ApexPages.currentPage().getParameters().get('id');
        System.debug('RecordId'+RecordId);
        results =[SELECT Id, OpportunityId, Product2Id, Name, TotalPrice, UnitPrice, ListPrice FROM OpportunityLineItem Where OpportunityId =:RecordId];
       /* results = Database.query(
            'SELECT Id, OpportunityId, Product2Id, Name, TotalPrice, UnitPrice, ListPrice FROM OpportunityLineItem' + 
            'Where OpportunityId =RecordId'
        );*/
        
        Apexpages.currentPage().getHeaders().put('content-disposition', 'attachment; filename=YourFileName.pdf'); 
        return null;
    }
}