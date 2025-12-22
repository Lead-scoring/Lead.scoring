@IsTest
private class KZ_ScoringConfigServiceTest {

    @IsTest
    static void testCompleteServiceFlow() {
        kzScoring__c config1 = new kzScoring__c(Name = 'Config 1', kzActive__c = true);
        insert config1;
        
        kzScoring__c config2 = new kzScoring__c(Name = 'Config 2', kzActive__c = true);
        
        Test.startTest();
        Id config2Id = KZ_ScoringConfigService.saveConfig(config2);
        
        kzItemScoring__c item = new kzItemScoring__c(
            Name='Item', kzScoring__c=config2Id, kzLeadFieldApi__c='Status', kzFieldType__c='PICKLIST'
        );
        Id itemId = KZ_ScoringConfigService.saveItem(item);
        
        kzScoringValue__c val = new kzScoringValue__c(Name='Val', kzItemScoring__c=itemId, kzValueText__c='Open');
        KZ_ScoringConfigService.saveValue(val);
        
        // Cobertura de métodos de consulta y utilidades
        KZ_ScoringConfigService.getScoringList();
        KZ_ScoringConfigService.getConfig(config2Id);
        KZ_ScoringConfigService.getNextItemOrder(config2Id);
        KZ_ScoringConfigService.getAllLeadFieldsForScoring();
        KZ_ScoringConfigService.getFieldAndPicklistOptions(itemId);
        KZ_ScoringConfigService.getValuesByItem(itemId);
        
        // Cobertura de borrados y excepciones
        KZ_ScoringConfigService.deleteValue(val.Id);
        KZ_ScoringConfigService.deleteItem(itemId);
        KZ_ScoringConfigService.deleteConfig(config2Id);
        
        // Cobertura de nulos
        KZ_ScoringConfigService.getConfig(null);
        KZ_ScoringConfigService.getItemsByScoring(null);
        KZ_ScoringConfigService.getValuesByItem(null);
        Test.stopTest();

        System.assertNotEquals(null, config2Id);
    }
}