package Ankama_Anomalies.ui
{
 import flash.utils.getDefinitionByName;
 public class AnomaliesUi
 {
  private static const TYPE:uint=290, CHANCE:uint=3100, POWER:uint=3101, ACTIVE:uint=3102;
  private static const PAGE_SIZE:int=10;
  [Api(name="SystemApi")] public var sysApi:Object;
  [Api(name="UiApi")] public var uiApi:Object;
  [Api(name="InventoryApi")] public var inventoryApi:Object;
  public var mainCtr:Object,btn_close:Object,btn_equip:Object,btn_collection_prev:Object,btn_collection_next:Object;
  public var lbl_btn_equip:Object,lbl_collection:Object,lbl_collection_page:Object;
  public var tx_equipped_empty:Object,tx_equipped_active:Object,tx_equipped_icon:Object,tx_detail_icon:Object;
  public var lbl_detail_name:Object,lbl_detail_rarity:Object,lbl_detail_level:Object,lbl_detail_description:Object;
  public var lbl_detail_chance:Object,lbl_detail_chance_max:Object,lbl_detail_power:Object,lbl_detail_power_max:Object;
  public var lbl_detail_category:Object,lbl_detail_source:Object,lbl_detail_date:Object;
  public var tx_collection_locked_0:Object,tx_collection_locked_1:Object,tx_collection_locked_2:Object,tx_collection_locked_3:Object,tx_collection_locked_4:Object;
  public var tx_collection_locked_5:Object,tx_collection_locked_6:Object,tx_collection_locked_7:Object,tx_collection_locked_8:Object,tx_collection_locked_9:Object;
  public var tx_collection_unlocked_0:Object,tx_collection_unlocked_1:Object,tx_collection_unlocked_2:Object,tx_collection_unlocked_3:Object,tx_collection_unlocked_4:Object;
  public var tx_collection_unlocked_5:Object,tx_collection_unlocked_6:Object,tx_collection_unlocked_7:Object,tx_collection_unlocked_8:Object,tx_collection_unlocked_9:Object;
  public var tx_collection_icon_0:Object,tx_collection_icon_1:Object,tx_collection_icon_2:Object,tx_collection_icon_3:Object,tx_collection_icon_4:Object;
  public var tx_collection_icon_5:Object,tx_collection_icon_6:Object,tx_collection_icon_7:Object,tx_collection_icon_8:Object,tx_collection_icon_9:Object;
  public var btn_collection_0:Object,btn_collection_1:Object,btn_collection_2:Object,btn_collection_3:Object,btn_collection_4:Object;
  public var btn_collection_5:Object,btn_collection_6:Object,btn_collection_7:Object,btn_collection_8:Object,btn_collection_9:Object;
  private var catalog:Array,best:Object={},activeItem:Object,selectedDef:Object,selectedItem:Object,page:int=0;
  private var locked:Array,unlocked:Array,icons:Array,buttons:Array;

  public function main(...args):void
  {
   diagnostic("AnomaliesUi.main() exécuté");
   try { createCatalog(); bindComponents(); installHooks(); refreshInventory(); }
   catch(error:Error) { diagnostic("ERREUR initialisation : "+error.name+" - "+error.message); }
  }
  private function createCatalog():void
  {
   var root:String=String(sysApi.getConfigEntry("config.mod.path"))+"Ankama_Anomalies/assets/";
   catalog=[{gid:32760,name:"Écho",rarity:"ANOMALIE ÉPIQUE",level:1,
    description:"« Le premier sort offensif éligible lancé durant le tour peut être répété avec une puissance réduite. »",
    category:"Offensive",source:"Donjon X",icon:root+"echo-64.png",chanceMin:170,chanceMax:200,powerMin:40,powerMax:60}];
   selectedDef=catalog.length?catalog[0]:null;
  }
  private function bindComponents():void
  {
   locked=[tx_collection_locked_0,tx_collection_locked_1,tx_collection_locked_2,tx_collection_locked_3,tx_collection_locked_4,tx_collection_locked_5,tx_collection_locked_6,tx_collection_locked_7,tx_collection_locked_8,tx_collection_locked_9];
   unlocked=[tx_collection_unlocked_0,tx_collection_unlocked_1,tx_collection_unlocked_2,tx_collection_unlocked_3,tx_collection_unlocked_4,tx_collection_unlocked_5,tx_collection_unlocked_6,tx_collection_unlocked_7,tx_collection_unlocked_8,tx_collection_unlocked_9];
   icons=[tx_collection_icon_0,tx_collection_icon_1,tx_collection_icon_2,tx_collection_icon_3,tx_collection_icon_4,tx_collection_icon_5,tx_collection_icon_6,tx_collection_icon_7,tx_collection_icon_8,tx_collection_icon_9];
   buttons=[btn_collection_0,btn_collection_1,btn_collection_2,btn_collection_3,btn_collection_4,btn_collection_5,btn_collection_6,btn_collection_7,btn_collection_8,btn_collection_9];
  }
  private function installHooks():void
  {
   var b:Object;
   uiApi.addComponentHook(btn_close,"onRelease"); uiApi.addComponentHook(btn_equip,"onRelease");
   uiApi.addComponentHook(btn_collection_prev,"onRelease"); uiApi.addComponentHook(btn_collection_next,"onRelease");
   for each(b in buttons) uiApi.addComponentHook(b,"onRelease");
   var h:Object=getDefinitionByName("com.ankamagames.dofus.misc.lists::InventoryHookList");
   sysApi.addHook(h.ObjectAdded,refreshInventory); sysApi.addHook(h.ObjectDeleted,refreshInventory);
   sysApi.addHook(h.ObjectModified,refreshInventory); sysApi.addHook(h.InventoryContent,refreshInventory);
  }
  private function refreshInventory(...args):void
  {
   var item:Object,current:Object,items:Array=inventoryCandidates();
   best={}; activeItem=null; if(!items) items=[];
   for each(item in items)
   {
    current=best[item.objectGID];
    if(!current||isBetter(item,current)) best[item.objectGID]=item;
    if(effect(item,ACTIVE)>0) activeItem=item;
   }
   selectedItem=selectedDef?best[selectedDef.gid]:null; renderAll();
  }
  private function inventoryCandidates():Array
  {
   var result:Array=[],seen:Object={},item:Object,d:Object,seed:Object,typed:Array;
   var configured:Array=inventoryApi.getStorageObjectsByType(TYPE);
   diagnostic("filtre type="+TYPE+" -> "+(configured?configured.length:0)+" objet(s)");
   mergeCandidates(result,seen,configured,"type configuré");
   for each(d in catalog)
   {
    seed=inventoryApi.getItemByGID(uint(d.gid));
    if(!seed)
    {
     diagnostic("GID "+d.gid+" absent via getItemByGID");
     continue;
    }
    diagnostic("GID "+d.gid+" trouvé directement : "+describeItem(seed));
    mergeCandidate(result,seen,seed,"recherche GID");
    typed=inventoryApi.getStorageObjectsByType(uint(seed.typeId));
    diagnostic("type réel="+seed.typeId+" -> "+(typed?typed.length:0)+" objet(s)");
    mergeCandidates(result,seen,typed,"type réel");
   }
   diagnostic("candidats uniques retenus="+result.length);
   return result;
  }
  private function mergeCandidates(target:Array,seen:Object,items:Array,source:String):void
  {
   var item:Object;
   if(!items) return;
   for each(item in items) mergeCandidate(target,seen,item,source);
  }
  private function mergeCandidate(target:Array,seen:Object,item:Object,source:String):void
  {
   if(!item||seen[item.objectUID]) return;
   seen[item.objectUID]=true; target.push(item);
   diagnostic(source+" : "+describeItem(item));
  }
  private function describeItem(item:Object):String
  {
   var values:Array=[],e:Object;
   if(item&&item.effects) for each(e in item.effects) values.push(e.effectId+"="+e.value);
   return "gid="+item.objectGID+", uid="+item.objectUID+", typeId="+item.typeId+", position="+item.position+", effets=["+values.join(",")+"]";
  }
  private function diagnostic(message:String):void
  {
   sysApi.log(2,"[ANOMALIES-INVENTORY] "+message);
   try
   {
    var hooks:Object=getDefinitionByName("com.ankamagames.dofus.misc.lists::ChatHookList");
    sysApi.dispatchHook(hooks.TextInformation,"[ANOMALIES-INVENTORY] "+message,666,0);
   }
   catch(ignore:Error) {}
  }
  private function isBetter(a:Object,b:Object):Boolean
  {
   var d:Object=definition(a.objectGID); if(!d) return false;
   var sa:Number=score(a,d),sb:Number=score(b,d);
   return sa==sb?uint(a.objectUID)<uint(b.objectUID):sa>sb;
  }
  private function score(item:Object,d:Object):Number
  {
   return (effect(item,CHANCE)-d.chanceMin)/(d.chanceMax-d.chanceMin)+(effect(item,POWER)-d.powerMin)/(d.powerMax-d.powerMin);
  }
  private function effect(item:Object,id:uint):int
  {
   var e:Object; if(!item||!item.effects) return 0;
   for each(e in item.effects) if(uint(e.effectId)==id) return int(e.value);
   return 0;
  }
  private function definition(gid:uint):Object
  {
   var d:Object; for each(d in catalog) if(uint(d.gid)==gid) return d; return null;
  }
  private function renderAll():void { renderCollection(); renderDetails(); renderEquipped(); }
  private function renderCollection():void
  {
   var owned:int=0,v:Object,i:int,ci:int,d:Object,item:Object;
   for each(v in best) ++owned;
   lbl_collection.text="Collection "+owned+"/"+catalog.length;
   var pages:int=Math.max(1,Math.ceil(catalog.length/PAGE_SIZE)); if(page>=pages) page=pages-1;
   lbl_collection_page.text=(page+1)+" / "+pages;
   for(i=0;i<PAGE_SIZE;++i)
   {
    ci=page*PAGE_SIZE+i; d=ci<catalog.length?catalog[ci]:null; item=d?best[d.gid]:null;
    locked[i].visible=!item; unlocked[i].visible=Boolean(item); icons[i].visible=Boolean(item); buttons[i].disabled=!d;
    if(item) icons[i].uri=uiApi.createUri(d.icon);
   }
  }
  private function renderDetails():void
  {
   var d:Object=selectedDef,item:Object=selectedItem; if(!d) return;
   tx_detail_icon.uri=uiApi.createUri(d.icon); lbl_detail_name.text=d.name; lbl_detail_rarity.text=d.rarity;
   lbl_detail_level.text="Niveau "+d.level; lbl_detail_description.text=d.description;
   lbl_detail_category.text=d.category; lbl_detail_source.text=d.source; lbl_detail_date.text="—";
   lbl_detail_chance_max.text="/ "+tenths(d.chanceMax)+" %"; lbl_detail_power_max.text="/ "+d.powerMax+" %";
   lbl_detail_chance.text=item?tenths(effect(item,CHANCE))+" %":"—"; lbl_detail_power.text=item?effect(item,POWER)+" %":"—";
   var isActive:Boolean=Boolean(item)&&Boolean(activeItem)&&uint(item.objectUID)==uint(activeItem.objectUID);
   lbl_btn_equip.text=isActive?"DÉSÉQUIPER":"ÉQUIPER"; btn_equip.disabled=!item;
  }
  private function renderEquipped():void
  {
   var d:Object=activeItem?definition(activeItem.objectGID):null;
   tx_equipped_empty.visible=!activeItem; tx_equipped_active.visible=Boolean(activeItem);
   tx_equipped_icon.visible=Boolean(activeItem)&&Boolean(d); if(d) tx_equipped_icon.uri=uiApi.createUri(d.icon);
  }
  private function tenths(v:int):String { return (v/10).toFixed(1).replace(".",","); }
  private function sendCommand(command:String):void
  {
   var action:Object=getDefinitionByName("com.ankamagames.dofus.logic.game.common.actions.chat.ChatTextOutputAction");
   sysApi.sendAction(action.create(command));
  }
  public function onRelease(target:Object):void
  {
   var i:int,pages:int;
   if(target==btn_close) { uiApi.unloadUi("anomaliesUi"); return; }
   if(target==btn_equip&&selectedItem)
   {
    sendCommand(activeItem&&uint(activeItem.objectUID)==uint(selectedItem.objectUID)?"/anomaly off":"/anomaly "+selectedItem.objectUID); return;
   }
   if(target==btn_collection_prev||target==btn_collection_next)
   {
    pages=Math.max(1,Math.ceil(catalog.length/PAGE_SIZE));
    page=target==btn_collection_prev?(page+pages-1)%pages:(page+1)%pages; renderCollection(); return;
   }
   for(i=0;i<buttons.length;++i) if(target==buttons[i]) { selectIndex(page*PAGE_SIZE+i); return; }
  }
  private function selectIndex(index:int):void
  {
   if(index<0||index>=catalog.length) return;
   selectedDef=catalog[index]; selectedItem=best[selectedDef.gid]; renderDetails();
  }
 }
}
