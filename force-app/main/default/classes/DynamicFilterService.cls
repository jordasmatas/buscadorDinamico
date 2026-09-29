/**
 * Service class containing business logic for dynamic filtering.
 * Handles SOQL construction, FLS validation, and result processing.
 */
public with sharing class DynamicFilterService {
    
    /**
     * Executes a dynamic search based on configuration and filter values.
     * Uses Search Layout fields for display columns automatically.
     * @param configId The Filter Configuration record Id
     * @param filterValues Map of field API names to their values
     * @return SearchResult with records and column definitions
     */
    public static DynamicFilterController.SearchResult searchRecords(String configId, Map<String, Object> filterValues) {
        DynamicFilterController.SearchResult result = new DynamicFilterController.SearchResult();
        
        // Query configuration with related filter fields
        Filter_Configuration__c config = [
            SELECT Id, Object_API_Name__c, Prefilter_Enabled__c, Prefilter_Field__c, Prefilter_Values__c,
                (SELECT Field_API_Name__c, Is_Multi_Search__c, Order__c
                 FROM Filter_Fields__r
                 ORDER BY Order__c NULLS LAST, Id)
            FROM Filter_Configuration__c
            WHERE Id = :configId
            WITH USER_MODE
        ];
        
        String objectName = config.Object_API_Name__c;
        
        // Validate object access
        Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectName);
        if (sObjType == null || !sObjType.getDescribe().isAccessible()) {
            throw new DynamicFilterServiceException('Object not accessible: ' + objectName);
        }
        
        Map<String, Schema.SObjectField> fieldMap = sObjType.getDescribe().fields.getMap();

        // Build column definitions from the DynamicSearch FieldSet
        Schema.FieldSet fs = sObjType.getDescribe().fieldSets.getMap().get('DynamicSearch');
        if (fs != null) {
            for (Schema.FieldSetMember fsm : fs.getFields()) {
                Schema.SObjectField field = fieldMap.get(fsm.getFieldPath());
                if (field != null && field.getDescribe().isAccessible()) {
                    result.columns.add(new DynamicFilterController.ColumnDefinition(
                        fsm.getLabel(),
                        fsm.getFieldPath(),
                        getFieldTypeForDatatable(field.getDescribe().getType()),
                        null
                    ));
                }
            }
        }
        
        // Build SOQL query
        String query = buildDynamicQuery(config, filterValues, fieldMap, result.columns);
        
        // Execute query
        result.records = Database.query(query);
        result.totalCount = result.records.size();
        
        return result;
    }
    
    /**
     * Builds a dynamic SOQL query based on configuration and filter values.
     */
    @TestVisible
    private static String buildDynamicQuery(
        Filter_Configuration__c config, 
        Map<String, Object> filterValues,
        Map<String, Schema.SObjectField> fieldMap,
        List<DynamicFilterController.ColumnDefinition> columns
    ) {
        Set<String> selectFields = new Set<String>{'Id'};
        
        // Add display fields from columns
        for (DynamicFilterController.ColumnDefinition col : columns) {
            selectFields.add(col.fieldName);
        }
        
        // Build SELECT clause
        String query = 'SELECT ' + String.join(new List<String>(selectFields), ', ');
        query += ' FROM ' + config.Object_API_Name__c;
        
        // Build WHERE clause
        List<String> whereClauses = new List<String>();
        
        for (Filter_Field__c filterField : config.Filter_Fields__r) {
            String fieldName = filterField.Field_API_Name__c;
            
            if (!filterValues.containsKey(fieldName)) {
                continue;
            }
            
            Object fieldValue = filterValues.get(fieldName);
            if (fieldValue == null || String.valueOf(fieldValue).trim() == '') {
                continue;
            }
            
            Schema.SObjectField field = fieldMap.get(fieldName);
            if (field == null || !field.getDescribe().isAccessible()) {
                continue;
            }
            
            Schema.DisplayType fieldType = field.getDescribe().getType();
            
            // Handle multi-search (OR logic with space-separated values)
            if (filterField.Is_Multi_Search__c) {
                List<String> values = String.valueOf(fieldValue).trim().split('\\s+');
                if (!values.isEmpty()) {
                    List<String> orClauses = new List<String>();
                    for (String val : values) {
                        if (String.isNotBlank(val)) {
                            orClauses.add(buildWildcardClause(fieldName, val));
                        }
                    }
                    if (!orClauses.isEmpty()) {
                        whereClauses.add('(' + String.join(orClauses, ' OR ') + ')');
                    }
                }
            } else {
                // Single value search
                String clause = buildWhereClause(fieldName, fieldValue, fieldType);
                if (clause != null) {
                    whereClauses.add(clause);
                }
            }
        }
        
        // Apply prefilter if enabled
        if (config.Prefilter_Enabled__c && String.isNotBlank(config.Prefilter_Field__c) && String.isNotBlank(config.Prefilter_Values__c)) {
            List<String> prefilterVals = config.Prefilter_Values__c.split(';');
            List<String> escapedVals = new List<String>();
            for (String val : prefilterVals) {
                if (String.isNotBlank(val)) {
                    escapedVals.add('\'' + String.escapeSingleQuotes(val.trim()) + '\'');
                }
            }
            if (!escapedVals.isEmpty()) {
                whereClauses.add(config.Prefilter_Field__c + ' IN (' + String.join(escapedVals, ', ') + ')');
            }
        }

        if (!whereClauses.isEmpty()) {
            query += ' WHERE ' + String.join(whereClauses, ' AND ');
        }

        query += ' WITH USER_MODE LIMIT 2000';
        
        return query;
    }
    
    /**
     * Builds a WHERE clause for a single field based on its type.
     */
    private static String buildWhereClause(String fieldName, Object fieldValue, Schema.DisplayType fieldType) {
        if (fieldValue == null) {
            return null;
        }
        
        String strValue = String.valueOf(fieldValue).trim();
        if (String.isBlank(strValue)) {
            return null;
        }
        
        switch on fieldType {
            when PICKLIST, MULTIPICKLIST {
                return buildPicklistClause(fieldName, strValue);
            }
            when STRING, TEXTAREA, EMAIL, PHONE, URL {
                return buildWildcardClause(fieldName, strValue);
            }
            when BOOLEAN {
                Boolean boolValue = Boolean.valueOf(strValue);
                return fieldName + ' = ' + boolValue;
            }
            when INTEGER, LONG {
                try {
                    Long longValue = Long.valueOf(strValue);
                    return fieldName + ' = ' + longValue;
                } catch (Exception e) {
                    return null;
                }
            }
            when DOUBLE, CURRENCY, PERCENT {
                try {
                    Decimal decValue = Decimal.valueOf(strValue);
                    return fieldName + ' = ' + decValue;
                } catch (Exception e) {
                    return null;
                }
            }
            when DATE {
                return buildDateRangeClause(fieldName, strValue, false);
            }
            when DATETIME {
                return buildDateRangeClause(fieldName, strValue, true);
            }
            when REFERENCE {
                return buildLookupClause(fieldName, strValue);
            }
            when else {
                String escapedValue = String.escapeSingleQuotes(strValue);
                return fieldName + ' = \'' + escapedValue + '\'';
            }
        }
    }
    
    /**
     * Builds a LIKE or = clause translating user wildcards (* → %, + → _).
     * If no wildcards are present, uses exact match (=).
     */
    private static String buildWildcardClause(String fieldName, String rawValue) {
        String escapedValue = String.escapeSingleQuotes(rawValue.trim());
        Boolean hasWildcards = escapedValue.contains('*') || escapedValue.contains('+');
        if (hasWildcards) {
            String likeValue = escapedValue.replace('*', '%').replace('+', '_');
            return fieldName + ' LIKE \'' + likeValue + '\'';
        }
        return fieldName + ' = \'' + escapedValue + '\'';
    }

    /**
     * Builds an IN clause for picklist fields. Supports multiple values separated by |PICKLIST|.
     */
    private static String buildPicklistClause(String fieldName, String rawValue) {
        List<String> values;
        if (rawValue.contains('|PICKLIST|')) {
            values = rawValue.split('\\|PICKLIST\\|');
        } else {
            values = new List<String>{ rawValue };
        }

        List<String> escapedVals = new List<String>();
        for (String val : values) {
            if (String.isNotBlank(val)) {
                escapedVals.add('\'' + String.escapeSingleQuotes(val.trim()) + '\'');
            }
        }
        if (escapedVals.isEmpty()) {
            return null;
        }
        if (escapedVals.size() == 1) {
            return fieldName + ' = ' + escapedVals[0];
        }
        return fieldName + ' IN (' + String.join(escapedVals, ', ') + ')';
    }

    /**
     * Builds a date/datetime range clause from the format "startValue|endValue".
     * Supports: both values (BETWEEN), only start (>=), only end (<=), or single value (=).
     */
    private static String buildDateRangeClause(String fieldName, String rawValue, Boolean isDateTime) {
        if (rawValue.contains('|')) {
            List<String> parts = rawValue.split('\\|', -1);
            String startVal = parts[0].trim();
            String endVal = parts.size() > 1 ? parts[1].trim() : '';

            if (isDateTime) {
                String startFormatted = formatDateTimeForSOQL(startVal, true);
                String endFormatted = formatDateTimeForSOQL(endVal, false);
                if (String.isNotBlank(startFormatted) && String.isNotBlank(endFormatted)) {
                    return fieldName + ' >= ' + startFormatted + ' AND ' + fieldName + ' <= ' + endFormatted;
                } else if (String.isNotBlank(startFormatted)) {
                    return fieldName + ' >= ' + startFormatted;
                } else if (String.isNotBlank(endFormatted)) {
                    return fieldName + ' <= ' + endFormatted;
                }
            } else {
                Date startDate = String.isNotBlank(startVal) ? Date.valueOf(startVal) : null;
                Date endDate = String.isNotBlank(endVal) ? Date.valueOf(endVal) : null;
                if (startDate != null && endDate != null) {
                    return fieldName + ' >= ' + String.valueOf(startDate) + ' AND ' + fieldName + ' <= ' + String.valueOf(endDate);
                } else if (startDate != null) {
                    return fieldName + ' >= ' + String.valueOf(startDate);
                } else if (endDate != null) {
                    return fieldName + ' <= ' + String.valueOf(endDate);
                }
            }
            return null;
        }
        // Fallback: single value exact match
        if (isDateTime) {
            String formatted = formatDateTimeForSOQL(rawValue, true);
            return String.isNotBlank(formatted) ? fieldName + ' = ' + formatted : null;
        }
        try {
            Date dateValue = Date.valueOf(rawValue);
            return fieldName + ' = ' + String.valueOf(dateValue);
        } catch (Exception e) {
            return null;
        }
    }

    private static String buildLookupClause(String fieldName, String rawValue) {
        List<String> ids;
        if (rawValue.contains('|LOOKUP|')) {
            ids = rawValue.split('\\|LOOKUP\\|');
        } else {
            ids = new List<String>{ rawValue };
        }
        List<String> escaped = new List<String>();
        for (String id : ids) {
            if (String.isNotBlank(id)) {
                escaped.add('\'' + String.escapeSingleQuotes(id.trim()) + '\'');
            }
        }
        if (escaped.isEmpty()) return null;
        if (escaped.size() == 1) return fieldName + ' = ' + escaped[0];
        return fieldName + ' IN (' + String.join(escaped, ', ') + ')';
    }

    private static String formatDateTimeForSOQL(String val, Boolean isStart) {
        if (String.isBlank(val)) {
            return null;
        }
        // Format: "2026-05-21T14:30:00+02:00" (with tz offset) or "2026-05-21T14:30" (legacy, treated as UTC)
        if (val.contains('T')) {
            // Check if the value already carries a timezone offset (+HH:MM or -HH:MM)
            // An offset always appears after the time portion, e.g. T14:30:00+02:00 or T14:30-05:00
            String timePortion = val.substringAfter('T');
            Boolean hasOffset = timePortion.contains('+') ||
                                (timePortion.contains('-') && timePortion.indexOf('-') > 0);
            if (hasOffset) {
                // Already has timezone — pass through as-is to SOQL
                return val;
            }
            // No offset: legacy plain format, append seconds if missing, default to UTC
            List<String> dtParts = val.split('T');
            String datePart = dtParts[0];
            String timePart = dtParts[1];
            if (timePart.length() == 5) {
                timePart += ':00';
            }
            return datePart + 'T' + timePart + 'Z';
        }
        // Date only - add start/end of day in UTC (date-only fields have no time component)
        if (isStart) {
            return val + 'T00:00:00Z';
        }
        return val + 'T23:59:59Z';
    }

    /**
     * Maps Salesforce field types to lightning-datatable types.
     */
    private static String getFieldTypeForDatatable(Schema.DisplayType fieldType) {
        switch on fieldType {
            when BOOLEAN {
                return 'boolean';
            }
            when CURRENCY {
                return 'currency';
            }
            when DATE {
                return 'date';
            }
            when DATETIME {
                return 'date';
            }
            when EMAIL {
                return 'email';
            }
            when PERCENT {
                return 'percent';
            }
            when PHONE {
                return 'phone';
            }
            when URL {
                return 'url';
            }
            when INTEGER, DOUBLE, LONG {
                return 'number';
            }
            when else {
                return 'text';
            }
        }
    }
    
    /**
     * Custom exception for service errors.
     */
    public class DynamicFilterServiceException extends Exception {}
}