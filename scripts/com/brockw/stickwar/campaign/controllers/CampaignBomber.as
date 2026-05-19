package com.brockw.stickwar.campaign.controllers
{
   import com.brockw.stickwar.GameScreen;
   import com.brockw.stickwar.engine.Ai.command.*;
   import com.brockw.stickwar.engine.Team.Tech;
   import com.brockw.stickwar.engine.units.Bomber;
   import com.brockw.stickwar.engine.units.Unit;
   
   public class CampaignBomber extends CampaignController
   {
      
      private static const MIN_NUM_BOMBERS:int = 2;
      
      public static const MAX_NUM_BOMBERS:int = 10;
      
      private static const FREQUENCY_SPAWN:int = 45;
      
      private static const FREQUENCY_INCREASE:int = 60;

      private var numToSpawn:int = 0;
      
      private var hasAppliedGiantGrowth:Boolean;
      
      public function CampaignBomber(gameScreen:GameScreen)
      {
         super(gameScreen);
         this.numToSpawn = MIN_NUM_BOMBERS;
         this.hasAppliedGiantGrowth = false;
      }
      
      override public function update(gameScreen:GameScreen) : void
      {
         var i:int = 0;
         var u1:Unit = null;
         if(!this.hasAppliedGiantGrowth)
         {
            gameScreen.game.team.enemyTeam.tech.isResearchedMap[Tech.GIANT_GROWTH_I] = true;
            gameScreen.game.team.enemyTeam.tech.isResearchedMap[Tech.GIANT_GROWTH_II] = true;
            this.hasAppliedGiantGrowth = true;
         }
         if(gameScreen.game.frame % (30 * FREQUENCY_SPAWN) == 0)
         {
            for(i = 0; i < this.numToSpawn; i++)
            {
               u1 = Bomber(gameScreen.game.unitFactory.getUnit(Unit.U_BOMBER));
               gameScreen.team.enemyTeam.spawn(u1,gameScreen.game);
               u1.px = gameScreen.team.enemyTeam.statue.x;
               u1.py = gameScreen.game.map.height / 2;
               u1.isTowerSpawned = true;
               u1.suppressTowerSpawnVisual = true;
               this.issueForwardAttackCommand(gameScreen,u1);
               gameScreen.team.enemyTeam.population += 1;
            }
         }
         if(gameScreen.game.frame % (30 * FREQUENCY_INCREASE) == 0)
         {
            ++this.numToSpawn;
            if(this.numToSpawn > MAX_NUM_BOMBERS)
            {
               this.numToSpawn = MAX_NUM_BOMBERS;
            }
         }
         this.convertSpecialAttackersToTowerSpawned(gameScreen);
      }

      private function convertSpecialAttackersToTowerSpawned(gameScreen:GameScreen) : void
      {
         var unit:Unit = null;
         for each(unit in gameScreen.team.enemyTeam.unitGroups[Unit.U_BOMBER])
         {
            if(unit != null && unit.isAlive() && !unit.isTowerSpawned)
            {
               unit.isTowerSpawned = true;
               unit.suppressTowerSpawnVisual = true;
               this.issueForwardAttackCommand(gameScreen,unit);
            }
         }
         for each(unit in gameScreen.team.enemyTeam.unitGroups[Unit.U_GIANT])
         {
            if(unit != null && unit.isAlive() && !unit.isTowerSpawned)
            {
               unit.isTowerSpawned = true;
               unit.suppressTowerSpawnVisual = true;
               this.issueForwardAttackCommand(gameScreen,unit);
            }
         }
      }

      private function issueForwardAttackCommand(gameScreen:GameScreen, unit:Unit) : void
      {
         var attackMoveCommand:AttackMoveCommand = new AttackMoveCommand(gameScreen.game);
         attackMoveCommand.type = UnitCommand.ATTACK_MOVE;
         attackMoveCommand.goalX = gameScreen.team.statue.px;
         attackMoveCommand.goalY = gameScreen.game.map.height / 2;
         attackMoveCommand.realX = gameScreen.team.statue.px;
         attackMoveCommand.realY = gameScreen.game.map.height / 2;
         unit.ai.setCommand(gameScreen.game,attackMoveCommand);
      }
   }
}

