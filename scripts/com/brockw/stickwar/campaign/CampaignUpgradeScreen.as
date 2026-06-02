package com.brockw.stickwar.campaign
{
   import com.brockw.game.Screen;
   import com.brockw.stickwar.BaseMain;
   import com.brockw.stickwar.engine.Team.Tech;
   import com.brockw.stickwar.engine.Team.TechItem;
   import flash.display.Bitmap;
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.utils.Dictionary;
   import flash.utils.getTimer;
   
   public class CampaignUpgradeScreen extends Screen
   {
      
      private var main:BaseMain;
      
      private var mc:campaignUpgradeScreenMc;
      
      private var buttonMap:Dictionary;
      
      private var clicked:Boolean;

      private var upgradeTips:Dictionary;
      
      private var timeOfLastUpdate:int;
      
      public function CampaignUpgradeScreen(main:BaseMain)
      {
         super();
         this.main = main;
         this.mc = new campaignUpgradeScreenMc();
         addChild(this.mc);
         this.timeOfLastUpdate = getTimer();
         this.initButtonMap();
         this.initUpgradeTips();
      }
      
      private function setUpButton(txt:String, button:MovieClip) : void
      {
         this.buttonMap[txt] = button;
         button.buttonMode = true;
         button.mouseChildren = false;
         button.gotoAndStop(1);
      }
      
      private function initButtonMap() : void
      {
         this.buttonMap = new Dictionary();
         this.setUpButton("Castle Archer I",this.mc.button1);
         this.setUpButton("Rage",this.mc.button2);
         this.setUpButton("Passive Income I",this.mc.button3);
         this.setUpButton("Block",this.mc.button4);
         this.setUpButton("Miner Speed",this.mc.button5);
         this.setUpButton("Castle Archer II",this.mc.button6);
         this.setUpButton("Shield Bash",this.mc.button7);
         this.setUpButton("Cure",this.mc.button8);
         this.setUpButton("Passive Income II",this.mc.button9);
         this.setUpButton("Castle Archer III",this.mc.button10);
         this.setUpButton("Fire Arrow",this.mc.button11);
         this.setUpButton("Cloak",this.mc.button12);
         this.setUpButton("Electric Wall",this.mc.button13);
         this.setUpButton("Miner Wall",this.mc.button14);
         this.setUpButton("Statue Health",this.mc.button15);
         this.setUpButton("Giant Growth I",this.mc.button16);
         this.setUpButton("Poison Spray",this.mc.button17);
         this.setUpButton("Giant Growth II",this.mc.button20);
         this.setUpButton("Tower Spawn II",this.mc.button18);
         this.setUpButton("Tower Spawn I",this.mc.button19);
      }

      private function addUpgradeTip(upgradeType:int, upgrade:XMLList, button:Bitmap) : void
      {
         this.upgradeTips[upgradeType] = new TechItem(upgrade,button);
      }

      private function initUpgradeTips() : void
      {
         this.upgradeTips = new Dictionary();
         this.addUpgradeTip(Tech.SWORDWRATH_RAGE,this.main.xml.xml.Order.Tech.rage,new Bitmap(new SwordwrathSacrifice()));
         this.addUpgradeTip(Tech.BLOCK,this.main.xml.xml.Order.Tech.block,new Bitmap(new SpeartanShieldWall()));
         this.addUpgradeTip(Tech.CLOAK,this.main.xml.xml.Order.Tech.cloak,new Bitmap(new NinjaCloak1()));
         this.addUpgradeTip(Tech.CLOAK_II,this.main.xml.xml.Order.Tech.cloak2,new Bitmap(new NinjaCloak2()));
         this.addUpgradeTip(Tech.ARCHIDON_FIRE,this.main.xml.xml.Order.Tech.archidonFire,new Bitmap(new ArchidonFire()));
         this.addUpgradeTip(Tech.MAGIKILL_NUKE,this.main.xml.xml.Order.Tech.magikillNuke,new Bitmap(new MagikillFireballs()));
         this.addUpgradeTip(Tech.MAGIKILL_WALL,this.main.xml.xml.Order.Tech.magikillWall,new Bitmap(new MagikillWall()));
         this.addUpgradeTip(Tech.MAGIKILL_POISON,this.main.xml.xml.Order.Tech.magikillPoison,new Bitmap(new poisonSprayBitmap()));
         this.addUpgradeTip(Tech.MONK_CURE,this.main.xml.xml.Order.Tech.cure,new Bitmap(new CureBitmap()));
         this.addUpgradeTip(Tech.CASTLE_ARCHER_1,this.main.xml.xml.Order.Tech.castleArchers1,new Bitmap(new castleArcherLevel1Bitmap()));
         this.addUpgradeTip(Tech.CASTLE_ARCHER_2,this.main.xml.xml.Order.Tech.castleArchers2,new Bitmap(new castleArcherLevel2Bitmap()));
         this.addUpgradeTip(Tech.CASTLE_ARCHER_3,this.main.xml.xml.Order.Tech.castleArchers3,new Bitmap(new castleArcherLevel3Bitmap()));
         this.addUpgradeTip(Tech.SHIELD_BASH,this.main.xml.xml.Order.Tech.speartonShieldBash,new Bitmap(new shieldHitBitmap()));
         this.addUpgradeTip(Tech.STATUE_HEALTH,this.main.xml.xml.Order.Tech.statueHealth,new Bitmap(new statueHealthBitmap()));
         this.addUpgradeTip(Tech.MINER_SPEED,this.main.xml.xml.Order.Tech.minerSpeed,new Bitmap(new minerBagBitmap()));
         this.addUpgradeTip(Tech.BANK_PASSIVE_1,this.main.xml.xml.Order.Tech.passiveIncomeGold1,new Bitmap(new passiveIncomeBitmap()));
         this.addUpgradeTip(Tech.BANK_PASSIVE_2,this.main.xml.xml.Order.Tech.passiveIncomeGold2,new Bitmap(new passiveIncomeBitmap()));
         this.addUpgradeTip(Tech.BANK_PASSIVE_3,this.main.xml.xml.Order.Tech.passiveIncomeGold3,new Bitmap(new passiveIncomeBitmap()));
         this.addUpgradeTip(Tech.GIANT_GROWTH_I,this.main.xml.xml.Order.Tech.giantSize1,new Bitmap(new GiantGrowth1Bitmap()));
         this.addUpgradeTip(Tech.GIANT_GROWTH_II,this.main.xml.xml.Order.Tech.giantSize2,new Bitmap(new GiantGrowth2Bitmap()));
         this.addUpgradeTip(Tech.MINER_WALL,this.main.xml.xml.Order.Tech.minerWall,new Bitmap(new OrderTowerBitmap()));
         this.addUpgradeTip(Tech.CROSSBOW_FIRE,this.main.xml.xml.Order.Tech.crossbowFire,new Bitmap(new allbowtrossFireArrowUpgrade()));
         this.addUpgradeTip(Tech.TOWER_SPAWN_I,this.main.xml.xml.Chaos.Tech.towerSpawnI,new Bitmap(new towerUpgradeI()));
         this.addUpgradeTip(Tech.TOWER_SPAWN_II,this.main.xml.xml.Chaos.Tech.towerSpawnII,new Bitmap(new towerUpgradeII()));
      }
      
      private function update(evt:Event) : void
      {
         var key:String = null;
         var c:CampaignUpgrade = null;
         var t:TechItem = null;
         var canUpgrade:Boolean = false;
         var p:String = null;
         if(this.mc.confirmTech.visible)
         {
            return;
         }
         this.mc.campaignPoints.text = "" + this.main.campaign.campaignPoints;
         if(this.main.campaign.campaignPoints == 0)
         {
            this.mc.campaignPoints.text = "0";
         }
         for(key in this.buttonMap)
         {
            c = CampaignUpgrade(this.main.campaign.upgradeMap[key]);
            t = this.upgradeTips[this.main.campaign.upgradeMap[key].tech];
            if(Boolean(t) && Boolean(this.buttonMap[key].hitTestPoint(stage.mouseX,stage.mouseY,false)))
            {
               this.mc.infoBox.text.text = t.tip;
            }
            canUpgrade = true;
            if(Boolean(this.main.campaign.upgradeMap[key].upgraded))
            {
               canUpgrade = false;
               this.buttonMap[key].gotoAndStop(3);
            }
            for each(p in this.main.campaign.upgradeMap[key].parents)
            {
               if(!this.main.campaign.upgradeMap[p].upgraded)
               {
                  canUpgrade = false;
               }
            }
            if(canUpgrade)
            {
               this.buttonMap[key].gotoAndStop(2);
               this.buttonMap[key].alpha = 1;
            }
            else if(!this.main.campaign.upgradeMap[key].upgraded)
            {
               this.buttonMap[key].alpha = 0.5;
            }
            if(this.main.campaign.campaignPoints == 0)
            {
               canUpgrade = false;
            }
            if(canUpgrade && MovieClip(this.buttonMap[key]).hitTestPoint(stage.mouseX,stage.mouseY,false) && this.clicked)
            {
               this.main.campaign.upgradeMap[key].upgraded = true;
               c = CampaignUpgrade(this.main.campaign.upgradeMap[key]);
               this.main.campaign.techAllowed[c.tech] = 1;
               --this.main.campaign.campaignPoints;
               this.main.soundManager.playSoundFullVolume("ArmoryEquipSound");
            }
         }
         this.clicked = false;
      }
      
      override public function maySwitchOnDisconnect() : Boolean
      {
         return false;
      }
      
      private function mapButton(evt:Event) : void
      {
         if(this.main.campaign.campaignPoints != 0)
         {
            this.mc.confirmTech.visible = true;
         }
         else
         {
            this.main.showScreen("campaignMap",false,true);
         }
         this.main.soundManager.playSoundFullVolume("clickButton");
      }
      
      private function click(evt:Event) : void
      {
         this.clicked = true;
      }
      
      private function yesButton(evt:Event) : void
      {
         this.mc.confirmTech.visible = false;
         this.main.showScreen("campaignMap",false,true);
      }
      
      private function noButton(evt:Event) : void
      {
         this.mc.confirmTech.visible = false;
      }
      
      override public function enter() : void
      {
         this.main.soundManager.playSoundInBackground("loginMusic");
         stage.frameRate = 30;
         addEventListener(Event.ENTER_FRAME,this.update);
         addEventListener(MouseEvent.CLICK,this.click);
         this.mc.start.addEventListener(MouseEvent.CLICK,this.mapButton);
         this.mc.confirmTech.visible = false;
         this.mc.confirmTech.yesButton.addEventListener(MouseEvent.CLICK,this.yesButton);
         this.mc.confirmTech.noButton.addEventListener(MouseEvent.CLICK,this.noButton);
      }
      
      override public function leave() : void
      {
         removeEventListener(Event.ENTER_FRAME,this.update);
         removeEventListener(MouseEvent.CLICK,this.click);
         this.mc.start.removeEventListener(MouseEvent.CLICK,this.mapButton);
         this.mc.confirmTech.yesButton.removeEventListener(MouseEvent.CLICK,this.yesButton);
         this.mc.confirmTech.noButton.removeEventListener(MouseEvent.CLICK,this.noButton);
      }
   }
}

