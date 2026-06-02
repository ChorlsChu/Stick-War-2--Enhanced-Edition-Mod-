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
   import flash.system.System;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import flash.ui.Keyboard;
   import flash.utils.getTimer;
   
   public class CampaignGameScreen extends GameScreen
   {
      
      private var enemyTeamAi:EnemyTeamAi;
      
      private var controller:CampaignController;
      
      public var doAiUpdates:Boolean;

      private var hasTriggeredCampaignReinforcements:Boolean;

      private var enemyReinforcementShieldUntilFrame:int;

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

      private static const PREWARM_INTERVAL_FRAMES:int = 10;

      private static const DEBUG_SET_ORDER:int = 0;

      private static const DEBUG_SET_CHAOS:int = 1;

      private static const LEVEL_TITLE_REBELS_UNITED:String = "Rebels United";

      private static const LEVEL_TITLE_MAGIKILL_BOSS:String = "Magic in the Air: Wizards and monks Declare War ";

      private static const LEVEL_TITLE_MEDUSA_GATES:String = "Medusa's Gates: The Chaos Capital is in sight. ";

      private static const REBELS_BOSS_QUEUE_WAVE_FRAMES:int = 30 * 10;

      private static const REBELS_BOSS_QUEUE_ACTIVE_SLOTS:int = 3;

      private static const MAGIKILL_WARD_MESSAGE:String = "The Magikill Archmage is shielding the statue!\nDefeat him to break the ward.";

      private static const MAGIKILL_WARD_MESSAGE_COOLDOWN_FRAMES:int = 30 * 14;

      private static const MAGIKILL_WARD_MESSAGE_DURATION_FRAMES:int = 30 * 7;

      private static const MEDUSA_LOOK_AT_ME_MESSAGE:String = "Look away to avoid being turned to stone.";

      private static const MEDUSA_LOOK_AT_ME_MESSAGE_COOLDOWN_FRAMES:int = 30 * 14;

      private static const MEDUSA_LOOK_AT_ME_MESSAGE_DURATION_FRAMES:int = 30 * 7;

      private var delayedLevelPrewarmQueue:Array;

      private var nextLevelPrewarmFrame:int;

      private var debugModeEnabled:Boolean;

      private var debugSpawnSet:int;

      private var debugOverlay:TextField;

      private var debugAbilityToast:TextField;

      private var debugAbilityToastText:String;

      private var debugAbilityToastUntilFrame:int;

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

      private var rebelsBossQueueActiveTypes:Object;

      private var rebelsBossQueueRecentWaves:Object;

      private var rebelsBossQueueWaveUntilFrame:int;

      private var rebelsBossQueueDebugText:String;

      private var nextMagikillWardMessageFrame:int;

      private var magikillWardMessageHideFrame:int;

      private var magikillWardMessageActive:Boolean;

      private var magikillWardMessage:inGameMessageBoxMc;

      private var nextMedusaLookAtMeMessageFrame:int;

      private var medusaLookAtMeMessageHideFrame:int;

      private var medusaLookAtMeMessageActive:Boolean;

      private var medusaLookAtMeMessage:inGameMessageBoxMc;
      
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
         this.initializeLevelPrewarm(level);
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
         this.hasTriggeredCampaignReinforcements = false;
         this.enemyReinforcementShieldUntilFrame = 0;
         this.shadowrathRevealQueue = [];
         this.shadowrathRevealQueued = {};
         this.shadowrathDisguiseCooldowns = {};
         this.shadowrathDisguiseLockUntil = {};
         this.shadowrathSeenForInitialLock = {};
         this.shadowrathLastAttackState = -1;
         this.cachedDisguisedShadowrathCount = 0;
         this.nextLevelPrewarmFrame = PREWARM_INTERVAL_FRAMES;
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
         this.rebelsBossQueueActiveTypes = {};
         this.rebelsBossQueueRecentWaves = {};
         this.rebelsBossQueueWaveUntilFrame = 0;
         this.rebelsBossQueueDebugText = "";
         this.nextMagikillWardMessageFrame = 0;
         this.magikillWardMessageHideFrame = 0;
         this.magikillWardMessageActive = false;
         this.magikillWardMessage = null;
         this.nextMedusaLookAtMeMessageFrame = 0;
         this.medusaLookAtMeMessageHideFrame = 0;
         this.medusaLookAtMeMessageActive = false;
         this.medusaLookAtMeMessage = null;
         this.debugAbilityToastText = "";
         this.debugAbilityToastUntilFrame = 0;
         game.soundManager.playSoundInBackground(this.getCampaignBackgroundMusic());
      }

      private function getCampaignBackgroundMusic() : String
      {
         var title:String = String(this.main.campaign.getCurrentLevel().title);
         switch(title)
         {
            case "Tutorial":
            case "Silent Assassins: Ninjas Declare War":
            case "Rebels United":
            case "Shadow of the moon: Eclipsors Attack.":
            case "Medusa and the Full Chaos Empire: Final battle":
               return "battleOfTheShadowElves";
            case "Blot out the sun: Archidons Declare War":
            case "Magic in the Air: Wizards and monks Declare War ":
            case "The Night is Dark: Juggerknights Attack":
            case " 4 legged Fury: Crawlers Attack":
            case "Medusa's Gates: The Chaos Capital is in sight. ":
               return "enteringTheStronghold";
            case "Massive Battle":
            case "Explosive War: Bombers Attack":
            case "Undead War: Deadly Deads Attack":
            case "Bone Pile: Marrowkai summon war":
               return "chaosInGame";
            default:
               if(Team.getIdFromRaceName(this.main.campaign.getCurrentLevel().oponent.race) == Team.T_GOOD)
               {
                  return "orderInGame";
               }
               return "chaosInGame";
         }
      }
      
      override public function update(evt:Event, timeDiff:Number) : void
      {
         this.handleDebugHotkeys();
         this.tryTriggerCampaignReinforcements();
         this.processDelayedLevelPrewarm();
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
         this.updateMagikillWardMessage();
         this.updateMedusaLookAtMeMessage();
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
         this.hasTriggeredCampaignReinforcements = false;
         this.enemyReinforcementShieldUntilFrame = 0;
         this.delayedLevelPrewarmQueue = null;
         this.nextLevelPrewarmFrame = 0;
         this.debugForceEnemyAttackFrames = 0;
         this.rebelsBossQueueActiveTypes = null;
         this.rebelsBossQueueRecentWaves = null;
         this.rebelsBossQueueWaveUntilFrame = 0;
         this.rebelsBossQueueDebugText = "";
         this.nextMagikillWardMessageFrame = 0;
         this.magikillWardMessageHideFrame = 0;
         this.magikillWardMessageActive = false;
         this.removeMagikillWardMessage();
         this.nextMedusaLookAtMeMessageFrame = 0;
         this.medusaLookAtMeMessageHideFrame = 0;
         this.medusaLookAtMeMessageActive = false;
         this.removeMedusaLookAtMeMessage();
         this.removeDebugOverlay();
         super.cleanUp();
      }

      public function showDebugBossAbility(message:String) : void
      {
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
         if(game == null || game.frame < this.nextMagikillWardMessageFrame)
         {
            return;
         }
         this.ensureMagikillWardMessage();
         this.magikillWardMessage.visible = true;
         this.magikillWardMessageActive = true;
         this.magikillWardMessageHideFrame = game.frame + MAGIKILL_WARD_MESSAGE_DURATION_FRAMES;
         this.nextMagikillWardMessageFrame = game.frame + MAGIKILL_WARD_MESSAGE_COOLDOWN_FRAMES;
      }

      private function ensureMagikillWardMessage() : void
      {
         if(this.magikillWardMessage == null)
         {
            this.magikillWardMessage = new inGameMessageBoxMc();
            this.magikillWardMessage.x = game.stage.stageWidth / 2;
            this.magikillWardMessage.y = game.stage.stageHeight / 4 - 75;
            this.magikillWardMessage.scaleX *= 1.3;
            this.magikillWardMessage.scaleY *= 1.3;
            this.magikillWardMessage.text.text = MAGIKILL_WARD_MESSAGE;
            this.magikillWardMessage.step.text = "";
            this.magikillWardMessage.tick.visible = false;
            this.magikillWardMessage.visible = false;
         }
         if(!contains(this.magikillWardMessage))
         {
            addChild(this.magikillWardMessage);
         }
      }

      private function updateMagikillWardMessage() : void
      {
         if(!this.magikillWardMessageActive || game == null || game.frame < this.magikillWardMessageHideFrame)
         {
            return;
         }
         this.magikillWardMessageActive = false;
         if(this.magikillWardMessage != null)
         {
            this.magikillWardMessage.visible = false;
         }
      }

      private function removeMagikillWardMessage() : void
      {
         if(this.magikillWardMessage != null && contains(this.magikillWardMessage))
         {
            removeChild(this.magikillWardMessage);
         }
         this.magikillWardMessage = null;
      }

      public function showMedusaLookAtMeMessage() : void
      {
         if(game == null || game.frame < this.nextMedusaLookAtMeMessageFrame)
         {
            return;
         }
         this.ensureMedusaLookAtMeMessage();
         this.medusaLookAtMeMessage.visible = true;
         this.medusaLookAtMeMessageActive = true;
         this.medusaLookAtMeMessageHideFrame = game.frame + MEDUSA_LOOK_AT_ME_MESSAGE_DURATION_FRAMES;
         this.nextMedusaLookAtMeMessageFrame = game.frame + MEDUSA_LOOK_AT_ME_MESSAGE_COOLDOWN_FRAMES;
      }

      private function ensureMedusaLookAtMeMessage() : void
      {
         if(this.medusaLookAtMeMessage == null)
         {
            this.medusaLookAtMeMessage = new inGameMessageBoxMc();
            this.medusaLookAtMeMessage.x = game.stage.stageWidth / 2;
            this.medusaLookAtMeMessage.y = game.stage.stageHeight / 4 - 75;
            this.medusaLookAtMeMessage.scaleX *= 1.3;
            this.medusaLookAtMeMessage.scaleY *= 1.3;
            this.medusaLookAtMeMessage.text.text = MEDUSA_LOOK_AT_ME_MESSAGE;
            this.medusaLookAtMeMessage.step.text = "";
            this.medusaLookAtMeMessage.tick.visible = false;
            this.medusaLookAtMeMessage.visible = false;
         }
         if(!contains(this.medusaLookAtMeMessage))
         {
            addChild(this.medusaLookAtMeMessage);
         }
      }

      private function updateMedusaLookAtMeMessage() : void
      {
         if(!this.medusaLookAtMeMessageActive || game == null || game.frame < this.medusaLookAtMeMessageHideFrame)
         {
            return;
         }
         this.medusaLookAtMeMessageActive = false;
         if(this.medusaLookAtMeMessage != null)
         {
            this.medusaLookAtMeMessage.visible = false;
         }
      }

      private function removeMedusaLookAtMeMessage() : void
      {
         if(this.medusaLookAtMeMessage != null && contains(this.medusaLookAtMeMessage))
         {
            removeChild(this.medusaLookAtMeMessage);
         }
         this.medusaLookAtMeMessage = null;
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
         if(level.title == "Rebels United")
         {
            return level.points * 3;
         }
         if(level.title == "The Night is Dark: Juggerknights Attack")
         {
            return level.points + 1;
         }
         if(level.title == "Shadow of the moon: Eclipsors Attack." || level.title == "Bone Pile: Marrowkai summon war" || level.title == "Medusa's Gates: The Chaos Capital is in sight. ")
         {
            return level.points + 1;
         }
         if(Team.getIdFromRaceName(level.oponent.race) == Team.T_GOOD)
         {
            return level.points * 2;
         }
         return level.points;
      }

      private function initializeLevelPrewarm(level:Level) : void
      {
         var immediateUnits:Array = [];
         var delayedUnits:Array = [];
         if(level == null || game == null || game.unitFactory == null)
         {
            this.delayedLevelPrewarmQueue = [];
            return;
         }
         this.addPrewarmUnitsFromSource(immediateUnits,level.player.startingUnits);
         this.addPrewarmUnitsFromSource(immediateUnits,level.oponent.startingUnits);
         this.addPrewarmUnitsFromSource(immediateUnits,this.getImmediatePrewarmUnitsForLevel(level.title));
         this.addPrewarmUnitsFromSource(delayedUnits,this.getDelayedPrewarmUnitsForLevel(level.title));
         this.removePrewarmDuplicatesAgainst(delayedUnits,immediateUnits);
         this.runImmediateLevelPrewarm(immediateUnits);
         this.delayedLevelPrewarmQueue = delayedUnits;
      }

      private function runImmediateLevelPrewarm(unitTypes:Array) : void
      {
         var unitType:int = 0;
         if(unitTypes == null)
         {
            return;
         }
         for each(unitType in unitTypes)
         {
            this.prewarmUnitType(unitType);
         }
      }

      private function processDelayedLevelPrewarm() : void
      {
         var nextType:int = 0;
         if(this.delayedLevelPrewarmQueue == null || this.delayedLevelPrewarmQueue.length == 0 || game == null)
         {
            return;
         }
         if(game.frame < this.nextLevelPrewarmFrame)
         {
            return;
         }
         nextType = int(this.delayedLevelPrewarmQueue.shift());
         this.prewarmUnitType(nextType);
         this.nextLevelPrewarmFrame = game.frame + PREWARM_INTERVAL_FRAMES;
      }

      private function prewarmUnitType(unitType:int) : void
      {
         var warmUnit:Unit = null;
         if(game == null || game.unitFactory == null || unitType <= 0)
         {
            return;
         }
         warmUnit = game.unitFactory.getUnit(unitType);
         if(warmUnit == null)
         {
            return;
         }
         if(warmUnit.mc != null)
         {
            warmUnit.mc.gotoAndStop(1);
         }
         game.unitFactory.returnUnit(unitType,warmUnit);
      }

      private function addPrewarmUnitsFromSource(dest:Array, source:*) : void
      {
         var nested:* = undefined;
         if(dest == null || source == null)
         {
            return;
         }
         if(source is Array)
         {
            for each(nested in source)
            {
               this.addPrewarmUnitsFromSource(dest,nested);
            }
            return;
         }
         this.addPrewarmUnitType(dest,int(source));
      }

      private function addPrewarmUnitType(dest:Array, unitType:int) : void
      {
         if(dest == null || !this.shouldPrewarmUnitType(unitType) || dest.indexOf(unitType) != -1)
         {
            return;
         }
         dest.push(unitType);
      }

      private function removePrewarmDuplicatesAgainst(dest:Array, existing:Array) : void
      {
         var i:int = 0;
         if(dest == null || existing == null)
         {
            return;
         }
         i = dest.length - 1;
         while(i >= 0)
         {
            if(existing.indexOf(dest[i]) != -1)
            {
               dest.splice(i,1);
            }
            i--;
         }
      }

      private function shouldPrewarmUnitType(unitType:int) : Boolean
      {
         switch(unitType)
         {
            case Unit.U_SPEARTON:
            case Unit.U_ARCHER:
            case Unit.U_NINJA:
            case Unit.U_MAGIKILL:
            case Unit.U_MONK:
            case Unit.U_BOMBER:
            case Unit.U_GIANT:
            case Unit.U_KNIGHT:
            case Unit.U_DEAD:
            case Unit.U_CAT:
            case Unit.U_WINGIDON:
            case Unit.U_SKELATOR:
            case Unit.U_MEDUSA:
            case Unit.U_ENSLAVED_GIANT:
               return true;
            default:
               return false;
         }
      }

      private function getImmediatePrewarmUnitsForLevel(title:String) : Array
      {
         switch(title)
         {
            case "Tutorial":
               return [Unit.U_SPEARTON,Unit.U_ARCHER];
            case "Blot out the sun: Archidons Declare War":
               return [Unit.U_ARCHER];
            case "Silent Assassins: Ninjas Declare War":
               return [Unit.U_NINJA];
            case "Magic in the Air: Wizards and monks Declare War ":
               return [Unit.U_MAGIKILL,Unit.U_MONK];
            case LEVEL_TITLE_REBELS_UNITED:
               return [Unit.U_SPEARTON,Unit.U_ARCHER,Unit.U_NINJA,Unit.U_MAGIKILL,Unit.U_MONK];
            case "Explosive War: Bombers Attack":
               return [Unit.U_BOMBER,Unit.U_GIANT];
            case "The Night is Dark: Juggerknights Attack":
            case "Undead War: Deadly Deads Attack":
               return [Unit.U_KNIGHT,Unit.U_DEAD];
            case " 4 legged Fury: Crawlers Attack":
               return [Unit.U_CAT,Unit.U_BOMBER];
            case "Shadow of the moon: Eclipsors Attack.":
               return [Unit.U_WINGIDON,Unit.U_KNIGHT];
            case "Bone Pile: Marrowkai summon war":
               return [Unit.U_SKELATOR,Unit.U_DEAD,Unit.U_KNIGHT];
            case LEVEL_TITLE_MEDUSA_GATES:
               return [Unit.U_MEDUSA,Unit.U_KNIGHT,Unit.U_DEAD,Unit.U_SKELATOR,Unit.U_WINGIDON,Unit.U_GIANT,Unit.U_CAT,Unit.U_BOMBER];
            default:
               return [];
         }
      }

      private function getDelayedPrewarmUnitsForLevel(title:String) : Array
      {
         var unitTypes:Array = [];
         this.addPrewarmUnitsFromSource(unitTypes,this.getCampaignReinforcementsForLevel(title,Campaign.D_INSANE));
         switch(title)
         {
            case LEVEL_TITLE_REBELS_UNITED:
               this.addPrewarmUnitsFromSource(unitTypes,[Unit.U_SPEARTON,Unit.U_ARCHER,Unit.U_NINJA,Unit.U_MAGIKILL,Unit.U_MONK]);
               break;
            case "Explosive War: Bombers Attack":
               this.addPrewarmUnitsFromSource(unitTypes,[Unit.U_BOMBER,Unit.U_GIANT]);
               break;
            case LEVEL_TITLE_MEDUSA_GATES:
               this.addPrewarmUnitsFromSource(unitTypes,[Unit.U_MEDUSA,Unit.U_KNIGHT,Unit.U_DEAD,Unit.U_SKELATOR,Unit.U_WINGIDON,Unit.U_GIANT,Unit.U_CAT,Unit.U_BOMBER,Unit.U_ENSLAVED_GIANT]);
         }
         return unitTypes;
      }

      private function tryTriggerCampaignReinforcements() : void
      {
         var difficulty:int = 0;
         var level:Level = null;
         var reinforcements:Array = null;
         if(this.hasTriggeredCampaignReinforcements || main == null || main.campaign == null || game == null || game.teamB == null || game.teamB.statue == null)
         {
            return;
         }
         level = main.campaign.getCurrentLevel();
         if(level == null || game.teamB.statue.health > level.oponent.statueHealth * 0.5)
         {
            return;
         }
         difficulty = main.campaign.difficultyLevel;
         reinforcements = this.getCampaignReinforcementsForLevel(level.title,difficulty);
         this.hasTriggeredCampaignReinforcements = true;
         if(reinforcements == null || reinforcements.length == 0)
         {
            return;
         }
         this.spawnEnemyReinforcements(reinforcements);
      }

      private function getCampaignReinforcementsForLevel(title:String, difficulty:int) : Array
      {
         switch(title)
         {
            case "Tutorial":
               if(difficulty == Campaign.D_NORMAL)
               {
                  return [Unit.U_SPEARTON];
               }
               if(difficulty == Campaign.D_HARD)
               {
                  return [Unit.U_SPEARTON,Unit.U_SPEARTON];
               }
               return [Unit.U_SPEARTON,Unit.U_SPEARTON,Unit.U_SPEARTON];
            case "Blot out the sun: Archidons Declare War":
               if(difficulty == Campaign.D_NORMAL)
               {
                  return [Unit.U_ARCHER,Unit.U_ARCHER,Unit.U_SWORDWRATH];
               }
               if(difficulty == Campaign.D_HARD)
               {
                  return [Unit.U_ARCHER,Unit.U_ARCHER,Unit.U_ARCHER,Unit.U_SWORDWRATH,Unit.U_SWORDWRATH];
               }
               return [Unit.U_ARCHER,Unit.U_ARCHER,Unit.U_ARCHER,Unit.U_ARCHER,Unit.U_SWORDWRATH,Unit.U_SWORDWRATH];
            case "Silent Assassins: Ninjas Declare War":
               if(difficulty == Campaign.D_NORMAL)
               {
                  return [Unit.U_NINJA,Unit.U_SWORDWRATH];
               }
               if(difficulty == Campaign.D_HARD)
               {
                  return [Unit.U_NINJA,Unit.U_NINJA,Unit.U_SWORDWRATH,Unit.U_SWORDWRATH];
               }
               return [Unit.U_NINJA,Unit.U_NINJA,Unit.U_NINJA,Unit.U_SWORDWRATH,Unit.U_SWORDWRATH];
            case "Magic in the Air: Wizards and monks Declare War ":
               if(difficulty == Campaign.D_NORMAL)
               {
                  return [Unit.U_MAGIKILL,Unit.U_MONK,Unit.U_SWORDWRATH];
               }
               if(difficulty == Campaign.D_HARD)
               {
                  return [Unit.U_MAGIKILL,Unit.U_MONK,Unit.U_MONK,Unit.U_SWORDWRATH];
               }
               return [Unit.U_MAGIKILL,Unit.U_MONK,Unit.U_MONK,Unit.U_SWORDWRATH,Unit.U_SWORDWRATH];
            case "Rebels United":
               if(difficulty == Campaign.D_NORMAL)
               {
                  return [Unit.U_SPEARTON,Unit.U_ARCHER,Unit.U_NINJA,Unit.U_MAGIKILL,Unit.U_MONK,Unit.U_SPEARTON,Unit.U_ARCHER];
               }
               if(difficulty == Campaign.D_HARD)
               {
                  return [Unit.U_SPEARTON,Unit.U_ARCHER,Unit.U_NINJA,Unit.U_MAGIKILL,Unit.U_MONK,Unit.U_SPEARTON,Unit.U_SPEARTON,Unit.U_ARCHER,Unit.U_ARCHER,Unit.U_NINJA];
               }
               return [Unit.U_SPEARTON,Unit.U_SPEARTON,Unit.U_SPEARTON,Unit.U_SPEARTON,Unit.U_SPEARTON,Unit.U_ARCHER,Unit.U_ARCHER,Unit.U_ARCHER,Unit.U_ARCHER,Unit.U_ARCHER,Unit.U_NINJA,Unit.U_NINJA,Unit.U_NINJA,Unit.U_MAGIKILL,Unit.U_MONK];
            case "Explosive War: Bombers Attack":
               if(difficulty == Campaign.D_NORMAL)
               {
                  return [Unit.U_BOMBER,Unit.U_GIANT];
               }
               if(difficulty == Campaign.D_HARD)
               {
                  return [Unit.U_BOMBER,Unit.U_BOMBER,Unit.U_GIANT];
               }
               return [Unit.U_BOMBER,Unit.U_BOMBER,Unit.U_BOMBER,Unit.U_GIANT];
            case "The Night is Dark: Juggerknights Attack":
               if(difficulty == Campaign.D_NORMAL)
               {
                  return [Unit.U_KNIGHT,Unit.U_KNIGHT,Unit.U_DEAD];
               }
               if(difficulty == Campaign.D_HARD)
               {
                  return [Unit.U_KNIGHT,Unit.U_KNIGHT,Unit.U_KNIGHT,Unit.U_DEAD];
               }
               return [Unit.U_KNIGHT,Unit.U_KNIGHT,Unit.U_KNIGHT,Unit.U_DEAD,Unit.U_DEAD];
            case "Undead War: Deadly Deads Attack":
               if(difficulty == Campaign.D_NORMAL)
               {
                  return [Unit.U_DEAD,Unit.U_DEAD,Unit.U_KNIGHT];
               }
               if(difficulty == Campaign.D_HARD)
               {
                  return [Unit.U_DEAD,Unit.U_DEAD,Unit.U_DEAD,Unit.U_KNIGHT,Unit.U_KNIGHT];
               }
               return [Unit.U_DEAD,Unit.U_DEAD,Unit.U_DEAD,Unit.U_DEAD,Unit.U_KNIGHT,Unit.U_KNIGHT];
            case " 4 legged Fury: Crawlers Attack":
               if(difficulty == Campaign.D_NORMAL)
               {
                  return [Unit.U_CAT,Unit.U_CAT,Unit.U_CAT,Unit.U_BOMBER];
               }
               if(difficulty == Campaign.D_HARD)
               {
                  return [Unit.U_CAT,Unit.U_CAT,Unit.U_CAT,Unit.U_CAT,Unit.U_BOMBER,Unit.U_BOMBER];
               }
               return [Unit.U_CAT,Unit.U_CAT,Unit.U_CAT,Unit.U_CAT,Unit.U_CAT,Unit.U_CAT,Unit.U_BOMBER,Unit.U_BOMBER];
            case "Shadow of the moon: Eclipsors Attack.":
               if(difficulty == Campaign.D_NORMAL)
               {
                  return [Unit.U_WINGIDON,Unit.U_WINGIDON,Unit.U_KNIGHT];
               }
               if(difficulty == Campaign.D_HARD)
               {
                  return [Unit.U_WINGIDON,Unit.U_WINGIDON,Unit.U_WINGIDON,Unit.U_KNIGHT];
               }
               return [Unit.U_WINGIDON,Unit.U_WINGIDON,Unit.U_WINGIDON,Unit.U_KNIGHT,Unit.U_KNIGHT];
            case "Bone Pile: Marrowkai summon war":
               if(difficulty == Campaign.D_NORMAL)
               {
                  return [Unit.U_SKELATOR,Unit.U_DEAD,Unit.U_KNIGHT];
               }
               if(difficulty == Campaign.D_HARD)
               {
                  return [Unit.U_SKELATOR,Unit.U_DEAD,Unit.U_DEAD,Unit.U_KNIGHT];
               }
               return [Unit.U_SKELATOR,Unit.U_DEAD,Unit.U_DEAD,Unit.U_DEAD,Unit.U_KNIGHT];
            case "Medusa's Gates: The Chaos Capital is in sight. ":
               if(difficulty == Campaign.D_NORMAL)
               {
                  return [Unit.U_MEDUSA,Unit.U_KNIGHT,Unit.U_WINGIDON,Unit.U_SKELATOR];
               }
               if(difficulty == Campaign.D_HARD)
               {
                  return [Unit.U_MEDUSA,Unit.U_KNIGHT,Unit.U_KNIGHT,Unit.U_WINGIDON,Unit.U_WINGIDON,Unit.U_SKELATOR];
               }
               return [Unit.U_MEDUSA,Unit.U_KNIGHT,Unit.U_KNIGHT,Unit.U_WINGIDON,Unit.U_WINGIDON,Unit.U_WINGIDON,Unit.U_SKELATOR];
            default:
               return null;
         }
      }

      private function spawnEnemyReinforcements(unitTypes:Array) : void
      {
         var unitType:int = 0;
         var newUnit:Unit = null;
         var attackMoveCommand:AttackMoveCommand = null;
         var spawnWestwindBosses:Boolean = false;
         var spawnFactionBosses:Boolean = false;
         var spawnedBossTypeCounts:Object = null;
         var i:int = 0;
         var row:int = 0;
         var column:int = 0;
         var rowCount:int = 0;
         var totalRows:int = 0;
         var xPos:Number = NaN;
         var yPos:Number = NaN;
         var currentLevelTitle:String = null;
         if(main != null && main.campaign != null && main.campaign.getCurrentLevel() != null)
         {
            currentLevelTitle = main.campaign.getCurrentLevel().title;
            spawnWestwindBosses = currentLevelTitle == "Rebels United";
            spawnFactionBosses = this.isFactionBossLevel(currentLevelTitle);
         }
         if(spawnWestwindBosses)
         {
            this.grantWestwindBossResearch();
         }
         else if(spawnFactionBosses)
         {
            this.grantFactionBossResearch(currentLevelTitle);
         }
         spawnedBossTypeCounts = {};
         var reinforcementUnits:Array = null;
         if(spawnWestwindBosses)
         {
            reinforcementUnits = unitTypes.concat([game.teamB.getMinerType(),game.teamB.getMinerType(),game.teamB.getMinerType(),game.teamB.getMinerType(),game.teamB.getMinerType()]);
         }
         else
         {
            reinforcementUnits = unitTypes.concat([game.teamB.getMinerType(),game.teamB.getMinerType()]);
         }
         unitTypes = reinforcementUnits;
         totalRows = Math.ceil(unitTypes.length / 4);
         this.activateEnemyReinforcementShield();
         this.playReinforcementSpawnEffects();
         for(i = 0; i < unitTypes.length; i++)
         {
            unitType = unitTypes[i];
            if(game.teamB.unitsAvailable != null && !(unitType in game.teamB.unitsAvailable))
            {
               game.teamB.unitsAvailable[unitType] = 1;
            }
            newUnit = game.unitFactory.getUnit(unitType);
            game.teamB.spawn(newUnit,game);
            if(spawnWestwindBosses)
            {
               if(!(unitType in spawnedBossTypeCounts))
               {
                  spawnedBossTypeCounts[unitType] = 0;
               }
               spawnedBossTypeCounts[unitType] += 1;
               if(this.shouldPromoteWestwindBoss(unitType,int(spawnedBossTypeCounts[unitType])))
               {
                  this.configureWestwindBoss(newUnit);
                  newUnit.enableCampaignBossEscape();
               }
            }
            else if(spawnFactionBosses)
            {
               if(!(unitType in spawnedBossTypeCounts))
               {
                  spawnedBossTypeCounts[unitType] = 0;
               }
               spawnedBossTypeCounts[unitType] += 1;
               if(this.shouldPromoteFactionBoss(currentLevelTitle,unitType,int(spawnedBossTypeCounts[unitType])))
               {
                  this.configureFactionBoss(newUnit,currentLevelTitle);
               }
            }
            row = int(i / 4);
            column = i % 4;
            rowCount = Math.min(4,unitTypes.length - row * 4);
            xPos = game.teamB.homeX + game.teamB.direction * (120 + row * 90);
            yPos = Math.max(80,Math.min(game.map.height - 80,game.map.height / 2 + (column - (rowCount - 1) / 2) * 85 + (row - (totalRows - 1) / 2) * 35));
            newUnit.x = newUnit.px = xPos;
            newUnit.y = newUnit.py = yPos;
            game.teamB.population += newUnit.population;
            attackMoveCommand = new AttackMoveCommand(game);
            attackMoveCommand.type = UnitCommand.ATTACK_MOVE;
            attackMoveCommand.goalX = team.statue.px;
            attackMoveCommand.goalY = game.map.height / 2;
            attackMoveCommand.realX = team.statue.px;
            attackMoveCommand.realY = game.map.height / 2;
            newUnit.ai.setCommand(game,attackMoveCommand);
         }
      }

      private function activateEnemyReinforcementShield() : void
      {
         var shieldFrames:int = this.getEnemyReinforcementShieldFrames();
         if(game == null || game.teamB == null || game.teamB.statue == null || shieldFrames <= 0)
         {
            return;
         }
         this.enemyReinforcementShieldUntilFrame = game.frame + shieldFrames;
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
         return game != null && game.teamB != null && game.teamB.statue != null && game.frame < this.enemyReinforcementShieldUntilFrame;
      }

      private function shouldPromoteWestwindBoss(unitType:int, spawnedCount:int) : Boolean
      {
         switch(unitType)
         {
            case Unit.U_SPEARTON:
            case Unit.U_ARCHER:
            case Unit.U_NINJA:
            case Unit.U_MAGIKILL:
            case Unit.U_MONK:
               return spawnedCount == 1;
            default:
               return false;
         }
      }

      private function configureWestwindBoss(unit:Unit) : void
      {
         if(unit == null)
         {
            return;
         }
         if(unit is Spearton)
         {
            Spearton(unit).makeBoss();
            return;
         }
         if(unit is Archer)
         {
            Archer(unit).makeBoss();
         }
         else if(unit is Ninja)
         {
            Ninja(unit).makeBoss();
         }
         else if(unit is Magikill)
         {
            Magikill(unit).makeBoss();
         }
         else if(unit is Monk)
         {
            Monk(unit).makeBoss();
         }
         else if(unit is Knight)
         {
            Knight(unit).makeBoss();
         }
         else if(unit is Wingidon)
         {
            Wingidon(unit).makeBoss();
         }
         else if(unit is Skelator)
         {
            Skelator(unit).makeBoss();
         }
         unit.isBossMovementLocked = false;
      }

      private function isFactionBossLevel(title:String) : Boolean
      {
         return title == "Tutorial" || title == "Blot out the sun: Archidons Declare War" || title == "Silent Assassins: Ninjas Declare War" || title == "Magic in the Air: Wizards and monks Declare War " || title == "The Night is Dark: Juggerknights Attack" || title == "Shadow of the moon: Eclipsors Attack." || title == "Bone Pile: Marrowkai summon war" || title == "Medusa's Gates: The Chaos Capital is in sight. ";
      }

      private function shouldPromoteFactionBoss(title:String, unitType:int, spawnedCount:int) : Boolean
      {
         switch(title)
         {
            case "Tutorial":
               return unitType == Unit.U_SPEARTON && spawnedCount == 1;
            case "Blot out the sun: Archidons Declare War":
               return unitType == Unit.U_ARCHER && spawnedCount == 1;
            case "Silent Assassins: Ninjas Declare War":
               return unitType == Unit.U_NINJA && spawnedCount == 1;
            case "Magic in the Air: Wizards and monks Declare War ":
               return (unitType == Unit.U_MAGIKILL || unitType == Unit.U_MONK) && spawnedCount == 1;
            case "The Night is Dark: Juggerknights Attack":
               return unitType == Unit.U_KNIGHT && spawnedCount == 1;
            case "Shadow of the moon: Eclipsors Attack.":
               return unitType == Unit.U_WINGIDON && spawnedCount == 1;
            case "Bone Pile: Marrowkai summon war":
               return unitType == Unit.U_SKELATOR && spawnedCount == 1;
            case "Medusa's Gates: The Chaos Capital is in sight. ":
               return (unitType == Unit.U_KNIGHT || unitType == Unit.U_WINGIDON || unitType == Unit.U_SKELATOR) && spawnedCount == 1;
            default:
               return false;
         }
      }

      private function configureFactionBoss(unit:Unit, title:String = "") : void
      {
         this.configureWestwindBoss(unit);
         if(unit is Skelator)
         {
            Skelator(unit).makeBoss(title == "Medusa's Gates: The Chaos Capital is in sight. ");
         }
         if(unit != null && title != "Medusa's Gates: The Chaos Capital is in sight. ")
         {
            unit.enableCampaignBossEscape();
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
         if(game == null || game.teamB == null || game.teamB.tech == null)
         {
            return;
         }
         game.teamB.tech.isResearchedMap[Tech.ARCHIDON_FIRE] = true;
         game.teamB.tech.isResearchedMap[Tech.BLOCK] = true;
         game.teamB.tech.isResearchedMap[Tech.SHIELD_BASH] = true;
         game.teamB.tech.isResearchedMap[Tech.CLOAK] = true;
         game.teamB.tech.isResearchedMap[Tech.CLOAK_II] = true;
         game.teamB.tech.isResearchedMap[Tech.MAGIKILL_WALL] = true;
         game.teamB.tech.isResearchedMap[Tech.MAGIKILL_POISON] = true;
         game.teamB.tech.isResearchedMap[Tech.MONK_CURE] = true;
         game.teamB.tech.isResearchedMap[Tech.CASTLE_ARCHER_1] = true;
         game.teamB.tech.isResearchedMap[Tech.CASTLE_ARCHER_2] = true;
         game.teamB.tech.isResearchedMap[Tech.WINGIDON_SPEED] = true;
      }

      private function grantFactionBossResearch(title:String) : void
      {
         if(game == null || game.teamB == null || game.teamB.tech == null)
         {
            return;
         }
         switch(title)
         {
            case "Tutorial":
               game.teamB.tech.isResearchedMap[Tech.BLOCK] = true;
               game.teamB.tech.isResearchedMap[Tech.SHIELD_BASH] = true;
               break;
            case "Blot out the sun: Archidons Declare War":
               game.teamB.tech.isResearchedMap[Tech.ARCHIDON_FIRE] = true;
               break;
            case "Silent Assassins: Ninjas Declare War":
               game.teamB.tech.isResearchedMap[Tech.CLOAK] = true;
               game.teamB.tech.isResearchedMap[Tech.CLOAK_II] = true;
               break;
            case "Magic in the Air: Wizards and monks Declare War ":
               game.teamB.tech.isResearchedMap[Tech.MAGIKILL_WALL] = true;
               game.teamB.tech.isResearchedMap[Tech.MAGIKILL_POISON] = true;
               game.teamB.tech.isResearchedMap[Tech.MONK_CURE] = true;
               break;
            case "Shadow of the moon: Eclipsors Attack.":
               game.teamB.tech.isResearchedMap[Tech.WINGIDON_SPEED] = true;
               break;
            case "Medusa's Gates: The Chaos Capital is in sight. ":
               game.teamB.tech.isResearchedMap[Tech.WINGIDON_SPEED] = true;
               game.teamB.tech.isResearchedMap[Tech.SKELETON_FIST_ATTACK] = true;
               break;
            case "Bone Pile: Marrowkai summon war":
               game.teamB.tech.isResearchedMap[Tech.SKELETON_FIST_ATTACK] = true;
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

      private function tryDebugSpawnBosses() : void
      {
         if(userInterface == null || userInterface.keyBoardState == null || !this.debugModeEnabled || !userInterface.keyBoardState.isShift)
         {
            return;
         }
         if(this.debugSpawnSet == DEBUG_SET_ORDER)
         {
            this.tryDebugSpawnOrderSet();
         }
         else
         {
            this.tryDebugSpawnChaosSet();
         }
      }

      private function tryDebugSpawnOrderSet() : void
      {
         if(userInterface.keyBoardState.isPressed(Keyboard.F1))
         {
            this.spawnDebugBoss(Unit.U_SPEARTON);
         }
         else if(userInterface.keyBoardState.isPressed(Keyboard.F2))
         {
            this.spawnDebugBoss(Unit.U_ARCHER);
         }
         else if(userInterface.keyBoardState.isPressed(Keyboard.F3))
         {
            this.spawnDebugBoss(Unit.U_NINJA);
         }
         else if(userInterface.keyBoardState.isPressed(Keyboard.F4))
         {
            this.spawnDebugBoss(Unit.U_MAGIKILL);
         }
         else if(userInterface.keyBoardState.isPressed(Keyboard.F5))
         {
            this.spawnDebugBoss(Unit.U_MONK);
         }
         else if(userInterface.keyBoardState.isPressed(49))
         {
            this.spawnDebugAlliedUnit(Unit.U_SPEARTON,1);
         }
         else if(userInterface.keyBoardState.isPressed(50))
         {
            this.spawnDebugAlliedUnit(Unit.U_ARCHER,2);
         }
         else if(userInterface.keyBoardState.isPressed(51))
         {
            this.spawnDebugAlliedGroupAtBase([Unit.U_MAGIKILL,Unit.U_MONK]);
         }
         else if(userInterface.keyBoardState.isPressed(52))
         {
            this.spawnDebugAlliedUnit(Unit.U_ENSLAVED_GIANT,1);
         }
         else if(userInterface.keyBoardState.isPressed(53))
         {
            this.spawnDebugAlliedUnit(Unit.U_NINJA,1);
         }
         else if(userInterface.keyBoardState.isPressed(54))
         {
            this.spawnDebugEnemyAtBase(Unit.U_SPEARTON,1);
         }
         else if(userInterface.keyBoardState.isPressed(55))
         {
            this.spawnDebugEnemyAtBase(Unit.U_ARCHER,2);
         }
         else if(userInterface.keyBoardState.isPressed(56))
         {
            this.spawnDebugShadowrathAtEnemyBase();
         }
         else if(userInterface.keyBoardState.isPressed(57))
         {
            this.spawnDebugEnemyGroupAtBase([Unit.U_MAGIKILL,Unit.U_MONK]);
         }
      }

      private function tryDebugSpawnChaosSet() : void
      {
         if(userInterface.keyBoardState.isPressed(Keyboard.F1))
         {
            this.spawnDebugKnightBoss();
         }
         else if(userInterface.keyBoardState.isPressed(Keyboard.F2))
         {
            this.spawnDebugBoss(Unit.U_WINGIDON);
         }
         else if(userInterface.keyBoardState.isPressed(Keyboard.F3))
         {
            this.spawnDebugBoss(Unit.U_SKELATOR);
         }
         else if(userInterface.keyBoardState.isPressed(Keyboard.F4))
         {
            this.spawnDebugThumbnailBossLineup();
         }
         else if(userInterface.keyBoardState.isPressed(49))
         {
            this.spawnDebugEnemyAtBase(Unit.U_KNIGHT,1);
         }
         else if(userInterface.keyBoardState.isPressed(50))
         {
            this.spawnDebugEnemyAtBase(Unit.U_DEAD,1);
         }
         else if(userInterface.keyBoardState.isPressed(51))
         {
            this.spawnDebugEnemyAtBase(Unit.U_WINGIDON,1);
         }
         else if(userInterface.keyBoardState.isPressed(52))
         {
            this.spawnDebugEnemyAtBase(Unit.U_SKELATOR,1);
         }
         else if(userInterface.keyBoardState.isPressed(53))
         {
            this.spawnDebugEnemyAtBase(Unit.U_MEDUSA,1);
         }
         else if(userInterface.keyBoardState.isPressed(54))
         {
            this.damageDebugEnemyStatue(250);
         }
      }

      private function spawnDebugKnightBoss() : void
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
         game.projectileManager.initTowerSpawn(spawnX,spawnY,game.teamB,0.7);
         game.projectileManager.initSpawnDrip(spawnX,spawnY,game.teamB);
         game.soundManager.playSoundFullVolume("Rage1");
      }

      private function damageDebugEnemyStatue(amount:Number) : void
      {
         if(game == null || game.teamB == null || game.teamB.statue == null)
         {
            return;
         }
         game.teamB.statue.health = Math.max(1,game.teamB.statue.health - amount);
         this.showDebugBossAbility("DEBUG: Enemy statue -" + amount + " HP");
      }

      private function spawnDebugAlliedUnit(unitType:int, count:int) : void
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

      private function spawnDebugAlliedGroupAtBase(unitTypes:Array) : void
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

      private function spawnDebugBoss(unitType:int) : void
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
            }
         }
      }

      private function spawnDebugThumbnailBossLineup() : void
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
      }

      private function spawnDebugEnemyAtBase(unitType:int, count:int) : void
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
         }
      }

      private function spawnDebugEnemyGroupAtBase(unitTypes:Array) : void
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
         }
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

      private function killEnemyUnitsAndLockTraining() : void
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
         if(userInterface == null || userInterface.keyBoardState == null || !userInterface.keyBoardState.isShift)
         {
            return;
         }
         if(userInterface.keyBoardState.isPressed(Keyboard.F9))
         {
            this.debugModeEnabled = !this.debugModeEnabled;
            if(!this.debugModeEnabled)
            {
               this.removeDebugOverlay();
            }
            else
            {
               this.showDebugEnabledLabel();
            }
            return;
         }
         if(this.debugModeEnabled)
         {
            if(userInterface.keyBoardState.isPressed(Keyboard.F8))
            {
               this.toggleDebugFullVision();
               return;
            }
            if(userInterface.keyBoardState.isPressed(Keyboard.F6))
            {
               this.debugSpawnSet = DEBUG_SET_ORDER;
               this.showDebugBossAbility("DEBUG SET: ORDER");
               return;
            }
            if(userInterface.keyBoardState.isPressed(Keyboard.F7))
            {
               this.debugSpawnSet = DEBUG_SET_CHAOS;
               this.showDebugBossAbility("DEBUG SET: CHAOS");
               return;
            }
            if(userInterface.keyBoardState.isPressed(48))
            {
               this.killEnemyUnitsAndLockTraining();
               return;
            }
            this.tryDebugSpawnBosses();
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

      private function showDebugEnabledLabel() : void
      {
         var format:TextFormat = null;
         if(this.debugOverlay != null)
         {
            if(!contains(this.debugOverlay))
            {
               addChild(this.debugOverlay);
            }
            return;
         }
         this.debugOverlay = new TextField();
         format = new TextFormat("_typewriter",12,16776960,true);
         this.debugOverlay.defaultTextFormat = format;
         this.debugOverlay.selectable = false;
         this.debugOverlay.mouseEnabled = false;
         this.debugOverlay.multiline = false;
         this.debugOverlay.wordWrap = false;
         this.debugOverlay.background = true;
         this.debugOverlay.backgroundColor = 0;
         this.debugOverlay.border = true;
         this.debugOverlay.borderColor = 16776960;
         this.debugOverlay.width = 120;
         this.debugOverlay.height = 20;
         this.debugOverlay.x = 8;
         this.debugOverlay.y = 8;
         this.debugOverlay.text = "DEBUG ENABLED";
         addChild(this.debugOverlay);
      }

      private function updateDebugOverlay() : void
      {
         var enemyState:String = null;
         var playerState:String = null;
         if(!this.debugModeEnabled)
         {
            return;
         }
         this.ensureDebugOverlay();
         this.updateDebugAbilityToast();
         enemyState = this.describeAttackState(game != null && game.teamB != null ? game.teamB.currentAttackState : -1);
         playerState = this.describeAttackState(game != null && game.teamA != null ? game.teamA.currentAttackState : -1);
         this.debugOverlay.text = "DEBUG MODE\n" + "set: " + this.getDebugSpawnSetName() + "\n" + "rt fps: " + this.formatNumber(this.debugLastRealtimeFps) + "\n" + "sim fps: " + this.formatNumber(simulation != null ? simulation.fps : 0) + "\n" + "frame ms: " + this.formatNumber(this.debugLastFrameMs) + "\n" + "frame: " + (game != null ? game.frame : 0) + "\n" + "mem MB: " + this.formatNumber(System.totalMemory / 1048576) + "\n" + "player AI: " + playerState + "\n" + "enemy AI: " + enemyState + "\n" + "boss queue: " + (this.rebelsBossQueueDebugText != null && this.rebelsBossQueueDebugText != "" ? this.rebelsBossQueueDebugText : "off") + "\n" + "units P/E: " + this.getUnitCount(game != null ? game.teamA : null) + "/" + this.getUnitCount(game != null ? game.teamB : null) + "\n" + "proj/fx: " + this.getProjectileCount() + "/" + this.getAirEffectCount() + "\n" + "prewarm queue: " + (this.delayedLevelPrewarmQueue != null ? this.delayedLevelPrewarmQueue.length : 0) + "\n" + "ms prewarm: " + this.debugLastPrewarmMs + "\n" + "ms enemy ai: " + this.debugLastEnemyAiMs + "\n" + "ms controller: " + this.debugLastControllerMs + "\n" + "ms core: " + this.debugLastCoreMs + "\n" + "ms total: " + this.debugLastTotalMs;
      }

      private function ensureDebugOverlay() : void
      {
         var format:TextFormat = null;
         if(this.debugOverlay != null)
         {
            if(!contains(this.debugOverlay))
            {
               addChild(this.debugOverlay);
            }
            return;
         }
         this.debugOverlay = new TextField();
         format = new TextFormat("_typewriter",14,16777215);
         this.debugOverlay.defaultTextFormat = format;
         this.debugOverlay.selectable = false;
         this.debugOverlay.mouseEnabled = false;
         this.debugOverlay.multiline = true;
         this.debugOverlay.wordWrap = false;
         this.debugOverlay.background = true;
         this.debugOverlay.backgroundColor = 0;
         this.debugOverlay.border = true;
         this.debugOverlay.borderColor = 16777215;
         this.debugOverlay.width = 270;
         this.debugOverlay.height = 270;
         this.debugOverlay.x = 8;
         this.debugOverlay.y = 8;
         addChild(this.debugOverlay);
      }

      private function updateDebugAbilityToast() : void
      {
         if(game == null || this.debugAbilityToastText == "" || game.frame > this.debugAbilityToastUntilFrame)
         {
            if(this.debugAbilityToast != null && contains(this.debugAbilityToast))
            {
               removeChild(this.debugAbilityToast);
            }
            return;
         }
         this.ensureDebugAbilityToast();
         this.debugAbilityToast.text = this.debugAbilityToastText;
      }

      private function ensureDebugAbilityToast() : void
      {
         var format:TextFormat = null;
         if(this.debugAbilityToast != null)
         {
            if(!contains(this.debugAbilityToast))
            {
               addChild(this.debugAbilityToast);
            }
            return;
         }
         this.debugAbilityToast = new TextField();
         format = new TextFormat("_typewriter",14,16776960,true);
         this.debugAbilityToast.defaultTextFormat = format;
         this.debugAbilityToast.selectable = false;
         this.debugAbilityToast.mouseEnabled = false;
         this.debugAbilityToast.multiline = false;
         this.debugAbilityToast.wordWrap = false;
         this.debugAbilityToast.background = true;
         this.debugAbilityToast.backgroundColor = 0;
         this.debugAbilityToast.border = true;
         this.debugAbilityToast.borderColor = 16776960;
         this.debugAbilityToast.width = 260;
         this.debugAbilityToast.height = 24;
         this.debugAbilityToast.x = 286;
         this.debugAbilityToast.y = 8;
         addChild(this.debugAbilityToast);
      }

      private function removeDebugOverlay() : void
      {
         if(this.debugOverlay != null && contains(this.debugOverlay))
         {
            removeChild(this.debugOverlay);
         }
         if(this.debugAbilityToast != null && contains(this.debugAbilityToast))
         {
            removeChild(this.debugAbilityToast);
         }
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

      private function toggleDebugFullVision() : void
      {
         if(game == null || game.fogOfWar == null)
         {
            return;
         }
         game.fogOfWar.isFogOn = !game.fogOfWar.isFogOn;
      }

      private function spawnDebugShadowrathAtEnemyBase() : void
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
