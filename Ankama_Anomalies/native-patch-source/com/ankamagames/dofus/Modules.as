package com.ankamagames.dofus
{
   import Ankama_Admin.Admin;
   import Ankama_Cartography.Cartography;
   import Ankama_CharacterSheet.CharacterSheet;
   import Ankama_Common.Common;
   import Ankama_Config.Config;
   import Ankama_Connection.Connection;
   import Ankama_Console.Console;
   import Ankama_ContextMenu.ContextMenu;
   import Ankama_Document.Document;
   import Ankama_Dungeon.Dungeon;
   import Ankama_Exchange.Exchange;
   import Ankama_Fight.Fight;
   import Ankama_GameUiCore.GameUiCore;
   import Ankama_Grimoire.Grimoire;
   import Ankama_House.House;
   import Ankama_Job.Job;
   import Ankama_Mount.Mount;
   import Ankama_Party.Party;
   import Ankama_Roleplay.Roleplay;
   import Ankama_Social.Social;
   import Ankama_Storage.Storage;
   import Ankama_Taxi.Taxi;
   import Ankama_Tooltips.Tooltips;
   import Ankama_TradeCenter.TradeCenter;
   import Ankama_Tutorial.Tutorial;
   import Ankama_Web.Web;
   import flash.utils.Dictionary;
   import flash.utils.getDefinitionByName;
   import flash.utils.setTimeout;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import com.ankamagames.jerakine.utils.display.StageShareManager;
   import com.ankamagames.berilia.utils.BeriliaHookList;
   import com.ankamagames.dofus.misc.lists.HookList;
   
   public class Modules
   {
      
      private static var _scripts:Dictionary;
      
      public function Modules()
      {
         super();
      }
      
      public static function get scripts() : Dictionary
      {
         if(!_scripts)
         {
            _scripts = new Dictionary();
            _scripts["Ankama_Admin"] = Admin;
            _scripts["Ankama_Cartography"] = Cartography;
            _scripts["Ankama_CharacterSheet"] = CharacterSheet;
            _scripts["Ankama_Common"] = Common;
            _scripts["Ankama_Config"] = Config;
            _scripts["Ankama_Connection"] = Connection;
            _scripts["Ankama_Console"] = Console;
            _scripts["Ankama_ContextMenu"] = ContextMenu;
            _scripts["Ankama_Document"] = Document;
            _scripts["Ankama_Dungeon"] = Dungeon;
            _scripts["Ankama_Exchange"] = Exchange;
            _scripts["Ankama_Fight"] = Fight;
            _scripts["Ankama_GameUiCore"] = GameUiCore;
            _scripts["Ankama_Grimoire"] = Grimoire;
            _scripts["Ankama_House"] = House;
            _scripts["Ankama_Job"] = Job;
            _scripts["Ankama_Mount"] = Mount;
            _scripts["Ankama_Party"] = Party;
            _scripts["Ankama_Roleplay"] = Roleplay;
            _scripts["Ankama_Social"] = Social;
            _scripts["Ankama_Storage"] = Storage;
            _scripts["Ankama_Taxi"] = Taxi;
            _scripts["Ankama_Tooltips"] = Tooltips;
            _scripts["Ankama_TradeCenter"] = TradeCenter;
            _scripts["Ankama_Tutorial"] = Tutorial;
            _scripts["Ankama_Web"] = Web;
            _scripts["Ankama_Anomalies"] = AnomaliesModuleRuntime;
         }
         return _scripts;
      }
   }

   internal class AnomaliesModuleRuntime extends Sprite
   {
      [Api(name="UiApi")]
      public var uiApi:Object;
      [Api(name="SystemApi")]
      public var sysApi:Object;
      [Api(name="InventoryApi")]
      public var inventoryApi:Object;
      [Api(name="DataApi")]
      public var dataApi:Object;
      private var button:Sprite;
      private var panel:Sprite;
      private var selected:Object;
      private var active:Object;
      private var dragging:Boolean = false;
      private var moved:Boolean = false;
      private var dragOffsetX:Number = 0;
      private var dragOffsetY:Number = 0;
      private static const POSITION_KEY:String = "anomaliesButtonPositionV1";

      public function main() : void
      {
         this.sysApi.addHook(HookList.GameStart,this.onGameStart);
         this.sysApi.addHook(BeriliaHookList.UiLoaded,this.onUiLoaded);
         setTimeout(this.installNativeButton,800);
         setTimeout(this.watchNativeButton,5000);
      }

      private function onGameStart() : void
      {
         setTimeout(this.installNativeButton,800);
      }

      private function onUiLoaded(name:String) : void
      {
         if(name == "bannerMenu")
         {
            setTimeout(this.installNativeButton,250);
         }
      }

      private function watchNativeButton() : void
      {
         this.installNativeButton();
         setTimeout(this.watchNativeButton,5000);
      }

      private function installNativeButton() : void
      {
         var banner:Object=this.uiApi.getUi("bannerMenu");
         if(!banner){setTimeout(this.installNativeButton,500);return;}
         var grid:Object=banner.getElement("gd_btnUis");
         if(!grid || !grid.dataProvider){setTimeout(this.installNativeButton,500);return;}
         var buttons:Array=grid.dataProvider as Array;
         if(!buttons)return;
         var entry:Object=null;
         for each(entry in buttons)if(entry && entry.id==32760)return;
         buttons=buttons.slice();
         buttons.push(this.dataApi.getButtonWrapper(32760,buttons.length+1,"btn_breach",this.togglePanel,"Anomalies"));
         grid.dataProvider=buttons;
      }

      private function drawButton() : void
      {
         this.button.graphics.beginFill(0x160E20,0.96);this.button.graphics.lineStyle(2,0xC94DFF);this.button.graphics.drawRoundRect(0,0,42,42,9);this.button.graphics.endFill();
         this.button.graphics.lineStyle(4,0xAD32E8);this.button.graphics.drawCircle(21,21,11);
         this.button.graphics.lineStyle(3,0xF39CFF);this.button.graphics.moveTo(21,10);this.button.graphics.curveTo(33,17,22,26);this.button.graphics.curveTo(13,33,10,21);
      }

      private function positionButton(e:Event=null) : void
      {
         if(!this.button) return;
         var saved:Object=this.sysApi.getData(POSITION_KEY);
         if(saved && !this.dragging)
         {
            this.button.x=Math.max(0,Math.min(StageShareManager.stage.stageWidth-this.button.width,Number(saved.x)));
            this.button.y=Math.max(0,Math.min(StageShareManager.stage.stageHeight-this.button.height,Number(saved.y)));
         }
         else if(!saved && !this.dragging)
         {
            this.button.x=StageShareManager.stage.stageWidth-430;
            this.button.y=StageShareManager.stage.stageHeight-58;
         }
         if(this.panel){this.panel.x=(StageShareManager.stage.stageWidth-920)/2;this.panel.y=(StageShareManager.stage.stageHeight-610)/2;}
      }

      private function startDragButton(e:MouseEvent) : void
      {
         this.dragging=true;this.moved=false;this.dragOffsetX=e.stageX-this.button.x;this.dragOffsetY=e.stageY-this.button.y;
         StageShareManager.stage.addEventListener(MouseEvent.MOUSE_MOVE,this.moveButton);
         StageShareManager.stage.addEventListener(MouseEvent.MOUSE_UP,this.stopDragButton);
      }

      private function moveButton(e:MouseEvent) : void
      {
         if(!this.dragging)return;
         var nx:Number=e.stageX-this.dragOffsetX;var ny:Number=e.stageY-this.dragOffsetY;
         if(Math.abs(nx-this.button.x)>2||Math.abs(ny-this.button.y)>2)this.moved=true;
         this.button.x=Math.max(0,Math.min(StageShareManager.stage.stageWidth-this.button.width,nx));
         this.button.y=Math.max(0,Math.min(StageShareManager.stage.stageHeight-this.button.height,ny));
         e.updateAfterEvent();
      }

      private function stopDragButton(e:MouseEvent) : void
      {
         if(!this.dragging)return;this.dragging=false;
         StageShareManager.stage.removeEventListener(MouseEvent.MOUSE_MOVE,this.moveButton);
         StageShareManager.stage.removeEventListener(MouseEvent.MOUSE_UP,this.stopDragButton);
         this.sysApi.setData(POSITION_KEY,{"x":this.button.x,"y":this.button.y});
      }

      private function label(text:String,x:Number,y:Number,size:int=16,color:uint=0xE8E1D3,width:Number=300) : TextField
      {
         var field:TextField=new TextField();field.defaultTextFormat=new TextFormat("Arial",size,color);field.htmlText=text;field.x=x;field.y=y;field.width=width;field.height=80;field.selectable=false;field.mouseEnabled=false;return field;
      }

      private function togglePanel(e:MouseEvent=null) : void
      {
         if(this.uiApi.getUi("anomaliesUi"))
         {
            this.uiApi.unloadUi("anomaliesUi");
         }
         else
         {
            this.uiApi.loadUi("anomaliesUi","anomaliesUi");
         }
      }

      private function buildPanel() : void
      {
         var items:Array=this.inventoryApi.getStorageObjectsByType(290);if(!items)items=[];
         this.active=null;var item:Object=null;for each(item in items)if(this.effect(item,3102)>0)this.active=item;
         this.selected=items.length?items[0]:null;
         this.panel=new Sprite();this.panel.graphics.beginFill(0x11171B,0.98);this.panel.graphics.lineStyle(2,0x8A7651);this.panel.graphics.drawRoundRect(0,0,920,610,14);this.panel.graphics.endFill();
         this.panel.addChild(this.label("<b>ANOMALIES</b>",28,16,27,0xE9D8B7,500));
         var close:TextField=this.label("<b>X</b>",872,15,24,0xE9D8B7,30);close.mouseEnabled=true;close.addEventListener(MouseEvent.CLICK,this.togglePanel);this.panel.addChild(close);
         this.panel.graphics.lineStyle(1,0x5E5543);this.panel.graphics.moveTo(300,65);this.panel.graphics.lineTo(300,585);this.panel.graphics.moveTo(600,65);this.panel.graphics.lineTo(600,585);
         this.panel.addChild(this.label("<b>Mes Anomalies</b>",25,75,21,0xE9D8B7,250));
         this.panel.addChild(this.label("<b>Anomalie equipee</b>",325,75,21,0xE9D8B7,250));
         this.panel.addChild(this.label("<b>Details de l'anomalie</b>",625,75,21,0xE9D8B7,270));
         if(!this.selected){this.panel.addChild(this.label("Aucune Anomalie possedee.",25,135,16,0x999999,250));return;}
         var chance:Number=this.effect(this.selected,3100)/10;var power:int=this.effect(this.selected,3101);var cs:String=chance.toFixed(1).replace(".",",");
         this.panel.addChild(this.label("<font color='#D65CFF'><b>Echo</b></font><br/>UID "+this.selected.objectUID,25,135,20,0xFFFFFF,250));
         this.panel.addChild(this.label(this.active?"<font color='#67D65C'><b>Echo actif</b></font>":"Aucune Anomalie active",325,135,19,0xAAAAAA,250));
         this.panel.addChild(this.label("<font color='#D65CFF'><b>Echo</b> - Epique</font><br/><br/><font color='#E8C34A'><b>Jets de l'Anomalie</b></font><br/><br/>Chance de repetition : <font color='#67D65C'><b>"+cs+" %</b></font> <font color='#929292'>(17-20 %)</font><br/>Puissance de l'Echo : <font color='#67D65C'><b>"+power+" %</b></font> <font color='#929292'>(40-60 %)</font><br/><br/><i><font color='#A8A8A8'>Une resonance violette venue d'ailleurs.<br/>Le Wakfu semble se souvenir de ce que vous avez deja fait.</font></i>",625,135,17,0xFFFFFF,275));
         var equip:Sprite=new Sprite();equip.graphics.beginFill(0x6E501B);equip.graphics.lineStyle(2,0xDAB85A);equip.graphics.drawRoundRect(0,0,245,45,8);equip.graphics.endFill();equip.x=638;equip.y=510;equip.buttonMode=true;equip.addChild(this.label(this.active&&this.active.objectUID==this.selected.objectUID?"<b>Desequiper</b>":"<b>Equiper</b>",55,9,18,0xFFF1C7,170));equip.addEventListener(MouseEvent.CLICK,this.equipSelected);this.panel.addChild(equip);
      }

      private function effect(item:Object,id:uint) : int
      {
         var e:Object=null;if(!item||!item.effects)return 0;for each(e in item.effects)if(e.effectId==id)return int(e.value);return 0;
      }

      private function equipSelected(e:MouseEvent) : void
      {
         var actionClass:Object=getDefinitionByName("com.ankamagames.dofus.logic.game.common.actions.chat.ChatTextOutputAction");
         this.sysApi.sendAction(actionClass.create(this.active&&this.active.objectUID==this.selected.objectUID?".anomaly off":".anomaly "+this.selected.objectUID));
         this.togglePanel();this.togglePanel();
      }
   }

   internal class AnomalyLauncher
   {
      [Api(name="UiApi")]
      public var uiApi:Object;
      public var btn_anomalies:Object;

      public function main(... args) : void
      {
         this.uiApi.addComponentHook(this.btn_anomalies,"onRelease");
         this.uiApi.addComponentHook(this.btn_anomalies,"onRollOver");
         this.uiApi.addComponentHook(this.btn_anomalies,"onRollOut");
      }

      public function onRelease(target:Object) : void
      {
         if(this.uiApi.getUi("anomaliesUi"))
         {
            this.uiApi.unloadUi("anomaliesUi");
         }
         else
         {
            this.uiApi.loadUi("anomaliesUi","anomaliesUi");
         }
      }

      public function onRollOver(target:Object) : void
      {
         this.uiApi.showTooltip(this.uiApi.textTooltipInfo("Anomalies"),target,false,"standard",7,1,3,null,null,null,"TextInfo");
      }

      public function onRollOut(target:Object) : void
      {
         this.uiApi.hideTooltip();
      }
   }

   internal class LegacyAnomaliesUiRuntime
   {
      private static const TYPE:uint = 290;
      private static const CHANCE:uint = 3100;
      private static const POWER:uint = 3101;
      private static const ACTIVE:uint = 3102;
      [Api(name="SystemApi")]
      public var sysApi:Object;
      [Api(name="UiApi")]
      public var uiApi:Object;
      [Api(name="InventoryApi")]
      public var inventoryApi:Object;
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
      private var all:Array = [];
      private var selected:Object;
      private var active:Object;

      public function main(... args) : void
      {
         this.uiApi.addComponentHook(this.gd_anomalies,"onSelectItem");
         this.uiApi.addComponentHook(this.gd_anomalies,"onItemRollOver");
         this.uiApi.addComponentHook(this.gd_anomalies,"onItemRollOut");
         this.uiApi.addComponentHook(this.inp_search,"onTextChange");
         this.uiApi.addComponentHook(this.btn_equip,"onRelease");
         this.uiApi.addComponentHook(this.btn_close,"onRelease");
         this.refresh();
      }

      private function refresh() : void
      {
         var item:Object = null;
         this.all = this.inventoryApi.getStorageObjectsByType(TYPE);
         if(!this.all) this.all = [];
         this.active = null;
         for each(item in this.all)
         {
            if(this.effect(item,ACTIVE) > 0) this.active = item;
         }
         this.filter();
         this.slot_equipped.data = this.active;
         this.lbl_empty.visible = this.all.length == 0;
         if(!this.selected && this.all.length) this.selected = this.all[0];
         this.details();
      }

      private function filter() : void
      {
         var filtered:Array = [];
         var item:Object = null;
         var query:String = this.inp_search.text.toLowerCase();
         for each(item in this.all)
         {
            if(!query.length || item.name.toLowerCase().indexOf(query) >= 0) filtered.push(item);
         }
         this.gd_anomalies.dataProvider = filtered;
      }

      private function effect(item:Object, id:uint) : int
      {
         var value:Object = null;
         if(!item || !item.effects) return 0;
         for each(value in item.effects)
         {
            if(value.effectId == id) return int(value.value);
         }
         return 0;
      }

      private function details() : void
      {
         this.slot_selected.data = this.selected;
         if(!this.selected)
         {
            this.lbl_name.text = "Selectionnez une Anomalie";
            this.btn_equip.disabled = true;
            return;
         }
         var chance:Number = this.effect(this.selected,CHANCE) / 10;
         var power:int = this.effect(this.selected,POWER);
         var chanceText:String = chance.toFixed(1).replace(".",",");
         var equipped:Boolean = Boolean(this.active && this.active.objectUID == this.selected.objectUID);
         this.lbl_name.text = "<font color='#D65CFF'><b>Echo</b></font>";
         this.lbl_rarity.text = "<font color='#D65CFF'>Epique</font>";
         this.lbl_level.text = "Niveau " + this.selected.level;
         this.lbl_rolls.text = "<font color='#E8C34A'><b>Jets de l'Anomalie</b></font><br/><br/>Chance de repetition : <font color='#67D65C'><b>" + chanceText + " %</b></font> <font color='#929292'>(17-20 %)</font><br/>Puissance de l'Echo : <font color='#67D65C'><b>" + power + " %</b></font> <font color='#929292'>(40-60 %)</font>";
         this.lbl_lore.text = "<i><font color='#A8A8A8'>Une resonance violette venue d'ailleurs.<br/>Le Wakfu semble se souvenir de ce que vous avez deja fait.</font></i>";
         this.lbl_effect.text = "<font color='#E8C34A'><b>Effet actuel</b></font><br/><br/>Le premier sort offensif eligible lance chaque tour possede <font color='#67D65C'><b>" + chanceText + " %</b></font> de chance de produire un Echo a <font color='#67D65C'><b>" + power + " %</b></font> de sa puissance.";
         this.btn_equip.label = equipped ? "Déséquiper" : "Équiper";
         this.btn_equip.disabled = false;
      }

      private function sendCommand(command:String) : void
      {
         var actionClass:Object = getDefinitionByName("com.ankamagames.dofus.logic.game.common.actions.chat.ChatTextOutputAction");
         this.sysApi.sendAction(actionClass.create(command));
      }

      public function onSelectItem(target:Object, method:uint, isNew:Boolean) : void
      {
         if(target.selectedItem)
         {
            this.selected = target.selectedItem;
            this.details();
         }
      }

      public function onItemRollOver(target:Object, item:Object) : void
      {
         if(item && item.data) this.uiApi.showTooltip(item.data,item.container,false,"standard",7,1,3,"itemName",null,{"showEffects":true});
      }

      public function onItemRollOut(target:Object, item:Object) : void
      {
         this.uiApi.hideTooltip();
      }

      public function onTextChange(target:Object) : void
      {
         this.filter();
      }

      public function onRelease(target:Object) : void
      {
         if(target == this.btn_close)
         {
            this.uiApi.unloadUi("anomaliesUi");
         }
         else if(target == this.btn_equip && this.selected)
         {
            this.sendCommand(this.active && this.active.objectUID == this.selected.objectUID ? ".anomaly off" : ".anomaly " + this.selected.objectUID);
            this.active = this.active && this.active.objectUID == this.selected.objectUID ? null : this.selected;
            this.slot_equipped.data = this.active;
            this.details();
         }
      }
   }
}

