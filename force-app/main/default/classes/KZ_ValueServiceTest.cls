@IsTest
private class KZ_ValueServiceTest {

    @IsTest
    static void testValueLifecycle() {
        // 1. Preparar datos: Jerarquía completa
        kzScoring__c scoring = new kzScoring__c(Name = 'Scoring Test');
        insert scoring;

        kzItemScoring__c item = new kzItemScoring__c(
            Name = 'Item Test',
            kzScoring__c = scoring.Id,
            kzLeadFieldApi__c = 'Status'
        );
        insert item;

        // 2. Probar saveValues (Insert)
        List<kzScoringValue__c> valuesToSave = new List<kzScoringValue__c>();
        valuesToSave.add(new kzScoringValue__c(
            Name = 'Valor 1',
            kzItemScoring__c = item.Id,
            kzValueText__c = 'Prueba',
            kzAwardedScore__c = 10
        ));

        Test.startTest();
        List<kzScoringValue__c> savedValues = KZ_ValueService.saveValues(valuesToSave);
        
        // 3. Probar saveValues (Update)
        savedValues[0].kzValueText__c = 'Prueba Editada';
        KZ_ValueService.saveValues(savedValues);
        
        // 4. Probar getValuesByItem
        List<kzScoringValue__c> fetchedValues = KZ_ValueService.getValuesByItem(item.Id);
        
        // 5. Probar deleteValue
        KZ_ValueService.deleteValue(savedValues[0].Id);
        Test.stopTest();

        // Verificaciones
        System.assertEquals(1, savedValues.size(), 'Debería haber guardado un valor');
        System.assertNotEquals(null, savedValues[0].Id, 'El valor debería tener Id');
        System.assertEquals(1, fetchedValues.size(), 'Debería haber encontrado el valor por ItemId');
        
        // Verificar eliminación
        List<kzScoringValue__c> checkDeleted = [SELECT Id FROM kzScoringValue__c WHERE Id = :savedValues[0].Id];
        System.assert(checkDeleted.isEmpty(), 'El valor debería haber sido eliminado');
    }

    @IsTest
    static void testErrorAndEmptyScenarios() {
        Test.startTest();
        // Casos nulos y vacíos
        List<kzScoringValue__c> emptyListById = KZ_ValueService.getValuesByItem(null);
        List<kzScoringValue__c> emptyListSave = KZ_ValueService.saveValues(null);
        List<kzScoringValue__c> emptyListSave2 = KZ_ValueService.saveValues(new List<kzScoringValue__c>());
        
        // Excepción AuraHandledException
        Boolean deleteError = false;
        try {
            KZ_ValueService.deleteValue(null);
        } catch (AuraHandledException e) {
            deleteError = true;
        }
        Test.stopTest();

        System.assert(emptyListById.isEmpty());
        System.assert(emptyListSave.isEmpty());
        System.assert(emptyListSave2.isEmpty());
        System.assert(deleteError, 'Debería haber lanzado error al intentar borrar Id nulo');
    }
}