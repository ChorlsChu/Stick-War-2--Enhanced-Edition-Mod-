package com.brockw.stickwar.campaign.controllers
{
   import com.brockw.stickwar.GameScreen;
   import com.brockw.stickwar.campaign.Campaign;
   import com.brockw.stickwar.campaign.*;
   import com.brockw.stickwar.engine.Ai.*;
   import com.brockw.stickwar.engine.Ai.command.*;
   import com.brockw.stickwar.engine.StickWar;
   import com.brockw.stickwar.engine.Team.*;
   import com.brockw.stickwar.engine.multiplayer.moves.*;
   import com.brockw.stickwar.engine.units.*;
   import flash.utils.Dictionary;
   
   public class CampaignCutScene2 extends CampaignController
   {
      
      private static const S_BEFORE_CUTSCENE:int = -1;
      
      private static const S_ENTER_MEDUSA:int = 0;
      
      private static const S_MEDUSA_YOU_MUST_ALL_DIE:int = 1;
      
      private static const S_SCROLLING_STONE:int = 2;
      
      private static const S_DONE:int = 3;
      
      private static const S_WAIT_FOR_END:int = 4;

      private static const PHASE_HIGH:int = 0;

      private static const PHASE_MID:int = 1;

      private static const PHASE_LOW:int = 2;

      private static const MID_PHASE_HP_THRESHOLD:Number = 0.66;

      private static const LOW_PHASE_HP_THRESHOLD:Number = 0.33;

      private static const HIGH_PHASE_SUMMON_DELAY:int = 30 * 55;

      private static const MID_PHASE_SUMMON_DELAY:int = 30 * 45;

      private static const LOW_PHASE_SUMMON_DELAY:int = 30 * 65;

      private static const MEDUSA_SUMMON_CAP:int = 8;

      private static const MEDUSA_SUMMON_CLEANUP_INTERVAL:int = 30;

      private static const MEDUSA_ENGAGEMENT_CHECK_INTERVAL:int = 10;

      private static const MEDUSA_REVEAL_MUSIC_START_MS:Number = 155000;

      private static const MEDUSA_DISTANT_RETREAT_FRAMES:int = 15;

      private var state:int;
      
      private var counter:int = 0;
      
      private var message:InGameMessage;
      
      private var scrollingStoneX:Number;
      
      private var gameScreen:GameScreen;
      
      private var medusa:Unit;

      private var medusaPhase:int;

      private var nextSummonFrame:int;

      private var hasMidPhaseTransitionWave:Boolean;

      private var hasLowPhaseTransitionWave:Boolean;

      private var medusaSummons:Dictionary;

      private var hasIssuedBossAttack:Boolean;

      private var activeMedusaSummonCount:int;

      private var activeMedusaDistantSummonCount:int;

      private var nextSummonCleanupFrame:int;

      private var isMedusaEngaged:Boolean;

      private var nextEngagementCheckFrame:int;

      private var medusaDistantRetreatUntilFrame:int;
      
      public function CampaignCutScene2(gameScreen:GameScreen)
      {
         super(gameScreen);
         this.gameScreen = gameScreen;
         this.state = S_BEFORE_CUTSCENE;
         this.counter = 0;
         this.medusa = null;
         this.medusaPhase = PHASE_HIGH;
         this.nextSummonFrame = 0;
         this.hasMidPhaseTransitionWave = false;
         this.hasLowPhaseTransitionWave = false;
         this.medusaSummons = new Dictionary();
         this.hasIssuedBossAttack = false;
         this.activeMedusaSummonCount = 0;
         this.activeMedusaDistantSummonCount = 0;
         this.nextSummonCleanupFrame = 0;
         this.isMedusaEngaged = false;
         this.nextEngagementCheckFrame = 0;
         this.medusaDistantRetreatUntilFrame = 0;
      }
      
      override public function update(gameScreen:GameScreen) : void
      {
         var u1:Unit = null;
         var attackMoveCommand:AttackMoveCommand = null;
         var m:StandCommand = null;
         var freezePoint:Number = NaN;
         var spawn:Array = null;
         var numToSpawn:int = 0;
         var i:int = 0;
         if(Boolean(this.message))
         {
            this.message.update();
         }
         if(this.state != S_BEFORE_CUTSCENE)
         {
            gameScreen.team.enemyTeam.statue.health = 750;
            gameScreen.team.enemyTeam.gold = 0;
            gameScreen.team.enemyTeam.mana = 200;
            gameScreen.userInterface.hud.hud.fastForward.visible = false;
            gameScreen.isFastForward = false;
         }
         else
         {
            gameScreen.userInterface.hud.hud.fastForward.visible = true;
         }
         if(this.state == S_BEFORE_CUTSCENE)
         {
            if(gameScreen.team.enemyTeam.statue.health < 750)
            {
               gameScreen.game.targetScreenX = gameScreen.game.team.enemyTeam.statue.x - 325;
               gameScreen.game.screenX = gameScreen.game.team.enemyTeam.statue.x - 325;
               gameScreen.userInterface.isSlowCamera = true;
               u1 = Medusa(gameScreen.game.unitFactory.getUnit(Unit.U_MEDUSA));
               this.medusa = u1;
               gameScreen.team.enemyTeam.spawn(u1,gameScreen.game);
               Medusa(u1).enableSuperMedusa();
               u1.pz = 0;
               u1.y = gameScreen.game.map.height / 2;
               u1.px = gameScreen.team.enemyTeam.homeX - 200;
               u1.x = u1.px;
               m = new StandCommand(gameScreen.game);
               u1.ai.setCommand(gameScreen.game,m);
               if(!gameScreen.game.soundManager.isBackgroundAtOrPast("battleOfTheShadowElves",MEDUSA_REVEAL_MUSIC_START_MS))
               {
                  gameScreen.game.soundManager.playSoundInBackground("battleOfTheShadowElves",MEDUSA_REVEAL_MUSIC_START_MS);
               }
               else
               {
                  gameScreen.game.soundManager.playCurrentBackgroundOnceFromCurrentPosition("battleOfTheShadowElves");
               }
               Medusa(this.medusa).stone(null);
               this.state = S_ENTER_MEDUSA;
               this.counter = 0;
            }
         }
         else if(this.state == S_ENTER_MEDUSA)
         {
            m = new StandCommand(gameScreen.game);
            this.medusa.ai.setCommand(gameScreen.game,m);
            gameScreen.game.fogOfWar.isFogOn = false;
            gameScreen.game.targetScreenX = gameScreen.game.team.enemyTeam.statue.x - 325;
            gameScreen.game.screenX = gameScreen.game.team.enemyTeam.statue.x - 325;
            if(this.counter++ > 60)
            {
               Medusa(this.medusa).prepareBossRevealStone();
               Medusa(this.medusa).stone(null);
               this.state = S_MEDUSA_YOU_MUST_ALL_DIE;
               this.counter = 0;
               gameScreen.game.soundManager.playSoundFullVolume("youMustAllDie");
            }
         }
         else if(this.state == S_MEDUSA_YOU_MUST_ALL_DIE)
         {
            gameScreen.game.targetScreenX = gameScreen.game.team.enemyTeam.statue.x - 325;
            gameScreen.game.screenX = gameScreen.game.team.enemyTeam.statue.x - 325;
            if(this.counter++ > 100)
            {
               this.state = S_SCROLLING_STONE;
               this.scrollingStoneX = gameScreen.game.team.enemyTeam.statue.x - 325;
            }
         }
         else if(this.state == S_SCROLLING_STONE)
         {
            gameScreen.game.targetScreenX = this.scrollingStoneX;
            gameScreen.game.screenX = this.scrollingStoneX;
            if(gameScreen.game.targetScreenX < gameScreen.game.team.statue.px - 300)
            {
               gameScreen.game.targetScreenX = gameScreen.game.team.statue.px - 300;
            }
            this.scrollingStoneX -= 20;
            freezePoint = this.scrollingStoneX + gameScreen.game.map.screenWidth / 2;
            gameScreen.game.spatialHash.mapInArea(freezePoint - 100,0,freezePoint + 100,gameScreen.game.map.height,this.freezeUnit);
            if(freezePoint < gameScreen.team.homeX)
            {
               this.state = S_DONE;
               attackMoveCommand = new AttackMoveCommand(gameScreen.game);
               attackMoveCommand.type = UnitCommand.ATTACK_MOVE;
               attackMoveCommand.goalX = gameScreen.team.statue.px;
               attackMoveCommand.goalY = gameScreen.game.map.height / 2;
               attackMoveCommand.realX = gameScreen.team.statue.px;
               attackMoveCommand.realY = gameScreen.game.map.height / 2;
               this.medusa.ai.setCommand(gameScreen.game,attackMoveCommand);
               this.hasIssuedBossAttack = true;
               this.medusaPhase = this.getMedusaPhase();
               this.nextSummonFrame = gameScreen.game.frame;
               this.hasMidPhaseTransitionWave = false;
               this.hasLowPhaseTransitionWave = false;
               this.medusaSummons = new Dictionary();
               this.activeMedusaSummonCount = 0;
               this.activeMedusaDistantSummonCount = 0;
               this.nextSummonCleanupFrame = gameScreen.game.frame + MEDUSA_SUMMON_CLEANUP_INTERVAL;
               this.isMedusaEngaged = false;
               this.nextEngagementCheckFrame = gameScreen.game.frame;
               this.medusaDistantRetreatUntilFrame = 0;
               spawn = this.getPlayerReinforcementWave(gameScreen);
               gameScreen.team.spawnUnitGroup(spawn);
               gameScreen.game.soundManager.playSoundInBackground("fieldOfMemories");
               gameScreen.game.soundManager.playSoundFullVolumeRandom("Rage",3);
               gameScreen.game.soundManager.playSoundFullVolumeRandom("Rage",3);
               gameScreen.game.soundManager.playSoundFullVolumeRandom("Rage",3);
               gameScreen.game.soundManager.playSoundFullVolumeRandom("Rage",3);
            }
         }
         if(this.state == S_DONE)
         {
            if(!this.medusa.isAlive())
            {
               this.onMedusaBossDied();
            }
            else
            {
               this.updateMedusaBossFight(gameScreen);
            }
         }
         else if(this.state == S_WAIT_FOR_END)
         {
            if(this.counter++ == 30 * 4)
            {
               gameScreen.team.enemyTeam.statue.health = 0;
            }
         }
         super.update(gameScreen);
      }
      
      private function freezeUnit(u:Unit) : void
      {
         if(u.team == this.gameScreen.team && !(u is Statue))
         {
            u.stoneAttack(10000);
         }
      }

      private function getPlayerReinforcementWave(gameScreen:GameScreen) : Array
      {
         var spawn:Array = [];
         if(gameScreen.main.campaign.difficultyLevel == Campaign.D_INSANE)
         {
            this.addInsaneReinforcementIfFits(gameScreen,spawn,Unit.U_ENSLAVED_GIANT,1);
            this.addInsaneReinforcementIfFits(gameScreen,spawn,Unit.U_MAGIKILL,1);
            this.addInsaneReinforcementIfFits(gameScreen,spawn,Unit.U_MONK,1);
            this.addInsaneReinforcementIfFits(gameScreen,spawn,Unit.U_SPEARTON,4);
            this.addInsaneReinforcementIfFits(gameScreen,spawn,Unit.U_MINER,4);
            return spawn;
         }
         if(gameScreen.main.campaign.difficultyLevel == Campaign.D_HARD)
         {
            this.addReinforcements(spawn,Unit.U_MINER,4);
            this.addReinforcements(spawn,Unit.U_SPEARTON,4);
            this.addReinforcements(spawn,Unit.U_MAGIKILL,1);
            this.addReinforcements(spawn,Unit.U_MONK,1);
            this.addReinforcements(spawn,Unit.U_ENSLAVED_GIANT,1);
            return spawn;
         }
         this.addReinforcements(spawn,Unit.U_MINER,6);
         this.addReinforcements(spawn,Unit.U_SPEARTON,6);
         this.addReinforcements(spawn,Unit.U_MAGIKILL,1);
         this.addReinforcements(spawn,Unit.U_MONK,1);
         this.addReinforcements(spawn,Unit.U_ENSLAVED_GIANT,1);
         return spawn;
      }

      private function addReinforcements(spawn:Array, unitType:int, count:int) : void
      {
         var i:int = 0;
         for(i = 0; i < count; i++)
         {
            spawn.push(unitType);
         }
      }

      private function addInsaneReinforcementIfFits(gameScreen:GameScreen, spawn:Array, unitType:int, count:int) : void
      {
         var i:int = 0;
         var unitPopulation:int = this.getPlayerReinforcementPopulation(gameScreen,unitType);
         var populationLimit:int = int(gameScreen.game.xml.xml.populationLimit);
         var projectedPopulation:int = gameScreen.team.population + this.getSpawnPopulation(gameScreen,spawn);
         for(i = 0; i < count; i++)
         {
            if(projectedPopulation + unitPopulation > populationLimit)
            {
               continue;
            }
            spawn.push(unitType);
            projectedPopulation += unitPopulation;
         }
      }

      private function getSpawnPopulation(gameScreen:GameScreen, spawn:Array) : int
      {
         var unitType:int = 0;
         var total:int = 0;
         for each(unitType in spawn)
         {
            total += this.getPlayerReinforcementPopulation(gameScreen,unitType);
         }
         return total;
      }

      private function getPlayerReinforcementPopulation(gameScreen:GameScreen, unitType:int) : int
      {
         if(unitType == Unit.U_MINER)
         {
            return int(gameScreen.game.xml.xml.Order.Units.miner.population);
         }
         if(unitType == Unit.U_SPEARTON)
         {
            return int(gameScreen.game.xml.xml.Order.Units.spearton.population);
         }
         if(unitType == Unit.U_MAGIKILL)
         {
            return int(gameScreen.game.xml.xml.Order.Units.magikill.population);
         }
         if(unitType == Unit.U_MONK)
         {
            return int(gameScreen.game.xml.xml.Order.Units.monk.population);
         }
         if(unitType == Unit.U_ENSLAVED_GIANT)
         {
            return int(gameScreen.game.xml.xml.Order.Units.giant.population);
         }
         return 0;
      }

      public function isMedusaRevealStoneLocked() : Boolean
      {
         return this.state == S_ENTER_MEDUSA || this.state == S_MEDUSA_YOU_MUST_ALL_DIE;
      }

      public function isMedusaLookAtMeActive() : Boolean
      {
         return this.state == S_DONE && this.medusa != null && this.medusa.isAlive();
      }

      public function isMedusaDistantPhaseActive() : Boolean
      {
         return this.state == S_DONE && this.activeMedusaDistantSummonCount > 0;
      }

      public function shouldMedusaDistantRetreat() : Boolean
      {
         return this.isMedusaDistantPhaseActive() && this.gameScreen.game.frame < this.medusaDistantRetreatUntilFrame;
      }

      private function updateMedusaBossFight(gameScreen:GameScreen) : void
      {
         if(this.medusa == null || !this.medusa.isAlive())
         {
            return;
         }
         if(gameScreen.game.frame >= this.nextSummonCleanupFrame)
         {
            this.cleanupMedusaSummons(gameScreen.game);
            this.nextSummonCleanupFrame = gameScreen.game.frame + MEDUSA_SUMMON_CLEANUP_INTERVAL;
         }
         if(gameScreen.game.frame >= this.nextEngagementCheckFrame)
         {
            this.isMedusaEngaged = this.getIsMedusaEngaged();
            this.nextEngagementCheckFrame = gameScreen.game.frame + MEDUSA_ENGAGEMENT_CHECK_INTERVAL;
         }
         if(!this.isMedusaEngaged)
         {
            return;
         }
         if(gameScreen.game.frame < this.nextSummonFrame)
         {
            return;
         }
         if(this.activeMedusaSummonCount >= MEDUSA_SUMMON_CAP)
         {
            this.nextSummonFrame = gameScreen.game.frame + 30 * 5;
            return;
         }
         if(this.medusaPhase == PHASE_HIGH)
         {
            this.spawnMedusaWave(gameScreen,this.getHighPhaseWave());
         }
         else if(this.medusaPhase == PHASE_MID)
         {
            this.spawnMedusaWave(gameScreen,this.getMidPhaseWave());
         }
         else
         {
            this.spawnMedusaWave(gameScreen,this.getLowPhaseRepeatWave());
         }
         this.nextSummonFrame = gameScreen.game.frame + this.getSummonDelayForPhase(this.medusaPhase);
      }

      private function getHighPhaseWave() : Array
      {
         if(this.gameScreen.main.campaign.difficultyLevel == Campaign.D_NORMAL)
         {
            return [Unit.U_CAT,Unit.U_CAT,Unit.U_CAT,Unit.U_CAT,Unit.U_BOMBER];
         }
         if(this.gameScreen.main.campaign.difficultyLevel == Campaign.D_INSANE)
         {
            return [Unit.U_CAT,Unit.U_CAT,Unit.U_CAT,Unit.U_CAT,Unit.U_CAT,Unit.U_CAT,Unit.U_BOMBER,Unit.U_BOMBER,Unit.U_BOMBER];
         }
         return [Unit.U_CAT,Unit.U_CAT,Unit.U_CAT,Unit.U_CAT,Unit.U_CAT,Unit.U_CAT,Unit.U_BOMBER,Unit.U_BOMBER];
      }

      private function getMidPhaseWave() : Array
      {
         if(this.gameScreen.main.campaign.difficultyLevel == Campaign.D_NORMAL)
         {
            return [Unit.U_KNIGHT,Unit.U_KNIGHT,Unit.U_DEAD];
         }
         if(this.gameScreen.main.campaign.difficultyLevel == Campaign.D_INSANE)
         {
            return [Unit.U_KNIGHT,Unit.U_KNIGHT,Unit.U_KNIGHT,Unit.U_KNIGHT,Unit.U_KNIGHT,Unit.U_DEAD,Unit.U_DEAD];
         }
         return [Unit.U_KNIGHT,Unit.U_KNIGHT,Unit.U_KNIGHT,Unit.U_KNIGHT,Unit.U_DEAD,Unit.U_DEAD];
      }

      private function getLowPhaseTransitionWave() : Array
      {
         if(this.gameScreen.main.campaign.difficultyLevel == Campaign.D_NORMAL)
         {
            return [Unit.U_KNIGHT,Unit.U_KNIGHT,Unit.U_SKELATOR,Unit.U_WINGIDON];
         }
         if(this.gameScreen.main.campaign.difficultyLevel == Campaign.D_INSANE)
         {
            return [Unit.U_KNIGHT,Unit.U_KNIGHT,Unit.U_KNIGHT,Unit.U_KNIGHT,Unit.U_SKELATOR,Unit.U_GIANT,Unit.U_WINGIDON,Unit.U_WINGIDON,Unit.U_DEAD,Unit.U_DEAD,Unit.U_BOMBER,Unit.U_BOMBER];
         }
         return [Unit.U_KNIGHT,Unit.U_KNIGHT,Unit.U_KNIGHT,Unit.U_KNIGHT,Unit.U_SKELATOR,Unit.U_GIANT,Unit.U_WINGIDON,Unit.U_WINGIDON];
      }

      private function getLowPhaseRepeatWave() : Array
      {
         if(this.gameScreen.main.campaign.difficultyLevel == Campaign.D_NORMAL)
         {
            return [Unit.U_KNIGHT,Unit.U_BOMBER];
         }
         if(this.gameScreen.main.campaign.difficultyLevel == Campaign.D_INSANE)
         {
            return [Unit.U_KNIGHT,Unit.U_KNIGHT,Unit.U_SKELATOR,Unit.U_DEAD];
         }
         return [Unit.U_KNIGHT,Unit.U_WINGIDON,Unit.U_WINGIDON];
      }

      private function spawnMedusaWave(gameScreen:GameScreen, unitTypes:Array, ignoreCap:Boolean = false) : void
      {
         var i:int = 0;
         var unitType:int = 0;
         var newUnit:Unit = null;
         var attackMoveCommand:AttackMoveCommand = null;
         var frontDepth:Number = NaN;
         var row:int = 0;
         var column:int = 0;
         var rowCount:int = 0;
         var yOffset:Number = NaN;
         var xPos:Number = NaN;
         var yPos:Number = NaN;
         if(this.medusa == null || !this.medusa.isAlive())
         {
            return;
         }
         if(!ignoreCap && this.activeMedusaSummonCount >= MEDUSA_SUMMON_CAP)
         {
            return;
         }
         this.medusa.triggerBossFallback();
         gameScreen.game.soundManager.playSoundFullVolumeRandom("GhostTower",2);
         for(i = 0; i < unitTypes.length; i++)
         {
            if(!ignoreCap && this.activeMedusaSummonCount >= MEDUSA_SUMMON_CAP)
            {
               return;
            }
            unitType = unitTypes[i];
            newUnit = gameScreen.game.unitFactory.getUnit(unitType);
            gameScreen.team.enemyTeam.spawn(newUnit,gameScreen.game);
            row = i < 4 ? 0 : 1;
            column = i % 4;
            rowCount = Math.min(4,unitTypes.length - row * 4);
            frontDepth = row == 0 ? 110 : 190;
            yOffset = (column - (rowCount - 1) / 2) * 75 + (row == 1 ? 35 : 0);
            xPos = this.medusa.px - gameScreen.team.enemyTeam.direction * frontDepth;
            yPos = Math.max(80,Math.min(gameScreen.game.map.height - 80,this.medusa.py + yOffset));
            newUnit.x = newUnit.px = xPos;
            newUnit.y = newUnit.py = yPos;
            newUnit.isTowerSpawned = true;
            newUnit.suppressTowerSpawnVisual = true;
            gameScreen.team.enemyTeam.population += newUnit.population;
            attackMoveCommand = new AttackMoveCommand(gameScreen.game);
            attackMoveCommand.type = UnitCommand.ATTACK_MOVE;
            attackMoveCommand.goalX = gameScreen.team.statue.px;
            attackMoveCommand.goalY = gameScreen.game.map.height / 2;
            attackMoveCommand.realX = gameScreen.team.statue.px;
            attackMoveCommand.realY = gameScreen.game.map.height / 2;
            newUnit.ai.setCommand(gameScreen.game,attackMoveCommand);
            this.medusaSummons[newUnit.id] = unitType;
            ++this.activeMedusaSummonCount;
            if(unitType != Unit.U_WINGIDON)
            {
               ++this.activeMedusaDistantSummonCount;
            }
            gameScreen.game.projectileManager.initTowerSpawn(xPos,yPos,gameScreen.team.enemyTeam,0.6);
            gameScreen.game.projectileManager.initSpawnDrip(xPos,yPos,gameScreen.team.enemyTeam);
         }
      }

      private function cleanupMedusaSummons(game:StickWar) : void
      {
         var id:* = undefined;
         var summon:Unit = null;
         var summonType:int = 0;
         for(id in this.medusaSummons)
         {
            summonType = int(this.medusaSummons[id]);
            if(!(id in game.units))
            {
               delete this.medusaSummons[id];
               if(this.activeMedusaSummonCount > 0)
               {
                  --this.activeMedusaSummonCount;
               }
               if(summonType != Unit.U_WINGIDON && this.activeMedusaDistantSummonCount > 0)
               {
                  --this.activeMedusaDistantSummonCount;
               }
            }
            else
            {
               summon = game.units[id];
               if(summon == null || !summon.isAlive() || summon.team != this.gameScreen.team.enemyTeam)
               {
                  delete this.medusaSummons[id];
                  if(this.activeMedusaSummonCount > 0)
                  {
                     --this.activeMedusaSummonCount;
                  }
                  if(summonType != Unit.U_WINGIDON && this.activeMedusaDistantSummonCount > 0)
                  {
                     --this.activeMedusaDistantSummonCount;
                  }
               }
            }
         }
      }

      private function getMedusaPhase() : int
      {
         var healthPercent:Number = 1;
         if(this.medusa == null || this.medusa.maxHealth <= 0)
         {
            return PHASE_HIGH;
         }
         healthPercent = this.medusa.health / this.medusa.maxHealth;
         if(healthPercent <= LOW_PHASE_HP_THRESHOLD)
         {
            return PHASE_LOW;
         }
         if(healthPercent <= MID_PHASE_HP_THRESHOLD)
         {
            return PHASE_MID;
         }
         return PHASE_HIGH;
      }

      private function getSummonDelayForPhase(phase:int) : int
      {
         if(phase == PHASE_HIGH)
         {
            return HIGH_PHASE_SUMMON_DELAY;
         }
         if(phase == PHASE_MID)
         {
            return MID_PHASE_SUMMON_DELAY;
         }
         return LOW_PHASE_SUMMON_DELAY;
      }

      private function getIsMedusaEngaged() : Boolean
      {
         var target:Unit = null;
         if(this.medusa == null || !this.medusa.isAlive())
         {
            return false;
         }
         target = this.medusa.ai.getClosestTarget();
         return target != null && Math.abs(target.px - this.medusa.px) <= 1200;
      }

      public function onMedusaBossDamaged(previousHealth:Number, currentHealth:Number) : void
      {
         var phase:int = 0;
         if(this.state != S_DONE || this.medusa == null || currentHealth <= 0 || currentHealth >= previousHealth)
         {
            return;
         }
         phase = this.getMedusaPhase();
         if(phase != this.medusaPhase)
         {
            this.medusaPhase = phase;
            this.nextSummonFrame = this.gameScreen.game.frame + this.getSummonDelayForPhase(phase);
            if(phase == PHASE_MID && !this.hasMidPhaseTransitionWave)
            {
               this.hasMidPhaseTransitionWave = true;
               this.spawnMedusaWave(this.gameScreen,this.getMidPhaseWave(),true);
            }
            else if(phase == PHASE_LOW && !this.hasLowPhaseTransitionWave)
            {
               this.hasLowPhaseTransitionWave = true;
               this.spawnMedusaWave(this.gameScreen,this.getLowPhaseTransitionWave(),true);
            }
         }
         if(this.isMedusaDistantPhaseActive())
         {
            this.medusaDistantRetreatUntilFrame = this.gameScreen.game.frame + MEDUSA_DISTANT_RETREAT_FRAMES;
         }
      }

      public function onMedusaBossDied() : void
      {
         if(this.state != S_DONE)
         {
            return;
         }
         this.state = S_WAIT_FOR_END;
         this.counter = 0;
         this.isMedusaEngaged = false;
      }

      public function onTrackedMedusaSummonRemoved(unit:Unit) : void
      {
         var summonType:int = 0;
         if(unit == null || !(unit.id in this.medusaSummons))
         {
            return;
         }
         summonType = int(this.medusaSummons[unit.id]);
         delete this.medusaSummons[unit.id];
         if(this.activeMedusaSummonCount > 0)
         {
            --this.activeMedusaSummonCount;
         }
         if(summonType != Unit.U_WINGIDON && this.activeMedusaDistantSummonCount > 0)
         {
            --this.activeMedusaDistantSummonCount;
         }
      }
   }
}
