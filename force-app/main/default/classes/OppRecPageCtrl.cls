public with sharing class OppRecPageCtrl {
    
    @AuraEnabled
    public static Boolean checkAccType( Id accId ){
        try {
            List<Account> acc = [SELECT Id, Type FROM Account WHERE Id = :accId];
            if( acc.size() > 0 ){
                if( acc[0].Type == 'Advertiser Client' ){    
                    return true;
                }
            }
                return false;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<String> getOppFields(){
        SObjectType contactType = Schema.getGlobalDescribe().get('Opportunity');
        Map<String,Schema.SObjectField> mfields = contactType.getDescribe().fields.getMap();

        List<String> sObjectDetailsList = new List<String>();
        System.debug( mfields );
        for(String s : mfields.keySet()){
            String fApiName = String.valueOf(mfields.get(s));
            if( fApiName != 'Id' && fApiName != 'IsDeleted' && fApiName != 'RecordTypeId' && fApiName != 'IsPrivate' && fApiName != 'RecordTypeId' && fApiName != 'IsWon' && fApiName != 'IsClosed'
            && fApiName != 'Fiscal' && fApiName != 'FiscalYear'&& fApiName != 'FiscalQuarter'&& fApiName != 'LastStageChangeDate'&& fApiName != 'PushCount'&& fApiName != 'LastActivityDate'&& fApiName != 'SystemModstamp'&& fApiName != 'LastModifiedById'
            && fApiName != 'LastModifiedDate'&& fApiName != 'CreatedById' && fApiName != 'CreatedDate'&& fApiName != 'OwnerId'&& fApiName != 'Pricebook2Id'&& fApiName != 'HasOpportunityLineItem' && fApiName != 'HasOpenActivity' && fApiName != 'SyncedQuoteId'
            && fApiName != 'LastReferencedDate' && fApiName != 'LastViewedDate' && fApiName != 'LastCloseDateChangedHistoryId'&& fApiName != 'LastAmountChangedHistoryId' && fApiName != 'IqScore' && fApiName != 'HasOverdueTask'&& fApiName != 'ForecastCategory'&& fApiName != 'ContactId'
            && fApiName != 'SubClient_or_Manufacturer__c' && fApiName != 'Advertiser_Client__c'&& fApiName != 'Brand__c'
            )
            sObjectDetailsList.add(String.valueOf(mfields.get(s)));
        }
        return sObjectDetailsList;
    }
    // adId = account with type advertiser client
    // AccountToId = account with type subclient
    @AuraEnabled
    public static List<AccountPartner> getAdSubClientsBrands( Id adId ){
        if(adId != null)
        return [SELECT AccountToId, Role, AccountTo.Name FROM AccountPartner WHERE AccountFromId = :adId];
        else {
            return null;
        }
    }
    @AuraEnabled
    public static List<Contact> getContacts( Id adId, Id subId, Id bId ){
        return [SELECT Name, Id FROM Contact WHERE AccountId = :adId OR AccountId = :subId OR AccountId = :bId];
    }
    //Opp record Id
    @AuraEnabled
    public static String getRecTypeName( Id recId ){
        if( recId != null )
            return [SELECT Name, DeveloperName
            FROM RecordType
            WHERE Id = :recId].DeveloperName;
        else    return null;
    }
    @AuraEnabled
    public static Opportunity getEditValue( Id recId ){
        try {   
            if( recId != null ){
                return [ SELECT RecordTypeId, SubClient_or_Manufacturer__c, AccountId, Direct__c,
                        Primary_Contact__c, Brand__c, Audience_Type__c, Target_Geo_Type__c, Loss_Reason__c
                        FROM Opportunity WHERE Id = :recId
                        ];
            }else   return null;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static string saveNewSubClient( Id accId, String subName ){
        try {
            Account acc = new Account( Name = subName, Type='Sub-Client' );
            INSERT acc;
            AccountPartner accP = new AccountPartner( AccountFromId = accId, AccountToId = acc.Id, Role = 'Sub-Client - Advertiser Client' );
            INSERT accP;
            return 'Success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}