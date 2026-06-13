package com.brockw.stickwar.campaign
{
   import com.brockw.stickwar.engine.StickWar;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   
   public class CampaignBossMessages
   {
      
      private static const MAGIKILL_WARD_MESSAGE:String = "The Magikill Archmage is shielding the statue!\nDefeat him to break the ward.";
      
      private static const MAGIKILL_WARD_COOLDOWN_FRAMES:int = 30 * 10;
      
      private static const MAGIKILL_WARD_VISIBLE_FRAMES:int = 30 * 7;
      
      private static const MEDUSA_LOOK_AT_ME_MESSAGE:String = "Look away to avoid being turned to stone.";
      
      private static const MEDUSA_LOOK_AT_ME_COOLDOWN_FRAMES:int = 30 * 14;
      
      private static const MEDUSA_LOOK_AT_ME_VISIBLE_FRAMES:int = 30 * 7;

      private static const ARCHIDON_CAPTAIN_MESSAGE:String = "The Archidon Captain has joined the battle";

      private static const ARCHIDON_CAPTAIN_VISIBLE_FRAMES:int = 30 * 4;
      
      private static const DEFAULT_MESSAGE_SCALE:Number = 1.3;
      
      private var owner:DisplayObjectContainer;
      
      private var game:StickWar;
      
      private var warningMessage:DisplayObject;
      
      private var warningHideFrame:int;
      
      private var warningActive:Boolean;
      
      private var nextMagikillWardFrame:int;
      
      private var nextMedusaLookAtMeFrame:int;

      private var activeWarningText:String;
      
      public function CampaignBossMessages(owner:DisplayObjectContainer, game:StickWar)
      {
         super();
         this.owner = owner;
         this.game = game;
         this.warningMessage = null;
         this.warningHideFrame = 0;
         this.warningActive = false;
         this.nextMagikillWardFrame = 0;
         this.nextMedusaLookAtMeFrame = 0;
         this.activeWarningText = "";
      }
      
      public function showMagikillWard() : void
      {
         if(this.game == null || this.game.frame < this.nextMagikillWardFrame)
         {
            return;
         }
         this.showWarning(MAGIKILL_WARD_MESSAGE,MAGIKILL_WARD_VISIBLE_FRAMES);
         this.nextMagikillWardFrame = this.game.frame + MAGIKILL_WARD_COOLDOWN_FRAMES;
      }
      
      public function showMedusaLookAtMe() : void
      {
         if(this.game == null || this.game.frame < this.nextMedusaLookAtMeFrame)
         {
            return;
         }
         this.showWarning(MEDUSA_LOOK_AT_ME_MESSAGE,MEDUSA_LOOK_AT_ME_VISIBLE_FRAMES);
         this.nextMedusaLookAtMeFrame = this.game.frame + MEDUSA_LOOK_AT_ME_COOLDOWN_FRAMES;
      }

      public function showArchidonCaptain() : void
      {
         this.showWarning(ARCHIDON_CAPTAIN_MESSAGE,ARCHIDON_CAPTAIN_VISIBLE_FRAMES);
      }
      
      public function update() : void
      {
         if(this.warningMessage == null || this.warningMessage.parent == null)
         {
            this.warningActive = false;
            return;
         }
         if(this.warningActive && this.game != null && this.game.frame >= this.warningHideFrame)
         {
            this.hideWarning();
         }
      }
      
      public function cleanUp() : void
      {
         this.hideWarning();
         this.owner = null;
         this.game = null;
         this.nextMagikillWardFrame = 0;
         this.nextMedusaLookAtMeFrame = 0;
      }
      
      private function showWarning(text:String, visibleFrames:int) : void
      {
         if(this.owner == null || this.game == null || this.game.stage == null)
         {
            return;
         }
         if(this.warningActive && this.activeWarningText == text)
         {
            return;
         }
         if(this.warningMessage != null && this.warningMessage.parent != null)
         {
            this.warningMessage.parent.removeChild(this.warningMessage);
         }
         var messageBox:inGameMessageBoxMc = new inGameMessageBoxMc();
         messageBox.text.text = text;
         messageBox.step.text = "";
         messageBox.tick.visible = false;
         messageBox.x = 0;
         messageBox.y = 0;
         this.warningMessage = messageBox;
         this.warningMessage.x = this.game.stage.stageWidth / 2;
         this.warningMessage.y = this.game.stage.stageHeight / 4 - 75;
         this.warningMessage.scaleX = DEFAULT_MESSAGE_SCALE;
         this.warningMessage.scaleY = DEFAULT_MESSAGE_SCALE;
         this.owner.addChild(this.warningMessage);
         this.warningHideFrame = this.game.frame + visibleFrames;
         this.warningActive = true;
         this.activeWarningText = text;
      }
      
      private function hideWarning() : void
      {
         this.warningActive = false;
         if(this.warningMessage != null && this.warningMessage.parent != null)
         {
            this.warningMessage.parent.removeChild(this.warningMessage);
         }
         this.warningMessage = null;
         this.activeWarningText = "";
      }
   }
}
