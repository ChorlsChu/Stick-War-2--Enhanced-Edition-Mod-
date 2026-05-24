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
   import flash.ui.Keyboard;
   
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

      private static const LEVEL_TITLE_REBELS_UNITED:String = "Rebels United";

      private static const LEVEL_TITLE_MEDUSA_GATES:String = "Medusa's Gates: The Chaos Capital is in sight. ";

      private var delayedLevelPrewarmQueue:Array;

      private var nextLevelPrewarmFrame:int;
      
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
         if(game.teamB.type == Team.T_CHAOS)
         {
            game.soundManager.playSoundInBackground("chaosInGame");
         }
         if(Team.getIdFromRaceName(this.main.campaign.getCurrentLevel().oponent.race) == Team.T_GOOD)
         {
            game.soundManager.playSoundInBackground("orderInGame");
         }
         else
         {
            game.soundManager.playSoundInBackground("chaosInGame");
         }
      }
      
      override public function update(evt:Event, timeDiff:Number) : void
      {
         this.tryTriggerCampaignReinforcements();
         this.processDelayedLevelPrewarm();
         if(this.doAiUpdates)
         {
            this.enemyTeamAi.update(game);
         }
         if(this.controller != null)
         {
            this.controller.update(this);
         }
         this.updateShadowrathLevelDisguises();
         super.update(evt,timeDiff);
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
         gameTimer.removeEventListener(TimerEvent.TIMER,updateGameLoop);
         gameTimer.stop();
         var e:EndOfGameMove = new EndOfGameMove();
         e.winner = game.winner.id;
         e.turn = simulation.turn;
         simulation.processMove(e);
         trace("UPDATE TIME");
         main.campaign.getCurrentLevel().updateTime(game.frame / 30);
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
         main.postGameScreen.setWinner(e.winner,team.type,main.campaign.getCurrentLevel().player.raceName,main.campaign.getCurrentLevel().oponent.raceName,team.id);
         main.postGameScreen.setRecords(game.economyRecords,game.militaryRecords);
         if(e.winner == team.id)
         {
            main.campaign.campaignPoints += main.campaign.getCurrentLevel().points;
            ++main.campaign.currentLevel;
         }
         if(!main.campaign.isGameFinished() && e.winner == team.id)
         {
            for each(u in main.campaign.getCurrentLevel().unlocks)
            {
               main.postGameScreen.appendUnitUnlocked(u,game);
            }
         }
         if(e.winner == team.id)
         {
            main.postGameScreen.showNextUnitUnlocked();
         }
         main.postGameScreen.setMode(PostGameScreen.M_CAMPAIGN);
         if(e.winner == team.id)
         {
            main.postGameScreen.setTipText("");
         }
         else
         {
            main.postGameScreen.setTipText(main.campaign.getCurrentLevel().tip);
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
         super.cleanUp();
      }
      
      override public function maySwitchOnDisconnect() : Boolean
      {
         return false;
      }

      public function get campaignController() : CampaignController
      {
         return this.controller;
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
                  return [Unit.U_MEDUSA,Unit.U_KNIGHT,Unit.U_WINGIDON];
               }
               if(difficulty == Campaign.D_HARD)
               {
                  return [Unit.U_MEDUSA,Unit.U_KNIGHT,Unit.U_KNIGHT,Unit.U_WINGIDON,Unit.U_WINGIDON];
               }
               return [Unit.U_MEDUSA,Unit.U_KNIGHT,Unit.U_KNIGHT,Unit.U_WINGIDON,Unit.U_WINGIDON,Unit.U_WINGIDON];
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
                  this.configureFactionBoss(newUnit);
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
      }

      private function isFactionBossLevel(title:String) : Boolean
      {
         return title == "Tutorial" || title == "Blot out the sun: Archidons Declare War" || title == "Silent Assassins: Ninjas Declare War" || title == "Magic in the Air: Wizards and monks Declare War ";
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
            default:
               return false;
         }
      }

      private function configureFactionBoss(unit:Unit) : void
      {
         this.configureWestwindBoss(unit);
         if(unit != null)
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
         for(unitId in this.shadowrathDisguiseCooldowns)
         {
            if(int(this.shadowrathDisguiseCooldowns[unitId]) > 0)
            {
               this.shadowrathDisguiseCooldowns[unitId] = int(this.shadowrathDisguiseCooldowns[unitId]) - 1;
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
         if(ninja.isBoss && (ninja.bossIsRetreating || ninja.bossEmergencySortie || ninja.isStealthed || ninja.hasBossWhiffPenalty()))
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
         if(main == null || main.isKongregate || !main.isCampaignDebug || userInterface == null || userInterface.keyBoardState == null || !userInterface.keyBoardState.isShift)
         {
            return;
         }
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
         else if(userInterface.keyBoardState.isPressed(Keyboard.F6))
         {
            this.spawnDebugEnemy(Unit.U_SWORDWRATH);
         }
         else if(userInterface.keyBoardState.isPressed(Keyboard.F7))
         {
            this.triggerDebugShadowrathEscapeEffect();
         }
         else if(userInterface.keyBoardState.isPressed(Keyboard.F8))
         {
            this.triggerDebugSpeartonBossSpecial();
         }
         else if(userInterface.keyBoardState.isPressed(Keyboard.F9))
         {
            this.toggleDebugFullVision();
         }
         else if(userInterface.keyBoardState.isPressed(49))
         {
            this.spawnDebugShadowrathAtEnemyBase();
         }
         else if(userInterface.keyBoardState.isPressed(50))
         {
            this.triggerDebugShadowrathDisguise();
         }
         else if(userInterface.keyBoardState.isPressed(51))
         {
            this.spawnDebugAlliedSpeartonAndArcher();
         }
      }

      private function spawnDebugAlliedSpeartonAndArcher() : void
      {
         var spearton:Unit = null;
         var archer:Unit = null;
         var spawnX:Number = NaN;
         var spawnY:Number = NaN;
         var attackMoveCommand:AttackMoveCommand = null;
         if(game == null || game.teamA == null || game.teamB == null)
         {
            return;
         }
         spawnX = game.teamA.homeX + game.teamA.direction * 220;
         spawnY = game.map.height / 2;
         spearton = game.unitFactory.getUnit(Unit.U_SPEARTON);
         game.teamA.spawn(spearton,game);
         spearton.x = spearton.px = spawnX;
         spearton.y = spearton.py = spawnY - 30;
         game.teamA.population += spearton.population;
         archer = game.unitFactory.getUnit(Unit.U_ARCHER);
         game.teamA.spawn(archer,game);
         archer.x = archer.px = spawnX - game.teamA.direction * 55;
         archer.y = archer.py = spawnY + 30;
         game.teamA.population += archer.population;
         game.projectileManager.initTowerSpawn(spearton.px,spearton.py,game.teamA,0.6);
         game.projectileManager.initTowerSpawn(archer.px,archer.py,game.teamA,0.6);
         game.projectileManager.initSpawnDrip(spearton.px,spearton.py,game.teamA);
         game.projectileManager.initSpawnDrip(archer.px,archer.py,game.teamA);
         attackMoveCommand = new AttackMoveCommand(game);
         attackMoveCommand.type = UnitCommand.ATTACK_MOVE;
         attackMoveCommand.goalX = game.teamB.statue.px;
         attackMoveCommand.goalY = game.map.height / 2;
         attackMoveCommand.realX = game.teamB.statue.px;
         attackMoveCommand.realY = game.map.height / 2;
         spearton.ai.setCommand(game,attackMoveCommand);
         attackMoveCommand = new AttackMoveCommand(game);
         attackMoveCommand.type = UnitCommand.ATTACK_MOVE;
         attackMoveCommand.goalX = game.teamB.statue.px;
         attackMoveCommand.goalY = game.map.height / 2;
         attackMoveCommand.realX = game.teamB.statue.px;
         attackMoveCommand.realY = game.map.height / 2;
         archer.ai.setCommand(game,attackMoveCommand);
      }

      private function spawnDebugBoss(unitType:int) : void
      {
         var boss:Unit = null;
         var ally:Unit = null;
         var spawnX:Number = NaN;
         var spawnY:Number = NaN;
         var offsetY:Number = NaN;
         var i:int = 0;
         var attackMoveCommand:AttackMoveCommand = null;
         if(game == null || game.teamB == null)
         {
            return;
         }
         this.grantWestwindBossResearch();
         boss = game.unitFactory.getUnit(unitType);
         game.teamB.spawn(boss,game);
         this.configureWestwindBoss(boss);
         spawnX = team.homeX + team.direction * 180;
         spawnY = game.map.height / 2;
         boss.x = boss.px = spawnX;
         boss.y = boss.py = spawnY;
         game.teamB.population += boss.population;
         game.projectileManager.initTowerSpawn(spawnX,spawnY,game.teamB,0.7);
         game.projectileManager.initSpawnDrip(spawnX,spawnY,game.teamB);
         game.soundManager.playSoundFullVolume("Rage1");
         attackMoveCommand = new AttackMoveCommand(game);
         attackMoveCommand.type = UnitCommand.ATTACK_MOVE;
         attackMoveCommand.goalX = team.statue.px;
         attackMoveCommand.goalY = game.map.height / 2;
         attackMoveCommand.realX = team.statue.px;
         attackMoveCommand.realY = game.map.height / 2;
         boss.ai.setCommand(game,attackMoveCommand);
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
               attackMoveCommand = new AttackMoveCommand(game);
               attackMoveCommand.type = UnitCommand.ATTACK_MOVE;
               attackMoveCommand.goalX = team.statue.px;
               attackMoveCommand.goalY = game.map.height / 2;
               attackMoveCommand.realX = team.statue.px;
               attackMoveCommand.realY = game.map.height / 2;
               ally.ai.setCommand(game,attackMoveCommand);
            }
         }
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
         enemy = game.unitFactory.getUnit(unitType);
         game.teamB.spawn(enemy,game);
         spawnX = team.homeX + team.direction * 220;
         spawnY = game.map.height / 2;
         enemy.x = enemy.px = spawnX;
         enemy.y = enemy.py = spawnY;
         game.teamB.population += enemy.population;
         game.projectileManager.initTowerSpawn(spawnX,spawnY,game.teamB,0.6);
         game.projectileManager.initSpawnDrip(spawnX,spawnY,game.teamB);
         attackMoveCommand = new AttackMoveCommand(game);
         attackMoveCommand.type = UnitCommand.ATTACK_MOVE;
         attackMoveCommand.goalX = team.statue.px;
         attackMoveCommand.goalY = game.map.height / 2;
         attackMoveCommand.realX = team.statue.px;
         attackMoveCommand.realY = game.map.height / 2;
         enemy.ai.setCommand(game,attackMoveCommand);
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

