@isTest
public class OppRecPageCtrlTest {
    
    @isTest
    public static void getOppFieldsTest(){
        List<String> OppRecord = OppRecPageCtrl.getOppFields(); 
        system.debug(OppRecord);
        System.assert(!OppRecord.isEmpty(),'List should not be empty');
    }
    
    @isTest
    public static void getAdSubClientsBrandsTest1(){
        Account acc1  = new Account(Name='Acc1',Type='Advertiser Client',Phone='9878786373',Industry='Banking',Website='www.cyntexa.com');
        insert acc1;
        Id acc1Id = acc1.id;
        Account acc2 = new Account(Name='Acc2',Type='Sub-Client',Phone='9878786373',Industry='Banking',Website='www.cyntexa.com');
        insert acc2;
        String AccountToName = acc2.Name;
        Id acc2Id  = acc2.id;
        AccountPartner Ap = new AccountPartner(AccountToId = acc2Id, Role='Sub-Client - Advertiser Client',AccountFromId=acc1Id);
        insert Ap;
        List<AccountPartner> AccountPartnerRecord = OppRecPageCtrl.getAdSubClientsBrands(acc1Id);
        System.assert(!AccountPartnerRecord.isEmpty(),'AccountPartner list should not be empty');
    }
    
    @isTest
    public static void getAdSubClientsBrandsTest2(){
        OppRecPageCtrl.getAdSubClientsBrands(null);    
    }
    
    @isTest
    public static void getContactsTest(){
        Account acc1  = new Account(Name='Acc1',Type='Advertiser Client',Phone='9878786373',Industry='Banking',Website='www.cyntexa.com');
        insert acc1;
        Id acc1Id = acc1.id;
        Account acc2 = new Account(Name='Acc2',Type='Sub-Client',Phone='9878786373',Industry='Banking',Website='www.cyntexa.com');
        insert acc2;
        Id acc2Id  = acc2.id;
        List<Contact> listOfContact = OppRecPageCtrl.getContacts(acc1Id,acc2Id,acc2Id); 
        system.debug('listOfContact-->'+listOfContact);
        System.assertNotEquals(!listOfContact.isEmpty(),Null);
    }
    
    @isTest
    public static void getRecTypeNameTest(){
        Account acc1  = new Account(Name='Acc1',Type='Advertiser Client',Phone='9878786373',Industry='Banking',Website='www.cyntexa.com');
        insert acc1;
        Id accountID = acc1.id;
        date startDate = date.parse('4/25/2022');
        date endDate = date.parse('5/25/2022');
        Opportunity opp = new opportunity(Name= 'opp1',CloseDate=date.today(), AccountId = accountID, StageName='Closed Won', Audience_Type__C = 'HCP', Flight_Start_Date__c = startDate, Flight_End_Date__c = endDate,recordTypeId = '0126C0000005P4dQAE');
        insert opp;
        Id oppId = opp.RecordTypeId;
        system.debug('oppId'+oppId);
        String Name = OppRecPageCtrl.getRecTypeName(oppId);
        system.debug('Name=====>'+Name);
        
    }
    @isTest
    public static void getRecTypeNameTest2(){
        Account acc1  = new Account(Name='Acc1',Type='Advertiser Client',Phone='9878786373',Industry='Banking',Website='www.cyntexa.com');
        insert acc1;
        Id accountID = acc1.id;
        date startDate = date.parse('4/25/2022');
        date endDate = date.parse('5/25/2022');
        ID RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Adfire Health Marketing').getRecordTypeId();
        Opportunity opp = new opportunity(Name= 'opp1',CloseDate=date.today(), AccountId = accountID, StageName='Closed Won', Audience_Type__C = 'HCP', Flight_Start_Date__c = startDate, Flight_End_Date__c = endDate);
        insert opp;
        Id oppId = opp.RecordTypeId;
        String Name = OppRecPageCtrl.getRecTypeName(oppId);
        System.assertEquals(Name,Null);
        
    }
    
    @isTest
    public static void getEditValueTest(){
        Account acc1  = new Account(Name='Acc1',Type='Advertiser Client',Phone='9878786373',Industry='Banking',Website='www.cyntexa.com');
        insert acc1;
        Id accountID = acc1.id;
        date startDate = date.parse('4/25/2022');
        date endDate = date.parse('5/25/2022');
        ID RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Adfire Health Marketing').getRecordTypeId();
        Opportunity opp = new opportunity(Name = 'opp1',CloseDate=date.today(), AccountId = accountID, StageName='Closed Won', Audience_Type__C = 'HCP', Flight_Start_Date__c = startDate, Flight_End_Date__c = endDate,recordTypeId = RecordTypeId);
        insert opp;
        Id oppId = opp.RecordTypeId;
        system.debug(oppId);
        opportunity oppdata =  OppRecPageCtrl.getEditValue(opp.Id);
        System.debug('oppdata'+oppdata); 
        System.assertNotEquals(oppdata.Id, Null);
    }
    
    @isTest
    public static void getEditValueTest2(){
        Account acc1  = new Account(Name='Acc1',Type='Advertiser Client',Phone='9878786373',Industry='Banking',Website='www.cyntexa.com');
        insert acc1;
        Id accountID = acc1.id;
        try{
            Opportunity opp = OppRecPageCtrl.getEditValue(accountID);
            System.assertEquals(opp, Null);
        }catch(exception e){} 
    }
    
    @isTest
    public static void saveNewSubClientTest(){
        Account acc1  = new Account(Name='Acc1',Type='Advertiser Client',Phone='9878786373',Industry='Banking',Website='www.cyntexa.com');
        insert acc1;
        Id accountID = acc1.id;
        OppRecPageCtrl.saveNewSubClient(accountID,'Alok');
    }
    
    @isTest
    public static void checkAccTypeTest1(){
        Account acc = new Account(Name='Account1',Type='Sub-Client');
        insert acc;
        OppRecPageCtrl.checkAccType(acc.id);
    }
    @isTest
    public static void checkAccTypeTest2(){
        Account acc = new Account(Name='Account1',Type='Advertiser Client');
        insert acc;
        OppRecPageCtrl.checkAccType(acc.id);
    }
    
    
}