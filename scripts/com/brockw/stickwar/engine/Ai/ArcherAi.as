package com.brockw.stickwar.engine.Ai
{
   import com.brockw.stickwar.engine.Ai.command.UnitCommand;
   import com.brockw.stickwar.engine.StickWar;
   import com.brockw.stickwar.engine.units.Archer;
   
   public class ArcherAi extends RangedAi
   {
      private static const BOSS_REAR_LINE_ADJUST_THRESHOLD:Number = 25;

      private static const BOSS_REAR_LINE_IDLE_THRESHOLD:Number = 65;
      
      public function ArcherAi(s:Archer)
      {
         super(s);
         unit = s;
      }
      
      override public function update(game:StickWar) : void
      {
         var targetDistance:Number = NaN;
         var rearLineX:Number = NaN;
         var shouldRearLineAdjust:Boolean = false;
         var closestTarget:* = null;
         checkNextMove(game);
         if(unit.shouldStartCampaignBossEscape())
         {
            unit.startCampaignBossEscape();
         }
         if(unit.updateCampaignBossEscape(game))
         {
            return;
         }
         if(Archer(unit).isBoss)
         {
            this.mayKite = true;
            Archer(unit).updateBossRegroupState();
            Archer(unit).tryBossCommandFireArrows(game);
            if(Archer(unit).shouldBossRetreatRegroup())
            {
               Archer(unit).bossRetreatAndRegroup(game);
            }
            if(currentCommand.type == UnitCommand.ATTACK_MOVE || currentCommand.type == UnitCommand.STAND || currentCommand.type == UnitCommand.HOLD)
            {
               rearLineX = Archer(unit).getBossRearLineX();
               if(Math.abs(rearLineX - unit.px) > BOSS_REAR_LINE_ADJUST_THRESHOLD)
               {
                  closestTarget = this.getClosestTarget();
                  if(closestTarget != null)
                  {
                     targetDistance = Math.abs(closestTarget.px - unit.px);
                     if(!Archer(unit).inRange(closestTarget) || unit.team.direction * unit.px > unit.team.direction * rearLineX)
                     {
                        shouldRearLineAdjust = true;
                        Archer(unit).isBossMovementLocked = true;
                        unit.walk((rearLineX - unit.px) / 100,0,unit.team.direction);
                        unit.faceDirection(closestTarget.px - unit.px);
                        return;
                     }
                  }
                  else if(Math.abs(rearLineX - unit.px) > BOSS_REAR_LINE_IDLE_THRESHOLD)
                  {
                     shouldRearLineAdjust = true;
                     Archer(unit).isBossMovementLocked = true;
                     unit.walk((rearLineX - unit.px) / 100,0,unit.team.direction);
                     return;
                  }
               }
            }
            Archer(unit).isBossMovementLocked = Archer(unit).bossIsRegrouping || shouldRearLineAdjust || currentCommand.type == UnitCommand.MOVE;
         }
         if(unit.team == unit.team.game.team)
         {
            this.mayKite = Archer(unit).isAutoKiteToggled;
         }
         if(currentCommand.type == UnitCommand.HEAL)
         {
            Archer(unit).isAutoKiteToggled = !Archer(unit).isAutoKiteToggled;
            this.mayKite = Archer(unit).isAutoKiteToggled;
            restoreMove(game);
            super.update(game);
            return;
         }
         if(currentCommand.type == UnitCommand.ARCHER_FIRE)
         {
            Archer(unit).archerFireArrow();
            nextMove(game);
         }
         super.update(game);
      }
   }
}

