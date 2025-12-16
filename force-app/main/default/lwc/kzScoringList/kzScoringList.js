import { LightningElement, track, wire, api } from 'lwc';
import getScoringList from '@salesforce/apex/KZ_ScoringConfigService.getScoringList';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

const COLUMNS = [
    { label: 'Nombre', fieldName: 'Name' },
    { label: 'Descripción', fieldName: 'kzDescription__c' },
    { label: 'Activo', fieldName: 'kzActive__c', type: 'boolean' },
    {
        type: 'action',
        typeAttributes: {
            rowActions: [
                { label: 'Editar', name: 'edit' },
                { label: 'Ver Items', name: 'viewItems' },
                { label: 'Eliminar', name: 'delete' }
            ]
        }
    }
];

export default class KzScoringList extends LightningElement {
    @track configs = [];
    wiredResult;
    columns = COLUMNS;
    _needsRefresh = false;

    @wire(getScoringList)
    wiredScorings(result) {
        this.wiredResult = result;
        if (result.data) {
            this.configs = result.data;
        } else if (result.error) {
            const msg = result.error?.body?.message || result.error?.message || JSON.stringify(result.error);
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: msg, variant: 'error' }));
        }
    }

    // Public API to refresh from parent
    @api async refresh() {
        if (this.wiredResult) {
            await refreshApex(this.wiredResult);
        }
    }

    // Allow parent to mark for refresh on next render
    @api markForRefresh() {
        this._needsRefresh = true;
    }

    renderedCallback() {
        if (this._needsRefresh) {
            this._needsRefresh = false;
            this.refresh();
        }
    }

    handleNew() {
        this.dispatchEvent(new CustomEvent('newconfig', { bubbles: true, composed: true }));
    }

    handleRowAction(event) {
        const action = event.detail.action.name;
        const row = event.detail.row;
        if (action === 'edit') {
            this.dispatchEvent(new CustomEvent('editconfig', { detail: row.Id, bubbles: true, composed: true }));
        } else if (action === 'viewItems') {
            this.dispatchEvent(new CustomEvent('viewitems', { detail: row.Id, bubbles: true, composed: true }));
        } else if (action === 'delete') {
            this.dispatchEvent(new CustomEvent('deleteconfig', { detail: { id: row.Id, label: row.Name }, bubbles: true, composed: true }));
        }
    }
}
