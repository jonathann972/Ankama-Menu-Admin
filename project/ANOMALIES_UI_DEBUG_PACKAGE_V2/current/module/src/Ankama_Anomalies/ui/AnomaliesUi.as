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
  public var ctr_tab_active:Object;
  public var ctr_anomalies_content:Object;
  public var lbl_section_message:Object;
  public var btn_tab_anomalies:Object;
  public var btn_tab_fusion:Object;
  public var btn_tab_catalogue:Object;
  public var btn_tab_effects:Object;
  public var btn_tab_history:Object;
  public var btn_tab_guide:Object;
  public var btn_page_prev:Object;
  public var btn_page_next:Object;
  public var lbl_page:Object;
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
  private var page:int=0;
  private static const PAGE_SIZE:int=20;
  public function main(...args):void {
   debugChat("[ANOMALIES-UI] Classe UI initialisee.");
   if(lbl_smoke_title) {
    if(btn_close) uiApi.addComponentHook(btn_close,"onRelease");
    debugChat("[ANOMALIES-UI] Smoke UI main() termine avec succes.");
    return;
   }
   try {
    debugChat("[ANOMALIES-UI] Composants grid="+gd_anomalies+", search="+inp_search+", equip="+btn_equip+", close="+btn_close);
    uiApi.addComponentHook(gd_anomalies,"onSelectItem");
    uiApi.addComponentHook(gd_anomalies,"onItemRollOver");
    uiApi.addComponentHook(gd_anomalies,"onItemRollOut");
    uiApi.addComponentHook(btn_equip,"onRelease");
    uiApi.addComponentHook(btn_close,"onRelease");
    uiApi.addComponentHook(btn_tab_anomalies,"onRelease");
    uiApi.addComponentHook(btn_tab_fusion,"onRelease");
    uiApi.addComponentHook(btn_tab_catalogue,"onRelease");
    uiApi.addComponentHook(btn_tab_effects,"onRelease");
    uiApi.addComponentHook(btn_tab_history,"onRelease");
    uiApi.addComponentHook(btn_tab_guide,"onRelease");
    uiApi.addComponentHook(btn_page_prev,"onRelease");
    uiApi.addComponentHook(btn_page_next,"onRelease");
    debugChat("[ANOMALIES-UI] Hooks installes.");
    refresh();
    debugChat("[ANOMALIES-UI] Donnees affichees.");
   } catch(error:Error) {
     debugChat("[ANOMALIES-UI] ERREUR INIT : "+error.name+" - "+error.message+"\n"+error.getStackTrace());
   }
  }
  private function debugChat(message:String):void {try {var hooks:Object=getDefinitionByName("com.ankamagames.dofus.misc.lists::ChatHookList");sysApi.dispatchHook(hooks.TextInformation,message,666,0);}catch(ignore:Error){sysApi.log(4,message);}}
  private function refresh():void {
   var i:Object;
   all=inventoryApi.getStorageObjectsByType(TYPE);
   if(!all)all=[];
   active=null;
   for each(i in all)if(fx(i,ACTIVE)>0)active=i;
   filter();if(slot_equipped)slot_equipped.data=active;lbl_empty.visible=all.length==0;
   if(!selected&&all.length)selected=all[0];details();
  }
  private function filter():void {var a:Array=[];var i:Object;var q:String=inp_search&&inp_search.text?inp_search.text.toLowerCase():"";for each(i in all)if(!q.length||i.name.toLowerCase().indexOf(q)>=0)a.push(i);var pages:int=Math.max(1,Math.ceil(a.length/PAGE_SIZE));if(page>=pages)page=pages-1;gd_anomalies.dataProvider=a.slice(page*PAGE_SIZE,Math.min(a.length,(page+1)*PAGE_SIZE));lbl_page.text=(page+1)+" / "+pages;btn_page_prev.disabled=page<=0;btn_page_next.disabled=page>=pages-1;}
  private function fx(i:Object,id:uint):int {var e:Object;if(!i||!i.effects)return 0;for each(e in i.effects)if(e.effectId==id)return int(e.value);return 0;}
  private function details():void {
   slot_selected.data=selected;
   if(!selected){lbl_name.text="S\u00e9lectionnez une Anomalie";btn_equip.disabled=true;return;}
   var c:Number=fx(selected,CHANCE)/10;var p:int=fx(selected,POWER);var cs:String=c.toFixed(1).replace(".",",");var on:Boolean=active&&active.objectUID==selected.objectUID;
   lbl_name.text="<font color='#EA74FF'><b>\u00c9cho</b></font>";lbl_rarity.text="<font color='#EA74FF'><b>\u00c9pique</b></font>";lbl_level.text="<font color='#E8E2D2'>Niveau "+selected.level+"</font>";
   lbl_rolls.text="<font color='#F0C95C'><b>Jets de l'Anomalie</b></font><br/><br/><font color='#F2EEE3'>Chance de r\u00e9p\u00e9tition : </font><font color='#6EEB7B'><b>"+cs+" %</b></font> <font color='#A6A6A6'>(17-20 %)</font><br/><font color='#F2EEE3'>Puissance de l'\u00c9cho : </font><font color='#6EEB7B'><b>"+p+" %</b></font> <font color='#A6A6A6'>(40-60 %)</font>";
   lbl_lore.text="<i><font color='#C4BFB5'>Une r\u00e9sonance violette venue d'ailleurs.<br/>Le Wakfu semble se souvenir de ce que vous avez d\u00e9j\u00e0 fait.</font></i>";
   lbl_effect.text="<font color='#F0C95C'><b>Effet actuel</b></font><br/><br/><font color='#F2EEE3'>Le premier sort offensif \u00e9ligible lanc\u00e9 chaque tour poss\u00e8de </font><font color='#6EEB7B'><b>"+cs+" %</b></font><font color='#F2EEE3'> de chance de produire un \u00c9cho \u00e0 </font><font color='#6EEB7B'><b>"+p+" %</b></font><font color='#F2EEE3'> de sa puissance.</font>";
   btn_equip.disabled=false;
  }
  private function sendCommand(command:String):void {var actionClass:Object=getDefinitionByName("com.ankamagames.dofus.logic.game.common.actions.chat.ChatTextOutputAction");sysApi.sendAction(actionClass.create(command));}
  public function onSelectItem(t:Object,m:uint,n:Boolean):void {if(t.selectedItem){selected=t.selectedItem;details();}}
  public function onItemRollOver(t:Object,i:Object):void {if(i&&i.data)uiApi.showTooltip(i.data,i.container,false,"standard",7,1,3,"itemName",null,{"showEffects":true});}
  public function onItemRollOut(t:Object,i:Object):void {uiApi.hideTooltip();}
  public function onTextChange(t:Object):void {filter();}
  private function showSection(index:int,title:String):void {
   ctr_tab_active.y=101+index*56;
   ctr_anomalies_content.visible=index==0;
   lbl_section_message.visible=index!=0;
   if(index!=0)lbl_section_message.text=title+"\nCette section sera disponible dans une prochaine version.";
  }
  public function onRelease(t:Object):void {
   if(t==btn_close){uiApi.unloadUi("anomaliesUi");return;}
   if(t==btn_tab_anomalies){showSection(0,"");return;}
   if(t==btn_tab_fusion){showSection(1,"Fusion");return;}
   if(t==btn_tab_catalogue){showSection(2,"Catalogue");return;}
   if(t==btn_tab_effects){showSection(3,"Effets");return;}
   if(t==btn_tab_history){showSection(4,"Historique");return;}
   if(t==btn_tab_guide){showSection(5,"Guide");return;}
   if(t==btn_page_prev){if(page>0){page--;filter();}return;}
   if(t==btn_page_next){page++;filter();return;}
   if(t==btn_equip&&selected){sendCommand(active&&active.objectUID==selected.objectUID?"/anomaly off":"/anomaly "+selected.objectUID);active=active&&active.objectUID==selected.objectUID?null:selected;if(slot_equipped)slot_equipped.data=active;details();}
  }
 }
}
