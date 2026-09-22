package Ankama_Anomalies {
 import Ankama_Anomalies.ui.AnomaliesUi;
 import flash.display.Sprite;
 import flash.utils.getDefinitionByName;
 import flash.utils.setTimeout;
 import flash.utils.ByteArray;
 import flash.events.Event;
 import flash.events.IOErrorEvent;
 import flash.events.SecurityErrorEvent;
 import flash.net.URLLoader;
 import flash.net.URLRequest;
 public class Ankama_Anomalies extends Sprite {
  [Embed(source="../../xml/anomaliesUiV2.xml", mimeType="application/octet-stream")]
  private static const PANEL_XML:Class;
  private static const PANEL_SMOKE_XML:String="<Definition><Constants><Constant name='assets' value='[config.ui.skin]assets.swf|'/><Constant name='css' value='[config.ui.skin]css/'/></Constants><Container name='mainCtr'><Anchors><Anchor point='CENTER' relativePoint='CENTER'/></Anchors><Size><AbsDimension x='760' y='480'/></Size><Texture><Size><AbsDimension x='760' y='480'/></Size><autoGrid>true</autoGrid><uri>[local.assets]tx_generalBackgroundWithTitle</uri></Texture><Label><Anchors><Anchor><AbsDimension x='24' y='15'/></Anchor></Anchors><Size><AbsDimension x='700' y='40'/></Size><css>[local.css]title.css</css><text>ANOMALIES - TEST BERILIA</text></Label><Label><Anchors><Anchor><AbsDimension x='40' y='100'/></Anchor></Anchors><Size><AbsDimension x='680' y='100'/></Size><css>[local.css]normal.css</css><text>Le panneau natif est correctement charge.</text></Label></Container></Definition>";
  [Api(name="UiApi")] public var uiApi:Object;
  [Api(name="SystemApi")] public var sysApi:Object;
  [Api(name="DataApi")] public var dataApi:Object;
  [Api(name="InventoryApi")] public var inventoryApi:Object;
  private var linkedAnomaliesUi:AnomaliesUi;
  private var smokeLoader:URLLoader;
  private var panelFile:String;
  public function Ankama_Anomalies(){super();}
  public function main():void { sysApi.log(2,"[ANOMALIES-UI] Module autonome demarre");setTimeout(install,500); }
  private function install():void {
   registerPanel();
   var banner:Object=uiApi.getUi("bannerMenu");
   if(!banner){setTimeout(install,500);return;}
   var grid:Object=banner.getElement("gd_btnUis");
   if(!grid||!grid.dataProvider){setTimeout(install,500);return;}
   var buttons:Array=grid.dataProvider as Array;
   if(!buttons)return;
   for each(var entry:Object in buttons)if(entry&&entry.id==32760)return;
   buttons=buttons.slice();
   buttons.push(dataApi.getButtonWrapper(32760,buttons.length+1,"btn_breach",togglePanel,"Anomalies"));
   grid.dataProvider=buttons;
   sysApi.log(2,"[ANOMALIES-UI] Bouton natif installe");
  }
  private function registerPanel():void {
   var managerClass:Object=getDefinitionByName("com.ankamagames.berilia.managers::UiModuleManager");
   var module:Object=managerClass.getInstance().getModule("Ankama_Anomalies");
   if(!module||module.uis["anomaliesUi"])return;
   var dataClass:Object=getDefinitionByName("com.ankamagames.berilia.types.data::UiData");
   panelFile=module.rootPath+"xml/anomaliesSmoke.xml";
   var data:Object=new dataClass(module,"anomaliesUi",panelFile,"Ankama_Anomalies.ui::AnomaliesUi");
   data.uiClass=getDefinitionByName("Ankama_Anomalies.ui::AnomaliesUi") as Class;
   module.uis["anomaliesUi"]=data;
  }
  private function togglePanel(...args):void {
   debugChat("[ANOMALIES-UI] Clic recu.");
   debugChat("[ANOMALIES-UI] XML : "+panelFile);
   testPanelFile();
   try {
    if(uiApi.getUi("anomaliesUi")){
     uiApi.unloadUi("anomaliesUi");
     debugChat("[ANOMALIES-UI] Panneau ferme.");
    } else {
     var result:Object=uiApi.loadUi("anomaliesUi","anomaliesUi");
     debugChat("[ANOMALIES-UI] loadUi retourne : "+result);
     setTimeout(checkPanel,800);
    }
   } catch(error:Error) {
    debugChat("[ANOMALIES-UI] ERREUR : "+error.name+" - "+error.message);
   }
  }
  private function testPanelFile():void {
   try {
    smokeLoader=new URLLoader();
    smokeLoader.addEventListener(Event.COMPLETE,onPanelFileLoaded);
    smokeLoader.addEventListener(IOErrorEvent.IO_ERROR,onPanelFileError);
    smokeLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,onPanelFileError);
    smokeLoader.load(new URLRequest(panelFile));
   } catch(error:Error) {
    debugChat("[ANOMALIES-UI] XML EXCEPTION : "+error.name+" - "+error.message);
   }
  }
  private function onPanelFileLoaded(event:Event):void {
   var raw:String=String(smokeLoader.data);
   debugChat("[ANOMALIES-UI] XML LU : "+raw.length+" octets");
   try { var parsed:XML=new XML(raw); debugChat("[ANOMALIES-UI] XML VALIDE : "+parsed.name()); }
   catch(error:Error) { debugChat("[ANOMALIES-UI] XML INVALIDE : "+error.message); }
  }
  private function onPanelFileError(event:Event):void {
   debugChat("[ANOMALIES-UI] XML I/O ERREUR : "+event.toString());
  }
  private function checkPanel():void {
   try {
    debugChat("[ANOMALIES-UI] Verification : "+(uiApi.getUi("anomaliesUi")?"OUVERT":"ABSENT"));
   } catch(error:Error) {
    debugChat("[ANOMALIES-UI] ERREUR VERIFICATION : "+error.message);
   }
  }
  private function debugChat(message:String):void {
   try {
    var hooks:Object=getDefinitionByName("com.ankamagames.dofus.misc.lists::ChatHookList");
    sysApi.dispatchHook(hooks.TextInformation,message,666,0);
   } catch(ignore:Error) {
    sysApi.log(4,message);
   }
  }
 }
}
