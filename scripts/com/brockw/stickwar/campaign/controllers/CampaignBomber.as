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
      
      private var lastConvertedEnemyArmyVersion:int;
      
      private var pendingAttackRefreshes:Array;
      
      public function CampaignBomber(gameScreen:GameScreen)
      {
         super(gameScreen);
         this.numToSpawn = MIN_NUM_BOMBERS;
         this.hasAppliedGiantGrowth = false;
         this.lastConvertedEnemyArmyVersion = -1;
         this.pendingAttackRefreshes = [];
      }
      
      override public function update(gameScreen:GameScreen) : void
      {
         var i:int = 0;
         var u1:Unit = null;
         var waveUnits:Array = null;
         if(!this.hasAppliedGiantGrowth)
         {
            gameScreen.game.team.enemyTeam.tech.isResearchedMap[Tech.GIANT_GROWTH_I] = true;
            gameScreen.game.team.enemyTeam.tech.isResearchedMap[Tech.GIANT_GROWTH_II] = true;
            this.hasAppliedGiantGrowth = true;
         }
         this.updatePendingAttackRefreshes(gameScreen);
         if(this.lastConvertedEnemyArmyVersion != gameScreen.team.enemyTeam.armyChangeVersion)
         {
            this.convertSpecialAttackersToIndependentAttackers(gameScreen);
            this.lastConvertedEnemyArmyVersion = gameScreen.team.enemyTeam.armyChangeVersion;
         }
         if(gameScreen.game.frame % (30 * FREQUENCY_SPAWN) == 0)
         {
            waveUnits = [];
            for(i = 0; i < this.numToSpawn; i++)
            {
               u1 = Bomber(gameScreen.game.unitFactory.getUnit(Unit.U_BOMBER));
               gameScreen.team.enemyTeam.spawn(u1,gameScreen.game);
               u1.px = gameScreen.team.enemyTeam.statue.x;
               u1.py = gameScreen.game.map.height / 2;
               this.makeIndependentAttacker(gameScreen,u1);
               waveUnits.push(u1);
               gameScreen.team.enemyTeam.population += 1;
            }
            this.scheduleAttackRefresh(gameScreen,waveUnits);
         }
         if(gameScreen.game.frame % (30 * FREQUENCY_INCREASE) == 0)
         {
            ++this.numToSpawn;
            if(this.numToSpawn > MAX_NUM_BOMBERS)
            {
               this.numToSpawn = MAX_NUM_BOMBERS;
            }
         }
      }

      private function convertSpecialAttackersToIndependentAttackers(gameScreen:GameScreen) : void
      {
         var unit:Unit = null;
         var convertedUnits:Array = [];
         for each(unit in gameScreen.team.enemyTeam.unitGroups[Unit.U_BOMBER])
         {
            if(unit != null && unit.isAlive() && !unit.isBossMovementLocked)
            {
               this.makeIndependentAttacker(gameScreen,unit);
               convertedUnits.push(unit);
            }
         }
         for each(unit in gameScreen.team.enemyTeam.unitGroups[Unit.U_GIANT])
         {
            if(unit != null && unit.isAlive() && !unit.isBossMovementLocked)
            {
               this.makeIndependentAttacker(gameScreen,unit);
               convertedUnits.push(unit);
            }
         }
         this.scheduleAttackRefresh(gameScreen,convertedUnits);
      }

      private function makeIndependentAttacker(gameScreen:GameScreen, unit:Unit) : void
      {
         if(unit == null || unit.ai == null)
         {
            return;
         }
         unit.isBossMovementLocked = true;
         unit.ai.mayAttack = true;
         unit.ai.mayMoveToAttack = true;
         this.issueForwardAttackCommand(gameScreen,unit);
      }

      private function scheduleAttackRefresh(gameScreen:GameScreen, units:Array) : void
      {
         if(units == null || units.length == 0)
         {
            return;
         }
         this.pendingAttackRefreshes.push([gameScreen.game.frame + 60,units]);
      }

      private function updatePendingAttackRefreshes(gameScreen:GameScreen) : void
      {
         var i:int = 0;
         var j:int = 0;
         var refresh:Array = null;
         var units:Array = null;
         while(i < this.pendingAttackRefreshes.length)
         {
            refresh = this.pendingAttackRefreshes[i];
            if(gameScreen.game.frame < int(refresh[0]))
            {
               ++i;
               continue;
            }
            units = refresh[1];
            for(j = 0; j < units.length; j++)
            {
               if(units[j] != null && Unit(units[j]).isAlive())
               {
                  this.issueForwardAttackCommand(gameScreen,Unit(units[j]),j,units.length);
               }
            }
            this.pendingAttackRefreshes.splice(i,1);
         }
      }

      private function issueForwardAttackCommand(gameScreen:GameScreen, unit:Unit, laneIndex:int = 0, laneCount:int = 1) : void
      {
         var attackMoveCommand:AttackMoveCommand = new AttackMoveCommand(gameScreen.game);
         var laneOffset:Number = 0;
         attackMoveCommand.type = UnitCommand.ATTACK_MOVE;
         if(laneCount > 1)
         {
            laneOffset = (laneIndex - (laneCount - 1) / 2) * 35;
         }
         attackMoveCommand.goalX = gameScreen.team.statue.px;
         attackMoveCommand.goalY = gameScreen.game.map.height / 2 + laneOffset;
         attackMoveCommand.realX = gameScreen.team.statue.px;
         attackMoveCommand.realY = attackMoveCommand.goalY;
         unit.ai.setCommand(gameScreen.game,attackMoveCommand);
      }
   }
}

