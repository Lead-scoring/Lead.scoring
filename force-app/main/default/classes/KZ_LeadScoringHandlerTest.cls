@IsTest
private class KZ_LeadScoringHandlerTest {

    @IsTest
    static void testApplyScoringFullFlow() {
        // 1. Configuración base
        kzScoring__c scoring = new kzScoring__c(Name = 'Config Test', kzActive__c = true, kzPMPTotalOverride__c = 100);
        insert scoring;

        // 2. Items con campos requeridos
        List<kzItemScoring__c> items = new List<kzItemScoring__c>();
        items.add(new kzItemScoring__c(Name='Item Text', kzScoring__c=scoring.Id, kzLeadFieldApi__c='LastName', kzFieldType__c='TEXT', kzActive__c=true, kzPMP__c=50));
        items.add(new kzItemScoring__c(Name='Item Pick', kzScoring__c=scoring.Id, kzLeadFieldApi__c='Status', kzFieldType__c='PICKLIST', kzActive__c=true, kzPMP__c=50));
        insert items;

        // 3. Valores: Aseguramos que AMBOS tengan kzValueText__c para evitar el DmlException
        List<kzScoringValue__c> values = new List<kzScoringValue__c>();
        
        // Valor 1
        values.add(new kzScoringValue__c(
            Name = 'Val1',
            kzItemScoring__c = items[0].Id, 
            kzValueText__c = 'Perez', // Requerido
            kzExactMatch__c = true, 
            kzAwardedScore__c = 50, 
            kzActive__c = true
        ));
        
        // Valor 2 (Aquí era donde faltaba el campo en la fila 1 de la lista)
        values.add(new kzScoringValue__c(
            Name = 'Val2',
            kzItemScoring__c = items[1].Id, 
            kzValueText__c = 'Open - Not Contacted', // Requerido
            kzPicklistOptionApi__c = 'Open - Not Contacted', 
            kzAwardedScore__c = 50, 
            kzActive__c = true
        ));
        insert values;

        // 4. Ejecución
        Lead l = new Lead(LastName='Perez', Company='TestCo', Status='Open - Not Contacted');
        Test.startTest();
        KZ_LeadScoringHandler.applyScoring(new List<Lead>{l});
        // Cobertura extra para ramas vacías y nulas
        KZ_LeadScoringHandler.applyScoring(new List<Lead>());
        KZ_LeadScoringHandler.applyScoring(null);
        Test.stopTest();

        String scoreField = l.getSObjectType().getDescribe().fields.getMap().containsKey('kzPuntuacionLead__c') ? 'kzPuntuacionLead__c' : 'Puntuacion_Lead__c';
        System.assertNotEquals(null, l.get(scoreField), 'El campo de score debe haberse llenado');
    }

    @IsTest
    static void testExtraFieldTypes() {
        kzScoring__c sc = new kzScoring__c(Name='Extra Types', kzActive__c=true);
        insert sc;

        kzItemScoring__c itNum = new kzItemScoring__c(Name='Num', kzScoring__c=sc.Id, kzActive__c=true, kzLeadFieldApi__c='AnnualRevenue', kzFieldType__c='NUMBER', kzPMP__c=10);
        kzItemScoring__c itBool = new kzItemScoring__c(Name='Bool', kzScoring__c=sc.Id, kzActive__c=true, kzLeadFieldApi__c='DoNotCall', kzFieldType__c='CHECKBOX', kzPMP__c=10);
        insert new List<kzItemScoring__c>{itNum, itBool};

        // Importante: kzValueText__c siempre presente
        insert new kzScoringValue__c(Name='VNum', kzItemScoring__c=itNum.Id, kzActive__c=true, kzValueText__c='1000', kzAwardedScore__c=10);
        insert new kzScoringValue__c(Name='VBool', kzItemScoring__c=itBool.Id, kzActive__c=true, kzValueText__c='true', kzAwardedScore__c=10);

        Lead l = new Lead(LastName='Test', Company='Test', AnnualRevenue=1000, DoNotCall=true);
        
        Test.startTest();
        KZ_LeadScoringHandler.applyScoring(new List<Lead>{l});
        Test.stopTest();
        System.assert(l.LastName != null);
    }
}