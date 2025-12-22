@IsTest
private class KZ_ValueServiceTest {
    @IsTest
    static void testValueLifecycle() {
        kzScoring__c sc = new kzScoring__c(Name = 'Val Test'); insert sc;
        kzItemScoring__c it = new kzItemScoring__c(Name='It', kzScoring__c=sc.Id, kzFieldType__c='TEXT', kzLeadFieldApi__c='LastName'); insert it;

        kzScoringValue__c val = new kzScoringValue__c(
            Name = 'V1', 
            kzItemScoring__c = it.Id, 
            kzValueText__c = 'TestValue',
            kzAwardedScore__c = 10
        );

        Test.startTest();
        List<kzScoringValue__c> saved = KZ_ValueService.saveValues(new List<kzScoringValue__c>{val});
        List<kzScoringValue__c> fetched = KZ_ValueService.getValuesByItem(it.Id);
        KZ_ValueService.deleteValue(saved[0].Id);
        Test.stopTest();

        System.assertEquals(1, fetched.size());
    }
}