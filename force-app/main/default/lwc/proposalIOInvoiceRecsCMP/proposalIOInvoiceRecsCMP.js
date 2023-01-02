import { api, LightningElement, track, wire } from 'lwc';
import getQuoteInvoice from '@salesforce/apex/ProposalIOInvoiceCls.getQuoteInvoice';
import getContractInvoice from '@salesforce/apex/ProposalIOInvoiceCls.getContractInvoice';
import saveInvoice from '@salesforce/apex/ProposalIOInvoiceCls.saveInvoice';
import saveIOInvoice from '@salesforce/apex/ProposalIOInvoiceCls.saveIOInvoice';
import getOppProds from '@salesforce/apex/ProposalIOInvoiceCls.getOppProds';
import getProducts from '@salesforce/apex/ProposalIOInvoiceCls.getProducts';
import getOppSegments from '@salesforce/apex/ProposalIOInvoiceCls.getOppSegments';
import getSegments from '@salesforce/apex/ProposalIOInvoiceCls.getAllSegments';
import getContractInvoiceStartEnd from '@salesforce/apex/ProposalIOInvoiceCls.getContractInvoiceStartEnd';
import createNewSegments from '@salesforce/apex/ProposalIOInvoiceCls.createNewSegments';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import dataSource from '@salesforce/schema/Invoice_Line_Item__c.Data_Source__c';
import InvoiceLineItem from '@salesforce/schema/Invoice_Line_Item__c';

export default class ProposalIOInvoiceRecsCMP extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;
    invoiceRecords;
    oppSegIdMap;
    spin = true;
    showQuantity = false;
    selectSegs = {};
    newSegmentRecords = {};
    dSourceValues = [];
    recordTypeId = '';
    dataSourceOptions;

    // @wire(getObjectInfo, { objectApiName: InvoiceLineItem })
    // getObjectData({ data, error }) {
    //     if (data) {
    //         this.recordTypeId = data.defaultRecordTypeid;
    //     } else if (error) {
    //         console.error(error);
    //     }
    // }
    @wire(getObjectInfo, { objectApiName: InvoiceLineItem })
    ioInvoiceLIMetadata;

    @wire(getPicklistValues, {
        recordTypeId: '$ioInvoiceLIMetadata.data.defaultRecordTypeId',
        fieldApiName: dataSource
    })
    picklistOptions({ data, error }) {
        if (data) {
            this.dataSourceOptions = data.values;
        } else if (error) {
            console.error(error);
        }
    }

    // get dataSourceOptions() {
    //     return [
    //         { label: 'DCM', value: 'DCM' },
    //         { label: 'TTD', value: 'TTD' },
    //         { label: 'Facebook', value: 'Facebook' },
    //         { label: 'LinkedIn', value: 'LinkedIn' },
    //         { label: 'Google Ads', value: 'Google Ads' }
    //     ];
    // }

    editSegOptions = [
        { label: 'Add Segment', value: 'Add Segment' },
        { label: 'Remove Segment', value: 'Remove Segment' },
    ];
    selectedSegOpValue = 'Add Segment';
    eDate;
    segNum;
    segNum2;

    segmentOptions = [];
    segValue;
    segLabel;

    delRecs = [];
    oppProducts;
    optionData = [];
    values;
    value;
    searchString;
    multiSelect;
    options;
    showDropdown = false;
    minChar = 2;

    oppSegNames;
    showSeg = false;
    //For multiple lookup
    @api objectName = 'User';
    @api fieldName = '';
    @api filterField = ''; //used to provide filter field in where clause
    @api filterFieldValue = ''; //used to provide filter field value in where clause
    @api useFilterCriteria = false; // used to toggle the where clause in soql query
    @api singleSelection = false; // used to toggle between single select and multi select
    @track disableInputField = false;

    @api Label;

    @track searchRecords = [];
    @track selectedIds = [];
    @track selectedRecords = [];
    @api selectedFromParent = [];
    @api required = false;
    @api iconName = 'action:new_user'
    @api LoadingText = false;
    @track dynamiClassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    @track messageFlag = false;

    showSegDrop = false;
    connectedCallback() {
        console.log('LookuoComponentinserted')
        console.log(this.selectedFromParent);
        console.log('SELID:', this.selectedIds);

        if (this.selectedFromParent != undefined) {
            this.selectedRecords = [...this.selectedFromParent];
            if (this.singleSelection) {
                this.disableInputField = true;
            }
        }
        console.log(this.recordId, this.objectApiName);
        console.log('Outside Quote');
        getOppProds({ quoteId: this.recordId, objName: this.objectApiName }).then(res2 => {
            res2.forEach(r => {
                r.ProdName = r.Product2.Name;
            });
            this.oppProducts = res2;
        });
        getProducts({ quoteId: this.recordId, objName: this.objectApiName }).then(res2 => {
            var p = [];
            var cBoxOp = [];
            res2 = JSON.parse(JSON.stringify(res2));
            res2.forEach(prod => {
                p.push({ ProductName: prod.Name, Product2Id: prod.Id });
                cBoxOp.push({ label: prod.Name, value: prod.Id });
            });
            this.prods = p;
            //For Combobox
            this.options = cBoxOp;
            this.showDropdown = false;
            var optionData = this.options ? (JSON.parse(JSON.stringify(this.options))) : null;
            var value = this.selectedValue ? (JSON.parse(JSON.stringify(this.selectedValue))) : null;
            var values = this.selectedValues ? (JSON.parse(JSON.stringify(this.selectedValues))) : null;
            if (value || values) {
                var searchString;
                var count = 0;
                for (var i = 0; i < optionData.length; i++) {
                    if (this.multiSelect) {
                        if (values.includes(optionData[i].value)) {
                            optionData[i].selected = true;
                            count++;
                        }
                    } else {
                        if (optionData[i].value == value) {
                            searchString = optionData[i].label;
                        }
                    }
                }
                if (this.multiSelect)
                    this.searchString = count + ' Option(s) Selected';
                else
                    this.searchString = searchString;
            }
            this.value = value;
            this.values = values;
            this.optionData = optionData;
        }).catch(err => {
            console.log(err);
        });

        if (this.objectApiName == 'Quote') {
            console.log('Inside Quote');
            this.showQuantity = true;
            getOppSegments({ quoteId: this.recordId }).then(res1 => {
                console.log('SegName:', res1);
                var segName = '';
                res1.forEach(r => {
                    segName += r.Segment__r.Name + ',';
                });
                segName = segName.substring(0, segName.length - 1);
                getQuoteInvoice({ quoteId: this.recordId }).then(res => {
                    console.log(res);
                    var campName;
                    var flight;
                    res.forEach(ele => {
                        ele.showLItems = false;
                        ele.iconName = "utility:chevronright";
                        ele.CampName = ele.Proposal__r.Campaign_Name__c;
                        campName = ele.CampName;
                        ele.Flight = ele.Proposal__r.Flight__c;
                        ele.SegName = segName;
                        segName = segName;
                        flight = ele.Flight;
                        if (ele.Proposal_Line_Items__r.length > 1) {
                            ele.showDelete = true;
                        } else {
                            ele.showDelete = false;
                        }
                        if (ele.Proposal_Line_Items__r != undefined) {
                            ele.Proposal_Line_Items__r.forEach(e => {
                                e.ProdName = e.Product2.Name;
                                e.showDropdown = false;
                                e.new = false;
                            });
                        }
                    });
                    var obj = { CampName: campName, search: true, SegName: segName, iconName: 'utility:chevronright', showLItems: false, Flight: flight, allItems: res };
                    var arr = [];
                    arr.push(obj);
                    this.invoiceRecords = res;
                    console.log('12', this.invoiceRecords);
                    console.log(this.invoiceRecords.SegName);
                }).catch(err => {
                    console.log(err);
                });
            }).catch(err => {
                console.log(err);
            });
        } else if (this.objectApiName == 'Contract') {
            console.log('Inside Contract');
            getOppSegments({ quoteId: this.recordId, objName: 'Contract' }).then(res1 => {
                console.log('SegName:', res1);
                var segName = '';
                var seSegMap = {};
                var startEndDate = {};
                var sIds = [];
                var ioSegIdMap1 = [];
                res1.forEach(r => {
                    var obj = { 'recName': r.Segment__r.Name, 'recId': r.Segment__c };
                    ioSegIdMap1.push(obj);
                    console.log('---SS--', r.Segment__c);
                    sIds.push(r.Segment__c);
                    segName += r.Segment__r.Name + ',';
                    console.log('SQ:', r.Start_Date__c);
                    if (seSegMap[new Date(r.Start_Date__c) + ':' + new Date(r.End_Date__c)] == undefined) {
                        seSegMap[new Date(r.Start_Date__c) + ':' + new Date(r.End_Date__c)] = [];
                    }
                    startEndDate[new Date(r.Start_Date__c)] = new Date(r.End_Date__c);
                    seSegMap[new Date(r.Start_Date__c) + ':' + new Date(r.End_Date__c)].push(r.Segment__r.Name);
                });
                this.oppSegIdMap = ioSegIdMap1;
                console.log('SE:', seSegMap);
                segName = segName.substring(0, segName.length - 1);
                var campName;
                var flight;
                if (segName == undefined || segName == '' || segName == ' ' || segName == ',') {
                    segName = 'No Segments';
                }
                this.oppSegNames = segName;
                this.selectedIds = sIds;
                console.log('SSSSS====', sIds);
                getSegments({ value: undefined, selectedRecId: sIds }).then(res => {
                    console.log('SEGMEN:', res);
                    var sOps = [];
                    res.forEach(r => {
                        sOps.push({ label: r.recName, value: r.recId });
                    });
                    this.segmentOptions = sOps;
                    getContractInvoice({ contractId: this.recordId }).then(res => {
                        console.log('RESTest:', res);
                        res = JSON.parse(JSON.stringify(res));
                        var res2 = res['Invoice Recs'].Invoices;
                        var segments = res['Segments'];
                        console.log('res2:', res2);
                        res2.forEach(ele => {
                            console.log('->', new Date(ele.End_Date__c));
                            console.log('--->', ele.End_Date__c);
                            if (this.eDate == undefined) {
                                this.eDate = new Date(ele.End_Date__c);
                            }
                            if (this.eDate < new Date(ele.End_Date__c)) {
                                this.eDate = new Date(ele.End_Date__c);
                            }
                            ele.showLItems = false;
                            ele.iconName = "utility:chevronright";
                            ele.iconName2 = "utility:chevronright";
                            console.log('IO:', ele.IO__r);
                            ele.CampName = ele.IO__r.Campaign_Name__c;
                            campName = ele.CampName;
                            ele.Flight = ele.IO__r.Flight__c;
                            flight = ele.Flight;
                            if (ele.Opportunity_Segments__r != undefined) {
                                if (ele.Opportunity_Segments__r.length > 0) {
                                    var sNames = [];
                                    ele.Opportunity_Segments__r.forEach(e => {
                                        sNames.push(e.Segment__r.Name);
                                    });
                                    ele.SegName = sNames.join();
                                } else {
                                    ele.SegName = 'No Segments';
                                }
                            } else {
                                ele.SegName = 'No Segments';
                            }

                            ele.showLItemsInside = false;
                            if (ele.Invoice_Line_Items__r != undefined) {
                                if (ele.Invoice_Line_Items__r.length > 1) {
                                    ele.showDelete = true;
                                } else {
                                    ele.showDelete = false;
                                }
                                var segCName = [];
                                if (ele.Invoice_Line_Items__r != undefined) {
                                    ele.Invoice_Line_Items__r.forEach(e => {
                                        e.CampaignUrl = e.Trade_Desk_Campaign__c;
                                        console.log('----------', e.Trade_Desk_Campaign__c);
                                        if (e.Trade_Desk_Campaign__c != undefined) {
                                            var a = e.Trade_Desk_Campaign__c.substring(0, e.Trade_Desk_Campaign__c.lastIndexOf('/'));
                                            e.CampaignId = a.substring(a.lastIndexOf('/') + 1);
                                            console.log('campId:', e.CampaignId);
                                        } else {
                                            e.CampaignId = '';
                                        }
                                        e.ProdName = e.Product__r.Name;
                                        e.UnitPrice = e.Sales_Price__c;
                                        e.showDropdown = false;
                                        e.showAddNewSeg = false;
                                        var ioLSegments = segments[e.Id];
                                        var ioSegs = [];
                                        var ioSegIdMap = [];
                                        if (ioLSegments != undefined) {
                                            for (var v of ioLSegments) {
                                                var obj = { 'recName': v.Segment__r.Name, 'recId': v.Segment__c };
                                                ioSegs.push(v.Segment__r.Name);
                                                segCName.push(v.Segment__r.Name);
                                                ioSegIdMap.push(obj);
                                            }
                                        }
                                        if (ioSegs.length > 0) {
                                            e.SegmentsName = ioSegs.join(',');
                                        } else {
                                            e.SegmentsName = 'No Segments';
                                        }
                                        console.log('------>>>::', ioSegIdMap);
                                        e.segmentIdMap = ioSegIdMap;
                                        e.new = false;
                                    });
                                } else {
                                    ele.Invoice_Line_Items__r = [];
                                }
                                if (segCName.length > 0) {
                                    segCName = segCName.filter((item,
                                        index) => segCName.indexOf(item) === index);
                                    const index = segCName.indexOf('No Segments');
                                    if (index > -1 && segCName.length > 1) {
                                        segCName.splice(index, 1);
                                    }

                                    ele.SegName = segCName.join(',');
                                }

                                ele.Proposal_Line_Items__r = ele.Invoice_Line_Items__r;
                            } else {
                                ele.showDelete = false;
                            }
                        });
                        console.log('RRESS::--::', res2);
                        this.invoiceRecords = res2;
                        this.spin = false;
                        // this.invoiceRecords = res; 
                    }).catch(err => {
                        this.spin = false;
                        console.log(err);
                    });
                }).catch(err => {
                    this.spin = false;
                    console.log(err);
                })
            });
        }
    }
    handleAddSegments(event) {
        this.segNum = event.target.dataset.idx;
        this.segNum2 = event.target.dataset.idx2;
        var invRec = this.invoiceRecords.slice();
        if (event.target.label == 'Edit Segments') {
            invRec[this.segNum].Proposal_Line_Items__r[this.segNum2].showAddNewSeg = true;
            event.target.label = 'Save Segments';
        } else {
            event.target.label = 'Edit Segments';
            try {
                invRec[this.segNum].Proposal_Line_Items__r[this.segNum2].showAddNewSeg = false;
                var seN = invRec[this.segNum].SegName.split(',');
                console.log(invRec[this.segNum].Proposal_Line_Items__r[this.segNum2].showAddNewSeg);
                if (event.detail != undefined) {
                    var res = JSON.parse(JSON.stringify(this.selectSegs));
                    console.log('SSEE;;;', res);
                    var val = res[this.segNum + ':' + this.segNum2];
                    if (val != undefined) {
                        console.log(val);
                        var objs = [];
                        var sNames = [];
                        // var sArr = invRec[this.segNum].Proposal_Line_Items__r[this.segNum2].segmentIdMap.slice();
                        for (var v of val) {
                            var o = { 'Segment__c': v.recId, 'IO_Invoice_Line_Item__c': invRec[this.segNum].Proposal_Line_Items__r[this.segNum2].Id };
                            objs.push(o);
                            seN.push(v.recName);
                            sNames.push(v.recName);
                        }
                        seN = seN.filter((item,
                            index) => seN.indexOf(item) === index);
                        const index = seN.indexOf('No Segments');
                        if (index > -1 && seN.length > 1) {
                            seN.splice(index, 1);
                        }
                        if (seN.length > 0) {
                            invRec[this.segNum].SegName = seN.join(',');
                        } else {
                            invRec[this.segNum].SegName = 'No Segments';
                        }
                        if (sNames.length > 0) {
                            invRec[this.segNum].Proposal_Line_Items__r[this.segNum2].SegmentsName = sNames.join(',');
                        } else {
                            invRec[this.segNum].Proposal_Line_Items__r[this.segNum2].SegmentsName = 'No Segments';
                        }
                        console.log('----');
                        console.log(invRec[this.segNum].Proposal_Line_Items__r[this.segNum2].segmentIdMap);
                        console.log(res);
                        invRec[this.segNum].Proposal_Line_Items__r[this.segNum2].segmentIdMap = val;
                        this.newSegmentRecords[this.segNum + ':' + this.segNum2] = objs;
                        console.log('NewSeg:', this.newSegmentRecords);
                    }
                }
            } catch (err) {
                console.log(err);
            }
        }
        this.invoiceRecords = invRec;
    }
    hideModalBox() {
        this.showSeg = false;
    }
    handleSelectEvent(event) {
        console.log('EVE:', JSON.parse(JSON.stringify(event.detail)));
        this.selectSegs[event.detail.idx + ':' + event.detail.idx2] = event.detail.segs;
        console.log('->;', this.selectSegs);
    }
    handleSegChange(event) {
        this.segValue = event.detail.value;
        this.segLabel = event.target.options.find(opt => opt.value === event.detail.value).label;
        console.log(event.detail.label, event.detail.value, JSON.parse(JSON.stringify(event.detail)));
    }
    handleEditSegChange(event) {
        console.log('EV');
        this.selectedSegOpValue = event.detail.value;
        if (this.selectedSegOpValue == 'Remove Segment') {
            var invRec = this.invoiceRecords.slice();
            var segNames = invRec[this.segNum].Proposal_Line_Items__r[this.segNum2].SegmentsName.split(',');
            var segOps = [];
            console.log('SeNames:', segNames);
            if (segNames != undefined) {
                for (var v of segNames) {
                    segOps.push({ label: v, value: v });
                }
            }
            this.segmentOptions = segOps;
            console.log('SOP:', this.segmentOptions);
        }
    }
    hideAddSegmentToIOInv(event) {
        try {
            console.log(this.segNum);
            var invRec = this.invoiceRecords.slice();
            var found = false;
            if (invRec[this.segNum].Proposal_Line_Items__r[this.segNum2].SegmentsName != 'No Segments') {
                var invSegs = invRec[this.segNum].Proposal_Line_Items__r[this.segNum2].SegmentsName.split(',');
                if (!invSegs.includes(this.segLabel)) {
                    invSegs.push(this.segLabel);
                    invRec[this.segNum].Proposal_Line_Items__r[this.segNum2].SegmentsName = invSegs.join();
                } else {
                    found = true;
                }
            } else {
                invRec[this.segNum].Proposal_Line_Items__r[this.segNum2].SegmentsName = this.segLabel;
            }
            if (!found) {
                if (invRec[this.segNum].Proposal_Line_Items__r[this.segNum2].newSegs == undefined) {
                    invRec[this.segNum].Proposal_Line_Items__r[this.segNum2].newSegs = {};
                }
                if (invRec[this.segNum].Proposal_Line_Items__r[this.segNum2].Id == undefined) {
                    invRec[this.segNum].Proposal_Line_Items__r[this.segNum2].newSegs[this.segValue] = invRec.length;
                } else {
                    invRec[this.segNum].Proposal_Line_Items__r[this.segNum2].newSegs[this.segValue] = invRec[this.segNum].Proposal_Line_Items__r[this.segNum2].Id;
                }
            }
            this.invoiceRecords = invRec;
            this.segLabel = '';
            this.segValue = '';
            this.showSeg = false;
            console.log(this.invoiceRecords);
        } catch (err) {
            console.log(err);
        }
    }
    handleEditSegChange(event) {

    }
    handleShowLItems2(event) {
        console.log(this.invoiceRecords);
        var invoiceLItems = this.invoiceRecords.slice();
        var idx = event.target.dataset.idx;
        console.log(idx, invoiceLItems[idx]);
        if (invoiceLItems[idx].showLItemsInside) invoiceLItems[idx].showLItemsInside = false;
        else
            invoiceLItems[idx].showLItemsInside = true;
        if (invoiceLItems[idx].iconName2 == 'utility:chevronright') {
            invoiceLItems[idx].iconName2 = 'utility:chevrondown';
        } else {
            invoiceLItems[idx].iconName2 = "utility:chevronright";
        }
        this.invoiceRecords = invoiceLItems;
    }
    handleShowLItems(event) {

        var invoiceLItems = this.invoiceRecords.slice();
        var idx = event.target.dataset.idx;
        if (invoiceLItems[idx].showLItems) invoiceLItems[idx].showLItems = false;
        else
            invoiceLItems[idx].showLItems = true;
        if (invoiceLItems[idx].iconName == 'utility:chevronright') {
            invoiceLItems[idx].iconName = 'utility:chevrondown';
        } else {
            invoiceLItems[idx].iconName = "utility:chevronright";
        }
        this.invoiceRecords = invoiceLItems;
    }
    handleAddFlights(event) {
        console.log(this.eDate);
        console.log('Added Flight', this.invoiceRecords, this.oppProducts);
        var pLItems = [];
        try {
            //var idx = event.target.dataset.idx;
            var i = 0;
            this.oppProducts.forEach(oppProd => {
                // console.log('-->',this.invoiceRecords[0].allItems);
                var newPItem = {
                    UnitPrice: oppProd.UnitPrice,
                    ProdName: oppProd.ProdName,
                    Counts__c: oppProd.Quantity,
                    CPM__c: oppProd.ListPrice,
                    Impression__c: oppProd.Impression__c,
                    QuoteId: this.recordId,
                    Quantity: 1,
                    PricebookEntryId: this.invoiceRecords[0].Proposal_Line_Items__r[0].PricebookEntryId,
                    Monthly_Frequency__c: 30,
                    Proposal_Invoice__c: this.invoiceRecords.length,
                    new: true,
                    Invoice__c: this.invoiceRecords.length,
                    Product__c: oppProd.Product2Id,
                    Product2Id: oppProd.Product2Id,
                    showAddNewSeg: false,
                    segmentIdMap: this.oppSegIdMap,
                    Id: this.invoiceRecords.length + ':' + i
                };
                pLItems.push(newPItem);
                i++;
            });
            console.log(pLItems);
            var showDel = false;
            if (pLItems.length > 1) {
                showDel = true;
            }
            var pId;
            var cName;
            var flight;
            var segName;
            if (this.objectApiName == 'Quote') {
                pId = this.recordId;
                // cName = this.invoiceRecords[0].Proposal__r.Campaign_Name__c;
                // flight = this.invoiceRecords[0].Proposal__r.Flight__c;
                // segName = this.invoiceRecords[0].Proposal__r.Opportunity.Segment_Name__c;
            } else {
                segName = this.invoiceRecords[0].IO__r.Opportunity__r.Segment_Name__c;
                cName = this.invoiceRecords[0].IO__r.Campaign_Name__c;
                flight = this.invoiceRecords[0].IO__r.Flight__c;
                pId = this.invoiceRecords[0].Proposal_Line_Items__r[0].Proposal__c;
            }

            this.eDate.setDate(this.eDate.getDate() + 1);
            var month = ("0" + (this.eDate.getUTCMonth() + 1)).slice(-2);
            var dat = ("0" + (this.eDate.getUTCDate())).slice(-2);
            var startDate1 = this.eDate.getUTCFullYear() + '-' + month + '-' + dat;
            console.log('SD1:', startDate1);
            var sDate = new Date(this.eDate);
            console.log('SDate:', sDate);
            sDate.setMonth(sDate.getMonth() + 1);
            sDate.setDate(sDate.getDate() - 1);
            console.log('sDate2:', sDate);
            month = ("0" + (sDate.getUTCMonth() + 1)).slice(-2);
            dat = ("0" + (sDate.getUTCDate())).slice(-2);
            var endDate1 = sDate.getUTCFullYear() + '-' + month + '-' + sDate.getUTCDate();
            console.log('eND:', endDate1);
            var newFlight = {
                End_Date__c: endDate1,
                Start_Date__c: startDate1,
                //  End_Date__c:'',
                //  Start_Date__c:'',
                CampName: cName,
                Client_Campaign_Name__c: '',
                Id: this.invoiceRecords.length,
                iconName: "utility:chevronright",
                iconName2: "utility:chevronright",
                Proposal__c: pId,
                showLItems: false,
                showLItemsInside: false,
                Flight: flight,
                Proposal_Line_Items__r: pLItems,
                showDelete: showDel,
                SegName: this.oppSegNames,
                IO__c: this.recordId
            };
            console.log('INVrecs:', this.invoiceRecords);
            var invRecs = this.invoiceRecords.slice();
            invRecs.push(newFlight);
            //invRecs[idx].search = true;
            this.invoiceRecords = invRecs;
            console.log('EE:', sDate);
            this.eDate = sDate;
            console.log(this.invoiceRecords);
        } catch (e) {
            console.log(e);
        }
    }
    handleAddCampaigns() {
        console.log(this.invoiceRecords);
        /* var invRecs = this.invoiceRecords.slice();
        var obj = {};
        for( var val in invRecs[0] ){
            obj[val] = invRecs[0][val];
        }
        obj['NewCamp'] = true;
        invRecs.push( obj );
        this.invoiceRecords = invRecs;
        console.log(this.invoiceRecords); */
        var invRecs = this.invoiceRecords.slice();
        var obj = { CampName: this.invoiceRecords[0].CampName, NewCamp: true, search: false, iconName: "utility:chevronright", showLItems: false, allItems: [] };
        invRecs.push(obj);
        this.invoiceRecords = invRecs;
    }
    handleCampDateChange(event) {
        var idx = event.target.dataset.idx;
        var label = event.target.dataset.label;
        var invRec = this.invoiceRecords.slice();
        if (label == 'Start') {
            invRec[idx].StartD = event.target.value;
        } else if (label == 'End') {
            invRec[idx].EndD = event.target.value;
        }
        this.invoiceRecords = invRec;
    }
    handleSearchCmp(event) {
        this.spin = true;
        console.log(this.invoiceRecords);
        var idx = event.target.dataset.idx;
        var sDate = this.invoiceRecords[idx].StartD;
        var eDate = this.invoiceRecords[idx].EndD;
        console.log(sDate, eDate);
        var campName;
        var flight;
        getContractInvoiceStartEnd({ contractId: this.recordId, sDate: sDate, eDate: eDate }).then(res => {
            console.log('StartEndRecs', res);
            if (res != undefined) {
                res.forEach(ele => {
                    ele.showLItems = false;
                    ele.iconName = "utility:chevronright";
                    console.log('IO:', ele.IO__r);
                    ele.CampName = ele.IO__r.Campaign_Name__c;
                    campName = ele.CampName;
                    ele.Flight = ele.IO__r.Flight__c;
                    flight = ele.Flight;
                    ele.SegName = ele.IO__r.Opportunity__r.Segment_Name__c;

                    if (ele.Invoice_Line_Items__r.length > 1) {
                        ele.showDelete = true;
                    } else {
                        ele.showDelete = false;
                    }
                    if (ele.Invoice_Line_Items__r != undefined) {
                        ele.Invoice_Line_Items__r.forEach(e => {
                            e.ProdName = e.Product__r.Name;
                            e.UnitPrice = e.Sales_Price__c;
                            e.showDropdown = false;
                            e.new = true;
                        });
                        ele.Proposal_Line_Items__r = ele.Invoice_Line_Items__r;
                    }
                });
            }
            var invRec = this.invoiceRecords;
            invRec[idx].allItems = res;
            invRec[idx].search = true;
            this.invoiceRecords = invRec;
            console.log('MOD:', this.invoiceRecords);
            this.spin = false;
            // this.invoiceRecords = res; 
        }).catch(err => {
            this.spin = false;
            console.log(err);
        });
    }
    handleValueChange(event) {
        try {
            console.log('in handleValueChange');
            var invRecs = this.invoiceRecords.slice();
            var idx = event.target.dataset.idx;
            var inv = invRecs[idx];
            var field = event.target.dataset.field;
            if (field != 'Start_Date__c' && field != 'End_Date__c' && field != 'Client_Campaign_Name__c') {
                var idx2 = event.target.dataset.idx2;
                var lItem = inv.Proposal_Line_Items__r[idx2];
                lItem[field] = event.target.value;
                if (field == 'UnitPrice' || field == 'CPM__c') {
                    lItem['Impression__c'] = ((lItem.UnitPrice / lItem.CPM__c) * 1000).toFixed(2);
                }
            } else {
                inv[field] = event.target.value;
            }
            this.invoiceRecords = invRecs;
        } catch (e) {
            console.log(e);
        }
    }
    showToastMess(message, variant, title) {
        this.spin = false;
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
    handleSave() {
        console.log(this.invoiceRecords);
        console.log(this.selectedIds.toString(), this.selectedRecords);
        var invRecs = [];
        var lItemRec = [];
        this.spin = true;
        if (this.objectApiName == 'Quote') {
            this.invoiceRecords.forEach(invRec => {
                invRec.Proposal_Line_Items__r.forEach(lItem => {
                    lItemRec.push(lItem);
                });
            });
            console.log('INV:', this.invoiceRecords);
            saveInvoice({ invRecs: this.invoiceRecords, lItemRecs: lItemRec, delRecsIds: this.delRecs }).then(res => {
                if (res == 'Success') {
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: this.recordId,
                            //objectApiName: 'Case', // objectApiName is optional
                            actionName: 'view'
                        }
                    });
                    this.spin = false;
                } else {
                    this.spin = false;
                }
            }).catch(err => {
                console.log(err);
            });
        } else if (this.objectApiName == 'Contract') {
            var newSegments = [];
            this.invoiceRecords.forEach(invRec => {
                invRec.Invoice_Line_Items__r = invRec.Proposal_Line_Items__r;
                invRec.Proposal_Line_Items__r.forEach(lItem => {
                    lItem.Sales_Price__c = lItem.UnitPrice;
                    lItemRec.push(lItem);
                });
                if (invRec.newSegs != undefined) {
                    for (var v in invRec.newSegs) {
                        var obj = { Segment__c: v, IO_Invoice__c: invRec.newSegs[v] };
                        newSegments.push(obj);
                    }
                }
            });
            try {
                console.log('NN:', JSON.stringify(newSegments));

                this.invoiceRecords.forEach(inv => {
                    if (inv.newSegs != undefined) {
                        delete inv.newSegs;
                    }
                });
                var nSegN = [];
                console.log('11:', this.newSegmentRecords);
                for (var v in this.newSegmentRecords) {
                    console.log(this.newSegmentRecords[v]);
                    if (this.newSegmentRecords[v] != undefined) {
                        if (this.newSegmentRecords[v][0] != undefined) {
                            console.log('len', this.newSegmentRecords[v][0].IO_Invoice_Line_Item__c + ''.length);
                            if (this.newSegmentRecords[v][0].IO_Invoice_Line_Item__c + ''.length < 10) {
                                nSegN.push(v);
                            }
                        }
                    }
                }
                console.log('-->', nSegN);
                console.log('//->', this.delRecs);
                this.delRecs = this.delRecs.filter((item) => item.length > 10);
                console.log(this.delRecs);
                saveIOInvoice({ invRecs: this.invoiceRecords, lItemRecs: lItemRec, delRecsIds: this.delRecs, newSegs: newSegments, nProdSeg: nSegN }).then(res => {
                    console.log(res);
                    for (var val in res) {
                        if (this.newSegmentRecords[val] != undefined) {
                            var arr = this.newSegmentRecords[val];
                            for (var v of arr) {
                                v.IO_Invoice_Line_Item__c = res[val];
                            }
                        }
                    }
                    createNewSegments({ newSegs: JSON.stringify(this.newSegmentRecords) }).then(res2 => {
                        this[NavigationMixin.Navigate]({
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: this.recordId,
                                //objectApiName: 'Case', // objectApiName is optional
                                actionName: 'view'
                            }
                        });
                        this.spin = false;
                    }).catch(err => {
                        console.log(err);
                        this.showToastMess(err.body.message, 'Error', 'Error');
                    });
                }).catch(err => {
                    console.log(err);
                    this.showToastMess(err.body.message, 'Error', 'Error');
                });
            } catch (err) {
                console.log(err);
                this.showToastMess(err.body.message, 'Error', 'Error');
            }
        }
    }
    handleAddProducts(event) {
        try {
            var idx = event.target.dataset.idx;
            console.log('Adding prods', idx);
            console.log(this.invoiceRecords[idx]);
            console.log(this.invoiceRecords[idx].Proposal_Line_Items__r);
            if (this.invoiceRecords[idx].Proposal_Line_Items__r == undefined) {
                this.invoiceRecords[idx].Proposal_Line_Items__r = [];
            }
            var newPItem = {
                UnitPrice: 0,
                ProdName: '',
                Counts__c: 0,
                Id: idx + ':' + this.invoiceRecords[idx].Proposal_Line_Items__r.length,
                CPM__c: 0,
                Impression__c: 0,
                QuoteId: this.recordId,
                Quantity: 1,
                PricebookEntryId: this.invoiceRecords[idx].Proposal_Line_Items__r[0].PricebookEntryId,
                Monthly_Frequency__c: 30,
                Proposal_Invoice__c: this.invoiceRecords[idx].Id,
                new: true,
                Invoice__c: this.invoiceRecords[idx].Id,
                showAddNewSeg: false,
                segmentIdMap: this.oppSegIdMap
            };
            var invRec = this.invoiceRecords.slice();
            invRec[idx].Proposal_Line_Items__r.push(newPItem);
            if (invRec[idx].Proposal_Line_Items__r.length > 1) {
                invRec[idx].showDelete = true;
            } else {
                invRec[idx].showDelete = false;
            }
            this.invoiceRecords = invRec;
            console.log('INVREC:::', this.invoiceRecords);
        } catch (err) {
            console.log(err);
        }
    }
    handleGetProds() {
        getProducts({ quoteId: this.recordId }).then(res2 => {
            var p = [];
            res2 = JSON.parse(JSON.stringify(res2));
            var cBoxOp = [];
            res2.forEach(prod => {
                cBoxOp.push({ label: prod.Name, value: prod.Id });
            });
            //For Combobox
            this.options = cBoxOp;
            this.optionData = this.options;
            console.log(this.optionData);
            /* var optionData = this.options ? (JSON.parse(JSON.stringify(this.options))) : null;
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
            this.optionData = optionData; */
        }).catch(err => {
            console.log(err);
        });
    }
    handleRemoveProducts(event) {
            var idx = event.currentTarget.dataset.idx;
            var idx2 = event.currentTarget.dataset.idx2;
            var invoiceLItems = this.invoiceRecords.slice();
            if (invoiceLItems[idx].Proposal_Line_Items__r.length < 2) {
                invoiceLItems[idx].showDelete = false;
            } else {
                try {
                    console.log('->', invoiceLItems[idx].Proposal_Line_Items__r[idx2].Id);
                    var idd = invoiceLItems[idx].Proposal_Line_Items__r[idx2].Id;
                    this.delRecs.push(idd);
                    invoiceLItems[idx].Proposal_Line_Items__r.splice(idx2, 1);
                    if (invoiceLItems[idx].Proposal_Line_Items__r.length < 2) {
                        invoiceLItems[idx].showDelete = false;
                    }
                    console.log('::', invoiceLItems);
                } catch (err) {
                    console.log(err);
                }
            }
            this.invoiceRecords = invoiceLItems;
        }
        //Combobox
    filterOptions(event) {
        try {
            this.searchString = event.target.value;
            var idx = event.target.dataset.idx;
            var idx2 = event.target.dataset.idx2;
            var oppP = [];
            for (var val of this.invoiceRecords) {
                val.Proposal_Line_Items__r.forEach(re => {
                    re.showDropdown = false;
                });
                oppP.push(val);
            }
            if (this.searchString && this.searchString.length > 0) {
                this.message = '';
                if (this.searchString.length >= this.minChar) {
                    var flag = true;
                    for (var i = 0; i < this.optionData.length; i++) {
                        if (this.optionData[i].label.toLowerCase().trim().startsWith(this.searchString.toLowerCase().trim())) {
                            this.optionData[i].isVisible = true;
                            flag = false;
                        } else {
                            this.optionData[i].isVisible = false;
                        }
                    }
                    if (flag) {
                        this.message = "No results found for '" + this.searchString + "'";
                    }
                }
                oppP[idx].Proposal_Line_Items__r[idx2].showDropdown = true;
                this.invoiceRecords = oppP;
                this.showDropdown = true;
                console.log('All:', this.invoiceRecords);
            } else {
                this.invoiceRecords = oppP;
                console.log('All12:', this.invoiceRecords);

            }
        } catch (err) {
            console.log(err);
        }

    }

    selectItem(event) {
        var selectedVal = event.currentTarget.dataset.id;
        var slectedPName = event.currentTarget.dataset.pname;
        var idx = event.currentTarget.dataset.idx;
        var idx2 = event.currentTarget.dataset.idx2;
        var oppP = [];
        for (var val of this.invoiceRecords) {
            val.Proposal_Line_Items__r.forEach(re => {
                re.showDropdown = false;
            });
            oppP.push(val);
        }
        if (selectedVal) {
            var options = JSON.parse(JSON.stringify(this.optionData));
            this.optionData = options;

            oppP[idx].Proposal_Line_Items__r[idx2].showDropdown = false;
            oppP[idx].Proposal_Line_Items__r[idx2].ProdName = slectedPName;
            oppP[idx].Proposal_Line_Items__r[idx2].Product2Id = selectedVal;
            oppP[idx].Proposal_Line_Items__r[idx2].Product__c = selectedVal;
            this.invoiceRecords = oppP;
            console.log(this.invoiceRecords);
            this.showDropdown = false;
        }
    }

    showOptions(event) {
        var idx = event.target.dataset.idx;
        var idx2 = event.target.dataset.idx2;
        var oppP = [];
        console.log('idx:', idx);
        console.log(this.optionData);
        for (var val of this.invoiceRecords) {
            val.Proposal_Line_Items__r.forEach(re => {
                re.showDropdown = false;
            });
            oppP.push(val);
        }
        this.message = '';
        this.searchString = '';
        var options = JSON.parse(JSON.stringify(this.optionData));
        for (var i = 0; i < options.length; i++) {
            options[i].isVisible = true;
        }
        if (options.length > 0) {
            var out = oppP[idx];
            console.log(out);
            out.Proposal_Line_Items__r[idx2].showDropdown = true;
            this.invoiceRecords = oppP;
        }
        this.optionData = options;
        console.log('Click');
    }

    removePill(event) {
        var value = event.currentTarget.name;
        var count = 0;
        var options = JSON.parse(JSON.stringify(this.optionData));
        for (var i = 0; i < options.length; i++) {
            if (options[i].value === value) {
                options[i].selected = false;
                this.values.splice(this.values.indexOf(options[i].value), 1);
            }
            if (options[i].selected) {
                count++;
            }
        }
        this.optionData = options;
        if (this.multiSelect)
            this.searchString = count + ' Option(s) Selected';
    }

    blurEvent(event) {
        try {
            var idx = event.target.dataset.idx;
            var idx2 = event.target.dataset.idx2;
            var oppP = [];
            for (var val of this.invoiceRecords) {
                val.Proposal_Line_Items__r.forEach(re => {
                    re.showDropdown = false;
                });
                oppP.push(val);
            }
            /* var previousLabel;
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
            */
            oppP[idx].Proposal_Line_Items__r[idx2].showDropdown = false;
            this.invoiceRecords = oppP;
            this.showDropdown = false;
            console.log('Blur Event');
        } catch (err) {
            console.log(err);
        }

        /* this.dispatchEvent(new CustomEvent('select', {
            detail: {
                'payloadType' : 'multi-select',
                'payload' : {
                    'value' : this.value,
                    'values' : this.values
                }
            }
        })); */
    }


    //For multiple lookup



    searchField(event) {
        try {
            var invRec1 = this.invoiceRecords.slice();
            var currentText = event.target.value;
            var idx = event.target.dataset.idx1;
            var invRec = invRec1[idx];
            var selectRecId = [];
            invRec.searchVal = currentText;
            if (invRec.selectedRecords == undefined) invRec.selectedRecords = [];
            for (let i = 0; i < invRec.selectedRecords.length; i++) {
                selectRecId.push(invRec.selectedRecords[i].recId);
            }
            invRec.LoadingText = true;
            console.log('SELID:', this.selectedIds);
            getSegments({ value: currentText, selectedRecId: this.selectedIds })
                .then(result => {
                    console.log('RESS:', result);
                    invRec.searchRecords = result;
                    invRec.LoadingText = false;

                    //
                    invRec.dynamiClassname = result.length > 0 ? 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open' : 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
                    if (currentText.length > 0 && result.length == 0) {
                        invRec.messageFlag = true;
                    } else {
                        invRec.messageFlag = false;
                    }

                    if (invRec.selectRecordId != null && invRec.selectRecordId.length > 0) {
                        invRec.iconFlag = false;
                        invRec.clearIconFlag = true;
                    } else {
                        invRec.iconFlag = true;
                        invRec.clearIconFlag = false;
                    }
                    this.invoiceRecords = invRec1;
                    console.log('IV:', this.invoiceRecords);
                })
                .catch(error => {
                    console.log('-------error-------------' + error);
                    console.log(error);
                });
        } catch (err) {
            console.log(err);
        }
    }

    setSelectedRecord(event) {
        try {
            var invRec1 = this.invoiceRecords.slice();
            var idx = event.currentTarget.dataset.idx;
            console.log(idx);
            var invRec = invRec1[idx];
            var recId = event.currentTarget.dataset.id;
            var selectName = event.currentTarget.dataset.name;
            console.log(recId);
            //console.log(selectName);
            let newsObject = { 'recId': recId, 'recName': selectName };
            if (invRec.selectedIds == undefined) invRec.selectedIds = [];
            if (invRec.selectedRecords == undefined) invRec.selectedRecords = [];
            invRec.selectedIds.push(recId);
            invRec.selectedRecords.push(newsObject);
            console.log('SelIds:', invRec.selectedIds);
            invRec.dynamiClassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
            //let selRecords = this.selectedRecords;
            /* this.template.querySelectorAll('lightning-input').forEach(each => {
                each.value = '';
            }); */
            invRec.searchVal = '';
            this.invoiceRecords = invRec1;
            console.log('event dispatch', this.invoiceRecords);
            //console.log(this.selectedIds);
            let ids = invRec.selectedIds.toString();
            console.log(ids);
            const selectedEvent = new CustomEvent("userselected", {
                detail: this.selectedRecords
            });
            // Dispatches the event.
            this.dispatchEvent(selectedEvent);
            if (this.singleSelection) {
                this.disableInputField = true;
            }
        } catch (err) {
            console.log(err);
        }

    }

    removeRecord(event) {
        let selectRecId = [];
        let selectedIds1 = [];
        var invRec1 = this.invoiceRecords.slice();
        var idx = event.target.dataset.idx;
        var invRec = invRec1[idx];
        for (let i = 0; i < invRec.selectedRecords.length; i++) {
            if (event.detail.name !== invRec.selectedRecords[i].recId) {
                selectRecId.push(invRec.selectedRecords[i]);
                selectedIds1.push(invRec.selectedRecords[i].recId)
            }
        }
        invRec.selectedRecords = [...selectRecId];
        invRec.selectedIds = [...selectedIds1];
        let selRecords = invRec.selectedRecords;

        this.invoiceRecords = invRec1;
        let ids = invRec.selectedIds.toString();
        /* if(this.singleSelection && selectRecId.length <=0){
            this.disableInputField = false;
        } */
        const selectedEvent = new CustomEvent('userselected', {
            detail: this.selectedRecords
        });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }
}