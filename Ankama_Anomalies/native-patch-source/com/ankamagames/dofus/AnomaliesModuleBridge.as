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

      public var lbl_collection:Object;

      public var tx_collection_locked_0:Object;

      public var tx_collection_unlocked_0:Object;

      public var tx_collection_icon_0:Object;

      public var lbl_detail_chance:Object;

      public var lbl_detail_power:Object;

      private var module:Object;
      private var loader:Loader;

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
         }
      }

      private function installInventoryHooks() : void
      {
         var hooks:Object = getDefinitionByName("com.ankamagames.dofus.misc.lists::InventoryHookList");
         this.sysApi.addHook(hooks.ObjectAdded,this.refreshEcho);
         this.sysApi.addHook(hooks.ObjectDeleted,this.refreshEcho);
         this.sysApi.addHook(hooks.ObjectModified,this.refreshEcho);
         this.sysApi.addHook(hooks.InventoryContent,this.refreshEcho);
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
            if(!best || this.echoScore(item) > this.echoScore(best) || this.echoScore(item) == this.echoScore(best) && uint(item.objectUID) < uint(best.objectUID))
            {
               best = item;
            }
         }
         this.chat("[ANOM-INVENTORY] anomalies possédées=" + (best ? 1 : 0));
         this.renderEcho(best);
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
