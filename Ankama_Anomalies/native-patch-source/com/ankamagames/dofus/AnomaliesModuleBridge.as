package com.ankamagames.dofus
{
   import com.ankamagames.jerakine.data.XmlConfig;
   import flash.display.Loader;
   import flash.events.Event;
   import flash.net.URLRequest;
   import flash.system.ApplicationDomain;
   import flash.system.LoaderContext;
   import flash.utils.getDefinitionByName;

   public class AnomaliesModuleBridge
   {
      private static const TYPE:uint = 290;
      private static const ACTIVE:uint = 3102;
      [Api(name="UiApi")] public var uiApi:Object;
      [Api(name="SystemApi")] public var sysApi:Object;
      [Api(name="DataApi")] public var dataApi:Object;
      [Api(name="InventoryApi")] public var inventoryApi:Object;
      public var btn_close:Object;
      public var btn_equip:Object;
      public var btn_collection_0:Object;
      public var btn_collection_1:Object;
      public var lbl_btn_equip:Object;
      public var lbl_collection:Object;
      public var tx_collection_locked_0:Object;
      public var tx_collection_locked_1:Object;
      public var tx_collection_unlocked_0:Object;
      public var tx_collection_unlocked_1:Object;
      public var tx_collection_icon_0:Object;
      public var tx_collection_icon_1:Object;
      public var tx_equipped_empty:Object;
      public var tx_equipped_active:Object;
      public var tx_equipped_icon:Object;
      public var lbl_equipped_name:Object;
      public var lbl_equipped_level:Object;
      public var tx_detail_icon:Object;
      public var lbl_detail_name:Object;
      public var lbl_detail_rarity:Object;
      public var lbl_detail_level:Object;
      public var lbl_detail_description:Object;
      public var lbl_detail_stat1_name:Object;
      public var lbl_detail_stat2_name:Object;
      public var lbl_detail_chance:Object;
      public var lbl_detail_chance_max:Object;
      public var lbl_detail_power:Object;
      public var lbl_detail_power_max:Object;
      public var lbl_detail_category:Object;
      public var lbl_detail_source:Object;
      public var lbl_detail_date:Object;
      private var module:Object;
      private var loader:Loader;
      private var catalog:Array;
      private var selectedDef:Object;
      private var selectedItem:Object;
      private var activeItem:Object;
      private var best:Object = {};
      private var pendingEquipUid:uint;
      private var pendingUnequip:Boolean;
      private var warnedEquippedName:String;

      public function main(... args) : void
      {
         var path:String;
         var context:LoaderContext;
         try
         {
            if(this.lbl_collection)
            {
               this.chat("[ANOM-UI] Contrôleur Berilia exécuté");
               this.createCatalog();
               this.installUiHooks();
               this.installInventoryHooks();
               this.refreshInventory();
               return;
            }
            this.sysApi.log(2,"[ANOMALIES-UI] Bridge charge");
            this.loader = new Loader();
            this.loader.contentLoaderInfo.addEventListener(Event.COMPLETE,this.onModuleLoaded);
            path = XmlConfig.getInstance().getEntry("config.mod.path") + "Ankama_Anomalies/Ankama_Anomalies.swf";
            context = new LoaderContext(false,ApplicationDomain.currentDomain);
            this.loader.load(new URLRequest(path),context);
         }
         catch(error:Error) { this.sysApi.log(4,"[ANOMALIES-UI] ERREUR PONT: " + error.message + " / " + error.getStackTrace()); }
      }

      private function onModuleLoaded(event:Event) : void
      {
         var moduleClass:Class;
         try
         {
            moduleClass = ApplicationDomain.currentDomain.getDefinition("Ankama_Anomalies.Ankama_Anomalies") as Class;
            this.module = new moduleClass();
            this.module.uiApi=this.uiApi; this.module.sysApi=this.sysApi; this.module.dataApi=this.dataApi; this.module.inventoryApi=this.inventoryApi;
            this.module.main();
            this.sysApi.log(2,"[ANOMALIES-UI] Module externe charge dans le domaine principal");
         }
         catch(error:Error) { this.sysApi.log(4,"[ANOMALIES-UI] ERREUR CHARGEMENT: " + error.message + " / " + error.getStackTrace()); }
      }

      private function createCatalog() : void
      {
         var root:String = String(this.sysApi.getConfigEntry("config.mod.path")) + "Ankama_Anomalies/assets/";
         this.catalog = [
            {gid:32760,name:"Écho",rarity:"ANOMALIE ÉPIQUE",level:1,description:"« Le premier sort offensif éligible lancé durant le tour peut être répété avec une puissance réduite. »",category:"Offensive",source:"Donjon X",icon:root+"echo-64.png",stat1Name:"Chance de répétition",stat1Id:3100,stat1Min:170,stat1Max:200,stat1Tenths:true,stat1Suffix:" %",stat2Name:"Puissance de l'écho",stat2Id:3101,stat2Min:40,stat2Max:60,stat2Tenths:false,stat2Suffix:" %"},
            {gid:32761,name:"Rémanence",rarity:"ANOMALIE ÉPIQUE",level:1,description:"« À la fin de votre tour, Rémanence peut conserver une partie de vos PA inutilisés pour votre prochain tour. »",category:"Utilitaire",source:"Donjon X",icon:root+"Remanence_64x64.png",stat1Name:"Chance de rémanence",stat1Id:3103,stat1Min:150,stat1Max:250,stat1Tenths:true,stat1Suffix:" %",stat2Name:"PA conservés",stat2Id:3104,stat2Min:1,stat2Max:2,stat2Tenths:false,stat2Suffix:""}
         ];
         this.selectedDef = this.catalog[0];
      }

      private function installUiHooks() : void
      {
         this.uiApi.addComponentHook(this.btn_close,"onRelease"); this.uiApi.addComponentHook(this.btn_equip,"onRelease");
         this.uiApi.addComponentHook(this.btn_collection_0,"onRelease"); this.uiApi.addComponentHook(this.btn_collection_1,"onRelease");
      }

      private function installInventoryHooks() : void
      {
         var hooks:Object=getDefinitionByName("com.ankamagames.dofus.misc.lists::InventoryHookList");
         this.sysApi.addHook(hooks.ObjectAdded,this.refreshInventory); this.sysApi.addHook(hooks.ObjectDeleted,this.refreshInventory);
         this.sysApi.addHook(hooks.ObjectModified,this.onObjectModified); this.sysApi.addHook(hooks.InventoryContent,this.refreshInventory);
      }

      public function onRelease(target:Object) : void
      {
         if(target==this.btn_close) { this.uiApi.unloadUi("anomaliesUi"); return; }
         if(target==this.btn_collection_0) { this.selectDefinition(0); return; }
         if(target==this.btn_collection_1) { this.selectDefinition(1); return; }
         if(target==this.btn_equip && this.selectedItem)
         {
            if(this.activeItem && uint(this.activeItem.objectUID)==uint(this.selectedItem.objectUID))
            {
               this.chat("[ANOM-EQUIP] clic déséquiper"); this.pendingUnequip=true; this.pendingEquipUid=0; this.sendCommand(".anomaly off");
            }
            else
            {
               this.pendingEquipUid=uint(this.selectedItem.objectUID); this.pendingUnequip=false;
               this.chat("[ANOM-EQUIP] clic équiper uid="+this.pendingEquipUid); this.sendCommand(".anomaly "+this.pendingEquipUid);
            }
            this.chat("[ANOM-EQUIP] commande envoyée");
         }
      }

      private function onObjectModified(item:Object) : void
      {
         this.chat("[ANOM-EQUIP] hook ObjectModified uid="+(item?item.objectUID:"inconnu"));
         this.chat("[ANOM-EQUIP] effet 3102 après modification="+this.effectValue(item,ACTIVE));
         this.refreshInventory();
         this.chat("[ANOM-EQUIP] refresh état "+(this.activeItem?"actif":"inactif"));
      }

      private function refreshInventory(... args) : void
      {
         var seen:Object = {};
         var candidates:Array = [];
         var definition:Object;
         var direct:Object;
         var item:Object;
         var current:Object;
         this.best={}; this.activeItem=null;
         this.collectCandidates(candidates,seen,this.inventoryApi.getStorageObjectsByType(TYPE));
         for each(definition in this.catalog)
         {
            direct=this.inventoryApi.getItemByGID(uint(definition.gid)); this.collectCandidate(candidates,seen,direct);
         }
         for each(item in candidates)
         {
            current=this.best[item.objectGID];
            if(!current || this.score(item,this.definition(uint(item.objectGID)))>this.score(current,this.definition(uint(item.objectGID)))) this.best[item.objectGID]=item;
            if(this.effectValue(item,ACTIVE)>0) this.activeItem=item;
         }
         this.selectedItem=this.selectedDef?this.best[this.selectedDef.gid]:null;
         this.renderAll(); this.confirmPendingState();
      }

      private function collectCandidates(target:Array,seen:Object,items:Array) : void
      { var item:Object; if(items) for each(item in items) this.collectCandidate(target,seen,item); }
      private function collectCandidate(target:Array,seen:Object,item:Object) : void
      { if(!item || !this.definition(uint(item.objectGID)) || seen[item.objectUID]) return; seen[item.objectUID]=true; target.push(item); }
      private function definition(gid:uint) : Object
      { var entry:Object; for each(entry in this.catalog) if(uint(entry.gid)==gid) return entry; return null; }
      private function score(item:Object,d:Object) : Number
      { return d?(this.effectValue(item,d.stat1Id)-d.stat1Min)/Math.max(1,d.stat1Max-d.stat1Min)+(this.effectValue(item,d.stat2Id)-d.stat2Min)/Math.max(1,d.stat2Max-d.stat2Min):0; }
      private function effectValue(item:Object,effectId:uint) : int
      { var effect:Object; if(item&&item.effects) for each(effect in item.effects) if(uint(effect.effectId)==effectId) return int(effect.value); return 0; }

      private function selectDefinition(index:int) : void
      { if(index<0||index>=this.catalog.length)return; this.selectedDef=this.catalog[index]; this.selectedItem=this.best[this.selectedDef.gid]; this.renderDetails(); }
      private function renderAll() : void { this.renderCollection(); this.renderDetails(); this.renderEquipped(); }

      private function renderCollection() : void
      {
         var owned:int = 0;
         var key:*;
         var first:Object = this.best[this.catalog[0].gid];
         var second:Object = this.best[this.catalog[1].gid];
         for(key in this.best) owned++;
         this.lbl_collection.text="Collection "+owned+"/"+this.catalog.length;
         this.tx_collection_locked_0.visible=!first; this.tx_collection_unlocked_0.visible=Boolean(first); this.tx_collection_icon_0.visible=true; this.tx_collection_icon_0.uri=this.uiApi.createUri(this.catalog[0].icon);
         this.tx_collection_locked_1.visible=!second; this.tx_collection_unlocked_1.visible=Boolean(second); this.tx_collection_icon_1.visible=true; this.tx_collection_icon_1.uri=this.uiApi.createUri(this.catalog[1].icon);
      }

      private function renderDetails() : void
      {
         var d:Object = this.selectedDef;
         var item:Object = this.selectedItem;
         var selectedIsActive:Boolean=Boolean(item)&&Boolean(this.activeItem)&&uint(item.objectUID)==uint(this.activeItem.objectUID);
         this.tx_detail_icon.uri=this.uiApi.createUri(d.icon); this.lbl_detail_name.text=d.name; this.lbl_detail_rarity.text=d.rarity;
         this.lbl_detail_level.text="Niveau "+d.level; this.lbl_detail_description.text=d.description;
         this.lbl_detail_stat1_name.text=d.stat1Name; this.lbl_detail_stat2_name.text=d.stat2Name;
         this.lbl_detail_category.text=d.category; this.lbl_detail_source.text=d.source; this.lbl_detail_date.text="—";
         this.lbl_detail_chance.text=item?this.formatValue(this.effectValue(item,d.stat1Id),d.stat1Tenths,d.stat1Suffix):"—";
         this.lbl_detail_chance_max.text="/ "+this.formatValue(d.stat1Max,d.stat1Tenths,d.stat1Suffix);
         this.lbl_detail_power.text=item?this.formatValue(this.effectValue(item,d.stat2Id),d.stat2Tenths,d.stat2Suffix):"—";
         this.lbl_detail_power_max.text="/ "+this.formatValue(d.stat2Max,d.stat2Tenths,d.stat2Suffix);
         this.lbl_btn_equip.text=selectedIsActive?"DÉSÉQUIPER":"ÉQUIPER"; this.btn_equip.disabled=!item;
      }

      private function renderEquipped() : void
      {
         var d:Object=this.activeItem?this.definition(uint(this.activeItem.objectGID)):null;
         var equipped:Boolean=Boolean(this.activeItem)&&Boolean(d);
         this.tx_equipped_empty.visible=!equipped; this.tx_equipped_active.visible=equipped; this.tx_equipped_icon.visible=equipped;
         this.lbl_equipped_name.visible=equipped; this.lbl_equipped_level.visible=equipped;
         this.lbl_equipped_name.text=equipped?d.name:""; this.lbl_equipped_level.text=equipped?"Niv. "+d.level:"";
         if(equipped) { this.tx_equipped_icon.uri=this.uiApi.createUri(d.icon); this.validateEquippedName(d.name); }
      }

      private function formatValue(value:int,tenths:Boolean,suffix:String) : String
      { return (tenths?(value/10).toFixed(1).replace(".",","):String(value))+suffix; }

      private function confirmPendingState() : void
      {
         var d:Object;
         if(this.pendingEquipUid>0&&this.activeItem&&uint(this.activeItem.objectUID)==this.pendingEquipUid)
         { d=this.definition(uint(this.activeItem.objectGID)); this.chat("[ANOM-EQUIP] état actif confirmé uid="+this.pendingEquipUid); this.chat("[ANOM-EQUIP] slot 1 actualisé : "+d.name+" niveau "+d.level); this.pendingEquipUid=0; }
         if(this.pendingUnequip&&!this.activeItem)
         { this.chat("[ANOM-EQUIP] état inactif confirmé"); this.chat("[ANOM-EQUIP] slot 1 vidé"); this.pendingUnequip=false; }
      }

      private function validateEquippedName(name:String) : void
      {
         var measuredWidth:Number=Number(this.lbl_equipped_name.textWidth);
         if((name.length>10||measuredWidth>89)&&this.warnedEquippedName!=name)
         { this.warnedEquippedName=name; this.chat("[ANOM-EQUIP] nom hors limites : \""+name+"\"; caractères="+name.length+"/10; largeur="+measuredWidth+"/89 px"); }
      }
      private function sendCommand(command:String) : void
      { var action:Object=getDefinitionByName("com.ankamagames.dofus.logic.game.common.actions.chat::ChatTextOutputAction"); this.sysApi.sendAction(action.create(command)); }
      private function chat(message:String) : void
      { try { var hooks:Object=getDefinitionByName("com.ankamagames.dofus.misc.lists::ChatHookList"); this.sysApi.dispatchHook(hooks.TextInformation,message,666,0); } catch(error:Error) { this.sysApi.log(4,message); } }
   }
}
