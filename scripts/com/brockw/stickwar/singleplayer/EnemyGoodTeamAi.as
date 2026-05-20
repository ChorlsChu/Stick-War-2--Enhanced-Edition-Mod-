package com.brockw.stickwar.singleplayer
{
   import com.brockw.stickwar.BaseMain;
   import com.brockw.stickwar.campaign.*;
   import com.brockw.stickwar.engine.Ai.*;
   import com.brockw.stickwar.engine.Ai.command.*;
   import com.brockw.stickwar.engine.StickWar;
   import com.brockw.stickwar.engine.Team.*;
   import com.brockw.stickwar.engine.multiplayer.moves.*;
   import com.brockw.stickwar.engine.units.*;
   import flash.utils.Dictionary;
   
   public class EnemyGoodTeamAi extends EnemyTeamAi
   {
      private static const DEFENCE_BUILD_COOLDOWN_FRAMES:int = 30 * 30;
      
      private static const DEFENCE_BUILD_X_OFFSET:int = 900;
      
      private static const MIN_DEFENCE_FORCE:int = 10;
      
      private static const DEFENCE_BUILD_RESERVE_FRAMES:int = 30 * 8;
      
      private static const MIN_FIRST_DEFENCE_FORCE:int = 20;

      private static const INSANE_RESEARCH_MULTIPLIER:Number = 0.75;

      private static const SHADOWRATH_LEVEL_TITLE:String = "Silent Assassins: Ninjas Declare War";

      private static const SHADOWRATH_LURE_TIMEOUT_FRAMES:int = 30 * 10;

      private static const SHADOWRATH_PARTIAL_REVEAL_TIMEOUT_FRAMES:int = 30 * 10;

      private static const SHADOWRATH_STRATEGY_NONE:int = 0;

      private static const SHADOWRATH_STRATEGY_MID_PRESSURE:int = 1;

      private static const SHADOWRATH_STRATEGY_TRAP:int = 2;

      private static const SHADOWRATH_STRATEGY_FULL_PUSH:int = 3;

      private static const SHADOWRATH_MID_PRESSURE_LOCK_FRAMES:int = 30 * 8;

      private static const SHADOWRATH_TRAP_LOCK_FRAMES:int = 30 * 12;

      private static const SHADOWRATH_FULL_PUSH_LOCK_FRAMES:int = 30 * 12;

      private static const SHADOWRATH_MID_PRESSURE_REVEAL_COUNT:int = 2;

      private static const SHADOWRATH_PARTIAL_REVEAL_COUNT:int = 2;

      private static const SHADOWRATH_FULL_PUSH_ADVANTAGE_MARGIN:int = 8;

      private static const SHADOWRATH_MID_PRESSURE_ADVANTAGE_MARGIN:int = 2;

      private static const SHADOWRATH_PLAYER_INTERRUPT_MARGIN:int = 4;
      
      private var buildOrder:Array;
      
      private var nukeSpell:NukeCommand;
      
      private var electricWallSpell:StunCommand;
      
      private var poisonSpell:PoisonDartCommand;
      
      private var nextWallBuildFrame:int;
      
      private var pendingWallBuildUntil:int;

      private var shadowrathTrapEnabled:Boolean;

      private var shadowrathLureCycles:int;

      private var shadowrathPartialRevealUsed:Boolean;

      private var shadowrathFullRevealUsed:Boolean;

      private var shadowrathTrapPhaseStartFrame:int;

      private var shadowrathStrategy:int;

      private var shadowrathStrategyLockUntil:int;

      private var shadowrathStrategyRevealDone:Boolean;

      private var shadowrathStrategyDirty:Boolean;

      private var shadowrathLastOwnAliveCount:int;

      private var shadowrathLastEnemyAliveCount:int;

      private var shadowrathLastHiddenCount:int;
      
      public function EnemyGoodTeamAi(team:Team, main:BaseMain, game:StickWar, isCreatingUnits:* = true)
      {
         var key:int = 0;
         var levelTitle:String = String(main.campaign.getCurrentLevel().title);
         unitComposition = new Dictionary();
         unitComposition[Unit.U_MINER] = main.campaign.xml.Order.UnitComposition.Miner;
         if(String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.Miner) != "")
         {
            unitComposition[Unit.U_MINER] = String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.Miner);
         }
         unitComposition[Unit.U_SWORDWRATH] = main.campaign.xml.Order.UnitComposition.Swordwrath;
         if(String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.Swordwrath) != "")
         {
            unitComposition[Unit.U_SWORDWRATH] = String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.Swordwrath);
         }
         unitComposition[Unit.U_ARCHER] = main.campaign.xml.Order.UnitComposition.Archidon;
         if(String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.Archidon) != "")
         {
            unitComposition[Unit.U_ARCHER] = String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.Archidon);
         }
         unitComposition[Unit.U_SPEARTON] = main.campaign.xml.Order.UnitComposition.Spearton;
         if(String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.Spearton) != "")
         {
            unitComposition[Unit.U_SPEARTON] = String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.Spearton);
         }
         unitComposition[Unit.U_NINJA] = main.campaign.xml.Order.UnitComposition.Ninja;
         if(String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.Ninja) != "")
         {
            unitComposition[Unit.U_NINJA] = String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.Ninja);
         }
         unitComposition[Unit.U_FLYING_CROSSBOWMAN] = main.campaign.xml.Order.UnitComposition.FlyingCrossbowman;
         if(String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.FlyingCrossbowman) != "")
         {
            unitComposition[Unit.U_FLYING_CROSSBOWMAN] = String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.FlyingCrossbowman);
         }
         unitComposition[Unit.U_MONK] = main.campaign.xml.Order.UnitComposition.Monk;
         if(String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.Monk) != "")
         {
            unitComposition[Unit.U_MONK] = String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.Monk);
         }
         unitComposition[Unit.U_MAGIKILL] = main.campaign.xml.Order.UnitComposition.Magikill;
         if(String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.Magikill) != "")
         {
            unitComposition[Unit.U_MAGIKILL] = String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.Magikill);
         }
         unitComposition[Unit.U_ENSLAVED_GIANT] = main.campaign.xml.Order.UnitComposition.EnslavedGiant;
         if(String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.EnslavedGiant) != "")
         {
            unitComposition[Unit.U_ENSLAVED_GIANT] = String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.EnslavedGiant);
         }
         if(main.campaign.difficultyLevel == Campaign.D_INSANE)
         {
            if(levelTitle == "Tutorial")
            {
               unitComposition[Unit.U_SPEARTON] = int(unitComposition[Unit.U_SPEARTON]) + 1;
            }
            else if(levelTitle == "Blot out the sun: Archidons Declare War")
            {
               unitComposition[Unit.U_ARCHER] = int(unitComposition[Unit.U_ARCHER]) + 1;
               unitComposition[Unit.U_SWORDWRATH] = int(unitComposition[Unit.U_SWORDWRATH]) + 2;
            }
            else if(levelTitle == "Silent Assassins: Ninjas Declare War")
            {
               unitComposition[Unit.U_NINJA] = int(unitComposition[Unit.U_NINJA]) + 1;
            }
            else if(levelTitle == "Magic in the Air: Wizards and monks Declare War ")
            {
               unitComposition[Unit.U_MAGIKILL] = int(unitComposition[Unit.U_MAGIKILL]) + 1;
               unitComposition[Unit.U_MONK] = int(unitComposition[Unit.U_MONK]) + 1;
            }
            else if(levelTitle == "Rebels United")
            {
               unitComposition[Unit.U_SPEARTON] = int(unitComposition[Unit.U_SPEARTON]) + 1;
               unitComposition[Unit.U_ARCHER] = int(unitComposition[Unit.U_ARCHER]) + 1;
               unitComposition[Unit.U_NINJA] = int(unitComposition[Unit.U_NINJA]) + 1;
            }
         }
         if(levelTitle == SHADOWRATH_LEVEL_TITLE)
         {
            unitComposition[Unit.U_SWORDWRATH] = Math.max(6,int(unitComposition[Unit.U_SWORDWRATH]));
         }
         var theoriticalBuildOrder:* = [Unit.U_ENSLAVED_GIANT,Unit.U_MAGIKILL,Unit.U_FLYING_CROSSBOWMAN,Unit.U_SPEARTON,Unit.U_SWORDWRATH,Unit.U_ARCHER,Unit.U_MONK,Unit.U_NINJA];
         this.buildOrder = [];
         for each(key in theoriticalBuildOrder)
         {
            if(team.unitsAvailable == null || key in team.unitsAvailable)
            {
               this.buildOrder.push(key);
            }
         }
         this.nukeSpell = new NukeCommand(game);
         this.electricWallSpell = new StunCommand(game);
         this.poisonSpell = new PoisonDartCommand(game);
         this.nextWallBuildFrame = 0;
         this.pendingWallBuildUntil = 0;
         this.shadowrathTrapEnabled = levelTitle == SHADOWRATH_LEVEL_TITLE;
         this.shadowrathLureCycles = 0;
         this.shadowrathPartialRevealUsed = false;
         this.shadowrathFullRevealUsed = false;
         this.shadowrathTrapPhaseStartFrame = 0;
         this.shadowrathStrategy = SHADOWRATH_STRATEGY_NONE;
         this.shadowrathStrategyLockUntil = 0;
         this.shadowrathStrategyRevealDone = false;
         this.shadowrathStrategyDirty = true;
         this.shadowrathLastOwnAliveCount = -1;
         this.shadowrathLastEnemyAliveCount = -1;
         this.shadowrathLastHiddenCount = -1;
         super(team,main,game,isCreatingUnits);
      }
      
      override public function update(game:StickWar) : void
      {
         super.update(game);
      }

      override protected function requiresPerFrameGlobalStrategy(game:StickWar) : Boolean
      {
         return this.shadowrathTrapEnabled;
      }
      
      override protected function isArmyHealers() : Boolean
      {
         var numHealers:int = 0;
         if(Unit.U_MONK in unitComposition)
         {
            numHealers = int(unitComposition[Unit.U_MONK]);
         }
         if(numHealers * team.game.xml.xml.Order.Units.monk.population == team.attackingForcePopulation)
         {
            return true;
         }
         return false;
      }
      
      override protected function updateUnitCreation(game:StickWar) : void
      {
         var i:int = 0;
         var numOfUnit:int = 0;
         var t:TechItem = null;
         if(this.hasPendingWallBuild(game))
         {
            return;
         }
         if(this.shouldPrioritizeFirstDefence())
         {
            if(!team.tech.isResearched(Tech.MINER_WALL))
            {
               if(this.tryResearchTech(Tech.MINER_WALL))
               {
                  return;
               }
            }
            else if(this.tryBuildWall(game))
            {
               return;
            }
         }
         if(!enemyIsAttacking() && (team.population < 6 || enemyIsWeak()))
         {
            numOfUnit = int(team.unitGroups[Unit.U_MINER].length);
            if(numOfUnit < unitComposition[Unit.U_MINER] && team.unitProductionQueue[team.unitInfo[Unit.U_MINER][2]].length == 0)
            {
               game.requestToSpawn(team.id,Unit.U_MINER);
            }
         }
         var overCompCount:int = 0;
         for(i = 0; i < this.buildOrder.length; i++)
         {
            numOfUnit = int(team.unitGroups[this.buildOrder[i]].length);
            if(numOfUnit >= unitComposition[this.buildOrder[i]])
            {
               overCompCount++;
            }
            else if(team.unitProductionQueue[team.unitInfo[this.buildOrder[i]][2]].length == 0)
            {
               game.requestToSpawn(team.id,this.buildOrder[i]);
            }
         }
         if(overCompCount >= this.buildOrder.length)
         {
            for(i = 0; i < this.buildOrder.length; i++)
            {
               numOfUnit = int(team.unitGroups[this.buildOrder[i]].length);
               if(team.unitProductionQueue[team.unitInfo[this.buildOrder[i]][2]].length == 0)
               {
                  game.requestToSpawn(team.id,this.buildOrder[i]);
               }
            }
         }
         if(int(team.unitGroups[Unit.U_MINER].length) > 0)
         {
            if(this.tryResearchTech(Tech.MINER_WALL))
            {
               return;
            }
         }
         if(int(team.unitGroups[Unit.U_NINJA].length) > 0)
         {
            if(team.game.main.campaign.difficultyLevel == Campaign.D_NORMAL)
            {
               if(this.tryResearchTech(Tech.CLOAK))
               {
                  return;
               }
            }
            else
            {
               team.tech.isResearchedMap[Tech.CLOAK] = true;
               if(team.game.main.campaign.difficultyLevel == Campaign.D_INSANE)
               {
                  team.tech.isResearchedMap[Tech.CLOAK_II] = true;
               }
               else if(this.tryResearchTech(Tech.CLOAK_II))
               {
                  return;
               }
            }
         }
         if(int(team.unitGroups[Unit.U_MAGIKILL].length) > 0)
         {
            if(this.tryResearchTech(Tech.MAGIKILL_WALL))
            {
               return;
            }
            if(this.tryResearchTech(Tech.MAGIKILL_POISON))
            {
               return;
            }
         }
         if(!(this.team.game.gameScreen is CampaignGameScreen) || team.game.main.campaign.currentLevel != 0)
         {
            if(!team.tech.isResearched(Tech.CASTLE_ARCHER_1))
            {
               t = team.tech.upgrades[Tech.CASTLE_ARCHER_1];
               if(t == null)
               {
                  return;
               }
               if(t.cost < team.gold && t.mana < team.mana)
               {
                  this.startEnemyResearch(Tech.CASTLE_ARCHER_1);
               }
            }
            else if(!team.tech.isResearched(Tech.CASTLE_ARCHER_2) && team.game.main.campaign.difficultyLevel > Campaign.D_NORMAL)
            {
               t = team.tech.upgrades[Tech.CASTLE_ARCHER_2];
               if(t == null)
               {
                  return;
               }
               if(t.cost < team.gold && t.mana < team.mana)
               {
                  this.startEnemyResearch(Tech.CASTLE_ARCHER_2);
               }
            }
         }
         this.tryBuildWall(game);
      }
      
      override protected function updateSpellCasters(game:StickWar) : void
      {
         var manaBefore:Number = team.mana;
         team.mana = 1000;
         this.updateMagikill(game);
         team.mana = manaBefore;
         this.updateArchers(game);
         this.updateNinjas(game);
      }

      override protected function updateGlobalStrategy(game:StickWar) : void
      {
         var screen:CampaignGameScreen = null;
         var hiddenCount:int = 0;
         if(!this.shadowrathTrapEnabled || !(game.gameScreen is CampaignGameScreen))
         {
            super.updateGlobalStrategy(game);
            return;
         }
         screen = CampaignGameScreen(game.gameScreen);
         hiddenCount = screen.getDisguisedShadowrathCount();
         this.updateShadowrathStrategyDirtyState(hiddenCount);
         if(hiddenCount <= 0)
         {
            this.shadowrathStrategy = SHADOWRATH_STRATEGY_NONE;
            super.updateGlobalStrategy(game);
            return;
         }
         if(this.playerHasShadowrathStrategyInterrupt())
         {
            this.shadowrathStrategy = SHADOWRATH_STRATEGY_NONE;
            this.shadowrathStrategyLockUntil = 0;
            this.defendGroup();
            return;
         }
         if(this.shadowrathStrategy == SHADOWRATH_STRATEGY_NONE || this.shadowrathStrategyDirty || game.frame >= this.shadowrathStrategyLockUntil)
         {
            this.chooseShadowrathStrategy(game,screen,hiddenCount);
            this.shadowrathStrategyDirty = false;
         }
         if(this.shadowrathStrategy == SHADOWRATH_STRATEGY_MID_PRESSURE)
         {
            this.executeShadowrathMidPressure(game,screen);
            return;
         }
         if(this.shadowrathStrategy == SHADOWRATH_STRATEGY_TRAP)
         {
            this.executeShadowrathTrapStrategy(game,screen,hiddenCount);
            return;
         }
         if(this.shadowrathStrategy == SHADOWRATH_STRATEGY_FULL_PUSH)
         {
            this.executeShadowrathFullPush(game,screen);
            return;
         }
         super.updateGlobalStrategy(game);
      }
      
      private function updateArchers(game:StickWar) : void
      {
         var archer:Archer = null;
         for each(archer in team.unitGroups[Unit.U_ARCHER])
         {
            if(archer.ai.currentTarget != null)
            {
               RangedAi(archer.ai).mayKite = true;
            }
         }
      }
      
      private function updateNinjas(game:StickWar) : void
      {
         var ninja:Ninja = null;
         var target:Unit = null;
         for each(ninja in team.unitGroups[Unit.U_NINJA])
         {
            target = ninja.ai.getClosestTarget();
            if(target != null && target.isAlive())
            {
               if(Math.abs(target.px - ninja.px) < 500)
               {
                  ninja.stealth();
               }
            }
         }
      }
      
      private function updateMagikill(game:StickWar) : void
      {
         var magikill:Magikill = null;
         var target:Unit = null;
         for each(magikill in team.unitGroups[Unit.U_MAGIKILL])
         {
            target = magikill.ai.getClosestTarget();
            if(Boolean(target))
            {
               if(magikill.nukeCooldown() == 0)
               {
                  this.nukeSpell.realX = target.px;
                  this.nukeSpell.realY = target.py;
                  if(this.nukeSpell.inRange(magikill))
                  {
                     magikill.nukeSpell(target.px,target.py);
                  }
               }
               else if(team.tech.isResearched(Tech.MAGIKILL_WALL) && magikill.stunCooldown() == 0)
               {
                  this.electricWallSpell.realX = target.px;
                  this.electricWallSpell.realY = target.py;
                  if(this.electricWallSpell.inRange(magikill))
                  {
                     magikill.stunSpell(target.px,target.py);
                  }
               }
               else if(team.tech.isResearched(Tech.MAGIKILL_POISON) && magikill.poisonDartCooldown() == 0)
               {
                  this.poisonSpell.realX = target.px;
                  this.poisonSpell.realY = target.py;
                  if(this.poisonSpell.inRange(magikill))
                  {
                     magikill.poisonDartSpell(target.px,target.py);
                  }
               }
            }
         }
      }

      private function tryResearchTech(type:int) : Boolean
      {
         var t:TechItem = team.tech.upgrades[type];
         if(t == null || team.tech.isResearched(type) || team.tech.isResearching(type))
         {
            return false;
         }
         if(t.cost <= team.gold && t.mana <= team.mana)
         {
            this.startEnemyResearch(type);
            return true;
         }
         return false;
      }

      private function startEnemyResearch(type:int) : void
      {
         team.tech.startResearching(type);
         if(team.game.main.campaign.difficultyLevel == Campaign.D_INSANE)
         {
            team.tech.speedUpResearch(type,INSANE_RESEARCH_MULTIPLIER);
         }
      }
      
      private function tryBuildWall(game:StickWar) : Boolean
      {
         var miner:Miner = null;
         var bestMiner:Miner = null;
         var move:UnitMove = null;
         var buildX:Number = NaN;
         var bestDistance:Number = NaN;
         var distance:Number = NaN;
         if(game.frame < this.nextWallBuildFrame)
         {
            return false;
         }
         if(!team.tech.isResearched(Tech.MINER_WALL) || team.walls.length > 0)
         {
            return false;
         }
         if((!enemyAtHome() && !enemyAtMiddle() && !this.shouldBuildFinalDefence()) || team.attackingForcePopulation < MIN_DEFENCE_FORCE)
         {
            return false;
         }
         if(team.gold < int(game.xml.xml.Order.Units.miner.wall.gold) || team.mana < int(game.xml.xml.Order.Units.miner.wall.mana))
         {
            return false;
         }
         buildX = team.homeX + team.direction * DEFENCE_BUILD_X_OFFSET;
         bestDistance = Number.POSITIVE_INFINITY;
         for each(miner in team.unitGroups[Unit.U_MINER])
         {
            if(miner != null && miner.isAlive() && !miner.isGarrisoned && miner.constructCooldown() == 0)
            {
               distance = Math.abs(miner.px - buildX);
               if(distance < bestDistance)
               {
                  bestDistance = distance;
                  bestMiner = miner;
               }
            }
         }
         if(bestMiner == null)
         {
            return false;
         }
         move = new UnitMove();
         move.moveType = UnitCommand.CONSTRUCT_WALL;
         move.units.push(bestMiner.id);
         move.owner = team.id;
         move.arg0 = buildX;
         move.arg1 = game.map.height / 2;
         move.execute(game);
         this.nextWallBuildFrame = game.frame + DEFENCE_BUILD_COOLDOWN_FRAMES;
         this.pendingWallBuildUntil = game.frame + DEFENCE_BUILD_RESERVE_FRAMES;
         return true;
      }
      
      private function hasPendingWallBuild(game:StickWar) : Boolean
      {
         if(team.walls.length > 0)
         {
            this.pendingWallBuildUntil = 0;
            return false;
         }
         if(this.pendingWallBuildUntil > game.frame)
         {
            return true;
         }
         this.pendingWallBuildUntil = 0;
         return false;
      }
      
      private function shouldBuildFinalDefence() : Boolean
      {
         return enemyIsWeak() && this.agressionMetric() < 0.8;
      }
      
      private function shouldPrioritizeFirstDefence() : Boolean
      {
         return int(team.unitGroups[Unit.U_MINER].length) > 0 && team.walls.length == 0 && team.attackingForcePopulation >= MIN_FIRST_DEFENCE_FORCE && (enemyAtHome() || enemyAtMiddle() || this.shouldBuildFinalDefence());
      }

      private function shadowrathBaitSwordwraths(game:StickWar) : void
      {
         var sword:Unit = null;
         var move:UnitMove = null;
         var targetX:Number = this.team.game.map.width / 2;
         if(this.shadowrathTrapPhaseStartFrame == 0)
         {
            this.shadowrathTrapPhaseStartFrame = game.frame;
         }
         this.isAttacking = true;
         move = new UnitMove();
         move.moveType = UnitCommand.ATTACK_MOVE;
         for each(sword in this.team.unitGroups[Unit.U_SWORDWRATH])
         {
            if(sword != null && sword.isAlive() && !sword.isGarrisoned)
            {
               move.units.push(sword.id);
            }
         }
         if(move.units.length == 0)
         {
            super.updateGlobalStrategy(game);
            return;
         }
         move.owner = this.team.id;
         move.arg0 = targetX;
         move.arg1 = this.team.game.gameScreen.game.map.height / 2;
         move.execute(this.team.game);
      }

      private function shadowrathShouldRetreatLure(game:StickWar) : Boolean
      {
         return this.enemyAtMiddle() || this.enemyIsAttacking() || this.shadowrathTrapPhaseStartFrame != 0 && game.frame - this.shadowrathTrapPhaseStartFrame >= SHADOWRATH_LURE_TIMEOUT_FRAMES;
      }

      private function playerHasShadowrathStrategyInterrupt() : Boolean
      {
         return this.team.enemyTeam.attackingForcePopulation > this.team.attackingForcePopulation + SHADOWRATH_PLAYER_INTERRUPT_MARGIN;
      }

      private function chooseShadowrathStrategy(game:StickWar, screen:CampaignGameScreen, hiddenCount:int) : void
      {
         if(this.shouldShadowrathFullPush(hiddenCount))
         {
            this.startShadowrathStrategy(SHADOWRATH_STRATEGY_FULL_PUSH,game);
         }
         else if(this.shouldShadowrathMidPressure(hiddenCount))
         {
            this.startShadowrathStrategy(SHADOWRATH_STRATEGY_MID_PRESSURE,game);
         }
         else
         {
            this.startShadowrathStrategy(SHADOWRATH_STRATEGY_TRAP,game);
         }
      }

      private function startShadowrathStrategy(strategy:int, game:StickWar) : void
      {
         this.shadowrathStrategy = strategy;
         this.shadowrathStrategyRevealDone = false;
         this.shadowrathTrapPhaseStartFrame = game.frame;
         if(strategy == SHADOWRATH_STRATEGY_MID_PRESSURE)
         {
            this.shadowrathStrategyLockUntil = game.frame + SHADOWRATH_MID_PRESSURE_LOCK_FRAMES;
         }
         else if(strategy == SHADOWRATH_STRATEGY_FULL_PUSH)
         {
            this.shadowrathStrategyLockUntil = game.frame + SHADOWRATH_FULL_PUSH_LOCK_FRAMES;
         }
         else if(strategy == SHADOWRATH_STRATEGY_TRAP)
         {
            this.shadowrathStrategyLockUntil = game.frame + SHADOWRATH_TRAP_LOCK_FRAMES;
         }
         else
         {
            this.shadowrathStrategyLockUntil = 0;
         }
         this.shadowrathStrategyDirty = false;
      }

      private function executeShadowrathMidPressure(game:StickWar, screen:CampaignGameScreen) : void
      {
         if(!this.shadowrathStrategyRevealDone)
         {
            screen.revealShadowrathDisguises(SHADOWRATH_MID_PRESSURE_REVEAL_COUNT);
            this.shadowrathStrategyRevealDone = true;
         }
         this.attackMoveGroupTo(this.team.game.map.width / 2);
      }

      private function executeShadowrathTrapStrategy(game:StickWar, screen:CampaignGameScreen, hiddenCount:int) : void
      {
         var movePos:Number = NaN;
         if(this.shadowrathFullRevealUsed)
         {
            this.shadowrathStrategyDirty = true;
            this.markStrategyDirty();
            this.startShadowrathStrategy(SHADOWRATH_STRATEGY_FULL_PUSH,game);
            this.executeShadowrathFullPush(game,screen);
            return;
         }
         if(this.shadowrathLureCycles < 2)
         {
            if(this.shadowrathShouldRetreatLure(game))
            {
               this.defendGroup();
               ++this.shadowrathLureCycles;
               this.shadowrathTrapPhaseStartFrame = game.frame;
               this.shadowrathStrategyDirty = true;
               this.markStrategyDirty();
               return;
            }
            this.shadowrathBaitSwordwraths(game);
            return;
         }
         if(!this.shadowrathPartialRevealUsed)
         {
            if(!this.shadowrathStrategyRevealDone)
            {
               screen.revealShadowrathDisguises(Math.min(SHADOWRATH_PARTIAL_REVEAL_COUNT,hiddenCount));
               this.shadowrathPartialRevealUsed = true;
               this.shadowrathStrategyRevealDone = true;
               this.shadowrathTrapPhaseStartFrame = game.frame;
            }
            movePos = this.team.medianPosition + this.team.direction * 250;
            if(this.team.direction * movePos > this.team.direction * this.team.game.map.width / 2)
            {
               movePos = this.team.game.map.width / 2;
            }
            this.attackMoveGroupTo(movePos);
            return;
         }
         if(game.frame - this.shadowrathTrapPhaseStartFrame >= SHADOWRATH_PARTIAL_REVEAL_TIMEOUT_FRAMES)
         {
            this.shadowrathFullRevealUsed = true;
            this.shadowrathStrategyDirty = true;
            this.markStrategyDirty();
            this.startShadowrathStrategy(SHADOWRATH_STRATEGY_FULL_PUSH,game);
            this.executeShadowrathFullPush(game,screen);
            return;
         }
         this.attackMoveGroupTo(this.team.game.map.width / 2);
      }

      private function executeShadowrathFullPush(game:StickWar, screen:CampaignGameScreen) : void
      {
         if(!this.shadowrathStrategyRevealDone)
         {
            screen.revealShadowrathDisguises();
            this.shadowrathStrategyRevealDone = true;
         }
         this.attackMoveGroupTo(this.team.game.map.width / 2);
      }

      private function shouldShadowrathFullPush(hiddenCount:int) : Boolean
      {
         return this.team.attackingForcePopulation >= this.team.enemyTeam.attackingForcePopulation + SHADOWRATH_FULL_PUSH_ADVANTAGE_MARGIN || this.shadowrathPartialRevealUsed && hiddenCount <= 2;
      }

      private function shouldShadowrathMidPressure(hiddenCount:int) : Boolean
      {
         return !this.enemyAtMiddle() && !this.enemyIsAttacking() && this.team.attackingForcePopulation >= this.team.enemyTeam.attackingForcePopulation + SHADOWRATH_MID_PRESSURE_ADVANTAGE_MARGIN && hiddenCount >= SHADOWRATH_MID_PRESSURE_REVEAL_COUNT;
      }

      private function updateShadowrathStrategyDirtyState(hiddenCount:int) : void
      {
         if(this.shadowrathLastHiddenCount != hiddenCount)
         {
            this.shadowrathStrategyDirty = true;
            this.markStrategyDirty();
         }
         this.shadowrathLastHiddenCount = hiddenCount;
      }
   }
}

