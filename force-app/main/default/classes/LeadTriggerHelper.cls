public class LeadTriggerHelper {
    public static void checkDupLead( List<Lead> newLeads ){
        Set<String> names = new Set<String>();
        for( Lead l : newLeads ){
            names.add( l.Name );
            names.add( l.Email );
        }
        Set<String> unNames = new Set<String>();
        for( Lead l : [SELECT Name, Email FROM Lead WHERE Name IN :names AND Email IN :names] ){
            unNames.add( l.Name+' '+l.Email );
        }
        for( Lead l : newLeads ){
            if( unNames.contains(l.Name + ' ' +l.Email) ){
                l.addError( 'Duplicate Lead' );
            }
        }
    }
}