package com.brockw.stickwar.campaign.controllers
{
   import com.brockw.stickwar.campaign.Campaign;
   import com.brockw.stickwar.campaign.CampaignGameScreen;
   import com.brockw.stickwar.campaign.InGameMessage;
   import com.brockw.stickwar.GameScreen;
   import com.brockw.stickwar.engine.Gold;
   import com.brockw.stickwar.engine.Hill;
   import com.brockw.stickwar.engine.Ai.command.AttackMoveCommand;
   import com.brockw.stickwar.engine.Ai.command.HoldCommand;
   import com.brockw.stickwar.engine.Ai.command.MoveCommand;
   import com.brockw.stickwar.engine.Ai.command.UnitCommand;
   import com.brockw.stickwar.engine.Team.Team;
   import com.brockw.stickwar.engine.Team.Tech;
   import com.brockw.stickwar.engine.units.Archer;
   import com.brockw.stickwar.engine.units.Magikill;
   import com.brockw.stickwar.engine.units.Monk;
   import com.brockw.stickwar.engine.units.Ninja;
   import com.brockw.stickwar.engine.units.Spearton;
   import com.brockw.stickwar.engine.units.Swordwrath;
   import com.brockw.stickwar.engine.units.Unit;
   import flash.display.Sprite;
   import flash.geom.ColorTransform;
   
   public class CampaignAmbush extends CampaignController
   {
      
      private static const LEVEL_NATIVE_TRIBES:String = "Ambush: Native Tribes";

      private static const LEVEL_SHADOWRATH_STALKERS:String = "Ambush: Shadowrath Stalkers";

      private static const LEVEL_REBELS_BREAK:String = "Ambush: Rebels Last Stand";
      
      private static const SURVIVE_FRAMES:int = 30 * 150;

      private static const SHADOWRATH_NIGHT_TINT_COLOR:uint = 0x07152F;

      private static const SHADOWRATH_NIGHT_TINT_ALPHA:Number = 0.32;

      private static const SHADOWRATH_BARRIER_DISTANCE_FROM_BASE:Number = 1350;

      private static const STALK_CLOAK_UNLOCK_FRAME:int = 2700;

      private static const STALK_CLOAK_TRIGGER_PADDING:Number = 160;

      private static const START_MESSAGE_DELAY_FRAMES:int = 45;

      private static const START_MESSAGE_VISIBLE_FRAMES:int = 30 * 4;

      private static const COMPLETE_DELAY_FRAMES:int = 30 * 3;

      private static const REINFORCEMENT_SWORDWRATHS:int = 6;

      private static const REINFORCEMENT_SPEARTONS:int = 3;
      
      private static const BARRIER_PADDING:Number = 120;

      private static const NATIVE_SPEARTON_WEAPON:String = "Native Spaer";
      
      private static const NATIVE_SPEARTON_ARMOR:String = "Native Spearton";
      
      private static const NATIVE_SPEARTON_MISC:String = "Native Shield";

      private static const NATIVE_SWORDWRATH_WEAPON:String = "Club";
      
      private static const NATIVE_HEALTH_MULTIPLIER:Number = 0.5;

      private static const NATIVE_BASE_SPAWN_OFFSET:Number = 260;

      private static const REINFORCEMENT_BASE_SPAWN_OFFSET:Number = 120;

      private static const NATIVE_FORMATION_MAX_ROWS:int = 6;

      private static const NATIVE_FORMATION_ROW_SPACING:Number = 34;

      private static const NATIVE_FORMATION_COLUMN_SPACING:Number = 55;

      private static const NATIVE_FORMATION_GOAL_PADDING:Number = 70;
      
      private static const ATTACK_REFRESH_DELAY_FRAMES:int = 60;
      
      private static const NATIVE_WAVE_TIMES:Array = [90,1200,2000,2700,3600];
      
      private static const NATIVE_WAVE_SPEARTONS_NORMAL:Array = [0,1,1,0,2];
      
      private static const NATIVE_WAVE_SWORDWRATHS_NORMAL:Array = [2,2,2,3,4];
      
      private static const NATIVE_WAVE_SPEARTONS_HARD:Array = [1,2,1,0,3];
      
      private static const NATIVE_WAVE_SWORDWRATHS_HARD:Array = [2,2,2,4,4];
      
      private static const NATIVE_WAVE_SPEARTONS_INSANE:Array = [1,2,2,1,5];
      
      private static const NATIVE_WAVE_SWORDWRATHS_INSANE:Array = [3,3,3,4,6];

      private static const STALK_WAVE_TIMES:Array = [90,1200,2000,2700,3600];

      private static const STALK_WAVE_SHADOWRATHS_NORMAL:Array = [0,2,0,1,4];

      private static const STALK_WAVE_SHADOWRATHS_HARD:Array = [0,3,0,2,5];

      private static const STALK_WAVE_SHADOWRATHS_INSANE:Array = [0,4,0,2,7];

      private static const REBEL_OPENING_DELAY_FRAMES:int = 30 * 2;

      private static const REBEL_OPENING_HOLD_FRAMES:int = 30 * 4;

      private static const REBEL_WAVE_FRAME:int = 3600;

      private static const REBEL_ENDING_HOLD_FRAMES:int = 30 * 5;

      private static const REBEL_END_COMPLETE_DELAY_FRAMES:int = 30 * 2;

      private static const REBEL_WAVE_NORMAL:Array = [Unit.U_SPEARTON,Unit.U_SPEARTON,Unit.U_SPEARTON,Unit.U_ARCHER,Unit.U_ARCHER,Unit.U_NINJA,Unit.U_SWORDWRATH,Unit.U_MONK];

      private static const REBEL_WAVE_HARD:Array = [Unit.U_SPEARTON,Unit.U_SPEARTON,Unit.U_SPEARTON,Unit.U_SPEARTON,Unit.U_ARCHER,Unit.U_ARCHER,Unit.U_ARCHER,Unit.U_NINJA,Unit.U_NINJA,Unit.U_SWORDWRATH,Unit.U_SWORDWRATH,Unit.U_MAGIKILL,Unit.U_MONK];

      private static const REBEL_WAVE_INSANE:Array = [Unit.U_SPEARTON,Unit.U_SPEARTON,Unit.U_SPEARTON,Unit.U_SPEARTON,Unit.U_SPEARTON,Unit.U_SPEARTON,Unit.U_ARCHER,Unit.U_ARCHER,Unit.U_ARCHER,Unit.U_ARCHER,Unit.U_NINJA,Unit.U_NINJA,Unit.U_SWORDWRATH,Unit.U_SWORDWRATH,Unit.U_MAGIKILL,Unit.U_MONK];
      
      private var initialized:Boolean;
      
      private var startFrame:int;
      
      private var barrierX:Number;
      
      private var lastEnemyArmyVersion:int;
      
      private var nativeWaveIndex:int;

      private var stalkWaveIndex:int;

      private var ambushCompleteDelayStartFrame:int;

      private var hasShownStartMessage:Boolean;

      private var hasSpawnedReinforcements:Boolean;

      private var message:InGameMessage;

      private var messageStartFrame:int;

      private var activeNativeWaveUnits:Array;

      private var activeStalkWaveUnits:Array;

      private var activeRebelWaveUnits:Array;

      private var rebelDisplayUnits:Array;

      private var rebelWaveSpawned:Boolean;

      private var rebelOpeningStarted:Boolean;

      private var rebelOpeningFinished:Boolean;

      private var rebelEndingStarted:Boolean;

      private var rebelEndingStartFrame:int;

      private var rebelRevealFog:Boolean;

      private var nightOverlay:Sprite;

      private var hasUnlockedStalkCloak:Boolean;
      
      private var pendingAttackRefreshes:Array;
      
      public function CampaignAmbush(gameScreen:GameScreen)
      {
         super(gameScreen);
         this.initialized = false;
         this.startFrame = 0;
         this.barrierX = 0;
         this.lastEnemyArmyVersion = -1;
         this.nativeWaveIndex = 0;
         this.stalkWaveIndex = 0;
         this.ambushCompleteDelayStartFrame = -1;
         this.hasShownStartMessage = false;
         this.hasSpawnedReinforcements = false;
         this.message = null;
         this.messageStartFrame = -1;
         this.activeNativeWaveUnits = [];
         this.activeStalkWaveUnits = [];
         this.activeRebelWaveUnits = [];
         this.rebelDisplayUnits = [];
         this.rebelWaveSpawned = false;
         this.rebelOpeningStarted = false;
         this.rebelOpeningFinished = false;
         this.rebelEndingStarted = false;
         this.rebelEndingStartFrame = -1;
         this.rebelRevealFog = false;
         this.nightOverlay = null;
         this.hasUnlockedStalkCloak = false;
         this.pendingAttackRefreshes = [];
      }
      
      override public function update(gameScreen:GameScreen) : void
      {
         if(!this.initialized)
         {
            this.initializeAmbush(gameScreen);
         }
         gameScreen.isFastForward = false;
         this.updateMessage(gameScreen);
         this.updateAmbushFog(gameScreen);
         this.keepEnemyBaseHidden(gameScreen);
         this.updateNativeTribesWaves(gameScreen);
         this.updateShadowrathStalkersWaves(gameScreen);
         this.updateShadowrathStalkersCloak(gameScreen);
         this.updateRebelBreakAmbush(gameScreen);
         this.updatePendingAttackRefreshes(gameScreen);
         this.updateAmbusherOrders(gameScreen);
         this.stopSpawnedPlayerUnits(gameScreen);
         this.clampPlayerUnits(gameScreen);
         if(this.isRebelBreakLevel(gameScreen))
         {
            return;
         }
         if(gameScreen.game.frame - this.startFrame >= SURVIVE_FRAMES && !this.hasSpawnedReinforcements)
         {
            this.spawnReinforcements(gameScreen);
            this.hasSpawnedReinforcements = true;
         }
         if(gameScreen.game.frame - this.startFrame >= SURVIVE_FRAMES && this.hasSpawnedAllAmbushWaves(gameScreen) && !this.hasLivingEnemyCombatUnits(gameScreen))
         {
            if(this.ambushCompleteDelayStartFrame < 0)
            {
               this.ambushCompleteDelayStartFrame = gameScreen.game.frame;
            }
            if(gameScreen.game.frame - this.ambushCompleteDelayStartFrame >= COMPLETE_DELAY_FRAMES)
            {
               this.completeAmbush(gameScreen);
            }
         }
         else
         {
            this.ambushCompleteDelayStartFrame = -1;
         }
      }
      
      private function initializeAmbush(gameScreen:GameScreen) : void
      {
         this.initialized = true;
         this.startFrame = gameScreen.game.frame;
         this.barrierX = this.getAmbushBarrierX(gameScreen);
         gameScreen.doAiUpdates = false;
         gameScreen.isFastForward = false;
         if(!this.isRebelBreakLevel(gameScreen))
         {
            gameScreen.team.tech.isResearchedMap[Tech.CASTLE_ARCHER_1] = true;
         }
         gameScreen.team.createTimeMultiplier = 0.5;
         gameScreen.team.tech.researchTimeMultiplier = 0.5;
         this.initializeShadowrathStalkers(gameScreen);
         this.initializeRebelBreak(gameScreen);
         this.removeMiddleHills(gameScreen);
         this.hideEnemyGoldVisuals(gameScreen);
         this.disableEnemyCastleDefence(gameScreen);
         this.applyShadowrathNightOverlay(gameScreen);
         this.updateAmbushFog(gameScreen);
         this.keepEnemyBaseHidden(gameScreen);
         this.updateAmbusherOrders(gameScreen);
      }

      private function getAmbushBarrierX(gameScreen:GameScreen) : Number
      {
         if(this.isShadowrathStalkersLevel(gameScreen))
         {
            return Math.min(gameScreen.game.map.width / 2 - BARRIER_PADDING,gameScreen.team.homeX + gameScreen.team.direction * SHADOWRATH_BARRIER_DISTANCE_FROM_BASE);
         }
         return gameScreen.game.map.width / 2 - BARRIER_PADDING;
      }

      private function initializeRebelBreak(gameScreen:GameScreen) : void
      {
         if(!this.isRebelBreakLevel(gameScreen))
         {
            return;
         }
         gameScreen.team.tech.isResearchedMap[Tech.MINER_SPEED] = true;
         gameScreen.team.enemyTeam.tech.isResearchedMap[Tech.MINER_WALL] = false;
         CampaignGameScreen(gameScreen).enemyTeamAi.setUnitCreationEnabled(false);
         this.applyRebelBreakDifficultyResearch(gameScreen);
         this.clearEnemyStartingCombatUnits(gameScreen);
      }

      private function applyRebelBreakDifficultyResearch(gameScreen:GameScreen) : void
      {
         if(gameScreen.main == null || gameScreen.main.campaign == null)
         {
            return;
         }
         if(gameScreen.main.campaign.difficultyLevel == Campaign.D_NORMAL)
         {
            gameScreen.team.tech.isResearchedMap[Tech.CASTLE_ARCHER_1] = true;
            gameScreen.team.tech.isResearchedMap[Tech.BANK_PASSIVE_1] = true;
            gameScreen.team.tech.isResearchedMap[Tech.MAGIKILL_WALL] = true;
            gameScreen.team.tech.isResearchedMap[Tech.MAGIKILL_POISON] = true;
         }
         else if(gameScreen.main.campaign.difficultyLevel == Campaign.D_HARD)
         {
            gameScreen.team.tech.isResearchedMap[Tech.BANK_PASSIVE_1] = true;
            gameScreen.team.tech.isResearchedMap[Tech.MAGIKILL_POISON] = true;
         }
      }

      private function initializeShadowrathStalkers(gameScreen:GameScreen) : void
      {
         if(!this.isShadowrathStalkersLevel(gameScreen))
         {
            return;
         }
         gameScreen.team.tech.isResearchedMap[Tech.MINER_SPEED] = true;
         delete gameScreen.team.enemyTeam.tech.isResearchedMap[Tech.CLOAK];
         this.clearEnemyStartingCombatUnits(gameScreen);
      }

      private function applyShadowrathNightOverlay(gameScreen:GameScreen) : void
      {
         if(!this.isShadowrathStalkersLevel(gameScreen) || gameScreen.game == null || gameScreen.game.stage == null)
         {
            return;
         }
         if(this.nightOverlay != null)
         {
            return;
         }
         this.nightOverlay = new Sprite();
         this.nightOverlay.mouseEnabled = false;
         this.nightOverlay.mouseChildren = false;
         this.nightOverlay.graphics.beginFill(SHADOWRATH_NIGHT_TINT_COLOR,SHADOWRATH_NIGHT_TINT_ALPHA);
         this.nightOverlay.graphics.drawRect(0,0,gameScreen.game.stage.stageWidth,gameScreen.game.stage.stageHeight);
         this.nightOverlay.graphics.endFill();
         gameScreen.game.addChild(this.nightOverlay);
      }

      private function updateMessage(gameScreen:GameScreen) : void
      {
         if(this.message != null)
         {
            if(gameScreen.contains(this.message))
            {
               this.message.update();
               if(this.messageStartFrame >= 0 && gameScreen.game.frame - this.messageStartFrame >= START_MESSAGE_VISIBLE_FRAMES)
               {
                  gameScreen.removeChild(this.message);
                  this.message = null;
               }
            }
            return;
         }
         if(!this.shouldShowStartMessage(gameScreen) || this.hasShownStartMessage || gameScreen.game.frame - this.startFrame < START_MESSAGE_DELAY_FRAMES)
         {
            return;
         }
         this.hasShownStartMessage = true;
         this.message = new InGameMessage("",gameScreen.game);
         this.message.x = gameScreen.game.stage.stageWidth / 2;
         this.message.y = gameScreen.game.stage.stageHeight / 4 - 75;
         this.message.scaleX *= 1.3;
         this.message.scaleY *= 1.3;
         this.message.setMessage("Defend until Reinforcements arrive","");
         gameScreen.addChild(this.message);
         this.messageStartFrame = gameScreen.game.frame;
      }

      private function updateAmbushFog(gameScreen:GameScreen) : void
      {
         if(gameScreen.game.fogOfWar == null)
         {
            return;
         }
         if(gameScreen is CampaignGameScreen && CampaignGameScreen(gameScreen).isDebugFullVisionEnabled)
         {
            gameScreen.game.fogOfWar.isFogOn = false;
            return;
         }
         if(this.rebelRevealFog)
         {
            gameScreen.game.fogOfWar.isFogOn = false;
            return;
         }
         if(this.isNativeTribesLevel(gameScreen) || this.isShadowrathStalkersLevel(gameScreen) || this.isRebelBreakLevel(gameScreen))
         {
            gameScreen.game.fogOfWar.isFogOn = true;
            gameScreen.game.fogOfWar.lockForwardPosition(this.barrierX);
         }
      }
      
      private function keepEnemyBaseHidden(gameScreen:GameScreen) : void
      {
         if(gameScreen.team.enemyTeam.castleBack != null)
         {
            gameScreen.team.enemyTeam.castleBack.visible = false;
         }
         if(gameScreen.team.enemyTeam.castleFront != null)
         {
            gameScreen.team.enemyTeam.castleFront.visible = false;
         }
         if(gameScreen.team.enemyTeam.base != null)
         {
            gameScreen.team.enemyTeam.base.visible = false;
         }
         if(gameScreen.team.enemyTeam.statue != null)
         {
            gameScreen.team.enemyTeam.statue.visible = false;
            gameScreen.team.enemyTeam.statue.health = Math.max(gameScreen.team.enemyTeam.statue.health,1);
         }
      }
      
      private function hideEnemyGoldVisuals(gameScreen:GameScreen) : void
      {
         var i:int = 0;
         var gold:Gold = null;
         if(gameScreen.game.map == null || gameScreen.game.map.gold == null)
         {
            return;
         }
         for(i = int(gameScreen.game.map.gold.length / 2); i < gameScreen.game.map.gold.length; i++)
         {
            gold = gameScreen.game.map.gold[i] as Gold;
            if(gold != null)
            {
               gold.ore.visible = false;
               gold.frontOre.visible = false;
               gold.ore.mouseEnabled = false;
               gold.frontOre.mouseEnabled = false;
            }
         }
      }
      
      private function removeMiddleHills(gameScreen:GameScreen) : void
      {
         var hill:Hill = null;
         while(gameScreen.game.map.hills.length > 0)
         {
            hill = gameScreen.game.map.hills.pop();
            if(hill != null && hill.parent != null)
            {
               hill.parent.removeChild(hill);
            }
         }
      }
      
      private function disableEnemyCastleDefence(gameScreen:GameScreen) : void
      {
         delete gameScreen.team.enemyTeam.tech.isResearchedMap[Tech.CASTLE_ARCHER_1];
         delete gameScreen.team.enemyTeam.tech.isResearchedMap[Tech.CASTLE_ARCHER_2];
         delete gameScreen.team.enemyTeam.tech.isResearchedMap[Tech.CASTLE_ARCHER_3];
         delete gameScreen.team.enemyTeam.tech.isResearchedMap[Tech.CASTLE_ARCHER_4];
         delete gameScreen.team.enemyTeam.tech.isResearchedMap[Tech.CASTLE_ARCHER_5];
      }
      
      private function clampPlayerUnits(gameScreen:GameScreen) : void
      {
         var unit:Unit = null;
         for each(unit in gameScreen.team.units)
         {
            if(unit != null && unit.isAlive() && this.rebelDisplayUnits.indexOf(unit) == -1 && unit.px > this.barrierX)
            {
               unit.px = this.barrierX;
               unit.x = unit.px;
               this.holdUnit(gameScreen,unit);
            }
         }
      }
      
      private function updateAmbusherOrders(gameScreen:GameScreen) : void
      {
         var unit:Unit = null;
         if(this.isNativeTribesLevel(gameScreen) || this.isShadowrathStalkersLevel(gameScreen) || this.isRebelBreakLevel(gameScreen))
         {
            return;
         }
         if(this.lastEnemyArmyVersion == gameScreen.team.enemyTeam.armyChangeVersion)
         {
            return;
         }
         this.lastEnemyArmyVersion = gameScreen.team.enemyTeam.armyChangeVersion;
         for each(unit in gameScreen.team.enemyTeam.units)
         {
            if(unit != null && unit.isAlive() && unit.type != Unit.U_MINER && unit.type != Unit.U_CHAOS_MINER && unit.type != Unit.U_CHAOS_TOWER)
            {
               this.issueAmbushAttackCommand(gameScreen,unit);
            }
         }
      }
      
      private function issueAmbushAttackCommand(gameScreen:GameScreen, unit:Unit, goalY:Number = -1) : void
      {
         var attackMoveCommand:AttackMoveCommand = null;
         if(unit.ai == null)
         {
            return;
         }
         attackMoveCommand = new AttackMoveCommand(gameScreen.game);
         attackMoveCommand.type = UnitCommand.ATTACK_MOVE;
         attackMoveCommand.goalX = gameScreen.team.statue.px;
         attackMoveCommand.goalY = goalY < 0 ? gameScreen.game.map.height / 2 : goalY;
         attackMoveCommand.realX = attackMoveCommand.goalX;
         attackMoveCommand.realY = attackMoveCommand.goalY;
         unit.ai.setCommand(gameScreen.game,attackMoveCommand);
      }

      private function updateNativeTribesWaves(gameScreen:GameScreen) : void
      {
         var elapsed:int = gameScreen.game.frame - this.startFrame;
         if(!this.isNativeTribesLevel(gameScreen))
         {
            return;
         }
         if(this.hasLivingActiveNativeWaveUnits())
         {
            return;
         }
         if(this.nativeWaveIndex < NATIVE_WAVE_TIMES.length && elapsed >= int(NATIVE_WAVE_TIMES[this.nativeWaveIndex]))
         {
            this.spawnNativeWave(gameScreen,int(this.getNativeWaveSpeartons(gameScreen)[this.nativeWaveIndex]),int(this.getNativeWaveSwordwraths(gameScreen)[this.nativeWaveIndex]));
            ++this.nativeWaveIndex;
         }
      }

      private function updateShadowrathStalkersWaves(gameScreen:GameScreen) : void
      {
         var elapsed:int = gameScreen.game.frame - this.startFrame;
         if(!this.isShadowrathStalkersLevel(gameScreen))
         {
            return;
         }
         this.updateShadowrathCloakUnlock(gameScreen,elapsed);
         if(this.hasLivingActiveStalkWaveUnits())
         {
            return;
         }
         if(this.stalkWaveIndex < STALK_WAVE_TIMES.length && elapsed >= int(STALK_WAVE_TIMES[this.stalkWaveIndex]))
         {
            this.spawnStalkWave(gameScreen,int(this.getStalkWaveShadowraths(gameScreen)[this.stalkWaveIndex]));
            ++this.stalkWaveIndex;
         }
      }

      private function updateShadowrathCloakUnlock(gameScreen:GameScreen, elapsed:int) : void
      {
         if(this.hasUnlockedStalkCloak || elapsed < STALK_CLOAK_UNLOCK_FRAME)
         {
            return;
         }
         this.hasUnlockedStalkCloak = true;
         gameScreen.team.enemyTeam.tech.isResearchedMap[Tech.CLOAK] = true;
      }

      private function getStalkWaveShadowraths(gameScreen:GameScreen) : Array
      {
         if(gameScreen.main != null && gameScreen.main.campaign != null && gameScreen.main.campaign.difficultyLevel == Campaign.D_INSANE)
         {
            return STALK_WAVE_SHADOWRATHS_INSANE;
         }
         if(gameScreen.main != null && gameScreen.main.campaign != null && gameScreen.main.campaign.difficultyLevel == Campaign.D_HARD)
         {
            return STALK_WAVE_SHADOWRATHS_HARD;
         }
         return STALK_WAVE_SHADOWRATHS_NORMAL;
      }

      private function getNativeWaveSpeartons(gameScreen:GameScreen) : Array
      {
         if(gameScreen.main != null && gameScreen.main.campaign != null && gameScreen.main.campaign.difficultyLevel == Campaign.D_INSANE)
         {
            return NATIVE_WAVE_SPEARTONS_INSANE;
         }
         if(gameScreen.main != null && gameScreen.main.campaign != null && gameScreen.main.campaign.difficultyLevel == Campaign.D_HARD)
         {
            return NATIVE_WAVE_SPEARTONS_HARD;
         }
         return NATIVE_WAVE_SPEARTONS_NORMAL;
      }

      private function getNativeWaveSwordwraths(gameScreen:GameScreen) : Array
      {
         if(gameScreen.main != null && gameScreen.main.campaign != null && gameScreen.main.campaign.difficultyLevel == Campaign.D_INSANE)
         {
            return NATIVE_WAVE_SWORDWRATHS_INSANE;
         }
         if(gameScreen.main != null && gameScreen.main.campaign != null && gameScreen.main.campaign.difficultyLevel == Campaign.D_HARD)
         {
            return NATIVE_WAVE_SWORDWRATHS_HARD;
         }
         return NATIVE_WAVE_SWORDWRATHS_NORMAL;
      }
      
      private function spawnNativeWave(gameScreen:GameScreen, speartonCount:int, swordwrathCount:int) : void
      {
         var i:int = 0;
         var spearton:Spearton = null;
         var swordwrath:Swordwrath = null;
         var spawnedUnits:Array = [];
         var refreshEntries:Array = [];
         var goalY:Number = 0;
         var totalCount:int = speartonCount + swordwrathCount;
         for(i = 0; i < speartonCount; i++)
         {
            spearton = Spearton(gameScreen.game.unitFactory.getUnit(Unit.U_SPEARTON));
            gameScreen.team.enemyTeam.spawn(spearton,gameScreen.game);
            goalY = this.getNativeFormationGoalY(gameScreen,i,totalCount);
            spearton.px = this.getNativeFormationSpawnX(gameScreen,i);
            spearton.x = spearton.px;
            spearton.py = goalY;
            spearton.y = spearton.py;
            spearton.scaleX *= gameScreen.team.enemyTeam.direction * -1;
            spearton.forceSkin(NATIVE_SPEARTON_WEAPON,NATIVE_SPEARTON_ARMOR,NATIVE_SPEARTON_MISC);
            spearton.maxHealth *= NATIVE_HEALTH_MULTIPLIER;
            spearton.health = spearton.maxHealth;
            spearton.healthBar.totalHealth = spearton.maxHealth;
            spearton.healthBar.health = spearton.health;
            spearton.healthBar.reset();
            this.issueAmbushAttackCommand(gameScreen,spearton,goalY);
            spawnedUnits.push(spearton);
            refreshEntries.push([spearton,goalY]);
         }
         for(i = 0; i < swordwrathCount; i++)
         {
            swordwrath = Swordwrath(gameScreen.game.unitFactory.getUnit(Unit.U_SWORDWRATH));
            gameScreen.team.enemyTeam.spawn(swordwrath,gameScreen.game);
            goalY = this.getNativeFormationGoalY(gameScreen,speartonCount + i,totalCount);
            swordwrath.px = this.getNativeFormationSpawnX(gameScreen,speartonCount + i);
            swordwrath.x = swordwrath.px;
            swordwrath.py = goalY;
            swordwrath.y = swordwrath.py;
            swordwrath.scaleX *= gameScreen.team.enemyTeam.direction * -1;
            swordwrath.forceSkin(NATIVE_SWORDWRATH_WEAPON);
            swordwrath.maxHealth *= NATIVE_HEALTH_MULTIPLIER;
            swordwrath.health = swordwrath.maxHealth;
            swordwrath.healthBar.totalHealth = swordwrath.maxHealth;
            swordwrath.healthBar.health = swordwrath.health;
            swordwrath.healthBar.reset();
            this.issueAmbushAttackCommand(gameScreen,swordwrath,goalY);
            spawnedUnits.push(swordwrath);
            refreshEntries.push([swordwrath,goalY]);
         }
         this.activeNativeWaveUnits = spawnedUnits;
         this.pendingAttackRefreshes.push([gameScreen.game.frame + ATTACK_REFRESH_DELAY_FRAMES,refreshEntries]);
      }

      private function spawnStalkWave(gameScreen:GameScreen, shadowrathCount:int) : void
      {
         var i:int = 0;
         var ninja:Ninja = null;
         var spawnedUnits:Array = [];
         var refreshEntries:Array = [];
         var goalY:Number = 0;
         if(shadowrathCount <= 0)
         {
            this.activeStalkWaveUnits = [];
            return;
         }
         for(i = 0; i < shadowrathCount; i++)
         {
            ninja = Ninja(gameScreen.game.unitFactory.getUnit(Unit.U_NINJA));
            gameScreen.team.enemyTeam.spawn(ninja,gameScreen.game);
            goalY = this.getNativeFormationGoalY(gameScreen,i,shadowrathCount);
            ninja.px = this.getNativeFormationSpawnX(gameScreen,i);
            ninja.x = ninja.px;
            ninja.py = goalY;
            ninja.y = ninja.py;
            ninja.scaleX *= gameScreen.team.enemyTeam.direction * -1;
            this.issueAmbushAttackCommand(gameScreen,ninja,goalY);
            spawnedUnits.push(ninja);
            refreshEntries.push([ninja,goalY]);
         }
         this.activeStalkWaveUnits = spawnedUnits;
         this.pendingAttackRefreshes.push([gameScreen.game.frame + ATTACK_REFRESH_DELAY_FRAMES,refreshEntries]);
      }

      private function updateShadowrathStalkersCloak(gameScreen:GameScreen) : void
      {
         var unit:Unit = null;
         var ninja:Ninja = null;
         var triggerX:Number = NaN;
         if(!this.hasUnlockedStalkCloak || !this.isShadowrathStalkersLevel(gameScreen))
         {
            return;
         }
         triggerX = this.barrierX + gameScreen.team.direction * STALK_CLOAK_TRIGGER_PADDING;
         for each(unit in this.activeStalkWaveUnits)
         {
            ninja = unit as Ninja;
            if(ninja != null && ninja.isAlive() && !ninja.isStealthed && (ninja.px - triggerX) * gameScreen.team.direction <= 0)
            {
               ninja.stealth();
            }
         }
      }

      private function updateRebelBreakAmbush(gameScreen:GameScreen) : void
      {
         var elapsed:int = gameScreen.game.frame - this.startFrame;
         if(!this.isRebelBreakLevel(gameScreen))
         {
            return;
         }
         if(!this.rebelOpeningStarted && elapsed >= REBEL_OPENING_DELAY_FRAMES)
         {
            this.startRebelOpening(gameScreen);
         }
         if(this.rebelOpeningStarted && !this.rebelOpeningFinished && elapsed >= REBEL_OPENING_DELAY_FRAMES + REBEL_OPENING_HOLD_FRAMES)
         {
            this.finishRebelOpening(gameScreen);
         }
         if(!this.rebelWaveSpawned && elapsed >= REBEL_WAVE_FRAME)
         {
            this.spawnRebelWave(gameScreen);
            this.rebelWaveSpawned = true;
         }
         if(this.rebelWaveSpawned && !this.rebelEndingStarted && !this.hasLivingActiveRebelWaveUnits())
         {
            if(this.ambushCompleteDelayStartFrame < 0)
            {
               this.ambushCompleteDelayStartFrame = gameScreen.game.frame;
            }
            if(gameScreen.game.frame - this.ambushCompleteDelayStartFrame >= REBEL_END_COMPLETE_DELAY_FRAMES)
            {
               this.startRebelEnding(gameScreen);
            }
         }
         if(this.rebelEndingStarted && gameScreen.game.frame - this.rebelEndingStartFrame >= REBEL_ENDING_HOLD_FRAMES)
         {
            this.cleanupRebelDisplayUnits(gameScreen);
            this.rebelRevealFog = false;
            this.completeAmbush(gameScreen);
         }
      }

      private function startRebelOpening(gameScreen:GameScreen) : void
      {
         this.rebelOpeningStarted = true;
         this.rebelRevealFog = true;
         this.spawnRebelOpeningDisplay(gameScreen);
         this.setCameraTarget(gameScreen,this.getEnemyCameraX(gameScreen));
         this.showAmbushMessage(gameScreen,"Rebels are sending everything they have at you! Prepare a defense");
      }

      private function finishRebelOpening(gameScreen:GameScreen) : void
      {
         this.rebelOpeningFinished = true;
         this.rebelRevealFog = false;
         this.cleanupRebelDisplayUnits(gameScreen);
         this.killAllEnemyUnits(gameScreen);
         this.setCameraTarget(gameScreen,this.getPlayerCameraX(gameScreen));
      }

      private function startRebelEnding(gameScreen:GameScreen) : void
      {
         this.rebelEndingStarted = true;
         this.rebelEndingStartFrame = gameScreen.game.frame;
         this.rebelRevealFog = true;
         gameScreen.doAiUpdates = true;
         this.spawnRebelEndingBattle(gameScreen);
         this.setCameraTarget(gameScreen,this.getEnemyCameraX(gameScreen));
      }

      private function spawnRebelOpeningDisplay(gameScreen:GameScreen) : void
      {
         var displayTypes:Array = [Unit.U_SPEARTON,Unit.U_SPEARTON,Unit.U_SPEARTON,Unit.U_SPEARTON,Unit.U_ARCHER,Unit.U_ARCHER,Unit.U_ARCHER,Unit.U_ARCHER,Unit.U_NINJA,Unit.U_NINJA,Unit.U_SWORDWRATH,Unit.U_SWORDWRATH,Unit.U_SPEARTON,Unit.U_ARCHER,Unit.U_MAGIKILL,Unit.U_MONK,Unit.U_SPEARTON,Unit.U_ARCHER,Unit.U_NINJA,Unit.U_SWORDWRATH];
         var bossTypes:Array = [Unit.U_SPEARTON,Unit.U_ARCHER,Unit.U_NINJA,Unit.U_MAGIKILL,Unit.U_MONK];
         var i:int = 0;
         var bossXOffset:int = int(Math.ceil(displayTypes.length / 6));
         for(i = 0; i < displayTypes.length; i++)
         {
            this.spawnDisplayUnit(gameScreen,gameScreen.team.enemyTeam,int(displayTypes[i]),this.getEnemyDisplayX(gameScreen,i,displayTypes.length),this.getDisplayY(gameScreen,i,displayTypes.length),false,false);
         }
         for(i = 0; i < bossTypes.length; i++)
         {
            this.spawnDisplayUnit(gameScreen,gameScreen.team.enemyTeam,int(bossTypes[i]),this.getEnemyDisplayX(gameScreen,bossXOffset * 6 + i,bossTypes.length),this.getDisplayY(gameScreen,bossXOffset * 6 + i,bossTypes.length),true,false);
         }
      }

      private function spawnRebelWave(gameScreen:GameScreen) : void
      {
         var wave:Array = this.getRebelWaveTypes(gameScreen);
         var refreshEntries:Array = [];
         var unit:Unit = null;
         var goalY:Number = 0;
         var i:int = 0;
         this.activeRebelWaveUnits = [];
         for(i = 0; i < wave.length; i++)
         {
            unit = gameScreen.game.unitFactory.getUnit(int(wave[i]));
            gameScreen.team.enemyTeam.spawn(unit,gameScreen.game);
            goalY = this.getNativeFormationGoalY(gameScreen,i,wave.length);
            unit.px = this.getNativeFormationSpawnX(gameScreen,i);
            unit.x = unit.px;
            unit.py = goalY;
            unit.y = unit.py;
            unit.scaleX *= gameScreen.team.enemyTeam.direction * -1;
            this.issueAmbushAttackCommand(gameScreen,unit,goalY);
            this.activeRebelWaveUnits.push(unit);
            refreshEntries.push([unit,goalY]);
         }
         this.pendingAttackRefreshes.push([gameScreen.game.frame + ATTACK_REFRESH_DELAY_FRAMES,refreshEntries]);
      }

      private function spawnRebelEndingBattle(gameScreen:GameScreen) : void
      {
         var rebelTypes:Array = [Unit.U_SPEARTON,Unit.U_SPEARTON,Unit.U_ARCHER,Unit.U_ARCHER,Unit.U_NINJA,Unit.U_SWORDWRATH,Unit.U_SPEARTON,Unit.U_ARCHER,Unit.U_MAGIKILL,Unit.U_MONK];
         var chaosTypes:Array = [Unit.U_KNIGHT,Unit.U_KNIGHT,Unit.U_DEAD,Unit.U_DEAD,Unit.U_BOMBER,Unit.U_CAT,Unit.U_CAT,Unit.U_WINGIDON,Unit.U_KNIGHT,Unit.U_DEAD];
         var bossTypes:Array = [Unit.U_NINJA,Unit.U_MAGIKILL,Unit.U_SPEARTON];
         var i:int = 0;
         var rebel:Unit = null;
         var chaos:Unit = null;
         if(gameScreen.team.unitGroups[Unit.U_KNIGHT] == null)
         {
            gameScreen.team.unitGroups[Unit.U_KNIGHT] = [];
         }
         if(gameScreen.team.unitGroups[Unit.U_DEAD] == null)
         {
            gameScreen.team.unitGroups[Unit.U_DEAD] = [];
         }
         if(gameScreen.team.unitGroups[Unit.U_BOMBER] == null)
         {
            gameScreen.team.unitGroups[Unit.U_BOMBER] = [];
         }
         if(gameScreen.team.unitGroups[Unit.U_CAT] == null)
         {
            gameScreen.team.unitGroups[Unit.U_CAT] = [];
         }
         if(gameScreen.team.unitGroups[Unit.U_WINGIDON] == null)
         {
            gameScreen.team.unitGroups[Unit.U_WINGIDON] = [];
         }
         for(i = 0; i < rebelTypes.length; i++)
         {
            rebel = this.spawnDisplayUnit(gameScreen,gameScreen.team.enemyTeam,int(rebelTypes[i]),this.getEndingBattleX(gameScreen,i,true),this.getEndingBattleY(gameScreen,i),false,true);
            if(rebel != null)
            {
               rebel.health = Math.max(1,rebel.maxHealth * (i % 3 == 0 ? 0.25 : 0.5));
               rebel.healthBar.health = rebel.health;
               rebel.healthBar.reset();
               this.issueDisplayAttackCommand(gameScreen,rebel,this.getEndingBattleX(gameScreen,i,false),rebel.py);
            }
         }
         for(i = 0; i < chaosTypes.length; i++)
         {
            chaos = this.spawnDisplayUnit(gameScreen,gameScreen.team,int(chaosTypes[i]),this.getEndingBattleX(gameScreen,i,false),this.getEndingBattleY(gameScreen,i + 3),false,true);
            if(chaos != null)
            {
               this.tintUnitRed(chaos);
               this.issueDisplayAttackCommand(gameScreen,chaos,this.getEndingBattleX(gameScreen,i,true),chaos.py);
            }
         }
         for(i = 0; i < bossTypes.length; i++)
         {
            rebel = this.spawnDisplayUnit(gameScreen,gameScreen.team.enemyTeam,int(bossTypes[i]),gameScreen.team.enemyTeam.homeX + gameScreen.team.enemyTeam.direction * (220 + i * 80),gameScreen.game.map.height / 2 + (i - 1) * 70,true,true);
            if(rebel != null)
            {
               this.issueBossEscapeMove(gameScreen,rebel);
            }
         }
      }

      private function getRebelWaveTypes(gameScreen:GameScreen) : Array
      {
         if(gameScreen.main != null && gameScreen.main.campaign != null && gameScreen.main.campaign.difficultyLevel == Campaign.D_INSANE)
         {
            return REBEL_WAVE_INSANE;
         }
         if(gameScreen.main != null && gameScreen.main.campaign != null && gameScreen.main.campaign.difficultyLevel == Campaign.D_HARD)
         {
            return REBEL_WAVE_HARD;
         }
         return REBEL_WAVE_NORMAL;
      }

      private function spawnReinforcements(gameScreen:GameScreen) : void
      {
         var i:int = 0;
         var swordwrath:Swordwrath = null;
         var spearton:Spearton = null;
         var totalCount:int = REINFORCEMENT_SWORDWRATHS + REINFORCEMENT_SPEARTONS;
         var goalY:Number = 0;
         for(i = 0; i < REINFORCEMENT_SWORDWRATHS; i++)
         {
            swordwrath = Swordwrath(gameScreen.game.unitFactory.getUnit(Unit.U_SWORDWRATH));
            gameScreen.team.spawn(swordwrath,gameScreen.game);
            goalY = this.getReinforcementFormationY(gameScreen,i,totalCount);
            swordwrath.px = this.getReinforcementFormationX(gameScreen,i);
            swordwrath.x = swordwrath.px;
            swordwrath.py = goalY;
            swordwrath.y = swordwrath.py;
         }
         for(i = 0; i < REINFORCEMENT_SPEARTONS; i++)
         {
            spearton = Spearton(gameScreen.game.unitFactory.getUnit(Unit.U_SPEARTON));
            gameScreen.team.spawn(spearton,gameScreen.game);
            goalY = this.getReinforcementFormationY(gameScreen,REINFORCEMENT_SWORDWRATHS + i,totalCount);
            spearton.px = this.getReinforcementFormationX(gameScreen,REINFORCEMENT_SWORDWRATHS + i);
            spearton.x = spearton.px;
            spearton.py = goalY;
            spearton.y = spearton.py;
         }
      }

      private function getReinforcementFormationX(gameScreen:GameScreen, formationIndex:int) : Number
      {
         var column:int = int(formationIndex / NATIVE_FORMATION_MAX_ROWS);
         return gameScreen.team.homeX + gameScreen.team.direction * (REINFORCEMENT_BASE_SPAWN_OFFSET + column * NATIVE_FORMATION_COLUMN_SPACING);
      }

      private function getReinforcementFormationY(gameScreen:GameScreen, formationIndex:int, totalCount:int) : Number
      {
         var column:int = int(formationIndex / NATIVE_FORMATION_MAX_ROWS);
         var row:int = formationIndex % NATIVE_FORMATION_MAX_ROWS;
         var rowsInColumn:int = Math.min(NATIVE_FORMATION_MAX_ROWS,totalCount - column * NATIVE_FORMATION_MAX_ROWS);
         var goalY:Number = gameScreen.game.map.height / 2 + (row - (rowsInColumn - 1) / 2) * NATIVE_FORMATION_ROW_SPACING;
         return Math.max(NATIVE_FORMATION_GOAL_PADDING,Math.min(gameScreen.game.map.height - NATIVE_FORMATION_GOAL_PADDING,goalY));
      }

      private function getNativeFormationGoalY(gameScreen:GameScreen, formationIndex:int, totalCount:int) : Number
      {
         var column:int = int(formationIndex / NATIVE_FORMATION_MAX_ROWS);
         var row:int = formationIndex % NATIVE_FORMATION_MAX_ROWS;
         var rowsInColumn:int = Math.min(NATIVE_FORMATION_MAX_ROWS,totalCount - column * NATIVE_FORMATION_MAX_ROWS);
         var goalY:Number = gameScreen.game.map.height / 2 + (row - (rowsInColumn - 1) / 2) * NATIVE_FORMATION_ROW_SPACING;
         return Math.max(NATIVE_FORMATION_GOAL_PADDING,Math.min(gameScreen.game.map.height - NATIVE_FORMATION_GOAL_PADDING,goalY));
      }

      private function getNativeFormationSpawnX(gameScreen:GameScreen, formationIndex:int) : Number
      {
         var column:int = int(formationIndex / NATIVE_FORMATION_MAX_ROWS);
         var row:int = formationIndex % NATIVE_FORMATION_MAX_ROWS;
         return gameScreen.team.enemyTeam.homeX + gameScreen.team.enemyTeam.direction * (NATIVE_BASE_SPAWN_OFFSET + column * NATIVE_FORMATION_COLUMN_SPACING + row * 6);
      }

      private function getEnemyDisplayX(gameScreen:GameScreen, formationIndex:int, totalCount:int) : Number
      {
         var column:int = int(formationIndex / 6);
         var row:int = formationIndex % 6;
         return gameScreen.team.enemyTeam.homeX + gameScreen.team.enemyTeam.direction * (220 + column * 90 + row * 8);
      }

      private function getDisplayY(gameScreen:GameScreen, formationIndex:int, totalCount:int) : Number
      {
         var row:int = formationIndex % 6;
         var column:int = int(formationIndex / 6);
         var rowsInColumn:int = Math.min(6,totalCount - column * 6);
         var goalY:Number = gameScreen.game.map.height / 2 + (row - (rowsInColumn - 1) / 2) * 60 + (column % 2 == 0 ? -15 : 15);
         return Math.max(80,Math.min(gameScreen.game.map.height - 80,goalY));
      }

      private function getEndingBattleX(gameScreen:GameScreen, formationIndex:int, rebelSide:Boolean) : Number
      {
         var spread:Number = (formationIndex % 5) * 110 + int(formationIndex / 5) * 60;
         var baseOffset:Number = rebelSide ? 450 : 850;
         return gameScreen.team.enemyTeam.homeX + gameScreen.team.enemyTeam.direction * (baseOffset + spread);
      }

      private function getEndingBattleY(gameScreen:GameScreen, formationIndex:int) : Number
      {
         var offsets:Array = [-145,-75,30,115,-15,160,-110,75,0,140, -165, 95];
         return Math.max(80,Math.min(gameScreen.game.map.height - 80,gameScreen.game.map.height / 2 + Number(offsets[formationIndex % offsets.length])));
      }

      private function spawnDisplayUnit(gameScreen:GameScreen, spawnTeam:Team, unitType:int, xPos:Number, yPos:Number, makeBoss:Boolean = false, allowAi:Boolean = false) : Unit
      {
         var unit:Unit = null;
         if(spawnTeam == null)
         {
            return null;
         }
         unit = gameScreen.game.unitFactory.getUnit(unitType);
         if(unit == null)
         {
            return null;
         }
         if(unit.mc == null)
         {
            return null;
         }
         spawnTeam.spawn(unit,gameScreen.game);
         unit.px = unit.x = xPos;
         unit.py = unit.y = yPos;
         unit.scaleX *= spawnTeam.direction * -1;
         unit.isBossMovementLocked = !allowAi;
         if(makeBoss)
         {
            this.makeDisplayBoss(unit);
         }
         if(!allowAi)
         {
            this.holdUnit(gameScreen,unit);
         }
         this.rebelDisplayUnits.push(unit);
         return unit;
      }

      private function spawnDisplayUnitRaw(gameScreen:GameScreen, spawnTeam:Team, unitType:int, xPos:Number, yPos:Number, makeBoss:Boolean = false, allowAi:Boolean = false) : Unit
      {
         var unit:Unit = null;
         if(spawnTeam == null)
         {
            return null;
         }
         unit = gameScreen.game.unitFactory.getUnit(unitType);
         if(unit == null)
         {
            return null;
         }
         if(unit.mc == null)
         {
            return null;
         }
         unit.team = spawnTeam;
         unit.setBuilding();
         unit.px = unit.x = xPos;
         unit.py = unit.y = yPos;
         unit.scaleX *= spawnTeam.direction * -1;
         unit.isBossMovementLocked = !allowAi;
         unit.isDead = false;
         unit.isDieing = false;
         unit.init(gameScreen.game);
         gameScreen.game.battlefield.addChildAt(unit,0);
         if(makeBoss)
         {
            this.makeDisplayBoss(unit);
         }
         if(!allowAi)
         {
            this.holdUnit(gameScreen,unit);
         }
         this.rebelDisplayUnits.push(unit);
         return unit;
      }

      private function getDisplayTeam(gameScreen:GameScreen, teamType:int, homeX:int, direction:int, isEnemy:Boolean) : Team
      {
         var displayTeam:Team = Team.getTeamFromId(teamType,gameScreen.game,9999,gameScreen.team.techAllowed);
         displayTeam.homeX = homeX;
         displayTeam.direction = direction;
         displayTeam.isEnemy = isEnemy;
         displayTeam.enemyTeam = gameScreen.team.enemyTeam;
         return displayTeam;
      }

      private function makeDisplayBoss(unit:Unit) : void
      {
         if(unit is Spearton)
         {
            Spearton(unit).makeBoss();
         }
         else if(unit is Archer)
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

      private function tintUnitRed(unit:Unit) : void
      {
         var color:ColorTransform = null;
         if(unit == null || unit.mc == null)
         {
            return;
         }
         color = unit.mc.transform.colorTransform;
         color.redOffset = 75;
         color.greenOffset = 0;
         color.blueOffset = 0;
         unit.mc.transform.colorTransform = color;
      }

      private function issueDisplayAttackCommand(gameScreen:GameScreen, unit:Unit, goalX:Number, goalY:Number) : void
      {
         var attackMoveCommand:AttackMoveCommand = null;
         if(unit == null || unit.ai == null)
         {
            return;
         }
         attackMoveCommand = new AttackMoveCommand(gameScreen.game);
         attackMoveCommand.type = UnitCommand.ATTACK_MOVE;
         attackMoveCommand.goalX = goalX;
         attackMoveCommand.goalY = goalY;
         attackMoveCommand.realX = goalX;
         attackMoveCommand.realY = goalY;
         unit.ai.setCommand(gameScreen.game,attackMoveCommand);
      }

      private function issueBossEscapeMove(gameScreen:GameScreen, unit:Unit) : void
      {
         var moveCommand:MoveCommand = null;
         if(unit == null || unit.ai == null)
         {
            return;
         }
         moveCommand = new MoveCommand(gameScreen.game);
         moveCommand.type = UnitCommand.MOVE;
         moveCommand.goalX = gameScreen.team.enemyTeam.homeX + gameScreen.team.enemyTeam.direction * 80;
         moveCommand.goalY = unit.py;
         moveCommand.realX = moveCommand.goalX;
         moveCommand.realY = moveCommand.goalY;
         unit.ai.setCommand(gameScreen.game,moveCommand);
      }

      private function hasLivingActiveNativeWaveUnits() : Boolean
      {
         var i:int = 0;
         var unit:Unit = null;
         while(i < this.activeNativeWaveUnits.length)
         {
            unit = this.activeNativeWaveUnits[i] as Unit;
            if(unit == null || !unit.isAlive())
            {
               this.activeNativeWaveUnits.splice(i,1);
               continue;
            }
            return true;
         }
         return false;
      }

      private function hasLivingActiveStalkWaveUnits() : Boolean
      {
         var i:int = 0;
         var unit:Unit = null;
         while(i < this.activeStalkWaveUnits.length)
         {
            unit = this.activeStalkWaveUnits[i] as Unit;
            if(unit == null || !unit.isAlive())
            {
               this.activeStalkWaveUnits.splice(i,1);
               continue;
            }
            return true;
         }
         return false;
      }

      private function hasLivingActiveRebelWaveUnits() : Boolean
      {
         var i:int = 0;
         var unit:Unit = null;
         while(i < this.activeRebelWaveUnits.length)
         {
            unit = this.activeRebelWaveUnits[i] as Unit;
            if(unit == null || !unit.isAlive())
            {
               this.activeRebelWaveUnits.splice(i,1);
               continue;
            }
            return true;
         }
         return false;
      }

      private function hasSpawnedAllAmbushWaves(gameScreen:GameScreen) : Boolean
      {
         if(this.isNativeTribesLevel(gameScreen))
         {
            return this.nativeWaveIndex >= NATIVE_WAVE_TIMES.length;
         }
         if(this.isShadowrathStalkersLevel(gameScreen))
         {
            return this.stalkWaveIndex >= STALK_WAVE_TIMES.length;
         }
         if(this.isRebelBreakLevel(gameScreen))
         {
            return this.rebelWaveSpawned;
         }
         return true;
      }
      
      private function updatePendingAttackRefreshes(gameScreen:GameScreen) : void
      {
         var i:int = 0;
         var j:int = 0;
         var refresh:Array = null;
         var refreshEntries:Array = null;
         var entry:Array = null;
         while(i < this.pendingAttackRefreshes.length)
         {
            refresh = this.pendingAttackRefreshes[i];
            if(gameScreen.game.frame < int(refresh[0]))
            {
               ++i;
               continue;
            }
            refreshEntries = refresh[1];
            for(j = 0; j < refreshEntries.length; j++)
            {
               entry = refreshEntries[j];
               if(entry != null && entry[0] != null && Unit(entry[0]).isAlive())
               {
                  this.issueAmbushAttackCommand(gameScreen,Unit(entry[0]),Number(entry[1]));
               }
            }
            this.pendingAttackRefreshes.splice(i,1);
         }
      }
      
      private function isNativeTribesLevel(gameScreen:GameScreen) : Boolean
      {
         return gameScreen.main != null && gameScreen.main.campaign != null && gameScreen.main.campaign.getCurrentLevel() != null && gameScreen.main.campaign.getCurrentLevel().title == LEVEL_NATIVE_TRIBES;
      }

      private function isShadowrathStalkersLevel(gameScreen:GameScreen) : Boolean
      {
         return gameScreen.main != null && gameScreen.main.campaign != null && gameScreen.main.campaign.getCurrentLevel() != null && gameScreen.main.campaign.getCurrentLevel().title == LEVEL_SHADOWRATH_STALKERS;
      }

      private function isRebelBreakLevel(gameScreen:GameScreen) : Boolean
      {
         return gameScreen.main != null && gameScreen.main.campaign != null && gameScreen.main.campaign.getCurrentLevel() != null && gameScreen.main.campaign.getCurrentLevel().title == LEVEL_REBELS_BREAK;
      }

      private function shouldShowStartMessage(gameScreen:GameScreen) : Boolean
      {
         return this.isNativeTribesLevel(gameScreen) || this.isShadowrathStalkersLevel(gameScreen);
      }

      private function showAmbushMessage(gameScreen:GameScreen, text:String) : void
      {
         if(this.message != null && gameScreen.contains(this.message))
         {
            gameScreen.removeChild(this.message);
         }
         this.message = new InGameMessage("",gameScreen.game);
         this.message.x = gameScreen.game.stage.stageWidth / 2;
         this.message.y = gameScreen.game.stage.stageHeight / 4 - 75;
         this.message.scaleX *= 1.3;
         this.message.scaleY *= 1.3;
         this.message.setMessage(text,"");
         gameScreen.addChild(this.message);
         this.messageStartFrame = gameScreen.game.frame;
      }

      private function cleanupRebelDisplayUnits(gameScreen:GameScreen) : void
      {
         var unit:Unit = null;
         while(this.rebelDisplayUnits.length > 0)
         {
            unit = this.rebelDisplayUnits.pop() as Unit;
            if(unit != null && unit.isAlive())
            {
               if(unit is Magikill && Magikill(unit).isBoss)
               {
                  unit.damage(Unit.D_NO_SOUND | Unit.D_NO_BLOOD,unit.maxHealth * 2,null);
               }
               else
               {
                  unit.team.removeUnitCompletely(unit,gameScreen.game);
               }
            }
         }
      }

      private function killAllEnemyUnits(gameScreen:GameScreen) : void
      {
         var unit:Unit = null;
         var snapshot:Array = null;
         if(gameScreen.team == null || gameScreen.team.enemyTeam == null)
         {
            return;
         }
         snapshot = gameScreen.team.enemyTeam.units.concat();
         for each(unit in snapshot)
         {
            if(unit != null && unit.isAlive() && unit.type != Unit.U_STATUE)
            {
               if(unit is Magikill && Magikill(unit).isBoss)
               {
                  unit.damage(Unit.D_NO_SOUND | Unit.D_NO_BLOOD,unit.maxHealth * 2,null);
               }
               else
               {
                  gameScreen.team.enemyTeam.removeUnitCompletely(unit,gameScreen.game);
               }
            }
         }
      }

      private function setCameraTarget(gameScreen:GameScreen, targetX:Number) : void
      {
         if(gameScreen.game.background != null)
         {
            targetX = Math.max(gameScreen.game.background.minScreenX(),Math.min(gameScreen.game.background.maxScreenX(),targetX));
         }
         gameScreen.game.targetScreenX = targetX;
      }

      private function getEnemyCameraX(gameScreen:GameScreen) : Number
      {
         return gameScreen.team.enemyTeam.homeX + gameScreen.team.enemyTeam.direction * gameScreen.game.map.screenWidth;
      }

      private function getPlayerCameraX(gameScreen:GameScreen) : Number
      {
         return gameScreen.team.homeX - gameScreen.team.direction * gameScreen.game.map.screenWidth;
      }
      
      private function stopSpawnedPlayerUnits(gameScreen:GameScreen) : void
      {
         var unit:Unit = null;
         if(!this.isRebelBreakLevel(gameScreen) || this.rebelEndingStarted)
         {
            return;
         }
         for each(unit in gameScreen.team.units)
         {
            if(unit != null && unit.isAlive() && unit.type != Unit.U_MINER && unit.ai.currentCommand.type == UnitCommand.ATTACK_MOVE && unit.px < gameScreen.team.homeX + gameScreen.team.direction * 200)
            {
               this.holdUnit(gameScreen,unit);
            }
         }
      }

      private function holdUnit(gameScreen:GameScreen, unit:Unit) : void
      {
         var holdCommand:HoldCommand = null;
         if(unit.ai == null)
         {
            return;
         }
         holdCommand = new HoldCommand(gameScreen.game);
         unit.ai.setCommand(gameScreen.game,holdCommand);
      }

      private function clearEnemyStartingCombatUnits(gameScreen:GameScreen) : void
      {
         var unit:Unit = null;
         var snapshot:Array = null;
         if(gameScreen.team == null || gameScreen.team.enemyTeam == null)
         {
            return;
         }
         snapshot = gameScreen.team.enemyTeam.units.concat();
         for each(unit in snapshot)
         {
            if(unit != null && unit.type != Unit.U_STATUE && unit.type != Unit.U_CHAOS_TOWER)
            {
               gameScreen.team.enemyTeam.population = Math.max(0,gameScreen.team.enemyTeam.population - unit.population);
               gameScreen.team.enemyTeam.removeUnitCompletely(unit,gameScreen.game);
            }
         }
      }
      
      private function hasLivingEnemyCombatUnits(gameScreen:GameScreen) : Boolean
      {
         var unit:Unit = null;
         for each(unit in gameScreen.team.enemyTeam.units)
         {
            if(unit != null && unit.isAlive() && unit.type != Unit.U_MINER && unit.type != Unit.U_CHAOS_MINER && unit.type != Unit.U_CHAOS_TOWER)
            {
               return true;
            }
         }
         return false;
      }
      
      private function completeAmbush(gameScreen:GameScreen) : void
      {
         if(gameScreen.game.gameOver)
         {
            return;
         }
         gameScreen.game.winner = gameScreen.team;
         gameScreen.game.gameOver = true;
      }
   }
}
