package com.ankamagames.dofus
{
   import com.ankamagames.jerakine.data.XmlConfig;
   import flash.display.Loader;
   import flash.events.Event;
   import flash.net.URLRequest;
   import flash.system.ApplicationDomain;
   import flash.system.LoaderContext;

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
      private var module:Object;
      private var loader:Loader;

      public function main() : void
      {
         try
         {
            this.sysApi.log(2,"[ANOMALIES-UI] Bridge charge");
            this.loader = new Loader();
            this.loader.contentLoaderInfo.addEventListener(Event.COMPLETE,this.onModuleLoaded);
            var path:String = XmlConfig.getInstance().getEntry("config.mod.path") + "Ankama_Anomalies/Ankama_Anomalies.swf";
            var context:LoaderContext = new LoaderContext(false,ApplicationDomain.currentDomain);
            this.loader.load(new URLRequest(path),context);
         }
         catch(error:Error)
         {
            this.sysApi.log(4,"[ANOMALIES-UI] ERREUR PONT: " + error.message + " / " + error.getStackTrace());
         }
      }

      private function onModuleLoaded(event:Event) : void
      {
         try
         {
            var moduleClass:Class = ApplicationDomain.currentDomain.getDefinition("Ankama_Anomalies.Ankama_Anomalies") as Class;
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
   }
}
