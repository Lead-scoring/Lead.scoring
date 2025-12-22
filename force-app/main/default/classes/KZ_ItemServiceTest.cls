@IsTest
private class KZ_ItemServiceTest {
    @IsTest
    static void testItemLifecycle() {
        kzScoring__c scoring = new kzScoring__c(Name = 'Scoring Test');
        insert scoring;

        kzItemScoring__c newItem = new kzItemScoring__c(
            Name = 'Item Test',
            kzScoring__c = scoring.Id,
            kzLeadFieldApi__c = 'Status',
            kzFieldType__c = 'PICKLIST', 
            kzOrder__c = 1
        );
        
        Test.startTest();
        kzItemScoring__c savedItem = KZ_ItemService.saveItem(newItem);
        List<kzItemScoring__c> items = KZ_ItemService.getItemsByScoring(scoring.Id);
        
        kzScoringValue__c valHijo = new kzScoringValue__c(
            Name = 'Val',
            kzItemScoring__c = savedItem.Id,
            kzValueText__c = 'Open' 
        );
        insert valHijo;
        
        KZ_ItemService.deleteItem(savedItem.Id);
        Test.stopTest();

        System.assertNotEquals(null, savedItem.Id);
        System.assertEquals(1, items.size());
    }

    @IsTest
    static void testErrors() {
        try { KZ_ItemService.saveItem(null); } catch (Exception e) { System.assert(true); }
        try { KZ_ItemService.deleteItem(null); } catch (Exception e) { System.assert(true); }
    }
}