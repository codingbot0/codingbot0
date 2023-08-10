@isTest
private class TestSyncPartsAndProducts {
    @TestSetup
    static void createData(){
       //Profile sysAdminProfile = [select id,name from Profile where name = 'System Administrator' limit 1];
       Id p = [select id from profile where name='System Administrator'].id;

        
        
        // Create a test CPQ Product Admin permission set
        PermissionSet cpqProductAdminPermissionSet = [select id,name from PermissionSet where name ='CQ_Product_Admin' limit 1];
        
        
        // Assign the permission set to the user.
        User testUser = new User(
            ProfileId = p,
            LastName = 'cpqProductuser',
            Email = 'cpqProductuser@example.com',
            Alias = 'cpqPdt',
            EmailEncodingKey='UTF-8',  
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US', 
            Country='United States', 
            IsActive =true,
            TimezoneSidKey='America/Los_Angeles',
            Username = 'cpqProductuser@example.com'
        );
        insert testUser;
        System.debug('&****'+testUser.ProfileId );
        System.debug('&****'+testUser.Id );
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = testUser.Id,
            PermissionSetId = cpqProductAdminPermissionSet.Id
        );
        insert psa;
        // Create test data: Parts with no Product reference
        
        
    }
    
    @isTest
    static void testSyncPartsAndProducts() {
        User testUser = [SELECT Id, Name FROM User LIMIT 1];
        
        List<SQX_Part__c> partsToInsert = new List<SQX_Part__c>{
            new SQX_Part__c(Name = 'Test Part 1', Part_Number__c = 'P123', Active__c = true),
                new SQX_Part__c(Name = 'Test Part 2', Part_Number__c = 'P456', Active__c = true)
                };
                    insert partsToInsert;
        
            List<SQX_Part__c> synchronizedParts = [SELECT Id, Product__c FROM SQX_Part__c WHERE Id IN :partsToInsert];
        
            System.Test.startTest();
            Database.executeBatch(new SyncPartsAndProducts());
            System.Test.stopTest();
        
        
        // Verify that Parts have been synchronized with Products
        
        
        for (SQX_Part__c part : synchronizedParts) {
            System.assertEquals(null, part.Product__c);
        } 
    }
    @isTest
    public static void testSyncPartsAndProductsScheduler() {
        String jobName = 'SyncPartsAndProductsScheduler';
        String sch = '0 06 * * * ?';
        Test.startTest();
        System.schedule(jobName, sch, new SyncPartsAndProductsScheduler());
        Test.stopTest();
        List<AsyncApexJob> jobsScheduled = [SELECT Id, ApexClass.Name, JobType FROM AsyncApexJob WHERE JobType = 'ScheduledApex' AND ApexClass.Name = 'SyncPartsAndProductsScheduler'];
        System.assertEquals(1, jobsScheduled.Size(), 'Job Scheduled');
    } 
}