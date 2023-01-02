import { api, LightningElement, wire, track } from 'lwc';
import getFileNames from '@salesforce/apex/campaignFolderCreateCls.getFileNames';
import getFilesOfFolder from '@salesforce/apex/campaignFolderCreateCls.getFilesOfFolder';
export default class GoogleDriveFiles extends LightningElement {
    @api recordId;
    @api objectApiName;
    spin = false;
    fileNames=[];
    showFileName = false;
    open=false;
    currentFolder=[];
    prevFolder={};
    folder = 'Assets';
    prev=false;
    noSubFile = false;
    list = false;
    connectedCallback(){
        console.log(this.objectApiName);
        this.handleRefresh();    
    }
    handleToggle( event ){
        this.list = event.target.checked;
        console.log('-->',event.target.checked);
    }
    handleRefresh(){
        console.log('Data:',this.data);
        this.spin = true;
        this.folder = 'Assets';
        this.prev = false;
        getFileNames({campaignId:this.recordId, objName : this.objectApiName}).then( res=>{
            var fileDetails = JSON.parse( JSON.stringify(res) );
            console.log(fileDetails);
            console.log('Spin:', this.spin);
            var fNames = [];
            if( fileDetails.length > 0 ){
                this.showFileName = true;
            }
            fileDetails.forEach( file =>{
                var obj = {'Name':file.name, 'Link':'https://drive.google.com/file/d/'+file.id+'/view?usp=sharing', 'isFolder':false, 'open':false, 'icon':'utility:add'};
                if( file.mimeType == 'application/vnd.google-apps.folder' ){
                    obj['isFolder'] = true;
                    obj['Link'] = 'https://drive.google.com/drive/u/0/folders/'+file.id; 
                    console.log('FileId:', file.id);
                    this.getInnerFolder( file, obj );
                }
                fNames.push(obj);
            });
            setTimeout( ()=>{
                this.fileNames = fNames;
                this.currentFolder = fNames;
                console.log(this.currentFolder);
                this.spin = false;
                console.log('Folder Details:',this.fileNames);
                console.log('Spin:', this.spin);
            }, 5000 ); 
        } ).catch( err=>{
            this.spin = false;
            this.showFileName = false;
        } );
    }
    async getInnerFolder(file, obj, inn ){
        var items = [];
        var fId = file.id;
        console.log('File:', file);
        await getFilesOfFolder( {folderId:fId} ).then( subFiles=>{
            var subFileDetails = JSON.parse( JSON.stringify(subFiles) );
            console.log(subFileDetails);
            if( subFileDetails!= undefined ){
                subFileDetails.forEach( file =>{
                    var o = {'Name':file.name, 'Link':'https://drive.google.com/file/d/'+file.id+'/view?usp=sharing', 'isFolder':false, 'open':false, 'icon':'utility:add'};
                    if( file.mimeType == 'application/vnd.google-apps.folder' ){
                        o['isFolder'] = true;
                        o['Link'] = 'https://drive.google.com/drive/u/0/folders/'+file.id;    
                        this.getInnerFolder( file, o, 'inner' );                  
                    }
                    items.push( o );               
                });
                obj['Folder'] = items;
            }
        });
    }
    handleAdd( event ){
        try{
            var ele = this.currentFolder[event.target.dataset.idx];
            ele.clicked = true;
            console.log(this.currentFolder);
            this.currentFolder[event.target.dataset.idx] = ele;
            console.log(this.currentFolder);
            if( Object.keys(this.prevFolder).length == 0 ){
                this.prevFolder = {1:this.currentFolder};
            }else{
                var keysObj = Object.keys(this.prevFolder);
                keysObj.sort(function(a, b) {
                    return a - b;
                  });              
                var lEle = keysObj.reverse();
                this.prevFolder[parseInt(lEle[0])+1] = this.currentFolder;
            }
            this.prev = true;
            console.log('PFolder:',this.prevFolder);
            console.log('idx',event.target.dataset.idx);
            var newF = this.currentFolder[event.target.dataset.idx];
            if( newF != undefined ){
                this.folder = this.currentFolder[event.target.dataset.idx].Name;
                this.currentFolder = this.currentFolder[event.target.dataset.idx].Folder;
                console.log('CFolder:',this.currentFolder);
                console.log(this.currentFolder[event.target.dataset.idx]);
            }
            if( this.currentFolder.length == 0 ){
                this.showFileName = false;
            }else{
                this.showFileName = true;
            }
            console.log('len1:', this.currentFolder.length);
        }catch(err){
            console.log(err);
        }
        
    }
    handlePrev(){
        try{
            var l = Object.keys(this.prevFolder).length;
            console.log(Object.keys(this.prevFolder).length);
            if( Object.keys(this.prevFolder).length > 0 ){
                var keysObj = Object.keys(this.prevFolder);
                keysObj.sort(function(a, b) {
                    return a - b;
                });
                console.log('>1',JSON.stringify(this.prevFolder));
                var lEle = keysObj.reverse();
                this.currentFolder = this.prevFolder[parseInt(lEle[0])];
                console.log('ClickCheck:',this.currentFolder);
                if( l > 1 ){
                    for( var v of this.prevFolder[parseInt(lEle[1])] ){
                        if( v.clicked == true ){
                            console.log(v);
                            this.folder = v.Name;
                            v.clicked = false;
                        }
                    }
                }
                console.log('Clicked:',this.currentFolder);
                delete this.prevFolder[lEle[0]];
                console.log(this.prevFolder);
                console.log('len:', this.currentFolder);
                if( this.currentFolder.length == 0 ){
                    this.showFileName = false;
                }else{
                    this.showFileName = true;
                }
            }
            if( l == 1 ){
                this.folder='Assets';
                this.prev = false;
            }
        }catch( err ){
            console.log(err);
        }
    }
}