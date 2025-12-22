import { LightningElement, api, track, wire } from 'lwc';
import getItemById from '@salesforce/apex/KZ_ItemService.getItemById';
import saveItem from '@salesforce/apex/KZ_ScoringConfigService.saveItem';
import getNextItemOrder from '@salesforce/apex/KZ_ScoringConfigService.getNextItemOrder';
import getAllLeadFieldsForScoring from '@salesforce/apex/KZ_ScoringConfigService.getAllLeadFieldsForScoring';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class KzDynamicFieldForm extends LightningElement {
    @api scoringId;
    @api fieldId;

    @track label = '';
    @track apiField = '';
    @track dataType = ''; 
    @track pmp = 0;
    @track order = 0;
    @track active = true;
    @track description = '';
    @track question = '';
    
    @track isEditMode = false;
    @track isLoadingFields = false;
    @track leadFieldOptions = [];
    
    typeOptions = [
        { label: 'Picklist', value: 'PICKLIST' },
        { label: 'Texto',    value: 'TEXT' },
        { label: 'Checkbox', value: 'CHECKBOX' },
        { label: 'Número',   value: 'NUMBER' },
        { label: 'Fecha',    value: 'DATE' },
        { label: 'Email',    value: 'EMAIL' },
        { label: 'Teléfono', value: 'PHONE' }
    ];

    connectedCallback() {
        this.isEditMode = !!this.fieldId;
        if (this.fieldId) {
            this.loadItem();
        } else {
            this.loadNextOrder();
        }
    }
    
    @wire(getAllLeadFieldsForScoring)
    wiredLeadFields({ error, data }) {
        this.isLoadingFields = true;
        if (data) {
            this.leadFieldOptions = data;
            this.isLoadingFields = false;
        } else if (error) {
            console.error('Error al cargar campos del Lead:', error);
            this.dispatchEvent(new ShowToastEvent({ title: 'Error de Carga', message: 'No se pudo cargar la lista de campos del Lead.', variant: 'error' }));
            this.isLoadingFields = false;
        }
    }

    get showApiField() { return true; }
    get showDataType() { return false; }
    
    get showDataTypeField() {
        return !!this.apiField; 
    }

    get showPmpNote() {
        if (!this.apiField) return false;
        const t = (this.dataType || 'TEXT').toUpperCase();
        return (t === 'TEXT' || t === 'EMAIL' || t === 'PHONE' || t === 'DATE');
    }

    async loadNextOrder() {
        if (!this.scoringId) return;
        try {
            const nextOrder = await getNextItemOrder({ scoringId: this.scoringId });
            this.order = nextOrder || 1;
        } catch (err) {
            console.error('Error al cargar orden', err);
            this.order = 1;
        }
    }

    loadItem() {
        getItemById({ itemId: this.fieldId })
            .then(res => {
                if (res) {
                    this.label = res.Name;
                    this.apiField = res.kzLeadFieldApi__c;
                    this.dataType = res.kzFieldType__c || ''; 
                    this.pmp = res.kzPMP__c || 0;
                    this.order = res.kzOrder__c || 0;
                    this.active = res.kzActive__c === true;
                    this.description = res.kzDescription__c || '';
                    this.question = res.kzQuestionAgent__c || '';
                }
            })
            .catch(err => {
                const msg = err?.body?.message || err?.message || JSON.stringify(err);
                this.dispatchEvent(new ShowToastEvent({ title: 'Error al cargar', message: msg, variant: 'error' }));
                console.error('getItemById error:', err);
            });
    }

    handleLabel(e) { this.label = e.target.value; }
    handleApiField(e) { /* readonly */ }
    handleType(e) { /* este handler ya no se usa, el campo es readonly */ } 
    handlePmp(e) { this.pmp = parseFloat(e.target.value) || 0; }
    handleOrder(e) { /* La propiedad readonly del HTML lo asegura */ } 
    handleActive(e) { this.active = e.target.checked; }
    handleDescription(e) { this.description = e.target.value; }
    handleQuestion(e) { this.question = e.target.value; }
    
    handleFieldSelected(event) {
        const selectedApiName = event.detail.value;
        
        if (!selectedApiName) {
            this.apiField = '';
            this.dataType = '';
            this.label = '';
            return;
        }

        const selectedField = this.leadFieldOptions.find(opt => opt.value === selectedApiName);

        if (selectedField) {
            const cleanLabel = selectedField.label.replace(/\s\([^)]+\)$/, '');
            const fieldType = selectedField.fieldType;

            this.label = cleanLabel;
            this.apiField = selectedField.value;
            this.dataType = fieldType;

            if (this.label.length > 80) {
                this.label = this.label.substring(0, 77) + '...';
            }
        }
    }

    async handleSave() {
        // Lógica de validación
        const inputFields = [
            ...this.template.querySelectorAll('lightning-input'),
            ...this.template.querySelectorAll('lightning-combobox'),
        ].filter(cmp => cmp.required);

        const allValid = inputFields.reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);

        if (!allValid) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Validación Fallida', message: 'Por favor, revise los campos marcados como requeridos.', variant: 'error' }));
            return;
        }
        
        if (!this.apiField) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Validación Crítica', message: 'Debe seleccionar un campo Lead válido.', variant: 'error' }));
            return;
        }

        if (this.pmp < 0) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Validación', message: 'El PMP debe ser cero o positivo.', variant: 'error' }));
            return;
        }

        const rec = {
            Id: this.fieldId,
            kzScoring__c: this.scoringId,
            Name: this.label,
            kzLeadFieldApi__c: this.apiField,
            kzFieldType__c: this.dataType, 
            kzPMP__c: this.pmp,
            kzOrder__c: this.order,
            kzActive__c: this.active,
            kzDescription__c: this.description,
            kzQuestionAgent__c: this.question
        };

        try {
            await saveItem({ item: rec });
            // Notificación y navegación
            this.dispatchEvent(new CustomEvent('saved', { bubbles: true, composed: true }));
            this.dispatchEvent(new ShowToastEvent({ title: 'Guardado', message: 'Campo guardado exitosamente.', variant: 'success' }));
        } catch (err) {
            console.error('saveItem error raw:', err);
            let msg = 'Error al guardar';
            if (err?.body?.message) {
                msg = err.body.message;
            } else if (err?.message) {
                msg = err.message;
            } else {
                msg = JSON.stringify(err);
            }
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: msg, variant: 'error' }));
        }
    }

    handleCancel() {  
        this.dispatchEvent(new CustomEvent('cancel', { bubbles: true, composed: true }));  
    }
}