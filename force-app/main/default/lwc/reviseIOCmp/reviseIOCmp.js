import { api, LightningElement } from 'lwc';
import getProductsOfIO from '@salesforce/apex/ReviseIOCls.getProductsOfIO';
import getProducts from '@salesforce/apex/ReviseIOCls.getProducts';
import createNewIO from '@salesforce/apex/ReviseIOCls.createNewIO';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
export default class ReviseIOCmp extends NavigationMixin(LightningElement) {
    //For Combobox
    options=[];
    selectedValue;
    selectedValues = [];
    label;
    minChar = 2;
    disabled = false;
    multiSelect = false;
    value;
    values = [];
    optionData;
    searchString;
    message;
    showDropdown = false;
    showDelete = false;

    @api recId; 
    startDate;
    endDate;
    showSpinner = false;
    handleStartDate( event ){
        this.startDate = event.target.value;
        console.log( this.startDate );
    }
    handleEndDate( event ){
        this.endDate = event.target.value;
        console.log( this.endDate );
    }
    oppCols=[
        {label:'Product', fieldName:'ProductName'},
        {label:'Budget', fieldName:'UnitPrice', editable: true},
        {label:'CPM', fieldName:'ListPrice'},
        {label:'Impressions', fieldName:'Impression__c'},
    ];
    prodCols = [
        {label:'Product', fieldName:'ProductName'},
        {label:'Budget', fieldName:'UnitPrice', editable: true}
    ];
    prods=[];
    draftValues=[];
    oppProds = [];
    preSelectPids = [];
    newProdMap = {};
     connectedCallback(){
        console.log(this.recId);
        getProductsOfIO( {ioId:this.recId} ).then( res=>{
            res = JSON.parse( JSON.stringify(res) );
            var preIds = [];
            var prodPredIds = [];
            var cBoxOp = [];
            res.forEach(oppProd => {
                oppProd.ProductName = oppProd.Product2.Name;
                oppProd.showDropdown = false;
                prodPredIds.push( oppProd.Product2Id );
                preIds.push( oppProd.Id );
                cBoxOp.push( {label:oppProd.Product2.Name, label:oppProd.Product2Id} );
            });
            this.oppProds = res;
            this.preSelectPids = preIds;
            console.log(this.preSelectPids);
            getProducts({ioId:this.recId}).then(res2=>{
                var p = [];
                res2 = JSON.parse( JSON.stringify(res2) );
                res2.forEach(prod => {
                    if( !prodPredIds.includes( prod.Id ) ){
                        p.push( {ProductName:prod.Name, Product2Id : prod.Id} );
                        cBoxOp.push({label:prod.Name, value : prod.Id});
                    }
                });
                this.prods = p;
                this.oppProds = res;
                if( this.oppProds.length > 1 ){
                    this.showDelete = true;
                }
                //For Combobox
                this.options = cBoxOp;
                this.showDropdown = false;
                var optionData = this.options ? (JSON.parse(JSON.stringify(this.options))) : null;
                var value = this.selectedValue ? (JSON.parse(JSON.stringify(this.selectedValue))) : null;
                var values = this.selectedValues ? (JSON.parse(JSON.stringify(this.selectedValues))) : null;
                if(value || values) {
                        var searchString;
                        var count = 0;
                            for(var i = 0; i < optionData.length; i++) {
                                if(this.multiSelect) {
                                    if(values.includes(optionData[i].value)) {
                                        optionData[i].selected = true;
                                        count++;
                                    }  
                                } else {
                                    if(optionData[i].value == value) {
                                        searchString = optionData[i].label;
                                    }
                                }
                            }
                            if(this.multiSelect)
                                this.searchString = count + ' Option(s) Selected';
                            else
                                this.searchString = searchString;
                        }
                        this.value = value;
                        this.values = values;
                        this.optionData = optionData;
            }).catch( err=>{
                console.log(err);
            } );
            console.log(res);
        } ).catch( err=>{
            console.log(err);
        } );
    } 
    handleSave(event){
        var selectedRecords =  this.template.querySelector("lightning-datatable").getSelectedRows();
        if(selectedRecords.length > 0){
            console.log('selectedRecords are ', selectedRecords);
            const records = event.detail.draftValues.slice().map((draftValue) => {
                const fields = Object.assign({}, draftValue);
                return { fields };
            });
            var oProds = this.oppProds;
            records.forEach( rec=>{
                oProds.forEach( oProd =>{
                    if( oProd.Id == rec.fields.Id ){
                        oProd.UnitPrice = rec.fields.UnitPrice;
                    }
                } );
            } );
            this.oppProds = oProds;
            console.log(records);
            console.log(event.detail.draftValues);
        }
    }
    handleNewProdSave( event ){
        console.log('He');
        try{
            const records = event.detail.draftValues.slice().map((draftValue) => {
                const fields = Object.assign({}, draftValue);
                return { fields };
            });
            var newProds = this.prods;
            console.log('NPS:',newProds);
            var nMap = this.newProdMap;
            records.forEach( rec=>{
                rec.fields.Id = parseInt(rec.fields.Id.substring( rec.fields.Id.lastIndexOf('-')+1 )); 
                newProds[rec.fields.Id].UnitPrice = rec.fields.UnitPrice;
                nMap[newProds[rec.fields.Id].Product2Id] = rec.fields.UnitPrice;
            } );
            this.newProdMap = nMap;
            this.prods = newProds;
            console.log(records);
            console.log(event.detail.draftValues);
        }catch( err ){
            console.log(err);
        }
    }
    @api handleRevise(){
        try{
            console.log('Revise');
            this.showSpinner = true;
            console.log(this.oppProds);
            if( this.startDate == undefined || this.startDate == '' || this.endDate == undefined || this.endDate == ''  ){
                this.showSpinner = false;
                const event = new ShowToastEvent({
                    title: 'Error',
                    message:'Please Fill All the required fields',
                    variant:'Error'
                });
                this.dispatchEvent( event );
            }
            else if( this.oppProds.length > 0 ){
                var start = true;
                for( var val of this.oppProds ){
                    if( val.Product2Id == undefined || val.Product2Id == '' ){
                        this.showSpinner = false;
                        start = false;
                        const event = new ShowToastEvent({
                            title: 'Error',
                            message:'Please Fill All the Required Fields',
                            variant:'Error'
                        });
                        this.dispatchEvent( event );
                        break;
                    }
                }
                if( start ){
                    createNewIO( {upItems : this.oppProds, startDate1:this.startDate, endDate1:this.endDate, ioId:this.recId} ).then( res=>{
                        console.log(res);
                        this.showSpinner = false;
                        if( res ){
                            this[NavigationMixin.Navigate]({
                                type: 'standard__recordPage',
                                attributes: {
                                    recordId: res,
                                    //objectApiName: 'Case', // objectApiName is optional
                                    actionName: 'view'
                                }
                            });
                        }
                    } ).catch( err=>{
                        const event = new ShowToastEvent({
                            title: 'Error',
                            message:err,
                            variant:'Error'
                        });
                        this.dispatchEvent(event);
                        this.showSpinner = false;
                        console.log(err);
                    } );
                }
            }else{
                this.showSpinner = false; 
            }
            /* var oppProdsNew = [];
            for( var val in this.newProdMap ){
                if( this.newProdMap[val] != '' ){
                    oppProdsNew.push( {Product2Id:val, UnitPrice:this.newProdMap[val]} );
                }
            }
            var selectedRecords =  this.template.querySelector("lightning-datatable").getSelectedRows();
            for( var val of selectedRecords ){
                console.log(selectedRecords[val]);
                console.log(val);
                oppProdsNew.push( {Product2Id:val.Product2Id, UnitPrice:val.UnitPrice, Id:val.Id} );
            }
            console.log('Final Items:',oppProdsNew);
            if( oppProdsNew.length > 0 ){
                createNewIO( {upItems : oppProdsNew, startDate1:this.startDate, endDate1:this.endDate, ioId:this.recId} ).then( res=>{
                    console.log(res);
                    this.showSpinner = false;
                    if( res == 'Success' ){
                        const event = new ShowToastEvent({
                            title: 'Success',
                            message:'IO has successfully revised.',
                            variant:'Success'
                        });
                        this.dispatchEvent(event);
                        this.dispatchEvent(new CloseActionScreenEvent());
                    }
                } ).catch( err=>{
                    this.dispatchEvent(new CloseActionScreenEvent());
                    this.showSpinner = false;
                    console.log(err);
                } );
            }else{
                this.showSpinner = false; 
                this.dispatchEvent(new CloseActionScreenEvent());
            }*/
        }catch( err ){
            this.showSpinner = false;
            const event = new ShowToastEvent({
                title: 'Error',
                message:err,
                variant:'Error'
            });
            this.dispatchEvent(event);
            console.log(err);
        } 
    }
    
    handleAddProducts(){
        var oppP = [];
        for( var val of this.oppProds ){
            oppP.push( val );
        }
        oppP.push( {ProductName:'',UnitPrice:0,Counts__c:0,Monthly_Frequency__c:30} );
        this.oppProds = oppP;
        this.showDelete = true;
        console.log('added', this.oppProds);
    }
    handleValueChangeP( event ){
        var label  = event.target.dataset.api;
        var idx = event.target.dataset.idx;
        var val = event.target.value;
        console.log(label, idx, val);
        var oppP =[];
        for( var val1 of this.oppProds ){
            oppP.push( val1 );
        }
        console.log(oppP[idx]);
        oppP[idx][label] = val;
        this.oppProds = oppP;
    }
    handleRemoveProducts( event ){
        if( this.oppProds.length > 1 ){ 
            var oppP = [];
            for( var val of this.oppProds ){
                oppP.push( val );
            }
            var i = event.target.dataset.idx;
            oppP.splice(i, 1);
            this.oppProds = oppP;
        }
        if( this.oppProds.length == 1 ){
            this.showDelete = false;
        }
    }
    //For Combobox
    filterOptions(event) {
        this.searchString = event.target.value;
        var idx = event.target.dataset.idx;
        var oppP =[];
        for( var val of this.oppProds ){
            val.showDropdown = false;
            oppP.push( val );
        }
        if( this.searchString && this.searchString.length > 0 ) {
            this.message = '';
            if(this.searchString.length >= this.minChar) {
                var flag = true;
                for(var i = 0; i < this.optionData.length; i++) {
                    if(this.optionData[i].label.toLowerCase().trim().startsWith(this.searchString.toLowerCase().trim())) {
                        this.optionData[i].isVisible = true;
                        flag = false;
                    } else {
                        this.optionData[i].isVisible = false;
                    }
                }
                if(flag) {
                    this.message = "No results found for '" + this.searchString + "'";
                }
            }
            oppP[idx].showDropdown = true;
            this.oppProds = oppP;
            this.showDropdown = true;
        } else {
            this.showDropdown = false;
        }
    }
 
    selectItem(event) {
        var selectedVal = event.currentTarget.dataset.id;
        var slectedPName = event.currentTarget.dataset.pname;
        var idx = event.currentTarget.dataset.idx;
        var oppP =[];
        for( var val of this.oppProds ){
            val.showDropdown = false;
            oppP.push( val );
        }
        if(selectedVal) {
            var options = JSON.parse(JSON.stringify(this.optionData));
            /* var count = 0;
            var options = JSON.parse(JSON.stringify(this.optionData));
            for(var i = 0; i < options.length; i++) {
                if(options[i].value === selectedVal) {
                    if(this.multiSelect) {
                        if(this.values.includes(options[i].value)) {
                            this.values.splice(this.values.indexOf(options[i].value), 1);
                        } else {
                            this.values.push(options[i].value);
                        }
                        options[i].selected = options[i].selected ? false : true;   
                    } else {
                        this.value = options[i].value;
                        this.searchString = options[i].label;
                    }
                }
                if(options[i].selected) {
                    count++;
                }
            } */
            this.optionData = options;

            oppP[idx].showDropdown = false;
            oppP[idx].ProductName = slectedPName;
            oppP[idx].Product2Id = selectedVal;
            this.oppProds = oppP;
            this.showDropdown = false;
        }
    }
 
    showOptions(event) {
        var idx = event.target.dataset.idx;
        var oppP =[];
        console.log('idx:',idx);
        for( var val of this.oppProds ){
            val.showDropdown = false;
            oppP.push( val );
        }
        if(this.disabled == false && this.options) {
            this.message = '';
            this.searchString = '';
            var options = JSON.parse(JSON.stringify(this.optionData));
            for(var i = 0; i < options.length; i++) {
                options[i].isVisible = true;
            }
            if(options.length > 0) {
                oppP[idx].showDropdown = true;
                this.showDropdown = true;
                this.oppProds = oppP;
            }
            this.optionData = options;
        }
 }
 
    removePill(event) {
        var value = event.currentTarget.name;
        var count = 0;
        var options = JSON.parse(JSON.stringify(this.optionData));
        for(var i = 0; i < options.length; i++) {
            if(options[i].value === value) {
                options[i].selected = false;
                this.values.splice(this.values.indexOf(options[i].value), 1);
            }
            if(options[i].selected) {
                count++;
            }
        }
        this.optionData = options;
        if(this.multiSelect)
            this.searchString = count + ' Option(s) Selected';
    }
 
    blurEvent(event) {
        var idx = event.target.dataset.idx;
        var oppP =[];
        for( var val of this.oppProds ){
            val.showDropdown = false;
            oppP.push( val );
        }
        var previousLabel;
        var count = 0;
        for(var i = 0; i < this.optionData.length; i++) {
            if(this.optionData[i].value === this.value) {
                previousLabel = this.optionData[i].label;
            }
            if(this.optionData[i].selected) {
                count++;
            }
        }
        if(this.multiSelect)
         this.searchString = count + ' Option(s) Selected';
        else
         this.searchString = previousLabel;
        
        oppP[idx].showDropdown = false;
        this.oppProds = oppP;
        this.showDropdown = false;
 
        this.dispatchEvent(new CustomEvent('select', {
            detail: {
                'payloadType' : 'multi-select',
                'payload' : {
                    'value' : this.value,
                    'values' : this.values
                }
            }
        }));
    }
    handleClose(){
        this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
               recordId: this.recId,
               actionName: "view"
            }
         });
    }
}