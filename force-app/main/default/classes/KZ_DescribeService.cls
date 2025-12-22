/**
 * Servicio para obtener metadata del objeto Lead.
 * Usado por los componentes de configuración de Scoring.
 *
 * @author Manuel Cerioni
 * @version 1.0.0
 * @since 2025-12-04
 */
public with sharing class KZ_DescribeService {

    /**
     * DTO para exponer valores de picklist a LWC.
     */
    public class PicklistValueDTO {
        @AuraEnabled public String label;
        @AuraEnabled public String value;

        public PicklistValueDTO(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    /**
     * Devuelve los campos del Lead.
     * Key: API Name
     * Value: Label
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getLeadFields() {

        Map<String, String> result = new Map<String, String>();
        Map<String, Schema.SObjectField> fieldMap =
            Schema.SObjectType.Lead.fields.getMap();

        for (String apiName : fieldMap.keySet()) {
            Schema.DescribeFieldResult d =
                fieldMap.get(apiName).getDescribe();
            result.put(apiName, d.getLabel());
        }

        return result;
    }

    /**
     * Devuelve los valores de un picklist del Lead.
     */
    @AuraEnabled(cacheable=true)
    public static List<PicklistValueDTO> describeLeadPicklist(String fieldApi) {

        List<PicklistValueDTO> result =
            new List<PicklistValueDTO>();

        if (String.isBlank(fieldApi)) {
            return result;
        }

        Map<String, Schema.SObjectField> fieldMap =
            Schema.SObjectType.Lead.fields.getMap();

        if (!fieldMap.containsKey(fieldApi)) {
            return result;
        }

        Schema.DescribeFieldResult describe =
            fieldMap.get(fieldApi).getDescribe();

        for (Schema.PicklistEntry entry :
             describe.getPicklistValues()) {

            result.add(
                new PicklistValueDTO(
                    entry.getLabel(),
                    entry.getValue()
                )
            );
        }

        return result;
    }
}