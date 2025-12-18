import { LightningElement, api, track, wire } from 'lwc';
import getValuesByItem from '@salesforce/apex/KZ_ScoringConfigService.getValuesByItem';
import saveValue from '@salesforce/apex/KZ_ScoringConfigService.saveValue';
import deleteValue from '@salesforce/apex/KZ_ScoringConfigService.deleteValue';
import getFieldAndPicklistOptions from '@salesforce/apex/KZ_ScoringConfigService.getFieldAndPicklistOptions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class KzFieldValueForm extends LightningElement {
    @api fieldId; // kzItemScoring__c Id (parent)
    @track values = [];
    wiredResult;
    @track isLoading = false;
    
    @track showForm = false;
    @track editingId = null; 

    @track parentFieldType = 'TEXT';
    @track parentFieldPMP = 0;
    @track picklistOptions = [];
    @track isLoadingFieldDetails = true;

    @track showDeleteConfirm = false;
    @track deleteCandidateId = null;
    @track deleteCandidateLabel = '';

    @track valueText = '';
    @track picklistApi = '';
    @track score = 0;
    @track exactMatch = false;
    @track active = true;
    
    checkboxOptions = [
        { label: 'True', value: 'TRUE' },
        { label: 'False', value: 'FALSE' }
    ];

    columns = [
        { label: 'Valor', fieldName: 'kzValueText__c' },
        { label: 'Picklist API', fieldName: 'kzPicklistOptionApi__c' },
        { label: 'Puntaje', fieldName: 'kzAwardedScore__c', type: 'number' },
        { label: 'Coinc. Exacta', fieldName: 'kzExactMatch__c', type: 'boolean' },
        { label: 'Activo', fieldName: 'kzActive__c', type: 'boolean' },
        {
            type: 'action',
            typeAttributes: {
                rowActions: { fieldName: 'rowActions' }
            }
        }
    ];

    @wire(getValuesByItem, { itemId: '$fieldId' })
    wiredValues(result) {
        this.wiredResult = result;
        this.isLoading = true;
        if (result.data) {
            // convert to plain objects with rowActions
            const rows = result.data.map(r => {
                const actions = [
                    { label: 'Editar', name: 'edit' },
                    { label: 'Eliminar', name: 'delete' }
                ];
                return {
                    Id: r.Id,
                    kzValueText__c: r.kzValueText__c,
                    kzPicklistOptionApi__c: r.kzPicklistOptionApi__c,
                    kzAwardedScore__c: r.kzAwardedScore__c,
                    kzExactMatch__c: r.kzExactMatch__c,
                    kzActive__c: r.kzActive__c,
                    rowActions: actions
                };
            });
            this.values = rows;
            this.isLoading = false;
        } else if (result.error) {
            this.isLoading = false;
            const msg = result.error?.body?.message || JSON.stringify(result.error);
            this.dispatchEvent(new ShowToastEvent({ title: 'Error al cargar valores', message: msg, variant: 'error' }));
        }
    }
    
    @wire(getFieldAndPicklistOptions, { itemId: '$fieldId' })
    loadParentFieldDetails({ error, data }) {
        this.isLoadingFieldDetails = true;
        if (data) {
            this.parentFieldType = data.fieldType || 'TEXT';
            this.parentFieldPMP = data.parentFieldPMP || 0;
            this.picklistOptions = data.picklistOptions || [];
            this.isLoadingFieldDetails = false;
        } else if (error) {
            this.isLoadingFieldDetails = false;
            console.error('Error al cargar detalles del campo padre:', error);
            const msg = error.body?.message || JSON.stringify(error);
            this.dispatchEvent(new ShowToastEvent({ title: 'Error al cargar detalles del campo', message: msg, variant: 'error' }));
        }
    }

    get noValues() {
        return !this.isLoading && (!this.values || this.values.length === 0);
    }
    
    get formTitle() { 
        return this.editingId ? 'Editar Valor' : 'Nuevo Valor'; 
    }

    get parentFieldTypeLabel() {
        const typeMap = {
            'PICKLIST': 'Picklist',
            'TEXT': 'Texto',
            'CHECKBOX': 'Checkbox',
            'NUMBER': 'Número',
            'DATE': 'Fecha',
            'EMAIL': 'Email',
            'PHONE': 'Teléfono'
        };
        return typeMap[this.parentFieldType] || this.parentFieldType;
    }

    get isText() { return false; } // no UI creation for generic text values
    get isCheckbox() { return this.parentFieldType === 'CHECKBOX'; }
    get isPicklist() { return this.parentFieldType === 'PICKLIST'; }
    get isNumber() { return this.parentFieldType === 'NUMBER'; }
    
    get showNewValueButton() {
        if (this.parentFieldType === 'CHECKBOX') {
            return this.availableCheckboxOptions.length > 0;
        }
        if (this.parentFieldType === 'PICKLIST') {
            return this.availablePicklistOptions.length > 0;
        }
        if (this.parentFieldType === 'NUMBER') {
            return true;
        }
        return false;
    }

    get availableCheckboxOptions() {
        if (!this.values || !this.isCheckbox) return this.checkboxOptions;
        const configuredValues = new Set(this.values.map(v => (v.kzValueText__c || '').toUpperCase()));
        return this.checkboxOptions.filter(opt => !configuredValues.has(opt.value.toUpperCase()));
    }
    
    get availablePicklistOptions() {
        if (!this.values || !this.isPicklist || !this.picklistOptions) return this.picklistOptions;
        const configuredValues = new Set(this.values.map(v => v.kzPicklistOptionApi__c));
        return this.picklistOptions.filter(opt => !configuredValues.has(opt.value));
    }

    handleNew() {
        if (!this.fieldId) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: 'FieldId no está definido', variant: 'error' }));
            return;
        }
        const forbidden = ['TEXT','EMAIL','PHONE','DATE'];
        if (forbidden.includes(this.parentFieldType)) {
            this.dispatchEvent(new ShowToastEvent({ title: 'No permitido', message: 'No se pueden definir valores para este tipo de campo. La puntuación se aplica con el PMP si el campo no está vacío.', variant: 'warning' }));
            return;
        }

        this.editingId = null;
        this.valueText = '';
        this.picklistApi = '';
        this.score = 0;
        this.exactMatch = false;
        this.active = true;
        
        if (this.isCheckbox && this.availableCheckboxOptions.length) {
            this.valueText = this.availableCheckboxOptions[0].value;
        } else if (this.isPicklist && this.availablePicklistOptions.length) {
             this.picklistApi = this.availablePicklistOptions[0].value;
        }
        
        this.showForm = true;
    }

    handleRowAction(event) {
        const action = event.detail.action.name;
        const row = event.detail.row;
        if (action === 'edit') this.loadForEdit(row);
        else if (action === 'delete') this.requestDelete(row);
    }

    loadForEdit(row) {
        this.editingId = row.Id;
        this.valueText = row.kzValueText__c || '';
        this.picklistApi = row.kzPicklistOptionApi__c || '';
        this.score = row.kzAwardedScore__c || 0;
        this.exactMatch = row.kzExactMatch__c === true;
        this.active = row.kzActive__c === true;
        this.showForm = true;
    }

    requestDelete(row) {
        this.deleteCandidateId = row.Id;
        this.deleteCandidateLabel = row.kzValueText__c || row.kzPicklistOptionApi__c || 'Valor';
        this.showDeleteConfirm = true;
    }

    async confirmDelete() {
        if (!this.deleteCandidateId) return;
        try {
            await deleteValue({ valueId: this.deleteCandidateId });
            this.dispatchEvent(new ShowToastEvent({ title: 'Eliminado', message: 'Valor eliminado', variant: 'success' }));
            this.showDeleteConfirm = false;
            this.deleteCandidateId = null;
            this.deleteCandidateLabel = '';
            await refreshApex(this.wiredResult);
        } catch (err) {
            console.error('deleteValue error', err);
            const msg = err?.body?.message || err?.message || JSON.stringify(err);
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: msg, variant: 'error' }));
        }
    }

    cancelDelete() {
        this.showDeleteConfirm = false;
        this.deleteCandidateId = null;
        this.deleteCandidateLabel = '';
    }

    handleValueText(e) { this.valueText = e.target.value; }
    handlePicklistApi(e) { this.picklistApi = e.target.value; }
    handleScore(e) { this.score = e.target.value === undefined ? 0 : Number(e.target.value); }
    handleExactMatch(e) { this.exactMatch = e.target.checked; }
    handleActive(e) { this.active = e.target.checked; }

    async save() {
        // Validación PMP
        if (this.score > this.parentFieldPMP) {
             this.dispatchEvent(new ShowToastEvent({ 
                title: 'Validación de Puntaje', 
                message: `El puntaje otorgado (${this.score}) no puede superar el PMP del campo padre (${this.parentFieldPMP}).`, 
                variant: 'error' 
            }));
            return;
        }

        if (!this.fieldId) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: 'Falta fieldId', variant: 'error' }));
            return;
        }

        const forbidden = ['TEXT','EMAIL','PHONE','DATE'];
        if (forbidden.includes(this.parentFieldType)) {
            this.dispatchEvent(new ShowToastEvent({ title: 'No permitido', message: 'Este tipo de campo no admite valores. La puntuación se calcula usando el PMP si el campo no está vacío.', variant: 'error' }));
            return;
        }

        let value = this.valueText;
        let apiValue = this.picklistApi;

        if (this.isPicklist) {
            if (!apiValue) {
                this.dispatchEvent(new ShowToastEvent({ title: 'Faltan datos', message: 'Seleccione un valor Picklist', variant: 'error' }));
                return;
            }
            if (!value) {
                const selectedOpt = this.picklistOptions.find(opt => opt.value === apiValue) || this.availablePicklistOptions.find(opt => opt.value === apiValue);
                value = selectedOpt ? selectedOpt.label : apiValue;
            }
        } else if (this.isCheckbox) {
            if (!value) {
                this.dispatchEvent(new ShowToastEvent({ title: 'Faltan datos', message: 'Seleccione True o False', variant: 'error' }));
                return;
            }
        } else if (this.isNumber) {
            if (value === '' || value === null || isNaN(Number(value))) {
                this.dispatchEvent(new ShowToastEvent({ title: 'Faltan datos', message: 'Ingrese un valor numérico', variant: 'error' }));
                return;
            }
        }

        if (this.isCheckbox) {
            this.exactMatch = true;
        }

        const rec = {
            Id: this.editingId,
            kzItemScoring__c: this.fieldId,
            kzValueText__c: value,
            kzPicklistOptionApi__c: this.isPicklist ? apiValue : null,
            kzAwardedScore__c: this.score,
            kzExactMatch__c: this.exactMatch,
            kzActive__c: this.active
        };

        try {
            await saveValue({ val: rec });
            this.dispatchEvent(new ShowToastEvent({ title: 'Guardado', message: 'Valor guardado', variant: 'success' }));
            this.showForm = false;
            this.editingId = null;
            await refreshApex(this.wiredResult);
            this.dispatchEvent(new CustomEvent('saved', { bubbles: true, composed: true }));
        } catch (err) {
            console.error('saveValue error', err);
            const msg = err?.body?.message || err?.message || JSON.stringify(err);
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: msg, variant: 'error' }));
        }
    }

    closeForm() {
        this.showForm = false;
        this.editingId = null;
    }
}