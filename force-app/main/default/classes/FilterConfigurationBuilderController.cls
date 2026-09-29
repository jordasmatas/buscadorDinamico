public with sharing class FilterConfigurationBuilderController {
    
    public class ObjectInfo implements Comparable {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }
        
        public Integer compareTo(Object compareTo) {
            ObjectInfo compareToObj = (ObjectInfo)compareTo;
            if (label == compareToObj.label) return 0;
            if (label > compareToObj.label) return 1;
            return -1;
        }
    }
    
    public class FieldInfo implements Comparable {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }
        @AuraEnabled public String type { get; set; }
        
        public Integer compareTo(Object compareTo) {
            FieldInfo compareToField = (FieldInfo)compareTo;
            if (label == compareToField.label) return 0;
            if (label > compareToField.label) return 1;
            return -1;
        }
    }
    
    public class ConfigurationWrapper {
        @AuraEnabled public Filter_Configuration__c configuration { get; set; }
        @AuraEnabled public List<FilterFieldWrapper> filterFields { get; set; }
        @AuraEnabled public List<Display_Column__c> displayColumns { get; set; }
        @AuraEnabled public List<Bulk_Action__c> bulkActions { get; set; }
    }
    
    public class FilterFieldWrapper {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String fieldApiName { get; set; }
        @AuraEnabled public String fieldLabel { get; set; }
        @AuraEnabled public String fieldType { get; set; }
        @AuraEnabled public Integer orderNumber { get; set; }
        @AuraEnabled public Boolean isMultiSearch { get; set; }
        @AuraEnabled public String multiSearchSeparator { get; set; }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<ObjectInfo> getAllObjects() {
        List<ObjectInfo> objectList = new List<ObjectInfo>();
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        
        for (String objName : globalDescribe.keySet()) {
            Schema.SObjectType objType = globalDescribe.get(objName);
            Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
            
            if (objDescribe.isAccessible() && objDescribe.isQueryable()) {
                ObjectInfo obj = new ObjectInfo();
                obj.label = objDescribe.getLabel();
                obj.value = objDescribe.getName();
                objectList.add(obj);
            }
        }
        
        objectList.sort();
        return objectList;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<FieldInfo> getObjectFields(String objectName) {
        List<FieldInfo> fieldList = new List<FieldInfo>();

        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        if (objType == null) {
            return fieldList;
        }

        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        Schema.FieldSet fs = objDescribe.fieldSets.getMap().get('DynamicSearch');
        if (fs == null) {
            return fieldList;
        }

        for (Schema.FieldSetMember fsm : fs.getFields()) {
            FieldInfo field = new FieldInfo();
            field.label = fsm.getLabel();
            field.value = fsm.getFieldPath();
            field.type = String.valueOf(fsm.getType());
            fieldList.add(field);
        }

        fieldList.sort();
        return fieldList;
    }
    
    @AuraEnabled
    public static ConfigurationWrapper getConfiguration(String configId) {
        try {
            ConfigurationWrapper wrapper = new ConfigurationWrapper();
            
            wrapper.configuration = [
                SELECT Id, Name, Label__c, Object_API_Name__c, Grid_Columns__c, Active__c,
                       Prefilter_Enabled__c, Prefilter_Field__c, Prefilter_Values__c
                FROM Filter_Configuration__c
                WHERE Id = :configId
                LIMIT 1
            ];
            
            List<Filter_Field__c> filterFields = [
                SELECT Id, Field_API_Name__c, Field_Label__c, Field_Type__c, 
                       Order__c, Is_Multi_Search__c, Multi_Search_Separator__c
                FROM Filter_Field__c
                WHERE Filter_Configuration__c = :configId
                ORDER BY Order__c ASC
            ];
            
            wrapper.filterFields = new List<FilterFieldWrapper>();
            for (Filter_Field__c ff : filterFields) {
                FilterFieldWrapper ffw = new FilterFieldWrapper();
                ffw.id = ff.Id;
                ffw.fieldApiName = ff.Field_API_Name__c;
                ffw.fieldLabel = ff.Field_Label__c;
                ffw.fieldType = ff.Field_Type__c;
                ffw.orderNumber = Integer.valueOf(ff.Order__c);
                ffw.isMultiSearch = ff.Is_Multi_Search__c;
                ffw.multiSearchSeparator = ff.Multi_Search_Separator__c;
                wrapper.filterFields.add(ffw);
            }
            
            wrapper.displayColumns = [
                SELECT Id, Field_API_Name__c, Field_Label__c, Order__c, Width__c
                FROM Display_Column__c
                WHERE Filter_Configuration__c = :configId
                ORDER BY Order__c ASC
            ];
            
            wrapper.bulkActions = [
                SELECT Id, Action_Label__c, Action_Type__c, Apex_Class__c, 
                       Flow_API_Name__c, Icon_Name__c, Order__c
                FROM Bulk_Action__c
                WHERE Filter_Configuration__c = :configId
                ORDER BY Order__c ASC
            ];
            
            return wrapper;
        } catch (Exception e) {
            throw new AuraHandledException('Error loading configuration: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String saveConfiguration(String configJson) {
        try {
            ConfigurationWrapper wrapper = (ConfigurationWrapper) JSON.deserialize(
                configJson, 
                ConfigurationWrapper.class
            );
            
            Savepoint sp = Database.setSavepoint();
            
            try {
                upsert wrapper.configuration;
                
                List<Filter_Field__c> existingFields = [
                    SELECT Id FROM Filter_Field__c 
                    WHERE Filter_Configuration__c = :wrapper.configuration.Id
                ];
                if (!existingFields.isEmpty()) {
                    delete existingFields;
                }
                
                List<Filter_Field__c> fieldsToInsert = new List<Filter_Field__c>();
                for (FilterFieldWrapper ffw : wrapper.filterFields) {
                    Filter_Field__c ff = new Filter_Field__c();
                    ff.Filter_Configuration__c = wrapper.configuration.Id;
                    ff.Field_API_Name__c = ffw.fieldApiName;
                    ff.Field_Label__c = ffw.fieldLabel;
                    ff.Field_Type__c = ffw.fieldType;
                    ff.Order__c = ffw.orderNumber;
                    ff.Grid_Position__c = ffw.orderNumber;
                    ff.Is_Multi_Search__c = ffw.isMultiSearch;
                    ff.Multi_Search_Separator__c = ffw.multiSearchSeparator;
                    fieldsToInsert.add(ff);
                }
                if (!fieldsToInsert.isEmpty()) {
                    insert fieldsToInsert;
                }
                
                List<Display_Column__c> existingColumns = [
                    SELECT Id FROM Display_Column__c 
                    WHERE Filter_Configuration__c = :wrapper.configuration.Id
                ];
                if (!existingColumns.isEmpty()) {
                    delete existingColumns;
                }
                
                if (wrapper.displayColumns != null && !wrapper.displayColumns.isEmpty()) {
                    for (Display_Column__c dc : wrapper.displayColumns) {
                        dc.Filter_Configuration__c = wrapper.configuration.Id;
                        dc.Id = null;
                    }
                    insert wrapper.displayColumns;
                }
                
                List<Bulk_Action__c> existingActions = [
                    SELECT Id FROM Bulk_Action__c 
                    WHERE Filter_Configuration__c = :wrapper.configuration.Id
                ];
                if (!existingActions.isEmpty()) {
                    delete existingActions;
                }
                
                if (wrapper.bulkActions != null && !wrapper.bulkActions.isEmpty()) {
                    for (Bulk_Action__c ba : wrapper.bulkActions) {
                        ba.Filter_Configuration__c = wrapper.configuration.Id;
                        ba.Id = null;
                    }
                    insert wrapper.bulkActions;
                }
                
                return wrapper.configuration.Id;
                
            } catch (Exception e) {
                Database.rollback(sp);
                throw e;
            }
            
        } catch (Exception e) {
            throw new AuraHandledException('Error saving configuration: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<Filter_Configuration__c> getAllConfigurations() {
        return [
            SELECT Id, Name, Label__c, Object_API_Name__c, Active__c, CreatedDate
            FROM Filter_Configuration__c
            ORDER BY CreatedDate DESC
        ];
    }
    
    @AuraEnabled
    public static void deleteConfiguration(String configId) {
        try {
            delete [SELECT Id FROM Filter_Configuration__c WHERE Id = :configId];
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting configuration: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<FieldInfo> getPicklistFields(String objectName) {
        List<FieldInfo> picklistFields = new List<FieldInfo>();
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        if (objType == null) {
            return picklistFields;
        }
        Map<String, Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap();
        for (String fieldName : fieldMap.keySet()) {
            Schema.DescribeFieldResult dfr = fieldMap.get(fieldName).getDescribe();
            if (dfr.isAccessible() && dfr.getType() == Schema.DisplayType.PICKLIST) {
                FieldInfo fi = new FieldInfo();
                fi.label = dfr.getLabel();
                fi.value = dfr.getName();
                fi.type = 'PICKLIST';
                picklistFields.add(fi);
            }
        }
        picklistFields.sort();
        return picklistFields;
    }

    @AuraEnabled
    public static List<ObjectInfo> getPicklistValues(String objectName, String fieldName) {
        List<ObjectInfo> values = new List<ObjectInfo>();
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        if (objType == null) {
            return values;
        }
        Schema.SObjectField field = objType.getDescribe().fields.getMap().get(fieldName);
        if (field == null) {
            return values;
        }
        for (Schema.PicklistEntry ple : field.getDescribe().getPicklistValues()) {
            if (ple.isActive()) {
                ObjectInfo oi = new ObjectInfo();
                oi.label = ple.getLabel();
                oi.value = ple.getValue();
                values.add(oi);
            }
        }
        return values;
    }

    @AuraEnabled(cacheable=true)
    public static List<ObjectInfo> getApexClasses() {
        List<ObjectInfo> classList = new List<ObjectInfo>();
        
        for (ApexClass ac : [SELECT Id, Name FROM ApexClass WHERE Status = 'Active' ORDER BY Name]) {
            ObjectInfo obj = new ObjectInfo();
            obj.label = ac.Name;
            obj.value = ac.Name;
            classList.add(obj);
        }
        
        return classList;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<ObjectInfo> getFlows() {
        List<ObjectInfo> flowList = new List<ObjectInfo>();
        
        for (FlowDefinitionView fdv : [SELECT ApiName, Label FROM FlowDefinitionView 
                                        WHERE IsActive = true AND ProcessType = 'AutolaunchedFlow' 
                                        ORDER BY Label
                                        LIMIT 200]) {
            ObjectInfo obj = new ObjectInfo();
            obj.label = fdv.Label;
            obj.value = fdv.ApiName;
            flowList.add(obj);
        }
        
        return flowList;
    }
}
