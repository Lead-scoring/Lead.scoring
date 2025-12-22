/**
 * Servicio para manejar los Items de Scoring (kzItemScoring__c).
 * Usado únicamente por los LWC de configuración.
 *
 * @author Manuel Cerioni
 * @version 1.0.0
 * @since 2025-12-04
 */
public with sharing class KZ_ItemService {

    /**
     * Devuelve los ítems asociados a un Scoring.
     */
    @AuraEnabled(cacheable=true)
    public static List<kzItemScoring__c> getItemsByScoring(Id scoringId) {

        if (scoringId == null) {
            return new List<kzItemScoring__c>();
        }

        return [
            SELECT Id,
                   Name,
                   kzLeadFieldApi__c,
                   kzFieldType__c,
                   kzPMP__c,
                   kzActive__c,
                   kzQuestionAgent__c,
                   kzOrder__c,
                   kzDescription__c,
                   kzScoring__c
            FROM kzItemScoring__c
            WHERE kzScoring__c = :scoringId
            ORDER BY kzOrder__c NULLS LAST, Name
        ];
    }

    /**
     * Devuelve un ítem por Id.
     */
    @AuraEnabled(cacheable=true)
    public static kzItemScoring__c getItemById(Id itemId) {

        if (itemId == null) {
            return null;
        }

        return [
            SELECT Id,
                   Name,
                   kzLeadFieldApi__c,
                   kzFieldType__c,
                   kzPMP__c,
                   kzActive__c,
                   kzQuestionAgent__c,
                   kzOrder__c,
                   kzDescription__c,
                   kzScoring__c
            FROM kzItemScoring__c
            WHERE Id = :itemId
            LIMIT 1
        ];
    }

    /**
     * Inserta o actualiza un ítem.
     */
    @AuraEnabled
    public static kzItemScoring__c saveItem(kzItemScoring__c item) {

        if (item == null) {
            throw new AuraHandledException('Item requerido');
        }

        upsert item;
        return item;
    }

    /**
     * Elimina un ítem y sus valores asociados.
     */
    @AuraEnabled
    public static void deleteItem(Id itemId) {

        if (itemId == null) {
            throw new AuraHandledException('itemId requerido');
        }

        // Valores hijos
        List<kzScoringValue__c> values = [
            SELECT Id
            FROM kzScoringValue__c
            WHERE kzItemScoring__c = :itemId
        ];

        if (!values.isEmpty()) {
            delete values;
        }

        // Ítem
        delete [
            SELECT Id
            FROM kzItemScoring__c
            WHERE Id = :itemId
            LIMIT 1
        ];
    }
}