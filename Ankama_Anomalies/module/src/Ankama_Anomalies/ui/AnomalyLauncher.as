package Ankama_Anomalies.ui {
 public class AnomalyLauncher {
  [Api(name="UiApi")] public var uiApi:Object;
  public var btn_anomalies:Object;
  public function main(...args):void { uiApi.addComponentHook(btn_anomalies,"onRelease"); uiApi.addComponentHook(btn_anomalies,"onRollOver"); uiApi.addComponentHook(btn_anomalies,"onRollOut"); }
  public function onRelease(target:Object):void { if(uiApi.getUi("anomaliesUi")) uiApi.unloadUi("anomaliesUi"); else uiApi.loadUi("anomaliesUi","anomaliesUi",null,1,null,true); }
  public function onRollOver(target:Object):void { uiApi.showTooltip(uiApi.textTooltipInfo("Anomalies"),target,false,"standard",7,1,3,null,null,null,"TextInfo"); }
  public function onRollOut(target:Object):void { uiApi.hideTooltip(); }
 }
}
