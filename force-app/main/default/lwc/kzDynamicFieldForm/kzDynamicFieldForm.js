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

    @track leadFieldOptions = [];
    @track isEditMode = false;

    connectedCallback() {
        this.isEditMode = !!this.fieldId;
        if (this.isEditMode) {
            this.loadItem();
        } else {
            this.loadNextOrder();
        }
    }

    @wire(getAllLeadFieldsForScoring)
    wiredLeadFields({ data, error }) {
        if (data) {
            this.leadFieldOptions = data;
        } else if (error) {
            this.showError('No se pudieron cargar los campos del Lead');
            console.error(error);
        }
    }

    get showDataTypeField() {
        return !!this.apiField;
    }

    get showPmpNote() {
        const type = (this.dataType || 'TEXT').toUpperCase();
        return ['TEXT', 'EMAIL', 'PHONE', 'DATE'].includes(type);
    }

    async loadNextOrder() {
        if (!this.scoringId) return;
        try {
            this.order = await getNextItemOrder({ scoringId: this.scoringId }) || 1;
        } catch (e) {
            this.order = 1;
            console.error(e);
        }
    }

    async loadItem() {
        try {
            const res = await getItemById({ itemId: this.fieldId });
            if (!res) return;

            this.label = res.Name || '';
            this.apiField = res.kzLeadFieldApi__c || '';
            this.dataType = res.kzFieldType__c || '';
            this.pmp = res.kzPMP__c || 0;
            this.order = res.kzOrder__c || 0;
            this.active = res.kzActive__c === true;
            this.description = res.kzDescription__c || '';
            this.question = res.kzQuestionAgent__c || '';
        } catch (e) {
            this.showError('No se pudo cargar el campo');
            console.error(e);
        }
    }

    handleFieldSelected(event) {
        const apiName = event.detail.value;
        if (!apiName) return;

        const field = this.leadFieldOptions.find(f => f.value === apiName);
        if (!field) return;

        this.apiField = field.value;
        this.dataType = field.fieldType;

        const cleanLabel = field.label.replace(/\s\([^)]+\)$/, '');
        this.label = cleanLabel.length > 80 ? cleanLabel.substring(0, 77) + '...' : cleanLabel;
    }

    handleLabel(e) { this.label = e.target.value; }
    handlePmp(e) { this.pmp = Number(e.target.value) || 0; }
    handleActive(e) { this.active = e.target.checked; }
    handleDescription(e) { this.description = e.target.value; }
    handleQuestion(e) { this.question = e.target.value; }

    async handleSave() {
        const requiredInputs = this.template.querySelectorAll('[required]');
        let valid = true;
        requiredInputs.forEach(i => {
            i.reportValidity();
            valid = valid && i.checkValidity();
        });

        if (!valid) {
            this.showError('Complete los campos requeridos');
            return;
        }

        if (this.pmp < 0) {
            this.showError('El PMP debe ser mayor o igual a 0');
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
            this.dispatchEvent(new CustomEvent('saved', { bubbles: true, composed: true }));
            this.showSuccess('Campo guardado correctamente');
        } catch (e) {
            this.showError(e?.body?.message || 'Error al guardar');
            console.error(e);
        }
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel', { bubbles: true, composed: true }));
    }

    showError(message) {
        this.dispatchEvent(new ShowToastEvent({ title: 'Error', message, variant: 'error' }));
    }

    showSuccess(message) {
        this.dispatchEvent(new ShowToastEvent({ title: 'Éxito', message, variant: 'success' }));
    }
}
