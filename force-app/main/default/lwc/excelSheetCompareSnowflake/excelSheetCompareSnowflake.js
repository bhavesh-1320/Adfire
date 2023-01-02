/*
 * Copyright (c) 2020, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

/* eslint-disable no-console */
/* eslint no-unused-vars: ["error", { "argsIgnorePattern": "^_" }] */

import { LightningElement, track, api } from 'lwc';
import { createRecord, updateRecord } from 'lightning/uiRecordApi';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { readAsBinaryString } from './readFile';
import SHEETJS_ZIP from '@salesforce/resourceUrl/sheetjs'
import getMatchNPILeads from '@salesforce/apex/SnowflakeAccessToken.getMatchNPILeads';
export default class ExcelSheetCompareSnowflake extends LightningElement {    
    // Id of currently displayed record (component is only for display on record pages)
    @api recordId;  
    @api objectApiName;

    // Title and Label displayed in UI
    @api title;
    @api label;

    // Configuration of record fields and the corresponding Excel cell adresses
    // up to 10 fields are supported; fields may be left blank
    @api field1;
    @api address1;
    @api field2;
    @api address2;
    @api field3;
    @api address3;
    @api field4;
    @api address4;
    @api field5;
    @api address5;            
    @api field6;
    @api address6;
    @api field7;
    @api address7;        
    @api field8;
    @api address8;
    @api field9;
    @api address9;
    @api field10;
    @api address10;

    fileName;
    columns=[];
    data=[];
    showTable = false;
    npiInSF = [];
    sfIDS = [];
    colInc = false;
    leadIdNameMap ={};
    // state management to display spinners and the modal used while uploading the component
    @track ready = false;
    @track error = false;    

    @track uploading = false;
    @track uploadStep = 0;
    @track uploadMessage = '';
    @track uploadDone = false;
    @track uploadError = false;

    loading = false;
    hrefdata;
    constructor() {
        super();

        loadScript(this, SHEETJS_ZIP)
        .then(() => {
            if(!window.XLSX) {
                throw new Error('Error loading SheetJS library (XLSX undefined)');                
            }
            this.ready = true;
        })
        .catch(error => {
            this.error = error;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Excel Upload: Error loading SheetJS',
                    message: error.message,
                    variant: 'error'
                })
            );
        });
    }

    // The promise chain for upload a new file will
    // 1. read the file, 2. parse it and extract the Excel cells and 
    // update the record, 3. upload the file to the record as "attachment"
    // (ContentVersion to be more precise), and 4. shortly wait to display
    // the modal before letting it disappear
    uploadFile(evt) {
        this.npiInSF = [];
        const recordId = this.recordId;               
        let file;
        
        Promise.resolve(evt.target.files)        
        .then( files => {
            this.uploading = true;
            this.uploadStep = "1";
            this.uploadMessage = 'Reading File';
            this.uploadDone = false;
            this.uploadError = false;

            if(files.length !== 1) {
                throw new Error("Error accessing file -- " + 
                    (files.length === 0 ? 
                        'No file received' : 
                        'Multiple files received'
                    ));
            }        
 
            file = files[0];
            return readAsBinaryString(file);
        })                
        .then( blob => {
            this.uploadStep = "2";
            this.uploadMessage = 'Extracting Data';

            let workbook = window.XLSX.read(blob, {type: 'binary'});    

            if(!workbook || !workbook.Workbook) { throw new Error("Cannot read Excel File (incorrect file format?)"); }
            if(workbook.SheetNames.length < 1) { throw new Error("Excel file does not contain any sheets"); }            
            console.log('Content->',workbook.Workbook);
            const record = {
                Id: recordId
            };
            console.log('OutLop');
            let sheetName = workbook.SheetNames[0];                    
            let sheet = workbook.Sheets[sheetName];
            var ref = sheet['!ref'];
            console.log('rr:',ref);
            var lst = parseInt(ref.substring( ref.length-2 ));
            console.log(lst);
            var ids = '(';
            var arr = [];
            for(let i=2; i<=lst; i++) {
                // console.log('INSLOOP');
                const field = "field"+i;
                let address = "A"+i;

                if(field && field !== 'NONE') {
                    /* let sheetName = workbook.SheetNames[0];                    
                    let sheet = workbook.Sheets[sheetName];
                     */
                    console.log('-----');
                    let cell = sheet[address];
                    console.log(sheet, address);
                    if(!cell) {
                        throw new Error(`Cell with address ${address} not found for Excel Address ${i} (value: '${this["address"+i]}')`);
                    }
                    arr.push( cell.v.toString() );
                    console.log('a:::',arr);
                    if( i == 2 )    ids+= cell.v;
                    else    ids+= ','+cell.v;
                    record[field] = cell.v;
                }
            }
            console.log('::::::::::::',arr);
            this.npiInSF = arr;
            console.log('---->>',this.npiInSF);
            ids+=')';
            this.getRecsFromSnowFlake( ids );
            console.log('Cont--->', record);
            console.log(ids);
            console.log('SS:',this.npiInSF);
            this.uploadStep = "3";
            this.uploadMessage = 'Updating Record';

            //return updateRecord({fields: record}).then( () => blob );                        
        })
        .then( blob => {            
            this.uploadStep = "4";
            this.uploadMessage = 'Uploading File';

            const cv = {
                Title: file.name,
                PathOnClient: file.name,
                VersionData: window.btoa(blob),          
                FirstPublishLocationId: recordId
            };
            this.fileName = file.name;
            //return createRecord({apiName: "ContentVersion", fields: cv})     
        })
        .then( _cv => {
            // Unfortunately, the last step won't get a check mark -- 
            // the base component <lightning-progress-indicator> is missing this functionality        
            this.uploadMessage = "Done";  
            this.uploadDone = true;       
            return new Promise(function(resolve, _reject){ 
                // eslint-disable-next-line @lwc/lwc/no-async-operation
                window.setTimeout(resolve, 1000); 
            });             
        })
        .then( () => {
            this.closeModal();

            /* this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Excel Upload: Success',
                    message: 'Current record has been updated successfully and the Excel file uploaded',
                    variant: 'success'
                })
            );        */      
        })
        .catch( err => {
            this.uploadError = true;
            this.uploadMessage = "Error: " + err.message;
        });
    }
    getRecsFromSnowFlake( ids ){
        console.log(ids);
        this.loading = true;
        try{
            getMatchNPILeads({ids : ids, colInclude: this.colInc}).then( res=>{
                if( res!= undefined ){
                    var result = JSON.parse(res);
                    console.log(result.resultSetMetaData);
                    console.log(result);
                    var cols = [];
                    var colNameMap = {};
                    var i = 0;
                    try{
                        for( var row of result.resultSetMetaData.rowType ){
                            cols.push( {label : row.name, fieldName:row.name} );
                            colNameMap[i] = row.name;
                            i++;
                        }
                        this.columns = cols;
                        var datas = [];
                        console.log('DVAL',colNameMap[1], colNameMap);
                        for( var d of result.data ){
                            var obj = {};
                            var ij = 0;
                            for( var j = 0; j<d.length; j++ ){
                                obj[colNameMap[j]] = d[ij];
                                this.sfIDS.push( d[ij] );
                                ij++;
                            }
                            datas.push( obj );
                        }
                        console.log('DATASS:', datas);
                        var sampleData = [];
                        for( var v of datas ){
                            this.leadIdNameMap[v.LEADID] = v.FIRSTNAME; 
                            sampleData.push(v);
                        }
                        this.data = sampleData;
                        this.showTable = true;
                        this.loading = false; 
                        /*
                        this.spin = false;
                        this.totalRecs = this.sampleData.length;
                        if( this.totalRecs > 0 ){
                            this.sfDataShow = true;
                        }else{
                            this.sfDataShow = false;
                        }
                        this.fillHalfData( 25 );
                        this.totalPage = Math.ceil(this.totalRecs/this.recPerPage);
                        if( this.totalPage == 1 ){
                            this.disableNext = true;
                        }
                        this.showRecords = true; */
                        console.log('npiInSF:',this.npiInSF);
                    }catch( err ){
                        this.loading=false;
                        this.showRecords = true;
                        this.sfDataShow = false;
                        console.log(err);
                    }
                }
            });
        }catch( err){
            console.log(err);
        }
    }
    handleCheckbox(){
        if( this.colInc ){
            this.colInc = false;
        }else{
            this.colInc = true;
        }
    }
    exportToCSV() {  
        var columnHeader=[];
        var jsonKeys=[];
        console.log(this.leadIdNameMap);
        /* for( var v of this.columns ){
            columnHeader.push( v.label );
            jsonKeys.push( v.fieldName );
        } */
        columnHeader.push( 'LEADID' );
        columnHeader.push( 'MATCHED' );
        // columnHeader.push( 'Matched' );
        jsonKeys.push( 'LEADID' );
        jsonKeys.push( 'MATCHED' );
        if( this.colInc ){
            columnHeader.push( 'FIRSTNAME' );
            jsonKeys.push( 'FIRSTNAME' );
        }
        // console.log(jsonKeys);
        console.log(columnHeader);
        // let columnHeader = ["Item Number", "Name"];  // This array holds the Column headers to be displayd
        // let jsonKeys = ["itemn", "name"]; // This array holds the keys in the json data 
        var csvContent = []; 
        for( var val of this.npiInSF ){
            var obj = {};
            if( this.sfIDS.includes( val ) ){
                obj.MATCHED = 'X';
            }else{
                obj.MATCHED = '';
            }
            obj.LEADID = val;
            obj.FIRSTNAME = this.leadIdNameMap[val];
            csvContent.push( obj );
        }
        console.log(csvContent);
        console.log('----------------->',this.npiInSF, this.sfIDS);
        var jsonRecordsData = csvContent;
        let csvIterativeData;  
        let csvSeperator  
        let newLineCharacter;  
        csvSeperator = ",";  
        newLineCharacter = "\n";  
        csvIterativeData = "";  
        csvIterativeData += columnHeader.join(csvSeperator);  
        csvIterativeData += newLineCharacter;  
        for (let i = 0; i < jsonRecordsData.length; i++) {  
          let counter = 0;  
          for (let iteratorObj in jsonKeys) {  
            let dataKey = jsonKeys[iteratorObj];  
            if (counter > 0) {  csvIterativeData += csvSeperator;  }  
            if (  jsonRecordsData[i][dataKey] !== null &&  
              jsonRecordsData[i][dataKey] !== undefined  
            ) {  csvIterativeData += '"' + jsonRecordsData[i][dataKey] + '"';  
            } else {  csvIterativeData += '""';  
            }  
            counter++;  
          }  
          csvIterativeData += newLineCharacter;  
        }  
        console.log("csvIterativeData", csvIterativeData);  
        console.log(encodeURI(csvIterativeData));
        this.hrefdata = "data:application/vnd.ms-excel," + encodeURI(csvIterativeData);  
    }
    closeModal() {
        this.uploading = false;
        this.uploadStep = 0;
        this.uploadMessage = '';
        this.uploadDone = false;
        this.uploadError = false;       
    }
}