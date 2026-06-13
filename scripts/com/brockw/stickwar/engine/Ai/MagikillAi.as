package com.brockw.stickwar.engine.Ai
{
   import com.brockw.stickwar.engine.Ai.command.NukeCommand;
   import com.brockw.stickwar.engine.Ai.command.PoisonDartCommand;
   import com.brockw.stickwar.engine.Ai.command.StunCommand;
   import com.brockw.stickwar.engine.Ai.command.HoldCommand;
   import com.brockw.stickwar.engine.Ai.command.UnitCommand;
   import com.brockw.stickwar.engine.StickWar;
   import com.brockw.stickwar.engine.Team.Team;
   import com.brockw.stickwar.engine.Team.Tech;
   import com.brockw.stickwar.engine.units.Magikill;
   import com.brockw.stickwar.engine.units.Medusa;
   import com.brockw.stickwar.engine.units.Unit;
   import com.brockw.stickwar.engine.units.Wall;
   
   public class MagikillAi extends UnitAi
   {
      private static const NUKE_WEIGHT:int = 5;
      
      private static const STUN_WEIGHT:int = 3;
      
      private static const POISON_WEIGHT:int = 2;

      private static const BOSS_CASTING_DISTANCE:Number = 320;

      private static const BOSS_PULLBACK_DISTANCE:Number = 390;

      private static const BOSS_MELEE_LAST_RESORT_DISTANCE:Number = 95;

      private static const BOSS_ATTACK_ACQUIRE_RANGE_SQR:Number = 640000;
      
      private var nukeCommand:NukeCommand;
      
      private var stunCommand:StunCommand;
      
      private var poisonDartCommand:PoisonDartCommand;
      
      private var shouldRestoreAutoSpellCommand:Boolean;
      
      private var holdCommand:HoldCommand;

      private var cachedNearestTargetAny:Unit;

      private var cachedNearestTargetAnyFrame:int;

      private var cachedNearestTargetInRange:Unit;

      private var cachedNearestTargetInRangeFrame:int;

      private var cachedNearestSharedTarget:Unit;

      private var cachedNearestSharedTargetFrame:int;

      private var cachedNearestSharedTargetMask:int;

      private var bossCommandAfterSummon:UnitCommand;

      private var bossWasSummoning:Boolean;

      private var bossAttackIntent:Boolean;
      
      public function MagikillAi(s:Magikill)
      {
         super();
         unit = s;
         isNonAttackingMage = true;
         this.cachedNearestTargetAny = null;
         this.cachedNearestTargetAnyFrame = -1;
         this.cachedNearestTargetInRange = null;
         this.cachedNearestTargetInRangeFrame = -1;
         this.cachedNearestSharedTarget = null;
         this.cachedNearestSharedTargetFrame = -1;
         this.cachedNearestSharedTargetMask = -1;
         this.bossCommandAfterSummon = null;
         this.bossWasSummoning = false;
         this.bossAttackIntent = false;
      }
      
      override public function update(game:StickWar) : void
      {
         var magikill:Magikill = Magikill(unit);
         if(unit.shouldStartCampaignBossEscape())
         {
            unit.startCampaignBossEscape();
         }
         if(unit.updateCampaignBossEscape(game))
         {
            return;
         }
         unit.isBusyForSpell = false;
         this.ensureCommands(game);
         if(unit.isConfused())
         {
            if(this.tryReaperControlSpell(game,magikill))
            {
               return;
            }
            baseUpdate(game);
            return;
         }
         if(magikill.isBoss)
         {
            this.updateBossGenericCasting(game,magikill);
            return;
         }
         if(this.tryFinishInitialSpawnMove(game))
         {
            return;
         }
         if(currentCommand.type == UnitCommand.CURE)
         {
            Magikill(unit).autoCastMode = (Magikill(unit).autoCastMode + 1) % 3;
            restoreMove(game);
            baseUpdate(game);
         }
         else if(currentCommand.type == UnitCommand.NUKE || currentCommand.type == UnitCommand.STUN || currentCommand.type == UnitCommand.POISON_DART)
         {
            if(this.shouldRestoreAutoSpellCommand && !this.isAutoSpellTargetStillValid(game))
            {
               this.finishSpellCommand(game);
               return;
            }
            this.updateSpellCommandTargetPosition(game);
            if(!currentCommand.inRange(unit))
            {
               unit.mayWalkThrough = true;
               unit.isBusyForSpell = true;
               unit.walk((currentCommand.realX - unit.px) / 100,(currentCommand.realY - unit.py) / 100,(currentCommand.realX - unit.px) / 100);
            }
            else if(currentCommand.type == UnitCommand.NUKE)
            {
               Magikill(unit).nukeSpell(NukeCommand(currentCommand).realX,NukeCommand(currentCommand).realY);
               this.finishSpellCommand(game);
            }
            else if(currentCommand.type == UnitCommand.STUN)
            {
               Magikill(unit).stunSpell(StunCommand(currentCommand).realX,StunCommand(currentCommand).realY);
               this.finishSpellCommand(game);
            }
            else if(currentCommand.type == UnitCommand.POISON_DART)
            {
               Magikill(unit).poisonDartSpell(PoisonDartCommand(currentCommand).realX,PoisonDartCommand(currentCommand).realY);
               this.finishSpellCommand(game);
            }
         }
         else
         {
            this.shouldRestoreAutoSpellCommand = false;
            this.tryAutoCast(game);
            if(currentCommand.type == UnitCommand.NUKE || currentCommand.type == UnitCommand.STUN || currentCommand.type == UnitCommand.POISON_DART)
            {
               return;
            }
            baseUpdate(game);
         }
      }

      private function updateSpellCommandTargetPosition(game:StickWar) : void
      {
         var target:Unit = null;
         if(currentCommand.targetId == -1 || !(currentCommand.targetId in game.units) || !(game.units[currentCommand.targetId] is Unit))
         {
            return;
         }
         target = Unit(game.units[currentCommand.targetId]);
         if(target == null || !target.isAlive() || target.team == null || target.team.id == unit.team.id || !target.isTargetable())
         {
            return;
         }
         currentCommand.realX = target.px;
         currentCommand.realY = target.py;
      }

      private function tryReaperControlSpell(game:StickWar, magikill:Magikill) : Boolean
      {
         var target:Unit = null;
         if(unit.isReaperControlFallingBack() || magikill.isBusy())
         {
            return false;
         }
         target = this.getClosestConfusedAllyTarget();
         if(target == null)
         {
            return false;
         }
         if(magikill.nukeCooldown() == 0)
         {
            this.nukeCommand.realX = target.px;
            this.nukeCommand.realY = target.py;
            if(this.nukeCommand.inRange(magikill))
            {
               magikill.nukeSpell(target.px,target.py);
               return true;
            }
         }
         if(unit.team.tech.isResearched(Tech.MAGIKILL_WALL) && magikill.stunCooldown() == 0)
         {
            this.stunCommand.realX = target.px;
            this.stunCommand.realY = target.py;
            if(this.stunCommand.inRange(magikill))
            {
               magikill.stunSpell(target.px,target.py);
               return true;
            }
         }
         if(unit.team.tech.isResearched(Tech.MAGIKILL_POISON) && magikill.poisonDartCooldown() == 0)
         {
            this.poisonDartCommand.realX = target.px;
            this.poisonDartCommand.realY = target.py;
            if(this.poisonDartCommand.inRange(magikill))
            {
               magikill.poisonDartSpell(target.px,target.py);
               return true;
            }
         }
         return false;
      }

      override public function setCommand(game:StickWar, c:UnitCommand) : void
      {
         if(Magikill(unit).isBoss && Magikill(unit).isBusy() && this.shouldDeferBossCommand(c))
         {
            this.bossAttackIntent = false;
            this.bossCommandAfterSummon = c;
            this.commandQueue.clear();
            this.commandQueue.push(c);
            return;
         }
         if(Magikill(unit).isBoss && this.shouldDeferBossCommand(c))
         {
            this.bossAttackIntent = false;
         }
         super.setCommand(game,c);
      }

      private function updateBossGenericCasting(game:StickWar, magikill:Magikill) : void
      {
         var target:Unit = null;
         var castedSpell:Boolean = false;
         if(this.tryFinishInitialSpawnMove(game))
         {
            return;
         }
         if(magikill.bossWasRecentlyDamaged(game) && this.tryBossSummonAndCacheCommand(game,magikill))
         {
            return;
         }
         if(magikill.isBusy())
         {
            return;
         }
         if(this.restoreBossCommandAfterSummon(game))
         {
            return;
         }
         if(!this.commandQueue.isEmpty())
         {
            nextMove(game);
         }
         if((!this.isBossAttackIntent() || currentCommand.type == UnitCommand.HOLD || currentCommand.type == UnitCommand.STAND) && this.tryBossSummonAndCacheCommand(game,magikill))
         {
            return;
         }
         target = this.getClosestTarget();
         if(!Boolean(target))
         {
            baseUpdate(game);
            return;
         }
         this.updateBossAttackIntentFromTarget(target);
         if((currentCommand.type == UnitCommand.MOVE || currentCommand.type == UnitCommand.ATTACK_MOVE) && distanceToTarget(target) > BOSS_PULLBACK_DISTANCE && this.tryBossSummonAndCacheCommand(game,magikill))
         {
            return;
         }
         if(!this.isBossAttackIntent() && (currentCommand.type == UnitCommand.MOVE || currentCommand.type == UnitCommand.ATTACK_MOVE))
         {
            baseUpdate(game);
            return;
         }
         if(!this.isBossAttackIntent() && Math.abs(target.px - unit.px) > BOSS_PULLBACK_DISTANCE && !this.isDefensiveFormationMove())
         {
            unit.faceDirection(target.px - unit.px);
            return;
         }
         if(magikill.nukeCooldown() == 0)
         {
            this.nukeCommand.realX = target.px;
            this.nukeCommand.realY = target.py;
            if(this.nukeCommand.inRange(magikill))
            {
               magikill.nukeSpell(target.px,target.py);
               castedSpell = true;
            }
         }
         else if(unit.team.tech.isResearched(Tech.MAGIKILL_WALL) && magikill.stunCooldown() == 0)
         {
            this.stunCommand.realX = target.px;
            this.stunCommand.realY = target.py;
            if(this.stunCommand.inRange(magikill))
            {
               magikill.stunSpell(target.px,target.py);
               castedSpell = true;
            }
         }
         else if(unit.team.tech.isResearched(Tech.MAGIKILL_POISON) && magikill.poisonDartCooldown() == 0)
         {
            this.poisonDartCommand.realX = target.px;
            this.poisonDartCommand.realY = target.py;
            if(this.poisonDartCommand.inRange(magikill))
            {
               magikill.poisonDartSpell(target.px,target.py);
               castedSpell = true;
            }
         }
         if(castedSpell)
         {
            return;
         }
         if(this.canBossMoveToSpellRange() && this.hasBossSpellReady(magikill) && !this.canBossCastAnyReadySpell(magikill,target))
         {
            unit.walk((target.px - unit.px) / 100,(target.py - unit.py) / 160,target.px - unit.px);
            unit.faceDirection(target.px - unit.px);
            return;
         }
         if(this.isBossAttackIntent() && Math.abs(target.px - unit.px) > BOSS_PULLBACK_DISTANCE && currentCommand.type == UnitCommand.ATTACK_MOVE)
         {
            baseUpdate(game);
            return;
         }
         if(!this.isBossAttackIntent() && Math.abs(target.px - unit.px) > BOSS_PULLBACK_DISTANCE && this.isDefensiveFormationMove())
         {
            baseUpdate(game);
            return;
         }
         if((currentCommand.type == UnitCommand.HOLD || currentCommand.type == UnitCommand.STAND) && Math.abs(target.px - unit.px) > BOSS_PULLBACK_DISTANCE)
         {
            unit.faceDirection(target.px - unit.px);
            return;
         }
         if((!this.isBossAttackIntent() || distanceToTarget(target) <= BOSS_PULLBACK_DISTANCE) && this.tryBossSummonAndCacheCommand(game,magikill))
         {
            return;
         }
         this.updateBossCasterSpacing(game,magikill,target);
      }

      private function tryBossSummonAndCacheCommand(game:StickWar, magikill:Magikill) : Boolean
      {
         if(!magikill.tryBossSummonGuards(game))
         {
            return false;
         }
         this.bossWasSummoning = true;
         if(this.shouldDeferBossCommand(currentCommand))
         {
            this.bossCommandAfterSummon = currentCommand;
         }
         return true;
      }

      private function restoreBossCommandAfterSummon(game:StickWar) : Boolean
      {
         var command:UnitCommand = null;
         if(!this.bossWasSummoning)
         {
            return false;
         }
         this.bossWasSummoning = false;
         if(!this.commandQueue.isEmpty())
         {
            nextMove(game);
            this.bossCommandAfterSummon = null;
            return true;
         }
         command = this.bossCommandAfterSummon;
         this.bossCommandAfterSummon = null;
         if(command == null)
         {
            return false;
         }
         super.setCommand(game,command);
         this.bossAttackIntent = false;
         return true;
      }

      private function hasBossSpellReady(magikill:Magikill) : Boolean
      {
         return magikill.nukeCooldown() == 0 || unit.team.tech.isResearched(Tech.MAGIKILL_WALL) && magikill.stunCooldown() == 0 || unit.team.tech.isResearched(Tech.MAGIKILL_POISON) && magikill.poisonDartCooldown() == 0;
      }

      private function canBossCastAnyReadySpell(magikill:Magikill, target:Unit) : Boolean
      {
         if(magikill.nukeCooldown() == 0)
         {
            this.nukeCommand.realX = target.px;
            this.nukeCommand.realY = target.py;
            if(this.nukeCommand.inRange(magikill))
            {
               return true;
            }
         }
         if(unit.team.tech.isResearched(Tech.MAGIKILL_WALL) && magikill.stunCooldown() == 0)
         {
            this.stunCommand.realX = target.px;
            this.stunCommand.realY = target.py;
            if(this.stunCommand.inRange(magikill))
            {
               return true;
            }
         }
         if(unit.team.tech.isResearched(Tech.MAGIKILL_POISON) && magikill.poisonDartCooldown() == 0)
         {
            this.poisonDartCommand.realX = target.px;
            this.poisonDartCommand.realY = target.py;
            if(this.poisonDartCommand.inRange(magikill))
            {
               return true;
            }
         }
         return false;
      }

      private function distanceToTarget(target:Unit) : Number
      {
         return Math.abs(target.px - unit.px);
      }

      private function updateBossCasterSpacing(game:StickWar, magikill:Magikill, target:Unit) : void
      {
         var distance:Number = Math.abs(target.px - unit.px);
         var yMove:Number = 0;
         var retreatDir:int = target.px < unit.px ? 1 : -1;
         var approachDir:int = target.px > unit.px ? 1 : -1;
         unit.isBusyForSpell = false;
         if(target.type != Unit.U_WALL && Math.abs(target.px - unit.px) < 240)
         {
            yMove = (target.py - unit.py) / 100;
         }
         if(distance <= BOSS_MELEE_LAST_RESORT_DISTANCE && Math.abs(unit.px - unit.team.homeX) < 160 && unit.mayAttack(target))
         {
            unit.attack();
            return;
         }
         if(magikill.bossWasRecentlyDamaged(game) || distance < BOSS_CASTING_DISTANCE)
         {
            unit.walk(retreatDir,yMove,retreatDir);
            unit.faceDirection(retreatDir);
            return;
         }
         if(distance > BOSS_PULLBACK_DISTANCE)
         {
            if(this.canBossMoveToSpellRange())
            {
               unit.walk(approachDir / 2,yMove,approachDir);
               unit.faceDirection(approachDir);
            }
            else
            {
               unit.faceDirection(target.px - unit.px);
            }
            return;
         }
         unit.faceDirection(target.px - unit.px);
      }

      private function canBossMoveToSpellRange() : Boolean
      {
         return this.mayMoveToAttack && this.isBossAttackIntent();
      }

      private function updateBossAttackIntentFromTarget(target:Unit) : void
      {
         if(!this.mayMoveToAttack || target == null || unit.isGarrisoned)
         {
            return;
         }
         if(unit.sqrDistanceTo(target) < BOSS_ATTACK_ACQUIRE_RANGE_SQR)
         {
            this.bossAttackIntent = true;
         }
      }

      private function isDefensiveFormationMove() : Boolean
      {
         if(currentCommand.type != UnitCommand.MOVE && currentCommand.type != UnitCommand.ATTACK_MOVE)
         {
            return false;
         }
         return Math.abs(currentCommand.goalX - (unit.team.homeX + unit.team.direction * 600)) < 80;
      }

      private function isBossAttackIntent() : Boolean
      {
         return this.bossAttackIntent;
      }

      private function shouldDeferBossCommand(c:UnitCommand) : Boolean
      {
         return c.type == UnitCommand.MOVE || c.type == UnitCommand.ATTACK_MOVE || c.type == UnitCommand.GARRISON || c.type == UnitCommand.STAND || c.type == UnitCommand.HOLD;
      }
      
      private function tryAutoCast(game:StickWar) : void
      {
         var magikill:Magikill = null;
         var defendMode:Boolean = false;
         var defendTarget:Unit = null;
         var nukeReady:Boolean = false;
         var stunReady:Boolean = false;
         var poisonReady:Boolean = false;
         var sharedTarget:Unit = null;
         var nukeTarget:Unit = null;
         var stunTarget:Unit = null;
         var poisonTarget:Unit = null;
         var directTarget:Unit = null;
         var totalWeight:int = 0;
         var roll:int = 0;
         if(unit.team == null || unit.team.isAi || unit.isGarrisoned || unit.isBusy())
         {
            return;
         }
         defendMode = this.isDefendMode();
         if(!defendMode && !this.isAttackMode(game))
         {
            return;
         }
         magikill = Magikill(unit);
         if(!magikill.isAutoCastEnabled)
         {
            return;
         }
         if(defendMode)
         {
            defendTarget = this.getNearestEnemyTarget(this.nukeCommand,false);
         }
         if(magikill.isMeteorOnlyToggled)
         {
            this.tryStartAutoSpell(game,this.nukeCommand,magikill.nukeCooldown(),this.getAutoCastTargetForSpell(game,this.nukeCommand,defendMode,defendTarget));
            return;
         }
         directTarget = this.getDirectAutoCastTarget(game);
         nukeReady = this.isSpellReadyForAutoCast(game,this.nukeCommand,magikill.nukeCooldown());
         stunReady = unit.team.tech.isResearched(Tech.MAGIKILL_WALL) && this.isSpellReadyForAutoCast(game,this.stunCommand,magikill.stunCooldown());
         poisonReady = unit.team.tech.isResearched(Tech.MAGIKILL_POISON) && this.isSpellReadyForAutoCast(game,this.poisonDartCommand,magikill.poisonDartCooldown());
         if(directTarget != null)
         {
            sharedTarget = directTarget;
         }
         else
         {
            sharedTarget = this.getSharedAutoCastTarget(game,defendMode,defendTarget,nukeReady,stunReady,poisonReady);
         }
         nukeTarget = nukeReady ? sharedTarget : null;
         stunTarget = stunReady ? sharedTarget : null;
         poisonTarget = poisonReady ? sharedTarget : null;
         if(nukeTarget != null)
         {
            totalWeight += NUKE_WEIGHT;
         }
         if(stunTarget != null)
         {
            totalWeight += STUN_WEIGHT;
         }
         if(poisonTarget != null)
         {
            totalWeight += POISON_WEIGHT;
         }
         if(totalWeight == 0)
         {
            return;
         }
         roll = Math.abs(unit.team.game.random.nextInt()) % totalWeight;
         if(this.isSpellAutoCastReady(game,this.nukeCommand,magikill.nukeCooldown(),nukeTarget))
         {
            if(roll < NUKE_WEIGHT)
            {
               this.startAutoSpell(game,this.nukeCommand,nukeTarget);
               return;
            }
            roll -= NUKE_WEIGHT;
         }
         if(this.isSpellAutoCastReady(game,this.stunCommand,magikill.stunCooldown(),stunTarget))
         {
            if(roll < STUN_WEIGHT)
            {
               this.startAutoSpell(game,this.stunCommand,stunTarget);
               return;
            }
            roll -= STUN_WEIGHT;
         }
         if(this.isSpellAutoCastReady(game,this.poisonDartCommand,magikill.poisonDartCooldown(),poisonTarget))
         {
            this.startAutoSpell(game,this.poisonDartCommand,poisonTarget);
            return;
         }
         if(this.isSpellAutoCastReady(game,this.nukeCommand,magikill.nukeCooldown(),nukeTarget))
         {
            this.startAutoSpell(game,this.nukeCommand,nukeTarget);
            return;
         }
         if(this.isSpellAutoCastReady(game,this.stunCommand,magikill.stunCooldown(),stunTarget))
         {
            this.startAutoSpell(game,this.stunCommand,stunTarget);
         }
      }
      
      private function isDefendMode() : Boolean
      {
         if(currentCommand.type == UnitCommand.STAND || currentCommand.type == UnitCommand.HOLD)
         {
            return true;
         }
         if(currentCommand.type == UnitCommand.MOVE && currentCommand.targetId == -1)
         {
            if(Math.abs(currentCommand.goalX - unit.px) < 25 && Math.abs(currentCommand.goalY - unit.py) < 25)
            {
               return true;
            }
            return !unit.isFeetMoving() && Math.abs(currentCommand.goalX - unit.px) < 50 && Math.abs(currentCommand.goalY - unit.py) < 50;
         }
         return false;
      }
      
      private function isAttackMode(game:StickWar) : Boolean
      {
         if(currentCommand.type == UnitCommand.ATTACK_MOVE)
         {
            return unit.team.currentAttackState == Team.G_ATTACK;
         }
         if(currentCommand.targetId in game.units)
         {
            if(game.units[currentCommand.targetId] is Unit)
            {
               return Unit(game.units[currentCommand.targetId]).team != null && Unit(game.units[currentCommand.targetId]).team.id != unit.team.id;
            }
         }
         return false;
      }
      
      private function getAutoCastTargetForSpell(game:StickWar, command:UnitCommand, defendMode:Boolean, defendTarget:Unit = null) : Unit
      {
         if(currentCommand.targetId in game.units)
         {
            if(game.units[currentCommand.targetId] is Unit)
            {
               if(this.isDirectAutoCastTarget(Unit(game.units[currentCommand.targetId])))
               {
                  if(!defendMode || this.canCastWithoutMoving(command,Unit(game.units[currentCommand.targetId])))
                  {
                     return Unit(game.units[currentCommand.targetId]);
                  }
                  return null;
               }
            }
         }
         if(defendMode)
         {
            if(defendTarget != null && this.canCastWithoutMoving(command,defendTarget))
            {
               return defendTarget;
            }
            return null;
         }
         return this.getNearestEnemyTarget(command,false);
      }

      private function getDirectAutoCastTarget(game:StickWar) : Unit
      {
         if(currentCommand.targetId in game.units)
         {
            if(game.units[currentCommand.targetId] is Unit)
            {
               if(this.isDirectAutoCastTarget(Unit(game.units[currentCommand.targetId])))
               {
                  return Unit(game.units[currentCommand.targetId]);
               }
            }
         }
         return null;
      }

      private function isDirectAutoCastTarget(target:Unit) : Boolean
      {
         return target != null && target.team != null && target.team.id != unit.team.id && target.isAlive() && !target.isGarrisoned;
      }

      private function isAutoCastScanTarget(target:Unit) : Boolean
      {
         if(target == null)
         {
            return false;
         }
         if(target.isTargetable())
         {
            return true;
         }
         return target is Medusa && target.team != null && target.team.id != unit.team.id && target.isAlive() && !target.isGarrisoned && target.maxHealth >= unit.team.game.xml.xml.Chaos.Units.medusa.superHealth;
      }
      
      private function getNearestEnemyTarget(command:UnitCommand, mustBeInRange:Boolean) : Unit
      {
         var candidate:Unit = null;
         var wall:Wall = null;
         var closest:Unit = null;
         var distance:Number = NaN;
         var minDistance:Number = Number.POSITIVE_INFINITY;
         if(mustBeInRange)
         {
            if(this.cachedNearestTargetInRangeFrame == unit.team.game.frame)
            {
               return this.cachedNearestTargetInRange;
            }
         }
         else if(this.cachedNearestTargetAnyFrame == unit.team.game.frame)
         {
            return this.cachedNearestTargetAny;
         }
         for each(candidate in unit.team.enemyTeam.units)
         {
            if(candidate == null || !this.isAutoCastScanTarget(candidate))
            {
               continue;
            }
            if(candidate.pz != 0 && !unit.canAttackAir())
            {
               continue;
            }
            if(mustBeInRange && !this.canCastWithoutMoving(command,candidate))
            {
               continue;
            }
            distance = unit.sqrDistanceToTarget(candidate);
            if(distance < minDistance)
            {
               minDistance = distance;
               closest = candidate;
            }
         }
         for each(wall in unit.team.enemyTeam.walls)
         {
            if(wall == null || !wall.isTargetable())
            {
               continue;
            }
            if(mustBeInRange && !this.canCastWithoutMoving(command,wall))
            {
               continue;
            }
            distance = unit.sqrDistanceToTarget(wall);
            if(distance < minDistance)
            {
               minDistance = distance;
               closest = wall;
            }
         }
         if(closest != null)
         {
            this.cacheNearestEnemyTarget(closest,mustBeInRange);
            return closest;
         }
         if(!mustBeInRange || this.canCastWithoutMoving(command,unit.team.enemyTeam.statue))
         {
            this.cacheNearestEnemyTarget(unit.team.enemyTeam.statue,mustBeInRange);
            return unit.team.enemyTeam.statue;
         }
         this.cacheNearestEnemyTarget(null,mustBeInRange);
         return null;
      }

      private function cacheNearestEnemyTarget(target:Unit, mustBeInRange:Boolean) : void
      {
         if(mustBeInRange)
         {
            this.cachedNearestTargetInRange = target;
            this.cachedNearestTargetInRangeFrame = unit.team.game.frame;
         }
         else
         {
            this.cachedNearestTargetAny = target;
            this.cachedNearestTargetAnyFrame = unit.team.game.frame;
         }
      }

      private function canCastWithoutMoving(command:UnitCommand, target:Unit) : Boolean
      {
         command.realX = target.px;
         command.realY = target.py;
         return command.inRange(unit);
      }

      private function tryStartAutoSpell(game:StickWar, command:UnitCommand, cooldown:Number, target:Unit) : void
      {
         if(!this.isSpellAutoCastReady(game,command,cooldown,target))
         {
            return;
         }
         this.startAutoSpell(game,command,target);
      }

      private function isSpellAutoCastReady(game:StickWar, command:UnitCommand, cooldown:Number, target:Unit) : Boolean
      {
         return cooldown == 0 && target != null && this.canAffordSpell(game,command);
      }

      private function isSpellReadyForAutoCast(game:StickWar, command:UnitCommand, cooldown:Number) : Boolean
      {
         return cooldown == 0 && this.canAffordSpell(game,command);
      }

      private function canAffordSpell(game:StickWar, command:UnitCommand) : Boolean
      {
         if(command.type == UnitCommand.NUKE)
         {
            return unit.team.mana >= int(game.xml.xml.Order.Units.magikill.nuke.mana);
         }
         if(command.type == UnitCommand.STUN)
         {
            return unit.team.mana >= int(game.xml.xml.Order.Units.magikill.electricWall.mana);
         }
         if(command.type == UnitCommand.POISON_DART)
         {
            return unit.team.mana >= int(game.xml.xml.Order.Units.magikill.poisonSpray.mana);
         }
         return false;
      }
      
      private function startAutoSpell(game:StickWar, command:UnitCommand, target:Unit) : void
      {
         if(Magikill(unit).isOnInitialSpawnMove)
         {
            Magikill(unit).isOnInitialSpawnMove = false;
         }
         command.realX = target.px;
         command.realY = target.py;
         command.targetId = target.id;
         this.shouldRestoreAutoSpellCommand = true;
         this.setCommand(game,command);
      }
      
      private function finishSpellCommand(game:StickWar) : void
      {
         if(this.shouldRestoreAutoSpellCommand)
         {
            this.shouldRestoreAutoSpellCommand = false;
            this.restoreMove(game);
         }
         else
         {
            nextMove(game);
         }
      }

      private function isAutoSpellTargetStillValid(game:StickWar) : Boolean
      {
         if(currentCommand.targetId == -1)
         {
            return true;
         }
         if(!(currentCommand.targetId in game.units))
         {
            return false;
         }
         if(!(game.units[currentCommand.targetId] is Unit))
         {
            return false;
         }
         return Unit(game.units[currentCommand.targetId]).team != null && Unit(game.units[currentCommand.targetId]).team.id != unit.team.id && Unit(game.units[currentCommand.targetId]).isTargetable();
      }
      
      private function ensureCommands(game:StickWar) : void
      {
         if(this.holdCommand == null)
         {
            this.holdCommand = new HoldCommand(game);
         }
         if(this.nukeCommand == null)
         {
            this.nukeCommand = new NukeCommand(game);
         }
         if(this.stunCommand == null)
         {
            this.stunCommand = new StunCommand(game);
         }
         if(this.poisonDartCommand == null)
         {
            this.poisonDartCommand = new PoisonDartCommand(game);
         }
      }

      private function getSharedAutoCastTarget(game:StickWar, defendMode:Boolean, defendTarget:Unit, useNuke:Boolean, useStun:Boolean, usePoison:Boolean) : Unit
      {
         var target:Unit = null;
         if(currentCommand.type == UnitCommand.MOVE && currentCommand.targetId in game.units)
         {
            if(game.units[currentCommand.targetId] is Unit)
            {
               target = Unit(game.units[currentCommand.targetId]);
               if(target.team != null && target.team.id != unit.team.id && target.isTargetable() && this.canCastAllWithoutMoving(target,useNuke,useStun,usePoison))
               {
                  return target;
               }
            }
         }
         if(defendMode)
         {
            if(defendTarget != null && this.canCastAllWithoutMoving(defendTarget,useNuke,useStun,usePoison))
            {
               return defendTarget;
            }
            return null;
         }
         return this.getNearestEnemySharedTarget(useNuke,useStun,usePoison);
      }

      private function getNearestEnemySharedTarget(useNuke:Boolean, useStun:Boolean, usePoison:Boolean) : Unit
      {
         var candidate:Unit = null;
         var wall:Wall = null;
         var closest:Unit = null;
         var distance:Number = NaN;
         var minDistance:Number = Number.POSITIVE_INFINITY;
         var mask:int = (useNuke ? 1 : 0) | (useStun ? 2 : 0) | (usePoison ? 4 : 0);
         if(this.cachedNearestSharedTargetFrame == unit.team.game.frame && this.cachedNearestSharedTargetMask == mask)
         {
            return this.cachedNearestSharedTarget;
         }
         for each(candidate in unit.team.enemyTeam.units)
         {
            if(candidate == null || !candidate.isTargetable())
            {
               continue;
            }
            if(candidate.pz != 0 && !unit.canAttackAir())
            {
               continue;
            }
            if(!this.canCastAllWithoutMoving(candidate,useNuke,useStun,usePoison))
            {
               continue;
            }
            distance = unit.sqrDistanceToTarget(candidate);
            if(distance < minDistance)
            {
               minDistance = distance;
               closest = candidate;
            }
         }
         for each(wall in unit.team.enemyTeam.walls)
         {
            if(wall == null || !wall.isTargetable())
            {
               continue;
            }
            if(!this.canCastAllWithoutMoving(wall,useNuke,useStun,usePoison))
            {
               continue;
            }
            distance = unit.sqrDistanceToTarget(wall);
            if(distance < minDistance)
            {
               minDistance = distance;
               closest = wall;
            }
         }
         if(closest != null)
         {
            this.cacheNearestSharedTarget(closest,mask);
            return closest;
         }
         if(this.canCastAllWithoutMoving(unit.team.enemyTeam.statue,useNuke,useStun,usePoison))
         {
            this.cacheNearestSharedTarget(unit.team.enemyTeam.statue,mask);
            return unit.team.enemyTeam.statue;
         }
         this.cacheNearestSharedTarget(null,mask);
         return null;
      }

      private function cacheNearestSharedTarget(target:Unit, mask:int) : void
      {
         this.cachedNearestSharedTarget = target;
         this.cachedNearestSharedTargetFrame = unit.team.game.frame;
         this.cachedNearestSharedTargetMask = mask;
      }

      private function canCastAllWithoutMoving(target:Unit, useNuke:Boolean, useStun:Boolean, usePoison:Boolean) : Boolean
      {
         if(useNuke && !this.canCastWithoutMoving(this.nukeCommand,target))
         {
            return false;
         }
         if(useStun && !this.canCastWithoutMoving(this.stunCommand,target))
         {
            return false;
         }
         if(usePoison && !this.canCastWithoutMoving(this.poisonDartCommand,target))
         {
            return false;
         }
         return true;
      }

      private function tryFinishInitialSpawnMove(game:StickWar) : Boolean
      {
         if(!Magikill(unit).isOnInitialSpawnMove)
         {
            return false;
         }
         if(currentCommand.type != UnitCommand.ATTACK_MOVE)
         {
            Magikill(unit).isOnInitialSpawnMove = false;
            return false;
         }
         if(!currentCommand.isFinished(unit))
         {
            return false;
         }
         Magikill(unit).isOnInitialSpawnMove = false;
         this.setCommand(game,this.holdCommand);
         return true;
      }
   }
}
