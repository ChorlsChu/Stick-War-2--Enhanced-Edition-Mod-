package com.brockw.stickwar.engine.Ai
{
   import com.brockw.stickwar.engine.Ai.command.*;
   import com.brockw.stickwar.engine.Entity;
   import com.brockw.stickwar.engine.StickWar;
   import com.brockw.stickwar.engine.units.*;
   
   public class SkelatorAi extends UnitAi
   {

      private static const BOSS_PREFERRED_DISTANCE:Number = 240;

      private static const BOSS_HOLD_DISTANCE:Number = 360;
      
      public function SkelatorAi(s:Skelator)
      {
         super();
         unit = s;
         isNonAttackingMage = true;
      }
      
      override public function update(game:StickWar) : void
      {
         var targetId:int = 0;
         var targ:Entity = null;
         unit.isBusyForSpell = false;
         if(Skelator(unit).isBoss && currentCommand.type != UnitCommand.FIST_ATTACK && currentCommand.type != UnitCommand.REAPER)
         {
            if(this.updateBossCaster(game))
            {
               return;
            }
         }
         if(currentCommand.type == UnitCommand.FIST_ATTACK || currentCommand.type == UnitCommand.REAPER)
         {
            if(currentCommand.isFinished(unit))
            {
               baseUpdate(game);
               return;
            }
            if(!this.currentCommand.inRange(unit))
            {
               unit.mayWalkThrough = true;
               unit.isBusyForSpell = true;
               unit.walk((currentCommand.realX - unit.px) / 100,(currentCommand.realY - unit.py) / 100,(currentCommand.realX - unit.px) / 100);
            }
            else if(currentCommand.type == UnitCommand.FIST_ATTACK)
            {
               Skelator(unit).fistAttack(FistAttackCommand(currentCommand).realX,FistAttackCommand(currentCommand).realY);
               nextMove(game);
            }
            else if(currentCommand.type == UnitCommand.REAPER)
            {
               targetId = ReaperCommand(currentCommand).targetId;
               if(targetId in game.units)
               {
                  targ = game.units[targetId];
                  if(targ is Unit && Unit(targ).team != unit.team)
                  {
                     Skelator(unit).reaperAttack(Unit(targ));
                     nextMove(game);
                  }
                  else
                  {
                     baseUpdate(game);
                  }
               }
               else
               {
                  baseUpdate(game);
               }
            }
         }
         else
         {
            baseUpdate(game);
         }
      }

      private function updateBossCaster(game:StickWar) : Boolean
      {
         var target:Unit = null;
         var skelator:Skelator = Skelator(unit);
         var dx:Number = NaN;
         var dy:Number = NaN;
         var distance:Number = NaN;
         var isDistancing:Boolean = false;
         var retreatDirection:int = 0;
         var fistReady:Boolean = false;
         var fistCanCast:Boolean = false;
         var reaperReady:Boolean = false;
         var reaperTarget:Unit = null;
         var reaperDistance:Number = NaN;
         var reaperRange:Number = Number(game.xml.xml.Chaos.Units.skelator.reaper.range);
         var fistRange:Number = Number(game.xml.xml.Chaos.Units.skelator.fist.range);
         if(unit.isBusy() || unit.isIncapacitated())
         {
            unit.isBossMovementLocked = false;
            return false;
         }
         if(skelator.canBossDeadRising())
         {
            unit.isBossMovementLocked = false;
            skelator.deadRising();
            return true;
         }
         target = this.getClosestTarget();
         if(target == null || !target.isAlive())
         {
            unit.isBossMovementLocked = false;
            return false;
         }
         dx = target.px - unit.px;
         dy = target.py - unit.py;
         distance = Math.sqrt(dx * dx + dy * dy);
         isDistancing = skelator.isBossDistancePhaseActive() && skelator.hasRecentBossHitForDistance();
         fistReady = skelator.fistAttackCooldown() == 0;
         fistCanCast = fistReady && distance <= fistRange;
         reaperReady = skelator.reaperCooldown() == 0;
         if(fistCanCast)
         {
            unit.isBossMovementLocked = false;
            skelator.fistAttack(target.px,target.py);
            return true;
         }
         if(reaperReady && (!fistCanCast || isDistancing))
         {
            reaperTarget = this.getBossReaperControlTarget(reaperRange);
            if(reaperTarget != null)
            {
               reaperDistance = Math.sqrt(Math.pow(reaperTarget.px - unit.px,2) + Math.pow(reaperTarget.py - unit.py,2));
               if(reaperDistance <= reaperRange)
               {
                  unit.isBossMovementLocked = false;
                  skelator.reaperAttack(reaperTarget);
                  return true;
               }
            }
         }
         if(isDistancing && distance < BOSS_PREFERRED_DISTANCE)
         {
            retreatDirection = skelator.getBossDistanceRetreatDirection();
            if(retreatDirection == 0)
            {
               retreatDirection = -unit.team.direction;
            }
            unit.isBossMovementLocked = true;
            unit.mayWalkThrough = true;
            unit.walk(retreatDirection,-dy / 160,retreatDirection);
            unit.faceDirection(retreatDirection);
            return true;
         }
         if(isDistancing && distance < BOSS_HOLD_DISTANCE)
         {
            retreatDirection = skelator.getBossDistanceRetreatDirection();
            if(retreatDirection == 0)
            {
               retreatDirection = -unit.team.direction;
            }
            unit.isBossMovementLocked = true;
            unit.mayWalkThrough = false;
            unit.faceDirection(retreatDirection);
            return true;
         }
         unit.isBossMovementLocked = false;
         unit.faceDirection(dx);
         return false;
      }

      private function getBossReaperControlTarget(reaperRange:Number) : Unit
      {
         var enemy:Unit = null;
         var best:Unit = null;
         var distance:Number = NaN;
         var bestDistance:Number = Number.MAX_VALUE;
         for each(enemy in unit.team.enemyTeam.units)
         {
            if(enemy == null || !enemy.isAlive() || !enemy.isTargetable() || enemy.isGarrisoned || enemy.isBossUnit || enemy.type == Unit.U_STATUE)
            {
               continue;
            }
            distance = Math.sqrt(Math.pow(enemy.px - unit.px,2) + Math.pow(enemy.py - unit.py,2));
            if(distance > reaperRange)
            {
               continue;
            }
            if(enemy.type == Unit.U_MAGIKILL)
            {
               return enemy;
            }
            if(distance < bestDistance)
            {
               bestDistance = distance;
               best = enemy;
            }
         }
         return best;
      }
   }
}

