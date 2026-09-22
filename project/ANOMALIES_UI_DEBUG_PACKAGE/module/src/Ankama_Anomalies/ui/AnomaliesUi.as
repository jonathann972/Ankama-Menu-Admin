package Ankama_Anomalies.ui {
 import flash.utils.getDefinitionByName;
 public class AnomaliesUi {
  private static const TYPE:uint=290;
  private static const CHANCE:uint=3100;
  private static const POWER:uint=3101;
  private static const ACTIVE:uint=3102;
  [Api(name="SystemApi")] public var sysApi:Object;
  [Api(name="UiApi")] public var uiApi:Object;
  [Api(name="InventoryApi")] public var inventoryApi:Object;
  public var mainCtr:Object;
  public var tx_background:Object;
  public var lbl_smoke_title:Object;
  public var lbl_smoke_body:Object;
  public var gd_anomalies:Object;
  public var inp_search:Object;
  public var slot_selected:Object;
  public var slot_equipped:Object;
  public var btn_equip:Object;
  public var btn_close:Object;
  public var lbl_empty:Object;
  public var lbl_name:Object;
  public var lbl_rarity:Object;
  public var lbl_level:Object;
  public var lbl_rolls:Object;
  public var lbl_lore:Object;
  public var lbl_effect:Object;
  public var lbl_btn_equip:Object;
  private var all:Array=[];
  private var selected:Object;
  private var active:Object;
  public function main(...args):void {
   debugChat("[ANOMALIES-UI] Classe UI initialisee.");
   try {
    debugChat("[ANOMALIES-UI] Composants grid="+gd_anomalies+", search="+inp_search+", equip="+btn_equip+", close="+btn_close);
    uiApi.addComponentHook(gd_anomalies,"onSelectItem");
    uiApi.addComponentHook(gd_anomalies,"onItemRollOver");
    uiApi.addComponentHook(gd_anomalies,"onItemRollOut");
    uiApi.addComponentHook(inp_search,"onTextChange");
    uiApi.addComponentHook(btn_equip,"onRelease");
    uiApi.addComponentHook(btn_close,"onRelease");
    debugChat("[ANOMALIES-UI] Hooks installes.");
    refresh();
    debugChat("[ANOMALIES-UI] Donnees affichees.");
   } catch(error:Error) {
    debugChat("[ANOMALIES-UI] ERREUR INIT : "+error.name+" - "+error.message);
   }
  }
  private function debugChat(message:String):void {try {var hooks:Object=getDefinitionByName("com.ankamagames.dofus.misc.lists::ChatHookList");sysApi.dispatchHook(hooks.TextInformation,message,666,0);}catch(ignore:Error){sysApi.log(4,message);}}
  private function refresh():void {
   var i:Object;
   all=inventoryApi.getStorageObjectsByType(TYPE);
   if(!all)all=[];
   active=null;
   for each(i in all)if(fx(i,ACTIVE)>0)active=i;
   filter();slot_equipped.data=active;lbl_empty.visible=all.length==0;
   if(!selected&&all.length)selected=all[0];details();
  }
  private function filter():void {var a:Array=[];var i:Object;var q:String=inp_search.text.toLowerCase();for each(i in all)if(!q.length||i.name.toLowerCase().indexOf(q)>=0)a.push(i);gd_anomalies.dataProvider=a;}
  private function fx(i:Object,id:uint):int {var e:Object;if(!i||!i.effects)return 0;for each(e in i.effects)if(e.effectId==id)return int(e.value);return 0;}
  private function details():void {
   slot_selected.data=selected;
   if(!selected){lbl_name.text="S\u00e9lectionnez une Anomalie";btn_equip.disabled=true;return;}
   var c:Number=fx(selected,CHANCE)/10;var p:int=fx(selected,POWER);var cs:String=c.toFixed(1).replace(".",",");var on:Boolean=active&&active.objectUID==selected.objectUID;
   lbl_name.text="<font color='#D65CFF'><b>\u00c9cho</b></font>";lbl_rarity.text="<font color='#D65CFF'>\u00c9pique</font>";lbl_level.text="Niveau "+selected.level;
   lbl_rolls.text="<font color='#E8C34A'><b>Jets de l'Anomalie</b></font><br/><br/>Chance de r\u00e9p\u00e9tition : <font color='#67D65C'><b>"+cs+" %</b></font> <font color='#929292'>(17-20 %)</font><br/>Puissance de l'\u00c9cho : <font color='#67D65C'><b>"+p+" %</b></font> <font color='#929292'>(40-60 %)</font>";
   lbl_lore.text="<i><font color='#A8A8A8'>Une r\u00e9sonance violette venue d'ailleurs.<br/>Le Wakfu semble se souvenir de ce que vous avez d\u00e9j\u00e0 fait.</font></i>";
   lbl_effect.text="<font color='#E8C34A'><b>Effet actuel</b></font><br/><br/>Le premier sort offensif \u00e9ligible lanc\u00e9 chaque tour poss\u00e8de <font color='#67D65C'><b>"+cs+" %</b></font> de chance de produire un \u00c9cho \u00e0 <font color='#67D65C'><b>"+p+" %</b></font> de sa puissance.";
   btn_equip.label=on?"D\u00e9s\u00e9quiper":"\u00c9quiper";btn_equip.disabled=false;
  }
  private function sendCommand(command:String):void {var actionClass:Object=getDefinitionByName("com.ankamagames.dofus.logic.game.common.actions.chat.ChatTextOutputAction");sysApi.sendAction(actionClass.create(command));}
  public function onSelectItem(t:Object,m:uint,n:Boolean):void {if(t.selectedItem){selected=t.selectedItem;details();}}
  public function onItemRollOver(t:Object,i:Object):void {if(i&&i.data)uiApi.showTooltip(i.data,i.container,false,"standard",7,1,3,"itemName",null,{"showEffects":true});}
  public function onItemRollOut(t:Object,i:Object):void {uiApi.hideTooltip();}
  public function onTextChange(t:Object):void {filter();}
  public function onRelease(t:Object):void {if(t==btn_close){uiApi.unloadUi("anomaliesUi");return;}if(t==btn_equip&&selected){sendCommand(active&&active.objectUID==selected.objectUID?"/anomaly off":"/anomaly "+selected.objectUID);active=active&&active.objectUID==selected.objectUID?null:selected;slot_equipped.data=active;details();}}
 }
}
