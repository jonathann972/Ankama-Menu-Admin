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
      [Api(name="UiApi")]
      public var uiApi:Object;

      [Api(name="SystemApi")]
      public var sysApi:Object;

      [Api(name="DataApi")]
      public var dataApi:Object;

      [Api(name="InventoryApi")]
      public var inventoryApi:Object;

      public var btn_close:Object;

      public var btn_equip:Object;

      public var lbl_btn_equip:Object;

      public var lbl_collection:Object;

      public var tx_collection_locked_0:Object;

      public var tx_collection_unlocked_0:Object;

      public var tx_collection_icon_0:Object;

      public var tx_equipped_empty:Object;

      public var tx_equipped_active:Object;

      public var tx_equipped_icon:Object;

      public var lbl_equipped_name:Object;

      public var lbl_equipped_level:Object;

      public var lbl_detail_chance:Object;

      public var lbl_detail_power:Object;

      private var module:Object;
      private var loader:Loader;

      private var selectedEcho:Object;

      private var activeEcho:Object;

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
               if(this.btn_close)
               {
                  this.uiApi.addComponentHook(this.btn_close,"onRelease");
               }
               if(this.btn_equip)
               {
                  this.uiApi.addComponentHook(this.btn_equip,"onRelease");
               }
               this.installInventoryHooks();
               this.refreshEcho();
               return;
            }
            this.sysApi.log(2,"[ANOMALIES-UI] Bridge charge");
            this.loader = new Loader();
            this.loader.contentLoaderInfo.addEventListener(Event.COMPLETE,this.onModuleLoaded);
            path = XmlConfig.getInstance().getEntry("config.mod.path") + "Ankama_Anomalies/Ankama_Anomalies.swf";
            context = new LoaderContext(false,ApplicationDomain.currentDomain);
            this.loader.load(new URLRequest(path),context);
         }
         catch(error:Error)
         {
            this.sysApi.log(4,"[ANOMALIES-UI] ERREUR PONT: " + error.message + " / " + error.getStackTrace());
         }
      }

      private function onModuleLoaded(event:Event) : void
      {
         var moduleClass:Class;
         try
         {
            moduleClass = ApplicationDomain.currentDomain.getDefinition("Ankama_Anomalies.Ankama_Anomalies") as Class;
            this.module = new moduleClass();
            this.module.uiApi = this.uiApi;
            this.module.sysApi = this.sysApi;
            this.module.dataApi = this.dataApi;
            this.module.inventoryApi = this.inventoryApi;
            this.module.main();
            this.sysApi.log(2,"[ANOMALIES-UI] Module externe charge dans le domaine principal");
         }
         catch(error:Error)
         {
            this.sysApi.log(4,"[ANOMALIES-UI] ERREUR CHARGEMENT: " + error.message + " / " + error.getStackTrace());
         }
      }

      public function onRelease(target:Object) : void
      {
         if(target == this.btn_close)
         {
            this.uiApi.unloadUi("anomaliesUi");
            return;
         }
         if(target == this.btn_equip && this.selectedEcho)
         {
            if(this.activeEcho && uint(this.activeEcho.objectUID) == uint(this.selectedEcho.objectUID))
            {
               this.chat("[ANOM-EQUIP] clic déséquiper");
               this.pendingUnequip = true;
               this.pendingEquipUid = 0;
               this.sendCommand(".anomaly off");
            }
            else
            {
               this.pendingEquipUid = uint(this.selectedEcho.objectUID);
               this.pendingUnequip = false;
               this.chat("[ANOM-EQUIP] clic équiper uid=" + this.pendingEquipUid);
               this.sendCommand(".anomaly " + this.pendingEquipUid);
            }
            this.chat("[ANOM-EQUIP] commande envoyée");
         }
      }

      private function installInventoryHooks() : void
      {
         var hooks:Object = getDefinitionByName("com.ankamagames.dofus.misc.lists::InventoryHookList");
         this.sysApi.addHook(hooks.ObjectAdded,this.refreshEcho);
         this.sysApi.addHook(hooks.ObjectDeleted,this.refreshEcho);
         this.sysApi.addHook(hooks.ObjectModified,this.onObjectModified);
         this.sysApi.addHook(hooks.InventoryContent,this.refreshEcho);
      }

      private function onObjectModified(item:Object) : void
      {
         var uid:* = item ? item.objectUID : "inconnu";
         var active:int = this.effectValue(item,3102);
         this.chat("[ANOM-EQUIP] hook ObjectModified uid=" + uid);
         this.chat("[ANOM-EQUIP] effet 3102 après modification=" + active);
         this.refreshEcho();
         this.chat("[ANOM-EQUIP] refresh état " + (this.activeEcho ? "actif" : "inactif"));
      }

      private function refreshEcho(... args) : void
      {
         var typed290:Array = this.inventoryApi.getStorageObjectsByType(290);
         var direct:Object = this.inventoryApi.getItemByGID(32760);
         var candidates:Array = [];
         var seen:Object = {};
         var actualType:Array;
         var item:Object;
         var best:Object;
         var active:Object;
         this.chat("[ANOM-INVENTORY] filtre type 290=" + (typed290 ? typed290.length : 0));
         this.collectEchoCandidates(candidates,seen,typed290);
         if(direct)
         {
            this.chat("[ANOM-INVENTORY] GID 32760 trouvé; objectUID=" + direct.objectUID + "; typeId=" + direct.typeId + "; position=" + direct.position);
            this.chat("[ANOM-INVENTORY] effets=" + this.describeEffects(direct));
            this.collectEchoCandidate(candidates,seen,direct);
            actualType = this.inventoryApi.getStorageObjectsByType(uint(direct.typeId));
            this.chat("[ANOM-INVENTORY] filtre type réel " + direct.typeId + "=" + (actualType ? actualType.length : 0));
            this.collectEchoCandidates(candidates,seen,actualType);
         }
         else
         {
            this.chat("[ANOM-INVENTORY] GID 32760 absent via getItemByGID");
         }
         for each(item in candidates)
         {
            if(this.effectValue(item,3102) > 0)
            {
               active = item;
            }
            if(!best || this.echoScore(item) > this.echoScore(best) || this.echoScore(item) == this.echoScore(best) && uint(item.objectUID) < uint(best.objectUID))
            {
               best = item;
            }
         }
         this.selectedEcho = best;
         this.activeEcho = active;
         this.chat("[ANOM-INVENTORY] anomalies possédées=" + (best ? 1 : 0));
         this.renderEcho(best);
         this.renderEquipped(active);
         this.confirmPendingState(active);
      }

      private function collectEchoCandidates(target:Array,seen:Object,items:Array) : void
      {
         var item:Object;
         if(!items)
         {
            return;
         }
         for each(item in items)
         {
            this.collectEchoCandidate(target,seen,item);
         }
      }

      private function collectEchoCandidate(target:Array,seen:Object,item:Object) : void
      {
         if(!item || uint(item.objectGID) != 32760 || seen[item.objectUID])
         {
            return;
         }
         seen[item.objectUID] = true;
         target.push(item);
      }

      private function echoScore(item:Object) : Number
      {
         return (this.effectValue(item,3100) - 170) / 30 + (this.effectValue(item,3101) - 40) / 20;
      }

      private function effectValue(item:Object,effectId:uint) : int
      {
         var effect:Object;
         if(!item || !item.effects)
         {
            return 0;
         }
         for each(effect in item.effects)
         {
            if(uint(effect.effectId) == effectId)
            {
               return int(effect.value);
            }
         }
         return 0;
      }

      private function describeEffects(item:Object) : String
      {
         var values:Array = [];
         var effect:Object;
         if(item && item.effects)
         {
            for each(effect in item.effects)
            {
               values.push(effect.effectId + "=" + effect.value);
            }
         }
         return "[" + values.join(",") + "]";
      }

      private function renderEcho(item:Object) : void
      {
         var owned:Boolean = Boolean(item);
         this.lbl_collection.text = "Collection " + (owned ? 1 : 0) + "/1";
         this.tx_collection_locked_0.visible = !owned;
         this.tx_collection_unlocked_0.visible = owned;
         this.tx_collection_icon_0.visible = owned;
         if(owned)
         {
            this.lbl_detail_chance.text = (this.effectValue(item,3100) / 10).toFixed(1).replace(".",",") + " %";
            this.lbl_detail_power.text = this.effectValue(item,3101) + " %";
         }
         else
         {
            this.lbl_detail_chance.text = "—";
            this.lbl_detail_power.text = "—";
         }
         var selectedIsActive:Boolean = Boolean(item) && Boolean(this.activeEcho) && uint(item.objectUID) == uint(this.activeEcho.objectUID);
         if(this.lbl_btn_equip)
         {
            this.lbl_btn_equip.text = selectedIsActive ? "DÉSÉQUIPER" : "ÉQUIPER";
         }
         if(this.btn_equip)
         {
            this.btn_equip.disabled = !owned;
         }
      }

      private function renderEquipped(item:Object) : void
      {
         var equipped:Boolean = Boolean(item);
         this.tx_equipped_empty.visible = !equipped;
         this.tx_equipped_active.visible = equipped;
         this.tx_equipped_icon.visible = equipped;
         this.lbl_equipped_name.visible = equipped;
         this.lbl_equipped_level.visible = equipped;
         this.lbl_equipped_name.text = equipped ? "Écho" : "";
         this.lbl_equipped_level.text = equipped ? "Niv. 1" : "";
         if(equipped)
         {
            this.validateEquippedName("Écho");
         }
      }

      private function confirmPendingState(active:Object) : void
      {
         if(this.pendingEquipUid > 0 && active && uint(active.objectUID) == this.pendingEquipUid)
         {
            this.chat("[ANOM-EQUIP] état actif confirmé uid=" + this.pendingEquipUid);
            this.chat("[ANOM-EQUIP] slot 1 actualisé : Écho niveau 1");
            this.pendingEquipUid = 0;
         }
         if(this.pendingUnequip && !active)
         {
            this.chat("[ANOM-EQUIP] état inactif confirmé");
            this.chat("[ANOM-EQUIP] slot 1 vidé");
            this.pendingUnequip = false;
         }
      }

      private function validateEquippedName(name:String) : void
      {
         var measuredWidth:Number = Number(this.lbl_equipped_name.textWidth);
         if((name.length > 10 || measuredWidth > 89) && this.warnedEquippedName != name)
         {
            this.warnedEquippedName = name;
            this.chat("[ANOM-EQUIP] nom hors limites : \"" + name + "\"; caractères=" + name.length + "/10; largeur=" + measuredWidth + "/89 px");
         }
      }

      private function sendCommand(command:String) : void
      {
         var action:Object = getDefinitionByName("com.ankamagames.dofus.logic.game.common.actions.chat::ChatTextOutputAction");
         this.sysApi.sendAction(action.create(command));
      }

      private function chat(message:String) : void
      {
         try
         {
            var hooks:Object = getDefinitionByName("com.ankamagames.dofus.misc.lists::ChatHookList");
            this.sysApi.dispatchHook(hooks.TextInformation,message,666,0);
         }
         catch(error:Error)
         {
            this.sysApi.log(4,message);
         }
      }
   }
}
