import { LightningElement, track, wire, api } from 'lwc';
import getActiveConfigurations from '@salesforce/apex/DynamicFilterController.getActiveConfigurations';
import getConfigurationDetails from '@salesforce/apex/DynamicFilterController.getConfigurationDetails';
import getPicklistFieldInfo from '@salesforce/apex/DynamicFilterPicklistHelper.getPicklistFieldInfo';
import searchRecords from '@salesforce/apex/DynamicFilterController.searchRecords';
import searchLookupRecords from '@salesforce/apex/DynamicFilterController.searchLookupRecords';
import markForDispatcher from '@salesforce/apex/DynamicFilterController.markForDispatcher';
import clearDispatcherFilter from '@salesforce/apex/DynamicFilterController.clearDispatcherFilter';
import getConfigurationIdByName from '@salesforce/apex/DynamicFilterController.getConfigurationIdByName';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import lbl_Title from '@salesforce/label/c.DFS_Title';
import lbl_SearchConfiguration from '@salesforce/label/c.DFS_SearchConfiguration';
import lbl_SelectConfiguration from '@salesforce/label/c.DFS_SelectConfiguration';
import lbl_Search from '@salesforce/label/c.DFS_Search';
import lbl_SearchAndSend from '@salesforce/label/c.DFS_SearchAndSend';
import lbl_Clear from '@salesforce/label/c.DFS_Clear';
import lbl_ClearPastResults from '@salesforce/label/c.DFS_ClearPastResults';
import lbl_SelectRange from '@salesforce/label/c.DFS_SelectRange';
import lbl_StartDate from '@salesforce/label/c.DFS_StartDate';
import lbl_EndDate from '@salesforce/label/c.DFS_EndDate';
import lbl_StartTime from '@salesforce/label/c.DFS_StartTime';
import lbl_EndTime from '@salesforce/label/c.DFS_EndTime';
import lbl_Apply from '@salesforce/label/c.DFS_Apply';
import lbl_ClearSelection from '@salesforce/label/c.DFS_ClearSelection';
import lbl_SelectPlaceholder from '@salesforce/label/c.DFS_SelectPlaceholder';
import lbl_Warning from '@salesforce/label/c.DFS_Warning';
import lbl_SelectConfigMessage from '@salesforce/label/c.DFS_SelectConfigMessage';
import lbl_Loading from '@salesforce/label/c.DFS_Loading';
import lbl_RecordsPerPage from '@salesforce/label/c.DFS_RecordsPerPage';
import lbl_Previous from '@salesforce/label/c.DFS_Previous';
import lbl_Next from '@salesforce/label/c.DFS_Next';
import lbl_PageOf from '@salesforce/label/c.DFS_PageOf';
import lbl_NoResultsFound from '@salesforce/label/c.DFS_NoResultsFound';
import lbl_ApplyFiltersMessage from '@salesforce/label/c.DFS_ApplyFiltersMessage';
import lbl_ShowAdvancedSearch from '@salesforce/label/c.DFS_ShowAdvancedSearch';
import lbl_HideAdvancedSearch from '@salesforce/label/c.DFS_HideAdvancedSearch';
import lbl_SendToDispatcher from '@salesforce/label/c.DFS_SendToDispatcher';
import lbl_RecordsFound from '@salesforce/label/c.DFS_RecordsFound';
import lbl_SeparatorSpace from '@salesforce/label/c.DFS_SeparatorSpace';
import lbl_SeparatorLabel from '@salesforce/label/c.DFS_SeparatorLabel';
import lbl_SelectConfigFirst from '@salesforce/label/c.DFS_SelectConfigFirst';
import lbl_RecordsFoundToast from '@salesforce/label/c.DFS_RecordsFoundToast';
import lbl_FiltersCleared from '@salesforce/label/c.DFS_FiltersCleared';
import lbl_SelectAtLeastOneRecord from '@salesforce/label/c.DFS_SelectAtLeastOneRecord';
import lbl_SentToDispatcher from '@salesforce/label/c.DFS_SentToDispatcher';
import lbl_ErrorSendingDispatcher from '@salesforce/label/c.DFS_ErrorSendingDispatcher';
import lbl_NoRecordsToSend from '@salesforce/label/c.DFS_NoRecordsToSend';
import lbl_FoundAndSent from '@salesforce/label/c.DFS_FoundAndSent';
import lbl_ErrorSearchAndSend from '@salesforce/label/c.DFS_ErrorSearchAndSend';
import lbl_ClearedFromDispatcher from '@salesforce/label/c.DFS_ClearedFromDispatcher';
import lbl_ErrorClearing from '@salesforce/label/c.DFS_ErrorClearing';

export default class DynamicFilterSearch extends LightningElement {
    @api title = lbl_Title;
    @api configurationId = '';
    @api configurationName = '';
    @api embeddedMode = false;
    @track selectedConfigId = '';
    @track configurationOptions = [];
    @track filterFields = [];
    @track displayColumns = [];
    @track searchResults = [];
    @track filterValues = {};
    @track isLoading = false;
    @track gridColumns = 3;
    @track isExpanded = false;
    @track objectApiName = '';
    @track searchPerformed = false;
    @track currentPage = 1;
    @track selectedRowIds = [];
    pageSize = 20;
    @track pageSizeValue = '20';

    labels = {
        title: lbl_Title,
        searchConfiguration: lbl_SearchConfiguration,
        selectConfiguration: lbl_SelectConfiguration,
        search: lbl_Search,
        searchAndSend: lbl_SearchAndSend,
        clear: lbl_Clear,
        clearPastResults: lbl_ClearPastResults,
        selectRange: lbl_SelectRange,
        startDate: lbl_StartDate,
        endDate: lbl_EndDate,
        startTime: lbl_StartTime,
        endTime: lbl_EndTime,
        apply: lbl_Apply,
        clearSelection: lbl_ClearSelection,
        selectPlaceholder: lbl_SelectPlaceholder,
        warning: lbl_Warning,
        selectConfigMessage: lbl_SelectConfigMessage,
        loading: lbl_Loading,
        recordsPerPage: lbl_RecordsPerPage,
        previous: lbl_Previous,
        next: lbl_Next,
        noResultsFound: lbl_NoResultsFound,
        applyFiltersMessage: lbl_ApplyFiltersMessage,
        sendToDispatcher: lbl_SendToDispatcher
    };

    // Date range inline state
    @track dateRangeValues = {};

    connectedCallback() {
        if (this.configurationName) {
            this.resolveConfigurationByName();
        } else if (this.configurationId) {
            this.selectedConfigId = this.configurationId;
            this.loadConfigurationDetails();
        }
        if (this.embeddedMode) {
            this.isExpanded = true;
        }
    }

    resolveConfigurationByName() {
        this.isLoading = true;
        getConfigurationIdByName({ configName: this.configurationName })
            .then(result => {
                if (result) {
                    this.selectedConfigId = result;
                    this.loadConfigurationDetails();
                }
            })
            .catch(error => {
                const errorMessage = error.body?.message || error.message || 'Unknown error';
                this.showToast('Error', errorMessage, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    @wire(getActiveConfigurations)
    wiredConfigurations({ error, data }) {
        if (data) {
            this.configurationOptions = data.map(config => ({
                label: config.Label__c,
                value: config.Id
            }));
        } else if (error) {
            const errorMessage = error.body?.message || error.message || 'Unknown error';
            this.showToast('Error', 'Failed to load configurations: ' + errorMessage, 'error');
        }
    }

    handleConfigurationChange(event) {
        this.selectedConfigId = event.detail.value;
        this.searchResults = [];
        this.filterValues = {};
        this.searchPerformed = false;
        this.currentPage = 1;

        if (this.selectedConfigId) {
            this.loadConfigurationDetails();
        }
    }

    handleToggleSearch() {
        this.isExpanded = !this.isExpanded;
    }

    loadConfigurationDetails() {
        this.isLoading = true;
        getConfigurationDetails({ configId: this.selectedConfigId })
            .then(result => {
                this.filterFields = result.filterFields.map(field => {
                    const fieldType = (field.Field_Type__c || 'TEXT').toUpperCase();
                    const isPicklist = fieldType === 'PICKLIST' || fieldType === 'MULTIPICKLIST';
                    const isLookup = fieldType === 'REFERENCE' || fieldType === 'LOOKUP';
                    const isSelectionType = isPicklist || isLookup || fieldType === 'DATE' || fieldType === 'DATETIME';
                    let label = field.Field_Label__c;
                    if (field.Is_Multi_Search__c && !isSelectionType) {
                        const sep = !field.Multi_Search_Separator__c || field.Multi_Search_Separator__c.trim() === '' ? lbl_SeparatorSpace : `'${field.Multi_Search_Separator__c}'`;
                        label += ' ' + lbl_SeparatorLabel.replace('{0}', sep);
                    }
                    return {
                        ...field,
                        key: field.Id,
                        displayLabel: label,
                        isDate: fieldType === 'DATE',
                        isDateTime: fieldType === 'DATETIME',
                        isNumber: fieldType === 'NUMBER' || fieldType === 'CURRENCY' || fieldType === 'PERCENT' || fieldType === 'DOUBLE',
                        isEmail: fieldType === 'EMAIL',
                        isPhone: fieldType === 'PHONE',
                        isBoolean: fieldType === 'BOOLEAN' || fieldType === 'CHECKBOX',
                        isPicklist: isPicklist,
                        isLookup: isLookup,
                        isText: !['DATE', 'DATETIME', 'NUMBER', 'CURRENCY', 'PERCENT', 'DOUBLE', 'EMAIL', 'PHONE', 'BOOLEAN', 'CHECKBOX', 'PICKLIST', 'MULTIPICKLIST', 'REFERENCE', 'LOOKUP'].includes(fieldType),
                        dateRangeDisplay: this.getDateRangeDisplay(field.Field_API_Name__c, fieldType),
                        isDateRangeOpen: false,
                        rangeStartDate: '',
                        rangeStartTime: '',
                        rangeEndDate: '',
                        rangeEndTime: '',
                        picklistOptions: [],
                        selectedPicklistValues: [],
                        picklistDisplay: lbl_SelectPlaceholder,
                        isPicklistOpen: false,
                        lookupSearchTerm: '',
                        lookupResults: [],
                        lookupSelectedItems: [],
                        lookupDisplay: lbl_SelectPlaceholder,
                        isLookupOpen: false
                    };
                });
                this.gridColumns = result.configuration.Grid_Columns__c || 3;
                this.objectApiName = result.configuration.Object_API_Name__c;
                this.loadPicklistOptions();
            })
            .catch(error => {
                const errorMessage = error.body?.message || error.message || 'Unknown error';
                this.showToast('Error', 'Failed to load configuration: ' + errorMessage, 'error');
                this.filterFields = [];
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleFilterChange(event) {
        const fieldName = event.target.dataset.field;
        const fieldType = event.target.type;

        if (fieldType === 'checkbox' || fieldType === 'checkbox-button') {
            this.filterValues[fieldName] = event.target.checked;
            this.refreshDependentPicklists();
        } else {
            this.filterValues[fieldName] = event.target.value;
        }
    }

    // Picklist multiselect methods
    loadPicklistOptions() {
        const picklistFields = this.filterFields.filter(f => f.isPicklist);
        const promises = picklistFields.map(field =>
            getPicklistFieldInfo({ objectApiName: this.objectApiName, fieldApiName: field.Field_API_Name__c })
                .then(info => ({ fieldName: field.Field_API_Name__c, info }))
        );

        Promise.all(promises).then(results => {
            const infoMap = {};
            results.forEach(r => { infoMap[r.fieldName] = r.info; });
            this.filterFields = this.filterFields.map(field => {
                if (field.isPicklist && infoMap[field.Field_API_Name__c]) {
                    const info = infoMap[field.Field_API_Name__c];
                    const allOptions = (info.options || []).map(opt => ({
                        label: opt.label,
                        value: opt.value,
                        validFor: opt.validFor || [],
                        selected: false
                    }));
                    return {
                        ...field,
                        controllingFieldApiName: info.controllingFieldApiName || null,
                        allPicklistOptions: allOptions,
                        picklistOptions: allOptions.map(opt => ({ ...opt }))
                    };
                }
                return field;
            });
            this.refreshDependentPicklists();
        });
    }

    // Resolves the currently selected controlling values for a controlling field.
    getSelectedControllingValues(controllingFieldApiName) {
        const controllingField = this.filterFields.find(f => f.Field_API_Name__c === controllingFieldApiName);
        if (!controllingField) {
            return [];
        }
        if (controllingField.isPicklist) {
            return controllingField.selectedPicklistValues || [];
        }
        if (controllingField.isBoolean) {
            const value = this.filterValues[controllingFieldApiName];
            return (value === true || value === 'true') ? ['true'] : ['false'];
        }
        return [];
    }

    // Restricts each dependent picklist's visible options to those valid for the
    // controlling field's current selection. Selections that become invalid are dropped.
    refreshDependentPicklists() {
        this.filterFields = this.filterFields.map(field => {
            if (!field.isPicklist || !field.controllingFieldApiName || !field.allPicklistOptions) {
                return field;
            }
            const controllingValues = this.getSelectedControllingValues(field.controllingFieldApiName);
            const visibleOptions = controllingValues.length === 0
                ? field.allPicklistOptions
                : field.allPicklistOptions.filter(opt => opt.validFor.some(v => controllingValues.includes(v)));

            const visibleValueSet = new Set(visibleOptions.map(opt => opt.value));
            const newSelected = (field.selectedPicklistValues || []).filter(v => visibleValueSet.has(v));
            const mappedOptions = visibleOptions.map(opt => ({ ...opt, selected: newSelected.includes(opt.value) }));

            if (newSelected.length > 0) {
                this.filterValues[field.Field_API_Name__c] = newSelected.join('|PICKLIST|');
            } else {
                delete this.filterValues[field.Field_API_Name__c];
            }

            return {
                ...field,
                picklistOptions: mappedOptions,
                selectedPicklistValues: newSelected,
                picklistDisplay: newSelected.length > 0
                    ? mappedOptions.filter(opt => opt.selected).map(opt => opt.label).join(', ')
                    : lbl_SelectPlaceholder
            };
        });
    }

    handlePicklistTriggerClick(event) {
        const fieldName = event.currentTarget.dataset.field;
        this.filterFields = this.filterFields.map(field => {
            if (field.Field_API_Name__c === fieldName) {
                return { ...field, isPicklistOpen: !field.isPicklistOpen };
            }
            return field;
        });
    }

    handlePicklistOptionToggle(event) {
        const fieldName = event.currentTarget.dataset.field;
        const optValue = event.currentTarget.dataset.value;

        this.filterFields = this.filterFields.map(field => {
            if (field.Field_API_Name__c === fieldName) {
                const updatedOptions = field.picklistOptions.map(opt => {
                    if (opt.value === optValue) {
                        return { ...opt, selected: !opt.selected };
                    }
                    return opt;
                });
                return { ...field, picklistOptions: updatedOptions };
            }
            return field;
        });
    }

    handlePicklistApply(event) {
        const fieldName = event.currentTarget.dataset.field;

        this.filterFields = this.filterFields.map(field => {
            if (field.Field_API_Name__c === fieldName) {
                const selectedValues = field.picklistOptions.filter(o => o.selected).map(o => o.value);
                const display = selectedValues.length > 0
                    ? field.picklistOptions.filter(o => o.selected).map(o => o.label).join(', ')
                    : lbl_SelectPlaceholder;

                if (selectedValues.length > 0) {
                    this.filterValues[fieldName] = selectedValues.join('|PICKLIST|');
                } else {
                    delete this.filterValues[fieldName];
                }

                return {
                    ...field,
                    selectedPicklistValues: selectedValues,
                    picklistDisplay: display,
                    isPicklistOpen: false
                };
            }
            return field;
        });
        this.refreshDependentPicklists();
    }

    handlePicklistClear(event) {
        const fieldName = event.currentTarget.dataset.field;
        delete this.filterValues[fieldName];
        this.filterFields = this.filterFields.map(field => {
            if (field.Field_API_Name__c === fieldName) {
                return {
                    ...field,
                    picklistOptions: field.picklistOptions.map(opt => ({ ...opt, selected: false })),
                    selectedPicklistValues: [],
                    picklistDisplay: lbl_SelectPlaceholder,
                    isPicklistOpen: false
                };
            }
            return field;
        });
        this.refreshDependentPicklists();
    }

    // Lookup multiselect methods
    handleLookupTriggerClick(event) {
        const fieldName = event.currentTarget.dataset.field;
        this.filterFields = this.filterFields.map(field => {
            if (field.Field_API_Name__c === fieldName) {
                const opening = !field.isLookupOpen;
                if (opening && field.lookupResults.length === 0) {
                    this._fetchLookupResults(fieldName, '');
                }
                return { ...field, isLookupOpen: opening };
            }
            return field;
        });
    }

    handleLookupSearchInput(event) {
        const fieldName = event.currentTarget.dataset.field;
        const term = event.target.value;
        this.filterFields = this.filterFields.map(field => {
            if (field.Field_API_Name__c === fieldName) {
                return { ...field, lookupSearchTerm: term };
            }
            return field;
        });
        if (this._lookupDebounceTimer) {
            clearTimeout(this._lookupDebounceTimer);
        }
        this._lookupDebounceTimer = setTimeout(() => {
            this._fetchLookupResults(fieldName, term);
        }, 300);
    }

    _fetchLookupResults(fieldName, term) {
        searchLookupRecords({
            objectApiName: this.objectApiName,
            fieldApiName: fieldName,
            searchTerm: term
        })
            .then(results => {
                this.filterFields = this.filterFields.map(field => {
                    if (field.Field_API_Name__c === fieldName) {
                        const selectedIds = new Set(field.lookupSelectedItems.map(i => i.value));
                        return {
                            ...field,
                            lookupResults: results.map(r => ({ ...r, selected: selectedIds.has(r.value) }))
                        };
                    }
                    return field;
                });
            })
            .catch(() => {});
    }

    handleLookupOptionToggle(event) {
        const fieldName = event.currentTarget.dataset.field;
        const optValue = event.currentTarget.dataset.value;
        const optLabel = event.currentTarget.dataset.label;

        this.filterFields = this.filterFields.map(field => {
            if (field.Field_API_Name__c === fieldName) {
                const alreadySelected = field.lookupSelectedItems.some(i => i.value === optValue);
                let updatedSelected;
                if (alreadySelected) {
                    updatedSelected = field.lookupSelectedItems.filter(i => i.value !== optValue);
                } else {
                    updatedSelected = [...field.lookupSelectedItems, { value: optValue, label: optLabel }];
                }
                const selectedIds = new Set(updatedSelected.map(i => i.value));
                return {
                    ...field,
                    lookupSelectedItems: updatedSelected,
                    lookupResults: field.lookupResults.map(r => ({ ...r, selected: selectedIds.has(r.value) }))
                };
            }
            return field;
        });
    }

    handleLookupTagRemove(event) {
        const fieldName = event.currentTarget.dataset.field;
        const tagValue = event.currentTarget.dataset.value;
        this.filterFields = this.filterFields.map(field => {
            if (field.Field_API_Name__c === fieldName) {
                const updatedSelected = field.lookupSelectedItems.filter(i => i.value !== tagValue);
                const selectedIds = new Set(updatedSelected.map(i => i.value));
                return {
                    ...field,
                    lookupSelectedItems: updatedSelected,
                    lookupResults: field.lookupResults.map(r => ({ ...r, selected: selectedIds.has(r.value) }))
                };
            }
            return field;
        });
    }

    handleLookupApply(event) {
        const fieldName = event.currentTarget.dataset.field;
        this.filterFields = this.filterFields.map(field => {
            if (field.Field_API_Name__c === fieldName) {
                const selected = field.lookupSelectedItems;
                if (selected.length > 0) {
                    this.filterValues[fieldName] = selected.map(i => i.value).join('|LOOKUP|');
                } else {
                    delete this.filterValues[fieldName];
                }
                const displayText = selected.length > 0
                    ? selected.map(i => i.label).join('; ')
                    : lbl_SelectPlaceholder;
                return { ...field, lookupDisplay: displayText, isLookupOpen: false };
            }
            return field;
        });
    }

    handleLookupClear(event) {
        const fieldName = event.currentTarget.dataset.field;
        delete this.filterValues[fieldName];
        this.filterFields = this.filterFields.map(field => {
            if (field.Field_API_Name__c === fieldName) {
                return {
                    ...field,
                    lookupSelectedItems: [],
                    lookupResults: field.lookupResults.map(r => ({ ...r, selected: false })),
                    lookupDisplay: lbl_SelectPlaceholder,
                    isLookupOpen: false
                };
            }
            return field;
        });
    }

    // Date Range inline methods
    handleDateRangeClick(event) {
        const fieldName = event.currentTarget.dataset.field;
        this.filterFields = this.filterFields.map(field => {
            if (field.Field_API_Name__c === fieldName) {
                return { ...field, isDateRangeOpen: !field.isDateRangeOpen };
            }
            return field;
        });
    }

    handleDateRangePartChange(event) {
        const fieldName = event.target.dataset.field;
        const part = event.target.dataset.rangePart;
        const value = event.detail.value;

        if (!this.dateRangeValues[fieldName]) {
            this.dateRangeValues[fieldName] = {};
        }
        this.dateRangeValues[fieldName][part] = value;

        this.filterFields = this.filterFields.map(field => {
            if (field.Field_API_Name__c === fieldName) {
                const stored = this.dateRangeValues[fieldName] || {};
                return {
                    ...field,
                    rangeStartDate: stored.startDate || '',
                    rangeStartTime: stored.startTime || '',
                    rangeEndDate: stored.endDate || '',
                    rangeEndTime: stored.endTime || ''
                };
            }
            return field;
        });
    }

    handleDateRangeInlineApply(event) {
        const fieldName = event.currentTarget.dataset.field;
        const type = event.currentTarget.dataset.type;
        const stored = this.dateRangeValues[fieldName] || {};

        if (type === 'datetime') {
            // Build timezone offset string (e.g. "+02:00" or "-05:00") so Salesforce
            // compares against the value the user sees in their local timezone.
            const offsetMins = new Date().getTimezoneOffset();
            const sign = offsetMins <= 0 ? '+' : '-';
            const absOffset = Math.abs(offsetMins);
            const tzOffset = `${sign}${String(Math.floor(absOffset / 60)).padStart(2, '0')}:${String(absOffset % 60).padStart(2, '0')}`;

            const startDt = stored.startDate && stored.startTime
                ? `${stored.startDate}T${stored.startTime}${tzOffset}`
                : stored.startDate ? `${stored.startDate}T00:00:00${tzOffset}` : '';
            const endDt = stored.endDate && stored.endTime
                ? `${stored.endDate}T${stored.endTime}${tzOffset}`
                : stored.endDate ? `${stored.endDate}T23:59:59${tzOffset}` : '';
            this.filterValues[fieldName] = `${startDt}|${endDt}`;
        } else {
            this.filterValues[fieldName] = `${stored.startDate || ''}|${stored.endDate || ''}`;
        }

        this.refreshDateRangeDisplays();
        this.filterFields = this.filterFields.map(field => {
            if (field.Field_API_Name__c === fieldName) {
                return { ...field, isDateRangeOpen: false };
            }
            return field;
        });
    }

    handleDateRangeInlineClear(event) {
        const fieldName = event.currentTarget.dataset.field;
        delete this.dateRangeValues[fieldName];
        delete this.filterValues[fieldName];

        this.filterFields = this.filterFields.map(field => {
            if (field.Field_API_Name__c === fieldName) {
                return {
                    ...field,
                    isDateRangeOpen: false,
                    rangeStartDate: '',
                    rangeStartTime: '',
                    rangeEndDate: '',
                    rangeEndTime: '',
                    dateRangeDisplay: lbl_SelectRange
                };
            }
            return field;
        });
    }

    getDateRangeDisplay(fieldName, fieldType) {
        const stored = this.dateRangeValues[fieldName];
        if (!stored || (!stored.startDate && !stored.endDate)) {
            return lbl_SelectRange;
        }
        const formatDate = (d) => {
            if (!d) return '...';
            const parts = d.split('-');
            return `${parts[2]}/${parts[1]}/${parts[0]}`;
        };
        if (fieldType === 'DATETIME') {
            const startStr = stored.startDate ? `${formatDate(stored.startDate)}${stored.startTime ? ' ' + stored.startTime : ''}` : '...';
            const endStr = stored.endDate ? `${formatDate(stored.endDate)}${stored.endTime ? ' ' + stored.endTime : ''}` : '...';
            return `${startStr} - ${endStr}`;
        }
        return `${formatDate(stored.startDate)} - ${formatDate(stored.endDate)}`;
    }

    refreshDateRangeDisplays() {
        this.filterFields = this.filterFields.map(field => ({
            ...field,
            dateRangeDisplay: this.getDateRangeDisplay(field.Field_API_Name__c, (field.Field_Type__c || 'TEXT').toUpperCase())
        }));
    }

    handleSearch() {
        if (!this.selectedConfigId) {
            this.showToast('Warning', lbl_SelectConfigFirst, 'warning');
            return;
        }

        this.isLoading = true;
        this.searchPerformed = true;
        this.currentPage = 1;

        searchRecords({
            configId: this.selectedConfigId,
            filterValues: this.filterValues
        })
            .then(result => {
                this.searchResults = result.records.map(record => {
                    return {
                        ...record,
                        recordUrl: `/${record.Id}`
                    };
                });

                this.displayColumns = result.columns.map(col => {
                    if (col.fieldName === 'Name' || col.fieldName.endsWith('Number')) {
                        return {
                            ...col,
                            type: 'url',
                            typeAttributes: {
                                label: { fieldName: col.fieldName },
                                target: '_blank'
                            },
                            fieldName: 'recordUrl'
                        };
                    }
                    return col;
                });

                this.showToast('Success', lbl_RecordsFoundToast.replace('{0}', result.totalCount), 'success');
            })
            .catch(error => {
                const errorMessage = error.body?.message || error.message || 'Unknown error';
                this.showToast('Error', 'Search failed: ' + errorMessage, 'error');
                this.searchResults = [];
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleClear() {
        this.filterValues = {};
        this.dateRangeValues = {};
        this.searchResults = [];
        this.searchPerformed = false;
        this.currentPage = 1;

        const inputs = this.template.querySelectorAll('lightning-input');
        inputs.forEach(input => {
            if (input.type === 'checkbox') {
                input.checked = false;
            } else {
                input.value = '';
            }
        });

        this.filterFields = this.filterFields.map(field => ({
            ...field,
            isDateRangeOpen: false,
            rangeStartDate: '',
            rangeStartTime: '',
            rangeEndDate: '',
            rangeEndTime: '',
            dateRangeDisplay: (field.isDate || field.isDateTime) ? lbl_SelectRange : field.dateRangeDisplay,
            isPicklistOpen: false,
            selectedPicklistValues: [],
            picklistDisplay: field.isPicklist ? lbl_SelectPlaceholder : field.picklistDisplay,
            picklistOptions: field.isPicklist
                ? (field.allPicklistOptions || field.picklistOptions).map(opt => ({ ...opt, selected: false }))
                : field.picklistOptions,
            isLookupOpen: false,
            lookupSelectedItems: field.isLookup ? [] : field.lookupSelectedItems,
            lookupResults: field.isLookup ? field.lookupResults.map(r => ({ ...r, selected: false })) : field.lookupResults,
            lookupDisplay: field.isLookup ? lbl_SelectPlaceholder : field.lookupDisplay,
            lookupSearchTerm: field.isLookup ? '' : field.lookupSearchTerm
        }));

        this.refreshDependentPicklists();
        this.showToast('Info', lbl_FiltersCleared, 'info');
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedRowIds = selectedRows.map(row => row.Id);
    }

    handleSendToDispatcher() {
        if (this.selectedRowIds.length === 0) {
            this.showToast('Warning', lbl_SelectAtLeastOneRecord, 'warning');
            return;
        }

        this.isLoading = true;
        markForDispatcher({ objectApiName: this.objectApiName, recordIds: this.selectedRowIds })
            .then(() => {
                this.showToast('Success', lbl_SentToDispatcher.replace('{0}', this.selectedRowIds.length), 'success');
            })
            .catch(error => {
                const errorMessage = error.body?.message || error.message || 'Unknown error';
                this.showToast('Error', lbl_ErrorSendingDispatcher.replace('{0}', errorMessage), 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleSearchAndSend() {
        if (!this.selectedConfigId) {
            this.showToast('Warning', lbl_SelectConfigFirst, 'warning');
            return;
        }

        this.isLoading = true;
        this.searchPerformed = true;
        this.currentPage = 1;

        searchRecords({
            configId: this.selectedConfigId,
            filterValues: this.filterValues
        })
            .then(result => {
                this.searchResults = result.records.map(record => ({
                    ...record,
                    recordUrl: `/${record.Id}`
                }));

                this.displayColumns = result.columns.map(col => {
                    if (col.fieldName === 'Name' || col.fieldName.endsWith('Number')) {
                        return {
                            ...col,
                            type: 'url',
                            typeAttributes: {
                                label: { fieldName: col.fieldName },
                                target: '_blank'
                            },
                            fieldName: 'recordUrl'
                        };
                    }
                    return col;
                });

                if (this.searchResults.length === 0) {
                    this.showToast('Info', lbl_NoRecordsToSend, 'info');
                    return;
                }

                this.selectedRowIds = this.searchResults.map(r => r.Id);

                return markForDispatcher({ objectApiName: this.objectApiName, recordIds: this.selectedRowIds });
            })
            .then(result => {
                if (result !== undefined) {
                    this.showToast('Success', lbl_FoundAndSent.replace('{0}', this.selectedRowIds.length), 'success');
                    this.dispatchEvent(new CustomEvent('searchandsendcomplete'));
                }
            })
            .catch(error => {
                const errorMessage = error.body?.message || error.message || 'Unknown error';
                this.showToast('Error', lbl_ErrorSearchAndSend.replace('{0}', errorMessage), 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleClearDispatcherFilter() {
        this.isLoading = true;
        clearDispatcherFilter({ objectApiName: this.objectApiName })
            .then(result => {
                this.showToast('Success', lbl_ClearedFromDispatcher.replace('{0}', result), 'success');
            })
            .catch(error => {
                const errorMessage = error.body?.message || error.message || 'Unknown error';
                this.showToast('Error', lbl_ErrorClearing.replace('{0}', errorMessage), 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    // Computed properties
    get hasResults() {
        return this.searchResults && this.searchResults.length > 0;
    }

    get showToggleButton() {
        return !this.embeddedMode;
    }

    get searchPanelClass() {
        return this.embeddedMode ? '' : 'search-panel slds-box slds-theme_shade slds-m-bottom_medium';
    }

    get showConfigSelector() {
        return !this.configurationName && !this.configurationId;
    }

    get toggleButtonLabel() {
        return this.isExpanded ? lbl_HideAdvancedSearch : lbl_ShowAdvancedSearch;
    }

    get toggleButtonIcon() {
        return this.isExpanded ? 'utility:chevronup' : 'utility:chevrondown';
    }

    get hasFilterFields() {
        return this.filterFields && this.filterFields.length > 0;
    }

    get sendToDispatcherLabel() {
        return `${lbl_SendToDispatcher} (${this.selectedRowIds.length})`;
    }

    get resultsMessage() {
        const count = this.searchResults.length;
        return lbl_RecordsFound.replace('{0}', count);
    }

    get paginationMessage() {
        return lbl_PageOf.replace('{0}', this.currentPage).replace('{1}', this.totalPages);
    }

    get filterFieldsInRows() {
        if (!this.filterFields || this.filterFields.length === 0) {
            return [];
        }

        const cols = this.gridColumns || 3;
        const rows = [];
        let currentRow = [];

        this.filterFields.forEach((field, index) => {
            currentRow.push(field);

            if ((index + 1) % cols === 0 || index === this.filterFields.length - 1) {
                rows.push({
                    key: `row-${rows.length}`,
                    fields: [...currentRow]
                });
                currentRow = [];
            }
        });

        return rows;
    }

    get filterGridStyle() {
        const cols = this.gridColumns || 3;
        return `grid-template-columns: repeat(${cols}, 1fr);`;
    }

    get pageSizeOptions() {
        return [
            { label: '5', value: '5' },
            { label: '10', value: '10' },
            { label: '15', value: '15' },
            { label: '20', value: '20' },
            { label: '50', value: '50' },
            { label: 'All', value: 'all' }
        ];
    }

    handlePageSizeChange(event) {
        this.pageSizeValue = event.detail.value;
        if (this.pageSizeValue === 'all') {
            this.pageSize = this.searchResults.length;
        } else {
            this.pageSize = parseInt(this.pageSizeValue, 10);
        }
        this.currentPage = 1;
    }

    get totalPages() {
        if (this.pageSizeValue === 'all') {
            return 1;
        }
        return Math.ceil(this.searchResults.length / this.pageSize);
    }

    get paginatedResults() {
        if (this.pageSizeValue === 'all') {
            return this.searchResults;
        }
        const start = (this.currentPage - 1) * this.pageSize;
        return this.searchResults.slice(start, start + this.pageSize);
    }

    get showPagination() {
        if (this.pageSizeValue === 'all') {
            return false;
        }
        return this.searchResults.length > this.pageSize;
    }

    get isFirstPage() {
        return this.currentPage <= 1;
    }

    get isLastPage() {
        return this.currentPage >= this.totalPages;
    }

    handlePreviousPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
        }
    }

    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
        }
    }
}
