import { LightningElement, api, track } from 'lwc';
import getConfig from '@salesforce/apex/KZ_ScoringConfigService.getConfig';
import saveConfig from '@salesforce/apex/KZ_ScoringConfigService.saveConfig';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class KzScoringForm extends LightningElement {
    _configId;
    @api
    get configId() { return this._configId; }
    set configId(value) {
        this._configId = value;
        this.loadConfig();
    }

    @track name = '';
    @track active = false;

    connectedCallback() {
        if (this._configId) this.loadConfig();
    }

    async loadConfig() {
        if (!this._configId) {
            this.name = '';
            this.active = false;
            return;
        }
        try {
            const data = await getConfig({ recordId: this._configId });
            if (data) {
                this.name = data.Name || '';
                this.active = data.kzActive__c === true;
            } else {
                this.name = '';
                this.active = false;
            }
        } catch (err) {
            console.error('getConfig error', err);
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: 'No se pudo cargar la configuración', variant: 'error' }));
        }
    }

    handleName(e) { this.name = e.target.value; }
    handleActive(e) { this.active = e.target.checked; }

    async handleSave() {
        // Creamos el objeto (puedes dejar el nombre de la variable 'rec' aquí)
        const rec = { 
            Id: this._configId, 
            Name: this.name, 
            kzActive__c: this.active,
            sobjectType: 'kzScoring__c' // Es buena práctica incluir esto para Apex
        };

        try {
            // CAMBIO AQUÍ: Cambiamos 'rec:' por 'record:' para que coincida con Apex
            const id = await saveConfig({ record: rec }); 
            
            const returnedId = id || this._configId;
            this.dispatchEvent(new CustomEvent('saved', { detail: { id: returnedId }, bubbles: true, composed: true }));
            this.dispatchEvent(new ShowToastEvent({ title: 'Guardado', message: 'Configuración guardada', variant: 'success' }));
        } catch (err) {
            const msg = err?.body?.message || err?.message || JSON.stringify(err);
            this.dispatchEvent(new ShowToastEvent({ title: 'Error al guardar', message: msg, variant: 'error' }));
        }
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel', { bubbles: true, composed: true }));
    }
}