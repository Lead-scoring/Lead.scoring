@IsTest
private class KZ_ScoringHomeControllerTest {
    @IsTest
    static void testGetScorings() {
        insert new kzScoring__c(Name = 'Home Test', kzActive__c = true);
        Test.startTest();
        List<kzScoring__c> result = KZ_ScoringHomeController.getScorings();
        Test.stopTest();
        System.assertEquals(1, result.size());
    }
}