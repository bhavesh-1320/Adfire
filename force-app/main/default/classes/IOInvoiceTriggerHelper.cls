public class IOInvoiceTriggerHelper {
    public static Boolean firstcall=false;
    public static void createSegments( Map<Id, Invoice__c> invsMap ){
        Set<Id> oppIds = new Set<ID>();
        List<Invoice__c> invs = [SELECT IO__r.Opportunity__c FROM Invoice__c WHERE Id IN :invsMap.keySet()];
        for( Invoice__c inv : invs ){
            oppIds.add( inv.IO__r.Opportunity__c );
        }
        Map<Id, List<Opportunity_Segment__c> > oppIdSegMap = new Map<Id, List<Opportunity_Segment__c> >();
        for( Opportunity opp : [SELECT Id, ( SELECT Segment__c, Opportunity__c, IO_Invoice__c FROM Opportunity_Segments__r ) 
                                FROM Opportunity WHERE ID IN :oppIds] ){
                                    oppIdSegMap.put( opp.Id, opp.Opportunity_Segments__r );
                                }
        List<Opportunity_Segment__c> newSegs = new List<Opportunity_Segment__c>();
        for( Invoice__c inv : invs ){
            if( oppIdSegMap.containsKey( inv.IO__r.Opportunity__c ) ){
                for( Opportunity_Segment__c oppSeg : oppIdSegMap.get(inv.IO__r.Opportunity__c) ){
                    Opportunity_Segment__c opS = new Opportunity_Segment__c( Segment__c=oppSeg.Segment__c, Io_Invoice__c = inv.Id );
                    newSegs.add( opS );
                } 	   
            }
        }
        if( newSegs.size() > 0 ){
            INSERT newSegs;
        }
    }
    
    public static void updateIOInvoicesPONumber(Set<Id> ivIds){
        List<Invoice__c> invoiceListToBeUpdated = new List<Invoice__c>();
        List<Invoice__c> ivList = [Select PO_Number__c,Name, IO__c, Id From Invoice__c Where Id IN :ivIds ];
        Set<Id> contractIds = new Set<Id>();
        Map<Id, List<Invoice__c>> ioInvoiceMap = new Map<Id, List<Invoice__c>>();
        for(Invoice__c iv : ivList){
            contractIds.add(iv.IO__c);
            //ioInvoiceMap.put(iv.IO__c,new List<Invoice__c>());
        }
        for(Invoice__c iv : ivList){
            /*List<Invoice__c> ivL = new List<Invoice__c>();
            if(ioInvoiceMap.get(iv.IO__c) != null){
                ivL = ioInvoiceMap.get(iv.IO__c);
                ivL.add(iv);
            }
            ivl.sort();
            ioInvoiceMap.put(iv.IO__c,ivL);*/
            if( !ioInvoiceMap.containsKey(iv.IO__c) ){
                ioInvoiceMap.put(iv.IO__c,new List<Invoice__c>());
            }
            ioInvoiceMap.get( iv.IO__c ).add( iv );
        }
        Map<Id,Contract> contInvMap = new Map<Id,Contract>([Select Id, (Select IO__c, Name, PO_Number__c from Contract_Invoices__r) From Contract Where Id In :ioInvoiceMap.keySet()]);
        for(Id crId : ioInvoiceMap.keySet()){
            Integer i = ioInvoiceMap.get(crId).size()-1;
            List<Invoice__c> invList1 = ioInvoiceMap.get(crId);
            for(Invoice__c inv : contInvMap.get(crId).Contract_Invoices__r){
                if(invList1[i].Name < inv.Name){
                    inv.PO_Number__c = invList1[i].PO_Number__c;
                    invoiceListToBeUpdated.add(inv);
                }
            }
        }  
        update invoiceListToBeUpdated;
    }
    
    public static void updateIOInvoicesPONumberFromIOI(Set<Id> invIds){
        List<Invoice__c> invList = [SELECT Id, Name, IO__r.PO_Number__c, PO_Number__c FROM Invoice__c Where Id IN : invIds];
        List<Invoice__c> newInvList = new List<Invoice__c>();
        for(Invoice__c inv : invList){
            inv.PO_Number__c = inv.IO__r.PO_Number__c;
            newInvList.add(inv);
        }
        update newInvList;
    }
}