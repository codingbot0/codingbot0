global class SyncPartsAndProducts implements Database.Batchable<sObject>, Database.Stateful {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Name, Part_Number__c, Product__c FROM SQX_Part__c WHERE Active__c = true AND Product__c = null';
        System.debug('--Query--' + query);
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<SQX_Part__c> scope) {
        String currentUserId = UserInfo.getUserId();
		User currentUser = [SELECT Id, Name,ProfileId FROM User WHERE Id = :currentUserId LIMIT 1];
        
        if (hasRequiredPermissions(currentUser.id)) {
            if (!scope.isEmpty()) {
                // Collect unique Part Names and Part Numbers
                Set<String> partNames = new Set<String>();
                Set<String> partNumbers = new Set<String>();
                for (SQX_Part__c part : scope) {
                    partNames.add(part.Name);
                    partNumbers.add(part.Part_Number__c);
                }

                // Query matching Products using bulkified query
                Map<String, Product2> matchingProducts = new Map<String, Product2>();
                for (Product2 product : [SELECT Id, Name, ProductCode
                                         FROM Product2
                                         WHERE Name IN :partNames AND ProductCode IN :partNumbers]) {
                    matchingProducts.put(product.Name + '-' + product.ProductCode, product);
                }

                List<SQX_Part__c> partsToUpdate = new List<SQX_Part__c>();
                for (SQX_Part__c part : scope) {
                    String productKey = part.Name + '-' + part.Part_Number__c;
                    Product2 matchingProduct = matchingProducts.get(productKey);

                    if (matchingProduct != null) {
                        // If matching Product exists, update Part with Product reference
                        part.Product__c = matchingProduct.Id;
                        partsToUpdate.add(part);
                    } else {
                        // If matching Product doesn't exist, create a new Product
                        Product2 newProduct = new Product2(
                            Name = part.Name,
                            ProductCode = part.Part_Number__c,
                            IsActive = true
                        );
                        insert newProduct;

                        // Update Part with the new Product reference
                        part.Product__c = newProduct.Id;
                        partsToUpdate.add(part);
                    }
                }

                // Update the modified Parts
                update partsToUpdate;
            }
        } else {
            System.debug('Insufficient permissions to execute the batch job.');
            // Handle insufficient permissions if needed
        }
    }

    public void finish(Database.BatchableContext bc) {
        // ...
    }

    // Helper method to check for required permissions
    public Boolean hasRequiredPermissions(string userid) {
        Boolean hasPermissions = false;
		
        // Check for System Administrator profile
        Profile sysAdminProfile = [SELECT Id,Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User currentUser = [SELECT Id, Name,ProfileId,Profile.name FROM User WHERE Id = :userid LIMIT 1];
        if (currentUser.ProfileId==sysAdminProfile.id){
            
            PermissionSetAssignment permAssign= [ SELECT Id,AssigneeId,PermissionSet.Name from PermissionSetAssignment where AssigneeId =:userid and PermissionSet.Name = 'CQ_Product_Admin'];
            if (permAssign!=null){
                hasPermissions = true;
            }
        }
        return hasPermissions;
    }
}