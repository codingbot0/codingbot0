public class SyncPartsAndProductsScheduler implements Schedulable{
    public void execute(SchedulableContext sc) {
        ID BatchId = Database.executeBatch(new SyncPartsAndProducts(), 100);
    }
}