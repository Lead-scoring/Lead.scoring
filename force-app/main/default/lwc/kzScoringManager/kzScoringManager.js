import { LightningElement, track } from 'lwc';
import deleteConfigApex from '@salesforce/apex/KZ_ScoringConfigService.deleteConfig';
import deleteItemApex from '@salesforce/apex/KZ_ScoringConfigService.deleteItem';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class KzScoringManager extends LightningElement {
    @track currentModal = null;
    @track modalContext = {};
    @track modalStack = [];

    @track showDeleteConfigConfirm = false;
    @track deleteConfigId = null;
    @track deleteConfigLabel = '';

    @track showDeleteItemConfirm = false;
    @track deleteItemId = null;
    @track deleteItemLabel = '';

    // --------------------------------
    get modalContainerClass() {
        if (this.isConfigModal) return 'slds-modal__container slds-modal_medium';
        if (this.isItemsModal) return 'slds-modal__container slds-modal_large';
        if (this.isFieldModal) return 'slds-modal__container slds-modal_large';
        if (this.isValuesModal) return 'slds-modal__container slds-modal_large';
        return 'slds-modal__container';
    }

    // -----------------------------
    // Eventos desde ScoringList
    // -----------------------------
    onNewConfigFromList() {
        this.modalStack = [];
        this.currentModal = 'config';
        this.modalContext = { configId: null };
    }

    onEditConfigFromList(event) {
        this.modalStack = [];
        const id = event?.detail;
        this.currentModal = 'config';
        this.modalContext = { configId: id };
    }

    onViewItemsFromList(event) {
        this.modalStack = [];
        const id = event?.detail;
        this.currentModal = 'items';
        this.modalContext = { configId: id };
    }

    onDeleteConfigFromList(event) {
        const payload = event?.detail || {};
        this.deleteConfigId = payload.id;
        this.deleteConfigLabel = payload.label;
        this.showDeleteConfigConfirm = true;
    }

    // -----------------------------
    // Eventos desde Items
    // -----------------------------
    handleNewField() {
        this.modalStack.push(this.currentModal);
        this.currentModal = 'field';
        this.modalContext = { configId: this.modalContext.configId, fieldId: null };
    }

    handleEditField(event) {
        this.modalStack.push(this.currentModal);
        const id = event?.detail;
        this.currentModal = 'field';
        this.modalContext = { configId: this.modalContext.configId, fieldId: id };
    }

    handleOpenValues(event) {
        this.modalStack.push(this.currentModal);
        const fieldId = event?.detail;
        this.currentModal = 'values';
        this.modalContext = { configId: this.modalContext.configId, fieldId };
    }

    handleDeleteField(event) {
        const id = event?.detail;
        const row = this.template.querySelector('c-kz-scoring-field-list')?.items.find(i => i.Id === id);
        this.deleteItemId = id;
        this.deleteItemLabel = row ? row.Name : 'Campo';
        this.showDeleteItemConfirm = true;
    }

    // -----------------------------
    // Cierre / Volver
    // -----------------------------
    handleChildCancel() {
        if (this.modalStack.length > 0) {
            const previous = this.modalStack.pop();
            this.currentModal = previous;
            if (previous === 'items') {
                this.modalContext = { configId: this.modalContext.configId };
            }
            return;
        }
        this.handleCloseModal();
    }

    handleBack() { this.handleChildCancel(); }

    handleCloseModal() {
        const list = this.template.querySelector('c-kz-scoring-list');
        if (list && list.refresh) {
            list.refresh();
        }
        this.currentModal = null;
        this.modalContext = {};
        this.modalStack = [];
    }

    // -----------------------------
    // Guardar
    // -----------------------------
    async handleConfigSaved(event) {
        await this.refreshConfigList();
        if (!this.modalContext.configId) {
            const newId = event?.detail?.id;
            this.modalStack = [];
            this.currentModal = 'items';
            this.modalContext = { configId: newId };
        } else {
            this.handleCloseModal();
        }
    }

    async handleFieldSaved() {
        // FIX 1 (Sincronización): Cambiamos la vista y esperamos un tick antes de refrescar
        this.currentModal = 'items';
        // Esperar el siguiente tick del DOM para que c-kz-scoring-field-list esté activo
        await new Promise(resolve => setTimeout(resolve, 0)); 
        await this.refreshItemsList();
    }

    async handleValuesSaved() {
        // FIX 1 (Sincronización): Cambiamos la vista y esperamos un tick antes de refrescar
        this.currentModal = 'items';
        await new Promise(resolve => setTimeout(resolve, 0));
        await this.refreshItemsList();
    }

    // -----------------------------
    // Confirm Delete
    // -----------------------------
    async confirmDeleteConfig() {
        try {
            await deleteConfigApex({ configId: this.deleteConfigId });
            this.dispatchEvent(new ShowToastEvent({ title: 'Éxito', message: 'Configuración eliminada', variant: 'success' }));
            this.cancelDeleteConfig();
            await this.refreshConfigList();
        } catch (err) {
            console.error(err);
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: 'No se pudo eliminar', variant: 'error' }));
        }
    }

    cancelDeleteConfig() {
        this.showDeleteConfigConfirm = false;
        this.deleteConfigId = null;
        this.deleteConfigLabel = '';
    }

    async confirmDeleteItem() {
        try {
            await deleteItemApex({ itemId: this.deleteItemId });
            this.dispatchEvent(new ShowToastEvent({ title: 'Éxito', message: 'Campo eliminado', variant: 'success' }));
            this.cancelDeleteItem();
            await this.refreshItemsList();
        } catch (err) {
            console.error(err);
             this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: err.body?.message || 'Error al eliminar Item.', variant: 'error' }));
        }
    }

    cancelDeleteItem() {
        this.showDeleteItemConfirm = false;
        this.deleteItemId = null;
        this.deleteItemLabel = '';
    }

    // -----------------------------
    // Refresh
    // -----------------------------
    refreshConfigList() {
        const list = this.template.querySelector('c-kz-scoring-list');
        if (list && list.refresh) return list.refresh();
    }

    refreshItemsList() {
        const list = this.template.querySelector('c-kz-scoring-field-list');
        if (list && list.refresh) return list.refresh();
    }

    // -----------------------------
    // Getters
    // -----------------------------
    get isConfigModal() { return this.currentModal === 'config'; }
    get isItemsModal() { return this.currentModal === 'items'; }
    get isFieldModal() { return this.currentModal === 'field'; }
    get isValuesModal() { return this.currentModal === 'values'; }

    get modalTitle() {
        if (this.isConfigModal) return this.modalContext.configId ? 'Modificar Configuración' : 'Nueva Configuración';
        if (this.isItemsModal) return 'Campos del Scoring';
        if (this.isFieldModal) return this.modalContext.fieldId ? 'Editar Campo' : 'Nuevo Campo';
        if (this.isValuesModal) return 'Valores del Campo';
        return '';
    }

    // FIX 2: El botón "Volver" solo aparece si hay stack Y NO estamos en la vista de ítems principal.
    get showBackButton() { 
        return this.modalStack.length > 0 && 
               !this.isItemsModal; 
    }
}