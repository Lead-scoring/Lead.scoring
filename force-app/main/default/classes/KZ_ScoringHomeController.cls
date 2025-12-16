/**
 * Controlador para la vista principal del módulo de Scoring.
 * Se usa únicamente para listar las configuraciones existentes.
 */
public with sharing class KZ_ScoringHomeController {

    /**
     * Devuelve las configuraciones de scoring ordenadas por fecha de creación.
     */
    @AuraEnabled(cacheable=true)
    public static List<kzScoring__c> getScorings() {

        return [
            SELECT Id, Name, kzActive__c, kzDescription__c, CreatedDate
            FROM kzScoring__c
            ORDER BY CreatedDate DESC
            LIMIT 200
        ];
    }
}
