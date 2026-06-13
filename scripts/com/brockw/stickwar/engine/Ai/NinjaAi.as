package com.brockw.stickwar.engine.Ai
{
   import com.brockw.game.Util;
   import com.brockw.stickwar.engine.Ai.command.AttackMoveCommand;
   import com.brockw.stickwar.engine.Ai.command.MoveCommand;
   import com.brockw.stickwar.engine.Ai.command.StandCommand;
   import com.brockw.stickwar.engine.Ai.command.UnitCommand;
   import com.brockw.stickwar.engine.StickWar;
   import com.brockw.stickwar.engine.Team.Team;
   import com.brockw.stickwar.engine.units.Archer;
   import com.brockw.stickwar.engine.units.EnslavedGiant;
   import com.brockw.stickwar.engine.units.Magikill;
   import com.brockw.stickwar.engine.units.Monk;
   import com.brockw.stickwar.engine.units.Ninja;
   import com.brockw.stickwar.engine.units.Statue;
   import com.brockw.stickwar.engine.units.Unit;
   
   public class NinjaAi extends UnitAi
   {
      private static const BOSS_TARGET_LOCK_FRAMES:int = 30;

      private static const BOSS_SPECIAL_ABORT_FRAMES:int = 30 * 3;

      private static const BOSS_OPENER_TRIGGER_RANGE:Number = 500;

      private static const BOSS_ENEMY_BASE_RADIUS:Number = 650;

      private static const BOSS_HEALER_ANCHOR_X:Number = 90;

      private static const BOSS_HEALER_ANCHOR_Y:Number = 60;

      private static const BOSS_ASSASSIN_STRIKE_OFFSET:Number = 20;

      private static const BOSS_ASSASSIN_BACK_STRIKE_OFFSET:Number = 95;

      private static const BOSS_SPECIAL_RESET_DISTANCE:Number = 260;

      private static const BOSS_SQUAD_RADIUS_X:Number = 260;

      private static const BOSS_SQUAD_RADIUS_Y:Number = 120;

      private static const BOSS_GARRISON_STUCK_FRAMES:int = 30;

      private var bossFocusTargetId:int;

      private var bossFocusFrames:int;

      private var cachedBossPriorityTarget:Unit;

      private var cachedBossPriorityTargetFrame:int;

      private var cachedNearbyAttackerCount:int;

      private var cachedNearbyAttackerCountFrame:int;

      private var cachedNearbyBossLeader:Ninja;

      private var cachedNearbyBossLeaderFrame:int;

      private var bossAssignedHealerId:int;

      private var bossAssignedHealerHealth:Number;

      private var bossNeedsHealerRefresh:Boolean;

      private var bossSpecialAbortFrames:int;

      private var lastFriendlyStatueHealth:Number;

      private var bossGarrisonMoveIssued:Boolean;

      private var bossGarrisonLastPx:Number;

      private var bossGarrisonLastPy:Number;

      private var bossGarrisonStuckFrames:int;
      
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
         this.bossAssignedHealerId = -1;
         this.bossAssignedHealerHealth = 0;
         this.bossNeedsHealerRefresh = true;
         this.bossSpecialAbortFrames = 0;
         this.lastFriendlyStatueHealth = -1;
         this.bossGarrisonMoveIssued = false;
         this.bossGarrisonLastPx = 0;
         this.bossGarrisonLastPy = 0;
         this.bossGarrisonStuckFrames = 0;
      }
      
      override public function update(game:StickWar) : void
      {
         var statueDamagedThisFrame:Boolean = false;
         if(!Ninja(unit).isBoss)
         {
            unit.isBossMovementLocked = false;
         }
         if(this.bossFocusFrames > 0)
         {
            --this.bossFocusFrames;
         }
         if(Ninja(unit).isBoss)
         {
            statueDamagedThisFrame = this.didFriendlyStatueTakeDamageThisFrame();
            if(Ninja(unit).shouldStartBossLostPhase())
            {
               unit.startCampaignBossEscape();
            }
         }
         else if(unit.shouldStartCampaignBossEscape())
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
               if(Ninja(unit).isBossCautiousPhaseDisabled || this.isEnemyPlayerDefendingBase())
               {
                  Ninja(unit).enterBossFinalStand();
                  this.clearBossHealerTarget();
                  this.bossSpecialAbortFrames = 0;
                  this.resetBossGarrisonRetreat();
               }
               else
               {
                  Ninja(unit).startBossRetreat();
                  this.clearBossHealerTarget();
                  this.bossNeedsHealerRefresh = true;
                  this.bossSpecialAbortFrames = 0;
                  this.resetBossGarrisonRetreat();
               }
            }
            if(Ninja(unit).bossIsRetreating)
            {
               this.clearBossFocusTarget();
               Ninja(unit).isBossMovementLocked = true;
               if(this.updateBossCautious(game,statueDamagedThisFrame))
               {
                  return;
               }
            }
            Ninja(unit).tryBossChainCloak();
            this.updateBossSpecialAbortState();
            if(this.updateBossSpecialReset())
            {
               return;
            }
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
         if(!Ninja(unit).isBossSpecialTargetingActive())
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
         var closestTarget:Unit = null;
         if(Ninja(unit).isBoss && (Ninja(unit).hasBossWhiffPenalty() || Ninja(unit).hasBossAbilitySpawnLock()))
         {
            return;
         }
         if(Ninja(unit).isBoss && (Ninja(unit).bossIsCautious || Ninja(unit).campaignBossEscaping || Ninja(unit).isBossSpecialTargetingActive()))
         {
            return;
         }
         closestTarget = Ninja(unit).isBoss ? super.getClosestTarget() : this.getClosestTarget();
         if(closestTarget != null && closestTarget.isAlive())
         {
            if(Math.abs(closestTarget.px - unit.px) < BOSS_OPENER_TRIGGER_RANGE)
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
         else if(Ninja(unit).isBossSpecialTargetingActive() && unit.team.enemyTeam != null && unit.team.enemyTeam.statue != null && unit.team.enemyTeam.statue.isAlive())
         {
            best = unit.team.enemyTeam.statue;
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
         retreat.goalX = unit.team.homeX + unit.team.direction * 120;
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
            if(this.updateBossGarrisonRetreat(game,true))
            {
               unit.health = Math.min(unit.maxHealth,unit.health + 0.15);
               return;
            }
         }
         if(unit.isGarrisoned)
         {
            unit.health = Math.min(unit.maxHealth,unit.health + 0.15);
            return;
         }
         baseUpdate(game);
      }

      private function finishBossRetreat(game:StickWar) : void
      {
         var attackMove:AttackMoveCommand = new AttackMoveCommand(game);
         this.resetBossGarrisonRetreat();
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
         var strikeX:Number = NaN;
         var strikeY:Number = NaN;
         var closeToStrike:Boolean = false;
         if(!Ninja(unit).isBossSpecialTargetingActive())
         {
            this.clearBossFocusTarget();
            return false;
         }
         if(target == null || !target.isAlive() || Ninja(unit).bossIsRetreating || unit.isGarrisoned)
         {
            return false;
         }
         if(Ninja(unit).hasBossWhiffPenalty())
         {
            return false;
         }
         this.lockBossFocusTarget(target);
         if(unit.mayAttack(target))
         {
            Ninja(unit).isBossMovementLocked = true;
            unit.faceDirection(target.px - unit.px);
            unit.attack();
            return true;
         }
         strikeX = target is Statue ? target.px - target.team.direction * 90 : target.px - target.team.direction * this.getBossStrikeOffset(target);
         strikeY = target.py;
         closeToStrike = Math.abs(unit.px - strikeX) < 8 && Math.abs(unit.py - strikeY) < 8;
         if(closeToStrike)
         {
            Ninja(unit).isBossMovementLocked = true;
            unit.mayWalkThrough = true;
            unit.walk(0,0,Util.sgn(target.px - unit.px));
            unit.faceDirection(target.px - unit.px);
            return true;
         }
         Ninja(unit).isBossMovementLocked = true;
         unit.mayWalkThrough = true;
         unit.walk((strikeX - unit.px) / 60,(strikeY - unit.py) / 60,Util.sgn(target.px - unit.px));
         unit.faceDirection(target.px - unit.px);
         return true;
      }

      private function getBossStrikeOffset(target:Unit) : Number
      {
         if(target is Archer)
         {
            return BOSS_ASSASSIN_BACK_STRIKE_OFFSET;
         }
         return BOSS_ASSASSIN_STRIKE_OFFSET;
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
         return Ninja(unit).isBossSpecialTargetingActive();
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
            if(ally == null || ally == unit || !ally.isAlive() || ally.isGarrisoned || ally is Statue)
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

      private function didFriendlyStatueTakeDamageThisFrame() : Boolean
      {
         var currentHealth:Number = NaN;
         var didTakeDamage:Boolean = false;
         if(unit.team == null || unit.team.statue == null)
         {
            return false;
         }
         currentHealth = unit.team.statue.health;
         if(this.lastFriendlyStatueHealth < 0)
         {
            this.lastFriendlyStatueHealth = currentHealth;
            return false;
         }
         didTakeDamage = currentHealth < this.lastFriendlyStatueHealth;
         this.lastFriendlyStatueHealth = currentHealth;
         return didTakeDamage;
      }

      private function updateBossSpecialAbortState() : void
      {
         if(!Ninja(unit).isBossSpecialTargetingActive() || Ninja(unit).bossIsCautious || unit.isGarrisoned)
         {
            this.bossSpecialAbortFrames = 0;
            return;
         }
         if(unit.team.currentAttackState == Team.G_ATTACK || this.hasImmediateBossEngageTarget())
         {
            this.bossSpecialAbortFrames = 0;
            return;
         }
         ++this.bossSpecialAbortFrames;
         if(this.bossSpecialAbortFrames >= BOSS_SPECIAL_ABORT_FRAMES)
         {
            Ninja(unit).failBossSpecial();
            this.bossSpecialAbortFrames = 0;
            this.clearBossFocusTarget();
         }
      }

      private function updateBossSpecialReset() : Boolean
      {
         var anchor:Unit = null;
         var resetX:Number = NaN;
         var resetY:Number = NaN;
         if(!Ninja(unit).needsBossSpecialReset)
         {
            return false;
         }
         anchor = this.getBossSpecialResetAnchor();
         if(anchor != null)
         {
            resetX = anchor.px - unit.team.direction * BOSS_SPECIAL_RESET_DISTANCE;
            resetY = anchor.py;
         }
         else
         {
            resetX = unit.team.medianPosition - unit.team.direction * BOSS_SPECIAL_RESET_DISTANCE;
            resetY = unit.team.game.map.height / 2;
            if(unit.team.direction * resetX > unit.team.direction * unit.team.homeX)
            {
               resetX = unit.team.homeX + unit.team.direction * 220;
            }
         }
         if(Math.abs(unit.px - resetX) < 35 && Math.abs(unit.py - resetY) < 55)
         {
            Ninja(unit).finishBossSpecialReset();
            return false;
         }
         Ninja(unit).isBossMovementLocked = true;
         unit.mayWalkThrough = true;
         unit.walk((resetX - unit.px) / 90,(resetY - unit.py) / 90,Util.sgn(resetX - unit.px));
         unit.faceDirection(resetX - unit.px);
         return true;
      }

      private function getBossSpecialResetAnchor() : Unit
      {
         var ally:Unit = null;
         var best:Unit = null;
         for each(ally in unit.team.units)
         {
            if(ally == null || ally == unit || !ally.isAlive() || ally.isGarrisoned)
            {
               continue;
            }
            if(ally.type == Unit.U_MINER || ally.type == Unit.U_CHAOS_MINER)
            {
               continue;
            }
            if(best == null || ally.px * unit.team.direction > best.px * unit.team.direction)
            {
               best = ally;
            }
         }
         return best;
      }

      private function hasImmediateBossEngageTarget() : Boolean
      {
         var target:Unit = super.getClosestTarget();
         return target != null && target.isAlive() && Math.abs(target.px - unit.px) < BOSS_OPENER_TRIGGER_RANGE;
      }

      private function isEnemyPlayerDefendingBase() : Boolean
      {
         var enemy:Unit = null;
         if(unit.team == null || unit.team.enemyTeam == null || unit.team.enemyTeam.statue == null)
         {
            return false;
         }
         for each(enemy in unit.team.enemyTeam.units)
         {
            if(enemy != null && enemy.isAlive() && !enemy.isGarrisoned && enemy.type != Unit.U_STATUE && enemy.type != Unit.U_MINER && enemy.type != Unit.U_CHAOS_MINER && Math.abs(enemy.px - unit.team.enemyTeam.statue.px) <= BOSS_ENEMY_BASE_RADIUS)
            {
               return true;
            }
         }
         return false;
      }

      private function updateBossCautious(game:StickWar, statueDamagedThisFrame:Boolean) : Boolean
      {
         var healer:Monk = this.getBossHealingTarget();
         if(unit.health >= unit.maxHealth)
         {
            Ninja(unit).finishBossCautious();
            this.clearBossHealerTarget();
            this.bossSpecialAbortFrames = 0;
            if(unit.isGarrisoned)
            {
               unit.ungarrison();
            }
            this.finishBossCautiousRecovery(game);
            return false;
         }
         if(statueDamagedThisFrame)
         {
            if(unit.isGarrisoned)
            {
               unit.ungarrison();
            }
            Ninja(unit).enterBossFinalStand();
            this.clearBossHealerTarget();
            this.bossSpecialAbortFrames = 0;
            this.finishBossRetreat(game);
            return false;
         }
         if(healer != null)
         {
            if(healer.health < this.bossAssignedHealerHealth)
            {
               Ninja(unit).triggerBossEscapeCloak();
               this.clearBossHealerTarget();
               this.bossNeedsHealerRefresh = true;
               healer = null;
            }
            else
            {
               this.bossAssignedHealerHealth = healer.health;
            }
         }
         if(healer == null && this.bossNeedsHealerRefresh)
         {
            healer = this.findBossHealer();
         }
         if(healer != null)
         {
            this.resetBossGarrisonRetreat();
            if(unit.isGarrisoned)
            {
               unit.ungarrison();
            }
            this.moveBossNearHealer(healer);
            return true;
         }
         if(!unit.isGarrisoned)
         {
            if(this.updateBossGarrisonRetreat(game,!statueDamagedThisFrame))
            {
               unit.health = Math.min(unit.maxHealth,unit.health + 0.15);
               return true;
            }
         }
         if(unit.isGarrisoned)
         {
            unit.health = Math.min(unit.maxHealth,unit.health + 0.15);
            return true;
         }
         baseUpdate(game);
         return true;
      }

      private function updateBossGarrisonRetreat(game:StickWar, allowGarrison:Boolean) : Boolean
      {
         if(unit.isGarrisoned)
         {
            this.garrisonBossInsideCastle(game);
            return true;
         }
         if(Ninja(unit).isAttackAnimationActive)
         {
            this.resetBossGarrisonRetreat();
            return false;
         }
         if(!this.bossGarrisonMoveIssued)
         {
            this.startBossRetreatMove(game);
            this.bossGarrisonMoveIssued = true;
            this.bossGarrisonLastPx = unit.px;
            this.bossGarrisonLastPy = unit.py;
            this.bossGarrisonStuckFrames = 0;
            return false;
         }
         if(Math.abs(unit.px - this.bossGarrisonLastPx) < 2 && Math.abs(unit.py - this.bossGarrisonLastPy) < 2)
         {
            ++this.bossGarrisonStuckFrames;
         }
         else
         {
            this.bossGarrisonStuckFrames = 0;
         }
         this.bossGarrisonLastPx = unit.px;
         this.bossGarrisonLastPy = unit.py;
         if(allowGarrison && this.bossGarrisonStuckFrames >= BOSS_GARRISON_STUCK_FRAMES)
         {
            this.garrisonBossInsideCastle(game);
            return true;
         }
         return false;
      }

      private function finishBossCautiousRecovery(game:StickWar) : void
      {
         var stand:StandCommand = new StandCommand(game);
         this.resetBossGarrisonRetreat();
         stand.type = UnitCommand.STAND;
         setCommand(game,stand);
      }

      private function resetBossGarrisonRetreat() : void
      {
         this.bossGarrisonMoveIssued = false;
         this.bossGarrisonStuckFrames = 0;
         this.bossGarrisonLastPx = unit.px;
         this.bossGarrisonLastPy = unit.py;
      }

      private function garrisonBossInsideCastle(game:StickWar) : void
      {
         var stand:StandCommand = new StandCommand(game);
         unit.x = unit.px = unit.team.homeX - unit.team.direction * game.map.screenWidth / 3;
         unit.y = unit.py = game.map.height / 2;
         unit.garrison();
         this.resetBossGarrisonRetreat();
         stand.type = UnitCommand.STAND;
         setCommand(game,stand);
      }

      private function moveBossNearHealer(healer:Monk) : void
      {
         var deltaX:Number = healer.px - unit.px;
         var deltaY:Number = healer.py - unit.py;
         unit.isBossMovementLocked = true;
         unit.mayWalkThrough = true;
         if(Math.abs(deltaX) <= BOSS_HEALER_ANCHOR_X && Math.abs(deltaY) <= BOSS_HEALER_ANCHOR_Y)
         {
            unit.walk(0,0,unit.team.direction);
            unit.faceDirection(unit.team.enemyTeam.statue.px - unit.px);
            return;
         }
         unit.walk(deltaX / 100,deltaY / 100,Util.sgn(deltaX));
         unit.faceDirection(healer.px - unit.px);
      }

      private function getBossHealingTarget() : Monk
      {
         var healer:Monk = null;
         if(this.bossAssignedHealerId == -1 || !(this.bossAssignedHealerId in unit.team.game.units))
         {
            this.clearBossHealerTarget();
            return null;
         }
         healer = unit.team.game.units[this.bossAssignedHealerId] as Monk;
         if(healer == null || !healer.isAlive() || healer.isGarrisoned || healer.team != unit.team)
         {
            this.clearBossHealerTarget();
            return null;
         }
         return healer;
      }

      private function clearBossHealerTarget() : void
      {
         this.bossAssignedHealerId = -1;
         this.bossAssignedHealerHealth = 0;
         this.bossNeedsHealerRefresh = true;
      }

      private function findBossHealer() : Monk
      {
         var ally:Unit = null;
         var monk:Monk = null;
         var bossMonk:Monk = null;
         var nearestMonk:Monk = null;
         var bossDistance:Number = Number.MAX_VALUE;
         var monkDistance:Number = Number.MAX_VALUE;
         var distance:Number = NaN;
         for each(ally in unit.team.units)
         {
            if(!(ally is Monk) || !ally.isAlive() || ally.isGarrisoned)
            {
               continue;
            }
            monk = Monk(ally);
            distance = Math.abs(monk.px - unit.px) + Math.abs(monk.py - unit.py);
            if(monk.isBossUnit)
            {
               if(distance < bossDistance)
               {
                  bossDistance = distance;
                  bossMonk = monk;
               }
            }
            else if(distance < monkDistance)
            {
               monkDistance = distance;
               nearestMonk = monk;
            }
         }
         monk = bossMonk != null ? bossMonk : nearestMonk;
         this.bossNeedsHealerRefresh = false;
         if(monk != null)
         {
            this.bossAssignedHealerId = monk.id;
            this.bossAssignedHealerHealth = monk.health;
         }
         return monk;
      }

   }
}
