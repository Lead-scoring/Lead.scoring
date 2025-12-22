@IsTest
private class KZ_DescribeServiceTest {

    @IsTest
    static void testGetLeadFields() {
        // Ejecutamos el método que mapea los campos del Lead
        Test.startTest();
        Map<String, String> fields = KZ_DescribeService.getLeadFields();
        Test.stopTest();

        // Verificamos que el mapa no esté vacío (Lead siempre tiene campos)
        System.assert(!fields.isEmpty(), 'El mapa de campos no debería estar vacío');
        System.assert(fields.containsKey('LastName'), 'Debería contener al menos el campo LastName');
    }

    @IsTest
    static void testDescribeLeadPicklist() {
        Test.startTest();
        // Caso exitoso: El campo 'Status' es un picklist estándar de Lead
        List<KZ_DescribeService.PicklistValueDTO> values = KZ_DescribeService.describeLeadPicklist('Status');
        
        // Casos de error (para cubrir los 'if' de tu clase):
        List<KZ_DescribeService.PicklistValueDTO> emptyResult = KZ_DescribeService.describeLeadPicklist('');
        List<KZ_DescribeService.PicklistValueDTO> invalidResult = KZ_DescribeService.describeLeadPicklist('Campo_No_Existente__c');
        Test.stopTest();

        // Verificaciones (Asserts)
        System.assert(!values.isEmpty(), 'Status debería devolver valores');
        System.assertEquals(0, emptyResult.size(), 'Debe ser 0 si el campo es vacío');
        System.assertEquals(0, invalidResult.size(), 'Debe ser 0 si el campo no existe');
        
        // Probamos que el DTO se haya construido bien
        if(!values.isEmpty()){
            System.assertNotEquals(null, values[0].label);
            System.assertNotEquals(null, values[0].value);
        }
    }
}