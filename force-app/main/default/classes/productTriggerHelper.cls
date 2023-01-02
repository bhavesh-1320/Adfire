public class productTriggerHelper {
    public static Boolean start = true;
    public static void createProdInQb( Set<Id> productIds ){
        Database.executeBatch(new CreateProdBatch( productIds ), 100);
    }
}