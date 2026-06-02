package com.brockw.stickwar.engine.Ai
{
   import com.brockw.stickwar.engine.Ai.command.*;
   import com.brockw.stickwar.engine.StickWar;
   import com.brockw.stickwar.engine.Team.Tech;
   import com.brockw.stickwar.engine.units.*;
   
   public class MonkAi extends UnitAi
   {
      
      private static var cureCommand:CureCommand = null;
      
      private static const healCommand:HealCommand = new HealCommand(null);

      private static const BOSS_PRIORITY_HEAL_RANGE:Number = 180;

      private static const BOSS_MAGIKILL_GUARD_MIN_DISTANCE:Number = 160;

      private static const BOSS_MAGIKILL_GUARD_RETREAT_DISTANCE:Number = 280;

      private static const BOSS_MAGIKILL_GUARD_MAX_DISTANCE:Number = 300;

      private static const BOSS_MAGIKILL_GUARD_Y_DISTANCE:Number = 200;

      private static const BOSS_MAGIKILL_FACE_DEAD_ZONE:Number = 25;
      
      private var inRange:Unit;

      private var bossRescueCorpse:Unit;
      
      public function MonkAi(s:Monk)
      {
         super();
         unit = s;
         isNonAttackingMage = true;
         this.bossRescueCorpse = null;
      }
      
      override public function update(game:StickWar) : void
      {
         var monk:Monk = Monk(unit);
         var u:Unit = null;
         var poisoned:Unit = null;
         var range:Number = NaN;
         if(unit.shouldStartCampaignBossEscape())
         {
            unit.startCampaignBossEscape();
         }
         if(unit.updateCampaignBossEscape(game))
         {
            return;
         }
         unit.isBusyForSpell = false;
         if(monk.isBoss)
         {
            monk.isBossMovementLocked = false;
            if(this.updateBossMagikillRescue(game,monk))
            {
               return;
            }
            if(!monk.isBusy() && !this.commandQueue.isEmpty())
            {
               nextMove(game);
            }
            monk.tryBossRevive(game);
            if(monk.isBusy())
            {
               monk.isBossMovementLocked = true;
            }
            else if(this.updateBossMagikillGuard(game,monk))
            {
               return;
            }
         }
         if(currentCommand.type == UnitCommand.HEAL || currentCommand.type == UnitCommand.CURE || currentCommand.type == UnitCommand.SLOW_DART)
         {
            if(!this.currentCommand.inRange(unit))
            {
               unit.mayWalkThrough = true;
               unit.isBusyForSpell = true;
               if(currentCommand.type != UnitCommand.SLOW_DART)
               {
                  unit.walk((currentCommand.realX - unit.px) / 100,(currentCommand.realY - unit.py) / 100,intendedX);
               }
               else
               {
                  u = null;
                  if(int(currentCommand.realX) in game.units)
                  {
                     u = game.units[int(currentCommand.realX)];
                  }
                  if(u != null)
                  {
                     unit.walk((u.px - unit.px) / 100,(u.py - unit.py) / 100,intendedX);
                  }
               }
            }
            else if(currentCommand.type == UnitCommand.CURE)
            {
               monk.isCureToggled = !monk.isCureToggled;
               restoreMove(game);
               baseUpdate(game);
            }
            else if(currentCommand.type == UnitCommand.HEAL)
            {
               monk.isHealToggled = !monk.isHealToggled;
               restoreMove(game);
               baseUpdate(game);
            }
            else if(currentCommand.type == UnitCommand.SLOW_DART)
            {
               monk.slowDartSpell(UnitCommand(currentCommand).realX);
               nextMove(game);
            }
         }
         else
         {
            if(unit.team.tech.isResearched(Tech.MONK_CURE) && monk.isCureToggled && !monk.isBusy() && monk.cureCooldown() == 0 && (currentCommand is AttackMoveCommand || currentCommand is StandCommand || currentCommand is HoldCommand))
            {
               this.inRange = null;
               if(cureCommand == null)
               {
                  cureCommand = new CureCommand(unit.team.game);
               }
               for each(poisoned in unit.team.poisonedUnits)
               {
                  cureCommand.realX = poisoned.px;
                  cureCommand.realY = poisoned.py;
                  if(cureCommand.inRange(unit))
                  {
                     this.inRange = poisoned;
                     break;
                  }
               }
               if(this.inRange != null)
               {
                  monk.cureSpell(this.inRange);
                  return;
               }
            }
            if(monk.isHealToggled && !monk.isBusy() && monk.healCooldown() == 0 && mayAttack == true)
            {
               if(monk.isBoss)
               {
                  this.inRange = null;
                  game.spatialHash.mapInArea(unit.px - BOSS_PRIORITY_HEAL_RANGE,unit.py - BOSS_PRIORITY_HEAL_RANGE,unit.px + BOSS_PRIORITY_HEAL_RANGE,unit.py + BOSS_PRIORITY_HEAL_RANGE,this.priorityShadowrathHeal,false);
                  if(this.inRange != null && monk.healSpell(this.inRange))
                  {
                     return;
                  }
               }
               this.inRange = null;
               range = 100;
               game.spatialHash.mapInArea(unit.px - range,unit.py - range,unit.px + range,unit.py + range,this.lowestUnit,false);
               if(this.inRange != null && this.inRange.health != this.inRange.maxHealth)
               {
                  if(monk.healSpell(this.inRange))
                  {
                  }
                  return;
               }
            }
            baseUpdate(game);
         }
      }

      override public function setCommand(game:StickWar, c:UnitCommand) : void
      {
         if(Monk(unit).isBoss && (Monk(unit).isBusy() || this.bossRescueCorpse != null) && this.shouldDeferBossCommand(c))
         {
            this.commandQueue.clear();
            this.commandQueue.push(c);
            return;
         }
         super.setCommand(game,c);
      }

      private function updateBossMagikillRescue(game:StickWar, monk:Monk) : Boolean
      {
         if(monk.bossWasRecentlyDamaged(game))
         {
            this.bossRescueCorpse = null;
            return false;
         }
         if(this.bossRescueCorpse == null)
         {
            this.bossRescueCorpse = monk.getSafeMagikillBossCorpseForRescue(game);
         }
         if(this.bossRescueCorpse == null)
         {
            return false;
         }
         if(!monk.canBossRescueCorpse(game,this.bossRescueCorpse))
         {
            this.bossRescueCorpse = null;
            return false;
         }
         if(monk.tryBossReviveTarget(game,this.bossRescueCorpse))
         {
            this.bossRescueCorpse = null;
            return true;
         }
         unit.walk((this.bossRescueCorpse.px - unit.px) / 100,(this.bossRescueCorpse.py - unit.py) / 100,this.bossRescueCorpse.px - unit.px);
         unit.faceDirection(this.bossRescueCorpse.px - unit.px);
         return true;
      }

      private function updateBossMagikillGuard(game:StickWar, monk:Monk) : Boolean
      {
         var magikill:Unit = this.getLivingMagikillBoss();
         var guardX:Number = NaN;
         var dx:Number = NaN;
         var dy:Number = NaN;
         if(magikill == null || currentCommand.type == UnitCommand.GARRISON)
         {
            return false;
         }
         guardX = magikill.px - unit.team.direction * (monk.bossWasRecentlyDamaged(game) ? BOSS_MAGIKILL_GUARD_RETREAT_DISTANCE : BOSS_MAGIKILL_GUARD_MIN_DISTANCE);
         dx = guardX - unit.px;
         dy = magikill.py - unit.py;
         if(Math.abs(dx) > BOSS_MAGIKILL_GUARD_MAX_DISTANCE || Math.abs(dy) > BOSS_MAGIKILL_GUARD_Y_DISTANCE)
         {
            unit.walk(dx / 100,dy / 100,dx);
            unit.faceDirection(dx);
            return true;
         }
         if(Math.abs(magikill.px - unit.px) > BOSS_MAGIKILL_FACE_DEAD_ZONE)
         {
            unit.faceDirection(magikill.px - unit.px);
         }
         return false;
      }

      private function getLivingMagikillBoss() : Unit
      {
         var ally:Unit = null;
         for each(ally in unit.team.unitGroups[Unit.U_MAGIKILL])
         {
            if(ally != null && ally.isBossUnit && ally.isAlive() && !ally.isGarrisoned)
            {
               return ally;
            }
         }
         return null;
      }

      private function shouldDeferBossCommand(c:UnitCommand) : Boolean
      {
         return c.type == UnitCommand.MOVE || c.type == UnitCommand.ATTACK_MOVE || c.type == UnitCommand.GARRISON || c.type == UnitCommand.STAND || c.type == UnitCommand.HOLD;
      }

      private function priorityShadowrathHeal(target:Unit) : void
      {
         if(!Monk(this.unit).isBossPriorityHealTarget(target))
         {
            return;
         }
         if(this.inRange == null || target.health < this.inRange.health)
         {
            this.inRange = target;
         }
      }
      
      private function lowestUnit(unit:Unit) : void
      {
         if(unit.team != this.unit.team || unit.health == unit.maxHealth || unit is Statue)
         {
            return;
         }
         if(this.inRange == null)
         {
            this.inRange = unit;
         }
         else if(unit.health < this.inRange.health)
         {
            this.inRange = unit;
         }
      }
   }
}

