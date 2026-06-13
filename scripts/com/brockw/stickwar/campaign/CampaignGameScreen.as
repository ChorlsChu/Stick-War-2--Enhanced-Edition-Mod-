package com.brockw.stickwar.campaign
{
   import com.brockw.*;
   import com.brockw.game.*;
   import com.brockw.simulationSync.EndOfTurnMove;
   import com.brockw.simulationSync.Move;
   import com.brockw.simulationSync.SimulationSyncronizer;
   import com.brockw.stickwar.BaseMain;
   import com.brockw.stickwar.GameScreen;
   import com.brockw.stickwar.campaign.controllers.CampaignController;
   import com.brockw.stickwar.engine.Ai.MinerAi;
   import com.brockw.stickwar.engine.Gold;
   import com.brockw.stickwar.engine.Ore;
   import com.brockw.stickwar.engine.Ai.command.*;
   import com.brockw.stickwar.engine.StickWar;
   import com.brockw.stickwar.engine.Team.Team;
   import com.brockw.stickwar.engine.Team.Tech;
   import com.brockw.stickwar.engine.UserInterface;
   import com.brockw.stickwar.engine.multiplayer.PostGameScreen;
   import com.brockw.stickwar.engine.multiplayer.moves.*;
   import com.brockw.stickwar.engine.units.*;
   import com.brockw.stickwar.singleplayer.*;
   import com.brockw.stickwar.stickwar2;
   import com.smartfoxserver.v2.requests.ExtensionRequest;
   import flash.display.*;
   import flash.events.*;
   import flash.utils.getTimer;
   
   public class CampaignGameScreen extends GameScreen
   {
      
      public var enemyTeamAi:EnemyTeamAi;
      
      private var controller:CampaignController;
      
      public var doAiUpdates:Boolean;

      private var shadowrathRevealQueue:Array;

      private var shadowrathRevealQueued:Object;

      private var shadowrathDisguiseCooldowns:Object;

      private var shadowrathDisguiseLockUntil:Object;

      private var shadowrathSeenForInitialLock:Object;

      private var shadowrathLastAttackState:int;

      private var cachedDisguisedShadowrathCount:int;

      private static const SHADOWRATH_LEVEL_TITLE:String = "Silent Assassins: Ninjas Declare War";

      private static const SHADOWRATH_REVEAL_RANGE_X:Number = 120;

      private static const SHADOWRATH_REVEAL_RANGE_Y:Number = 70;

      private static const SHADOWRATH_DEFENSE_RADIUS:Number = 700;

      private static const SHADOWRATH_REVEAL_STAGGER_FRAMES:int = 8;

      private static const SHADOWRATH_REDISGUISE_COOLDOWN_FRAMES:int = 30 * 12;

      private static const SHADOWRATH_INITIAL_DISGUISE_COOLDOWN_FRAMES:int = 30 * 10;

      private static const SHADOWRATH_HEAVY_UPDATE_INTERVAL_FRAMES:int = 5;

      private static const DEBUG_SET_ORDER:int = 0;

      private static const DEBUG_SET_CHAOS:int = 1;

      private static const LEVEL_TITLE_REBELS_UNITED:String = "Rebels United";

      private static const LEVEL_TITLE_MAGIKILL_BOSS:String = "Magic in the Air: Wizards and monks Declare War ";

      private static const LEVEL_TITLE_MEDUSA_GATES:String = "Medusa's Gates: The Chaos Capital is in sight. ";

      private static const REBELS_BOSS_QUEUE_WAVE_FRAMES:int = 30 * 10;

      private static const REBELS_BOSS_QUEUE_ACTIVE_SLOTS:int = 3;

      private var campaignMusicManager:CampaignMusicManager;

      private var campaignPrewarmManager:CampaignPrewarmManager;

      private var campaignBossMessages:CampaignBossMessages;

      private var campaignBossSpawner:CampaignBossSpawner;

      private var campaignReinforcementManager:CampaignReinforcementManager;

      private var campaignDebugTools:CampaignDebugTools;

      private var debugModeEnabled:Boolean;

      private var debugSpawnSet:int;

      private var debugLastFrameTick:int;

      private var debugLastFrameMs:Number;

      private var debugLastRealtimeFps:Number;

      private var debugLastPrewarmMs:int;

      private var debugLastEnemyAiMs:int;

      private var debugLastControllerMs:int;

      private var debugLastCoreMs:int;

      private var debugLastTotalMs:int;

      private var debugForceEnemyAttackFrames:int;

      private var debugEnemyTrainingLocked:Boolean;

      private var debugFullVisionEnabled:Boolean;

      private var debugEnemyAiFrozenAttackMode:Boolean;

      private var debugPreviousDoAiUpdates:Boolean;

      private var rebelsBossQueueActiveTypes:Object;

      private var rebelsBossQueueRecentWaves:Object;

      private var rebelsBossQueueWaveUntilFrame:int;

      private var rebelsBossQueueDebugText:String;

      public function CampaignGameScreen(main:BaseMain)
      {
         super(main);
      }
      
      override public function enter() : void
      {
         var a:int = 0;
         var b:int = 0;
         var upgrade:CampaignUpgrade = null;
         var w:Wall = null;
         var towerConstructing:ChaosTower = null;
         if(main is stickwar2 && main.tracker != null)
         {
            main.tracker.trackEvent(main.campaign.getLevelDescription(),"start");
         }
         var level:Level = main.campaign.getCurrentLevel();
         var c:Class = level.controller;
         if(c != null)
         {
            this.controller = new c(this);
         }
         else
         {
            this.controller = null;
         }
         if(!main.stickWar)
         {
            main.stickWar = new StickWar(main,this);
         }
         game = main.stickWar;
         simulation = new SimulationSyncronizer(game,main,this.endTurn,this.endGame);
         simulation.init(0);
         this.addChild(game);
         game.initGame(main,this,level.mapName);
         userInterface = new UserInterface(main,this);
         addChild(userInterface);
         a = 0;
         b = 1;
         var levelModifier:Number = level.normalModifier;
         if(main.campaign.difficultyLevel == Campaign.D_HARD)
         {
            levelModifier = level.hardModifier;
         }
         else if(main.campaign.difficultyLevel == Campaign.D_INSANE)
         {
            levelModifier = level.insaneModifier;
         }
         var healthModifier:Number = 1;
         if(main.campaign.difficultyLevel == 1)
         {
            healthModifier = level.normalHealthScale;
         }
         var damageModifier:Number = 1;
         if(main.campaign.difficultyLevel == Campaign.D_NORMAL)
         {
            damageModifier = level.normalDamageModifier;
         }
         if(Boolean(level.player.unitsAvailable[Unit.U_NINJA]))
         {
            upgrade = CampaignUpgrade(main.campaign.upgradeMap["Cloak_BASIC"]);
            upgrade.upgraded = true;
            main.campaign.techAllowed[Tech.CLOAK] = 1;
         }
         game.initTeams(Team.getIdFromRaceName(level.player.race),Team.getIdFromRaceName(level.oponent.race),level.player.statueHealth,level.oponent.statueHealth,main.campaign.techAllowed,null,1,level.insaneModifier,1,healthModifier,1,damageModifier);
         team = game.teamA;
         game.team = team;
         game.teamA.id = a;
         game.teamB.id = b;
         game.teamA.unitsAvailable = level.player.unitsAvailable;
         if(main.campaign.isGameFinished())
         {
            this.unlockAllPlayerOrderUnits();
         }
         game.teamB.unitsAvailable = level.oponent.unitsAvailable;
         game.teamA.name = a;
         game.teamB.name = b;
         this.team.enemyTeam.isEnemy = true;
         this.team.enemyTeam.isAi = true;
         team.realName = "Player";
         team.enemyTeam.realName = "Computer";
         game.teamA.statueType = level.player.statue;
         game.teamB.statueType = level.oponent.statue;
         game.teamA.gold = level.player.gold;
         game.teamA.mana = level.player.mana;
         game.teamB.gold = level.oponent.gold;
         game.teamB.mana = level.oponent.mana;
         if(main.campaign.difficultyLevel == Campaign.D_NORMAL)
         {
            game.teamA.gold += 200;
            game.teamA.mana += 200;
         }
         var playerStartingUnits:Array = level.player.startingUnits.slice(0,level.player.startingUnits.length);
         if(main.campaign.getCurrentLevel().hasInsaneWall && main.campaign.difficultyLevel == Campaign.D_INSANE)
         {
            if(game.teamB.type == Team.T_GOOD)
            {
               w = team.enemyTeam.addWall(team.enemyTeam.homeX - 900);
               w.setConstructionAmount(1);
            }
            else
            {
               towerConstructing = ChaosTower(game.unitFactory.getUnit(int(Unit.U_CHAOS_TOWER)));
               team.enemyTeam.spawn(towerConstructing,game);
               towerConstructing.scaleX *= team.enemyTeam.direction * -1;
               towerConstructing.px = team.enemyTeam.homeX - 900;
               towerConstructing.py = game.map.height / 2;
               towerConstructing.setConstructionAmount(1);
            }
         }
         if(main.campaign.currentLevel != 0)
         {
            if(main.campaign.difficultyLevel == Campaign.D_HARD)
            {
               playerStartingUnits.push(game.team.getMinerType());
            }
            else if(main.campaign.difficultyLevel == Campaign.D_NORMAL)
            {
               playerStartingUnits.push([game.team.getMinerType()]);
               w = team.addWall(team.homeX + 1200);
               w.setConstructionAmount(1);
            }
         }
         else
         {
            game.teamB.gold = 0;
         }
         this.campaignMusicManager = new CampaignMusicManager();
         this.campaignPrewarmManager = new CampaignPrewarmManager();
         this.campaignBossMessages = new CampaignBossMessages(this,game);
         this.campaignBossSpawner = new CampaignBossSpawner(game);
         this.campaignReinforcementManager = new CampaignReinforcementManager(main,game,team,this.campaignBossSpawner);
         this.campaignDebugTools = new CampaignDebugTools(this);
         this.campaignPrewarmManager.initialize(level,game,this.getCampaignReinforcementsForLevel(level.title,Campaign.D_INSANE));
         game.teamA.spawnUnitGroup(level.player.startingUnits);
         game.teamB.spawnUnitGroup(level.oponent.startingUnits);
         if(main.campaign.difficultyLevel > Campaign.D_NORMAL || Team.getIdFromRaceName(main.campaign.getCurrentLevel().oponent.race) == Team.T_CHAOS)
         {
            if(level.oponent.castleArcherLevel >= 1)
            {
               game.teamB.tech.isResearchedMap[Tech.CASTLE_ARCHER_1] = 1;
            }
            if(level.oponent.castleArcherLevel >= 2)
            {
               game.teamB.tech.isResearchedMap[Tech.CASTLE_ARCHER_2] = 1;
            }
            if(level.oponent.castleArcherLevel >= 3)
            {
               game.teamB.tech.isResearchedMap[Tech.CASTLE_ARCHER_3] = 1;
            }
            if(level.oponent.castleArcherLevel >= 4)
            {
               game.teamB.tech.isResearchedMap[Tech.CASTLE_ARCHER_4] = 1;
            }
         }
         if(level.player.castleArcherLevel >= 1)
         {
            game.teamA.tech.isResearchedMap[Tech.CASTLE_ARCHER_1] = 1;
         }
         if(level.player.castleArcherLevel >= 2)
         {
            game.teamA.tech.isResearchedMap[Tech.CASTLE_ARCHER_2] = 1;
         }
         if(level.player.castleArcherLevel >= 3)
         {
            game.teamA.tech.isResearchedMap[Tech.CASTLE_ARCHER_3] = 1;
         }
         if(level.player.castleArcherLevel >= 4)
         {
            game.teamA.tech.isResearchedMap[Tech.CASTLE_ARCHER_4] = 1;
         }
         userInterface.init(game.team);
         if(team.enemyTeam.type == Team.T_GOOD)
         {
            this.enemyTeamAi = new EnemyGoodTeamAi(team.enemyTeam,main,game);
         }
         else
         {
            this.enemyTeamAi = new EnemyChaosTeamAi(team.enemyTeam,main,game);
         }
         game.init(0);
         game.postInit();
         simulation.hasStarted = true;
         super.enter();
         this.doAiUpdates = true;
         if(this.campaignReinforcementManager != null)
         {
            this.campaignReinforcementManager.reset();
         }
         this.shadowrathRevealQueue = [];
         this.shadowrathRevealQueued = {};
         this.shadowrathDisguiseCooldowns = {};
         this.shadowrathDisguiseLockUntil = {};
         this.shadowrathSeenForInitialLock = {};
         this.shadowrathLastAttackState = -1;
         this.cachedDisguisedShadowrathCount = 0;
         this.debugModeEnabled = false;
         this.debugSpawnSet = DEBUG_SET_ORDER;
         this.debugLastFrameTick = getTimer();
         this.debugLastFrameMs = 0;
         this.debugLastRealtimeFps = 0;
         this.debugLastPrewarmMs = 0;
         this.debugLastEnemyAiMs = 0;
         this.debugLastControllerMs = 0;
         this.debugLastCoreMs = 0;
         this.debugLastTotalMs = 0;
         this.debugForceEnemyAttackFrames = 0;
         this.debugEnemyTrainingLocked = false;
         this.debugFullVisionEnabled = false;
         this.debugEnemyAiFrozenAttackMode = false;
         this.debugPreviousDoAiUpdates = true;
         this.rebelsBossQueueActiveTypes = {};
         this.rebelsBossQueueRecentWaves = {};
         this.rebelsBossQueueWaveUntilFrame = 0;
         this.rebelsBossQueueDebugText = "";
         var musicName:String = this.campaignMusicManager.getBackgroundMusic(level);
         if(this.campaignMusicManager.shouldMusicLoop(level))
         {
            game.soundManager.playSoundInBackground(musicName);
         }
         else
         {
            game.soundManager.playSoundInBackgroundOnce(musicName);
         }
      }
      
      override public function update(evt:Event, timeDiff:Number) : void
      {
         this.handleDebugHotkeys();
         this.tryTriggerCampaignReinforcements();
         if(this.campaignPrewarmManager != null)
         {
            this.campaignPrewarmManager.process();
         }
         if(this.doAiUpdates)
         {
            this.enemyTeamAi.update(game);
         }
         if(this.debugForceEnemyAttackFrames > 0 && game != null && game.teamB != null)
         {
            game.teamB.currentAttackState = Team.G_ATTACK;
            --this.debugForceEnemyAttackFrames;
         }
         if(this.controller != null)
         {
            this.controller.update(this);
         }
         this.updateShadowrathLevelDisguises();
         super.update(evt,timeDiff);
         if(this.campaignBossMessages != null)
         {
            this.campaignBossMessages.update();
         }
         if(this.campaignDebugTools != null)
         {
            this.campaignDebugTools.update();
         }
      }
      
      override public function leave() : void
      {
         this.cleanUp();
      }
      
      override public function endTurn() : void
      {
         simulation.endOfTurnMove = new EndOfTurnMove();
         simulation.endOfTurnMove.expectedNumberOfMoves = this.simulation.movesInTurn;
         simulation.endOfTurnMove.frameRate = simulation.frameRate;
         simulation.endOfTurnMove.turnSize = 5;
         simulation.endOfTurnMove.turn = simulation.turn;
         simulation.processMove(simulation.endOfTurnMove);
         simulation.movesInTurn = 0;
      }
      
      override public function endGame() : void
      {
         var u:int = 0;
         var playedLevel:Level = main.campaign.getCurrentLevel();
         var wasReplay:Boolean = main.campaign.isReplay;
         gameTimer.removeEventListener(TimerEvent.TIMER,updateGameLoop);
         gameTimer.stop();
         var e:EndOfGameMove = new EndOfGameMove();
         e.winner = game.winner.id;
         e.turn = simulation.turn;
         simulation.processMove(e);
         trace("UPDATE TIME");
         playedLevel.updateTime(game.frame / 30);
         if(main is stickwar2 && main.tracker != null)
         {
            if(e.winner == team.id)
            {
               main.tracker.trackEvent(main.campaign.getLevelDescription(),"finish","win",game.economyRecords.length);
            }
            else
            {
               main.tracker.trackEvent(main.campaign.getLevelDescription(),"finish","lose",game.economyRecords.length);
            }
         }
         main.postGameScreen.setWinner(e.winner,team.type,playedLevel.player.raceName,playedLevel.oponent.raceName,team.id);
         main.postGameScreen.setRecords(game.economyRecords,game.militaryRecords);
         if(e.winner == team.id && !wasReplay)
         {
            main.campaign.campaignPoints += this.getCampaignPointReward(playedLevel);
            if(main.campaign.currentLevel >= main.campaign.levels.length - 1)
            {
               main.campaign.currentLevel = main.campaign.levels.length;
            }
            else
            {
               ++main.campaign.currentLevel;
            }
         }
         else if(wasReplay)
         {
            if(e.winner == team.id && main.campaign.hasLockedUpgrades())
            {
               ++main.campaign.campaignPoints;
            }
            main.campaign.currentLevel = main.campaign.levels.length;
            main.campaign.isReplay = false;
            main.campaign.replayLevel = -1;
         }
         if(!wasReplay && !main.campaign.isGameFinished() && e.winner == team.id)
         {
            for each(u in main.campaign.getCurrentLevel().unlocks)
            {
               main.postGameScreen.appendUnitUnlocked(u,game);
            }
         }
         if(e.winner == team.id && !wasReplay)
         {
            main.postGameScreen.showNextUnitUnlocked();
         }
         main.postGameScreen.setMode(PostGameScreen.M_CAMPAIGN,wasReplay);
         if(e.winner == team.id)
         {
            main.postGameScreen.setTipText("");
         }
         else
         {
            main.postGameScreen.setTipText(playedLevel.tip);
         }
         if(main.campaign.justTutorial)
         {
            if(e.winner == team.id)
            {
               main.sfs.send(new ExtensionRequest("SetDoneTutorialHandler",null));
            }
            main.showScreen("lobby");
         }
         else
         {
            main.showScreen("postGame",false,true);
         }
      }
      
      override public function doMove(move:Move, id:int) : void
      {
         move.init(id,simulation.frame,simulation.turn);
         simulation.processMove(move);
         ++simulation.movesInTurn;
      }
      
      override public function cleanUp() : void
      {
         trace("Do the cleanup");
         this.enemyTeamAi = null;
         this.controller = null;
         if(this.campaignPrewarmManager != null)
         {
            this.campaignPrewarmManager.reset();
         }
         this.campaignMusicManager = null;
         this.campaignPrewarmManager = null;
         if(this.campaignBossMessages != null)
         {
            this.campaignBossMessages.cleanUp();
         }
         this.campaignBossMessages = null;
         if(this.campaignBossSpawner != null)
         {
            this.campaignBossSpawner.cleanUp();
         }
         if(this.campaignReinforcementManager != null)
         {
            this.campaignReinforcementManager.cleanUp();
         }
         if(this.campaignDebugTools != null)
         {
            this.campaignDebugTools.cleanUp();
         }
         this.campaignBossSpawner = null;
         this.campaignReinforcementManager = null;
         this.campaignDebugTools = null;
         this.debugForceEnemyAttackFrames = 0;
         this.rebelsBossQueueActiveTypes = null;
         this.rebelsBossQueueRecentWaves = null;
         this.rebelsBossQueueWaveUntilFrame = 0;
         this.rebelsBossQueueDebugText = "";
         super.cleanUp();
      }

      public function showDebugBossAbility(message:String) : void
      {
         if(!this.debugModeEnabled)
         {
            return;
         }
         if(this.campaignDebugTools != null)
         {
            this.campaignDebugTools.showToast(message);
         }
      }

      public function setDebugModeEnabled(value:Boolean) : void
      {
         this.debugModeEnabled = value;
      }

      public function setDebugSpawnSet(value:int) : void
      {
         this.debugSpawnSet = value;
      }

      public function canUseRebelsUnitedBossAbility(unit:Unit, abilityName:String = "") : Boolean
      {
         if(!this.isRebelsUnitedBossQueueEnabled() || unit == null || !unit.isBossUnit || !unit.isAlive())
         {
            return true;
         }
         this.updateRebelsUnitedBossAbilityWave();
         return this.rebelsBossQueueActiveTypes != null && unit.type in this.rebelsBossQueueActiveTypes;
      }

      public function shouldBlockEnemyStatueDamageWithMagikillWard(inflictor:Object) : Boolean
      {
         if(!this.isMagikillWardLevel() || this.isEnemyReinforcementShieldActive() || !this.isPlayerInflictor(inflictor) || !this.hasLivingEnemyMagikillBoss())
         {
            return false;
         }
         this.showMagikillWardMessage();
         return true;
      }

      private function isMagikillWardLevel() : Boolean
      {
         var title:String = null;
         if(main == null || main.campaign == null || main.campaign.getCurrentLevel() == null)
         {
            return false;
         }
         title = main.campaign.getCurrentLevel().title;
         return title == LEVEL_TITLE_MAGIKILL_BOSS || title == LEVEL_TITLE_REBELS_UNITED;
      }

      private function isPlayerInflictor(inflictor:Object) : Boolean
      {
         return game != null && (inflictor == null || inflictor is Unit && Unit(inflictor).team == game.teamA);
      }

      private function hasLivingEnemyMagikillBoss() : Boolean
      {
         var unit:Unit = null;
         if(game == null || game.teamB == null)
         {
            return false;
         }
         for each(unit in game.teamB.units)
         {
            if(unit is Magikill && unit.isAlive() && Magikill(unit).isBoss)
            {
               return true;
            }
         }
         return false;
      }

      private function showMagikillWardMessage() : void
      {
         if(this.campaignBossMessages != null)
         {
            this.campaignBossMessages.showMagikillWard();
         }
      }

      public function showMedusaLookAtMeMessage() : void
      {
         if(this.campaignBossMessages != null)
         {
            this.campaignBossMessages.showMedusaLookAtMe();
         }
      }

      private function isRebelsUnitedBossQueueEnabled() : Boolean
      {
         return game != null && main != null && main.campaign != null && main.campaign.getCurrentLevel() != null && main.campaign.getCurrentLevel().title == LEVEL_TITLE_REBELS_UNITED;
      }

      private function updateRebelsUnitedBossAbilityWave() : void
      {
         if(game == null)
         {
            return;
         }
         if(this.rebelsBossQueueActiveTypes != null && game.frame < this.rebelsBossQueueWaveUntilFrame)
         {
            return;
         }
         this.chooseRebelsUnitedBossAbilityWave();
      }

      private function chooseRebelsUnitedBossAbilityWave() : void
      {
         var candidates:Array = this.getLivingRebelsUnitedBossTypes();
         var selected:Array = [];
         var selectedTypes:Object = {};
         var slots:int = Math.min(REBELS_BOSS_QUEUE_ACTIVE_SLOTS,candidates.length);
         var totalWeight:int = 0;
         var roll:int = 0;
         var running:int = 0;
         var i:int = 0;
         var type:int = 0;
         var key:String = null;
         if(this.rebelsBossQueueRecentWaves == null)
         {
            this.rebelsBossQueueRecentWaves = {};
         }
         while(selected.length < slots && candidates.length > 0)
         {
            totalWeight = 0;
            for(i = 0; i < candidates.length; i++)
            {
               totalWeight += this.getRebelsUnitedBossQueueWeight(int(candidates[i]));
            }
            if(totalWeight <= 0)
            {
               type = int(candidates.shift());
            }
            else
            {
               roll = Math.abs(game.random.nextInt()) % totalWeight;
               running = 0;
               for(i = 0; i < candidates.length; i++)
               {
                  running += this.getRebelsUnitedBossQueueWeight(int(candidates[i]));
                  if(roll < running)
                  {
                     type = int(candidates.splice(i,1)[0]);
                     break;
                  }
               }
            }
            selected.push(type);
            selectedTypes[type] = true;
         }
         for(key in this.rebelsBossQueueRecentWaves)
         {
            this.rebelsBossQueueRecentWaves[key] = Math.min(3,int(this.rebelsBossQueueRecentWaves[key]) + 1);
         }
         for each(type in selected)
         {
            this.rebelsBossQueueRecentWaves[type] = 1;
         }
         this.rebelsBossQueueActiveTypes = selectedTypes;
         this.rebelsBossQueueDebugText = this.getRebelsUnitedBossQueueNames(selected);
         this.rebelsBossQueueWaveUntilFrame = game.frame + REBELS_BOSS_QUEUE_WAVE_FRAMES;
      }

      private function getRebelsUnitedBossQueueWeight(type:int) : int
      {
         var age:int = 0;
         if(this.rebelsBossQueueRecentWaves == null || !(type in this.rebelsBossQueueRecentWaves))
         {
            return 100;
         }
         age = int(this.rebelsBossQueueRecentWaves[type]);
         if(age <= 1)
         {
            return 20;
         }
         if(age == 2)
         {
            return 60;
         }
         return 100;
      }

      private function getLivingRebelsUnitedBossTypes() : Array
      {
         var unit:Unit = null;
         var seen:Object = {};
         var result:Array = [];
         if(game == null || game.teamB == null)
         {
            return result;
         }
         for each(unit in game.teamB.units)
         {
            if(unit == null || !unit.isAlive() || !unit.isBossUnit || !this.isRebelsUnitedQueueBossType(unit.type) || unit.type in seen)
            {
               continue;
            }
            seen[unit.type] = true;
            result.push(unit.type);
         }
         return result;
      }

      private function isRebelsUnitedQueueBossType(type:int) : Boolean
      {
         return type == Unit.U_SPEARTON || type == Unit.U_ARCHER || type == Unit.U_NINJA || type == Unit.U_MAGIKILL || type == Unit.U_MONK;
      }

      private function getRebelsUnitedBossQueueNames(types:Array) : String
      {
         var names:Array = [];
         var type:int = 0;
         if(types == null || types.length == 0)
         {
            return "none";
         }
         for each(type in types)
         {
            names.push(this.getRebelsUnitedBossName(type));
         }
         return names.join(", ");
      }

      private function getRebelsUnitedBossName(type:int) : String
      {
         switch(type)
         {
            case Unit.U_SPEARTON:
               return "Spearton";
            case Unit.U_ARCHER:
               return "Archer";
            case Unit.U_NINJA:
               return "Shadowrath";
            case Unit.U_MAGIKILL:
               return "Magikill";
            case Unit.U_MONK:
               return "Meric";
            default:
               return "Boss";
         }
      }
      
      override public function maySwitchOnDisconnect() : Boolean
      {
         return false;
      }

      public function get campaignController() : CampaignController
      {
         return this.controller;
      }

      private function unlockAllPlayerOrderUnits() : void
      {
         game.teamA.unitsAvailable[Unit.U_MINER] = 1;
         game.teamA.unitsAvailable[Unit.U_SWORDWRATH] = 1;
         game.teamA.unitsAvailable[Unit.U_ARCHER] = 1;
         game.teamA.unitsAvailable[Unit.U_SPEARTON] = 1;
         game.teamA.unitsAvailable[Unit.U_NINJA] = 1;
         game.teamA.unitsAvailable[Unit.U_FLYING_CROSSBOWMAN] = 1;
         game.teamA.unitsAvailable[Unit.U_MONK] = 1;
         game.teamA.unitsAvailable[Unit.U_MAGIKILL] = 1;
         game.teamA.unitsAvailable[Unit.U_ENSLAVED_GIANT] = 1;
      }

      private function getCampaignPointReward(level:Level) : int
      {
         if(level == null)
         {
            return 0;
         }
         return level.points;
      }

      private function tryTriggerCampaignReinforcements() : void
      {
         if(this.campaignReinforcementManager != null)
         {
            this.campaignReinforcementManager.tryTrigger();
         }
      }

      private function getCampaignReinforcementsForLevel(title:String, difficulty:int) : Array
      {
         if(this.campaignReinforcementManager != null)
         {
            return this.campaignReinforcementManager.getCampaignReinforcementsForLevel(title,difficulty);
         }
         return null;
      }

      private function spawnEnemyReinforcements(unitTypes:Array) : void
      {
         if(this.campaignReinforcementManager != null)
         {
            this.campaignReinforcementManager.spawnEnemyReinforcements(unitTypes);
         }
      }

      private function spawnShadowrathFlankReinforcements(difficulty:int) : void
      {
      }

      private function getShadowrathFlankCount(difficulty:int) : int
      {
         return difficulty == Campaign.D_NORMAL ? 2 : 3;
      }

      private function getShadowrathFlankSpawnX() : Number
      {
         return team != null ? team.medianPosition : 0;
      }

      private function activateEnemyReinforcementShield() : void
      {
      }

      private function getEnemyReinforcementShieldFrames() : int
      {
         if(main == null || main.campaign == null)
         {
            return 0;
         }
         if(main.campaign.difficultyLevel == Campaign.D_NORMAL)
         {
            return 105;
         }
         if(main.campaign.difficultyLevel == Campaign.D_HARD)
         {
            return 135;
         }
         return 150;
      }

      public function isEnemyReinforcementShieldActive() : Boolean
      {
         return this.campaignReinforcementManager != null && this.campaignReinforcementManager.isShieldActive();
      }

      private function shouldPromoteWestwindBoss(unitType:int, spawnedCount:int) : Boolean
      {
         return this.campaignBossSpawner != null && this.campaignBossSpawner.shouldPromoteWestwindBoss(unitType,spawnedCount);
      }

      private function configureWestwindBoss(unit:Unit) : void
      {
         if(this.campaignBossSpawner != null)
         {
            this.campaignBossSpawner.configureWestwindBoss(unit);
         }
      }

      private function isFactionBossLevel(title:String) : Boolean
      {
         return this.campaignBossSpawner != null && this.campaignBossSpawner.isFactionBossLevel(title);
      }

      private function shouldPromoteFactionBoss(title:String, unitType:int, spawnedCount:int) : Boolean
      {
         return this.campaignBossSpawner != null && this.campaignBossSpawner.shouldPromoteFactionBoss(title,unitType,spawnedCount);
      }

      private function configureFactionBoss(unit:Unit, title:String = "") : void
      {
         if(this.campaignBossSpawner != null)
         {
            this.campaignBossSpawner.configureFactionBoss(unit,title);
         }
      }

      private function playReinforcementSpawnEffects() : void
      {
         if(game == null || game.soundManager == null)
         {
            return;
         }
         game.soundManager.playSoundFullVolume("Rage1");
         game.soundManager.playSoundFullVolume("Rage2");
         game.soundManager.playSoundFullVolume("Rage3");
      }

      private function grantWestwindBossResearch() : void
      {
         if(this.campaignBossSpawner != null)
         {
            this.campaignBossSpawner.grantWestwindBossResearch();
         }
      }

      private function grantFactionBossResearch(title:String) : void
      {
         if(this.campaignBossSpawner != null)
         {
            this.campaignBossSpawner.grantFactionBossResearch(title);
         }
      }

      private function isShadowrathDisguiseLevelActive() : Boolean
      {
         return main != null && main.campaign != null && main.campaign.getCurrentLevel() != null && main.campaign.getCurrentLevel().title == SHADOWRATH_LEVEL_TITLE;
      }

      private function updateShadowrathLevelDisguises() : void
      {
         var unit:Unit = null;
         var snapshot:Array = null;
         var disguisedCount:int = 0;
         if(!this.isShadowrathDisguiseLevelActive() || game == null || game.teamB == null)
         {
            return;
         }
         this.updateShadowrathDisguiseCooldowns();
         this.processShadowrathRevealQueue();
         if(this.shadowrathLastAttackState != Team.G_DEFEND && game.teamB.currentAttackState == Team.G_DEFEND)
         {
            this.applyShadowrathInitialDisguiseCooldown();
         }
         this.shadowrathLastAttackState = game.teamB.currentAttackState;
         if(game.teamB.currentAttackState != Team.G_DEFEND)
         {
            this.queueRevealAllShadowrathFakeMiners();
            return;
         }
         if(game.frame % SHADOWRATH_HEAVY_UPDATE_INTERVAL_FRAMES != 0)
         {
            return;
         }
         this.applyInitialShadowrathSpawnLocks();
         this.resolveShadowrathFakeMinerPriority();
         snapshot = game.teamB.units.concat();
         for each(unit in snapshot)
         {
            if(unit is Miner && Miner(unit).isShadowrathDisguise)
            {
               ++disguisedCount;
            }
            else if(unit is Ninja && this.canShadowrathDisguise(Ninja(unit)))
            {
               this.tryDisguiseShadowrath(Ninja(unit));
            }
         }
         this.cachedDisguisedShadowrathCount = disguisedCount;
      }

      private function updateShadowrathDisguiseCooldowns() : void
      {
         var unitId:String = null;
         var numericId:int = 0;
         for(unitId in this.shadowrathDisguiseCooldowns)
         {
            if(int(this.shadowrathDisguiseCooldowns[unitId]) <= 0)
            {
               delete this.shadowrathDisguiseCooldowns[unitId];
            }
            else
            {
               this.shadowrathDisguiseCooldowns[unitId] = int(this.shadowrathDisguiseCooldowns[unitId]) - 1;
            }
         }
         for(unitId in this.shadowrathDisguiseLockUntil)
         {
            if(game == null || int(this.shadowrathDisguiseLockUntil[unitId]) <= game.frame)
            {
               delete this.shadowrathDisguiseLockUntil[unitId];
            }
         }
         for(unitId in this.shadowrathSeenForInitialLock)
         {
            numericId = int(unitId);
            if(game == null || !(numericId in game.units) || game.units[numericId] == null)
            {
               delete this.shadowrathSeenForInitialLock[unitId];
            }
         }
      }

      private function processShadowrathRevealQueue() : void
      {
         var i:int = 0;
         var entry:Object = null;
         var miner:Miner = null;
         while(i < this.shadowrathRevealQueue.length)
         {
            entry = this.shadowrathRevealQueue[i];
            entry.delay -= 1;
            if(entry.delay > 0)
            {
               ++i;
            }
            else
            {
               miner = this.getDisguisedMinerById(int(entry.unitId));
               delete this.shadowrathRevealQueued[entry.unitId];
               this.shadowrathRevealQueue.splice(i,1);
               if(miner != null)
               {
                  this.revealShadowrathFakeMiner(miner);
               }
            }
         }
      }

      private function queueRevealAllShadowrathFakeMiners() : void
      {
         var unit:Unit = null;
         var delay:int = 0;
         for each(unit in game.teamB.units)
         {
            if(unit is Miner && Miner(unit).isShadowrathDisguise && !(unit.id in this.shadowrathRevealQueued))
            {
               this.shadowrathRevealQueued[unit.id] = true;
               this.shadowrathRevealQueue.push({
                  unitId: unit.id,
                  delay: delay
               });
               delay += SHADOWRATH_REVEAL_STAGGER_FRAMES;
            }
         }
      }

      private function startShadowrathRevealChain(trigger:Miner) : void
      {
         var unit:Unit = null;
         var delay:int = 0;
         if(trigger == null)
         {
            return;
         }
         if(!(trigger.id in this.shadowrathRevealQueued))
         {
            this.shadowrathRevealQueued[trigger.id] = true;
            this.shadowrathRevealQueue.push({
               unitId: trigger.id,
               delay: 0
            });
         }
         delay = SHADOWRATH_REVEAL_STAGGER_FRAMES;
         for each(unit in game.teamB.units)
         {
            if(unit is Miner && unit != trigger && Miner(unit).isShadowrathDisguise && !(unit.id in this.shadowrathRevealQueued))
            {
               this.shadowrathRevealQueued[unit.id] = true;
               this.shadowrathRevealQueue.push({
                  unitId: unit.id,
                  delay: delay
               });
               delay += SHADOWRATH_REVEAL_STAGGER_FRAMES;
            }
         }
      }

      public function onShadowrathFakeMinerDamaged(miner:Miner) : void
      {
         if(miner == null || game == null || game.teamB == null || !this.isShadowrathDisguiseLevelActive() || !miner.isShadowrathDisguise || miner.team != game.teamB)
         {
            return;
         }
         this.startShadowrathRevealChain(miner);
      }

      private function canShadowrathDisguise(ninja:Ninja) : Boolean
      {
         if(ninja == null || !ninja.isAlive() || ninja.isGarrisoned || ninja.team != game.teamB)
         {
            return false;
         }
         if(this.getShadowrathDisguiseCooldown(ninja.id) > 0)
         {
            return false;
         }
         if(this.hasShadowrathDisguiseLock(ninja.id))
         {
            return false;
         }
         if(Math.abs(ninja.px - ninja.team.homeX) > SHADOWRATH_DEFENSE_RADIUS)
         {
            return false;
         }
         if(this.isEnemyNearUnit(ninja,SHADOWRATH_REVEAL_RANGE_X,SHADOWRATH_REVEAL_RANGE_Y))
         {
            return false;
         }
         if(ninja.isBoss)
         {
            return false;
         }
         return true;
      }

      private function tryDisguiseShadowrath(ninja:Ninja, forceDebug:Boolean = false) : Boolean
      {
         var miner:Miner = null;
         var moveCommand:MoveCommand = null;
         if(ninja == null)
         {
            return false;
         }
         miner = Miner(game.unitFactory.getUnit(Unit.U_MINER));
         game.teamB.spawn(miner,game);
         miner.x = miner.px = ninja.px;
         miner.y = miner.py = ninja.py;
         miner.health = Math.min(miner.maxHealth,ninja.health);
         miner.isShadowrathDisguise = true;
         miner.isShadowrathBossDisguise = ninja.isBoss;
         if(!this.assignFakeMinerSlot(miner))
         {
            if(!forceDebug)
            {
               game.teamB.removeUnitCompletely(miner,game);
               return false;
            }
            MinerAi(miner.ai).targetOre = null;
            MinerAi(miner.ai).isUnassigned = false;
            MinerAi(miner.ai).isGoingForOre = false;
            moveCommand = new MoveCommand(game);
            moveCommand.type = UnitCommand.MOVE;
            moveCommand.goalX = miner.px;
            moveCommand.goalY = miner.py;
            moveCommand.realX = miner.px;
            moveCommand.realY = miner.py;
            miner.ai.setCommand(game,moveCommand);
         }
         game.projectileManager.initStealthWallExplosion(miner.px,miner.py,game.teamB);
         if(miner.isShadowrathBossDisguise)
         {
            this.setShadowrathDisguiseCooldown(miner.id,0);
         }
         game.teamB.removeUnitCompletely(ninja,game);
         delete this.shadowrathDisguiseCooldowns[ninja.id];
         ++this.cachedDisguisedShadowrathCount;
         return true;
      }

      private function revealShadowrathFakeMiner(miner:Miner) : Ninja
      {
         var ninja:Ninja = null;
         var attackMove:AttackMoveCommand = null;
         var healthRatio:Number = 1;
         if(miner == null)
         {
            return null;
         }
         healthRatio = miner.maxHealth > 0 ? miner.health / miner.maxHealth : 1;
         healthRatio = Math.max(0.25,Math.min(1,healthRatio));
         MinerAi(miner.ai).targetOre = null;
         ninja = Ninja(game.unitFactory.getUnit(Unit.U_NINJA));
         game.teamB.spawn(ninja,game);
         ninja.x = ninja.px = miner.px;
         ninja.y = ninja.py = miner.py;
         if(miner.isShadowrathBossDisguise)
         {
            ninja.makeBoss();
            ninja.enableCampaignBossEscape();
         }
         ninja.health = Math.max(1,ninja.maxHealth * healthRatio);
         game.projectileManager.initStealthWallExplosion(ninja.px,ninja.py,game.teamB);
         game.teamB.removeUnitCompletely(miner,game);
         if(this.cachedDisguisedShadowrathCount > 0)
         {
            --this.cachedDisguisedShadowrathCount;
         }
         attackMove = new AttackMoveCommand(game);
         attackMove.type = UnitCommand.ATTACK_MOVE;
         attackMove.goalX = team.statue.px;
         attackMove.goalY = game.map.height / 2;
         attackMove.realX = attackMove.goalX;
         attackMove.realY = attackMove.goalY;
         ninja.ai.setCommand(game,attackMove);
         this.setShadowrathDisguiseCooldown(ninja.id,SHADOWRATH_REDISGUISE_COOLDOWN_FRAMES);
         return ninja;
      }

      private function assignFakeMinerSlot(miner:Miner) : Boolean
      {
         var goldOre:Ore = this.getFreeGoldOreForEnemyMiner(miner);
         if(goldOre != null && goldOre.reserveMiningSpot(miner))
         {
            MinerAi(miner.ai).isUnassigned = false;
            MinerAi(miner.ai).isGoingForOre = true;
            MinerAi(miner.ai).targetOre = goldOre;
            return true;
         }
         if(!miner.team.statue.isMineFull() && miner.team.statue.reserveMiningSpot(miner))
         {
            MinerAi(miner.ai).isUnassigned = false;
            MinerAi(miner.ai).isGoingForOre = false;
            MinerAi(miner.ai).targetOre = miner.team.statue;
            return true;
         }
         return false;
      }

      private function resolveShadowrathFakeMinerPriority() : void
      {
         var unit:Unit = null;
         var miner:Miner = null;
         var needsSlot:Boolean = false;
         for each(unit in game.teamB.units)
         {
            if(unit is Miner && !Miner(unit).isShadowrathDisguise)
            {
               if(MinerAi(unit.ai).targetOre == null)
               {
                  needsSlot = true;
                  break;
               }
            }
         }
         if(!needsSlot)
         {
            return;
         }
         for each(unit in game.teamB.units)
         {
            if(!(unit is Miner) || !Miner(unit).isShadowrathDisguise)
            {
               continue;
            }
            miner = Miner(unit);
            if(!this.reassignFakeMinerSlot(miner))
            {
               this.startShadowrathRevealChain(miner);
            }
            break;
         }
      }

      private function reassignFakeMinerSlot(miner:Miner) : Boolean
      {
         var goldOre:Ore = null;
         if(miner == null)
         {
            return false;
         }
         goldOre = this.getFreeGoldOreForEnemyMiner(miner);
         if(goldOre != null && goldOre != MinerAi(miner.ai).targetOre && goldOre.reserveMiningSpot(miner))
         {
            MinerAi(miner.ai).isUnassigned = false;
            MinerAi(miner.ai).isGoingForOre = true;
            MinerAi(miner.ai).targetOre = goldOre;
            return true;
         }
         if(MinerAi(miner.ai).targetOre != miner.team.statue && this.moveFakeMinerToPrayer(miner))
         {
            return true;
         }
         return false;
      }

      private function moveFakeMinerToPrayer(miner:Miner) : Boolean
      {
         if(miner == null || miner.team.statue.isMineFull() || !miner.team.statue.reserveMiningSpot(miner))
         {
            return false;
         }
         MinerAi(miner.ai).isUnassigned = false;
         MinerAi(miner.ai).isGoingForOre = false;
         MinerAi(miner.ai).targetOre = miner.team.statue;
         return true;
      }

      private function getFreeGoldOreForEnemyMiner(miner:Miner) : Ore
      {
         var i:int = 0;
         if(miner == null || game == null || game.map == null)
         {
            return null;
         }
         if(miner.team.direction == 1)
         {
            for(i = 0; i < game.map.gold.length / 2; i++)
            {
               if(!game.map.gold[i].isMineFull())
               {
                  return game.map.gold[i];
               }
            }
         }
         else
         {
            for(i = game.map.gold.length - 1; i >= game.map.gold.length / 2; i--)
            {
               if(!game.map.gold[i].isMineFull())
               {
                  return game.map.gold[i];
               }
            }
         }
         return null;
      }

      private function getDisguisedMinerById(unitId:int) : Miner
      {
         if(game != null && unitId in game.units && game.units[unitId] is Miner && Miner(game.units[unitId]).isShadowrathDisguise)
         {
            return Miner(game.units[unitId]);
         }
         return null;
      }

      private function getShadowrathDisguiseCooldown(unitId:int) : int
      {
         return unitId in this.shadowrathDisguiseCooldowns ? int(this.shadowrathDisguiseCooldowns[unitId]) : 0;
      }

      private function setShadowrathDisguiseCooldown(unitId:int, frames:int) : void
      {
         this.shadowrathDisguiseCooldowns[unitId] = frames;
      }

      private function setShadowrathDisguiseLock(unitId:int, frames:int) : void
      {
         this.shadowrathDisguiseLockUntil[unitId] = game != null ? game.frame + frames : frames;
      }

      private function hasShadowrathDisguiseLock(unitId:int) : Boolean
      {
         if(!(unitId in this.shadowrathDisguiseLockUntil))
         {
            return false;
         }
         return game != null && int(this.shadowrathDisguiseLockUntil[unitId]) > game.frame;
      }

      private function applyShadowrathInitialDisguiseCooldown() : void
      {
         var unit:Unit = null;
         for each(unit in game.teamB.units)
         {
            if(unit is Ninja && unit.isAlive())
            {
               this.setShadowrathDisguiseLock(unit.id,SHADOWRATH_INITIAL_DISGUISE_COOLDOWN_FRAMES);
            }
         }
      }

      private function applyInitialShadowrathSpawnLocks() : void
      {
         var unit:Unit = null;
         for each(unit in game.teamB.units)
         {
            if(unit is Ninja && unit.isAlive() && !(unit.id in this.shadowrathSeenForInitialLock))
            {
               this.shadowrathSeenForInitialLock[unit.id] = true;
               this.setShadowrathDisguiseLock(unit.id,SHADOWRATH_INITIAL_DISGUISE_COOLDOWN_FRAMES);
            }
         }
      }

      private function isEnemyNearUnit(unit:Unit, rangeX:Number, rangeY:Number) : Boolean
      {
         var enemy:Unit = null;
         for each(enemy in unit.team.enemyTeam.units)
         {
            if(enemy != null && enemy.isAlive() && Math.abs(enemy.px - unit.px) <= rangeX && Math.abs(enemy.py - unit.py) <= rangeY)
            {
               return true;
            }
         }
         return false;
      }

      public function spawnDebugKnightBoss() : void
      {
         var boss:Unit = null;
         var spawnX:Number = NaN;
         var spawnY:Number = NaN;
         if(game == null || game.teamB == null || game.teamB.tech == null)
         {
            return;
         }
         if(!this.canDebugSpawnUnitOnTeam(Unit.U_KNIGHT,game.teamB))
         {
            return;
         }
         game.teamB.tech.isResearchedMap[Tech.KNIGHT_CHARGE] = true;
         boss = game.unitFactory.getUnit(Unit.U_KNIGHT);
         game.teamB.spawn(boss,game);
         if(boss is Knight)
         {
            Knight(boss).makeBoss();
         }
         boss.isBossMovementLocked = false;
         spawnX = game.teamB.homeX + game.teamB.direction * 180;
         spawnY = game.map.height / 2;
         boss.x = boss.px = spawnX;
         boss.y = boss.py = spawnY;
         game.teamB.population += boss.population;
         this.commandDebugBossForCurrentArmyState(boss);
         this.applyDebugFrozenAttackModeToUnit(boss);
         game.projectileManager.initTowerSpawn(spawnX,spawnY,game.teamB,0.7);
         game.projectileManager.initSpawnDrip(spawnX,spawnY,game.teamB);
         game.soundManager.playSoundFullVolume("Rage1");
      }

      public function damageDebugEnemyStatue(amount:Number) : void
      {
         if(game == null || game.teamB == null || game.teamB.statue == null)
         {
            return;
         }
         game.teamB.statue.health = Math.max(1,game.teamB.statue.health - amount);
         this.showDebugBossAbility("DEBUG: Enemy statue -" + amount + " HP");
      }

      public function spawnDebugAlliedUnit(unitType:int, count:int) : void
      {
         var ally:Unit = null;
         var spawnX:Number = NaN;
         var spawnY:Number = NaN;
         var i:int = 0;
         var attackMoveCommand:AttackMoveCommand = null;
         if(game == null || game.teamA == null || game.teamB == null)
         {
            return;
         }
         if(!this.canDebugSpawnUnitOnTeam(unitType,game.teamA))
         {
            return;
         }
         spawnX = game.teamA.homeX + game.teamA.direction * 220;
         spawnY = game.map.height / 2;
         for(i = 0; i < count; i++)
         {
            ally = game.unitFactory.getUnit(unitType);
            game.teamA.spawn(ally,game);
            ally.x = ally.px = spawnX - game.teamA.direction * i * 55;
            ally.y = ally.py = spawnY + (i - (count - 1) / 2) * 40;
            game.teamA.population += ally.population;
            game.projectileManager.initTowerSpawn(ally.px,ally.py,game.teamA,0.6);
            game.projectileManager.initSpawnDrip(ally.px,ally.py,game.teamA);
            attackMoveCommand = new AttackMoveCommand(game);
            attackMoveCommand.type = UnitCommand.ATTACK_MOVE;
            attackMoveCommand.goalX = game.teamB.statue.px;
            attackMoveCommand.goalY = game.map.height / 2;
            attackMoveCommand.realX = game.teamB.statue.px;
            attackMoveCommand.realY = game.map.height / 2;
            ally.ai.setCommand(game,attackMoveCommand);
         }
      }

      public function spawnDebugAlliedGroupAtBase(unitTypes:Array) : void
      {
         var ally:Unit = null;
         var spawnX:Number = NaN;
         var spawnY:Number = NaN;
         var i:int = 0;
         var attackMoveCommand:AttackMoveCommand = null;
         if(game == null || game.teamA == null || game.teamB == null)
         {
            return;
         }
         if(!this.canDebugSpawnUnitGroupOnTeam(unitTypes,game.teamA))
         {
            return;
         }
         spawnX = game.teamA.homeX + game.teamA.direction * 220;
         spawnY = game.map.height / 2;
         for(i = 0; i < unitTypes.length; i++)
         {
            ally = game.unitFactory.getUnit(int(unitTypes[i]));
            game.teamA.spawn(ally,game);
            ally.x = ally.px = spawnX - game.teamA.direction * i * 55;
            ally.y = ally.py = spawnY + (i - (unitTypes.length - 1) / 2) * 40;
            game.teamA.population += ally.population;
            game.projectileManager.initTowerSpawn(ally.px,ally.py,game.teamA,0.6);
            game.projectileManager.initSpawnDrip(ally.px,ally.py,game.teamA);
            attackMoveCommand = new AttackMoveCommand(game);
            attackMoveCommand.type = UnitCommand.ATTACK_MOVE;
            attackMoveCommand.goalX = game.teamB.statue.px;
            attackMoveCommand.goalY = game.map.height / 2;
            attackMoveCommand.realX = game.teamB.statue.px;
            attackMoveCommand.realY = game.map.height / 2;
            ally.ai.setCommand(game,attackMoveCommand);
         }
      }

      public function spawnDebugBoss(unitType:int) : void
      {
         var boss:Unit = null;
         var ally:Unit = null;
         var spawnX:Number = NaN;
         var spawnY:Number = NaN;
         var offsetY:Number = NaN;
         var i:int = 0;
         if(game == null || game.teamB == null)
         {
            return;
         }
         if(!this.canDebugSpawnUnitOnTeam(unitType,game.teamB))
         {
            return;
         }
         this.grantWestwindBossResearch();
         boss = game.unitFactory.getUnit(unitType);
         game.teamB.spawn(boss,game);
         this.configureWestwindBoss(boss);
         spawnX = game.teamB.homeX + game.teamB.direction * 180;
         spawnY = game.map.height / 2;
         boss.x = boss.px = spawnX;
         boss.y = boss.py = spawnY;
         game.teamB.population += boss.population;
         this.commandDebugBossForCurrentArmyState(boss);
         this.applyDebugFrozenAttackModeToUnit(boss);
         game.projectileManager.initTowerSpawn(spawnX,spawnY,game.teamB,0.7);
         game.projectileManager.initSpawnDrip(spawnX,spawnY,game.teamB);
         game.soundManager.playSoundFullVolume("Rage1");
         if(unitType == Unit.U_SPEARTON)
         {
            for(i = 0; i < 2; i++)
            {
               ally = game.unitFactory.getUnit(Unit.U_SPEARTON);
               game.teamB.spawn(ally,game);
               ally.x = ally.px = spawnX - game.teamB.direction * (60 + i * 35);
               offsetY = i == 0 ? -25 : 25;
               ally.y = ally.py = spawnY + offsetY;
               game.teamB.population += ally.population;
               this.applyDebugFrozenAttackModeToUnit(ally);
            }
         }
      }

      public function spawnDebugThumbnailBossLineup() : void
      {
         var bossTypes:Array = [Unit.U_SPEARTON,Unit.U_ARCHER,Unit.U_NINJA,Unit.U_MAGIKILL,Unit.U_MONK,Unit.U_KNIGHT,Unit.U_WINGIDON,Unit.U_SKELATOR,Unit.U_MEDUSA];
         var boss:Unit = null;
         var standCommand:StandCommand = null;
         var spawnX:Number = NaN;
         var spawnY:Number = NaN;
         var i:int = 0;
         if(game == null || game.teamA == null)
         {
            return;
         }
         this.grantWestwindBossResearch();
         this.grantFactionBossResearch(LEVEL_TITLE_MEDUSA_GATES);
         this.clearDebugThumbnailStage();
         spawnX = game.teamA.homeX + game.teamA.direction * 520;
         spawnY = game.map.height / 2;
         for(i = 0; i < bossTypes.length; i++)
         {
            this.ensureDebugUnitGroup(game.teamA,int(bossTypes[i]));
            boss = game.unitFactory.getUnit(int(bossTypes[i]));
            game.teamA.spawn(boss,game);
            this.configureThumbnailBoss(boss);
            boss.x = boss.px = spawnX - game.teamA.direction * (i - (bossTypes.length - 1) / 2) * 70;
            boss.y = boss.py = Math.max(80,Math.min(game.map.height - 80,spawnY + (i % 2 == 0 ? -45 : 45)));
            boss.isBossMovementLocked = false;
            boss.mayWalkThrough = false;
            standCommand = new StandCommand(game);
            boss.ai.setCommand(game,standCommand);
            game.teamA.population += boss.population;
         }
         this.showDebugBossAbility("DEBUG: Thumbnail boss lineup spawned");
      }

      private function clearDebugThumbnailStage() : void
      {
         var ore:Ore = null;
         var gold:Gold = null;
         var unit:Unit = null;
         var snapshot:Array = null;
         if(game == null)
         {
            return;
         }
         if(game.map != null && game.map.gold != null)
         {
            for each(ore in game.map.gold)
            {
               if(ore is Gold)
               {
                  gold = Gold(ore);
                  gold.ore.visible = false;
                  gold.frontOre.visible = false;
                  gold.ore.mouseEnabled = false;
                  gold.frontOre.mouseEnabled = false;
               }
            }
         }
         if(game.teamA != null)
         {
            game.teamA.gold = 0;
            snapshot = game.teamA.units.concat();
            for each(unit in snapshot)
            {
               if(unit is ChaosTower)
               {
                  game.teamA.removeUnitCompletely(unit,game);
               }
            }
         }
         if(game.teamB != null)
         {
            game.teamB.gold = 0;
            snapshot = game.teamB.units.concat();
            for each(unit in snapshot)
            {
               if(unit is ChaosTower)
               {
                  game.teamB.removeUnitCompletely(unit,game);
               }
            }
         }
      }

      private function ensureDebugUnitGroup(targetTeam:Team, unitType:int) : void
      {
         if(targetTeam == null || targetTeam.unitGroups == null)
         {
            return;
         }
         if(targetTeam.unitGroups[unitType] == null)
         {
            targetTeam.unitGroups[unitType] = [];
         }
      }

      private function configureThumbnailBoss(unit:Unit) : void
      {
         if(unit == null)
         {
            return;
         }
         if(unit is Medusa)
         {
            Medusa(unit).enableSuperMedusa();
            return;
         }
         this.configureWestwindBoss(unit);
      }

      private function commandDebugBossForCurrentArmyState(boss:Unit) : void
      {
         var attackMoveCommand:AttackMoveCommand = null;
         if(boss == null || game == null || game.teamB == null || game.teamA == null)
         {
            return;
         }
         attackMoveCommand = new AttackMoveCommand(game);
         attackMoveCommand.type = UnitCommand.ATTACK_MOVE;
         if(game.teamB.currentAttackState == Team.G_ATTACK)
         {
            attackMoveCommand.goalX = game.teamA.statue.px;
            attackMoveCommand.goalY = game.map.height / 2;
            attackMoveCommand.realX = game.teamA.statue.px;
            attackMoveCommand.realY = game.map.height / 2;
            boss.ai.setCommand(game,attackMoveCommand);
            return;
         }
         attackMoveCommand.goalX = game.teamB.homeX + game.teamB.direction * 600;
         attackMoveCommand.goalY = game.map.height / 2;
         attackMoveCommand.realX = attackMoveCommand.goalX;
         attackMoveCommand.realY = attackMoveCommand.goalY;
         boss.ai.setCommand(game,attackMoveCommand);
      }

      private function spawnDebugEnemy(unitType:int) : void
      {
         var enemy:Unit = null;
         var spawnX:Number = NaN;
         var spawnY:Number = NaN;
         var attackMoveCommand:AttackMoveCommand = null;
         if(game == null || game.teamB == null)
         {
            return;
         }
         if(!this.canDebugSpawnUnitOnTeam(unitType,game.teamB))
         {
            return;
         }
         game.teamB.currentAttackState = Team.G_ATTACK;
         this.debugForceEnemyAttackFrames = 30 * 3;
         enemy = game.unitFactory.getUnit(unitType);
         game.teamB.spawn(enemy,game);
         spawnX = game.teamB.homeX + game.teamB.direction * 220;
         spawnY = game.map.height / 2;
         enemy.x = enemy.px = spawnX;
         enemy.y = enemy.py = spawnY;
         game.teamB.population += enemy.population;
         game.projectileManager.initTowerSpawn(spawnX,spawnY,game.teamB,0.6);
         game.projectileManager.initSpawnDrip(spawnX,spawnY,game.teamB);
         attackMoveCommand = new AttackMoveCommand(game);
         attackMoveCommand.type = UnitCommand.ATTACK_MOVE;
         attackMoveCommand.goalX = game.teamA.statue.px;
         attackMoveCommand.goalY = game.map.height / 2;
         attackMoveCommand.realX = game.teamA.statue.px;
         attackMoveCommand.realY = game.map.height / 2;
         enemy.ai.setCommand(game,attackMoveCommand);
         this.applyDebugFrozenAttackModeToUnit(enemy);
      }

      public function spawnDebugEnemyAtBase(unitType:int, count:int) : void
      {
         var enemy:Unit = null;
         var spawnX:Number = NaN;
         var spawnY:Number = NaN;
         var i:int = 0;
         if(game == null || game.teamB == null)
         {
            return;
         }
         if(!this.canDebugSpawnUnitOnTeam(unitType,game.teamB))
         {
            return;
         }
         spawnX = game.teamB.homeX + game.teamB.direction * 220;
         spawnY = game.map.height / 2;
         for(i = 0; i < count; i++)
         {
            enemy = game.unitFactory.getUnit(unitType);
            game.teamB.spawn(enemy,game);
            enemy.x = enemy.px = spawnX - game.teamB.direction * i * 55;
            enemy.y = enemy.py = spawnY + (i - (count - 1) / 2) * 40;
            game.teamB.population += enemy.population;
            game.projectileManager.initTowerSpawn(enemy.px,enemy.py,game.teamB,0.6);
            game.projectileManager.initSpawnDrip(enemy.px,enemy.py,game.teamB);
            this.applyDebugFrozenAttackModeToUnit(enemy);
         }
      }

      public function spawnDebugEnemyGroupAtBase(unitTypes:Array) : void
      {
         var enemy:Unit = null;
         var spawnX:Number = NaN;
         var spawnY:Number = NaN;
         var i:int = 0;
         if(game == null || game.teamB == null)
         {
            return;
         }
         if(!this.canDebugSpawnUnitGroupOnTeam(unitTypes,game.teamB))
         {
            return;
         }
         spawnX = game.teamB.homeX + game.teamB.direction * 220;
         spawnY = game.map.height / 2;
         for(i = 0; i < unitTypes.length; i++)
         {
            enemy = game.unitFactory.getUnit(int(unitTypes[i]));
            game.teamB.spawn(enemy,game);
            enemy.x = enemy.px = spawnX - game.teamB.direction * i * 55;
            enemy.y = enemy.py = spawnY + (i - (unitTypes.length - 1) / 2) * 40;
            game.teamB.population += enemy.population;
            game.projectileManager.initTowerSpawn(enemy.px,enemy.py,game.teamB,0.6);
            game.projectileManager.initSpawnDrip(enemy.px,enemy.py,game.teamB);
            this.applyDebugFrozenAttackModeToUnit(enemy);
         }
      }

      public function toggleDebugEnemyAiFreezeAttackMode() : void
      {
         if(game == null || game.teamB == null)
         {
            return;
         }
         this.debugEnemyAiFrozenAttackMode = !this.debugEnemyAiFrozenAttackMode;
         if(this.debugEnemyAiFrozenAttackMode)
         {
            this.debugPreviousDoAiUpdates = this.doAiUpdates;
            this.doAiUpdates = false;
            if(this.enemyTeamAi != null)
            {
               this.enemyTeamAi.setUnitCreationEnabled(false);
            }
            this.forceDebugEnemyArmyAttackMove();
            this.showDebugBossAbility("DEBUG: Enemy AI frozen; attack move forced");
         }
         else
         {
            this.doAiUpdates = this.debugPreviousDoAiUpdates;
            if(this.enemyTeamAi != null)
            {
               this.enemyTeamAi.setUnitCreationEnabled(!this.debugEnemyTrainingLocked);
            }
            this.unlockDebugEnemyArmyMovement();
            this.showDebugBossAbility("DEBUG: Enemy AI resumed");
         }
      }

      private function forceDebugEnemyArmyAttackMove() : void
      {
         var unit:Unit = null;
         if(game == null || game.teamB == null)
         {
            return;
         }
         game.teamB.currentAttackState = Team.G_ATTACK;
         for each(unit in game.teamB.units)
         {
            this.applyDebugFrozenAttackModeToUnit(unit);
         }
      }

      private function unlockDebugEnemyArmyMovement() : void
      {
         var unit:Unit = null;
         if(game == null || game.teamB == null)
         {
            return;
         }
         for each(unit in game.teamB.units)
         {
            if(unit != null && unit.type != Unit.U_STATUE)
            {
               unit.isBossMovementLocked = false;
            }
         }
      }

      private function applyDebugFrozenAttackModeToUnit(unit:Unit) : void
      {
         var attackMoveCommand:AttackMoveCommand = null;
         if(!this.debugEnemyAiFrozenAttackMode || unit == null || game == null || game.teamA == null || unit.team != game.teamB || !unit.isAlive() || unit.type == Unit.U_STATUE || unit.type == Unit.U_CHAOS_TOWER || unit.ai == null)
         {
            return;
         }
         unit.isBossMovementLocked = true;
         attackMoveCommand = new AttackMoveCommand(game);
         attackMoveCommand.type = UnitCommand.ATTACK_MOVE;
         attackMoveCommand.goalX = game.teamA.statue.px;
         attackMoveCommand.goalY = game.map.height / 2;
         attackMoveCommand.realX = game.teamA.statue.px;
         attackMoveCommand.realY = game.map.height / 2;
         unit.ai.setCommand(game,attackMoveCommand);
      }

      private function canDebugSpawnUnitGroupOnTeam(unitTypes:Array, targetTeam:Team) : Boolean
      {
         var unitType:int = 0;
         if(unitTypes == null)
         {
            return false;
         }
         for each(unitType in unitTypes)
         {
            if(!this.canDebugSpawnUnitOnTeam(unitType,targetTeam))
            {
               return false;
            }
         }
         return true;
      }

      private function canDebugSpawnUnitOnTeam(unitType:int, targetTeam:Team) : Boolean
      {
         var expectedTeam:int = this.getDebugUnitTeamType(unitType);
         if(targetTeam == null || expectedTeam == -1)
         {
            return false;
         }
         if(targetTeam.type != expectedTeam)
         {
            this.showDebugBossAbility("DEBUG SPAWN REJECTED: wrong empire");
            return false;
         }
         return true;
      }

      private function getDebugUnitTeamType(unitType:int) : int
      {
         switch(unitType)
         {
            case Unit.U_MINER:
            case Unit.U_SWORDWRATH:
            case Unit.U_ARCHER:
            case Unit.U_SPEARTON:
            case Unit.U_NINJA:
            case Unit.U_FLYING_CROSSBOWMAN:
            case Unit.U_MONK:
            case Unit.U_MAGIKILL:
            case Unit.U_ENSLAVED_GIANT:
               return Team.T_GOOD;
            case Unit.U_CHAOS_MINER:
            case Unit.U_BOMBER:
            case Unit.U_WINGIDON:
            case Unit.U_SKELATOR:
            case Unit.U_DEAD:
            case Unit.U_CAT:
            case Unit.U_KNIGHT:
            case Unit.U_MEDUSA:
            case Unit.U_GIANT:
               return Team.T_CHAOS;
            default:
               return -1;
         }
      }

      public function killEnemyUnitsAndLockTraining() : void
      {
         var unit:Unit = null;
         var snapshot:Array = null;
         if(game == null || game.teamB == null)
         {
            return;
         }
         this.debugEnemyTrainingLocked = true;
         if(this.enemyTeamAi != null)
         {
            this.enemyTeamAi.setUnitCreationEnabled(false);
         }
         snapshot = game.teamB.units.concat();
         for each(unit in snapshot)
         {
            if(unit != null && unit.isAlive() && unit.type != Unit.U_STATUE)
            {
               unit.health = 0;
               unit.isDieing = true;
               if(unit.healthBar != null)
               {
                  unit.healthBar.health = 0;
                  unit.healthBar.update();
               }
            }
         }
         this.showDebugBossAbility("DEBUG: Enemy units killed; training locked");
      }

      private function handleDebugHotkeys() : void
      {
         if(this.campaignDebugTools != null)
         {
            this.campaignDebugTools.handleHotkeys();
         }
      }

      private function playDebugBackgroundMusic(name:String) : void
      {
         if(game == null || game.soundManager == null)
         {
            return;
         }
         game.soundManager.playSoundInBackground(name);
         this.showDebugBossAbility("DEBUG MUSIC: " + name);
      }

      private function getDebugSpawnSetName() : String
      {
         return this.debugSpawnSet == DEBUG_SET_CHAOS ? "Chaos" : "Order";
      }

      private function formatNumber(value:Number) : String
      {
         return value.toFixed(1);
      }

      private function describeAttackState(state:int) : String
      {
         if(state == Team.G_ATTACK)
         {
            return "ATTACK";
         }
         if(state == Team.G_DEFEND)
         {
            return "DEFEND";
         }
         return "IDLE";
      }

      private function getUnitCount(targetTeam:Team) : int
      {
         var count:int = 0;
         var unit:Unit = null;
         if(targetTeam == null)
         {
            return 0;
         }
         for each(unit in targetTeam.units)
         {
            if(unit != null && unit.isAlive())
            {
               ++count;
            }
         }
         return count;
      }

      private function getProjectileCount() : int
      {
         return game != null && game.projectileManager != null && game.projectileManager.projectiles != null ? game.projectileManager.projectiles.length : 0;
      }

      private function getAirEffectCount() : int
      {
         return game != null && game.projectileManager != null && game.projectileManager.airEffects != null ? game.projectileManager.airEffects.length : 0;
      }

      private function triggerDebugSpeartonBossSpecial() : void
      {
         var unit:Unit = null;
         if(game == null || game.teamB == null)
         {
            return;
         }
         this.grantWestwindBossResearch();
         for each(unit in game.teamB.units)
         {
            if(unit is Spearton && Spearton(unit).isBoss && unit.isAlive())
            {
               Spearton(unit).resetBossSpecialDebugState();
               Spearton(unit).tryBossBraceShieldSlam();
               break;
            }
         }
      }

      private function triggerDebugShadowrathEscapeEffect() : void
      {
         var unit:Unit = null;
         if(game == null || game.teamB == null)
         {
            return;
         }
         for each(unit in game.teamB.units)
         {
            if(unit is Ninja && Ninja(unit).isBoss && unit.isAlive())
            {
               game.projectileManager.initWallExplosion(unit.px,unit.py,game.teamB);
               game.soundManager.playSound("mediumExplosion3",unit.px,unit.py);
               return;
            }
         }
      }

      public function toggleDebugFullVision() : void
      {
         if(game == null || game.fogOfWar == null)
         {
            return;
         }
         this.debugFullVisionEnabled = !this.debugFullVisionEnabled;
         game.fogOfWar.isFogOn = !this.debugFullVisionEnabled;
      }

      public function get isDebugFullVisionEnabled() : Boolean
      {
         return this.debugFullVisionEnabled;
      }

      public function spawnDebugShadowrathAtEnemyBase() : void
      {
         var enemy:Unit = null;
         var spawnX:Number = NaN;
         var spawnY:Number = NaN;
         var moveCommand:MoveCommand = null;
         if(game == null || game.teamB == null)
         {
            return;
         }
         if(!this.canDebugSpawnUnitOnTeam(Unit.U_NINJA,game.teamB))
         {
            return;
         }
         enemy = game.unitFactory.getUnit(Unit.U_NINJA);
         game.teamB.spawn(enemy,game);
         spawnX = game.teamB.homeX + game.teamB.direction * 140;
         spawnY = game.map.height / 2;
         enemy.x = enemy.px = spawnX;
         enemy.y = enemy.py = spawnY;
         game.teamB.population += enemy.population;
         this.setShadowrathDisguiseLock(enemy.id,SHADOWRATH_INITIAL_DISGUISE_COOLDOWN_FRAMES);
         game.projectileManager.initTowerSpawn(spawnX,spawnY,game.teamB,0.6);
         game.projectileManager.initSpawnDrip(spawnX,spawnY,game.teamB);
         moveCommand = new MoveCommand(game);
         moveCommand.type = UnitCommand.MOVE;
         moveCommand.goalX = spawnX;
         moveCommand.goalY = spawnY;
         moveCommand.realX = spawnX;
         moveCommand.realY = spawnY;
         enemy.ai.setCommand(game,moveCommand);
         this.applyDebugFrozenAttackModeToUnit(enemy);
      }

      private function triggerDebugShadowrathDisguise() : void
      {
         var unit:Unit = null;
         var snapshot:Array = null;
         if(game == null || game.teamB == null)
         {
            return;
         }
         snapshot = game.teamB.units.concat();
         for each(unit in snapshot)
         {
            if(unit is Ninja && unit.isAlive() && !unit.isGarrisoned && unit.team == game.teamB)
            {
               delete this.shadowrathDisguiseCooldowns[unit.id];
               delete this.shadowrathDisguiseLockUntil[unit.id];
               this.tryDisguiseShadowrath(Ninja(unit),true);
            }
         }
      }

      public function getDisguisedShadowrathCount() : int
      {
         if(game == null || game.teamB == null)
         {
            return 0;
         }
         return this.cachedDisguisedShadowrathCount;
      }

      public function revealShadowrathDisguises(limit:int = -1) : int
      {
         var unit:Unit = null;
         var snapshot:Array = null;
         var revealed:int = 0;
         var miner:Miner = null;
         if(game == null || game.teamB == null)
         {
            return 0;
         }
         snapshot = game.teamB.units.concat();
         for each(unit in snapshot)
         {
            if(!(unit is Miner) || !Miner(unit).isShadowrathDisguise || !unit.isAlive())
            {
               continue;
            }
            miner = Miner(unit);
            this.revealShadowrathFakeMiner(miner);
            ++revealed;
            if(limit >= 0 && revealed >= limit)
            {
               break;
            }
         }
         return revealed;
      }
   }
}
