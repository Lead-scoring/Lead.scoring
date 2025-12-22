@IsTest
private class KZ_ScoringConfigServiceTest {

    @IsTest
    static void testScoringManagement() {
        // Test de Guardado y Desactivación de otras configs
        kzScoring__c config1 = new kzScoring__c(Name = 'Config 1', kzActive__c = true);
        insert config1;
        
        kzScoring__c config2 = new kzScoring__c(Name = 'Config 2', kzActive__c = true);
        
        Test.startTest();
        Id config2Id = KZ_ScoringConfigService.saveConfig(config2);
        List<kzScoring__c> listConfigs = KZ_ScoringConfigService.getScoringList();
        kzScoring__c fetchedConfig = KZ_ScoringConfigService.getConfig(config2Id);
        
        // Test de utilidades de orden
        Integer nextOrder = KZ_ScoringConfigService.getNextItemOrder(config2Id);
        
        // Test de eliminación en cascada
        kzItemScoring__c item = new kzItemScoring__c(Name='Item', kzScoring__c=config2Id, kzOrder__c=1);
        insert item;
        insert new kzScoringValue__c(Name='Val', kzItemScoring__c=item.Id);
        
        KZ_ScoringConfigService.deleteConfig(config2Id);
        Test.stopTest();

        System.assertNotEquals(null, config2Id);
        System.assertEquals(1, listConfigs.size());
        System.assertEquals(1, nextOrder);
    }

    @IsTest
    static void testItemAndValueManagement() {
        kzScoring__c cfg = new kzScoring__c(Name = 'Test');
        insert cfg;

        kzItemScoring__c item = new kzItemScoring__c(Name='Item Test', kzScoring__c=cfg.Id, kzLeadFieldApi__c='Status', kzFieldType__c='PICKLIST');
        
        Test.startTest();
        Id itemId = KZ_ScoringConfigService.saveItem(item);
        List<kzItemScoring__c> items = KZ_ScoringConfigService.getItemsByScoring(cfg.Id);
        
        kzScoringValue__c val = new kzScoringValue__c(Name='Val', kzItemScoring__c=itemId);
        Id valId = KZ_ScoringConfigService.saveValue(val);
        List<kzScoringValue__c> values = KZ_ScoringConfigService.getValuesByItem(itemId);
        
        // Metadata helpers
        KZ_ScoringConfigService.FieldDetails details = KZ_ScoringConfigService.getFieldAndPicklistOptions(itemId);
        
        KZ_ScoringConfigService.deleteValue(valId);
        KZ_ScoringConfigService.deleteItem(itemId);
        Test.stopTest();

        System.assertEquals(1, items.size());
        System.assertEquals(1, values.size());
        System.assertEquals('PICKLIST', details.fieldType);
    }

    @IsTest
    static void testMetadataUtils() {
        Test.startTest();
        List<KZ_ScoringConfigService.PicklistOption> fields = KZ_ScoringConfigService.getAllLeadFieldsForScoring();
        // Casos nulos para cobertura
        kzScoring__c nullConfig = KZ_ScoringConfigService.getConfig(null);
        List<kzItemScoring__c> emptyItems = KZ_ScoringConfigService.getItemsByScoring(null);
        KZ_ScoringConfigService.FieldDetails nullDetails = KZ_ScoringConfigService.getFieldAndPicklistOptions(null);
        Test.stopTest();

        System.assert(!fields.isEmpty());
        System.assertEquals(null, nullConfig);
        System.assert(emptyItems.isEmpty());
    }
}