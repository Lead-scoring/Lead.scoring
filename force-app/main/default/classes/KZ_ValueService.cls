/**
 * Servicio para manejar los valores de scoring (kzScoringValue__c)
 * asociados a un ítem de scoring.
 */
public with sharing class KZ_ValueService {

    /**
     * Devuelve los valores asociados a un ítem de scoring.
     */
    @AuraEnabled(cacheable=true)
    public static List<kzScoringValue__c> getValuesByItem(Id itemId) {

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

    /**
     * Guarda o actualiza una lista de valores de scoring.
     */
    @AuraEnabled
    public static List<kzScoringValue__c> saveValues(List<kzScoringValue__c> values) {

        if (values == null || values.isEmpty()) {
            return new List<kzScoringValue__c>();
        }

        List<kzScoringValue__c> toInsert = new List<kzScoringValue__c>();
        List<kzScoringValue__c> toUpdate = new List<kzScoringValue__c>();

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

    /**
     * Elimina un valor de scoring.
     */
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
