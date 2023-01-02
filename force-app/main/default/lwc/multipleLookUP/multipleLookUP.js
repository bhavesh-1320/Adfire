import { LightningElement,api,track } from 'lwc';
import getResults from '@salesforce/apex/ProposalIOInvoiceCls.getResults';

export default class MultipleLookUP extends LightningElement {
    @api objectName = 'Account';
    @api fieldName = 'Name';
    @api Label;
    @track searchRecords = [];
    @api selectedRecords = [];
    @api required = false;
    @api iconName = 'action:new_account'
    @api LoadingText = false;
    @track txtclassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    @track messageFlag = false;
    @api idx;
    @api idx2;
    searchField(event) {

        var currentText = event.target.value;
        var selectRecId = [];
        for(let i = 0; i < this.selectedRecords.length; i++){
            selectRecId.push(this.selectedRecords[i].recId);
        }
        this.LoadingText = true;
        getResults({ value: currentText })
        .then(result => {
            this.searchRecords= result;
            this.LoadingText = false;
            
            this.txtclassname =  result.length > 0 ? 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open' : 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
            if(currentText.length > 0 && result.length == 0) {
                this.messageFlag = true;
            }
            else {
                this.messageFlag = false;
            }

            if(this.selectRecordId != null && this.selectRecordId.length > 0) {
                this.iconFlag = false;
                this.clearIconFlag = true;
            }
            else {
                this.iconFlag = true;
                this.clearIconFlag = false;
            }
        })
        .catch(error => {
            console.log('-------error-------------'+error);
            console.log(error);
        });
        
    }
    connectedCallback(){
        console.log('ll__--L>',JSON.parse(JSON.stringify(this.selectedRecords)));
        console.log('IDS:',this.idx, this.idx2);
    }
   setSelectedRecord(event) {
       console.log('Hello');
        var recId = event.currentTarget.dataset.id;
        var selectName = event.currentTarget.dataset.name;
        let newsObject = { 'recId' : recId ,'recName' : selectName };
        console.log(newsObject);
        try{
            var obj = JSON.parse( JSON.stringify( this.selectedRecords ) );
            obj.push(newsObject);
            this.selectedRecords = obj;
        }catch( err ){
            console.log(err);
        }

        console.log('REDS:',this.selectedRecords);
        this.txtclassname =  'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
        let selRecords = this.selectedRecords;
		this.template.querySelectorAll('lightning-input').forEach(each => {
            each.value = '';
        });
        const selectedEvent = new CustomEvent('selected', { detail: {idx:this.idx, idx2:this.idx2, segs: selRecords}, });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }

    removeRecord (event){
        let selectRecId = [];
        for(let i = 0; i < this.selectedRecords.length; i++){
            if(event.detail.name !== this.selectedRecords[i].recId)
                selectRecId.push(this.selectedRecords[i]);
        }
        this.selectedRecords = [...selectRecId];
        let selRecords = this.selectedRecords;
        const selectedEvent = new CustomEvent('selected', { detail: {idx:this.idx, idx2:this.idx2, segs: selRecords}, });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }
}