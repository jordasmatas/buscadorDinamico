import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getAllObjects from '@salesforce/apex/FilterConfigurationBuilderController.getAllObjects';
import getObjectFields from '@salesforce/apex/FilterConfigurationBuilderController.getObjectFields';
import saveConfiguration from '@salesforce/apex/FilterConfigurationBuilderController.saveConfiguration';
import getConfiguration from '@salesforce/apex/FilterConfigurationBuilderController.getConfiguration';
import getAllConfigurations from '@salesforce/apex/FilterConfigurationBuilderController.getAllConfigurations';
import deleteConfiguration from '@salesforce/apex/FilterConfigurationBuilderController.deleteConfiguration';
import getApexClasses from '@salesforce/apex/FilterConfigurationBuilderController.getApexClasses';
import getFlows from '@salesforce/apex/FilterConfigurationBuilderController.getFlows';
import getPicklistFields from '@salesforce/apex/FilterConfigurationBuilderController.getPicklistFields';
import getPicklistValues from '@salesforce/apex/FilterConfigurationBuilderController.getPicklistValues';

import lbl_FilterConfigurations from '@salesforce/label/c.FCB_FilterConfigurations';
import lbl_NewConfiguration from '@salesforce/label/c.FCB_NewConfiguration';
import lbl_Name from '@salesforce/label/c.FCB_Name';
import lbl_Label from '@salesforce/label/c.FCB_Label';
import lbl_Object from '@salesforce/label/c.FCB_Object';
import lbl_Active from '@salesforce/label/c.FCB_Active';
import lbl_Actions from '@salesforce/label/c.FCB_Actions';
import lbl_Edit from '@salesforce/label/c.FCB_Edit';
import lbl_Delete from '@salesforce/label/c.FCB_Delete';
import lbl_NoConfigurations from '@salesforce/label/c.FCB_NoConfigurations';
import lbl_NewConfigTitle from '@salesforce/label/c.FCB_NewConfigTitle';
import lbl_EditConfigTitle from '@salesforce/label/c.FCB_EditConfigTitle';
import lbl_Back from '@salesforce/label/c.FCB_Back';
import lbl_Save from '@salesforce/label/c.FCB_Save';
import lbl_BasicInformation from '@salesforce/label/c.FCB_BasicInformation';
import lbl_ConfigurationName from '@salesforce/label/c.FCB_ConfigurationName';
import lbl_GridColumns from '@salesforce/label/c.FCB_GridColumns';
import lbl_ObjectAndFields from '@salesforce/label/c.FCB_ObjectAndFields';
import lbl_SelectObject from '@salesforce/label/c.FCB_SelectObject';
import lbl_ChooseObject from '@salesforce/label/c.FCB_ChooseObject';
import lbl_SelectFields from '@salesforce/label/c.FCB_SelectFields';
import lbl_AvailableFields from '@salesforce/label/c.FCB_AvailableFields';
import lbl_SelectedFields from '@salesforce/label/c.FCB_SelectedFields';
import lbl_AddFields from '@salesforce/label/c.FCB_AddFields';
import lbl_ConfigureFilterFields from '@salesforce/label/c.FCB_ConfigureFilterFields';
import lbl_MultiSearch from '@salesforce/label/c.FCB_MultiSearch';
import lbl_SeparatorCharacter from '@salesforce/label/c.FCB_SeparatorCharacter';
import lbl_SeparatorPlaceholder from '@salesforce/label/c.FCB_SeparatorPlaceholder';
import lbl_Remove from '@salesforce/label/c.FCB_Remove';
import lbl_Prefilter from '@salesforce/label/c.FCB_Prefilter';
import lbl_EnablePrefilter from '@salesforce/label/c.FCB_EnablePrefilter';
import lbl_PrefilterField from '@salesforce/label/c.FCB_PrefilterField';
import lbl_SelectPicklistField from '@salesforce/label/c.FCB_SelectPicklistField';
import lbl_PrefilterValues from '@salesforce/label/c.FCB_PrefilterValues';
import lbl_AvailableValues from '@salesforce/label/c.FCB_AvailableValues';
import lbl_SelectedValues from '@salesforce/label/c.FCB_SelectedValues';
import lbl_BulkActions from '@salesforce/label/c.FCB_BulkActions';
import lbl_AddBulkAction from '@salesforce/label/c.FCB_AddBulkAction';
import lbl_ActionLabel from '@salesforce/label/c.FCB_ActionLabel';
import lbl_ActionType from '@salesforce/label/c.FCB_ActionType';
import lbl_ApexClass from '@salesforce/label/c.FCB_ApexClass';
import lbl_FlowApiName from '@salesforce/label/c.FCB_FlowApiName';
import lbl_IconName from '@salesforce/label/c.FCB_IconName';
import lbl_Order from '@salesforce/label/c.FCB_Order';
import lbl_Loading from '@salesforce/label/c.FCB_Loading';
import lbl_ConfirmDelete from '@salesforce/label/c.FCB_ConfirmDelete';
import lbl_ConfigDeleted from '@salesforce/label/c.FCB_ConfigDeleted';
import lbl_ConfigSaved from '@salesforce/label/c.FCB_ConfigSaved';
import lbl_NoFieldSet from '@salesforce/label/c.FCB_NoFieldSet';
import lbl_SelectOneField from '@salesforce/label/c.FCB_SelectOneField';
import lbl_EnterConfigName from '@salesforce/label/c.FCB_EnterConfigName';
import lbl_EnterConfigLabel from '@salesforce/label/c.FCB_EnterConfigLabel';
import lbl_SelectAnObject from '@salesforce/label/c.FCB_SelectAnObject';
import lbl_AddOneField from '@salesforce/label/c.FCB_AddOneField';

export default class FilterConfigurationBuilder extends NavigationMixin(LightningElement) {
    @api recordId;
    @api title = lbl_FilterConfigurations;
    @track configurations = [];
    @track selectedConfigId;
    @track isNewConfig = false;
    @track isLoading = false;

    labels = {
        filterConfigurations: lbl_FilterConfigurations,
        newConfiguration: lbl_NewConfiguration,
        name: lbl_Name,
        label: lbl_Label,
        object: lbl_Object,
        active: lbl_Active,
        actions: lbl_Actions,
        edit: lbl_Edit,
        delete: lbl_Delete,
        noConfigurations: lbl_NoConfigurations,
        newConfigTitle: lbl_NewConfigTitle,
        editConfigTitle: lbl_EditConfigTitle,
        back: lbl_Back,
        save: lbl_Save,
        basicInformation: lbl_BasicInformation,
        configurationName: lbl_ConfigurationName,
        gridColumns: lbl_GridColumns,
        objectAndFields: lbl_ObjectAndFields,
        selectObject: lbl_SelectObject,
        chooseObject: lbl_ChooseObject,
        selectFields: lbl_SelectFields,
        availableFields: lbl_AvailableFields,
        selectedFields: lbl_SelectedFields,
        addFields: lbl_AddFields,
        configureFilterFields: lbl_ConfigureFilterFields,
        multiSearch: lbl_MultiSearch,
        separatorCharacter: lbl_SeparatorCharacter,
        separatorPlaceholder: lbl_SeparatorPlaceholder,
        remove: lbl_Remove,
        prefilter: lbl_Prefilter,
        enablePrefilter: lbl_EnablePrefilter,
        prefilterField: lbl_PrefilterField,
        selectPicklistField: lbl_SelectPicklistField,
        prefilterValues: lbl_PrefilterValues,
        availableValues: lbl_AvailableValues,
        selectedValues: lbl_SelectedValues,
        bulkActions: lbl_BulkActions,
        addBulkAction: lbl_AddBulkAction,
        actionLabel: lbl_ActionLabel,
        actionType: lbl_ActionType,
        apexClass: lbl_ApexClass,
        flowApiName: lbl_FlowApiName,
        iconName: lbl_IconName,
        order: lbl_Order,
        loading: lbl_Loading
    };

    // Configuration data
    @track configName = '';
    @track configLabel = '';
    @track gridColumns = 3;
    @track isActive = true;
    @track selectedObject = '';
    @track selectedFields = [];

    // Available options
    @track objectOptions = [];
    @track fieldOptions = [];

    // Selected fields with configuration
    @track configuredFields = [];

    // Prefilter
    @track prefilterEnabled = false;
    @track prefilterField = '';
    @track prefilterValues = [];
    @track picklistFieldOptions = [];
    @track picklistValueOptions = [];

    // Bulk actions
    @track bulkActions = [];
    @track actionTypeOptions = [
        { label: 'Apex', value: 'Apex' },
        { label: 'Flow', value: 'Flow' }
    ];
    @track apexClassOptions = [];
    @track flowOptions = [];

    // Display columns
    @track displayColumns = [];

    // UI state
    @track showFieldSelector = false;
    @track showConfigList = true;
    @track showConfigForm = false;

    connectedCallback() {
        this.loadConfigurations();
        this.loadObjects();
        this.loadApexClasses();
        this.loadFlows();
    }

    loadConfigurations() {
        this.isLoading = true;
        getAllConfigurations()
            .then(result => {
                this.configurations = result;
            })
            .catch(error => {
                this.showToast('Error', 'Error loading configurations: ' + error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    loadObjects() {
        getAllObjects()
            .then(result => {
                this.objectOptions = result.map(obj => ({
                    label: obj.label + ' (' + obj.value + ')',
                    value: obj.value
                }));
            })
            .catch(error => {
                this.showToast('Error', 'Error loading objects: ' + error.body.message, 'error');
            });
    }

    loadApexClasses() {
        getApexClasses()
            .then(result => {
                this.apexClassOptions = result.map(cls => ({
                    label: cls.label,
                    value: cls.value
                }));
            })
            .catch(error => {
                this.showToast('Error', 'Error loading Apex classes: ' + error.body.message, 'error');
            });
    }

    loadFlows() {
        getFlows()
            .then(result => {
                this.flowOptions = result.map(flow => ({
                    label: flow.label,
                    value: flow.value
                }));
            })
            .catch(error => {
                this.showToast('Error', 'Error loading Flows: ' + error.body.message, 'error');
            });
    }

    handleNewConfig() {
        this.isNewConfig = true;
        this.showConfigList = false;
        this.showConfigForm = true;
        this.resetForm();
    }

    handleEditConfig(event) {
        const configId = event.currentTarget.dataset.id;
        this.selectedConfigId = configId;
        this.isNewConfig = false;
        this.showConfigList = false;
        this.showConfigForm = true;
        this.loadConfigurationData(configId);
    }

    handleDeleteConfig(event) {
        const configId = event.currentTarget.dataset.id;
        if (confirm(lbl_ConfirmDelete)) {
            deleteConfiguration({ configId })
                .then(() => {
                    this.showToast('Success', lbl_ConfigDeleted, 'success');
                    this.loadConfigurations();
                })
                .catch(error => {
                    this.showToast('Error', 'Error deleting configuration: ' + error.body.message, 'error');
                });
        }
    }

    handleBackToList() {
        this.showConfigList = true;
        this.showConfigForm = false;
        this.loadConfigurations();
    }

    loadConfigurationData(configId) {
        this.isLoading = true;
        getConfiguration({ configId })
            .then(result => {
                this.configName = result.configuration.Name;
                this.configLabel = result.configuration.Label__c;
                this.gridColumns = result.configuration.Grid_Columns__c;
                this.isActive = result.configuration.Active__c;
                this.selectedObject = result.configuration.Object_API_Name__c;
                this.prefilterEnabled = result.configuration.Prefilter_Enabled__c || false;
                this.prefilterField = result.configuration.Prefilter_Field__c || '';
                this.prefilterValues = result.configuration.Prefilter_Values__c
                    ? result.configuration.Prefilter_Values__c.split(';')
                    : [];

                if (this.selectedObject) {
                    this.loadObjectFields();
                    this.loadPicklistFields();
                    if (this.prefilterField) {
                        this.loadPicklistValuesForField();
                    }
                }

                this.configuredFields = result.filterFields.map((ff, index) => ({
                    ...ff,
                    key: 'field-' + index
                }));

                this.displayColumns = result.displayColumns;

                this.bulkActions = result.bulkActions.map((ba, index) => ({
                    key: 'action-' + index,
                    id: ba.Id,
                    actionLabel: ba.Action_Label__c,
                    actionType: ba.Action_Type__c,
                    apexClass: ba.Apex_Class__c || '',
                    flowApiName: ba.Flow_API_Name__c || '',
                    iconName: ba.Icon_Name__c || 'utility:check',
                    order: ba.Order__c || (index + 1),
                    isApexType: ba.Action_Type__c === 'Apex',
                    isFlowType: ba.Action_Type__c === 'Flow'
                }));
            })
            .catch(error => {
                this.showToast('Error', 'Error loading configuration: ' + error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleInputChange(event) {
        const field = event.currentTarget.dataset.field;
        const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
        this[field] = value;
    }

    handleObjectChange(event) {
        this.selectedObject = event.detail.value;
        this.selectedFields = [];
        this.configuredFields = [];
        this.prefilterField = '';
        this.prefilterValues = [];
        this.picklistFieldOptions = [];
        this.picklistValueOptions = [];
        if (this.selectedObject) {
            this.loadObjectFields();
            this.loadPicklistFields();
        }
    }

    loadObjectFields() {
        this.isLoading = true;
        getObjectFields({ objectName: this.selectedObject })
            .then(result => {
                if (result.length === 0) {
                    this.showToast('Info', lbl_NoFieldSet, 'info');
                    this.fieldOptions = [];
                    this.showFieldSelector = false;
                } else {
                    this.fieldOptions = result.map(field => ({
                        label: field.label + ' (' + field.value + ')',
                        value: field.value,
                        type: field.type
                    }));
                    this.showFieldSelector = true;
                }
            })
            .catch(error => {
                this.showToast('Error', 'Error loading fields: ' + error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleFieldSelection(event) {
        this.selectedFields = event.detail.value;
    }

    handleAddFields() {
        if (this.selectedFields.length === 0) {
            this.showToast('Warning', lbl_SelectOneField, 'warning');
            return;
        }

        const newFields = this.selectedFields.map((fieldValue, index) => {
            const fieldOption = this.fieldOptions.find(opt => opt.value === fieldValue);
            return {
                key: 'field-' + Date.now() + '-' + index,
                fieldApiName: fieldValue,
                fieldLabel: fieldOption ? fieldOption.label.split(' (')[0] : fieldValue,
                fieldType: fieldOption ? this.mapFieldType(fieldOption.type) : 'Text',
                orderNumber: this.configuredFields.length + index + 1,
                isMultiSearch: false,
                multiSearchSeparator: ' '
            };
        });

        this.configuredFields = [...this.configuredFields, ...newFields];
        this.selectedFields = [];
    }

    mapFieldType(sfType) {
        const typeMap = {
            'STRING': 'Text',
            'PICKLIST': 'Picklist',
            'DATE': 'Date',
            'DATETIME': 'DateTime',
            'DOUBLE': 'Number',
            'INTEGER': 'Number',
            'CURRENCY': 'Number',
            'PERCENT': 'Number',
            'BOOLEAN': 'Checkbox',
            'REFERENCE': 'Lookup'
        };
        return typeMap[sfType.toUpperCase()] || 'Text';
    }

    handleFieldConfigChange(event) {
        const fieldKey = event.currentTarget.dataset.key;
        const fieldName = event.currentTarget.dataset.field;
        const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;

        this.configuredFields = this.configuredFields.map(field => {
            if (field.key === fieldKey) {
                return { ...field, [fieldName]: value };
            }
            return field;
        });
    }

    handleRemoveField(event) {
        const fieldKey = event.currentTarget.dataset.key;
        this.configuredFields = this.configuredFields.filter(field => field.key !== fieldKey);
        this.reorderFields();
    }

    handleFieldDragStart(event) {
        event.dataTransfer.effectAllowed = 'move';
        event.dataTransfer.setData('text/plain', event.currentTarget.dataset.key);
    }

    handleFieldDragOver(event) {
        event.preventDefault();
        event.dataTransfer.dropEffect = 'move';
    }

    handleFieldDrop(event) {
        event.preventDefault();
        const draggedKey = event.dataTransfer.getData('text/plain');
        const targetKey = event.currentTarget.dataset.key;

        if (draggedKey === targetKey) return;

        const draggedIndex = this.configuredFields.findIndex(f => f.key === draggedKey);
        const targetIndex = this.configuredFields.findIndex(f => f.key === targetKey);

        const fields = [...this.configuredFields];
        const [draggedField] = fields.splice(draggedIndex, 1);
        fields.splice(targetIndex, 0, draggedField);

        this.configuredFields = fields;
        this.reorderFields();
    }

    reorderFields() {
        this.configuredFields = this.configuredFields.map((field, index) => ({
            ...field,
            orderNumber: index + 1
        }));
    }

    loadPicklistFields() {
        getPicklistFields({ objectName: this.selectedObject })
            .then(result => {
                this.picklistFieldOptions = result.map(f => ({
                    label: f.label + ' (' + f.value + ')',
                    value: f.value
                }));
            })
            .catch(error => {
                this.showToast('Error', 'Error loading picklist fields: ' + (error.body?.message || error.message), 'error');
            });
    }

    handlePrefilterEnabledChange(event) {
        this.prefilterEnabled = event.target.checked;
        if (!this.prefilterEnabled) {
            this.prefilterField = '';
            this.prefilterValues = [];
            this.picklistValueOptions = [];
        }
    }

    handlePrefilterFieldChange(event) {
        this.prefilterField = event.detail.value;
        this.prefilterValues = [];
        this.picklistValueOptions = [];
        if (this.prefilterField) {
            this.loadPicklistValuesForField();
        }
    }

    loadPicklistValuesForField() {
        getPicklistValues({ objectName: this.selectedObject, fieldName: this.prefilterField })
            .then(result => {
                this.picklistValueOptions = result.map(v => ({
                    label: v.label,
                    value: v.value
                }));
            })
            .catch(error => {
                this.showToast('Error', 'Error loading picklist values: ' + (error.body?.message || error.message), 'error');
            });
    }

    handlePrefilterValuesChange(event) {
        this.prefilterValues = event.detail.value;
    }

    handleSave() {
        if (!this.validateForm()) {
            return;
        }

        const configData = {
            configuration: {
                Id: this.selectedConfigId,
                Name: this.configName,
                Label__c: this.configLabel,
                Object_API_Name__c: this.selectedObject,
                Grid_Columns__c: this.gridColumns,
                Active__c: this.isActive,
                Prefilter_Enabled__c: this.prefilterEnabled,
                Prefilter_Field__c: this.prefilterEnabled ? this.prefilterField : null,
                Prefilter_Values__c: this.prefilterEnabled ? this.prefilterValues.join(';') : null
            },
            filterFields: this.configuredFields,
            displayColumns: this.configuredFields.map((field, index) => ({
                Field_API_Name__c: field.fieldApiName,
                Field_Label__c: field.fieldLabel,
                Order__c: index + 1,
                Width__c: 150
            })),
            bulkActions: this.bulkActions.map(action => ({
                Action_Label__c: action.actionLabel,
                Action_Type__c: action.actionType,
                Apex_Class__c: action.actionType === 'Apex' ? action.apexClass : null,
                Flow_API_Name__c: action.actionType === 'Flow' ? action.flowApiName : null,
                Icon_Name__c: action.iconName,
                Order__c: action.order
            }))
        };

        this.isLoading = true;
        saveConfiguration({ configJson: JSON.stringify(configData) })
            .then(() => {
                this.showToast('Success', lbl_ConfigSaved, 'success');
                this.handleBackToList();
            })
            .catch(error => {
                this.showToast('Error', 'Error saving configuration: ' + error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    validateForm() {
        if (!this.configName) {
            this.showToast('Error', lbl_EnterConfigName, 'error');
            return false;
        }
        if (!this.configLabel) {
            this.showToast('Error', lbl_EnterConfigLabel, 'error');
            return false;
        }
        if (!this.selectedObject) {
            this.showToast('Error', lbl_SelectAnObject, 'error');
            return false;
        }
        if (this.configuredFields.length === 0) {
            this.showToast('Error', lbl_AddOneField, 'error');
            return false;
        }
        return true;
    }

    resetForm() {
        this.configName = '';
        this.configLabel = '';
        this.gridColumns = 3;
        this.isActive = true;
        this.selectedObject = '';
        this.selectedFields = [];
        this.configuredFields = [];
        this.bulkActions = [];
        this.displayColumns = [];
        this.showFieldSelector = false;
        this.prefilterEnabled = false;
        this.prefilterField = '';
        this.prefilterValues = [];
        this.picklistFieldOptions = [];
        this.picklistValueOptions = [];
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }

    get configFormTitle() {
        return this.isNewConfig ? lbl_NewConfigTitle : lbl_EditConfigTitle;
    }

    get hasConfiguredFields() {
        return this.configuredFields.length > 0;
    }

    get hasBulkActions() {
        return this.bulkActions.length > 0;
    }

    handleAddBulkAction() {
        const newAction = {
            key: 'action-' + Date.now(),
            actionLabel: '',
            actionType: 'Apex',
            apexClass: '',
            flowApiName: '',
            iconName: 'utility:check',
            order: this.bulkActions.length + 1,
            isApexType: true,
            isFlowType: false
        };
        this.bulkActions = [...this.bulkActions, newAction];
    }

    handleRemoveBulkAction(event) {
        const actionKey = event.currentTarget.dataset.key;
        this.bulkActions = this.bulkActions.filter(action => action.key !== actionKey);
        this.reorderBulkActions();
    }

    handleBulkActionChange(event) {
        const actionKey = event.currentTarget.dataset.key;
        const fieldName = event.currentTarget.dataset.field;
        const value = event.detail.value;

        this.bulkActions = this.bulkActions.map(action => {
            if (action.key === actionKey) {
                const updatedAction = { ...action, [fieldName]: value };

                if (fieldName === 'actionType') {
                    updatedAction.isApexType = value === 'Apex';
                    updatedAction.isFlowType = value === 'Flow';
                    if (value === 'Apex') {
                        updatedAction.flowApiName = '';
                    } else {
                        updatedAction.apexClass = '';
                    }
                }

                return updatedAction;
            }
            return action;
        });
    }

    reorderBulkActions() {
        this.bulkActions = this.bulkActions.map((action, index) => ({
            ...action,
            order: index + 1
        }));
    }
}
