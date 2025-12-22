@IsTest
private class KZ_DescribeServiceTest {
    @IsTest
    static void testGetLeadFields() {
        Test.startTest();
        Map<String, String> fields = KZ_DescribeService.getLeadFields();
        Test.stopTest();
        System.assert(!fields.isEmpty(), 'El mapa de campos no debería estar vacío');
        // Verificación flexible para evitar fallos por capitalización de API names
        String checkField = 'LastName'.toLowerCase();
        Boolean found = false;
        for(String key : fields.keySet()) {
            if(key.toLowerCase() == checkField) { found = true; break; }
        }
        System.assert(found, 'Debería contener al menos el campo LastName');
    }

    @IsTest
    static void testDescribeLeadPicklist() {
        Test.startTest();
        List<KZ_DescribeService.PicklistValueDTO> values = KZ_DescribeService.describeLeadPicklist('Status');
        List<KZ_DescribeService.PicklistValueDTO> emptyValues = KZ_DescribeService.describeLeadPicklist('');
        List<KZ_DescribeService.PicklistValueDTO> invalidField = KZ_DescribeService.describeLeadPicklist('Campo_Inexistente__c');
        Test.stopTest();
        System.assert(!values.isEmpty(), 'Status debería devolver valores');
        System.assertEquals(0, emptyValues.size());
        System.assertEquals(0, invalidField.size());
    }
}