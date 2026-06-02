package com.brockw.stickwar.singleplayer
{
   import com.brockw.stickwar.BaseMain;
   import com.brockw.stickwar.campaign.*;
   import com.brockw.stickwar.campaign.controllers.CampaignCutScene2;
   import com.brockw.stickwar.engine.Ai.*;
   import com.brockw.stickwar.engine.Ai.command.*;
   import com.brockw.stickwar.engine.StickWar;
   import com.brockw.stickwar.engine.Team.Team;
   import com.brockw.stickwar.engine.Team.Tech;
   import com.brockw.stickwar.engine.Team.TechItem;
   import com.brockw.stickwar.engine.multiplayer.moves.UnitMove;
   import com.brockw.stickwar.engine.units.*;
   import flash.utils.Dictionary;
   
   public class EnemyChaosTeamAi extends EnemyTeamAi
   {
      private static const MEDUSA_LOW_PHASE_HP_THRESHOLD:Number = 0.33;

      private static const MEDUSA_MID_PHASE_HP_THRESHOLD:Number = 0.66;

      private static const MEDUSA_ESCAPE_RANGE:Number = 260;

      private static const MEDUSA_ESCORT_RANGE:Number = 550;

      private static const MEDUSA_TARGET_RANGE:Number = 1200;

      private static const MEDUSA_POISON_CLUSTER_RANGE:Number = 160;

      private static const MEDUSA_POISON_PRIORITY_CLUSTER_COUNT:int = 3;

      private static const DEFENCE_BUILD_COOLDOWN_FRAMES:int = 30 * 30;
      
      private static const DEFENCE_BUILD_X_OFFSET:int = 900;
      
      private static const MIN_DEFENCE_FORCE:int = 10;
      
      private static const DEFENCE_BUILD_RESERVE_FRAMES:int = 30 * 8;
      
      private static const MIN_FIRST_DEFENCE_FORCE:int = 20;

      private static const NORMAL_MEDUSA_LIMIT:int = 2;

      private static const INSANE_RESEARCH_MULTIPLIER:Number = 0.75;
      
      private var buildOrder:Array;
      
      private var fistAttackSpell:FistAttackCommand;
      
      private var reaperSpell:ReaperCommand;
      
      private var poisonPoolSpell:PoisonPoolCommand;
      
      private var stoneSpell:StoneCommand;
      
      private var nextTowerBuildFrame:int;
      
      private var pendingTowerBuildUntil:int;

      private var allowTrainableMedusa:Boolean;
      
      public function EnemyChaosTeamAi(team:Team, main:BaseMain, game:StickWar, isCreatingUnits:* = true)
      {
         var key:int = 0;
         var levelTitle:String = String(main.campaign.getCurrentLevel().title);
         var isLateMedusaLevel:Boolean = main.campaign.getCurrentLevel().controller == CampaignCutScene2 || int(main.campaign.getCurrentLevel().levelXml.attribute("number")) == 13;
         this.fistAttackSpell = new FistAttackCommand(game);
         this.reaperSpell = new ReaperCommand(game);
         this.poisonPoolSpell = new PoisonPoolCommand(game);
         this.stoneSpell = new StoneCommand(game);
         this.nextTowerBuildFrame = 0;
         this.pendingTowerBuildUntil = 0;
         this.allowTrainableMedusa = isLateMedusaLevel && main.campaign.difficultyLevel != Campaign.D_NORMAL;
         if(this.allowTrainableMedusa && team.unitsAvailable != null)
         {
            team.unitsAvailable[Unit.U_MEDUSA] = 1;
         }
         unitComposition = new Dictionary();
         unitComposition[Unit.U_CHAOS_MINER] = main.campaign.xml.Chaos.UnitComposition.ChaosMiner;
         if(String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.ChaosMiner) != "")
         {
            unitComposition[Unit.U_CHAOS_MINER] = String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.ChaosMiner);
         }
         unitComposition[Unit.U_BOMBER] = main.campaign.xml.Chaos.UnitComposition.Bomber;
         if(String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.Bomber) != "")
         {
            unitComposition[Unit.U_BOMBER] = String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.Bomber);
         }
         unitComposition[Unit.U_WINGIDON] = main.campaign.xml.Chaos.UnitComposition.Wingadon;
         if(String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.Wingadon) != "")
         {
            unitComposition[Unit.U_WINGIDON] = String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.Wingadon);
         }
         unitComposition[Unit.U_SKELATOR] = main.campaign.xml.Chaos.UnitComposition.SkelatalMage;
         if(String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.SkelatalMage) != "")
         {
            unitComposition[Unit.U_SKELATOR] = String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.SkelatalMage);
         }
         unitComposition[Unit.U_DEAD] = main.campaign.xml.Chaos.UnitComposition.Dead;
         if(String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.Dead) != "")
         {
            unitComposition[Unit.U_DEAD] = String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.Dead);
         }
         unitComposition[Unit.U_CAT] = main.campaign.xml.Chaos.UnitComposition.Cat;
         if(String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.Cat) != "")
         {
            unitComposition[Unit.U_CAT] = String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.Cat);
         }
         unitComposition[Unit.U_KNIGHT] = main.campaign.xml.Chaos.UnitComposition.Knight;
         if(String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.Knight) != "")
         {
            unitComposition[Unit.U_KNIGHT] = String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.Knight);
         }
         unitComposition[Unit.U_MEDUSA] = main.campaign.xml.Chaos.UnitComposition.Medusa;
         if(String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.Medusa) != "")
         {
            unitComposition[Unit.U_MEDUSA] = String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.Medusa);
         }
         if(this.allowTrainableMedusa)
         {
            unitComposition[Unit.U_MEDUSA] = NORMAL_MEDUSA_LIMIT;
         }
         else if(isLateMedusaLevel)
         {
            unitComposition[Unit.U_MEDUSA] = 0;
         }
         unitComposition[Unit.U_GIANT] = main.campaign.xml.Chaos.UnitComposition.Giant;
         if(String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.Giant) != "")
         {
            unitComposition[Unit.U_GIANT] = String(main.campaign.getCurrentLevel().levelXml.oponent.UnitComposition.Giant);
         }
         if(main.campaign.difficultyLevel == Campaign.D_INSANE)
         {
            if(levelTitle == "Explosive War: Bombers Attack")
            {
               unitComposition[Unit.U_BOMBER] = int(unitComposition[Unit.U_BOMBER]) + 2;
            }
            else if(levelTitle == "The Night is Dark: Juggerknights Attack")
            {
               unitComposition[Unit.U_KNIGHT] = int(unitComposition[Unit.U_KNIGHT]) + 2;
            }
            else if(levelTitle == "Undead War: Deadly Deads Attack")
            {
               unitComposition[Unit.U_DEAD] = int(unitComposition[Unit.U_DEAD]) + 2;
            }
            else if(levelTitle == " 4 legged Fury: Crawlers Attack")
            {
               unitComposition[Unit.U_CAT] = int(unitComposition[Unit.U_CAT]) + 4;
            }
            else if(levelTitle == "Shadow of the moon: Eclipsors Attack.")
            {
               unitComposition[Unit.U_WINGIDON] = int(unitComposition[Unit.U_WINGIDON]) + 1;
            }
            else if(levelTitle == "Bone Pile: Marrowkai summon war")
            {
               unitComposition[Unit.U_SKELATOR] = int(unitComposition[Unit.U_SKELATOR]) + 1;
            }
            else if(levelTitle == "Medusa's Gates: The Chaos Capital is in sight. ")
            {
               unitComposition[Unit.U_MEDUSA] = int(unitComposition[Unit.U_MEDUSA]) + 1;
               unitComposition[Unit.U_KNIGHT] = int(unitComposition[Unit.U_KNIGHT]) + 1;
               unitComposition[Unit.U_WINGIDON] = int(unitComposition[Unit.U_WINGIDON]) + 1;
            }
         }
         var theoriticalBuildOrder:* = [Unit.U_GIANT,Unit.U_MEDUSA,Unit.U_KNIGHT,Unit.U_CAT,Unit.U_DEAD,Unit.U_SKELATOR,Unit.U_WINGIDON,Unit.U_BOMBER];
         this.buildOrder = [];
         for each(key in theoriticalBuildOrder)
         {
            if(team.unitsAvailable == null || key in team.unitsAvailable)
            {
               this.buildOrder.push(key);
            }
         }
         super(team,main,game,isCreatingUnits);
      }
      
      override public function update(game:StickWar) : void
      {
         super.update(game);
         this.updateKnights(game);
      }
      
      override protected function updateUnitCreation(game:StickWar) : void
      {
         var i:int = 0;
         var numOfUnit:int = 0;
         var t:TechItem = null;
         if(this.hasPendingTowerBuild(game))
         {
            return;
         }
         if(this.shouldPrioritizeFirstDefence())
         {
            if(!team.tech.isResearched(Tech.MINER_TOWER))
            {
               if(this.tryResearchTech(Tech.MINER_TOWER))
               {
                  return;
               }
            }
            else if(this.tryBuildTower(game))
            {
               return;
            }
         }
         if(!enemyIsAttacking() && (team.population < 6 || this.enemyAtHome()))
         {
            numOfUnit = int(team.unitGroups[Unit.U_CHAOS_MINER].length);
            if(numOfUnit < unitComposition[Unit.U_CHAOS_MINER] && team.unitProductionQueue[team.unitInfo[Unit.U_CHAOS_MINER][2]].length == 0)
            {
               game.requestToSpawn(team.id,Unit.U_CHAOS_MINER);
            }
         }
         var overCompCount:int = 0;
         for(i = 0; i < this.buildOrder.length; i++)
         {
            numOfUnit = this.getAiBuildCount(this.buildOrder[i]);
            if(!(this.buildOrder[i] == Unit.U_BOMBER && team.attackingForcePopulation < 6))
            {
               if(numOfUnit >= unitComposition[this.buildOrder[i]])
               {
                  overCompCount++;
               }
               else if(team.unitProductionQueue[team.unitInfo[this.buildOrder[i]][2]].length == 0)
               {
                  game.requestToSpawn(team.id,this.buildOrder[i]);
               }
            }
         }
         if(overCompCount >= this.buildOrder.length)
         {
            for(i = 0; i < this.buildOrder.length; i++)
            {
               numOfUnit = this.getAiBuildCount(this.buildOrder[i]);
               if(numOfUnit < unitComposition[this.buildOrder[i]] && team.unitProductionQueue[team.unitInfo[this.buildOrder[i]][2]].length == 0)
               {
                  game.requestToSpawn(team.id,this.buildOrder[i]);
               }
            }
         }
         if(int(team.unitGroups[Unit.U_CHAOS_MINER].length) > 0)
         {
            if(this.tryResearchTech(Tech.MINER_TOWER))
            {
               return;
            }
         }
         if(int(team.unitGroups[Unit.U_KNIGHT].length) > 0)
         {
            team.tech.isResearchedMap[Tech.KNIGHT_CHARGE] = true;
         }
         if(int(team.unitGroups[Unit.U_DEAD].length) > 0 && this.tryResearchTech(Tech.DEAD_POISON))
         {
            return;
         }
         if(int(team.unitGroups[Unit.U_SKELATOR].length) > 0 && this.tryResearchTech(Tech.SKELETON_FIST_ATTACK))
         {
            return;
         }
         if(this.getNormalMedusaCount() > 0 && this.tryResearchTech(Tech.MEDUSA_POISON))
         {
            return;
         }
         if(int(team.unitGroups[Unit.U_CAT].length) > 0)
         {
            team.tech.isResearchedMap[Tech.CAT_SPEED] = true;
            team.tech.isResearchedMap[Tech.CAT_PACK] = true;
         }
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
         this.tryBuildTower(game);
      }

      private function updateKnights(game:StickWar) : void
      {
         var knight:Knight = null;
         var target:Unit = null;
         if(Knight.AUTO_CHARGE_LOCKED)
         {
            return;
         }
         for each(knight in team.unitGroups[Unit.U_KNIGHT])
         {
            if(!team.tech.isResearched(Tech.KNIGHT_CHARGE) || knight.getChargeCooldown() != 0 || knight.isBusy() || knight.isGarrisoned)
            {
               continue;
            }
            target = knight.ai.getClosestTarget();
            if(target != null && target.pz == 0)
            {
               if(Math.abs(target.px - knight.px) > 150 && Math.abs(target.px - knight.px) < 450)
               {
                  knight.charge();
               }
            }
         }
      }
      
      override protected function updateSpellCasters(game:StickWar) : void
      {
         var manaBefore:Number = team.mana;
         this.updateDeads(game);
         team.mana = 1000;
         this.updateSkelator(game);
         this.updateMedusa(game);
         team.mana = manaBefore;
      }
      
      private function updateDeads(game:StickWar) : void
      {
         var dead:Dead = null;
         for each(dead in team.unitGroups[Unit.U_DEAD])
         {
            if(!dead.isPoisonedToggled)
            {
               dead.togglePoison();
            }
            if(dead.ai.currentTarget != null)
            {
               RangedAi(dead.ai).mayKite = true;
            }
         }
      }
      
      private function updateGiants(game:StickWar) : void
      {
         var giant:Giant = null;
         for each(giant in team.unitGroups[Unit.U_GIANT])
         {
            if(giant.ai.currentTarget != null)
            {
               if(Math.abs(team.enemyTeam.statue.px - giant.px) < 200)
               {
                  giant.ai.currentTarget = team.enemyTeam.statue;
               }
               else if(team.direction * giant.ai.currentTarget.px < team.direction * (giant.px + -team.direction * 150))
               {
                  giant.ai.currentTarget = null;
                  giant.walk(team.direction,0,team.direction);
               }
            }
         }
      }
      
      private function updateMedusa(game:StickWar) : void
      {
         var campaignScreen:CampaignGameScreen = null;
         var medusaController:CampaignCutScene2 = null;
         var medusa:Medusa = null;
         var target:Unit = null;
         var stoneTarget:Unit = null;
         var poisonTarget:Unit = null;
         var escortCount:int = 0;
         var desperation:Boolean = false;
         var supportStonePhase:Boolean = false;
         var poisonClusterCount:int = 0;
         var shouldDistantRetreat:Boolean = false;
         if(game.gameScreen is CampaignGameScreen && CampaignGameScreen(game.gameScreen).campaignController is CampaignCutScene2)
         {
            campaignScreen = CampaignGameScreen(game.gameScreen);
            medusaController = CampaignCutScene2(campaignScreen.campaignController);
         }
         for each(medusa in team.unitGroups[Unit.U_MEDUSA])
         {
            if(this.isBossMedusa(medusa))
            {
               if(medusaController != null && medusaController.isMedusaRevealStoneLocked())
               {
                  continue;
               }
               target = medusa.ai.getClosestTarget();
               escortCount = this.getNearbyMedusaEscortCount(medusa);
               shouldDistantRetreat = medusaController != null && medusaController.shouldMedusaDistantRetreat();
               if(target != null && escortCount > 0 && medusa.isBossFallbackActive())
               {
                  medusa.walk(-team.direction,0,-team.direction);
                  continue;
               }
               if(shouldDistantRetreat && target != null)
               {
                  medusa.requestBossDistantRetreat();
                  continue;
               }
               if(Boolean(target))
               {
                  if(medusa.stoneCooldown() == 0)
                  {
                     this.stoneSpell.realX = target.px;
                     this.stoneSpell.realY = target.py;
                     this.stoneSpell.targetId = target.id;
                     if(this.stoneSpell.inRange(medusa))
                     {
                        medusa.stone(target);
                     }
                  }
                  else if(medusa.poisonPoolCooldown() == 0)
                  {
                     this.poisonPoolSpell.realX = target.px;
                     this.poisonPoolSpell.realY = target.py;
                     if(this.poisonPoolSpell.inRange(medusa))
                     {
                        medusa.forceFaceDirection(target.px - medusa.px);
                        medusa.poisonSpray();
                     }
                  }
               }
            }
            else
            {
               target = medusa.ai.getClosestTarget();
               if(Boolean(target))
               {
                  if(medusa.stoneCooldown() == 0)
                  {
                     this.stoneSpell.realX = target.px;
                     this.stoneSpell.realY = target.py;
                     this.stoneSpell.targetId = target.id;
                     if(this.stoneSpell.inRange(medusa))
                     {
                        medusa.stone(target);
                     }
                  }
                  else if(medusa.poisonPoolCooldown() == 0)
                  {
                     this.poisonPoolSpell.realX = target.px;
                     this.poisonPoolSpell.realY = target.py;
                     if(this.poisonPoolSpell.inRange(medusa))
                     {
                        medusa.forceFaceDirection(target.px - medusa.px);
                        medusa.poisonSpray();
                     }
                  }
               }
            }
         }
      }

      private function isBossMedusa(medusa:Medusa) : Boolean
      {
         return medusa != null && medusa.maxHealth >= team.game.xml.xml.Chaos.Units.medusa.superHealth;
      }

      private function getNormalMedusaCount() : int
      {
         var medusa:Medusa = null;
         var count:int = 0;
         for each(medusa in team.unitGroups[Unit.U_MEDUSA])
         {
            if(!this.isBossMedusa(medusa))
            {
               ++count;
            }
         }
         return count;
      }

      private function getAiBuildCount(unitType:int) : int
      {
         if(unitType == Unit.U_MEDUSA && this.allowTrainableMedusa)
         {
            return Math.min(NORMAL_MEDUSA_LIMIT,this.getNormalMedusaCount());
         }
         return int(team.unitGroups[unitType].length);
      }

      private function getNearbyMedusaEscortCount(medusa:Medusa) : int
      {
         var unit:String = null;
         var ally:Unit = null;
         var count:int = 0;
         for(unit in team.units)
         {
            ally = team.units[unit];
            if(ally != null && ally != medusa && ally.isAlive() && ally.type != Unit.U_CHAOS_MINER && ally.type != Unit.U_CHAOS_TOWER && Math.abs(ally.px - medusa.px) < MEDUSA_ESCORT_RANGE && Math.abs(ally.py - medusa.py) < 180)
            {
               ++count;
            }
         }
         return count;
      }

      private function getBestMedusaStoneTarget(medusa:Medusa, game:StickWar) : Unit
      {
         var unit:String = null;
         var enemy:Unit = null;
         var bestTarget:Unit = null;
         var score:Number = NaN;
         var bestScore:Number = Number.NEGATIVE_INFINITY;
         for(unit in team.enemyTeam.units)
         {
            enemy = team.enemyTeam.units[unit];
            if(this.isValidMedusaTarget(enemy,medusa))
            {
               score = this.getMedusaStoneTargetScore(enemy,medusa);
               if(score > bestScore)
               {
                  bestScore = score;
                  bestTarget = enemy;
               }
            }
         }
         return bestTarget;
      }

      private function getBestMedusaPoisonTarget(medusa:Medusa, game:StickWar, desperation:Boolean) : Unit
      {
         var unit:String = null;
         var enemy:Unit = null;
         var bestTarget:Unit = null;
         var score:Number = NaN;
         var bestScore:Number = Number.NEGATIVE_INFINITY;
         for(unit in team.enemyTeam.units)
         {
            enemy = team.enemyTeam.units[unit];
            if(this.isValidMedusaTarget(enemy,medusa))
            {
               score = this.getEnemyClusterCount(enemy,MEDUSA_POISON_CLUSTER_RANGE) * 100 - Math.abs(enemy.px - medusa.px) * 0.1;
               if(desperation)
               {
                  score += 75;
               }
               if(score > bestScore)
               {
                  bestScore = score;
                  bestTarget = enemy;
               }
            }
         }
         if(!desperation && bestTarget != null && this.getEnemyClusterCount(bestTarget,MEDUSA_POISON_CLUSTER_RANGE) < 2)
         {
            return null;
         }
         return bestTarget;
      }

      private function getEnemyClusterCount(center:Unit, clusterRange:Number) : int
      {
         var unit:String = null;
         var enemy:Unit = null;
         var count:int = 0;
         for(unit in team.enemyTeam.units)
         {
            enemy = team.enemyTeam.units[unit];
            if(enemy != null && enemy.isAlive() && !enemy.isGarrisoned && enemy.pz == 0 && Math.abs(enemy.px - center.px) <= clusterRange && Math.abs(enemy.py - center.py) <= 80)
            {
               ++count;
            }
         }
         return count;
      }

      private function isValidMedusaTarget(enemy:Unit, medusa:Medusa) : Boolean
      {
         return enemy != null && enemy.isAlive() && !enemy.isGarrisoned && enemy.pz == 0 && Math.abs(enemy.px - medusa.px) <= MEDUSA_TARGET_RANGE;
      }

      private function getMedusaStoneTargetScore(enemy:Unit, medusa:Medusa) : Number
      {
         var score:Number = 0;
         if(enemy.type == Unit.U_GIANT || enemy.type == Unit.U_ENSLAVED_GIANT)
         {
            score += 1000;
         }
         else if(enemy.type == Unit.U_MAGIKILL)
         {
            score += 850;
         }
         else if(enemy.type == Unit.U_SPEARTON)
         {
            score += 700;
         }
         else if(enemy.type == Unit.U_MONK)
         {
            score += 550;
         }
         else if(enemy.type == Unit.U_ARCHER || enemy.type == Unit.U_FLYING_CROSSBOWMAN || enemy.type == Unit.U_NINJA)
         {
            score += 500;
         }
         else if(enemy.type == Unit.U_SWORDWRATH || enemy.type == Unit.U_DEAD || enemy.type == Unit.U_KNIGHT || enemy.type == Unit.U_CAT)
         {
            score += 300;
         }
         else if(enemy.type == Unit.U_BOMBER)
         {
            score += 250;
         }
         else if(enemy.type == Unit.U_MINER || enemy.type == Unit.U_CHAOS_MINER)
         {
            score += 75;
         }
         else
         {
            score += 150;
         }
         score += enemy.health * 0.1;
         score -= Math.abs(enemy.px - medusa.px) * 0.15;
         return score;
      }
      
      private function updateSkelator(game:StickWar) : void
      {
         var skelator:Skelator = null;
         var target:Unit = null;
         for each(skelator in team.unitGroups[Unit.U_SKELATOR])
         {
            target = skelator.ai.getClosestTarget();
            if(Boolean(target))
            {
               if(team.tech.isResearched(Tech.SKELETON_FIST_ATTACK) && skelator.fistAttackCooldown() == 0)
               {
                  this.fistAttackSpell.realX = target.px;
                  this.fistAttackSpell.realY = target.py;
                  if(this.fistAttackSpell.inRange(skelator))
                  {
                     skelator.fistAttack(target.px,target.py);
                  }
               }
               else if(skelator.reaperCooldown() == 0)
               {
                  this.reaperSpell.targetId = target.id;
                  this.reaperSpell.realX = target.px;
                  this.reaperSpell.realY = target.py;
                  if(this.reaperSpell.inRange(skelator))
                  {
                     skelator.reaperAttack(target);
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
      
      private function tryBuildTower(game:StickWar) : Boolean
      {
         var miner:MinerChaos = null;
         var bestMiner:MinerChaos = null;
         var move:UnitMove = null;
         var buildX:Number = NaN;
         var bestDistance:Number = NaN;
         var distance:Number = NaN;
         if(game.frame < this.nextTowerBuildFrame)
         {
            return false;
         }
         if(!team.tech.isResearched(Tech.MINER_TOWER) || team.unitGroups[Unit.U_CHAOS_TOWER].length > 0)
         {
            return false;
         }
         if((!enemyAtHome() && !enemyAtMiddle() && !this.shouldBuildFinalDefence()) || team.attackingForcePopulation < MIN_DEFENCE_FORCE)
         {
            return false;
         }
         if(team.gold <= int(game.xml.xml.Chaos.Units.miner.tower.gold) || team.mana < int(game.xml.xml.Chaos.Units.miner.tower.mana))
         {
            return false;
         }
         buildX = team.homeX + team.direction * DEFENCE_BUILD_X_OFFSET;
         bestDistance = Number.POSITIVE_INFINITY;
         for each(miner in team.unitGroups[Unit.U_CHAOS_MINER])
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
         move.moveType = UnitCommand.CONSTRUCT_TOWER;
         move.units.push(bestMiner.id);
         move.owner = team.id;
         move.arg0 = buildX;
         move.arg1 = game.map.height / 2;
         move.execute(game);
         this.nextTowerBuildFrame = game.frame + DEFENCE_BUILD_COOLDOWN_FRAMES;
         this.pendingTowerBuildUntil = game.frame + DEFENCE_BUILD_RESERVE_FRAMES;
         return true;
      }
      
      private function hasPendingTowerBuild(game:StickWar) : Boolean
      {
         if(team.unitGroups[Unit.U_CHAOS_TOWER].length > 0)
         {
            this.pendingTowerBuildUntil = 0;
            return false;
         }
         if(this.pendingTowerBuildUntil > game.frame)
         {
            return true;
         }
         this.pendingTowerBuildUntil = 0;
         return false;
      }
      
      private function shouldBuildFinalDefence() : Boolean
      {
         return enemyIsWeak() && this.agressionMetric() < 0.8;
      }
      
      private function shouldPrioritizeFirstDefence() : Boolean
      {
         return int(team.unitGroups[Unit.U_CHAOS_MINER].length) > 0 && team.unitGroups[Unit.U_CHAOS_TOWER].length == 0 && team.attackingForcePopulation >= MIN_FIRST_DEFENCE_FORCE && (enemyAtHome() || enemyAtMiddle() || this.shouldBuildFinalDefence());
      }
   }
}

