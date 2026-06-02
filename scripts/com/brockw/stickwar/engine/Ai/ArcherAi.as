package com.brockw.stickwar.engine.Ai
{
   import com.brockw.stickwar.engine.Ai.command.UnitCommand;
   import com.brockw.stickwar.engine.StickWar;
   import com.brockw.stickwar.engine.units.Archer;
   
   public class ArcherAi extends RangedAi
   {
      public function ArcherAi(s:Archer)
      {
         super(s);
         unit = s;
      }
      
      override public function update(game:StickWar) : void
      {
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
            Archer(unit).tryBossAbilities(game);
            Archer(unit).isBossMovementLocked = false;
            if(Archer(unit).handleBossExplosionSetupMovement(game))
            {
               return;
            }
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

