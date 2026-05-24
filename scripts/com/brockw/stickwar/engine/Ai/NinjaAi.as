package com.brockw.stickwar.engine.Ai
{
   import com.brockw.game.Util;
   import com.brockw.stickwar.engine.Ai.command.AttackMoveCommand;
   import com.brockw.stickwar.engine.Ai.command.MoveCommand;
   import com.brockw.stickwar.engine.Ai.command.UnitCommand;
   import com.brockw.stickwar.engine.StickWar;
   import com.brockw.stickwar.engine.Team.Team;
   import com.brockw.stickwar.engine.units.Archer;
   import com.brockw.stickwar.engine.units.EnslavedGiant;
   import com.brockw.stickwar.engine.units.Magikill;
   import com.brockw.stickwar.engine.units.Monk;
   import com.brockw.stickwar.engine.units.Ninja;
   import com.brockw.stickwar.engine.units.Unit;
   
   public class NinjaAi extends UnitAi
   {
      private static const BOSS_TARGET_LOCK_FRAMES:int = 30;

      private static const BOSS_SQUAD_RADIUS_X:Number = 260;

      private static const BOSS_SQUAD_RADIUS_Y:Number = 120;

      private var bossFocusTargetId:int;

      private var bossFocusFrames:int;

      private var cachedBossPriorityTarget:Unit;

      private var cachedBossPriorityTargetFrame:int;

      private var cachedNearbyAttackerCount:int;

      private var cachedNearbyAttackerCountFrame:int;

      private var cachedNearbyBossLeader:Ninja;

      private var cachedNearbyBossLeaderFrame:int;
      
      public function NinjaAi(s:Ninja)
      {
         super();
         unit = s;
         this.bossFocusTargetId = -1;
         this.bossFocusFrames = 0;
         this.cachedBossPriorityTarget = null;
         this.cachedBossPriorityTargetFrame = -1;
         this.cachedNearbyAttackerCount = 0;
         this.cachedNearbyAttackerCountFrame = -1;
         this.cachedNearbyBossLeader = null;
         this.cachedNearbyBossLeaderFrame = -1;
      }
      
      override public function update(game:StickWar) : void
      {
         if(!Ninja(unit).isBoss)
         {
            unit.isBossMovementLocked = false;
         }
         if(this.bossFocusFrames > 0)
         {
            --this.bossFocusFrames;
         }
         if(unit.shouldStartCampaignBossEscape())
         {
            unit.startCampaignBossEscape();
         }
         if(unit.updateCampaignBossEscape(game))
         {
            Ninja(unit).isBossMovementLocked = true;
            return;
         }
         if(Ninja(unit).isBoss)
         {
            Ninja(unit).isBossMovementLocked = false;
            if(Ninja(unit).shouldBossRetreat())
            {
               Ninja(unit).startBossRetreat();
            }
            if(Ninja(unit).bossEmergencySortie)
            {
               Ninja(unit).isBossMovementLocked = true;
               Ninja(unit).beginBossRecovery();
            }
            if(Ninja(unit).bossIsRetreating)
            {
               this.clearBossFocusTarget();
               Ninja(unit).isBossMovementLocked = true;
               this.updateBossRetreat(game);
               return;
            }
            Ninja(unit).tryBossChainCloak();
         }
         if(currentCommand.type == UnitCommand.CURE)
         {
            Ninja(unit).isAutoCloakToggled = !Ninja(unit).isAutoCloakToggled;
            restoreMove(game);
         }
         if(currentCommand.type == UnitCommand.STEALTH)
         {
            Ninja(unit).stealth();
            restoreMove(game);
         }
         if(Ninja(unit).isAutoCloakToggled)
         {
            this.tryAutoCloak();
         }
         if(!Ninja(unit).isBoss && this.tryBossAssassinSquadMovement())
         {
            return;
         }
         if(Ninja(unit).isBoss && this.tryBossAssassinMovement())
         {
            return;
         }
         baseUpdate(game);
      }

      override public function getClosestTarget() : Unit
      {
         var prioritized:Unit = null;
         if(!Ninja(unit).isBoss || Ninja(unit).bossIsRetreating)
         {
            return super.getClosestTarget();
         }
         if(!this.shouldUseBossAssassinProtocol() && !Ninja(unit).isBossSpecialTargetingActive())
         {
            return super.getClosestTarget();
         }
         prioritized = this.getBossPriorityTarget();
         if(prioritized != null)
         {
            return prioritized;
         }
         return super.getClosestTarget();
      }

      private function tryAutoCloak() : void
      {
         var closestTarget:* = this.getClosestTarget();
         if(Ninja(unit).isBoss && (Ninja(unit).hasBossWhiffPenalty() || Ninja(unit).hasBossAbilitySpawnLock()))
         {
            return;
         }
         if(Ninja(unit).isBoss && !this.shouldUseBossAssassinProtocol())
         {
            return;
         }
         if(closestTarget != null && closestTarget.isAlive())
         {
            if(Math.abs(closestTarget.px - unit.px) < 500)
            {
               if(Ninja(unit).isBoss)
               {
                  Ninja(unit).bossSpecialStealth();
               }
               else
               {
                  Ninja(unit).stealth();
               }
            }
         }
      }

      private function getBossPriorityTarget() : Unit
      {
         var enemy:Unit = null;
         var best:Unit = null;
         var bestPriority:int = 999;
         var priority:int = 0;
         if(unit.team != null && unit.team.game != null && this.cachedBossPriorityTargetFrame == unit.team.game.frame)
         {
            return this.cachedBossPriorityTarget;
         }
         best = this.getLockedBossPriorityTarget();
         if(best != null)
         {
            this.cacheBossPriorityTarget(best);
            return best;
         }
         for each(enemy in unit.team.enemyTeam.units)
         {
            if(enemy == null || !enemy.isAlive())
            {
               continue;
            }
            priority = this.getBossTargetPriority(enemy);
            if(priority < bestPriority)
            {
               bestPriority = priority;
               best = enemy;
            }
         }
         if(best != null)
         {
            this.lockBossFocusTarget(best);
         }
         this.cacheBossPriorityTarget(best);
         return best;
      }

      private function cacheBossPriorityTarget(target:Unit) : void
      {
         this.cachedBossPriorityTarget = target;
         if(unit.team != null && unit.team.game != null)
         {
            this.cachedBossPriorityTargetFrame = unit.team.game.frame;
         }
      }

      private function getBossTargetPriority(enemy:Unit) : int
      {
         if(enemy is Archer)
         {
            return 1;
         }
         if(enemy is Monk)
         {
            return 2;
         }
         if(enemy is Magikill)
         {
            return 3;
         }
         if(enemy is EnslavedGiant)
         {
            return 4;
         }
         return 10 + int(Math.abs(enemy.px - unit.px) / 100);
      }

      private function startBossRetreatMove(game:StickWar) : void
      {
         var retreat:MoveCommand = new MoveCommand(game);
         retreat.type = UnitCommand.MOVE;
         retreat.goalX = unit.team.homeX + unit.team.direction * 150;
         retreat.goalY = game.map.height / 2;
         retreat.realX = retreat.goalX;
         retreat.realY = retreat.goalY;
         setCommand(game,retreat);
      }

      private function updateBossRetreat(game:StickWar) : void
      {
         if(unit.health >= unit.maxHealth * Ninja(unit).bossReturnHealthRatio)
         {
            if(unit.isGarrisoned)
            {
               unit.ungarrison();
            }
            this.finishBossRetreat(game);
            return;
         }
         if(!unit.isGarrisoned)
         {
            this.startBossRetreatMove(game);
            if(Math.abs(unit.px - unit.team.homeX) < 100)
            {
               unit.garrison();
            }
         }
         if(unit.isGarrisoned)
         {
            unit.health = Math.min(unit.maxHealth,unit.health + 0.15);
         }
         baseUpdate(game);
      }

      private function finishBossRetreat(game:StickWar) : void
      {
         var attackMove:AttackMoveCommand = new AttackMoveCommand(game);
         attackMove.type = UnitCommand.ATTACK_MOVE;
         attackMove.goalX = unit.team.enemyTeam.statue.px;
         attackMove.goalY = game.map.height / 2;
         attackMove.realX = attackMove.goalX;
         attackMove.realY = attackMove.goalY;
         setCommand(game,attackMove);
      }

      private function tryBossAssassinMovement() : Boolean
      {
         var target:Unit = this.getBossPriorityTarget();
         var flankX:Number = NaN;
         var flankY:Number = NaN;
         if(!this.shouldUseBossAssassinProtocol())
         {
            this.clearBossFocusTarget();
            return false;
         }
         if(target == null || !target.isAlive() || Ninja(unit).bossIsRetreating || Ninja(unit).bossEmergencySortie || unit.isGarrisoned)
         {
            return false;
         }
         if(Ninja(unit).hasBossWhiffPenalty())
         {
            return false;
         }
         if(this.getBossTargetPriority(target) > 4)
         {
            return false;
         }
         this.lockBossFocusTarget(target);
         if(!Ninja(unit).isStealthed && Ninja(unit).stealthCooldown() == 0)
         {
            Ninja(unit).bossSpecialStealth();
         }
         if(Ninja(unit).isStealthed)
         {
            return false;
         }
         if(unit.mayAttack(target))
         {
            return false;
         }
         if(!this.hasBossFrontlineBlockers(target) && Math.abs(target.px - unit.px) < 220)
         {
            return false;
         }
         flankX = target.px - target.team.direction * 140;
         flankY = target.py + this.getBossFlankYOffset(target);
         if(Math.abs(unit.px - flankX) < 25 && Math.abs(unit.py - flankY) < 25)
         {
            return false;
         }
         Ninja(unit).isBossMovementLocked = true;
         unit.mayWalkThrough = true;
         unit.walk((flankX - unit.px) / 60,(flankY - unit.py) / 60,Util.sgn(flankX - unit.px));
         unit.faceDirection(target.px - unit.px);
         return true;
      }

      private function tryBossAssassinSquadMovement() : Boolean
      {
         var leader:Ninja = null;
         var target:Unit = null;
         var flankX:Number = NaN;
         var flankY:Number = NaN;
         leader = this.getNearbyBossAssassinLeader();
         if(leader == null)
         {
            return false;
         }
         target = this.getBossSquadTargetForLeader(leader);
         if(target == null || !target.isAlive() || !target.isTargetable())
         {
            return false;
         }
         if(Ninja(unit).isStealthed)
         {
            return false;
         }
         if(unit.mayAttack(target))
         {
            return false;
         }
         if(Ninja(unit).stealthCooldown() == 0)
         {
            Ninja(unit).stealth();
         }
         flankX = target.px - target.team.direction * 140;
         flankY = target.py + this.getBossSquadFlankYOffset(leader,target);
         if(Math.abs(unit.px - flankX) < 25 && Math.abs(unit.py - flankY) < 25)
         {
            return false;
         }
         unit.isBossMovementLocked = true;
         unit.mayWalkThrough = true;
         unit.walk((flankX - unit.px) / 60,(flankY - unit.py) / 60,Util.sgn(flankX - unit.px));
         unit.faceDirection(target.px - unit.px);
         return true;
      }

      private function shouldUseBossAssassinProtocol() : Boolean
      {
         return unit.team.currentAttackState == Team.G_ATTACK && this.countNearbyAlliedAttackers() >= 2;
      }

      private function countNearbyAlliedAttackers() : int
      {
         var ally:Unit = null;
         var count:int = 0;
         if(unit.team != null && unit.team.game != null && this.cachedNearbyAttackerCountFrame == unit.team.game.frame)
         {
            return this.cachedNearbyAttackerCount;
         }
         for each(ally in unit.team.units)
         {
            if(ally == null || ally == unit || !ally.isAlive() || ally.isGarrisoned)
            {
               continue;
            }
            if(ally.type == Unit.U_MINER || ally.type == Unit.U_CHAOS_MINER || ally.type == Unit.U_MONK)
            {
               continue;
            }
            if(Math.abs(ally.px - unit.px) < 280 && Math.abs(ally.py - unit.py) < 120)
            {
               ++count;
            }
         }
         this.cachedNearbyAttackerCount = count;
         if(unit.team != null && unit.team.game != null)
         {
            this.cachedNearbyAttackerCountFrame = unit.team.game.frame;
         }
         return count;
      }

      private function getLockedBossPriorityTarget() : Unit
      {
         var locked:Unit = null;
         if(this.bossFocusFrames <= 0 || this.bossFocusTargetId == -1)
         {
            return null;
         }
         if(!(this.bossFocusTargetId in unit.team.enemyTeam.game.units))
         {
            this.clearBossFocusTarget();
            return null;
         }
         locked = unit.team.enemyTeam.game.units[this.bossFocusTargetId];
         if(locked == null || !locked.isAlive() || !locked.isTargetable())
         {
            this.clearBossFocusTarget();
            return null;
         }
         return locked;
      }

      private function lockBossFocusTarget(target:Unit) : void
      {
         this.bossFocusTargetId = target.id;
         this.bossFocusFrames = BOSS_TARGET_LOCK_FRAMES;
      }

      private function clearBossFocusTarget() : void
      {
         this.bossFocusTargetId = -1;
         this.bossFocusFrames = 0;
      }

      private function hasBossFrontlineBlockers(target:Unit) : Boolean
      {
         var enemy:Unit = null;
         var minX:Number = Math.min(unit.px,target.px);
         var maxX:Number = Math.max(unit.px,target.px);
         for each(enemy in unit.team.enemyTeam.units)
         {
            if(enemy == null || !enemy.isAlive() || enemy == target)
            {
               continue;
            }
            if(enemy.type == Unit.U_SWORDWRATH || enemy.type == Unit.U_SPEARTON || enemy.type == Unit.U_NINJA || enemy.type == Unit.U_ENSLAVED_GIANT)
            {
               if(enemy.px > minX && enemy.px < maxX && Math.abs(enemy.py - target.py) < 85)
               {
                  return true;
               }
            }
         }
         return false;
      }

      private function getBossFlankYOffset(target:Unit) : Number
      {
         if(int(target.px + target.py) % 2 == 0)
         {
            return 70;
         }
         return -70;
      }

      private function getNearbyBossAssassinLeader() : Ninja
      {
         var ally:Unit = null;
         if(unit.team != null && unit.team.game != null && this.cachedNearbyBossLeaderFrame == unit.team.game.frame)
         {
            return this.cachedNearbyBossLeader;
         }
         for each(ally in unit.team.unitGroups[Unit.U_NINJA])
         {
            if(!(ally is Ninja) || ally == unit || !ally.isAlive())
            {
               continue;
            }
            if(!Ninja(ally).isBoss || Ninja(ally).bossIsRetreating || Ninja(ally).bossEmergencySortie || ally.isGarrisoned || !Ninja(ally).isStealthed || Ninja(ally).hasBossWhiffPenalty())
            {
               continue;
            }
            if(ally.team.currentAttackState != Team.G_ATTACK)
            {
               continue;
            }
            if(Math.abs(ally.px - unit.px) <= BOSS_SQUAD_RADIUS_X && Math.abs(ally.py - unit.py) <= BOSS_SQUAD_RADIUS_Y)
            {
               this.cachedNearbyBossLeader = Ninja(ally);
               if(unit.team != null && unit.team.game != null)
               {
                  this.cachedNearbyBossLeaderFrame = unit.team.game.frame;
               }
               return this.cachedNearbyBossLeader;
            }
         }
         this.cachedNearbyBossLeader = null;
         if(unit.team != null && unit.team.game != null)
         {
            this.cachedNearbyBossLeaderFrame = unit.team.game.frame;
         }
         return null;
      }

      private function getBossSquadTargetForLeader(leader:Ninja) : Unit
      {
         var target:Unit = null;
         if(leader == null || !(leader.ai is NinjaAi))
         {
            return null;
         }
         target = NinjaAi(leader.ai).getClosestTarget();
         return target != null && target.isAlive() && target.isTargetable() ? target : null;
      }

      private function getBossSquadFlankYOffset(leader:Ninja, target:Unit) : Number
      {
         var index:int = unit.id % 3;
         if(index == 0)
         {
            return this.getBossFlankYOffset(target) - 35;
         }
         if(index == 1)
         {
            return this.getBossFlankYOffset(target) + 35;
         }
         return this.getBossFlankYOffset(target);
      }

   }
}
