/**
 * Provides picklist metadata for the Dynamic Filter Search component, including
 * dependent (controlling) picklist relationships so the search UI can restrict a
 * dependent picklist's values based on the controlling field's selection.
 *
 * Self-contained by design: this component must not depend on other org utilities.
 */
public with sharing class DynamicFilterPicklistHelper {
    private static final String BASE64_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    /**
     * Returns the active picklist values for a field plus, when the field is a
     * dependent picklist, the controlling field API name and the controlling
     * values each option is valid for.
     *
     * @param objectApiName API name of the object owning the field
     * @param fieldApiName API name of the picklist field
     * @return Picklist metadata including dependency information
     */
    @AuraEnabled(cacheable=true)
    public static PicklistFieldInfo getPicklistFieldInfo(String objectApiName, String fieldApiName) {
        if (String.isBlank(objectApiName) || String.isBlank(fieldApiName)) {
            throw new AuraHandledException('Object and field API names are required.');
        }
        try {
            Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectApiName);
            if (objType == null) {
                throw new AuraHandledException('Object not found: ' + objectApiName);
            }
            Schema.SObjectField field = objType.getDescribe().fields.getMap().get(fieldApiName);
            if (field == null) {
                throw new AuraHandledException('Field not found: ' + fieldApiName);
            }

            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            PicklistFieldInfo result = new PicklistFieldInfo();
            List<String> controllingValues = resolveControllingValues(fieldDescribe, result);
            result.options = buildOptions(fieldDescribe, controllingValues);
            return result;
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Unable to load picklist information: ' + e.getMessage());
        }
    }

    /**
     * Builds the active picklist options with their decoded validFor entries.
     *
     * @param fieldDescribe Describe result of the picklist field
     * @param controllingValues Ordered controlling values aligned with the validFor bitset
     * @return Active options with resolved validFor controlling values
     */
    private static List<DependentPicklistOption> buildOptions(Schema.DescribeFieldResult fieldDescribe, List<String> controllingValues) {
        List<DependentPicklistOption> options = new List<DependentPicklistOption>();
        List<Schema.PicklistEntry> entries = fieldDescribe.getPicklistValues();
        List<PicklistEntryWrapper> wrappedEntries = (List<PicklistEntryWrapper>) JSON.deserialize(
            JSON.serialize(entries),
            List<PicklistEntryWrapper>.class
        );

        for (Integer index = 0; index < entries.size(); index++) {
            Schema.PicklistEntry entry = entries[index];
            if (!entry.isActive()) {
                continue;
            }
            DependentPicklistOption option = new DependentPicklistOption();
            option.label = entry.getLabel();
            option.value = entry.getValue();
            option.validFor = decodeValidFor(wrappedEntries[index].validFor, controllingValues);
            options.add(option);
        }
        return options;
    }

    /**
     * Decodes a validFor token into the list of controlling values the option is valid for.
     *
     * @param validForToken Base64 validFor token from the dependent picklist entry
     * @param controllingValues Ordered controlling values aligned with the bitset
     * @return Controlling values this option is valid for (empty when independent)
     */
    private static List<String> decodeValidFor(String validForToken, List<String> controllingValues) {
        List<String> validFor = new List<String>();
        if (controllingValues.isEmpty() || String.isBlank(validForToken)) {
            return validFor;
        }
        String bits = base64ToBits(validForToken);
        Integer maxIndex = Math.min(bits.length(), controllingValues.size());
        for (Integer bitIndex = 0; bitIndex < maxIndex; bitIndex++) {
            if (bits.substring(bitIndex, bitIndex + 1) == '1') {
                validFor.add(controllingValues.get(bitIndex));
            }
        }
        return validFor;
    }

    /**
     * Resolves the ordered controlling values for a dependent picklist and records
     * the controlling field API name on the result. Returns an empty list when the
     * field is not dependent.
     *
     * @param fieldDescribe Describe result of the dependent picklist field
     * @param result Result wrapper mutated with the controlling field API name
     * @return Ordered controlling values aligned with the validFor bitset
     */
    private static List<String> resolveControllingValues(Schema.DescribeFieldResult fieldDescribe, PicklistFieldInfo result) {
        List<String> controllingValues = new List<String>();
        Schema.SObjectField controller = fieldDescribe.getController();
        if (controller == null) {
            return controllingValues;
        }
        Schema.DescribeFieldResult controllerDescribe = controller.getDescribe();
        result.controllingFieldApiName = controllerDescribe.getName();
        if (controllerDescribe.getType() == Schema.DisplayType.BOOLEAN) {
            controllingValues.add('false');
            controllingValues.add('true');
        } else {
            for (Schema.PicklistEntry controllingEntry : controllerDescribe.getPicklistValues()) {
                controllingValues.add(controllingEntry.getValue());
            }
        }
        return controllingValues;
    }

    /**
     * Converts a Salesforce validFor base64 token into its bit string.
     *
     * @param validFor Base64 validFor token from a dependent picklist entry
     * @return Bit string where each '1' marks a valid controlling value index
     */
    @TestVisible
    private static String base64ToBits(String validFor) {
        if (String.isBlank(validFor)) {
            return '';
        }
        String bits = '';
        for (Integer i = 0; i < validFor.length(); i++) {
            Integer charValue = BASE64_CHARS.indexOf(validFor.substring(i, i + 1));
            bits += decimalToBinary(charValue).leftPad(6, '0');
        }
        return bits;
    }

    /**
     * Converts a non-negative integer into its binary string representation.
     *
     * @param value Non-negative integer to convert
     * @return Binary representation (empty string for 0)
     */
    @TestVisible
    private static String decimalToBinary(Integer value) {
        String bits = '';
        while (value > 0) {
            bits = String.valueOf(Math.mod(value, 2)) + bits;
            value = Integer.valueOf(Math.floor(value / 2));
        }
        return bits;
    }

    /**
     * Picklist metadata for a single field, including dependency information.
     */
    public class PicklistFieldInfo {
        @AuraEnabled public String controllingFieldApiName;
        @AuraEnabled public List<DependentPicklistOption> options;
    }

    /**
     * A single picklist option with the controlling values it is valid for.
     */
    public class DependentPicklistOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public List<String> validFor;
    }

    /**
     * Deserialization shape for a Schema.PicklistEntry, used to read the validFor token.
     */
    private class PicklistEntryWrapper {
        public String active;
        public String defaultValue;
        public String label;
        public String value;
        public String validFor;
    }
}
