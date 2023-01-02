public class Opp_RequestforProposal_class {
    public static boolean show{get;set;}
     Public Id OpporId {get;set;}
    String oppName{get;set;}
      Public Opp_RequestforProposal_class(ApexPages.StandardController controller) {
        Opportunity Opp = (Opportunity)controller.getRecord();
        system.debug('Opportunity'+Opp.Id);
        OpporId = Opp.Id; 
          oppName = [SELECT name FROM Opportunity WHERE Id = :OpporId].Name;
          show = false;
        system.debug(OpporId);
    }
    
    public string strImageBlob {get;set;}
    
    public void AddDocument()
    {
        System.debug('Hello');
        ContentVersion cv = new ContentVersion();
        cv.Title = 'RFP : '+oppName+' : '+Datetime.now();
        cv.PathOnClient = 'Document.png';
        cv.VersionData = EncodingUtil.base64Decode(strImageBlob.replaceFirst('data:image/png;base64,',''));
        cv.IsMajorVersion = true;
        Insert cv;
        
        
        //Get Content Documents
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
        
        //Create ContentDocumentLink 
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = OpporId;
        cdl.ContentDocumentId = conDocId;
        cdl.shareType = 'V';
        Insert cdl;
        
        System.debug('-->'+cdl+'Done');
    }

    

}