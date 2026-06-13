package com.brockw.stickwar.campaign.controllers
{
   import com.brockw.stickwar.GameScreen;
   import com.brockw.stickwar.campaign.CampaignBossMessages;
   import com.brockw.stickwar.campaign.InGameMessage;
   import com.brockw.stickwar.engine.Ai.command.AttackMoveCommand;
   import com.brockw.stickwar.engine.Ai.command.UnitCommand;
   import com.brockw.stickwar.engine.units.Archer;
   import com.brockw.stickwar.engine.units.Unit;
   
   public class CampaignArcher extends CampaignController
   {
      
      private static const CAPTAIN_SPAWN_FRAME:int = 30 * 180;
      
      private static const CAPTAIN_STATUE_HEALTH_TRIGGER:Number = 0.5;
      
      private static const CAPTAIN_SUPPORT_ARCHERS:int = 2;
      
      private static const CAPTAIN_ATTACK_REFRESH_DELAY_FRAMES:int = 30 * 2;
      
      private static const CAPTAIN_SPAWN_OFFSET:Number = 220;
      
      private static const CAPTAIN_COLUMN_SPACING:Number = 55;
      
      private static const CAPTAIN_ROW_SPACING:Number = 55;
      
      private var message:InGameMessage;
      
      private var bossMessages:CampaignBossMessages;
      
      private var frames:int;
      
      private var hasSpawnedCaptain:Boolean;
      
      private var pendingCaptainAttackRefresh:Array;
      
      private var arrow:tutorialArrow;
      
      internal var state:int = 0;
      
      internal var S_BEFORE:int = 0;
      
      internal var S_SELECT:int = 1;
      
      internal var S_HILL:int = 2;
      
      internal var S_DONE:int = 2;
      
      public function CampaignArcher(gameScreen:GameScreen)
      {
         super(gameScreen);
         this.frames = 0;
         this.state = this.S_BEFORE;
         this.bossMessages = null;
         this.hasSpawnedCaptain = false;
         this.pendingCaptainAttackRefresh = null;
      }
      
      override public function update(gameScreen:GameScreen) : void
      {
         if(this.arrow != null)
         {
            if(this.arrow.currentFrame == this.arrow.totalFrames)
            {
               this.arrow.gotoAndPlay(1);
            }
            else
            {
               this.arrow.nextFrame();
            }
         }
         if(Boolean(this.message))
         {
            this.message.update();
         }
         if(this.bossMessages == null && gameScreen.game != null)
         {
            this.bossMessages = new CampaignBossMessages(gameScreen,gameScreen.game);
         }
         this.updateCaptainSpawn(gameScreen);
         if(this.bossMessages != null)
         {
            this.bossMessages.update();
         }
         this.updateCaptainAttackRefresh(gameScreen);
         if(this.state == this.S_BEFORE)
         {
            if(Boolean(gameScreen.game.frame > 30) && Boolean(gameScreen.userInterface.selectedUnits.interactsWith & Unit.I_ENEMY) && !(gameScreen.userInterface.selectedUnits.interactsWith & Unit.I_MINE))
            {
               this.state = this.S_SELECT;
               this.message = new InGameMessage("",gameScreen.game);
               this.message.x = gameScreen.game.stage.stageWidth / 2 + 205;
               this.message.y = gameScreen.game.stage.stageHeight - 190;
               this.message.scaleX *= 0.9;
               this.message.scaleY *= 0.9;
               this.message.visible = false;
               this.message.setMessage("Gain full control over individual units by clicking commands such as hold position.","");
               gameScreen.addChild(this.message);
               this.frames = 0;
               this.arrow = new tutorialArrow();
               gameScreen.addChild(this.arrow);
               this.arrow.x = gameScreen.game.stage.stageWidth / 2 + 392;
               this.arrow.y = gameScreen.game.stage.stageHeight - 35;
            }
         }
         else if(this.state == this.S_SELECT)
         {
            if(Boolean(gameScreen.userInterface.selectedUnits.interactsWith & Unit.I_ENEMY))
            {
               this.arrow.visible = true;
            }
            else
            {
               this.arrow.visible = false;
            }
            if(this.message.isShowingNewMessage())
            {
               this.message.visible = true;
            }
            if(this.frames++ > 30 * 10)
            {
               this.message.visible = false;
               this.arrow.visible = false;
            }
            if(Boolean(gameScreen.team.forwardUnit) && gameScreen.team.forwardUnit.x > gameScreen.game.map.width / 2)
            {
               this.message.x = gameScreen.game.stage.stageWidth / 2;
               this.message.y = gameScreen.game.stage.stageHeight / 4 - 75;
               this.message.scaleX = 1.3;
               this.message.scaleY = 1.3;
               this.message.setMessage("Capturing the center tower will award you a continuous stream of gold for as long as you hold the tower","");
               this.frames = 0;
               this.state = this.S_HILL;
            }
         }
         else if(this.state == this.S_HILL)
         {
            if(this.frames++ < 3 * 30)
            {
               gameScreen.game.targetScreenX = gameScreen.game.map.hills[0].x - gameScreen.game.map.screenWidth / 2;
            }
            if(this.message.isShowingNewMessage())
            {
               this.message.visible = true;
            }
            if(this.frames++ > 7.5 * 30)
            {
               this.state = this.S_DONE;
               this.message.visible = false;
               this.arrow.visible = false;
            }
         }
         else if(this.state == this.S_DONE)
         {
         }
      }
      
      private function updateCaptainSpawn(gameScreen:GameScreen) : void
      {
         if(this.hasSpawnedCaptain || !this.shouldSpawnCaptain(gameScreen))
         {
            return;
         }
         this.hasSpawnedCaptain = true;
         this.spawnArchidonCaptain(gameScreen);
         this.showCaptainMessage(gameScreen);
      }
      
      private function shouldSpawnCaptain(gameScreen:GameScreen) : Boolean
      {
         if(gameScreen.game.frame >= CAPTAIN_SPAWN_FRAME)
         {
            return true;
         }
         if(gameScreen.team == null || gameScreen.team.enemyTeam == null || gameScreen.team.enemyTeam.statue == null)
         {
            return false;
         }
         return gameScreen.team.enemyTeam.statue.health <= gameScreen.team.enemyTeam.statue.maxHealth * CAPTAIN_STATUE_HEALTH_TRIGGER;
      }
      
      private function spawnArchidonCaptain(gameScreen:GameScreen) : void
      {
         var i:int = 0;
         var archer:Archer = null;
         var spawnedArchers:Array = [];
         var total:int = CAPTAIN_SUPPORT_ARCHERS + 1;
         var xPos:Number = 0;
         var yPos:Number = 0;
         for(i = 0; i < total; i++)
         {
            archer = Archer(gameScreen.game.unitFactory.getUnit(Unit.U_ARCHER));
            gameScreen.team.enemyTeam.spawn(archer,gameScreen.game);
            if(i == 0)
            {
               archer.makeBoss();
            }
            xPos = gameScreen.team.enemyTeam.homeX + gameScreen.team.enemyTeam.direction * (CAPTAIN_SPAWN_OFFSET + int(i / 3) * CAPTAIN_COLUMN_SPACING);
            yPos = Math.max(80,Math.min(gameScreen.game.map.height - 80,gameScreen.game.map.height / 2 + (i % 3 - 1) * CAPTAIN_ROW_SPACING));
            archer.x = archer.px = xPos;
            archer.y = archer.py = yPos;
            gameScreen.team.enemyTeam.population += archer.population;
            this.issueCaptainAttackCommand(gameScreen,archer);
            spawnedArchers.push(archer);
         }
         this.pendingCaptainAttackRefresh = [gameScreen.game.frame + CAPTAIN_ATTACK_REFRESH_DELAY_FRAMES,spawnedArchers];
      }
      
      private function issueCaptainAttackCommand(gameScreen:GameScreen, unit:Unit) : void
      {
         var attackMoveCommand:AttackMoveCommand = null;
         if(unit == null || unit.ai == null)
         {
            return;
         }
         attackMoveCommand = new AttackMoveCommand(gameScreen.game);
         attackMoveCommand.type = UnitCommand.ATTACK_MOVE;
         attackMoveCommand.goalX = gameScreen.team.statue.px;
         attackMoveCommand.goalY = gameScreen.game.map.height / 2;
         attackMoveCommand.realX = attackMoveCommand.goalX;
         attackMoveCommand.realY = attackMoveCommand.goalY;
         unit.ai.setCommand(gameScreen.game,attackMoveCommand);
      }
      
      private function updateCaptainAttackRefresh(gameScreen:GameScreen) : void
      {
         var unit:Unit = null;
         if(this.pendingCaptainAttackRefresh == null || gameScreen.game.frame < int(this.pendingCaptainAttackRefresh[0]))
         {
            return;
         }
         for each(unit in this.pendingCaptainAttackRefresh[1])
         {
            if(unit != null && unit.isAlive())
            {
               this.issueCaptainAttackCommand(gameScreen,unit);
            }
         }
         this.pendingCaptainAttackRefresh = null;
      }
      
      private function showCaptainMessage(gameScreen:GameScreen) : void
      {
         if(this.bossMessages != null)
         {
            this.bossMessages.showArchidonCaptain();
         }
      }
   }
}
