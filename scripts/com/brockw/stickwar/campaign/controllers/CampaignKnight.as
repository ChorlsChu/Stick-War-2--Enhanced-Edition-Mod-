package com.brockw.stickwar.campaign.controllers
{
   import com.brockw.stickwar.GameScreen;
   import com.brockw.stickwar.campaign.InGameMessage;
   import com.brockw.stickwar.engine.Ai.command.UnitCommand;
   import com.brockw.stickwar.engine.Team.Team;
   import com.brockw.stickwar.engine.multiplayer.moves.UnitMove;
   import com.brockw.stickwar.engine.units.Unit;
   
   public class CampaignKnight extends CampaignController
   {
      
      private var message:InGameMessage;
      
      private var frames:int;

      private var openingRushIssued:Boolean;

      public function CampaignKnight(gameScreen:GameScreen)
      {
         super(gameScreen);
         this.openingRushIssued = false;
      }
      
      override public function update(gameScreen:GameScreen) : void
      {
         this.tryOpeningRush(gameScreen);
         if(Boolean(this.message) && gameScreen.contains(this.message))
         {
            this.message.update();
            if(this.frames++ > 30 * 5)
            {
               gameScreen.removeChild(this.message);
            }
         }
         else if(!this.message)
         {
            if(Boolean(gameScreen.team.forwardUnit) && gameScreen.team.forwardUnit.px > gameScreen.game.map.width / 2)
            {
               this.message = new InGameMessage("",gameScreen.game);
               this.message.x = gameScreen.game.stage.stageWidth / 2;
               this.message.y = gameScreen.game.stage.stageHeight / 4 - 75;
               this.message.scaleX *= 1.3;
               this.message.scaleY *= 1.3;
               gameScreen.addChild(this.message);
               this.message.setMessage("Press SPACE to select all of your attacking units","");
               this.frames = 0;
            }
         }
      }

      private function tryOpeningRush(gameScreen:GameScreen) : void
      {
         var unitId:String = null;
         var unit:Unit = null;
         var rushMove:UnitMove = null;
         var enemyTeam:Team = null;
         if(this.openingRushIssued || gameScreen == null || gameScreen.team == null || gameScreen.team.enemyTeam == null)
         {
            return;
         }
         enemyTeam = gameScreen.team.enemyTeam;
         rushMove = new UnitMove();
         rushMove.moveType = UnitCommand.ATTACK_MOVE;
         rushMove.owner = enemyTeam.id;
         rushMove.arg0 = gameScreen.team.statue.px;
         rushMove.arg1 = gameScreen.game.map.height / 2;
         for(unitId in enemyTeam.units)
         {
            unit = enemyTeam.units[unitId];
            if(unit != null && unit.isAlive() && (unit.type == Unit.U_BOMBER || unit.type == Unit.U_KNIGHT))
            {
               rushMove.units.push(unit.id);
            }
         }
         if(rushMove.units.length > 0)
         {
            enemyTeam.currentAttackState = Team.G_ATTACK;
            rushMove.execute(gameScreen.game);
         }
         this.openingRushIssued = true;
      }
   }
}

