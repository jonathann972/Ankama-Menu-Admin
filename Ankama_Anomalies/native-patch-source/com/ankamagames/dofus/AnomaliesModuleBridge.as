package com.ankamagames.dofus
{
   import flash.utils.getDefinitionByName;

   public class AnomaliesModuleBridge
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

      private var all:Array = [];
      private var selected:Object;
      private var active:Object;

      public function AnomaliesModuleBridge()
      {
         super();
      }

      public function main(... args) : void
      {
         this.sysApi.log(2,"[ANOM-NATIVE] AnomaliesUi.main OK");
         this.addHook(this.gd_anomalies,"onSelectItem");
         this.addHook(this.gd_anomalies,"onItemRollOver");
         this.addHook(this.gd_anomalies,"onItemRollOut");
         this.addHook(this.inp_search,"onTextChange");
         this.addHook(this.btn_equip,"onRelease");
         this.addHook(this.btn_close,"onRelease");
         this.addHook(this.btn_tab_anomalies,"onRelease");
         this.addHook(this.btn_tab_fusion,"onRelease");
         this.addHook(this.btn_tab_catalogue,"onRelease");
         this.addHook(this.btn_tab_effects,"onRelease");
         this.addHook(this.btn_tab_history,"onRelease");
         this.addHook(this.btn_tab_guide,"onRelease");
         this.refresh();
      }

      private function addHook(component:Object, hook:String) : void
      {
         if(component)
         {
            this.uiApi.addComponentHook(component,hook);
         }
      }

      private function refresh() : void
      {
         var item:Object = null;
         this.all = this.inventoryApi.getStorageObjectsByType(TYPE);
         if(!this.all)
         {
            this.all = [];
         }
         this.active = null;
         for each(item in this.all)
         {
            if(this.effect(item,ACTIVE) > 0)
            {
               this.active = item;
            }
         }
         this.filter();
         this.slot_equipped.data = this.active;
         this.lbl_empty.visible = this.all.length == 0;
         if(!this.selected && this.all.length)
         {
            this.selected = this.all[0];
         }
         this.details();
      }

      private function filter() : void
      {
         var filtered:Array = [];
         var item:Object = null;
         var query:String = this.inp_search && this.inp_search.text ? this.inp_search.text.toLowerCase() : "";
         for each(item in this.all)
         {
            if(!query.length || item.name.toLowerCase().indexOf(query) >= 0)
            {
               filtered.push(item);
            }
         }
         this.gd_anomalies.dataProvider = filtered;
      }

      private function effect(item:Object, id:uint) : int
      {
         var value:Object = null;
         if(!item || !item.effects)
         {
            return 0;
         }
         for each(value in item.effects)
         {
            if(value.effectId == id)
            {
               return int(value.value);
            }
         }
         return 0;
      }

      private function details() : void
      {
         this.slot_selected.data = this.selected;
         if(!this.selected)
         {
            this.lbl_name.text = "Selectionnez une Anomalie";
            this.lbl_rarity.text = "";
            this.lbl_level.text = "";
            this.lbl_rolls.text = "";
            this.lbl_lore.text = "";
            this.lbl_effect.text = "";
            this.btn_equip.disabled = true;
            return;
         }
         var chance:Number = this.effect(this.selected,CHANCE) / 10;
         var power:int = this.effect(this.selected,POWER);
         var chanceText:String = chance.toFixed(1).replace(".",",");
         var equipped:Boolean = Boolean(this.active) && this.active.objectUID == this.selected.objectUID;
         this.lbl_name.text = "<font color='#D65CFF'><b>Echo</b></font>";
         this.lbl_rarity.text = "<font color='#D65CFF'>Epique</font>";
         this.lbl_level.text = "Niveau " + this.selected.level;
         this.lbl_rolls.text = "<font color='#E8C34A'><b>Jets de l'Anomalie</b></font><br/><br/>Chance de repetition : <font color='#67D65C'><b>" + chanceText + " %</b></font> <font color='#929292'>(17-20 %)</font><br/>Puissance de l'Echo : <font color='#67D65C'><b>" + power + " %</b></font> <font color='#929292'>(40-60 %)</font>";
         this.lbl_lore.text = "<i><font color='#A8A8A8'>Une resonance violette venue d'ailleurs.<br/>Le Wakfu semble se souvenir de ce que vous avez deja fait.</font></i>";
         this.lbl_effect.text = "<font color='#E8C34A'><b>Effet actuel</b></font><br/><br/>Le premier sort offensif eligible lance chaque tour possede <font color='#67D65C'><b>" + chanceText + " %</b></font> de chance de produire un Echo a <font color='#67D65C'><b>" + power + " %</b></font> de sa puissance.";
         this.btn_equip.label = equipped ? "Desequiper" : "Equiper";
         this.btn_equip.disabled = false;
      }

      private function sendCommand(command:String) : void
      {
         var actionClass:Object = getDefinitionByName("com.ankamagames.dofus.logic.game.common.actions.chat.ChatTextOutputAction");
         this.sysApi.sendAction(actionClass.create(command));
      }

      private function showSection(index:int, title:String) : void
      {
         this.ctr_tab_active.x = 30 + index * 150;
         this.ctr_anomalies_content.visible = index == 0;
         this.lbl_section_message.visible = index != 0;
         if(index != 0)
         {
            this.lbl_section_message.text = title + "\nCette section sera disponible dans une prochaine version.";
         }
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
         if(item && item.data)
         {
            this.uiApi.showTooltip(item.data,item.container,false,"standard",7,1,3,"itemName",null,{"showEffects":true});
         }
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
         else if(target == this.btn_tab_anomalies)
         {
            this.showSection(0,"");
         }
         else if(target == this.btn_tab_fusion)
         {
            this.showSection(1,"Fusion");
         }
         else if(target == this.btn_tab_catalogue)
         {
            this.showSection(2,"Catalogue");
         }
         else if(target == this.btn_tab_effects)
         {
            this.showSection(3,"Effets");
         }
         else if(target == this.btn_tab_history)
         {
            this.showSection(4,"Historique");
         }
         else if(target == this.btn_tab_guide)
         {
            this.showSection(5,"Guide");
         }
         else if(target == this.btn_equip && this.selected)
         {
            this.sendCommand(this.active && this.active.objectUID == this.selected.objectUID ? "/anomaly off" : "/anomaly " + this.selected.objectUID);
            this.active = this.active && this.active.objectUID == this.selected.objectUID ? null : this.selected;
            this.slot_equipped.data = this.active;
            this.details();
         }
      }
   }
}
