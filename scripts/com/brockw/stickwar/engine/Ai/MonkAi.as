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
      
      private var inRange:Unit;
      
      public function MonkAi(s:Monk)
      {
         super();
         unit = s;
         isNonAttackingMage = true;
      }
      
      override public function update(game:StickWar) : void
      {
         var u:Unit = null;
         var poisoned:Unit = null;
         var range:Number = NaN;
         var rearLineX:Number = NaN;
         if(unit.shouldStartCampaignBossEscape())
         {
            unit.startCampaignBossEscape();
         }
         if(unit.updateCampaignBossEscape(game))
         {
            return;
         }
         if(Monk(unit).isBoss)
         {
            Monk(unit).isBossMovementLocked = false;
            Monk(unit).tryBossRevive(game);
            if(Monk(unit).isBusy())
            {
               Monk(unit).isBossMovementLocked = true;
            }
            if(!Monk(unit).isBusy() && (currentCommand is AttackMoveCommand || currentCommand is StandCommand || currentCommand is HoldCommand))
            {
               rearLineX = Monk(unit).getBossRearLineX();
               if(unit.team.direction * unit.px > unit.team.direction * rearLineX + 25)
               {
                  Monk(unit).isBossMovementLocked = true;
                  unit.walk((rearLineX - unit.px) / 100,0,unit.team.direction);
                  return;
               }
            }
         }
         unit.isBusyForSpell = false;
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
               Monk(unit).isCureToggled = !Monk(unit).isCureToggled;
               restoreMove(game);
               baseUpdate(game);
            }
            else if(currentCommand.type == UnitCommand.HEAL)
            {
               Monk(unit).isHealToggled = !Monk(unit).isHealToggled;
               restoreMove(game);
               baseUpdate(game);
            }
            else if(currentCommand.type == UnitCommand.SLOW_DART)
            {
               Monk(unit).slowDartSpell(UnitCommand(currentCommand).realX);
               nextMove(game);
            }
         }
         else
         {
            if(unit.team.tech.isResearched(Tech.MONK_CURE) && Monk(unit).isCureToggled && !Monk(unit).isBusy() && Monk(unit).cureCooldown() == 0 && (currentCommand is AttackMoveCommand || currentCommand is StandCommand || currentCommand is HoldCommand))
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
                  Monk(unit).cureSpell(this.inRange);
                  return;
               }
            }
            if(Monk(unit).isHealToggled && !Monk(unit).isBusy() && Monk(unit).healCooldown() == 0 && mayAttack == true)
            {
               if(Monk(unit).isBoss)
               {
                  this.inRange = null;
                  game.spatialHash.mapInArea(unit.px - BOSS_PRIORITY_HEAL_RANGE,unit.py - BOSS_PRIORITY_HEAL_RANGE,unit.px + BOSS_PRIORITY_HEAL_RANGE,unit.py + BOSS_PRIORITY_HEAL_RANGE,this.priorityShadowrathHeal,false);
                  if(this.inRange != null && Monk(unit).healSpell(this.inRange))
                  {
                     return;
                  }
               }
               this.inRange = null;
               range = 100;
               game.spatialHash.mapInArea(unit.px - range,unit.py - range,unit.px + range,unit.py + range,this.lowestUnit,false);
               if(this.inRange != null && this.inRange.health != this.inRange.maxHealth)
               {
                  if(Monk(unit).healSpell(this.inRange))
                  {
                  }
                  return;
               }
            }
            baseUpdate(game);
         }
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

