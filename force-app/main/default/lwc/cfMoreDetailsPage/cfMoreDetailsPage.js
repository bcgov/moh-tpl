import { FlexCardMixin } from "omnistudio/flexCardMixin";
    import { CurrentPageReference } from 'lightning/navigation';
    import {interpolateWithRegex, interpolateKeyValue, loadCssFromStaticResource } from "omnistudio/flexCardUtility";
    
          import { LightningElement, api, track, wire } from "lwc";
          import pubsub from "omnistudio/pubsub";
          import { getRecord } from "lightning/uiRecordApi";
          
          import data from "./definition";
          
          import styleDef from "./styleDefinition";
              
          export default class cfMoreDetailsPage extends FlexCardMixin(LightningElement){
              currentPageReference;        
              @wire(CurrentPageReference)
              setCurrentPageReference(currentPageReference) {
                this.currentPageReference = currentPageReference;
              }
              @api debug;
              @api recordId;
              @api objectApiName;
              
              @track record;
              
              
              pubsubEvent = [];
              customEvent = [];
              
              connectedCallback() {
                super.connectedCallback();
                this.setThemeClass(data);
                this.setStyleDefinition(styleDef);
                data.Session = {} //reinitialize on reload
                
                
                
                this.setDefinition(data);
 this.registerEvents();
                
                
              }
              
              disconnectedCallback(){
                super.disconnectedCallback();
                    
                    

                  this.unregisterEvents();
              }

              registerEvents() {
                
        this.pubsubEvent[0] = {
          [interpolateWithRegex(`msprecorddetailsevent`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[0],0)
        };
        this.pubsubChannel0 = interpolateWithRegex(`mspRecordDetailsChannel`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel0,this.pubsubEvent[0]);

        this.pubsubEvent[1] = {
          [interpolateWithRegex(`hosprecorddetailevent`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[1],1)
        };
        this.pubsubChannel1 = interpolateWithRegex(`hospRecordDetailsChannel`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel1,this.pubsubEvent[1]);

        this.pubsubEvent[2] = {
          [interpolateWithRegex(`ambrecorddetailevent`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[2],2)
        };
        this.pubsubChannel2 = interpolateWithRegex(`ambRecordDetailChannel`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel2,this.pubsubEvent[2]);

        this.pubsubEvent[3] = {
          [interpolateWithRegex(`pharmarecorddetailevent`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[3],3)
        };
        this.pubsubChannel3 = interpolateWithRegex(`pharmaRecordDetailChannel`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel3,this.pubsubEvent[3]);

              }

              unregisterEvents(){
                pubsub.unregister(this.pubsubChannel0,this.pubsubEvent[0]);
pubsub.unregister(this.pubsubChannel1,this.pubsubEvent[1]);
pubsub.unregister(this.pubsubChannel2,this.pubsubEvent[2]);
pubsub.unregister(this.pubsubChannel3,this.pubsubEvent[3]);

              }
            
              renderedCallback() {
                super.renderedCallback();
                
              }
          }