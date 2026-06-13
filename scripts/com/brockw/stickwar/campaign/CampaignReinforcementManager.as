package com.brockw.stickwar.campaign
{
   import com.brockw.stickwar.BaseMain;
   import com.brockw.stickwar.engine.Ai.command.AttackMoveCommand;
   import com.brockw.stickwar.engine.Ai.command.MoveCommand;
   import com.brockw.stickwar.engine.Ai.command.UnitCommand;
   import com.brockw.stickwar.engine.StickWar;
   import com.brockw.stickwar.engine.Team.Team;
   import com.brockw.stickwar.engine.units.*;
   
   public class CampaignReinforcementManager
   {
      
      private static const SHADOWRATH_LEVEL_TITLE:String = "Silent Assassins: Ninjas Declare War";
      
      private static const SHADOWRATH_FLANK_SPAWN_BACK_OFFSET:Number = 260;
      
      private static const SHADOWRATH_FLANK_MIN_BASE_DISTANCE:Number = 700;
      
      private static const SHADOWRATH_FLANK_ROW_SPACING:Number = 55;

      private static const SHADOWRATH_FLANK_LOCK_FRAMES:int = 30 * 12;
      
      private var main:BaseMain;
      
      private var game:StickWar;
      
      private var playerTeam:Team;
      
      private var bossSpawner:CampaignBossSpawner;
      
      private var hasTriggered:Boolean;
      
      private var shieldUntilFrame:int;

      private var shadowrathFlankUnits:Array;
      
      public function CampaignReinforcementManager(main:BaseMain, game:StickWar, playerTeam:Team, bossSpawner:CampaignBossSpawner)
      {
         super();
         this.main = main;
         this.game = game;
         this.playerTeam = playerTeam;
         this.bossSpawner = bossSpawner;
         this.hasTriggered = false;
         this.shieldUntilFrame = 0;
         this.shadowrathFlankUnits = [];
      }
      
      public function cleanUp() : void
      {
         this.main = null;
         this.game = null;
         this.playerTeam = null;
         this.bossSpawner = null;
         this.hasTriggered = false;
         this.shieldUntilFrame = 0;
         this.shadowrathFlankUnits = null;
      }
      
      public function reset() : void
      {
         this.hasTriggered = false;
         this.shieldUntilFrame = 0;
         this.shadowrathFlankUnits = [];
      }
      
      public function tryTrigger() : void
      {
         var difficulty:int = 0;
         var level:Level = null;
         var reinforcements:Array = null;
         this.updateShadowrathFlankUnits();
         if(this.hasTriggered || this.main == null || this.main.campaign == null || this.game == null || this.game.teamB == null || this.game.teamB.statue == null)
         {
            return;
         }
         level = this.main.campaign.getCurrentLevel();
         if(level == null || this.game.teamB.statue.health > level.oponent.statueHealth * 0.5)
         {
            return;
         }
         difficulty = this.main.campaign.difficultyLevel;
         reinforcements = this.getCampaignReinforcementsForLevel(level.title,difficulty);
         this.hasTriggered = true;
         if(reinforcements != null && reinforcements.length != 0)
         {
            this.spawnEnemyReinforcements(reinforcements);
         }
         if(level.title == SHADOWRATH_LEVEL_TITLE)
         {
            this.spawnShadowrathFlankReinforcements(difficulty);
         }
      }
      
      public function isShieldActive() : Boolean
      {
         return this.game != null && this.game.teamB != null && this.game.teamB.statue != null && this.game.frame < this.shieldUntilFrame;
      }
      
      public function getCampaignReinforcementsForLevel(title:String, difficulty:int) : Array
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
               return [];
            case "Silent Assassins: Ninjas Declare War":
               if(difficulty == Campaign.D_NORMAL)
               {
                  return [Unit.U_NINJA,Unit.U_SWORDWRATH,Unit.U_SWORDWRATH];
               }
               if(difficulty == Campaign.D_HARD)
               {
                  return [Unit.U_NINJA,Unit.U_NINJA,Unit.U_SWORDWRATH,Unit.U_SWORDWRATH,Unit.U_SWORDWRATH];
               }
               return [Unit.U_NINJA,Unit.U_NINJA,Unit.U_NINJA,Unit.U_SWORDWRATH,Unit.U_SWORDWRATH,Unit.U_SWORDWRATH,Unit.U_SWORDWRATH];
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
      
      public function spawnEnemyReinforcements(unitTypes:Array) : void
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
         var minerIndex:int = 0;
         var isHelperMiner:Boolean = false;
         var currentLevelTitle:String = null;
         var reinforcementUnits:Array = null;
         if(this.game == null || this.game.teamB == null || this.playerTeam == null || unitTypes == null)
         {
            return;
         }
         if(this.main != null && this.main.campaign != null && this.main.campaign.getCurrentLevel() != null)
         {
            currentLevelTitle = this.main.campaign.getCurrentLevel().title;
            spawnWestwindBosses = currentLevelTitle == "Rebels United";
            spawnFactionBosses = this.bossSpawner != null && this.bossSpawner.isFactionBossLevel(currentLevelTitle);
         }
         if(spawnWestwindBosses)
         {
            if(this.bossSpawner != null)
            {
               this.bossSpawner.grantWestwindBossResearch();
            }
         }
         else if(spawnFactionBosses)
         {
            if(this.bossSpawner != null)
            {
               this.bossSpawner.grantFactionBossResearch(currentLevelTitle);
            }
         }
         spawnedBossTypeCounts = {};
         if(spawnWestwindBosses)
         {
            reinforcementUnits = unitTypes.concat([this.game.teamB.getMinerType(),this.game.teamB.getMinerType(),this.game.teamB.getMinerType()]);
         }
         else
         {
            reinforcementUnits = unitTypes.concat([this.game.teamB.getMinerType(),this.game.teamB.getMinerType()]);
         }
         unitTypes = reinforcementUnits;
         totalRows = Math.ceil(unitTypes.length / 4);
         this.activateShield();
         this.playSpawnEffects();
         for(i = 0; i < unitTypes.length; i++)
         {
            unitType = unitTypes[i];
            if(this.game.teamB.unitsAvailable != null && !(unitType in this.game.teamB.unitsAvailable))
            {
               this.game.teamB.unitsAvailable[unitType] = 1;
            }
            newUnit = this.game.unitFactory.getUnit(unitType);
            this.game.teamB.spawn(newUnit,this.game);
            if(spawnWestwindBosses)
            {
               if(!(unitType in spawnedBossTypeCounts))
               {
                  spawnedBossTypeCounts[unitType] = 0;
               }
               spawnedBossTypeCounts[unitType] += 1;
               if(this.bossSpawner.shouldPromoteWestwindBoss(unitType,int(spawnedBossTypeCounts[unitType])))
               {
                  this.bossSpawner.configureWestwindBoss(newUnit);
                  if(newUnit is Ninja)
                  {
                     Ninja(newUnit).disableBossCautiousPhase();
                  }
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
               if(this.bossSpawner.shouldPromoteFactionBoss(currentLevelTitle,unitType,int(spawnedBossTypeCounts[unitType])))
               {
                  this.bossSpawner.configureFactionBoss(newUnit,currentLevelTitle);
               }
            }
            row = int(i / 4);
            column = i % 4;
            rowCount = Math.min(4,unitTypes.length - row * 4);
            xPos = this.game.teamB.homeX + this.game.teamB.direction * (120 + row * 90);
            yPos = Math.max(80,Math.min(this.game.map.height - 80,this.game.map.height / 2 + (column - (rowCount - 1) / 2) * 85 + (row - (totalRows - 1) / 2) * 35));
            isHelperMiner = spawnWestwindBosses && unitType == this.game.teamB.getMinerType();
            if(isHelperMiner)
            {
               xPos = this.game.teamB.homeX + this.game.teamB.direction * 70;
               yPos = Math.max(80,Math.min(this.game.map.height - 80,this.game.map.height / 2 + (minerIndex - 1) * 75));
               ++minerIndex;
            }
            newUnit.x = newUnit.px = xPos;
            newUnit.y = newUnit.py = yPos;
            this.game.teamB.population += newUnit.population;
            attackMoveCommand = new AttackMoveCommand(this.game);
            attackMoveCommand.type = UnitCommand.ATTACK_MOVE;
            attackMoveCommand.goalX = this.playerTeam.statue.px;
            attackMoveCommand.goalY = this.game.map.height / 2;
            attackMoveCommand.realX = this.playerTeam.statue.px;
            attackMoveCommand.realY = this.game.map.height / 2;
            newUnit.ai.setCommand(this.game,attackMoveCommand);
         }
      }
      
      private function spawnShadowrathFlankReinforcements(difficulty:int) : void
      {
         var i:int = 0;
         var ninja:Ninja = null;
         var count:int = this.getShadowrathFlankCount(difficulty);
         var spawnX:Number = 0;
         var spawnY:Number = 0;
         if(this.game == null || this.game.teamB == null || this.playerTeam == null)
         {
            return;
         }
         spawnX = this.getShadowrathFlankSpawnX();
         for(i = 0; i < count; i++)
         {
            ninja = Ninja(this.game.unitFactory.getUnit(Unit.U_NINJA));
            this.game.teamB.spawn(ninja,this.game);
            if(i == 0)
            {
               ninja.makeBoss();
               ninja.enableCampaignBossEscape();
            }
            spawnY = Math.max(80,Math.min(this.game.map.height - 80,this.game.map.height / 2 + (i - (count - 1) / 2) * SHADOWRATH_FLANK_ROW_SPACING));
            ninja.x = ninja.px = spawnX;
            ninja.y = ninja.py = spawnY;
            this.game.teamB.population += ninja.population;
            if(i == 0)
            {
               ninja.bossSpecialStealth(true);
            }
            this.game.projectileManager.initStealthWallExplosion(ninja.px,ninja.py,this.game.teamB);
            this.issueShadowrathFlankTarget(ninja,i == 0);
            if(i != 0)
            {
               ninja.isBossMovementLocked = true;
               this.shadowrathFlankUnits.push([ninja,this.game.frame + SHADOWRATH_FLANK_LOCK_FRAMES]);
            }
         }
      }

      private function updateShadowrathFlankUnits() : void
      {
         var i:int = 0;
         var entry:Array = null;
         var ninja:Ninja = null;
         if(this.shadowrathFlankUnits == null || this.game == null)
         {
            return;
         }
         while(i < this.shadowrathFlankUnits.length)
         {
            entry = this.shadowrathFlankUnits[i] as Array;
            ninja = entry != null ? entry[0] as Ninja : null;
            if(ninja == null || !ninja.isAlive())
            {
               this.shadowrathFlankUnits.splice(i,1);
               continue;
            }
            if(this.game.frame >= int(entry[1]))
            {
               ninja.isBossMovementLocked = false;
               this.shadowrathFlankUnits.splice(i,1);
               continue;
            }
            ninja.isBossMovementLocked = true;
            if(this.game.frame % 15 == 0 && (ninja.ai == null || ninja.ai.currentTarget == null || !ninja.ai.currentTarget.isAlive()))
            {
               this.issueShadowrathFlankTarget(ninja);
            }
            ++i;
         }
      }

      private function issueShadowrathFlankTarget(ninja:Ninja, preferBossPriority:Boolean = false) : void
      {
         var target:Unit = preferBossPriority ? this.getShadowrathFlankBossTarget(ninja) : this.getClosestFlankTarget(ninja);
         var targetCommand:MoveCommand = null;
         var attackMoveCommand:AttackMoveCommand = null;
         if(ninja == null || ninja.ai == null || this.game == null || this.playerTeam == null)
         {
            return;
         }
         if(target != null)
         {
            targetCommand = new MoveCommand(this.game);
            targetCommand.type = UnitCommand.MOVE;
            targetCommand.goalX = target.px;
            targetCommand.goalY = target.py;
            targetCommand.realX = target.px;
            targetCommand.realY = target.py;
            targetCommand.targetId = target.id;
            ninja.ai.setCommand(this.game,targetCommand);
            return;
         }
         attackMoveCommand = new AttackMoveCommand(this.game);
         attackMoveCommand.type = UnitCommand.ATTACK_MOVE;
         attackMoveCommand.goalX = this.playerTeam.statue.px;
         attackMoveCommand.goalY = this.game.map.height / 2;
         attackMoveCommand.realX = attackMoveCommand.goalX;
         attackMoveCommand.realY = attackMoveCommand.goalY;
         ninja.ai.setCommand(this.game,attackMoveCommand);
      }

      private function getShadowrathFlankBossTarget(ninja:Ninja) : Unit
      {
         var archer:Archer = null;
         var unit:Unit = null;
         var bestArcher:Archer = null;
         var bestFallback:Unit = null;
         var archerDistance:Number = 0;
         var bestArcherDistance:Number = Number.POSITIVE_INFINITY;
         var fallbackDistance:Number = 0;
         var bestFallbackDistance:Number = Number.POSITIVE_INFINITY;
         if(ninja == null || this.playerTeam == null)
         {
            return null;
         }
         for each(unit in this.playerTeam.units)
         {
            if(unit == null || !unit.isAlive() || !unit.isTargetable() || unit.isGarrisoned || unit.type == Unit.U_STATUE || unit.type == Unit.U_MINER || unit.type == Unit.U_CHAOS_MINER || unit.isFlying() && !ninja.canAttackAir())
            {
               continue;
            }
            if(unit is Archer)
            {
               archer = Archer(unit);
               archerDistance = ninja.sqrDistanceTo(archer);
               if(archerDistance < bestArcherDistance)
               {
                  bestArcherDistance = archerDistance;
                  bestArcher = archer;
               }
            }
            else
            {
               fallbackDistance = ninja.sqrDistanceTo(unit);
               if(fallbackDistance < bestFallbackDistance)
               {
                  bestFallbackDistance = fallbackDistance;
                  bestFallback = unit;
               }
            }
         }
         return bestArcher != null ? bestArcher : bestFallback;
      }

      private function getClosestFlankTarget(ninja:Ninja) : Unit
      {
         var unit:Unit = null;
         var best:Unit = null;
         var distance:Number = 0;
         var bestDistance:Number = Number.POSITIVE_INFINITY;
         if(ninja == null || this.playerTeam == null)
         {
            return null;
         }
         for each(unit in this.playerTeam.units)
         {
            if(unit != null && unit.isAlive() && unit.isTargetable() && !unit.isGarrisoned && unit.type != Unit.U_STATUE && (!unit.isFlying() || ninja.canAttackAir()))
            {
               distance = ninja.sqrDistanceTo(unit);
               if(distance < bestDistance)
               {
                  bestDistance = distance;
                  best = unit;
               }
            }
         }
         return best;
      }
      
      private function getShadowrathFlankCount(difficulty:int) : int
      {
         if(difficulty == Campaign.D_NORMAL)
         {
            return 2;
         }
         return 3;
      }
      
      private function getShadowrathFlankSpawnX() : Number
      {
         var playerMedian:Number = this.playerTeam.medianPosition;
         var spawnX:Number = playerMedian - this.playerTeam.direction * SHADOWRATH_FLANK_SPAWN_BACK_OFFSET;
         var minX:Number = Math.min(this.playerTeam.homeX + this.playerTeam.direction * SHADOWRATH_FLANK_MIN_BASE_DISTANCE,this.game.map.width - SHADOWRATH_FLANK_MIN_BASE_DISTANCE);
         var maxX:Number = Math.max(this.playerTeam.homeX + this.playerTeam.direction * SHADOWRATH_FLANK_MIN_BASE_DISTANCE,this.game.map.width - SHADOWRATH_FLANK_MIN_BASE_DISTANCE);
         return Math.max(minX,Math.min(maxX,spawnX));
      }
      
      private function activateShield() : void
      {
         var shieldFrames:int = this.getShieldFrames();
         if(this.game == null || this.game.teamB == null || this.game.teamB.statue == null || shieldFrames <= 0)
         {
            return;
         }
         this.shieldUntilFrame = this.game.frame + shieldFrames;
      }
      
      private function getShieldFrames() : int
      {
         if(this.main == null || this.main.campaign == null)
         {
            return 0;
         }
         if(this.main.campaign.difficultyLevel == Campaign.D_NORMAL)
         {
            return 105;
         }
         if(this.main.campaign.difficultyLevel == Campaign.D_HARD)
         {
            return 135;
         }
         return 150;
      }
      
      private function playSpawnEffects() : void
      {
         if(this.game == null || this.game.soundManager == null)
         {
            return;
         }
         this.game.soundManager.playSoundFullVolume("Rage1");
         this.game.soundManager.playSoundFullVolume("Rage2");
         this.game.soundManager.playSoundFullVolume("Rage3");
      }
   }
}
