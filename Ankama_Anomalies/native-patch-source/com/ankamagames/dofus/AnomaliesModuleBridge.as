package com.ankamagames.dofus
{
   public class AnomaliesModuleBridge
   {
      [Api(name="UiApi")]
      public var uiApi:Object;

      [Api(name="SystemApi")]
      public var sysApi:Object;

      public var btn_close:Object;

      public function AnomaliesModuleBridge()
      {
         super();
      }

      public function main(... args) : void
      {
         this.sysApi.log(2,"[ANOM-NATIVE] AnomaliesUi.main OK");
         if(this.btn_close)
         {
            this.uiApi.addComponentHook(this.btn_close,"onRelease");
         }
      }

      public function onRelease(target:Object) : void
      {
         if(target == this.btn_close)
         {
            this.uiApi.unloadUi("anomaliesUi");
         }
      }
   }
}
