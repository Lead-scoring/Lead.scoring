/**
 * Service encargado de administrar la configuración del Scoring.
 *
 * Se usa principalmente desde LWCs para:
 * - gestionar configuraciones
 * - ítems de scoring
 * - valores
 * - metadata auxiliar (campos, picklists, orden)
 *
 * @author Manuel Cerioni
 * @version 2.0.0
 */
public with sharing class KZ_ScoringConfigService {

    /* ========================= CLASES INTERNAS ========================= */

    // Opción genérica para picklists
    public class PicklistOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public String fieldType;
    }

    // Información del campo seleccionado en un ítem
    public class FieldDetails {
        @AuraEnabled public String fieldType;
        @AuraEnabled public List<PicklistOption> picklistOptions;
        @AuraEnabled public Decimal parentFieldPMP;
    }

    /* ========================= SCORING ========================= */

    @AuraEnabled(cacheable=true)
    public static List<kzScoring__c> getScoringList() {

        // Devuelve las últimas configuraciones creadas
        return [
            SELECT Id, Name, kzActive__c, kzDescription__c, CreatedDate
            FROM kzScoring__c
            ORDER BY CreatedDate DESC
            LIMIT 1000
        ];
    }

    @AuraEnabled
    public static kzScoring__c getConfig(Id recordId) {

        // Si no hay id -> null
        if (recordId == null) {
            return null;
        }

        return [
            SELECT Id, Name, kzActive__c, kzDescription__c, kzPMPTotalOverride__c
            FROM kzScoring__c
            WHERE Id = :recordId
            LIMIT 1
        ];
    }

    @AuraEnabled
    public static Id saveConfig(kzScoring__c record) {

        if (record == null) {
            throw new AuraHandledException('Record is required');
        }

        // Si se activa una config -> se desactivan las demás
        if (record.kzActive__c == true) {

            List<kzScoring__c> activeConfigs = [
                SELECT Id, kzActive__c
                FROM kzScoring__c
                WHERE kzActive__c = true
                AND Id != :record.Id
            ];

            if (!activeConfigs.isEmpty()) {
                for (kzScoring__c cfg : activeConfigs) {
                    cfg.kzActive__c = false;
                }
                update activeConfigs;
            }
        }

        upsert record;
        return record.Id;
    }

    @AuraEnabled
    public static void deleteConfig(Id configId) {

        if (configId == null) {
            throw new AuraHandledException('Config Id is required');
        }

        try {

            // Primero elimina ítems y valores asociados
            List<kzItemScoring__c> items = [
                SELECT Id
                FROM kzItemScoring__c
                WHERE kzScoring__c = :configId
            ];

            if (!items.isEmpty()) {

                List<kzScoringValue__c> values = [
                    SELECT Id
                    FROM kzScoringValue__c
                    WHERE kzItemScoring__c IN :items
                ];

                if (!values.isEmpty()) {
                    delete values;
                }

                delete items;
            }

            // Por último elimina la configuración
            delete [
                SELECT Id
                FROM kzScoring__c
                WHERE Id = :configId
                LIMIT 1
            ];

        } catch (Exception e) {
            throw new AuraHandledException(
                'Error al eliminar la configuración: ' + e.getMessage()
            );
        }
    }

    /* ========================= ITEMS ========================= */

    @AuraEnabled(cacheable=true)
    public static List<kzItemScoring__c> getItemsByScoring(Id scoringId) {

        // Si no hay scoring -> lista vacía
        if (scoringId == null) {
            return new List<kzItemScoring__c>();
        }

        return [
            SELECT Id, Name, kzLeadFieldApi__c, kzFieldType__c, kzPMP__c,
                   kzActive__c, kzQuestionAgent__c, kzOrder__c,
                   kzDescription__c, kzScoring__c
            FROM kzItemScoring__c
            WHERE kzScoring__c = :scoringId
            ORDER BY kzOrder__c NULLS LAST, Name
        ];
    }

    @AuraEnabled
    public static Id saveItem(kzItemScoring__c item) {

        if (item == null) {
            throw new AuraHandledException('Item record is required');
        }

        // Si no tiene orden -> asigna el siguiente
        if (item.kzOrder__c == null) {
            item.kzOrder__c = getNextItemOrder(item.kzScoring__c);
        }

        upsert item;
        return item.Id;
    }

    @AuraEnabled
    public static void deleteItem(Id itemId) {

        if (itemId == null) {
            throw new AuraHandledException('Item Id is required');
        }

        try {

            // Elimina primero los valores del ítem
            List<kzScoringValue__c> values = [
                SELECT Id
                FROM kzScoringValue__c
                WHERE kzItemScoring__c = :itemId
            ];

            if (!values.isEmpty()) {
                delete values;
            }

            delete [
                SELECT Id
                FROM kzItemScoring__c
                WHERE Id = :itemId
                LIMIT 1
            ];

        } catch (Exception e) {
            throw new AuraHandledException(
                'Error al eliminar el item de scoring: ' + e.getMessage()
            );
        }
    }

    /* ========================= VALUES ========================= */

    @AuraEnabled(cacheable=true)
    public static List<kzScoringValue__c> getValuesByItem(Id itemId) {

        // Si no hay item -> lista vacía
        if (itemId == null) {
            return new List<kzScoringValue__c>();
        }

        return [
            SELECT Id, Name, kzValueText__c, kzPicklistOptionApi__c,
                   kzAwardedScore__c, kzExactMatch__c, kzActive__c,
                   kzItemScoring__c, kzOrder__c
            FROM kzScoringValue__c
            WHERE kzItemScoring__c = :itemId
            ORDER BY kzOrder__c NULLS LAST
        ];
    }

    @AuraEnabled
    public static Id saveValue(kzScoringValue__c value) {

        if (value == null) {
            throw new AuraHandledException('Value record is required');
        }

        upsert value;
        return value.Id;
    }

    @AuraEnabled
    public static void deleteValue(Id valueId) {

        if (valueId == null) {
            throw new AuraHandledException('Value Id is required');
        }

        try {
            delete [
                SELECT Id
                FROM kzScoringValue__c
                WHERE Id = :valueId
                LIMIT 1
            ];
        } catch (Exception e) {
            throw new AuraHandledException(
                'Error al eliminar el valor de scoring: ' + e.getMessage()
            );
        }
    }

    /* ========================= UTILIDADES ========================= */

    @AuraEnabled(cacheable=true)
    public static Integer getNextItemOrder(Id scoringId) {

        // Si no hay scoring -> empieza en 1
        if (scoringId == null) {
            return 1;
        }

        AggregateResult ar = [
            SELECT MAX(kzOrder__c) maxOrder
            FROM kzItemScoring__c
            WHERE kzScoring__c = :scoringId
        ];

        Decimal maxOrder = (Decimal) ar.get('maxOrder');
        return maxOrder == null ? 1 : maxOrder.intValue() + 1;
    }

    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getAllLeadFieldsForScoring() {

        List<PicklistOption> result = new List<PicklistOption>();
        Map<String, Schema.SObjectField> fields =
            Schema.SObjectType.Lead.fields.getMap();

        for (String apiName : fields.keySet()) {

            Schema.DescribeFieldResult d = fields.get(apiName).getDescribe();
            String lower = apiName.toLowerCase();

            // Se filtran campos que no sirven para scoring
            if (d.isCalculated() ||
                !d.isUpdateable() ||
                lower.endsWith('id') ||
                lower.endsWith('by') ||
                lower == 'name' ||
                lower == 'ownerid') {
                continue;
            }

            PicklistOption opt = new PicklistOption();
            opt.value = apiName;
            opt.fieldType = mapDisplayType(d.getType());
            opt.label = d.getLabel() + ' (' + opt.fieldType + ')';

            result.add(opt);
        }

        result.sort(new PicklistSorter());
        return result;
    }

    // Ordena los campos por label
    private class PicklistSorter implements Comparator<PicklistOption> {
        public Integer compare(PicklistOption a, PicklistOption b) {
            if (a.label == b.label) return 0;
            return a.label > b.label ? 1 : -1;
        }
    }

    @AuraEnabled(cacheable=true)
    public static FieldDetails getFieldAndPicklistOptions(Id itemId) {

        FieldDetails result = new FieldDetails();
        result.picklistOptions = new List<PicklistOption>();
        result.fieldType = 'TEXT';
        result.parentFieldPMP = 0;

        // Si no hay item -> valores por defecto
        if (itemId == null) {
            return result;
        }

        List<kzItemScoring__c> items = [
            SELECT kzLeadFieldApi__c, kzFieldType__c, kzPMP__c
            FROM kzItemScoring__c
            WHERE Id = :itemId
            LIMIT 1
        ];

        if (items.isEmpty()) {
            return result;
        }

        kzItemScoring__c item = items[0];
        result.fieldType = item.kzFieldType__c;
        result.parentFieldPMP = item.kzPMP__c;

        // Si es picklist -> trae las opciones del campo
        if (result.fieldType == 'PICKLIST' &&
            item.kzLeadFieldApi__c != null) {

            Map<String, Schema.SObjectField> leadFields =
                Schema.SObjectType.Lead.fields.getMap();

            Schema.SObjectField field = leadFields.get(item.kzLeadFieldApi__c);

            if (field != null) {
                for (Schema.PicklistEntry pe :
                     field.getDescribe().getPicklistValues()) {

                    PicklistOption opt = new PicklistOption();
                    opt.label = pe.getLabel();
                    opt.value = pe.getValue();
                    result.picklistOptions.add(opt);
                }
            }
        }

        return result;
    }

    private static String mapDisplayType(Schema.DisplayType dt) {

        if (dt == Schema.DisplayType.Picklist ||
            dt == Schema.DisplayType.MultiPicklist) return 'PICKLIST';

        if (dt == Schema.DisplayType.String ||
            dt == Schema.DisplayType.TextArea ||
            dt == Schema.DisplayType.Url) return 'TEXT';

        if (dt == Schema.DisplayType.Boolean) return 'CHECKBOX';

        if (dt == Schema.DisplayType.Integer ||
            dt == Schema.DisplayType.Double ||
            dt == Schema.DisplayType.Currency ||
            dt == Schema.DisplayType.Percent) return 'NUMBER';

        if (dt == Schema.DisplayType.Date ||
            dt == Schema.DisplayType.DateTime) return 'DATE';

        if (dt == Schema.DisplayType.Email) return 'EMAIL';
        if (dt == Schema.DisplayType.Phone) return 'PHONE';

        return 'OTHER';
    }
}
