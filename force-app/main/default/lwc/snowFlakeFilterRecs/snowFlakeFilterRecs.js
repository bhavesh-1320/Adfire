import { LightningElement, wire } from 'lwc';

import { getPicklistValues } from 'lightning/uiObjectInfoApi'; 
import Opportunity_OBJECT from '@salesforce/schema/Opportunity';
import pTypeField from '@salesforce/schema/Opportunity.Product_Type__c';
import lTypeField from '@salesforce/schema/Opportunity.License_Type__c';
import sField from '@salesforce/schema/Opportunity.Speciality__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import getLeadFromSnowflake from '@salesforce/apex/SnowflakeAccessToken.getLeadFromSnowflake';
import getLicenseType from '@salesforce/apex/SnowflakeAccessToken.getLicenseType';
import getAllInfo from '@salesforce/apex/SnowflakeAccessToken.getAllInfo';
import getLeadsCount from '@salesforce/apex/SnowflakeAccessToken.getLeadsCount';
import { getRelatedListCount } from 'lightning/uiRelatedListApi';
export default class SnowFlakeFilterRecs extends LightningElement {
    sampleData=[];
    sfDataShow = false;
    
    usePAreaValue = 'As a Filter';
    minMilesValue = 'Minutes';
    showRecords = false;
    limit = 1000;
    lTypeOptions;
    practiceAreasOptions;
    allOPInfo;
    settingsOptions;
    npiOptions;
    stateOptions;
    countyOptions;
    countyStateMap;

    selectedLoc;
    selectedMinMile;
    selectedStartMin;
    selectedEndMin;
    selectedMinYear;
    selectedMaxYear;
    selectedZipCode;
    selectedAdd;
    selectedSetting;
    selectedNpi;
    selectedState;
    practiceArea;    
    lType;
    selectedCunty;

    get minMilesOptions(){
        return [
            {label:'Minutes', value:'Minutes'},
            {label:'Miles', value:'Miles'}
        ];
    }
    get addresses(){
        return [
            {
                value: "residentialOnly",
                label: "Residential Address Only"
            },
            {
                value: "commercialOnly",
                label: "Commercial Address Only"
            },
            {
                value: null,
                label: "Both"
            }              
        ];
    }
    get usePAreaOptions(){
        return [
            {label:'As a Filter', value:'As a Filter'},
            {label:'Separate rows', value:'Separate rows'}
        ];
    }
    columns=[
        {label:'Practice Area', fieldName:'pArea'},
        {label:'Email', fieldName:'Email'},
        {label:'Mail', fieldName:'Mail'}
        ];
    data=[];
    hrefdata;
    nRecs = '25 Records Per Page';
    recPerPage = 25;
    totalRecs;
    halfData=[];
    currentPage = 1;
    disablePrevious=true;
    totalPage;
    disableNext=false;
    start = 0;
    end = 25;
    spin = false;
    get options() {
        return [
            { label: '25 Records Per Page', value: '25 Records Per Page' },
            { label: '50 Records Per Page', value: '50 Records Per Page' },
            { label: '100 Records Per Page', value: '100 Records Per Page' },
        ];
    }
    @wire(getObjectInfo, { objectApiName: Opportunity_OBJECT })
 
    opportunityMetadata;
 
    // now retriving the StageName picklist values of Opportunity
 
    @wire(getPicklistValues,
 
        {
 
            recordTypeId: '$opportunityMetadata.data.defaultRecordTypeId', 
 
            fieldApiName: pTypeField
 
        }
 
    )
 
    OpportunityPicklist;

    @wire(getPicklistValues,
 
        {
 
            recordTypeId: '$opportunityMetadata.data.defaultRecordTypeId', 
 
            fieldApiName: lTypeField
 
        }
 
    )
 
    OpportunityPicklistLType;


    @wire(getPicklistValues,
 
        {
 
            recordTypeId: '$opportunityMetadata.data.defaultRecordTypeId', 
 
            fieldApiName: sField
 
        }
 
    )
    OpportunityPicklistS;


    nextHandler(){
        console.log('Start1:',this.start);
        console.log('End1:', this.end);
        if( this.currentPage < this.totalPage ){
            this.start = this.end;
            this.end += this.recPerPage;
            this.fillHalfData( this.end ); 
            this.disablePrevious = false;
            this.currentPage++;
        }
        if( this.currentPage == this.totalPage ){
            this.disableNext = true;
        }
        console.log('Start2:',this.start);
        console.log('End2:', this.end);
    }
    previousHandler(){
        console.log('Start1:',this.start);
        console.log('End1:', this.end);
        if( this.currentPage > 1 ){
            this.start = this.end - (2*this.recPerPage);
            this.end -= this.recPerPage;
            this.fillHalfData( this.end ); 
            this.disableNext = false;
            this.currentPage--;
        }
        if( this.currentPage == 1 ){
            this.disablePrevious = true;
        }
        console.log('Start2:',this.start);
        console.log('End2:', this.end);
    }
    connectedCallback(){
        this.spin = true;
        getLicenseType().then( res=>{
            console.log( 'PAreas:',res );
            var arr = [];
            for( var val in res ){
                var obj = { label:res[val], value:val.toLocaleLowerCase() };
                arr.push( obj );
            }
            this.lTypeOptions = arr;
        } ).catch( err=>{
            console.log( err );
        } );
        getAllInfo().then( res=>{
            var jsonRes = JSON.parse(  res );
            var obj = {};
            console.log('JR:',jsonRes);
            for( var val of jsonRes ){
                console.log(val);
                var j = JSON.parse( JSON.stringify( val ) );
                obj[j.licenseType] = j;
            }
            this.allOPInfo = obj;
            console.log( 'All:',this.allOPInfo );
            this.spin = false;
        } );
        /* var ch = 65;
        for( var i = 1; i<=200; i++ ){
            var obj = {};
            obj['itemn'] = i;
            obj['name'] = String.fromCharCode(ch);
            if( String.fromCharCode(ch) == 'Z' ){
                ch=64;
            }
            ch++;
            this.sampleData.push(obj);
        }
        this.totalRecs = this.sampleData.length;
        this.fillHalfData( 25 );
        this.totalPage = this.totalRecs/this.recPerPage; */
    }
    handleComboChange( event ){
        try{
            var op = event.target.dataset.op;
            console.log('e:',event);
            var value; 
            if( event.detail != undefined ){
                value = event.detail.value;
            }
            if( op == 'LType' ){
                this.lType = value;
                var practiceA = this.allOPInfo[this.lType].practiceAreas;
                var arr = [{label:'None', value:'None'}];
                for( var val of practiceA ){
                    var obj = { label:val, value:val };
                    arr.push( obj );
                }
                this.practiceAreasOptions = arr;

                var settingsA = this.allOPInfo[this.lType].settings;
                var arr2 = [{label:'None', value:'None'}];
                for( var val of settingsA ){
                    var obj = { label:val, value:val };
                    arr2.push( obj );
                }
                this.settingsOptions = arr2;

                var npiTax = this.allOPInfo[this.lType].originalPracticeAreas;
                var arr3 = [{label:'None', value:'None'}];
                for( var val of npiTax ){
                    var obj = { label:val, value:val };
                    arr3.push( obj );
                }
                this.npiOptions = arr3;

                var cState = this.allOPInfo[this.lType].stateAndCounties;
                var arr4 = [{label:'None', value:'None'}];
                var cSMap = {};
                for( var val of cState ){
                    var obj = { label:val.name, value:val.name };
                    arr4.push( obj );
                    cSMap[val.name] = val.counties;
                }
                this.countyStateMap = cSMap;
                this.stateOptions = arr4;
            }else if( op == 'PArea' ){
                this.practiceArea = value;
            }else if( op == 'Address' ){
                this.selectedAdd = value;
            }else if( op == 'Settings' ){
                this.selectedSetting = value;
            }else if( op == 'npi' ){
                this.selectedNpi = value;
            }else if( op == 'State' ){
                this.selectedState = value;
                
                var arr4 = [];
                for( var val of this.countyStateMap[this.selectedState] ){
                    var obj = { label:val, value:val };
                    arr4.push( obj );
                }
                this.countyOptions = arr4;
            }else if( op == 'County' ){
                this.selectedCounty = value;
            }else if( op == 'Location' ){
                this.selectedLoc = value;
            }else if( op == 'MinMile' ){
                this.selectedMinMile = value;
            }else if( op == 'StartMin' ){
                this.selectedStartMin = value;
            }else if( op == 'EndMin' ){
                this.selectedEndMin = value;
            }else if( op == 'ZipCode' ){
                this.selectedZipCode = value;
            }else if( op == 'MaxYear' ){
                this.selectedMaxYear = value;
            }else if( op == 'MinYear' ){
                this.selectedMinYear = value;
            }else if( op == 'MinMileRad' ){
                this.minMilesValue = value;
            }      
        }catch( err ){
            console.log(err);
        }
    }
    handleBlur( event ){
        if( event.target.dataset.op == 'StartMin' ){
            if( this.minMilesValue == 'Minutes' ){
                this.selectedStartMin = Math.ceil(this.selectedStartMin / 10) * 10;
            }
        }else if( event.target.dataset.op == 'EndMin' ){
            console.log('EdMin:', this.minMilesValue, this.selectedEndMin );
            if( this.minMilesValue == 'Minutes' ){
                console.log(this.selectedEndMin);
                this.selectedEndMin = Math.ceil(this.selectedEndMin / 10) * 10;
            }
        } 
    }
    fillHalfData( n ){
        this.data = [];
        var d = [];
        for( var i = this.start; i<this.sampleData.length; i++ ){
            if( i >= n ){
                break;
            }
            d.push( this.sampleData[i] );
        }
        this.data = d;
        console.log('Sam:',this.sampleData);
        console.log('Sam:',this.data);
    }
    handleRecsChange( event ){
        this.spin = true;
        console.log('Start:',this.start);
        console.log('End:', this.end);
        this.nRecs = event.detail.value;
        console.log(this.nRecs);
        var idx = this.nRecs.indexOf( ' ' );
        this.recPerPage = parseInt( this.nRecs.substring( 0, idx ) );
        this.totalPage = Math.ceil(this.totalRecs/this.recPerPage);
        this.currentPage = 1;
        this.disablePrevious = true;
        if( this.currentPage == this.totalPage ){
            this.disableNext = true;
        }else   this.disableNext = false;
        this.end = this.recPerPage;
        this.start = 0;
        this.fillHalfData( this.end );
        console.log('Start2:',this.start);
        console.log('End2:', this.end);
        this.spin = false;
    }
    exportToCSV( all ) {  
        var columnHeader=[];
        var jsonKeys=[];
        for( var v of this.columns ){
            columnHeader.push( v.label );
            jsonKeys.push( v.fieldName );
        }
        console.log(jsonKeys);
        console.log(columnHeader);
        // let columnHeader = ["Item Number", "Name"];  // This array holds the Column headers to be displayd
        // let jsonKeys = ["itemn", "name"]; // This array holds the keys in the json data  
        var jsonRecordsData = this.data;  
        if( all == 'All' ){
            jsonRecordsData = this.sampleData;
        }
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
    exportToCSVAll(){
        this.exportToCSV( 'All' );
    }

    exportToXls(){
        // Prepare a html table
        let doc = '<table>';
        // Add styles for the table
        doc += '<style>';
        doc += 'table, th, td {';
        doc += '    border: 1px solid black;';
        doc += '    border-collapse: collapse;';
        doc += '}';          
        doc += '</style>';
        // Add all the Table Headers
        doc += '<tr>';
        this.columns.forEach(element => {            
            doc += '<th>'+ element.label +'</th>'           
        });
        doc += '</tr>';
        // Add the data rows
        this.data.forEach(record => {
            doc += '<tr>';
            doc += '<th>'+record.itemn+'</th>'; 
            doc += '<th>'+record.name+'</th>'; 
            doc += '</tr>';
        });
        doc += '</table>';
        var element = 'data:application/vnd.ms-excel,' + encodeURIComponent(doc);
        let downloadElement = document.createElement('a');
        downloadElement.href = element;
        downloadElement.target = '_self';
        // use .csv as extension on below line if you want to export data as csv
        downloadElement.download = 'Snowflake.xlsx';
        document.body.appendChild(downloadElement);
        downloadElement.click();
    }
    handleGetLeads(){
        this.totalPage = '';
        this.totalRecs = '';
        this.data = [];
        this.sampleData=[];
        console.log( 'LType:', this.lType, '--Parea:', this.practiceArea, '--Address:', this.selectedAdd, '--MinStart:', this.selectedStartMin, '--MinEnd:', this.selectedEndMin, '--MinYear:', this.selectedMinYear, '--MaxYear:',this.selectedMaxYear, '--Zip:', this.selectedZipCode );
        console.log( '--Setting:', this.selectedSetting, '--NPI:', this.selectedNpi, '--State:', this.selectedState, '--County:', this.selectedCounty, 'Location:', this.selectedLoc, '-MinMilerad:', this.minMilesValue );
        var mile = false;
        this.spin = true;
        if( this.minMilesValue == 'Miles' ){
            mile = true;
        }
        getLeadsCount( {'LType': this.lType, 'Parea': this.practiceArea, 'Address': this.selectedAdd, 'MinStart': this.selectedStartMin, 'MinEnd': this.selectedEndMin, 'MinYear': this.selectedMinYear, 'MaxYear':this.selectedMaxYear, 'Zip': this.selectedZipCode, 'Setting': this.selectedSetting, 'NPI': this.selectedNpi, 'State': this.selectedState, 'County': this.selectedCounty, 'Location': this.selectedLoc, 'Mile':mile} ).then( res=>{
            if( res!= undefined ){
                var result = JSON.parse(res);
                console.log(result.counts);
                try{
                    var datas = [];
                    var totalEmail = 0;
                    var totalPvt = 0;
                    var totalNotPvt = 0;
                    for( var d of result.counts ){
                        var obj = {};
                        obj['pArea'] = d.practiceArea;
                        obj['Email'] = d.hasResEmail;
                        totalEmail += parseInt(d.hasResEmail);
                        totalPvt += parseInt(d.uniqueDRNotPrivate);
                        totalNotPvt += parseInt(d.totalNotPrivate);
                        obj['Mail'] = d.uniqueDRNotPrivate +' Of '+d.totalNotPrivate;
                        datas.push( obj );
                    }
                    var o = {};
                    o['pArea'] = 'Total';
                    o['Email'] = totalEmail;
                    o['Mail'] = totalPvt + ' Of '+totalNotPvt;
                    datas.push( o );
                    console.log('DATASS:', datas);
                    for( var v of datas ){
                        this.sampleData.push(v);
                    }
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
                    this.showRecords = true;
                }catch( err ){
                    this.spin=false;
                    this.showRecords = true;
                    this.sfDataShow = false;
                    console.log(err);
                }
            }else{
                this.spin = false;
            }
        }).catch( err=>{
            console.log(err);
            this.spin = false;
        } );
        //this.spin = true;
        //this.getRecsFromSnowFlake( 0 );
        /* getLeadFromSnowflake().then( res=>{
            if( res!= undefined ){
                var result = JSON.parse(res);
                console.log(result.resultSetMetaData);
                console.log(result);
                var cols = [];
                var colNameMap = {};
                var i = 1;
                try{
                    for( var row of result.resultSetMetaData.rowType ){
                        cols.push( {label : row.name, fieldName:row.name} );
                        colNameMap[i] = row.name;
                        i++;
                    }
                    this.columns = cols;
                    var datas = [];
                    for( var d of result.data ){
                        var obj = {};
                        for( var j = 1; j<d.length; j++ ){
                            obj[colNameMap[j]] = d[j];
                        }
                        datas.push( obj );
                    }
                    this.sampleData = datas;
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
                    this.showRecords = true;
                }catch{
                    this.sfDataShow = false;
                    this.showRecords = true;
                }
            }
            this.spin = false;
        } ).catch( err=>{
            this.spin = false;
            console.log(err);
        } ); */

        // WARNING: For POST requests, body is set to null by browsers.
        /* var data = JSON.stringify({
            "statement": "select * from country where name = 'sandeep' ",
            "timeout": 60,
            "resultSetMetaData": {
            "format": "json"
            },
            "database": "YOUTUBE_TOTURIAL",
            "schema": "LOCATION",
            "warehouse": "COMPUTE_WH"
        });
        
        var xhr = new XMLHttpRequest();
        xhr.withCredentials = true;
        
        xhr.addEventListener("readystatechange", function() {
            if(this.readyState === 4) {
            console.log(this.responseText);
            }
        });
        
        xhr.open("POST", "https://ww53743.europe-west4.gcp.snowflakecomputing.com/api/statements");
        xhr.setRequestHeader("Authorization", "Bearer ver:1-hint:2745241609-ETMsDgAAAYJjiL6yABRBRVMvQ0JDL1BLQ1M1UGFkZGluZwEAABAAENaBGdQL7E0my/wtOW7jUK0AAABQhLD/kyYrtfUYOpjRG/6wUN0VIntM2PoVxkmeDMyzLRvGBm+zDQSeYvlirqn5JthqA2XsOPu0oVoznP3sBsbwZl9Fm+7GKLtc0tU+QbCG+jwAFJbwR9pTvlcJO2IYdkmVPi15iBS2");
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.setRequestHeader('Access-Control-Allow-Origin','*');
        xhr.setRequestHeader('mode','cors');
        xhr.send(data); */
        //Working
        /* try{
            var raw = JSON.stringify({
                "mimeType": "application/vnd.google-apps.folder",
                "title": "testFile",
                "name": "Test Folder"
                });
        
                var requestOptions = {
                method: 'POST',
                body: raw,
                headers:{
                    'Authorization':'Bearer ya29.A0AVA9y1vYhNNdQHxvaFUwg7K326Tz8-yTg15FwhQargVQ45-zDej2xFfGJ69M91vP7eAfJZKl_SO908wNCetXn4USBCiDcnm9k8_iH0hlMApBVpl6jvcd61FyaeQqnFfEq-j9Y1D2Ax0Vx7ulMaS0sj2p1y5J7gYUNnWUtBVEFTQVRBU0ZRRTY1ZHI4X2dwT3lXbExBLXAyc2lKQVowODRndw0165',
                    'Accept':'application/json',
                    'Content-Type':'application/json'
                },
                redirect: 'follow'
                };
        
                fetch("https://www.googleapis.com/drive/v3/files", requestOptions)
                .then(response => response.text())
                .then(result => console.log(result))
                .catch(error => console.log('error', error));
        }catch( err ){
            console.log(err);
        } */
        
        /* try{
            var raw = JSON.stringify({
                "statement": "select * from country where name = 'sandeep' ",
                "timeout": 60,
                "resultSetMetaData": {
                    "format": "json"
                },
                "database": "YOUTUBE_TOTURIAL",
                "schema": "LOCATION",
                "warehouse": "COMPUTE_WH"
                });
        
                var requestOptions = {
                method: 'POST',
                body: raw,
                headers:{
                    'Authorization':'Bearer ver:1-hint:2745241609-ETMsDgAAAYJjiL6yABRBRVMvQ0JDL1BLQ1M1UGFkZGluZwEAABAAENaBGdQL7E0my/wtOW7jUK0AAABQhLD/kyYrtfUYOpjRG/6wUN0VIntM2PoVxkmeDMyzLRvGBm+zDQSeYvlirqn5JthqA2XsOPu0oVoznP3sBsbwZl9Fm+7GKLtc0tU+QbCG+jwAFJbwR9pTvlcJO2IYdkmVPi15iBS2',
                    'Content-Type':'application/json',
                    'Accept':'application/json'
                },
                redirect: 'follow'
                };
        
                fetch("https://ww53743.europe-west4.gcp.snowflakecomputing.com/api/statements", requestOptions)
                .then(response => response.text())
                .then(result => console.log(result))
                .catch(error => console.log('error', error));
        }catch( err ){
            console.log(err);
        } */
        //try{
            
        /* var raw = JSON.stringify({
        "statement": "select * from country where name = 'sandeep' ",
        "timeout": 60,
        "resultSetMetaData": {
            "format": "json"
        },
        "database": "YOUTUBE_TOTURIAL",
        "schema": "LOCATION",
        "warehouse": "COMPUTE_WH"
        });

        var requestOptions = {
        method: 'POST',
        headers: {
            'Authorization':'Bearer ver:1-hint:2745241609-ETMsDgAAAYJjiL6yABRBRVMvQ0JDL1BLQ1M1UGFkZGluZwEAABAAENaBGdQL7E0my/wtOW7jUK0AAABQhLD/kyYrtfUYOpjRG/6wUN0VIntM2PoVxkmeDMyzLRvGBm+zDQSeYvlirqn5JthqA2XsOPu0oVoznP3sBsbwZl9Fm+7GKLtc0tU+QbCG+jwAFJbwR9pTvlcJO2IYdkmVPi15iBS2',
            'Content-Type':'application/json',
            'Access-Control-Allow-Origin':'*'
        },
        body: raw,
        mode:'cors',
        origin:'https://ww53743.europe-west4.gcp.snowflakecomputing.com/api/statements',
        };
        fetch("https://ww53743.europe-west4.gcp.snowflakecomputing.com/api/statements", requestOptions)
        .then(response => console.log(response))
        .then(result => console.log(result))
        .catch(error => console.log('error', error));
        }catch( err ){
            console.log(err);
        } */
        
    }

    getRecsFromSnowFlake( num ){
        getLeadFromSnowflake({ofValue : num, limitRec : this.limit}).then( res=>{
            if( res!= undefined ){
                var result = JSON.parse(res);
                console.log(result.resultSetMetaData);
                console.log(result);
                var cols = [];
                var colNameMap = {};
                var i = 1;
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
                        for( var j = 1; j<d.length; j++ ){
                            obj[colNameMap[j]] = d[ij];
                            ij++;
                        }
                        datas.push( obj );
                    }
                    console.log('DATASS:', datas);
                    for( var v of datas ){
                        this.sampleData.push(v);
                    }
                    if( result.resultSetMetaData.numRows > 0 ){
                        this.getRecsFromSnowFlake( num+this.limit );
                    }else{
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
                        this.showRecords = true;
                    }
                }catch( err ){
                    this.spin=false;
                    this.showRecords = true;
                    this.sfDataShow = false;
                    console.log(err);
                }
            }
        });
    }
}