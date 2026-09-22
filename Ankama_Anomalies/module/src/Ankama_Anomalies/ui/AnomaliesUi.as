package Ankama_Anomalies.ui
{
   import flash.utils.getDefinitionByName;
   
   public class AnomaliesUi
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
      
      public function AnomaliesUi()
      {
         super();
      }
      
      public function main(... rest) : void
      {
         var args:Array = rest;
         this.debugChat("[ANOM-TRACE 10] ENTER AnomaliesUi.main");
         this.debugChat("[ANOMALIES-UI] Classe UI initialisee.");
         if(this.lbl_smoke_title)
         {
            if(this.btn_close)
            {
               this.uiApi.addComponentHook(this.btn_close,"onRelease");
            }
            this.debugChat("[ANOMALIES-UI] Smoke UI main() termine avec succes.");
            return;
         }
         try
         {
            this.debugChat("[ANOMALIES-UI] Composants grid=" + this.gd_anomalies + ", search=" + this.inp_search + ", equip=" + this.btn_equip + ", close=" + this.btn_close);
            this.uiApi.addComponentHook(this.gd_anomalies,"onSelectItem");
            this.uiApi.addComponentHook(this.gd_anomalies,"onItemRollOver");
            this.uiApi.addComponentHook(this.gd_anomalies,"onItemRollOut");
            this.uiApi.addComponentHook(this.btn_equip,"onRelease");
            this.uiApi.addComponentHook(this.btn_close,"onRelease");
            this.uiApi.addComponentHook(this.btn_tab_anomalies,"onRelease");
            this.uiApi.addComponentHook(this.btn_tab_fusion,"onRelease");
            this.uiApi.addComponentHook(this.btn_tab_catalogue,"onRelease");
            this.uiApi.addComponentHook(this.btn_tab_effects,"onRelease");
            this.uiApi.addComponentHook(this.btn_tab_history,"onRelease");
            this.uiApi.addComponentHook(this.btn_tab_guide,"onRelease");
            this.debugChat("[ANOMALIES-UI] Hooks installes.");
            this.refresh();
            this.debugChat("[ANOMALIES-UI] Donnees affichees.");
         }
         catch(error:Error)
         {
            debugChat("[ANOMALIES-UI] ERREUR INIT : " + error.name + " - " + error.message);
         }
      }
      
      private function debugChat(param1:String) : void
      {
         var hooks:Object = null;
         var message:String = param1;
         try
         {
            hooks = getDefinitionByName("com.ankamagames.dofus.misc.lists::ChatHookList");
            this.sysApi.dispatchHook(hooks.TextInformation,message,666,0);
         }
         catch(ignore:Error)
         {
            sysApi.log(4,message);
         }
      }
      
      private function refresh() : void
      {
         var _loc1_:Object = null;
         this.all = this.inventoryApi.getStorageObjectsByType(TYPE);
         if(!this.all)
         {
            this.all = [];
         }
         this.active = null;
         for each(_loc1_ in this.all)
         {
            if(this.fx(_loc1_,ACTIVE) > 0)
            {
               this.active = _loc1_;
            }
         }
         this.filter();
         if(this.slot_equipped)
         {
            this.slot_equipped.data = this.active;
         }
         this.lbl_empty.visible = this.all.length == 0;
         if(!this.selected && Boolean(this.all.length))
         {
            this.selected = this.all[0];
         }
         this.details();
      }
      
      private function filter() : void
      {
         var _loc2_:Object = null;
         var _loc1_:Array = [];
         var _loc3_:String = Boolean(this.inp_search) && Boolean(this.inp_search.text) ? this.inp_search.text.toLowerCase() : "";
         for each(_loc2_ in this.all)
         {
            if(!_loc3_.length || _loc2_.name.toLowerCase().indexOf(_loc3_) >= 0)
            {
               _loc1_.push(_loc2_);
            }
         }
         this.gd_anomalies.dataProvider = _loc1_;
      }
      
      private function fx(param1:Object, param2:uint) : int
      {
         var _loc3_:Object = null;
         if(!param1 || !param1.effects)
         {
            return 0;
         }
         for each(_loc3_ in param1.effects)
         {
            if(_loc3_.effectId == param2)
            {
               return int(_loc3_.value);
            }
         }
         return 0;
      }
      
      private function details() : void
      {
         this.slot_selected.data = this.selected;
         if(!this.selected)
         {
            this.lbl_name.text = "Sélectionnez une Anomalie";
            this.btn_equip.disabled = true;
            return;
         }
         var _loc1_:Number = this.fx(this.selected,CHANCE) / 10;
         var _loc2_:int = this.fx(this.selected,POWER);
         var _loc3_:String = _loc1_.toFixed(1).replace(".",",");
         var _loc4_:Boolean = Boolean(this.active) && this.active.objectUID == this.selected.objectUID;
         this.lbl_name.text = "<font color=\'#D65CFF\'><b>Écho</b></font>";
         this.lbl_rarity.text = "<font color=\'#D65CFF\'>Épique</font>";
         this.lbl_level.text = "Niveau " + this.selected.level;
         this.lbl_rolls.text = "<font color=\'#E8C34A\'><b>Jets de l\'Anomalie</b></font><br/><br/>Chance de répétition : <font color=\'#67D65C\'><b>" + _loc3_ + " %</b></font> <font color=\'#929292\'>(17-20 %)</font><br/>Puissance de l\'Écho : <font color=\'#67D65C\'><b>" + _loc2_ + " %</b></font> <font color=\'#929292\'>(40-60 %)</font>";
         this.lbl_lore.text = "<i><font color=\'#A8A8A8\'>Une résonance violette venue d\'ailleurs.<br/>Le Wakfu semble se souvenir de ce que vous avez déjà fait.</font></i>";
         this.lbl_effect.text = "<font color=\'#E8C34A\'><b>Effet actuel</b></font><br/><br/>Le premier sort offensif éligible lancé chaque tour possède <font color=\'#67D65C\'><b>" + _loc3_ + " %</b></font> de chance de produire un Écho à <font color=\'#67D65C\'><b>" + _loc2_ + " %</b></font> de sa puissance.";
         this.btn_equip.label = _loc4_ ? "Déséquiper" : "Équiper";
         this.btn_equip.disabled = false;
      }
      
      private function sendCommand(param1:String) : void
      {
         var _loc2_:Object = getDefinitionByName("com.ankamagames.dofus.logic.game.common.actions.chat.ChatTextOutputAction");
         this.sysApi.sendAction(_loc2_.create(param1));
      }
      
      public function onSelectItem(param1:Object, param2:uint, param3:Boolean) : void
      {
         if(param1.selectedItem)
         {
            this.selected = param1.selectedItem;
            this.details();
         }
      }
      
      public function onItemRollOver(param1:Object, param2:Object) : void
      {
         if(Boolean(param2) && Boolean(param2.data))
         {
            this.uiApi.showTooltip(param2.data,param2.container,false,"standard",7,1,3,"itemName",null,{"showEffects":true});
         }
      }
      
      public function onItemRollOut(param1:Object, param2:Object) : void
      {
         this.uiApi.hideTooltip();
      }
      
      public function onTextChange(param1:Object) : void
      {
         this.filter();
      }
      
      private function showSection(param1:int, param2:String) : void
      {
         this.ctr_tab_active.y = 101 + param1 * 56;
         this.ctr_anomalies_content.visible = param1 == 0;
         this.lbl_section_message.visible = param1 != 0;
         if(param1 != 0)
         {
            this.lbl_section_message.text = param2 + "\nCette section sera disponible dans une prochaine version.";
         }
      }
      
      public function onRelease(param1:Object) : void
      {
         if(param1 == this.btn_close)
         {
            this.uiApi.unloadUi("anomaliesUi");
            return;
         }
         if(param1 == this.btn_tab_anomalies)
         {
            this.showSection(0,"");
            return;
         }
         if(param1 == this.btn_tab_fusion)
         {
            this.showSection(1,"Fusion");
            return;
         }
         if(param1 == this.btn_tab_catalogue)
         {
            this.showSection(2,"Catalogue");
            return;
         }
         if(param1 == this.btn_tab_effects)
         {
            this.showSection(3,"Effets");
            return;
         }
         if(param1 == this.btn_tab_history)
         {
            this.showSection(4,"Historique");
            return;
         }
         if(param1 == this.btn_tab_guide)
         {
            this.showSection(5,"Guide");
            return;
         }
         if(param1 == this.btn_equip && Boolean(this.selected))
         {
            this.sendCommand(Boolean(this.active) && this.active.objectUID == this.selected.objectUID ? "/anomaly off" : "/anomaly " + this.selected.objectUID);
            this.active = Boolean(this.active) && this.active.objectUID == this.selected.objectUID ? null : this.selected;
            if(this.slot_equipped)
            {
               this.slot_equipped.data = this.active;
            }
            this.details();
         }
      }
   }
}

