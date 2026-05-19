package com.brockw.stickwar.engine.Ai
{
   import com.brockw.stickwar.engine.Ai.command.UnitCommand;
   import com.brockw.stickwar.engine.StickWar;
   import com.brockw.stickwar.engine.units.Spearton;
   
   public class SpeartonAi extends UnitAi
   {
      
      public function SpeartonAi(s:Spearton)
      {
         super();
         unit = s;
      }
      
      override public function update(game:StickWar) : void
      {
         if(unit.shouldStartCampaignBossEscape())
         {
            unit.startCampaignBossEscape();
         }
         if(unit.updateCampaignBossEscape(game))
         {
            return;
         }
         if(this.tryBossBraceShieldSlam(game))
         {
            if(!Spearton(unit).inBlock)
            {
               baseUpdate(game);
            }
            return;
         }
         if(Spearton(unit).isInBossBraceSequence)
         {
            return;
         }
         if(currentCommand.type == UnitCommand.SPEARTON_BLOCK)
         {
            if(Spearton(unit).inBlock)
            {
               Spearton(unit).stopBlocking();
            }
            else
            {
               Spearton(unit).startBlocking();
            }
            nextMove(game);
         }
         else if(currentCommand.type == UnitCommand.SHIELD_BASH)
         {
            Spearton(unit).shieldBash();
            nextMove(game);
         }
         else if(currentCommand.type != UnitCommand.STAND)
         {
            Spearton(unit).stopBlocking();
         }
         if(!Spearton(unit).inBlock)
         {
            baseUpdate(game);
         }
      }

      private function tryBossBraceShieldSlam(game:StickWar) : Boolean
      {
         var target:* = null;
         if(!Spearton(unit).isBoss)
         {
            return false;
         }
         target = this.getClosestTarget();
         if(target == null || target.team == unit.team || !target.isTargetable())
         {
            return false;
         }
         if(unit.sqrDistanceToTarget(target) > Spearton(unit).bossCombatRadius * Spearton(unit).bossCombatRadius)
         {
            return false;
         }
         if(!Spearton(unit).hasRecentBossNormalAttack())
         {
            return false;
         }
         Spearton(unit).tryBossBraceShieldSlam();
         return Spearton(unit).inBlock;
      }
   }
}

