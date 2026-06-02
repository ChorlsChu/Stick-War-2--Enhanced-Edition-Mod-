package com.brockw.stickwar.engine.Ai
{
   import com.brockw.game.Util;
   import com.brockw.stickwar.engine.Ai.command.UnitCommand;
   import com.brockw.stickwar.engine.StickWar;
   import com.brockw.stickwar.engine.units.RangedUnit;
   import com.brockw.stickwar.engine.units.Unit;
   import com.brockw.stickwar.engine.units.Wingidon;
   
   public class WingidonAi extends RangedAi
   {
      
      public function WingidonAi(s:Wingidon)
      {
         super(s);
         unit = s;
      }
      
      override public function update(game:StickWar) : void
      {
         checkNextMove(game);
         if(Wingidon(unit).isBoss)
         {
            Wingidon(unit).tryBossAbilities(game);
         }
         if(this.tryMarkedPreyFocus(game))
         {
            return;
         }
         super.update(game);
      }

      private function tryMarkedPreyFocus(game:StickWar) : Boolean
      {
         var target:Unit = Wingidon(unit).getMarkedPreyTarget(game);
         var walkX:Number = NaN;
         if(target == null || (!mayAttack && !mayMoveToAttack))
         {
            return false;
         }
         currentTarget = target;
         RangedUnit(unit).aim(currentTarget);
         if(RangedUnit(unit).mayAttack(currentTarget) && currentCommand.type != UnitCommand.MOVE)
         {
            unit.faceDirection(Util.sgn(currentTarget.px - unit.px));
         }
         if(mayAttack && unit.mayAttack(currentTarget))
         {
            unit.faceDirection(Util.sgn(currentTarget.px - unit.px));
            RangedUnit(unit).shoot(game,currentTarget);
         }
         else if(mayMoveToAttack && unit.sqrDistanceTo(currentTarget) < 150000 && !unit.isGarrisoned)
         {
            walkX = currentTarget.px - unit.px - 100 * unit.team.direction;
            if(RangedUnit(unit).inRange(currentTarget) || Util.sgn(walkX) != Util.sgn(currentTarget.px - unit.px))
            {
               unit.faceDirection(Util.sgn(currentTarget.px - unit.px));
            }
            else
            {
               unit.walk(walkX / 100,(currentTarget.py - unit.py) / 100,Util.sgn(currentTarget.px - unit.px));
            }
         }
         else
         {
            unit.faceDirection(Util.sgn(currentTarget.px - unit.px));
         }
         return true;
      }
   }
}

