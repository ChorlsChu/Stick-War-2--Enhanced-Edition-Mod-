package com.brockw.stickwar.engine.units
{
   import com.brockw.game.Util;
   import com.brockw.stickwar.engine.ActionInterface;
   import com.brockw.stickwar.engine.Ai.*;
   import com.brockw.stickwar.engine.Ai.command.*;
   import com.brockw.stickwar.engine.Entity;
   import com.brockw.stickwar.engine.StickWar;
   import com.brockw.stickwar.campaign.CampaignGameScreen;
   import com.brockw.stickwar.engine.Team.*;
   import com.brockw.stickwar.market.MarketItem;
   import flash.display.MovieClip;
   
   public class Magikill extends Unit
   {
      
      private static const BOSS_STAFF_SKIN:String = "Basic Wooden Staff";
      
      private static const BOSS_HAT_SKIN:String = "Gold Hat";
      
      private static const BOSS_BEARD_SKIN:String = "Grey Beard";
      
      private static const BOSS_SUMMON_COOLDOWN_FRAMES:int = 30 * 15;
      
      private static const BOSS_SUMMON_RADIUS:Number = 220;

      private static const BOSS_SUMMON_SPEARTON_MAX:int = 3;

      private static const BOSS_SUMMON_SWORDWRATH_MAX:int = 2;

      private static const BOSS_SUMMON_ARCHER_MAX:int = 2;

      private static const BOSS_SUMMON_COMMIT_RANGE:Number = 600;

      private static const BOSS_SUMMON_SOUND_SCREEN_PADDING:Number = 160;

      private static const BOSS_METEOR_CHAIN_DAMAGE_SCALE:Number = 0.75;

      private static const BOSS_METEOR_CHAIN_SPREAD_X:Number = 220;

      private static const BOSS_METEOR_CHAIN_SPREAD_Y:Number = 110;

      private static const BOSS_METEOR_CHAIN_MIN_OFFSET_X:Number = 120;

      private static const BOSS_METEOR_CHAIN_MIN_OFFSET_Y:Number = 45;

      private static const BOSS_METEOR_CHAIN_MIN_DISTANCE_FROM_MAIN:Number = 120;

      private static const BOSS_METEOR_CHAIN_MIN_DISTANCE_BETWEEN:Number = 140;

      private static const BOSS_METEOR_CHAIN_PLACEMENT_ATTEMPTS:int = 5;

      private static const BOSS_METEOR_CHAIN_FIRST_DELAY:int = 8;

      private static const BOSS_METEOR_CHAIN_SECOND_DELAY:int = 16;
      
      private static const BOSS_DAMAGE_TAKEN_MULTIPLIER:Number = 1 / 1.8;
      
      private static var WEAPON_REACH:int;
      
      private var stunSpellCooldown:SpellCooldown;
      
      private var nukeSpellCooldown:SpellCooldown;
      
      private var poisonDartSpellCooldown:SpellCooldown;
      
      private var isStunning:Boolean;
      
      private var isNuking:Boolean;
      
      private var isPoisonDarting:Boolean;

      private var isSummoning:Boolean;
      
      private var spellX:Number;
      
      private var spellY:Number;
      
      private var explosionDamage:Number;

      private var _autoCastMode:int;
      
      private var _isOnInitialSpawnMove:Boolean;
      
      private var _isBoss:Boolean;
      
      private var bossSummonCooldownFrames:int;
      
      private var bossSummonedUnits:Array;

      private var bossMeteorChainQueue:Array;

      private var bossDamagedUntilFrame:int;
      
      public function Magikill(game:StickWar)
      {
         super(game);
         _mc = new _magikill();
         this.init(game);
         addChild(_mc);
         ai = new MagikillAi(this);
         initSync();
         firstInit();
         healthBar.y = -pheight * 1;
      }
      
      public static function setItem(mc:MovieClip, weapon:String, armor:String, misc:String) : void
      {
         var m:_magikill = _magikill(mc);
         if(Boolean(m.mc.wizhat))
         {
            if(armor != "")
            {
               m.mc.wizhat.gotoAndStop(armor);
            }
         }
         if(Boolean(m.mc.wizstaff))
         {
            if(weapon != "")
            {
               m.mc.wizstaff.gotoAndStop(weapon);
            }
         }
         if(Boolean(m.mc.wizbeard))
         {
            if(misc != "")
            {
               m.mc.wizbeard.gotoAndStop(misc);
            }
         }
      }
      
      override public function weaponReach() : Number
      {
         return WEAPON_REACH;
      }
      
      override public function playDeathSound() : void
      {
         team.game.soundManager.playSound("MagikillDeath",px,py);
      }
      
      override public function init(game:StickWar) : void
      {
         initBase();
         WEAPON_REACH = game.xml.xml.Order.Units.magikill.weaponReach;
         population = game.xml.xml.Order.Units.magikill.population;
         _mass = game.xml.xml.Order.Units.magikill.mass;
         _maxForce = game.xml.xml.Order.Units.magikill.maxForce;
         _dragForce = game.xml.xml.Order.Units.magikill.dragForce;
         _scale = game.xml.xml.Order.Units.magikill.scale;
         _maxVelocity = game.xml.xml.Order.Units.magikill.maxVelocity;
         this.explosionDamage = game.xml.xml.Order.Units.magikill.nuke.damage;
         this.createTime = game.xml.xml.Order.Units.magikill.cooldown;
         maxHealth = health = game.xml.xml.Order.Units.magikill.health;
         loadDamage(game.xml.xml.Order.Units.magikill);
         type = Unit.U_MAGIKILL;
         _mc.stop();
         _mc.width *= _scale;
         _mc.height *= _scale;
         _state = S_RUN;
         MovieClip(_mc.mc.gotoAndPlay(1));
         MovieClip(_mc.gotoAndStop(1));
         drawShadow();
         this.stunSpellCooldown = new SpellCooldown(game.xml.xml.Order.Units.magikill.electricWall.effect,game.xml.xml.Order.Units.magikill.electricWall.cooldown,game.xml.xml.Order.Units.magikill.electricWall.mana);
         this.nukeSpellCooldown = new SpellCooldown(game.xml.xml.Order.Units.magikill.nuke.effect,game.xml.xml.Order.Units.magikill.nuke.cooldown,game.xml.xml.Order.Units.magikill.nuke.mana);
         this.poisonDartSpellCooldown = new SpellCooldown(game.xml.xml.Order.Units.magikill.poisonSpray.effect,game.xml.xml.Order.Units.magikill.poisonSpray.cooldown,game.xml.xml.Order.Units.magikill.poisonSpray.mana);
         this.isNuking = false;
         this.isStunning = false;
         this.isPoisonDarting = false;
         this.isSummoning = false;
         this._autoCastMode = 2;
         this._isOnInitialSpawnMove = true;
         this._isBoss = false;
         this.bossSummonCooldownFrames = 0;
         this.bossSummonedUnits = [];
         this.bossMeteorChainQueue = [];
         this.bossDamagedUntilFrame = 0;
      }
      
      override public function setBuilding() : void
      {
         building = team.buildings["MagicGuildBuilding"];
      }
      
      override public function getDamageToDeal() : Number
      {
         return damageToDeal;
      }
      
      override public function update(game:StickWar) : void
      {
         if(this.bossSummonCooldownFrames > 0)
         {
            --this.bossSummonCooldownFrames;
         }
         if(this.isBoss)
         {
            this.updateBossSummons(game);
         }
         this.updateBossMeteorChain(game);
         this.stunSpellCooldown.update();
         this.nukeSpellCooldown.update();
         this.poisonDartSpellCooldown.update();
         updateCommon(game);
         if(!isDieing)
         {
            if(_isDualing)
            {
               _mc.gotoAndStop(_currentDual.attackLabel);
               moveDualPartner(_dualPartner,_currentDual.xDiff);
               if(MovieClip(_mc.mc).currentFrame == MovieClip(_mc.mc).totalFrames)
               {
                  _mc.gotoAndStop("run");
                  _isDualing = false;
                  _state = S_RUN;
                  px += Util.sgn(mc.scaleX) * _currentDual.finalXOffset * this.scaleX * this._scale * _worldScaleX * this.perspectiveScale;
                  dx = 0;
                  dy = 0;
               }
            }
            else if(this.isNuking == true)
            {
               _mc.gotoAndStop("attack_1");
               if(MovieClip(_mc.mc).currentFrame == 36 && !hasHit)
               {
                  game.soundManager.playSoundRandom("mediumExplosion",3,this.spellX,this.spellY);
                  game.projectileManager.initNuke(this.spellX,this.spellY,this,this.explosionDamage);
                  if(this.isBoss)
                  {
                     this.queueBossMeteorChain(game,this.spellX,this.spellY);
                  }
                  hasHit = true;
               }
               if(MovieClip(_mc.mc).currentFrame == MovieClip(_mc.mc).totalFrames)
               {
                  this.isNuking = false;
                  _state = S_RUN;
               }
            }
            else if(this.isStunning == true)
            {
               _mc.gotoAndStop("electricAttack");
               if(MovieClip(_mc.mc).currentFrame == 47 && !hasHit)
               {
                  game.soundManager.playSound("electricWall",this.spellX,this.spellY);
                  game.projectileManager.initStun(this.spellX,this.spellY,game.xml.xml.Order.Units.magikill.electricWallDamage,this);
                  hasHit = true;
               }
               if(MovieClip(_mc.mc).currentFrame == MovieClip(_mc.mc).totalFrames)
               {
                  this.isStunning = false;
                  _state = S_RUN;
               }
            }
            else if(this.isPoisonDarting == true)
            {
               _mc.gotoAndStop("poisonAttack");
               if(MovieClip(_mc.mc).currentFrame == 44 && !hasHit)
               {
                  game.soundManager.playSound("AcidSpraySound",px,py);
                  game.projectileManager.initPoisonSpray(this.spellX,this.spellY,this);
                  hasHit = true;
               }
               if(MovieClip(_mc.mc).currentFrame == MovieClip(_mc.mc).totalFrames)
               {
                  this.isPoisonDarting = false;
                  _state = S_RUN;
               }
            }
            else if(this.isSummoning == true)
            {
               _mc.gotoAndStop("electricAttack");
               if(MovieClip(_mc.mc).currentFrame == 47 && !hasHit)
               {
                  this.performBossSummonGuards(game);
                  hasHit = true;
               }
               if(MovieClip(_mc.mc).currentFrame == MovieClip(_mc.mc).totalFrames)
               {
                  this.isSummoning = false;
                  _state = S_RUN;
               }
            }
            else if(_state == S_RUN)
            {
               if(isFeetMoving())
               {
                  _mc.gotoAndStop("run");
               }
               else
               {
                  _mc.gotoAndStop("stand");
               }
            }
            else if(_state == S_ATTACK)
            {
               if(!hasHit)
               {
                  hasHit = this.checkForHit();
               }
               if(MovieClip(_mc.mc).totalFrames == MovieClip(_mc.mc).currentFrame)
               {
                  _state = S_RUN;
               }
            }
            updateMotion(game);
         }
         else if(isDead == false)
         {
            if(this.isBoss)
            {
               this.clearBossSummonsOnDeath();
            }
            if(_isDualing)
            {
               _mc.gotoAndStop(_currentDual.defendLabel);
               if(MovieClip(_mc.mc).currentFrame == MovieClip(_mc.mc).totalFrames)
               {
                  isDualing = false;
                  mc.filters = [];
                  this.team.removeUnit(this,game);
                  isDead = true;
               }
            }
            else
            {
               _mc.gotoAndStop(getDeathLabel(game));
               this.team.removeUnit(this,game);
               isDead = true;
            }
         }
         if(!isDead && MovieClip(_mc.mc).currentFrame == MovieClip(_mc.mc).totalFrames)
         {
            MovieClip(_mc.mc).gotoAndStop(1);
         }
         Util.animateMovieClip(_mc,0);
         if(mc.mc.wizhat != null)
         {
            mc.mc.wizhat.gotoAndStop(1);
         }
         if(mc.mc.wizstaff != null)
         {
            mc.mc.wizstaff.gotoAndStop(1);
            if(mc.mc.wizstaff.fireloopwizstaff != null)
            {
               mc.mc.wizstaff.fireloopwizstaff.nextFrame();
               if(mc.mc.wizstaff.fireloopwizstaff.currentFrame == mc.mc.wizstaff.fireloopwizstaff.totalFrames)
               {
                  mc.mc.wizstaff.fireloopwizstaff.gotoAndStop(1);
               }
            }
         }
         if(this.isBoss)
         {
            Magikill.setItem(_magikill(mc),BOSS_STAFF_SKIN,BOSS_HAT_SKIN,BOSS_BEARD_SKIN);
         }
         else if(!hasDefaultLoadout)
         {
            Magikill.setItem(_magikill(mc),team.loadout.getItem(this.type,MarketItem.T_WEAPON),team.loadout.getItem(this.type,MarketItem.T_ARMOR),team.loadout.getItem(this.type,MarketItem.T_MISC));
         }
      }
      
      override public function setActionInterface(a:ActionInterface) : void
      {
         super.setActionInterface(a);
         a.setAction(0,0,UnitCommand.NUKE);
         a.setAction(0,1,UnitCommand.CURE);
         if(team.tech.isResearched(Tech.MAGIKILL_POISON))
         {
            a.setAction(1,0,UnitCommand.POISON_DART);
         }
         if(team.tech.isResearched(Tech.MAGIKILL_WALL))
         {
            a.setAction(2,0,UnitCommand.STUN);
         }
      }
      
      override public function attack() : void
      {
         var id:int = 0;
         if(_state != S_ATTACK)
         {
            id = team.game.random.nextInt() % this._attackLabels.length;
            _mc.gotoAndStop("attack_" + this._attackLabels[id]);
            MovieClip(_mc.mc).gotoAndStop(1);
            _state = S_ATTACK;
            hasHit = false;
         }
      }
      
      override public function isBusy() : Boolean
      {
         return !this.notInSpell() || isBusyForSpell;
      }
      
      private function notInSpell() : Boolean
      {
         return !this.isPoisonDarting && !this.isStunning && !this.isNuking && !this.isSummoning;
      }
      
      public function poisonDartSpell(x:Number, y:Number) : void
      {
         if(!team.tech.isResearched(Tech.MAGIKILL_POISON))
         {
            return;
         }
         if(this.notInSpell() && this.poisonDartSpellCooldown.spellActivate(this.team))
         {
            this.spellX = x;
            this.spellY = y;
            forceFaceDirection(this.spellX - this.px);
            this.isPoisonDarting = true;
            hasHit = false;
            _state = S_ATTACK;
            team.game.soundManager.playSound("wizardPoisonSound",px,py);
         }
      }
      
      public function nukeSpell(x:Number, y:Number) : void
      {
         if(this.notInSpell() && this.nukeSpellCooldown.spellActivate(this.team))
         {
            this.spellX = x;
            forceFaceDirection(this.spellX - this.px);
            this.spellY = y;
            this.isNuking = true;
            hasHit = false;
            _state = S_ATTACK;
            _mc.gotoAndStop("attack_1");
            MovieClip(_mc.mc).gotoAndStop(1);
            team.game.soundManager.playSound("fulminateSound",px,py);
         }
      }
      
      public function stunSpell(x:Number, y:Number) : void
      {
         if(!team.tech.isResearched(Tech.MAGIKILL_WALL))
         {
            return;
         }
         if(this.notInSpell() && this.stunSpellCooldown.spellActivate(this.team))
         {
            this.spellX = x;
            forceFaceDirection(this.spellX - this.px);
            this.spellY = y;
            this.isStunning = true;
            hasHit = false;
            _state = S_ATTACK;
            team.game.soundManager.playSound("electricWallSound",px,py);
         }
      }
      
      public function stunCooldown() : Number
      {
         return this.stunSpellCooldown.cooldown();
      }
      
      public function nukeCooldown() : Number
      {
         return this.nukeSpellCooldown.cooldown();
      }
      
      public function poisonDartCooldown() : Number
      {
         return this.poisonDartSpellCooldown.cooldown();
      }
      
      override public function mayAttack(target:Unit) : Boolean
      {
         if(isIncapacitated())
         {
            return false;
         }
         if(target == null)
         {
            return false;
         }
         if(this.isDualing == true)
         {
            return false;
         }
         if(_state == S_RUN)
         {
            if(Math.abs(px - target.px) < WEAPON_REACH && Math.abs(py - target.py) < 40 && this.getDirection() == Util.sgn(target.px - px))
            {
               return true;
            }
         }
         return false;
      }
      
      override public function stateFixForCutToWalk() : void
      {
         if(!this.isStunning && !this.isNuking && !this.isPoisonDarting)
         {
            super.stateFixForCutToWalk();
            this.isStunning = false;
            this.isNuking = false;
            this.isPoisonDarting = false;
         }
      }

      public function get isMeteorOnlyToggled() : Boolean
      {
         return this._autoCastMode == 1;
      }

      public function set isMeteorOnlyToggled(value:Boolean) : void
      {
         this._autoCastMode = value ? 1 : 0;
      }

      public function get autoCastMode() : int
      {
         return this._autoCastMode;
      }

      public function set autoCastMode(value:int) : void
      {
         this._autoCastMode = value;
      }

      public function get isAutoCastEnabled() : Boolean
      {
         return this._autoCastMode != 2;
      }

      public function get isOnInitialSpawnMove() : Boolean
      {
         return this._isOnInitialSpawnMove;
      }

      public function set isOnInitialSpawnMove(value:Boolean) : void
      {
         this._isOnInitialSpawnMove = value;
      }

      public function makeBoss() : void
      {
         this._isBoss = true;
         this.isBossUnit = true;
         this.hasDefaultLoadout = true;
         this.bossAbilitySpawnLockFrames = 30 * 2;
         this.damageToDeal *= 1.2;
         this.autoCastMode = 2;
         this.bossMeteorChainQueue = [];
         this.bossDamagedUntilFrame = 0;
      }

      override public function damage(type:int, amount:int, inflictor:Entity, modifier:Number = 1) : void
      {
         var previousHealth:Number = this.health;
         if(this.isBoss)
         {
            modifier *= BOSS_DAMAGE_TAKEN_MULTIPLIER;
         }
         super.damage(type,amount,inflictor,modifier);
         if(this.isBoss && this.health < previousHealth && this.team != null && this.team.game != null)
         {
            this.bossDamagedUntilFrame = this.team.game.frame + 30 * 3;
         }
      }

      public function get isBoss() : Boolean
      {
         return this._isBoss;
      }

      public function bossWasRecentlyDamaged(game:StickWar) : Boolean
      {
         return game != null && game.frame < this.bossDamagedUntilFrame;
      }

      public function tryBossSummonGuards(game:StickWar) : Boolean
      {
         if(!this.isBoss || this.hasBossAbilitySpawnLock() || this.bossSummonCooldownFrames > 0 || !this.canBossSummonAnyGuardType() || !this.notInSpell())
         {
            return false;
         }
         if(game.gameScreen is CampaignGameScreen && !CampaignGameScreen(game.gameScreen).canUseRebelsUnitedBossAbility(this,"magikillSummon"))
         {
            return false;
         }
         forceFaceDirection(this.team.enemyTeam.statue.px - this.px);
         this.isSummoning = true;
         hasHit = false;
         _state = S_ATTACK;
         team.game.soundManager.playSound("electricWallSound",px,py);
         this.bossSummonCooldownFrames = BOSS_SUMMON_COOLDOWN_FRAMES;
         return true;
      }

      private function performBossSummonGuards(game:StickWar) : void
      {
         var availableSummons:Array = [];
         var summonType:int = 0;
         var summonCount:int = 0;
         var i:int = 0;
         var newUnit:Unit = null;
         this.pruneBossSummonList();
         if(!this.canBossSummonAnyGuardType())
         {
            return;
         }
         if(this.countLivingBossSummonsByType(Unit.U_SWORDWRATH) < BOSS_SUMMON_SWORDWRATH_MAX)
         {
            availableSummons.push(Unit.U_SWORDWRATH);
         }
         if(this.countLivingBossSummonsByType(Unit.U_ARCHER) < BOSS_SUMMON_ARCHER_MAX)
         {
            availableSummons.push(Unit.U_ARCHER);
         }
         if(this.countLivingBossSummonsByType(Unit.U_SPEARTON) < BOSS_SUMMON_SPEARTON_MAX)
         {
            availableSummons.push(Unit.U_SPEARTON);
         }
         if(availableSummons.length == 0)
         {
            return;
         }
         summonType = int(availableSummons[int(game.random.nextInt() % availableSummons.length)]);
         summonCount = this.getBossSummonSpawnCountForType(summonType);
         if(this.isBossSummonSoundInView(game))
         {
            game.soundManager.playSoundRandom("GhostTower",2,this.px,this.py);
         }
         for(i = 0; i < summonCount; i++)
         {
            if(!this.canBossSummonType(summonType))
            {
               return;
            }
            newUnit = game.unitFactory.getUnit(summonType);
            this.team.spawn(newUnit,game);
            newUnit.isBossSummoned = true;
            newUnit.isTowerSpawned = false;
            newUnit.forceTowerSpawnVisual = true;
            newUnit.x = newUnit.px = this.px - this.team.direction * (40 + this.countLivingBossSummons() * 25);
            newUnit.y = newUnit.py = Math.max(70,Math.min(game.map.height - 70,this.py + (this.countLivingBossSummons() - 1) * 35));
            this.team.population += newUnit.population;
            game.projectileManager.initTowerSpawn(newUnit.px,newUnit.py,this.team,0.6);
            game.projectileManager.initSpawnDrip(newUnit.px,newUnit.py,this.team);
            this.bossSummonedUnits.push(newUnit);
         }
      }

      private function isBossSummonSoundInView(game:StickWar) : Boolean
      {
         if(game == null || game.map == null)
         {
            return false;
         }
         return this.px >= game.screenX - BOSS_SUMMON_SOUND_SCREEN_PADDING && this.px <= game.screenX + game.map.screenWidth + BOSS_SUMMON_SOUND_SCREEN_PADDING;
      }

      public function clearBossSummonsOnDeath() : void
      {
         var summoned:Unit = null;
         for each(summoned in this.bossSummonedUnits)
         {
            if(summoned != null && summoned.isAlive())
            {
               summoned.isDieing = true;
            }
         }
      }

      private function countLivingBossSummons() : int
      {
         var summoned:Unit = null;
         var count:int = 0;
         for each(summoned in this.bossSummonedUnits)
         {
            if(summoned != null && summoned.isAlive() && Math.abs(summoned.px - this.px) < BOSS_SUMMON_RADIUS * 2)
            {
               ++count;
            }
         }
         return count;
      }

      private function countLivingBossSummonsByType(type:int) : int
      {
         var summoned:Unit = null;
         var count:int = 0;
         for each(summoned in this.bossSummonedUnits)
         {
            if(summoned != null && summoned.isAlive() && summoned.type == type)
            {
               ++count;
            }
         }
         return count;
      }

      private function canBossSummonAnyGuardType() : Boolean
      {
         return this.canBossSummonType(Unit.U_SPEARTON) || this.canBossSummonType(Unit.U_SWORDWRATH) || this.canBossSummonType(Unit.U_ARCHER);
      }

      private function canBossSummonType(type:int) : Boolean
      {
         switch(type)
         {
            case Unit.U_SPEARTON:
               return this.countLivingBossSummonsByType(type) < BOSS_SUMMON_SPEARTON_MAX;
            case Unit.U_SWORDWRATH:
               return this.countLivingBossSummonsByType(type) < BOSS_SUMMON_SWORDWRATH_MAX;
            case Unit.U_ARCHER:
               return this.countLivingBossSummonsByType(type) < BOSS_SUMMON_ARCHER_MAX;
            default:
               return false;
         }
      }

      private function getBossSummonSpawnCountForType(type:int) : int
      {
         if(type == Unit.U_SPEARTON)
         {
            return 1;
         }
         return 2;
      }

      private function updateBossMeteorChain(game:StickWar) : void
      {
         var readIndex:int = 0;
         var writeIndex:int = 0;
         var entry:Object = null;
         if(this.bossMeteorChainQueue == null || this.bossMeteorChainQueue.length == 0)
         {
            return;
         }
         for(readIndex = 0; readIndex < this.bossMeteorChainQueue.length; readIndex++)
         {
            entry = this.bossMeteorChainQueue[readIndex];
            if(game.frame >= int(entry.frame))
            {
               game.soundManager.playSoundRandom("mediumExplosion",3,Number(entry.x),Number(entry.y));
               game.projectileManager.initNuke(Number(entry.x),Number(entry.y),this,this.explosionDamage * BOSS_METEOR_CHAIN_DAMAGE_SCALE);
            }
            else
            {
               this.bossMeteorChainQueue[writeIndex] = entry;
               ++writeIndex;
            }
         }
         this.bossMeteorChainQueue.length = writeIndex;
      }

      private function queueBossMeteorChain(game:StickWar, centerX:Number, centerY:Number) : void
      {
         var first:Object = this.pickBossMeteorChainPoint(game,centerX,centerY,null,-1);
         var second:Object = this.pickBossMeteorChainPoint(game,centerX,centerY,first,1);
         this.queueBossMeteorChainExplosion(game,first.x,first.y,BOSS_METEOR_CHAIN_FIRST_DELAY);
         this.queueBossMeteorChainExplosion(game,second.x,second.y,BOSS_METEOR_CHAIN_SECOND_DELAY);
      }

      private function pickBossMeteorChainPoint(game:StickWar, centerX:Number, centerY:Number, avoid:Object, fallbackSide:int) : Object
      {
         var i:int = 0;
         var x:Number = NaN;
         var y:Number = NaN;
         for(i = 0; i < BOSS_METEOR_CHAIN_PLACEMENT_ATTEMPTS; i++)
         {
            x = centerX + (game.random.nextNumber() * 2 - 1) * BOSS_METEOR_CHAIN_SPREAD_X;
            y = Math.max(70,Math.min(game.map.height - 70,centerY + (game.random.nextNumber() * 2 - 1) * BOSS_METEOR_CHAIN_SPREAD_Y));
            if(this.isBossMeteorChainPointValid(x,y,centerX,centerY,avoid))
            {
               return {
                  x: x,
                  y: y
               };
            }
         }
         x = centerX + fallbackSide * (BOSS_METEOR_CHAIN_MIN_OFFSET_X + BOSS_METEOR_CHAIN_MIN_DISTANCE_BETWEEN);
         y = Math.max(70,Math.min(game.map.height - 70,centerY + fallbackSide * BOSS_METEOR_CHAIN_MIN_OFFSET_Y));
         return {
            x: x,
            y: y
         };
      }

      private function isBossMeteorChainPointValid(x:Number, y:Number, centerX:Number, centerY:Number, avoid:Object) : Boolean
      {
         var dx:Number = x - centerX;
         var dy:Number = y - centerY;
         var avoidDx:Number = NaN;
         var avoidDy:Number = NaN;
         if(dx * dx + dy * dy < BOSS_METEOR_CHAIN_MIN_DISTANCE_FROM_MAIN * BOSS_METEOR_CHAIN_MIN_DISTANCE_FROM_MAIN)
         {
            return false;
         }
         if(avoid != null)
         {
            avoidDx = x - Number(avoid.x);
            avoidDy = y - Number(avoid.y);
            if(avoidDx * avoidDx + avoidDy * avoidDy < BOSS_METEOR_CHAIN_MIN_DISTANCE_BETWEEN * BOSS_METEOR_CHAIN_MIN_DISTANCE_BETWEEN)
            {
               return false;
            }
         }
         return true;
      }

      private function queueBossMeteorChainExplosion(game:StickWar, x:Number, y:Number, delayFrames:int) : void
      {
         this.bossMeteorChainQueue.push({
            x: x,
            y: y,
            frame: game.frame + delayFrames
         });
      }

      private function updateBossSummons(game:StickWar) : void
      {
         var summoned:Unit = null;
         this.pruneBossSummonList();
         for each(summoned in this.bossSummonedUnits)
         {
            if(summoned == null || !summoned.isAlive())
            {
               continue;
            }
            if(!summoned.isBossMovementLocked && this.isBossSummonInCombat(summoned))
            {
               this.commitBossSummon(game,summoned);
            }
            else if(summoned.isBossMovementLocked && !this.isBossSummonInCombat(summoned))
            {
               this.releaseBossSummonToArmy(game,summoned);
            }
         }
      }

      private function commitBossSummon(game:StickWar, summoned:Unit) : void
      {
         var target:Unit = summoned.ai.getClosestTarget();
         var attackMove:AttackMoveCommand = new AttackMoveCommand(game);
         summoned.isBossMovementLocked = true;
         attackMove.type = UnitCommand.ATTACK_MOVE;
         if(target != null && target.isAlive() && target.team != summoned.team)
         {
            attackMove.goalX = target.px;
            attackMove.goalY = target.py;
            attackMove.realX = target.px;
            attackMove.realY = target.py;
         }
         else
         {
            attackMove.goalX = this.team.enemyTeam.statue.px;
            attackMove.goalY = game.map.height / 2;
            attackMove.realX = attackMove.goalX;
            attackMove.realY = attackMove.goalY;
         }
         summoned.ai.setCommand(game,attackMove);
      }

      private function releaseBossSummonToArmy(game:StickWar, summoned:Unit) : void
      {
         var attackMove:AttackMoveCommand = null;
         var move:MoveCommand = null;
         summoned.isBossMovementLocked = false;
         if(this.team.currentAttackState == Team.G_ATTACK)
         {
            attackMove = new AttackMoveCommand(game);
            attackMove.type = UnitCommand.ATTACK_MOVE;
            attackMove.goalX = this.team.enemyTeam.statue.px;
            attackMove.goalY = game.map.height / 2;
            attackMove.realX = attackMove.goalX;
            attackMove.realY = attackMove.goalY;
            summoned.ai.setCommand(game,attackMove);
            return;
         }
         move = new MoveCommand(game);
         move.type = UnitCommand.MOVE;
         move.goalX = this.team.homeX + this.team.direction * 600;
         move.goalY = game.map.height / 2;
         move.realX = move.goalX;
         move.realY = move.goalY;
         summoned.ai.setCommand(game,move);
      }

      private function isBossSummonInCombat(summoned:Unit) : Boolean
      {
         var target:Unit = summoned.ai.getClosestTarget();
         return target != null && target.team != summoned.team && target.isTargetable() && summoned.sqrDistanceToTarget(target) < BOSS_SUMMON_COMMIT_RANGE * BOSS_SUMMON_COMMIT_RANGE;
      }

      private function pruneBossSummonList() : void
      {
         var readIndex:int = 0;
         var writeIndex:int = 0;
         var summoned:Unit = null;
         for(readIndex = 0; readIndex < this.bossSummonedUnits.length; readIndex++)
         {
            summoned = this.bossSummonedUnits[readIndex];
            if(summoned != null && summoned.isAlive())
            {
               this.bossSummonedUnits[writeIndex] = summoned;
               ++writeIndex;
            }
         }
         this.bossSummonedUnits.length = writeIndex;
      }
   }
}
