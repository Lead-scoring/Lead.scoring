import { LightningElement, api, track, wire } from 'lwc';
import getItemsByScoring from '@salesforce/apex/KZ_ScoringConfigService.getItemsByScoring';
import deleteItem from '@salesforce/apex/KZ_ScoringConfigService.deleteItem';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class KzScoringFieldList extends LightningElement {
    @api scoringId;
    @track items = [];
    wiredResult;

    columns = [
        { label: 'Nombre', fieldName: 'Name' },
        { label: 'Lead Field', fieldName: 'kzLeadFieldApi__c' },
        { label: 'PMP', fieldName: 'kzPMP__c', type: 'number' },
        { label: 'Activo', fieldName: 'kzActive__c', type: 'boolean' },
        {
            type: 'action',
            typeAttributes: {
                rowActions: this.getRowActions.bind(this)
            }
        }
    ];

    @wire(getItemsByScoring, { scoringId: '$scoringId' })
    wiredItems(result) {
        this.wiredResult = result;
        if (result.data) {
            this.items = result.data;
        } else if (result.error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: result.error.body?.message || result.error.message,
                    variant: 'error'
                })
            );
        }
    }

    getRowActions(row, doneCallback) {
        const type = (row.kzFieldType__c || 'TEXT').toUpperCase();
        const actions = [];

        actions.push({ label: 'Editar', name: 'edit' });

        if (type === 'PICKLIST' || type === 'CHECKBOX' || type === 'NUMBER') {
            actions.push({ label: 'Valores', name: 'values' });
        }

        actions.push({
            label: 'Eliminar',
            name: 'delete',
            iconName: 'utility:delete',
            variant: 'destructive'
        });

        doneCallback(actions);
    }

    handleNew() {
        this.dispatchEvent(new CustomEvent('newitem'));
    }

    handleRowAction(event) {
        const action = event.detail.action.name;
        const row = event.detail.row;

        if (action === 'edit') {
            this.dispatchEvent(new CustomEvent('edititem', { detail: row.Id }));
        } else if (action === 'values') {
            this.dispatchEvent(new CustomEvent('openvalues', { detail: row.Id }));
        } else if (action === 'delete') {
            // Se llama al método de eliminación que ahora captura errores
            this.handleDelete(row.Id);
        }
    }

    // Método para manejar la eliminación con manejo de promesa/error (Corregido)
    async handleDelete(itemId) {
        try {
            const confirmed = confirm('¿Estás seguro de que quieres eliminar este Item de Scoring? Se eliminarán todos sus valores asociados.');
            if (!confirmed) return;

            // Llamada a Apex
            await deleteItem({ itemId: itemId });

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Éxito',
                    message: 'El Item de Scoring se eliminó correctamente.',
                    variant: 'success'
                })
            );
            
            // Refrescar la tabla
            await this.refresh();

        } catch (error) {
            // Manejo de errores más robusto, mostrando el mensaje de Apex
            let message = 'Error desconocido al eliminar.';
            if (error.body && error.body.message) {
                // Captura el mensaje de la AuraHandledException de Apex
                message = error.body.message;
            } else if (error.message) {
                 message = error.message;
            }
            
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error al Eliminar',
                    message: message,
                    variant: 'error'
                })
            );
        }
    }

    @api async refresh() {
        if (this.wiredResult) {
            await refreshApex(this.wiredResult);
        }
    }
}