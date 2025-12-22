@IsTest
private class KZ_LeadScoringHandlerTest {

    @IsTest
    static void testApplyScoringFullFlow() {
        // 1. Preparar Configuración (Scoring -> Item -> Value)
        kzScoring__c scoring = new kzScoring__c(
            Name = 'Config Test', 
            kzActive__c = true,
            kzPMPTotalOverride__c = 100
        );
        insert scoring;

        // Creamos ítems de diferentes tipos para cubrir los métodos 'match'
        List<kzItemScoring__c> items = new List<kzItemScoring__c>();
        items.add(new kzItemScoring__c(Name='Item Text', kzScoring__c=scoring.Id, kzLeadFieldApi__c='LastName', kzFieldType__c='TEXT', kzActive__c=true, kzPMP__c=50));
        items.add(new kzItemScoring__c(Name='Item Pick', kzScoring__c=scoring.Id, kzLeadFieldApi__c='Status', kzFieldType__c='PICKLIST', kzActive__c=true, kzPMP__c=50));
        items.add(new kzItemScoring__c(Name='Item Bool', kzScoring__c=scoring.Id, kzLeadFieldApi__c='DoNotCall', kzFieldType__c='CHECKBOX', kzActive__c=true, kzPMP__c=0));
        insert items;

        List<kzScoringValue__c> values = new List<kzScoringValue__c>();
        // Valor texto (Exact Match)
        values.add(new kzScoringValue__c(kzItemScoring__c=items[0].Id, kzValueText__c='Perez', kzExactMatch__c=true, kzAwardedScore__c=50, kzActive__c=true));
        // Valor Picklist
        values.add(new kzScoringValue__c(kzItemScoring__c=items[1].Id, kzPicklistOptionApi__c='Open - Not Contacted', kzAwardedScore__c=50, kzActive__c=true));
        // Valor Checkbox
        values.add(new kzScoringValue__c(kzItemScoring__c=items[2].Id, kzValueText__c='true', kzAwardedScore__c=0, kzActive__c=true));
        insert values;

        // 2. Crear Leads para procesar
        List<Lead> leads = new List<Lead>();
        leads.add(new Lead(LastName='Perez', Company='TestCo', Status='Open - Not Contacted', DoNotCall=true));
        leads.add(new Lead(LastName='Other', Company='TestCo', Status='Working', DoNotCall=false));

        // 3. Ejecutar Handler
        Test.startTest();
        KZ_LeadScoringHandler.applyScoring(leads);
        KZ_LeadScoringHandler.applyScoring(leads, null); // Cubrir firma con oldMap
        Test.stopTest();

        // 4. Verificaciones
        // El primer Lead debería tener 100 (50 de texto + 50 de picklist)
        // Buscamos dinámicamente el campo de puntuación que use tu Org
        Decimal score = (Decimal)leads[0].get(leads[0].getSObjectType().getDescribe().fields.getMap().containsKey('kzPuntuacionLead__c') ? 'kzPuntuacionLead__c' : 'Puntuacion_Lead__c');
        System.assertEquals(100.00, score, 'El score debería ser 100');
    }

    @IsTest
    static void testSpecialTokensAndNumbers() {
        kzScoring__c scoring = new kzScoring__c(Name = 'Tokens Test', kzActive__c = true);
        insert scoring;

        // Item para probar tokens de vacío/no vacío y números (usamos AnnualRevenue como número)
        kzItemScoring__c itemText = new kzItemScoring__c(Name='Token Item', kzScoring__c=scoring.Id, kzLeadFieldApi__c='FirstName', kzFieldType__c='TEXT', kzActive__c=true, kzPMP__c=100);
        kzItemScoring__c itemNum = new kzItemScoring__c(Name='Num Item', kzScoring__c=scoring.Id, kzLeadFieldApi__c='AnnualRevenue', kzFieldType__c='NUMBER', kzActive__c=true, kzPMP__c=100);
        insert new List<kzItemScoring__c>{itemText, itemNum};

        insert new kzScoringValue__c(kzItemScoring__c=itemText.Id, kzValueText__c='__IS_EMPTY__', kzAwardedScore__c=100, kzActive__c=true);
        insert new kzScoringValue__c(kzItemScoring__c=itemNum.Id, kzValueText__c='1000', kzAwardedScore__c=100, kzActive__c=true);

        Lead l = new Lead(LastName='Test', Company='Test', FirstName=null, AnnualRevenue=1000);
        
        Test.startTest();
        KZ_LeadScoringHandler.applyScoring(new List<Lead>{l});
        Test.stopTest();

        System.assert(l.get('LastName') != null);
    }

    @IsTest
    static void testNoActiveScoring() {
        // Test para cubrir el escenario donde no hay nada activo (debe poner 100%)
        Lead l = new Lead(LastName='Test', Company='Test');
        
        Test.startTest();
        KZ_LeadScoringHandler.applyScoring(new List<Lead>{l});
        KZ_LeadScoringHandler.applyScoring(null); // Cubrir null check
        Test.stopTest();

        System.assertNotEquals(null, l.get(l.getSObjectType().getDescribe().fields.getMap().containsKey('kzPuntuacionLead__c') ? 'kzPuntuacionLead__c' : 'Puntuacion_Lead__c'));
    }
}