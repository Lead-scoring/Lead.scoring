/**
 * Handler encargado de calcular el scoring del Lead
 * en base a la configuración activa de KZ Scoring.
 * 
 *
 * Se ejecuta desde el trigger.
 *
 * @author Manuel Cerioni
 * @version 2.0.2
 */
public with sharing class KZ_LeadScoringHandler {

    // Tokens usados en reglas de texto
    private static final String TOKEN_IS_EMPTY = '__IS_EMPTY__';
    private static final String TOKEN_IS_NOT_EMPTY = '__IS_NOT_EMPTY__';

    public static void applyScoring(List<Lead> newList, Map<Id, Lead> oldMap) {
        applyScoring(newList);
    }

    public static void applyScoring(List<Lead> newList) {

        // Si no hay leads -> no hace nada
        if (newList == null || newList.isEmpty()) {
            return;
        }

        kzScoring__c scoring = getActiveScoring();

        // Si no hay scoring activo -> 100%
        if (scoring == null) {
            writeDefaultScore(newList);
            return;
        }

        List<kzItemScoring__c> items = getActiveItems(scoring.Id);

        // Si no hay ítems -> 100%
        if (items.isEmpty()) {
            writeDefaultScore(newList);
            return;
        }

        Map<Id, List<kzScoringValue__c>> valuesByItem = getValuesByItem(items);
        List<kzItemScoring__c> validItems = filterItemsWithValues(items, valuesByItem);

        // Si ningún ítem tiene valores -> 100%
        if (validItems.isEmpty()) {
            writeDefaultScore(newList);
            return;
        }

        Decimal pmpTotal = calculatePmpTotal(scoring, validItems);
        Map<String, Schema.SObjectField> leadFields = Schema.SObjectType.Lead.fields.getMap();

        for (Lead l : newList) {

            Decimal totalScore = 0;

            for (kzItemScoring__c item : validItems) {

                // Si el campo no existe en Lead -> se ignora
                if (String.isBlank(item.kzLeadFieldApi__c) ||
                    !leadFields.containsKey(item.kzLeadFieldApi__c)) {
                    continue;
                }

                Object rawValue = getFieldValue(l, item.kzLeadFieldApi__c);
                String leadText = rawValue == null ? '' : String.valueOf(rawValue);
                Boolean leadBool = rawValue instanceof Boolean ? (Boolean) rawValue : null;
                Decimal leadNumber = parseDecimal(rawValue);

                List<kzScoringValue__c> values = valuesByItem.get(item.Id);
                if (values == null || values.isEmpty()) {
                    continue;
                }

                totalScore += evaluateItem(item, values, leadText, leadBool, leadNumber);
            }

            Decimal percentage = normalizeScore(totalScore, pmpTotal);
            writeScore(l, percentage, leadFields);
        }
    }

    /* ======================== MÉTODOS INTERNOS ======================== */

    private static kzScoring__c getActiveScoring() {
        List<kzScoring__c> listScoring = [
            SELECT Id, kzPMPTotalOverride__c
            FROM kzScoring__c
            WHERE kzActive__c = true
            LIMIT 1
        ];
        return listScoring.isEmpty() ? null : listScoring[0];
    }

    private static List<kzItemScoring__c> getActiveItems(Id scoringId) {
        return [
            SELECT Id, kzLeadFieldApi__c, kzFieldType__c, kzPMP__c
            FROM kzItemScoring__c
            WHERE kzScoring__c = :scoringId
            AND kzActive__c = true
            ORDER BY kzOrder__c NULLS LAST, Name
        ];
    }

    private static Map<Id, List<kzScoringValue__c>> getValuesByItem(List<kzItemScoring__c> items) {

        Map<Id, List<kzScoringValue__c>> result = new Map<Id, List<kzScoringValue__c>>();
        List<Id> itemIds = new List<Id>();

        for (kzItemScoring__c i : items) {
            itemIds.add(i.Id);
        }

        for (kzScoringValue__c v : [
            SELECT Id, kzItemScoring__c, kzPicklistOptionApi__c, kzValueText__c,
                   kzAwardedScore__c, kzExactMatch__c
            FROM kzScoringValue__c
            WHERE kzItemScoring__c IN :itemIds
            AND kzActive__c = true
            ORDER BY kzOrder__c NULLS LAST
        ]) {
            if (!result.containsKey(v.kzItemScoring__c)) {
                result.put(v.kzItemScoring__c, new List<kzScoringValue__c>());
            }
            result.get(v.kzItemScoring__c).add(v);
        }

        return result;
    }

    private static List<kzItemScoring__c> filterItemsWithValues(
        List<kzItemScoring__c> items,
        Map<Id, List<kzScoringValue__c>> valuesByItem
    ) {
        List<kzItemScoring__c> result = new List<kzItemScoring__c>();

        for (kzItemScoring__c i : items) {
            if (valuesByItem.containsKey(i.Id) && !valuesByItem.get(i.Id).isEmpty()) {
                result.add(i);
            }
        }

        return result;
    }

    private static Decimal calculatePmpTotal(kzScoring__c scoring, List<kzItemScoring__c> items) {

        // Si hay override -> usarlo
        if (scoring.kzPMPTotalOverride__c != null &&
            scoring.kzPMPTotalOverride__c > 0) {
            return scoring.kzPMPTotalOverride__c;
        }

        Decimal total = 0;
        for (kzItemScoring__c i : items) {
            total += i.kzPMP__c == null ? 0 : i.kzPMP__c;
        }

        return total == 0 ? 100 : total;
    }

    private static Object getFieldValue(SObject sObj, String fieldApi) {
        try {
            return sObj.get(fieldApi);
        } catch (Exception e) {
            return null;
        }
    }

    private static Decimal parseDecimal(Object value) {
        try {
            return value == null ? null : Decimal.valueOf(String.valueOf(value));
        } catch (Exception e) {
            return null;
        }
    }

    private static Decimal normalizeScore(Decimal score, Decimal pmpTotal) {

        Decimal result = pmpTotal > 0 ? (score / pmpTotal) * 100 : 0;
        result = result.setScale(2, System.RoundingMode.HALF_UP);

        if (result < 0) return 0;
        if (result > 100) return 100;
        return result;
    }

    private static void writeScore(
        Lead l,
        Decimal percentage,
        Map<String, Schema.SObjectField> fields
    ) {
        if (fields.containsKey('kzPuntuacionLead__c')) {
            l.put('kzPuntuacionLead__c', percentage);
        } else if (fields.containsKey('Puntuacion_Lead__c')) {
            l.put('Puntuacion_Lead__c', percentage);
        }
    }

    private static void writeDefaultScore(List<Lead> leads) {
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Lead.fields.getMap();
        for (Lead l : leads) {
            writeScore(l, 100, fields);
        }
    }

    private static Decimal evaluateItem(
        kzItemScoring__c item,
        List<kzScoringValue__c> values,
        String leadText,
        Boolean leadBool,
        Decimal leadNumber
    ) {

        String type = item.kzFieldType__c == null
            ? 'TEXT'
            : item.kzFieldType__c.trim().toUpperCase();

        for (kzScoringValue__c v : values) {

            Boolean matched;

            if (type == 'PICKLIST') {
                matched = matchPicklist(leadText, v);
            } else if (type == 'CHECKBOX') {
                matched = matchCheckbox(leadBool, v);
            } else if (type == 'NUMBER') {
                matched = matchNumber(leadNumber, v.kzValueText__c);
            } else {
                matched = matchText(leadText, v);
            }

            if (matched) {
                return v.kzAwardedScore__c == null ? 0 : v.kzAwardedScore__c;
            }
        }

        return 0;
    }

    /* ======================== MATCHING ======================== */

    private static Boolean matchPicklist(String leadVal, kzScoringValue__c v) {
        if (String.isBlank(leadVal)) return false;
        if (leadVal.equalsIgnoreCase(v.kzPicklistOptionApi__c)) return true;
        if (leadVal.equalsIgnoreCase(v.kzValueText__c)) return true;
        return false;
    }

    private static Boolean matchCheckbox(Boolean leadBool, kzScoringValue__c v) {
        if (leadBool == null) return false;
        Boolean value = v.kzValueText__c == 'true' || v.kzValueText__c == '1';
        return leadBool == value;
    }

    private static Boolean matchNumber(Decimal leadNum, String value) {
        try {
            return leadNum != null && leadNum == Decimal.valueOf(value);
        } catch (Exception e) {
            return false;
        }
    }

    private static Boolean matchText(String leadVal, kzScoringValue__c v) {

        String rule = v.kzValueText__c == null ? '' : v.kzValueText__c.trim();

        if (rule == TOKEN_IS_EMPTY) return String.isBlank(leadVal);
        if (rule == TOKEN_IS_NOT_EMPTY) return !String.isBlank(leadVal);

        if (v.kzExactMatch__c == true) {
            return leadVal.equalsIgnoreCase(rule);
        }

        return leadVal.toLowerCase().contains(rule.toLowerCase());
    }
}