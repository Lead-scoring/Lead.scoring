/**
 * Servicio para manejar los valores de scoring
 * asociados a un ítem (kzScoringValue__c).
 *
 * Se usa desde los LWCs de configuración.
 *
 * @author Manuel Cerioni
 * @version 1.0.0
 */
public with sharing class KZ_ValueService {

    /* ========================= VALUES ========================= */

    @AuraEnabled(cacheable=true)
    public static List<kzScoringValue__c> getValuesByItem(Id itemId) {

        // Si no hay item -> lista vacía
        if (itemId == null) {
            return new List<kzScoringValue__c>();
        }

        return [
            SELECT Id,
                   Name,
                   kzValueText__c,
                   kzPicklistOptionApi__c,
                   kzAwardedScore__c,
                   kzExactMatch__c,
                   kzActive__c,
                   kzItemScoring__c,
                   kzOrder__c
            FROM kzScoringValue__c
            WHERE kzItemScoring__c = :itemId
            ORDER BY kzOrder__c NULLS LAST
        ];
    }

    @AuraEnabled
    public static List<kzScoringValue__c> saveValues(List<kzScoringValue__c> values) {

        // Si no hay valores -> no hace nada
        if (values == null || values.isEmpty()) {
            return new List<kzScoringValue__c>();
        }

        List<kzScoringValue__c> toInsert = new List<kzScoringValue__c>();
        List<kzScoringValue__c> toUpdate = new List<kzScoringValue__c>();

        // Separa nuevos de existentes
        for (kzScoringValue__c val : values) {
            if (val.Id == null) {
                toInsert.add(val);
            } else {
                toUpdate.add(val);
            }
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }

        return values;
    }

    @AuraEnabled
    public static void deleteValue(Id valueId) {

        if (valueId == null) {
            throw new AuraHandledException('valueId requerido');
        }

        delete [
            SELECT Id
            FROM kzScoringValue__c
            WHERE Id = :valueId
            LIMIT 1
        ];
    }
}