import { api, LightningElement, wire,track } from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Opp_OBJECT from '@salesforce/schema/Opportunity';
import NAME_FIELD from '@salesforce/schema/Opportunity.Name';
import adClientField from '@salesforce/schema/Opportunity.Advertiser_Client__c';
import brandField from '@salesforce/schema/Opportunity.Brand__c';
import subField from '@salesforce/schema/Opportunity.SubClient_or_Manufacturer__c';
import { CurrentPageReference } from 'lightning/navigation';
import getFields from '@salesforce/apex/OppRecPageCtrl.getOppFields';
import getAdSubClientsBrands from '@salesforce/apex/OppRecPageCtrl.getAdSubClientsBrands';
import { NavigationMixin } from 'lightning/navigation';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import getContacts from '@salesforce/apex/OppRecPageCtrl.getContacts';
import getRecTypeName from '@salesforce/apex/OppRecPageCtrl.getRecTypeName';
import getEditValue from '@salesforce/apex/OppRecPageCtrl.getEditValue';
import saveNewSubClient from '@salesforce/apex/OppRecPageCtrl.saveNewSubClient';
import checkAccType from '@salesforce/apex/OppRecPageCtrl.checkAccType';
export default class OpportunityRecPageCmp extends NavigationMixin(LightningElement) {
    @api recId;
    accountId;
    showNewSubClient = false;
    activeSections = ['Basic', 'Geography', 'Campaign', 'Audience','Revenue', 'Opportunity'];
    showLossOther = false;
    spin = false;
    newSub;
    subValue = '';
    subDisable = true;
    subOptions;
    objectApiName = Opp_OBJECT.objectApiName;
    fieldsApiName = [];
    adFieldApiName = adClientField.fieldApiName;
    brandOptions;
    brandDisable = true;
    brandValue='';
    recordTypeId;
    adBrandOptions;
    pContOptions;
    contVal;
    adId;
    adMarket = false;
    adRecruit = false;
    showOther = false;
    showRadius = false;
    accId;
    direct;
    //....
   @track Segmentlist;
   @track SegmentValue;
   //....

    geoOp;
    audOp;

    geoVal;
    audVal;
    @wire(getPicklistValuesByRecordType, { objectApiName: 'Opportunity', recordTypeId: '$recordTypeId' })
    
    picklistValues({error, data}){
    	if(data){
        	console.log('PicVal',data);
            if( data != undefined ){
                if( data.picklistFieldValues != undefined ){
                    var geoType = [];
                    var audType = [];
                    if( data.picklistFieldValues.Target_Geo_Type__c != undefined ){
                        data.picklistFieldValues.Target_Geo_Type__c.values.forEach( res=>{
                            geoType.push( {label:res.label, value:res.value} );
                        } );
                    }
                    if( data.picklistFieldValues.Audience_Type__c != undefined ){
                        data.picklistFieldValues.Audience_Type__c.values.forEach( res=>{
                            audType.push( {label:res.label, value:res.value} );
                        } );
                    }
                    this.geoOp = geoType;
                    this.audOp = audType;
                }
            }
        }else if(error){
        	console.log(error);
        }
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
       if (currentPageReference) { 
           console.log(currentPageReference);
            this.accId = currentPageReference.state?.additionalParams;
            if( this.accId != undefined ){
                if( this.accId.includes('accid') ){
                    var aId = this.accId.substring( (this.accId.indexOf('=')+1), this.accId.length-1 );
                    checkAccType( {accId:aId} ).then( res=>{
                        if( res ){
                            this.accId = aId;
                            this.handleAdClient( {target:{value:this.accId}} );
                        }
                    } ).catch(err=>{
                        console.log(err);
                    })
                }
            }
            console.log('aId:',this.accId);
            this.recordTypeId = currentPageReference.state?.recordTypeId;
            console.log('RTypeId:',this.recordTypeId); 
            getRecTypeName( {recId : this.recordTypeId} ).then(res=>{
                if( res == 'Adfire_Health_Recruit' ){
                    this.adRecruit = true;
                }else if( res == 'Adfire_Health_Marketing' ){
                    this.adMarket = true;
                }
            })
       }
    }
    connectedCallback(){
        console.log('RecId:',this.recId);
        this.spin = true;
        if( this.recId != undefined && this.recId != '' ){
            getEditValue( {recId:this.recId} ).then( res=>{
                console.log('=>',res);
                this.spin = false;
                if( res != undefined ){
                    this.recordTypeId = res.RecordTypeId;
                    getRecTypeName( {recId : this.recordTypeId} ).then(res=>{
                        if( res == 'Adfire_Health_Recruit' ){
                            this.adRecruit = true;
                        }else if( res == 'Adfire_Health_Marketing' ){
                            this.adMarket = true;
                        }
                    })
                    this.audVal = res.Audience_Type__c;
                    this.geoVal = res.Target_Geo_Type__c;
                    var dis = res.Direct__c;
                    if( this.geoVal == 'Other' ){
                        this.showOther = true;
                    }else if( this.geoVal == 'Radius' ){
                        this.showRadius = true;
                    }
                    if( res.Loss_Reason__c == 'Other' ){
                        this.showLossOther = true;
                    }else{
                        this.showLossOther = false;
                    }
                    this.contVal = res.Primary_Contact__c;
                    this.brandValue = res.Brand__c;
                    this.subValue = res.SubClient_or_Manufacturer__c;
                }
                this.handleAdClient( {target:{value:res.AccountId}}, 1, dis );
            } ).catch( err=>{
                this.spin = false;
            } );
        }else{
            getFields().then( res=>{
                this.spin = false;
                console.log(res);
                this.fieldsApiName = res;
            } ).catch( err =>{
                this.spin = false;
            })
        }
        //.....
        this.initData();
        //....
    }
//........
    initData() {
        let listOfSegment = [];
        this.createRow(listOfSegment);
        this.Segmentlist = listOfSegment;
    }
    createRow(listOfSegment) {
        let segmentObject = {};
        if(listOfSegment.length > 0) {
            segmentObject.index = listOfSegment[listOfSegment.length - 1].index + 1;
        } else {
            segmentObject.index = 1;
        }
        if(listOfSegment.length > 0) {
            segmentObject.label ='Segment '+`${listOfSegment[listOfSegment.length - 1].index + 0}`;
        } else {
            segmentObject.label  = 'Segment';
        }
        segmentObject.value = null;
        listOfSegment.push(segmentObject);
    }

    handleAddSegmentButton() {
        this.createRow(this.Segmentlist);
    }

    handleSegemntvalue(event){
        let index = event.target.dataset.id;
        let value = event.target.value;
        let segmentvalue =[];

        for(let i = 0; i < this.Segmentlist.length; i++) {
            if(this.Segmentlist[i].index === parseInt(index)) {
                this.Segmentlist[i]["value"] = value;
            }
        }
        for(let i = 0; i < this.Segmentlist.length; i++) {
            if(this.Segmentlist[i].value != '' && this.Segmentlist[i].value != ' ' && this.Segmentlist[i].value != undefined){
                segmentvalue.push(this.Segmentlist[i].value);
            }  
        }
        this.SegmentValue = segmentvalue.join(',');
    }

//..............
    handleAdClient(event, i, dis){
        console.log(event.target.value);
        var adId = event.target.value;
        this.adId = adId;
        console.log('DIS:::>>',dis);
        try{
            var sOptions = [{label:'None', value:'None'}];
            var bOptions = [{label:'None', value:'None'}];
            getAdSubClientsBrands( {adId : adId} ).then(res=>{
                console.log(res);
                if( res != undefined ){
                    if( res.length > 0 ){
                        res.forEach( r =>{
                            if( r.Role == "Sub-Client - Advertiser Client" ){
                                sOptions.push( {label:r.AccountTo.Name, value:r.AccountToId} );
                            }else if( r.Role == "Brand - Advertiser Client" ){
                                bOptions.push( {label:r.AccountTo.Name, value:r.AccountToId} );
                            }
                        } );
                        this.subOptions = sOptions;
                        this.brandOptions = bOptions;
                        this.adBrandOptions = this.brandOptions;
                        this.subDisable = false;
                        if( this.direct != undefined )  this.subDisable = this.direct;
                        if( dis != undefined )  this.subDisable = dis;
                        this.brandDisable = false;
                        if( i == undefined ){
                            this.subValue = 'None';
                            this.brandValue = 'None';
                            this.contVal = 'None';
                        }
                    }else{
                        this.subDisable = true;
                        this.brandDisable = true;
                    }
                    if( this.recId != undefined && this.recId != '' ){
                        console.log('Call');
                        this.handleSubChange( {target:{value:this.subValue}}, i );
                    }
                }
                this.getAllContact();
            }).catch( err=>{
                console.log(err);
                this.subDisable = true;
                this.brandDisable = true;
            } );
        }catch( err ){
            console.log(err);
            this.subDisable = false;
            this.brandDisable = false;
        }
    }
    getAllContact(){
        console.log(this.adId, this.subValue, this.brandValue, this.contVal);
        if( this.adId != undefined && this.adId != '' ){
            var sVal = (this.subValue == undefined || this.subValue == ''|| this.subValue == 'None') ? this.adId : this.subValue;
            var bVal = (this.brandValue == undefined || this.brandValue == ''||this.brandValue == 'None') ? this.adId : this.brandValue;
            console.log('->',this.adId, this.subValue, this.brandValue);
            getContacts({adId:this.adId, subId:sVal, bId:bVal}).then( res=>{
                console.log(res);
                if( res.length > 0 ){
                    var cOptions = [{label:'None', value:'None'}];
                    res.forEach( r =>{
                        cOptions.push( {label:r.Name, value:r.Id} );
                    } );
                    this.pContOptions = cOptions;
                }
            } )
        }
    }
    handleSubChange(event, i) {
        this.subValue = event.target.value;
        var bOptions = [{label:'None', value:'None'}];
        if( this.subValue!= 'None' && this.subValue != '' && this.subValue != undefined ){
            getAdSubClientsBrands( {adId : this.subValue} ).then(res=>{
                console.log(res);
                if( res != undefined ){
                    if( res.length > 0 ){
                        res.forEach( r =>{
                            if( r.Role == "Brand - Sub-Client" ){
                                bOptions.push( {label:r.AccountTo.Name, value:r.AccountToId} );
                            }
                        } );
                        this.brandOptions = bOptions;
                        if( i == undefined ){
                            this.contVal = 'None';
                            this.brandValue = 'None';
                        }
                        this.getAllContact();
                    }
                }
            })
        }else{
            if( i == undefined ){
                this.contVal = 'None';
                this.brandValue = 'None';
            }
            this.brandOptions = this.adBrandOptions;
            this.getAllContact();
        }
    }
    handleTGeoChange( event ){
        this.geoVal = event.target.value;
        if( event.target.value == 'Other' ){
            this.showOther = true;
            this.showRadius = false;
        }else if( event.target.value == 'Radius' ){
            this.showRadius = true;
            this.showOther = false;
        }else{
            this.showOther = false;
            this.showRadius = false;
        }
    }
    handleAudChange( event ){
        this.audVal = event.target.value;
    }
    handlePrimaryContChange( event ){
        this.contVal = event.target.value;
    }
    handleBrandChange(event, i) {
        this.brandValue = event.target.value;
        if( i == undefined )
            this.contVal = 'None';
        this.getAllContact();
    }
    handleSubmit(event){
        console.log("finalsegmentvalue",this.SegmentValue);

        try{
            this.spin = true;
            event.preventDefault();       // stop the form from submitting
            console.log('Sub', this.subValue);
            const fields = event.detail.fields;
            if( this.subValue != 'None' && this.subValue != '' && this.subValue != undefined ){
                fields.SubClient_or_Manufacturer__c = this.subValue;
            }else{
                try{
                    console.log('Sub Null');
                    fields.SubClient_or_Manufacturer__c = '';
                    console.log(fields.SubClient_or_Manufacturer__c);
                }catch( err ){
                    console.log(err);
                }
            }
            if( this.brandValue != 'None' && this.brandValue != '' && this.brandValue != undefined ){
                fields.Brand__c = this.brandValue;
            }else{
                fields.Brand__c = '';
            }
            if( this.SegmentValue != 'None' && this.SegmentValue != '' && this.SegmentValue != undefined ){
                fields.Segment_Name__c = this.SegmentValue;
            }else{
                fields.Segment_Name__c = '';
            }
            if( this.contVal != 'None' && this.contVal != '' && this.contVal != undefined ){
                fields.Primary_Contact__c = this.contVal;
                console.log('cc:',this.contVal);
            }else{
                fields.Primary_Contact__c = '';
            }
            if( this.audVal != 'None' && this.audVal != '' && this.audVal != undefined ){
                fields.Audience_Type__c = this.audVal;
            }else{
                fields.Audience_Type__c = '';
            }
            if( this.geoVal != 'None' && this.geoVal != '' && this.geoVal != undefined ){
                fields.Target_Geo_Type__c = this.geoVal;
                if( this.geoVal != 'Other' ){
                    fields.Target_Geo_Other__c = '';
                }
                if( this.geoVal != 'Radius' ){
                    fields.Target_Geo_Radius__c = '';
                }
            }else{
                fields.Target_Geo_Type__c = '';
                fields.Target_Geo_Radius__c = '';
                fields.Target_Geo_Other__c = '';
            }
            if( fields.Loss_Reason__c != 'Other' ){
                fields.Other_Loss_Reason__c = '';
            }
            fields.RecordTypeId	= this.recordTypeId;
            if( fields.Audience_Type__c == undefined || fields.Audience_Type__c == 'None' || fields.Audience_Type__c == 'null' || fields.Audience_Type__c == '' ||
                fields.Flight_Start_Date__c == undefined || fields.Flight_Start_Date__c == 'None' || fields.Flight_Start_Date__c == 'null' || fields.Flight_Start_Date__c == '' ||
                fields.Flight_End_Date__c == undefined || fields.Flight_End_Date__c == 'None' || fields.Flight_End_Date__c == 'null' || fields.Flight_End_Date__c == ''
            ){
                const event = new ShowToastEvent({
                    title: 'Error',
                    message:'Please Fill All the required fields',
                    variant:'Error'
                });
                this.dispatchEvent( event );
                this.spin = false;
            }else
                this.template.querySelector('lightning-record-edit-form').submit(fields);
            console.log('Submitted',fields.Audience_Type__c);
        }catch( err ){
            this.spin = false;
            console.log(err);
        }
    }
    handleDirect( event ){
        this.direct = event.detail.checked;
        if( event.detail.checked ){
            this.subValue = undefined;
            this.subDisable = true;
        }else{
            this.subDisable = false;
        }
    }
    handleLossRes( event ){
        var lRes = event.target.value;
        if( lRes == 'Other' ){
            this.showLossOther = true;
        }else{
            this.showLossOther = false;
        }
    }
    handleErr( evt ){
        if( evt.detail != undefined ){
            var jsMap = evt.detail.detail;
            const event = new ShowToastEvent({
                title: 'Error',
                message: jsMap,
                variant: 'Error'
            });
            this.spin = false;
            this.dispatchEvent(event);
            console.log(jsMap);    
            console.log(JSON.stringify(evt.detail));
        }
    }
    handleSuccess(event) {
        console.log('hello');
        console.log(event);
        console.log(event.detail.id);
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.detail.id,
                //objectApiName: 'Case', // objectApiName is optional
                actionName: 'view'
            }
        });
    }
    handleClose(){
        if( this.recId == undefined ){
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: 'Opportunity',
                    actionName: 'list'
                },
                state: {
                    // 'filterName' is a property on the page 'state'
                    // and identifies the target list view.
                    // It may also be an 18 character list view id.
                    filterName: 'Recent' // or by 18 char '00BT0000002TONQMA4'
                }
            });
        }else{
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    objectApiName: 'Opportunity',
                    actionName: 'view',
                    recordId : this.recId
                }
            });
        }
    }
    handleAddNewSubClient(){
        console.log(this.adId, this.accId);
        if( this.accId == '' )  this.accId = undefined;
        if( this.adId == undefined && this.accId == undefined ){
            const event = new ShowToastEvent({
                title: 'Error',
                message:'Please Select Account',
                variant:'Error'
            });
            this.dispatchEvent( event );
        }else{
            this.showNewSubClient = true;
        }
    }
    hideModalBox() {  
        this.showNewSubClient = false;
    }
    handleNewSubName( event ){
        this.newSub = event.detail.value;
    }
    handleSaveNewSub( event ){
        console.log(this.newSub);
        if( this.newSub == undefined || this.newSub == '' ){
            const event = new ShowToastEvent({
                title: 'Error',
                message:'Please Fill Name',
                variant:'Error'
            });
            this.dispatchEvent( event );
        }else{
            this.spin = true;
            var aId;
            var dis = this.subDisable;
            console.log('>>>>>',dis);
            if( this.accId != undefined )   aId = this.accId;
            else if( this.adId != undefined ) aId = this.adId;
            this.showNewSubClient = false;
            saveNewSubClient( {accId:aId, subName:this.newSub} ).then( res=>{
                if( res == 'Success' ){
                    const event = new ShowToastEvent({
                        title: 'Success',
                        message:'Record has been created successfully',
                        variant:'Success'
                    });
                    this.dispatchEvent( event );
                    this.newSub = '';
                    this.subDisable = false; 
                }
                this.handleAdClient( {target:{value:aId}}, 1, false );
                this.spin = false;
            } ).catch( err=>{
                this.spin = false;
                console.log(err);
            } );
        }
    }
}