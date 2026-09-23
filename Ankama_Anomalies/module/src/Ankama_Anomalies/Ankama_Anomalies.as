package Ankama_Anomalies {
 import Ankama_Anomalies.ui.AnomaliesUi;
 import flash.display.Sprite;
 import flash.display.DisplayObject;
 import flash.display.DisplayObjectContainer;
 import flash.utils.getDefinitionByName;
 import flash.utils.setTimeout;
 import flash.utils.ByteArray;
 import flash.utils.describeType;
 import flash.utils.getQualifiedClassName;
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
  private var renderListenerInstalled:Boolean;
  private var diagnosticSprite:Sprite;
  public function Ankama_Anomalies(){super();}
  public function main():void { sysApi.log(2,"[ANOMALIES-UI] Diagnostic display list charge (2026-09-22)");setTimeout(install,500); }
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
   if(!module)return;
   var data:Object=module.uis["anomaliesUi"];
   panelFile=data ? data.file : null;
   debugChat("[ANOM-NATIVE] UiData from .dm="+data+", file="+readProperty(data,"file")+", uiClassName="+readProperty(data,"uiClassName")+", uiClass="+readProperty(data,"uiClass"));
   if(!renderListenerInstalled) {
    var renderManagerClass:Object=getDefinitionByName("com.ankamagames.berilia.managers::UiRenderManager");
    var renderEventClass:Object=getDefinitionByName("com.ankamagames.berilia.types.event::UiRenderEvent");
    renderManagerClass.getInstance().addEventListener(renderEventClass.UIRenderComplete,onRenderComplete);
    renderListenerInstalled=true;
   }
  }
  private function togglePanel(...args):void {
   var existing:Object=uiApi.getUi("anomaliesUi");
   if(existing) {
    debugChat("[ANOM-DIAG] Fermeture du panneau anomaliesUi.");
    uiApi.unloadUi("anomaliesUi");
   } else {
    var data:Object=getRegisteredPanel();
    debugChat("[ANOM-DIAG] Ouverture. Classe declaree="+readProperty(data,"uiClass")+", fichier="+readProperty(data,"file"));
    var loaded:Object=uiApi.loadUi("anomaliesUi","anomaliesUi");
    debugChat("[ANOM-DIAG] loadUi retourne="+loaded);
    setTimeout(reportLoadedController,500);
   }
  }
  private function reportLoadedController():void {
   var panel:Object=uiApi.getUi("anomaliesUi");
   if(!panel) {
    debugChat("[ANOM-DIAG] ECHEC : anomaliesUi introuvable 500 ms apres loadUi.");
    return;
   }
   debugChat("[ANOM-DIAG] Panneau charge. uiClass="+readNestedProperty(panel,"uiData","uiClass")+", instance="+qualifiedName(readProperty(panel,"uiClass")));
  }
  private function getRegisteredPanel():Object {
   var managerClass:Object=getDefinitionByName("com.ankamagames.berilia.managers::UiModuleManager");
   var module:Object=managerClass.getInstance().getModule("Ankama_Anomalies");
   return module ? module.uis["anomaliesUi"] : null;
  }
  private function onRenderComplete(event:Object):void {
   try {
    debugChat("[ANOM-TRACE 09] ENTER UIRenderComplete");
    var renderer:Object=readProperty(event,"uiRenderer");
    var uiTarget:Object=readProperty(event,"uiTarget");
    var uiData:Object=readProperty(uiTarget,"uiData");
    debugChat("[TRACE09] event.target="+readProperty(event,"target"));
    debugChat("[TRACE09] event.currentTarget="+readProperty(event,"currentTarget"));
    debugChat("[TRACE09] uiName="+readProperty(uiTarget,"name"));
    debugChat("[TRACE09] uiId="+readProperty(uiData,"name"));
    debugChat("[TRACE09] renderer="+renderer);
    debugChat("[TRACE09] renderer.script="+readProperty(renderer,"script"));
    debugChat("[TRACE09] renderer.uiData="+readProperty(renderer,"uiData"));
    debugChat("[TRACE09] renderer.uiData.name="+readNestedProperty(renderer,"uiData","name"));
    debugChat("[TRACE09] renderer.uiData.file="+readNestedProperty(renderer,"uiData","file"));
    debugChat("[TRACE09] renderer.uiData.uiClass="+readNestedProperty(renderer,"uiData","uiClass"));
    debugChat("[TRACE09] uiTarget.uiData="+uiData+", name="+readProperty(uiData,"name")+", file="+readProperty(uiData,"file")+", uiClass="+readProperty(uiData,"uiClass"));
    if(event.uiTarget && event.uiTarget.name=="anomaliesUi_DIAG_001") {
     sysApi.log(2,"[ANOMALIES-UI] Panel rendu : "+getQualifiedClassName(event.uiTarget.uiClass));
     var root:Object=uiApi.getUi("anomaliesUi_DIAG_001");
     debugChat("[ANOMALIES-DISPLAY] ROOT "+describeDisplay(root)+", stage="+(root && root.stage ? describeDisplay(root.stage) : "NULL"));
     dumpParentChain(root);
     if(root) {
      diagnosticSprite=new Sprite();
      diagnosticSprite.name="anomaliesDirectMagentaTest";
      diagnosticSprite.graphics.beginFill(0xFF00FF,1);
      diagnosticSprite.graphics.drawRect(0,0,500,500);
      diagnosticSprite.graphics.endFill();
      diagnosticSprite.x=300;
      diagnosticSprite.y=200;
      root.addChild(diagnosticSprite);
      debugChat("[ANOMALIES-DISPLAY] SPRITE AJOUTE "+describeDisplay(diagnosticSprite)+", stage="+(diagnosticSprite.stage ? describeDisplay(diagnosticSprite.stage) : "NULL"));
      dumpDisplayTree(DisplayObject(root),0);
     }
    }
   } catch(error:Error) {
    debugChat("[ANOMALIES-UI] ERREUR EVENT COMPLETE : "+error.name+" - "+error.message+"\n"+error.getStackTrace());
   }
  }
  private function describeDisplay(display:Object):String {
   if(!display) return "NULL";
   var parentName:String=display.parent ? (display.parent.name+":"+getQualifiedClassName(display.parent)) : "NULL";
   var children:String=display is DisplayObjectContainer ? ", children="+DisplayObjectContainer(display).numChildren : "";
   return "name="+display.name+", class="+getQualifiedClassName(display)+", x="+display.x+", y="+display.y+", w="+display.width+", h="+display.height+", visible="+display.visible+", alpha="+display.alpha+", scaleX="+display.scaleX+", scaleY="+display.scaleY+", parent="+parentName+children;
  }
  private function dumpParentChain(display:Object):void {
   var current:Object=display;
   var depth:int=0;
   while(current && depth<20) {
    debugChat("[ANOMALIES-PARENT "+depth+"] "+describeDisplay(current)+", stage="+(current.stage ? getQualifiedClassName(current.stage) : "NULL"));
    current=current.parent;
    depth++;
   }
  }
  private function dumpDisplayTree(display:DisplayObject,depth:int):void {
   if(!display || depth>6) return;
   var prefix:String="";
   for(var p:int=0;p<depth;p++) prefix+="  ";
   debugChat("[ANOMALIES-TREE] "+prefix+describeDisplay(display));
   if(display is DisplayObjectContainer) {
    var container:DisplayObjectContainer=DisplayObjectContainer(display);
    for(var i:int=0;i<container.numChildren;i++) dumpDisplayTree(container.getChildAt(i),depth+1);
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
  private function checkDiagnosticPanel():void {
   try {
    var diag:Object=uiApi.getUi("anomaliesUi_DIAG_001");
    debugChat("[ANOM-TRACE 11] getUi DIAG="+diag);
    traceRoot("[ANOM-TRACE 11] diag",diag);
   } catch(error:Error) {
    debugChat("[ANOM-TRACE 11] ERREUR="+error.message);
   }
  }
  private function traceRoot(prefix:String,root:Object):void {
   debugChat(prefix+".stage="+readProperty(root,"stage"));
   debugChat(prefix+".parent="+readProperty(root,"parent"));
   debugChat(prefix+".numChildren="+readProperty(root,"numChildren"));
   debugChat(prefix+".visible="+readProperty(root,"visible"));
   debugChat(prefix+".alpha="+readProperty(root,"alpha"));
   debugChat(prefix+".width="+readProperty(root,"width"));
   debugChat(prefix+".height="+readProperty(root,"height"));
  }
  private function readProperty(object:Object,property:String):* {
   if(!object) return null;
   try { return object[property]; }
   catch(error:Error) { return "<indisponible: "+error.message+">"; }
  }
  private function readNestedProperty(object:Object,first:String,second:String):* {
   var nested:*=readProperty(object,first);
   if(!nested || nested is String) return nested;
   return readProperty(nested,second);
  }
  private function qualifiedName(value:Object):String {
   if(!value) return "null";
   try { return getQualifiedClassName(value); }
   catch(error:Error) { return "<indisponible: "+error.message+">"; }
   return "<indisponible>";
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
