/**
 * Main controller for Dynamic Filter LWC components.
 * Provides methods to retrieve metadata, execute searches, and handle bulk actions.
 */
public with sharing class DynamicFilterController {
    
    /**
     * Retrieves all available Salesforce objects accessible to the current user.
     * @return List of ObjectInfo wrappers containing object metadata
     * @example
     * List<DynamicFilterController.ObjectInfo> objects = DynamicFilterController.getAvailableObjects();
     */
    @AuraEnabled(cacheable=true)
    public static List<ObjectInfo> getAvailableObjects() {
        List<ObjectInfo> result = new List<ObjectInfo>();
        
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        
        for (String objectName : globalDescribe.keySet()) {
            Schema.SObjectType objType = globalDescribe.get(objectName);
            Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
            
            // Only include objects that are accessible, queryable, and not deprecated
            if (objDescribe.isAccessible() && 
                objDescribe.isQueryable() && 
                !objDescribe.isDeprecatedAndHidden()) {
                
                result.add(new ObjectInfo(
                    objDescribe.getName(),
                    objDescribe.getLabel(),
                    objDescribe.getLabelPlural()
                ));
            }
        }
        
        result.sort();
        return result;
    }
    
    /**
     * Retrieves all fields for a given object that are accessible to the current user.
     * @param objectApiName The API name of the object
     * @return List of FieldInfo wrappers containing field metadata
     * @example
     * List<DynamicFilterController.FieldInfo> fields = DynamicFilterController.getObjectFields('Account');
     */
    @AuraEnabled(cacheable=true)
    public static List<FieldInfo> getObjectFields(String objectApiName) {
        if (String.isBlank(objectApiName)) {
            throw new AuraHandledException('Object API Name is required');
        }
        
        List<FieldInfo> result = new List<FieldInfo>();
        
        try {
            Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectApiName);
            if (objType == null) {
                throw new AuraHandledException('Object not found: ' + objectApiName);
            }
            
            Map<String, Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap();
            
            for (String fieldName : fieldMap.keySet()) {
                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
                
                // Only include accessible fields
                if (fieldDescribe.isAccessible()) {
                    result.add(new FieldInfo(
                        fieldDescribe.getName(),
                        fieldDescribe.getLabel(),
                        fieldDescribe.getType().name()
                    ));
                }
            }
            
            result.sort();
            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving fields: ' + e.getMessage());
        }
    }
    
    /**
     * Executes a dynamic search based on filter configuration and user inputs.
     * @param configId The Filter Configuration record Id
     * @param filterValues Map of field API names to their filter values
     * @return SearchResult wrapper containing records and metadata
     * @example
     * Map<String, Object> filters = new Map<String, Object>{'Status' => 'Open'};
     * DynamicFilterController.SearchResult result = DynamicFilterController.searchRecords('a0X...', filters);
     */
    @AuraEnabled
    public static SearchResult searchRecords(String configId, Map<String, Object> filterValues) {
        if (String.isBlank(configId)) {
            throw new AuraHandledException('Configuration ID is required');
        }
        
        try {
            return DynamicFilterService.searchRecords(configId, filterValues);
        } catch (Exception e) {
            throw new AuraHandledException('Search failed: ' + e.getMessage());
        }
    }
    
    
    /**
     * Retrieves active filter configurations.
     * @return List of active Filter_Configuration__c records
     * @example
     * List<Filter_Configuration__c> configs = DynamicFilterController.getActiveConfigurations();
     */
    @AuraEnabled(cacheable=true)
    public static List<Filter_Configuration__c> getActiveConfigurations() {
        return [
            SELECT Id, Name, Label__c, Object_API_Name__c, Grid_Columns__c
            FROM Filter_Configuration__c
            WITH USER_MODE
            ORDER BY Label__c ASC
        ];
    }
    
    /**
     * Retrieves active filtean en urations for App Builder picklist datasource.
     * Returns data in the format required by Lightning App Builder (VisualEditor.DataSource).
     * @return VisualEditor.DynamicPickListRows containing configuration options
     * @example Used automatically by Lightning App Builder when configuring the component
     */
    @AuraEnabled(cacheable=true)
    public static VisualEditor.DynamicPickListRows getConfigurationPicklistValues() {
        VisualEditor.DynamicPickListRows picklistValues = new VisualEditor.DynamicPickListRows();
        
        List<Filter_Configuration__c> configs = [
            SELECT Id, Label__c
            FROM Filter_Configuration__c
            WITH USER_MODE
            ORDER BY Label__c ASC
        ];
        
        for (Filter_Configuration__c config : configs) {
            VisualEditor.DataRow row = new VisualEditor.DataRow(config.Label__c, config.Id);
            picklistValues.addRow(row);
        }
        
        return picklistValues;
    }
    
    /**
     * Retrieves configuration details including filter fields.
     * @param configId The Filter Configuration record Id
     * @return ConfigurationDetails wrapper containing configuration and filter fields
     * @example
     * DynamicFilterController.ConfigurationDetails details = DynamicFilterController.getConfigurationDetails('a0X...');
     */
    @AuraEnabled(cacheable=true)
    public static ConfigurationDetails getConfigurationDetails(String configId) {
        if (String.isBlank(configId)) {
            throw new AuraHandledException('Configuration ID is required');
        }
        
        try {
            ConfigurationDetails details = new ConfigurationDetails();
            
            // Get configuration
            List<Filter_Configuration__c> configs = [
                SELECT Id, Name, Label__c, Object_API_Name__c, Grid_Columns__c, 
                       Display_Mode__c, List_View_API_Name__c
                FROM Filter_Configuration__c
                WHERE Id = :configId
                WITH USER_MODE
                LIMIT 1
            ];
            
            if (configs.isEmpty()) {
                throw new AuraHandledException('Configuration not found');
            }
            
            details.configuration = configs[0];
            
            // Get filter fields
            details.filterFields = [
                SELECT Id, Field_API_Name__c, Field_Label__c, Field_Type__c, 
                       Grid_Position__c, Order__c, Is_Multi_Search__c, Multi_Search_Separator__c
                FROM Filter_Field__c
                WHERE Filter_Configuration__c = :configId
                WITH USER_MODE
                ORDER BY Order__c ASC NULLS LAST, Field_Label__c ASC
            ];
            
            return details;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving configuration details: ' + e.getMessage());
        }
    }
    
    /**
     * Retrieves Search Layout fields for a given object.
     * These are the fields typically shown in global search results.
     * @param objectApiName The API name of the object
     * @return List of FieldInfo wrappers containing field metadata
     * @example
     * List<DynamicFilterController.FieldInfo> fields = DynamicFilterController.getSearchLayoutFields('Account');
     */
    @AuraEnabled(cacheable=true)
    public static List<FieldInfo> getSearchLayoutFields(String objectApiName) {
        if (String.isBlank(objectApiName)) {
            throw new AuraHandledException('Object API Name is required');
        }
        
        List<FieldInfo> result = new List<FieldInfo>();
        
        try {
            Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectApiName);
            if (objType == null) {
                throw new AuraHandledException('Object not found: ' + objectApiName);
            }
            
            Map<String, Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap();
            
            // Get commonly used searchable fields
            // In a production environment, you would query SearchLayout metadata
            // For now, we filter by commonly searchable field properties
            for (String fieldName : fieldMap.keySet()) {
                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
                
                // Include fields that are:
                // - Accessible and filterable
                // - Not system fields (except Name)
                // - Commonly used in searches
                if (fieldDescribe.isAccessible() && 
                    fieldDescribe.isFilterable() &&
                    (fieldDescribe.isNameField() || 
                     fieldDescribe.isCustom() ||
                     isCommonSearchField(fieldDescribe.getName()))) {
                    
                    result.add(new FieldInfo(
                        fieldDescribe.getName(),
                        fieldDescribe.getLabel(),
                        fieldDescribe.getType().name()
                    ));
                }
            }
            
            result.sort();
            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving search layout fields: ' + e.getMessage());
        }
    }
    
    /**
     * Helper method to identify common search fields.
     */
    private static Boolean isCommonSearchField(String fieldName) {
        Set<String> commonFields = new Set<String>{
            'Name', 'Email', 'Phone', 'Status', 'Type', 'Subject', 
            'Description', 'AccountNumber', 'CaseNumber', 'AppointmentNumber'
        };
        return commonFields.contains(fieldName);
    }
    
    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getPicklistValues(String objectApiName, String fieldApiName) {
        List<PicklistOption> options = new List<PicklistOption>();
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectApiName);
        if (objType == null) {
            return options;
        }
        Schema.SObjectField field = objType.getDescribe().fields.getMap().get(fieldApiName);
        if (field == null) {
            return options;
        }
        for (Schema.PicklistEntry entry : field.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                options.add(new PicklistOption(entry.getLabel(), entry.getValue()));
            }
        }
        return options;
    }

    @AuraEnabled(cacheable=true)
    public static List<LookupOption> searchLookupRecords(String objectApiName, String fieldApiName, String searchTerm) {
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectApiName);
        if (objType == null) return new List<LookupOption>();

        Schema.SObjectField sField = objType.getDescribe().fields.getMap().get(fieldApiName);
        if (sField == null) return new List<LookupOption>();

        List<Schema.SObjectType> refs = sField.getDescribe().getReferenceTo();
        if (refs.isEmpty()) return new List<LookupOption>();

        Schema.SObjectType refType = refs[0];
        if (!refType.getDescribe().isAccessible() || !refType.getDescribe().isQueryable()) {
            return new List<LookupOption>();
        }
        String refObjectName = refType.getDescribe().getName();

        List<LookupOption> options = new List<LookupOption>();
        if (String.isBlank(searchTerm)) {
            String q = 'SELECT Id, Name FROM ' + refObjectName + ' WITH USER_MODE ORDER BY Name ASC LIMIT 20';
            for (SObject record : Database.query(q)) {
                options.add(new LookupOption((String) record.get('Id'), (String) record.get('Name')));
            }
        } else {
            String searchPattern = '%' + String.escapeSingleQuotes(searchTerm.trim()) + '%';
            String q = 'SELECT Id, Name FROM ' + refObjectName + ' WHERE Name LIKE :searchPattern WITH USER_MODE ORDER BY Name ASC LIMIT 20';
            for (SObject record : Database.query(q)) {
                options.add(new LookupOption((String) record.get('Id'), (String) record.get('Name')));
            }
        }
        return options;
    }

    @AuraEnabled
    public static void markForDispatcher(String objectApiName, List<Id> recordIds) {
        DispatcherPinService.markForDispatcher(objectApiName, recordIds);
    }

    @AuraEnabled
    public static Integer clearDispatcherFilter(String objectApiName) {
        return DispatcherPinService.clearDispatcherFilter(objectApiName);
    }

    /**
     * Wrapper class for object metadata.
     */
    public class ObjectInfo implements Comparable {
        @AuraEnabled public String apiName { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String labelPlural { get; set; }
        
        public ObjectInfo(String apiName, String label, String labelPlural) {
            this.apiName = apiName;
            this.label = label;
            this.labelPlural = labelPlural;
        }
        
        public Integer compareTo(Object compareTo) {
            ObjectInfo other = (ObjectInfo) compareTo;
            return this.label.compareTo(other.label);
        }
    }
    
    /**
     * Wrapper class for field metadata.
     */
    public class FieldInfo implements Comparable {
        @AuraEnabled public String apiName { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String fieldType { get; set; }
        
        public FieldInfo(String apiName, String label, String fieldType) {
            this.apiName = apiName;
            this.label = label;
            this.fieldType = fieldType;
        }
        
        public Integer compareTo(Object compareTo) {
            FieldInfo other = (FieldInfo) compareTo;
            return this.label.compareTo(other.label);
        }
    }
    
    /**
     * Wrapper class for search results.
     */
    public class SearchResult {
        @AuraEnabled public List<SObject> records { get; set; }
        @AuraEnabled public Integer totalCount { get; set; }
        @AuraEnabled public List<ColumnDefinition> columns { get; set; }
        
        public SearchResult() {
            this.records = new List<SObject>();
            this.totalCount = 0;
            this.columns = new List<ColumnDefinition>();
        }
    }
    
    /**
     * Wrapper class for datatable column definitions.
     */
    public class ColumnDefinition {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String fieldName { get; set; }
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public Integer initialWidth { get; set; }
        
        public ColumnDefinition(String label, String fieldName, String type, Integer initialWidth) {
            this.label = label;
            this.fieldName = fieldName;
            this.type = type;
            this.initialWidth = initialWidth;
        }
    }
    
    /**
     * Wrapper class for configuration details.
     */
    public class ConfigurationDetails {
        @AuraEnabled public Filter_Configuration__c configuration { get; set; }
        @AuraEnabled public List<Filter_Field__c> filterFields { get; set; }

        public ConfigurationDetails() {
            this.filterFields = new List<Filter_Field__c>();
        }
    }

    /**
     * Wrapper class for lookup search results.
     */
    public class LookupOption {
        @AuraEnabled public String value { get; set; }
        @AuraEnabled public String label { get; set; }

        public LookupOption(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }

    /**
     * Wrapper class for picklist options.
     */
    public class PicklistOption {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }

        public PicklistOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getDefaultConfigurationName() {
        List<Dynamic_Filter_Setting__mdt> settings = [
            SELECT Configuration_Name__c
            FROM Dynamic_Filter_Setting__mdt
            WHERE Configuration_Name__c != null
            LIMIT 1
        ];
        if (!settings.isEmpty() && String.isNotBlank(settings[0].Configuration_Name__c)) {
            return settings[0].Configuration_Name__c;
        }
        return null;
    }

    @AuraEnabled(cacheable=true)
    public static String getConfigurationIdByName(String configName) {
        List<Filter_Configuration__c> configs = [
            SELECT Id
            FROM Filter_Configuration__c
            WHERE Name = :configName AND Active__c = true
            LIMIT 1
        ];
        if (!configs.isEmpty()) {
            return configs[0].Id;
        }
        return null;
    }
}
