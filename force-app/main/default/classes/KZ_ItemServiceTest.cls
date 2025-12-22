@IsTest
private class KZ_ItemServiceTest {

    @IsTest
    static void testItemLifecycle() {
        // 1. Preparar datos: Necesitamos un Scoring padre (asumo que existe el objeto kzScoring__c)
        // Si el objeto se llama distinto, ajusta el nombre aquí.
        sObject scoringPadre = Schema.getGlobalDescribe().get('kzScoring__c').newSObject();
        scoringPadre.put('Name', 'Scoring de Prueba');
        insert scoringPadre;

        // 2. Probar saveItem (Insert)
        kzItemScoring__c newItem = new kzItemScoring__c(
            Name = 'Item Test',
            kzScoring__c = scoringPadre.Id,
            kzLeadFieldApi__c = 'Status',
            kzOrder__c = 1
        );
        
        Test.startTest();
        kzItemScoring__c savedItem = KZ_ItemService.saveItem(newItem);
        
        // 3. Probar getItemsByScoring
        List<kzItemScoring__c> items = KZ_ItemService.getItemsByScoring(scoringPadre.Id);
        
        // 4. Probar getItemById
        kzItemScoring__c foundItem = KZ_ItemService.getItemById(savedItem.Id);
        
        // 5. Probar deleteItem (creamos un valor hijo primero para cubrir esa lógica)
        // Ajusta el nombre si el objeto kzScoringValue__c tiene campos obligatorios
        sObject valHijo = Schema.getGlobalDescribe().get('kzScoringValue__c').newSObject();
        valHijo.put('kzItemScoring__c', savedItem.Id);
        insert valHijo;
        
        KZ_ItemService.deleteItem(savedItem.Id);
        Test.stopTest();

        // Verificaciones
        System.assertNotEquals(null, savedItem.Id, 'El item debería haberse guardado');
        System.assertEquals(1, items.size(), 'Debería haber un item asociado al scoring');
        System.assertEquals(savedItem.Id, foundItem.Id, 'Debería encontrar el item por su Id');
        
        // Verificar eliminación
        List<kzItemScoring__c> deletedCheck = [SELECT Id FROM kzItemScoring__c WHERE Id = :savedItem.Id];
        System.assert(deletedCheck.isEmpty(), 'El item debería haber sido eliminado');
    }

    @IsTest
    static void testErrorScenarios() {
        Test.startTest();
        // Casos nulos para cubrir los retornos vacíos y excepciones
        List<kzItemScoring__c> emptyList = KZ_ItemService.getItemsByScoring(null);
        kzItemScoring__c nullItem = KZ_ItemService.getItemById(null);
        
        // Probar excepciones AuraHandledException
        Boolean saveError = false;
        try { KZ_ItemService.saveItem(null); } catch (AuraHandledException e) { saveError = true; }
        
        Boolean deleteError = false;
        try { KZ_ItemService.deleteItem(null); } catch (AuraHandledException e) { deleteError = true; }
        Test.stopTest();

        System.assert(emptyList.isEmpty());
        System.assertEquals(null, nullItem);
        System.assert(saveError, 'Debería haber lanzado error al guardar nulo');
        System.assert(deleteError, 'Debería haber lanzado error al eliminar nulo');
    }
}