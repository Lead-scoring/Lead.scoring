@IsTest
private class KZ_ScoringHomeControllerTest {

    @IsTest
    static void testGetScorings() {
        // 1. Preparar datos: Creamos un registro de configuración
        // Usamos el nombre del objeto que vimos en la clase anterior
        kzScoring__c scoring = new kzScoring__c(
            Name = 'Configuración Global',
            kzActive__c = true,
            kzDescription__c = 'Descripción de prueba'
        );
        insert scoring;

        // 2. Ejecutar el método del controlador
        Test.startTest();
        List<kzScoring__c> result = KZ_ScoringHomeController.getScorings();
        Test.stopTest();

        // 3. Verificaciones
        System.assertEquals(1, result.size(), 'Debería haber devuelto exactamente 1 registro');
        System.assertEquals('Configuración Global', result[0].Name, 'El nombre del registro no coincide');
        System.assertNotEquals(null, result[0].CreatedDate, 'Debería incluir la fecha de creación');
    }
    
    @IsTest
    static void testGetScoringsEmpty() {
        // Probamos el escenario donde no hay datos para asegurar que no rompa
        Test.startTest();
        List<kzScoring__c> result = KZ_ScoringHomeController.getScorings();
        Test.stopTest();

        System.assertEquals(0, result.size(), 'La lista debería estar vacía si no hay registros');
    }
}