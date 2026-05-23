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
         var spearton:Spearton = Spearton(unit);
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
            if(!spearton.inBlock)
            {
               baseUpdate(game);
            }
            return;
         }
         if(spearton.isInBossBraceSequence)
         {
            return;
         }
         if(currentCommand.type == UnitCommand.SPEARTON_BLOCK)
         {
            if(spearton.inBlock)
            {
               spearton.stopBlocking();
            }
            else
            {
               spearton.startBlocking();
            }
            nextMove(game);
         }
         else if(currentCommand.type == UnitCommand.SHIELD_BASH)
         {
            spearton.shieldBash();
            nextMove(game);
         }
         else if(currentCommand.type != UnitCommand.STAND)
         {
            spearton.stopBlocking();
         }
         if(!spearton.inBlock)
         {
            baseUpdate(game);
         }
      }

      private function tryBossBraceShieldSlam(game:StickWar) : Boolean
      {
         var spearton:Spearton = Spearton(unit);
         var target:* = null;
         if(!spearton.isBoss)
         {
            return false;
         }
         if(!spearton.hasRecentBossNormalAttack())
         {
            return false;
         }
         target = this.getClosestTarget();
         if(target == null || target.team == unit.team || !target.isTargetable())
         {
            return false;
         }
         if(unit.sqrDistanceToTarget(target) > spearton.bossCombatRadius * spearton.bossCombatRadius)
         {
            return false;
         }
         spearton.tryBossBraceShieldSlam();
         return spearton.inBlock;
      }
   }
}

