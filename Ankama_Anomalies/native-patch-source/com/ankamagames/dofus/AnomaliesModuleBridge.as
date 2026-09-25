package com.ankamagames.dofus
{
 import flash.utils.getDefinitionByName;
 import com.ankamagames.jerakine.data.XmlConfig;
 import flash.display.Loader;
 import flash.events.Event;
 import flash.net.URLRequest;
 import flash.system.ApplicationDomain;
 import flash.system.LoaderContext;
 public class AnomaliesModuleBridge
 {
  private static const DESCRIPTION_MAX_LENGTH:int=140;
  private static const TYPE:uint=290;
  private static const ACTIVE:uint=3102;
  private static const PAGE_SIZE:int=10;
  [Api(name="SystemApi")] public var sysApi:Object;
  [Api(name="UiApi")] public var uiApi:Object;
  [Api(name="InventoryApi")] public var inventoryApi:Object;
  [Api(name="DataApi")] public var dataApi:Object;
  public var mainCtr:Object;
  public var btn_close:Object;
  public var btn_equip:Object;
  public var btn_collection_prev:Object;
  public var btn_collection_next:Object;
  public var lbl_btn_equip:Object;
  public var lbl_collection:Object;
  public var lbl_collection_page:Object;
  public var tx_equipped_empty:Object;
  public var tx_equipped_active:Object;
  public var tx_equipped_icon:Object;
  public var tx_detail_icon:Object;
  public var lbl_equipped_name:Object;
  public var lbl_equipped_level:Object;
  public var lbl_detail_name:Object;
  public var lbl_detail_rarity:Object;
  public var lbl_detail_level:Object;
  public var lbl_detail_description:Object;
  public var lbl_detail_stat1_name:Object;
  public var lbl_detail_stat2_name:Object;
  public var lbl_detail_chance:Object;
  public var lbl_detail_chance_max:Object;
  public var lbl_detail_power:Object;
  public var lbl_detail_power_max:Object;
  public var lbl_detail_category:Object;
  public var lbl_detail_source:Object;
  public var lbl_detail_date:Object;
  public var tx_collection_locked_0:Object;
  public var tx_collection_locked_1:Object;
  public var tx_collection_locked_2:Object;
  public var tx_collection_locked_3:Object;
  public var tx_collection_locked_4:Object;
  public var tx_collection_locked_5:Object;
  public var tx_collection_locked_6:Object;
  public var tx_collection_locked_7:Object;
  public var tx_collection_locked_8:Object;
  public var tx_collection_locked_9:Object;
  public var tx_collection_unlocked_0:Object;
  public var tx_collection_unlocked_1:Object;
  public var tx_collection_unlocked_2:Object;
  public var tx_collection_unlocked_3:Object;
  public var tx_collection_unlocked_4:Object;
  public var tx_collection_unlocked_5:Object;
  public var tx_collection_unlocked_6:Object;
  public var tx_collection_unlocked_7:Object;
  public var tx_collection_unlocked_8:Object;
  public var tx_collection_unlocked_9:Object;
  public var tx_collection_icon_0:Object;
  public var tx_collection_icon_1:Object;
  public var tx_collection_icon_2:Object;
  public var tx_collection_icon_3:Object;
  public var tx_collection_icon_4:Object;
  public var tx_collection_icon_5:Object;
  public var tx_collection_icon_6:Object;
  public var tx_collection_icon_7:Object;
  public var tx_collection_icon_8:Object;
  public var tx_collection_icon_9:Object;
  public var btn_collection_0:Object;
  public var btn_collection_1:Object;
  public var btn_collection_2:Object;
  public var btn_collection_3:Object;
  public var btn_collection_4:Object;
  public var btn_collection_5:Object;
  public var btn_collection_6:Object;
  public var btn_collection_7:Object;
  public var btn_collection_8:Object;
  public var btn_collection_9:Object;
  private var catalog:Array;
  private var best:Object = {};
  private var activeItem:Object;
  private var selectedDef:Object;
  private var selectedItem:Object;
  private var page:int = 0;
  private var locked:Array;
  private var unlocked:Array;
  private var icons:Array;
  private var buttons:Array;
  private var module:Object;
  private var loader:Loader;

  public function main(...args):void
  {
   var path:String;
   var context:LoaderContext;
   try
   {
    if(lbl_collection)
    {
     diagnostic("Contrôleur Berilia exécuté");
     createCatalog(); bindComponents(); installHooks(); refreshInventory();
     return;
    }
    loader=new Loader(); loader.contentLoaderInfo.addEventListener(Event.COMPLETE,onModuleLoaded);
    path=XmlConfig.getInstance().getEntry("config.mod.path")+"Ankama_Anomalies/Ankama_Anomalies.swf";
    context=new LoaderContext(false,ApplicationDomain.currentDomain); loader.load(new URLRequest(path),context);
   }
   catch(error:Error) { diagnostic("ERREUR initialisation : "+error.name+" - "+error.message); }
  }
  private function onModuleLoaded(event:Event):void
  {
   var moduleClass:Class;
   try
   {
    moduleClass=ApplicationDomain.currentDomain.getDefinition("Ankama_Anomalies.Ankama_Anomalies") as Class;
    module=new moduleClass(); module.uiApi=uiApi; module.sysApi=sysApi; module.dataApi=dataApi; module.inventoryApi=inventoryApi;
    module.main(); sysApi.log(2,"[ANOMALIES-UI] Module externe chargé dans le domaine principal");
   }
   catch(error:Error) { sysApi.log(4,"[ANOMALIES-UI] ERREUR CHARGEMENT: "+error.message+" / "+error.getStackTrace()); }
  }
  private function createCatalog():void
  {
   var root:String=String(sysApi.getConfigEntry("config.mod.path"))+"Ankama_Anomalies/assets/";
   catalog=[
    {gid:32760,name:"Écho",rarity:"ANOMALIE ÉPIQUE",level:1,description:"« Le premier sort offensif éligible lancé durant le tour peut être répété avec une puissance réduite. »",category:"Offensive",source:"Donjon X",icon:root+"echo-64.png",stat1Name:"Chance de répétition",stat1Id:3100,stat1Min:170,stat1Max:200,stat1Scale:10,stat1Suffix:" %",stat2Name:"Puissance de l'écho",stat2Id:3101,stat2Min:40,stat2Max:60,stat2Scale:1,stat2Suffix:" %"},
    {gid:32761,name:"Rémanence",rarity:"ANOMALIE ÉPIQUE",level:1,description:"« À la fin de votre tour, Rémanence peut conserver une partie de vos PA inutilisés pour votre prochain tour. »",category:"Utilitaire",source:"Donjon X",icon:root+"Remanence_64x64.png",stat1Name:"Chance de rémanence",stat1Id:3103,stat1Min:150,stat1Max:250,stat1Scale:10,stat1Suffix:" %",stat2Name:"PA conservés",stat2Id:3104,stat2Min:1,stat2Max:2,stat2Scale:1,stat2Suffix:""},
    {gid:32762,name:"Toison",rarity:"ANOMALIE COMMUNE",level:6,description:"« Après avoir subi des dégâts de mêlée, Toison peut restaurer une petite partie des points de vie perdus. »",category:"Mêlée",source:"Bouftou Royal",icon:root+"Toison_64x64.png",stat1Name:"Chance de déclenchement",stat1Id:3105,stat1Min:150,stat1Max:250,stat1Scale:10,stat1Suffix:" %",stat2Name:"PV perdus restaurés",stat2Id:3106,stat2Min:10,stat2Max:20,stat2Scale:1,stat2Suffix:" %"},
    {gid:32764,name:"Rétribut",rarity:"ANOMALIE RARE",level:8,description:"La première attaque directe reçue peut déclencher une riposte réduite sur l'attaquant. Une seule tentative par tour.",category:"Anomalie",source:"Maître Corbac",icon:root+"Retribut_64x64.png",stat1Name:"Chance de riposte",stat1Id:3109,stat1Min:150,stat1Max:250,stat1Scale:10,stat1Suffix:" %",stat2Name:"Puissance de la riposte",stat2Id:3110,stat2Min:20,stat2Max:30,stat2Scale:1,stat2Suffix:" %"},
    {gid:32765,name:"Dédale",rarity:"ANOMALIE RARE",level:6,description:"Après un déplacement forcé subi, Dédale peut se déclencher et accorde temporairement de l'Esquive PM ainsi qu'une charge de mobilité. Limite : une tentative par tour.",category:"Anomalie",source:"Minotoror",icon:root+"Dedale_64x64.png",stat1Name:"Chance de déclenchement",stat1Id:3111,stat1Min:150,stat1Max:250,stat1Scale:10,stat1Suffix:" %",stat2Name:"Esquive PM",stat2Id:3112,stat2Min:10,stat2Max:20,stat2Scale:1,stat2Suffix:""},
    {gid:32766,name:"Méphitique",rarity:"ANOMALIE RARE",level:10,description:"Perdre des PA peut contaminer l'attaquant avec un poison léger. Le contrecoup dépend des PA dépensés par la cible contaminée et reste plafonné afin d'éviter un effet disproportionné.",category:"Anomalie",source:"Dragon Cochon",icon:root+"Mephitique_64x64.png",stat1Name:"Chance de contamination",stat1Id:3113,stat1Min:150,stat1Max:250,stat1Scale:10,stat1Suffix:" %",stat2Name:"Puissance du poison",stat2Id:3114,stat2Min:10,stat2Max:20,stat2Scale:1,stat2Suffix:" %"},
    {gid:32767,name:"Éruption",rarity:"ANOMALIE ÉPIQUE",level:8,description:"Alterner des éléments remplit une jauge volcanique. Chaque action valide ajoute 1 charge, jusqu'à 3. À 3 charges, la prochaine action concernée consomme les charges et déclenche une décharge.",category:"Anomalie",source:"Crocabulia",icon:root+"Eruption_64x64.png",stat1Name:"Puissance de la décharge",stat1Id:3115,stat1Min:20,stat1Max:30,stat1Scale:1,stat1Suffix:" %",stat2Name:"",stat2Id:0,stat2Min:0,stat2Max:0,stat2Scale:1,stat2Suffix:""},
    {gid:32768,name:"Germiner",rarity:"ANOMALIE COMMUNE",level:8,description:"Finir un tour sans avoir subi de dégâts fait germer un soin au début du tour suivant. L'effet ne se déclenche qu'une seule fois et ne peut pas s'alimenter lui-même.",category:"Anomalie",source:"Tournesol Affamé",icon:root+"Germiner_64x64.png",stat1Name:"Puissance du soin",stat1Id:3116,stat1Min:5,stat1Max:10,stat1Scale:1,stat1Suffix:" %",stat2Name:"",stat2Id:0,stat2Min:0,stat2Max:0,stat2Scale:1,stat2Suffix:""},
    {gid:32769,name:"Paralysie",rarity:"ANOMALIE RARE",level:9,description:"Les PA dépensés par une cible empoisonnée augmentent son contrecoup, avec un plafond afin qu'un tour disposant de beaucoup de PA ne produise pas un effet disproportionné.",category:"Anomalie",source:"Abraknyde Ancestral",icon:root+"Paralysie_64x64.png",stat1Name:"Puissance par PA dépensé",stat1Id:3117,stat1Min:2,stat1Max:4,stat1Scale:1,stat1Suffix:" %",stat2Name:"",stat2Id:0,stat2Min:0,stat2Max:0,stat2Scale:1,stat2Suffix:""},
    {gid:32770,name:"Ramifier",rarity:"ANOMALIE ÉPIQUE",level:8,description:"Un sort monocible peut semer une copie très réduite de ses dégâts sur un ennemi adjacent à la cible principale.",category:"Anomalie",source:"Chêne Mou",icon:root+"Ramifier_64x64.png",stat1Name:"Chance de ramification",stat1Id:3118,stat1Min:150,stat1Max:250,stat1Scale:10,stat1Suffix:" %",stat2Name:"Dégâts de ramification",stat2Id:3119,stat2Min:15,stat2Max:25,stat2Scale:1,stat2Suffix:" %"},
    {gid:32771,name:"Chromatis",rarity:"ANOMALIE RARE",level:9,description:"Deux éléments différents utilisés à la suite accordent un bonus temporaire propre au second élément, jusqu'à la fin du tour.",category:"Anomalie",source:"Blop Multicolore Royal",icon:root+"Chromatis_64x64.png",stat1Name:"Puissance du bonus élémentaire",stat1Id:3120,stat1Min:10,stat1Max:20,stat1Scale:1,stat1Suffix:" %",stat2Name:"",stat2Id:0,stat2Min:0,stat2Max:0,stat2Scale:1,stat2Suffix:""},
    {gid:32772,name:"Brutalité",rarity:"ANOMALIE COMMUNE",level:9,description:"Après une attaque de mêlée, une faible chance permet de préparer un bonus de puissance. Le bonus est appliqué au début du prochain tour et disparaît à la fin de celui-ci.",category:"Anomalie",source:"Bworkette",icon:root+"Brutalite_64x64.png",stat1Name:"Chance de déclenchement",stat1Id:3121,stat1Min:100,stat1Max:200,stat1Scale:10,stat1Suffix:" %",stat2Name:"Puissance au prochain tour",stat2Id:3122,stat2Min:20,stat2Max:40,stat2Scale:1,stat2Suffix:" %"},
    {gid:32773,name:"Poursuite",rarity:"ANOMALIE ÉPIQUE",level:9,description:"Sous 75 % de PV, gagne un bonus offensif croissant. Il augmente sous 50 % puis 25 %, et diminue lorsque les PV remontent.",category:"Anomalie",source:"Bworker",icon:root+"Poursuite_64x64.png",stat1Name:"Puissance par palier",stat1Id:3123,stat1Min:10,stat1Max:20,stat1Scale:1,stat1Suffix:" %",stat2Name:"",stat2Id:0,stat2Min:0,stat2Max:0,stat2Scale:1,stat2Suffix:""},
    {gid:32774,name:"Frénésie",rarity:"ANOMALIE RARE",level:8,description:"La troisième attaque directe contre la même cible pendant un tour reçoit le bonus. Changer de cible remet le compteur à zéro. Maximum 1 bonus par tour.",category:"Anomalie",source:"Meulou",icon:root+"Frenesie_64x64.png",stat1Name:"Puissance de l'effet",stat1Id:3124,stat1Min:10,stat1Max:20,stat1Scale:1,stat1Suffix:" %",stat2Name:"Puissance offensive",stat2Id:3125,stat2Min:10,stat2Max:20,stat2Scale:1,stat2Suffix:" %"},
    {gid:32775,name:"BondRoyal",rarity:"ANOMALIE COMMUNE",level:9,description:"Après avoir dépensé au moins 5 PM dans le tour, prépare +1 PM pour le tour suivant. Maximum 1 fois par tour ; le PM temporaire disparaît en fin de tour.",category:"Anomalie",source:"Wa Wabbit",icon:root+"BondRoyal_64x64.png",stat1Name:"Bonus par PM / case",stat1Id:3126,stat1Min:2,stat1Max:4,stat1Scale:1,stat1Suffix:" %",stat2Name:"",stat2Id:0,stat2Min:0,stat2Max:0,stat2Scale:1,stat2Suffix:""},
    {gid:32776,name:"Monolithe",rarity:"ANOMALIE COMMUNE",level:9,description:"Si aucun PM n'a été dépensé pendant le tour, gagne une réduction de dégâts jusqu'au début du prochain tour. Le bonus disparaît immédiatement après un déplacement volontaire.",category:"Anomalie",source:"Craqueleur Légendaire",icon:root+"Monolithe_64x64.png",stat1Name:"Réduction / protection",stat1Id:3127,stat1Min:5,stat1Max:10,stat1Scale:1,stat1Suffix:" %",stat2Name:"Puissance offensive",stat2Id:3128,stat2Min:10,stat2Max:20,stat2Scale:1,stat2Suffix:" %"}
   ];
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
   var item:Object;
   var current:Object;
   var items:Array=inventoryCandidates();
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
   var result:Array=[];
   var seen:Object={};
   var item:Object;
   var d:Object;
   var seed:Object;
   var typed:Array;
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
   if(!item||!definition(uint(item.objectGID))||seen[item.objectUID]) return;
   seen[item.objectUID]=true; target.push(item);
   diagnostic(source+" : "+describeItem(item));
  }
  private function describeItem(item:Object):String
  {
   var values:Array=[];
   var e:Object;
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
   var sa:Number=score(a,d);
   var sb:Number=score(b,d);
   return sa==sb?uint(a.objectUID)<uint(b.objectUID):sa>sb;
  }
  private function score(item:Object,d:Object):Number
  {
   var result:Number=(effect(item,d.stat1Id)-d.stat1Min)/Math.max(1,d.stat1Max-d.stat1Min);
   if(uint(d.stat2Id)>0) result+=(effect(item,d.stat2Id)-d.stat2Min)/Math.max(1,d.stat2Max-d.stat2Min);
   return result;
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
  private function rarityColor(rarity:String):String
  {
   var value:String=rarity?rarity.toUpperCase():"";
   if(value.indexOf("LÉGENDAIRE")>=0||value.indexOf("LEGENDAIRE")>=0) return "#FF9D3D";
   if(value.indexOf("MYTHIQUE")>=0) return "#FF4D5A";
   if(value.indexOf("ÉPIQUE")>=0||value.indexOf("EPIQUE")>=0) return "#D65CFF";
   if(value.indexOf("INHABITUELLE")>=0||value.indexOf("PEU COMMUNE")>=0) return "#62D26F";
   if(value.indexOf("RARE")>=0) return "#4EA5FF";
   if(value.indexOf("COMMUNE")>=0) return "#B8B8B8";
   if(value.indexOf("UNIQUE")>=0) return "#45D6C8";
   return "#E8C34A";
  }
  private function rarityMarkup(rarity:String):String
  {
   return "<font color='"+rarityColor(rarity)+"'><b>"+rarity+"</b></font>";
  }
  private function displayDescription(value:String):String
  {
   if(!value||value.length<=DESCRIPTION_MAX_LENGTH) return value;
   return value.substr(0,DESCRIPTION_MAX_LENGTH-1).replace(/\s+\S*$/g,"")+"…";
  }
  private function renderAll():void { renderCollection(); renderDetails(); renderEquipped(); }
  private function renderCollection():void
  {
   var owned:int=0;
   var v:Object;
   var i:int;
   var ci:int;
   var d:Object;
   var item:Object;
   for each(v in best) ++owned;
   lbl_collection.text="Collection "+owned+"/"+catalog.length;
   var pages:int=Math.max(1,Math.ceil(catalog.length/PAGE_SIZE)); if(page>=pages) page=pages-1;
   lbl_collection_page.text=(page+1)+" / "+pages;
   for(i=0;i<PAGE_SIZE;++i)
   {
    ci=page*PAGE_SIZE+i; d=ci<catalog.length?catalog[ci]:null; item=d?best[d.gid]:null;
    locked[i].visible=Boolean(d)&&!item; unlocked[i].visible=Boolean(item); icons[i].visible=Boolean(d); buttons[i].disabled=!d;
    if(d) icons[i].uri=uiApi.createUri(d.icon);
   }
  }
  private function renderDetails():void
  {
   var d:Object=selectedDef;
   var item:Object=selectedItem; if(!d) return;
   tx_detail_icon.uri=uiApi.createUri(d.icon); lbl_detail_name.text=d.name; lbl_detail_rarity.text=rarityMarkup(d.rarity);
   lbl_detail_level.text="Niveau "+d.level; lbl_detail_description.text=displayDescription(d.description);
   lbl_detail_category.text=d.category; lbl_detail_source.text=d.source; lbl_detail_date.text="—";
   lbl_detail_stat1_name.text=d.stat1Name; lbl_detail_stat2_name.text=uint(d.stat2Id)>0?d.stat2Name:"";
   lbl_detail_chance_max.text="/ "+formatValue(d.stat1Max,d.stat1Scale,d.stat1Suffix);
   lbl_detail_power_max.text=uint(d.stat2Id)>0?"/ "+formatValue(d.stat2Max,d.stat2Scale,d.stat2Suffix):"";
   lbl_detail_chance.text=item?formatValue(effect(item,d.stat1Id),d.stat1Scale,d.stat1Suffix):"—";
   lbl_detail_power.text=uint(d.stat2Id)>0?(item?formatValue(effect(item,d.stat2Id),d.stat2Scale,d.stat2Suffix):"—"):"";
   var isActive:Boolean=Boolean(item)&&Boolean(activeItem)&&uint(item.objectUID)==uint(activeItem.objectUID);
   lbl_btn_equip.text=isActive?"DÉSÉQUIPER":"ÉQUIPER"; btn_equip.disabled=!item;
  }
  private function renderEquipped():void
  {
   var d:Object=activeItem?definition(activeItem.objectGID):null;
   var equipped:Boolean=Boolean(activeItem)&&Boolean(d);
   tx_equipped_empty.visible=!equipped; tx_equipped_active.visible=equipped;
   tx_equipped_icon.visible=equipped; lbl_equipped_name.visible=equipped; lbl_equipped_level.visible=equipped;
   lbl_equipped_name.text=equipped?d.name:""; lbl_equipped_level.text=equipped?"Niv. "+d.level:"";
   if(equipped) tx_equipped_icon.uri=uiApi.createUri(d.icon);
  }
  private function formatValue(v:int,scale:Number,suffix:String):String
  { return (scale==10?(v/10).toFixed(1).replace(".",","):String(v))+suffix; }
  private function sendCommand(command:String):void
  {
   var action:Object=getDefinitionByName("com.ankamagames.dofus.logic.game.common.actions.chat.ChatTextOutputAction");
   sysApi.sendAction(action.create(command));
  }
  public function onRelease(target:Object):void
  {
   var i:int;
   var pages:int;
   if(target==btn_close) { uiApi.unloadUi("anomaliesUi"); return; }
   if(target==btn_equip&&selectedItem)
   {
    sendCommand(activeItem&&uint(activeItem.objectUID)==uint(selectedItem.objectUID)?".anomaly off":".anomaly "+selectedItem.objectUID); return;
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
