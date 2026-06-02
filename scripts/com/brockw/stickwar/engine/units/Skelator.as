package com.brockw.stickwar.engine.units
{
   import com.brockw.game.Util;
   import com.brockw.stickwar.engine.ActionInterface;
   import com.brockw.stickwar.engine.Ai.SkelatorAi;
   import com.brockw.stickwar.engine.Ai.command.*;
   import com.brockw.stickwar.engine.Entity;
   import com.brockw.stickwar.engine.StickWar;
   import com.brockw.stickwar.engine.Team.Tech;
   import com.brockw.stickwar.market.MarketItem;
   import flash.display.MovieClip;
   
   public class Skelator extends Unit
   {
      
      private var WEAPON_REACH:Number;

      private static const BOSS_STAFF_SKIN:String = "Scythe";

      private static const BOSS_HEAD_SKIN:String = "Green Helmet";

      private static const BOSS_HEALTH_MULTIPLIER:Number = 2.2;

      private static const BOSS_DAMAGE_MULTIPLIER:Number = 1.2;

      private static const BOSS_DAMAGE_TAKEN_MULTIPLIER:Number = 0.75;

      private static const BOSS_PROJECTILE_RESISTANCE:Number = 0.3;

      private static const BOSS_DEATH_BURST_COUNT:int = 6;

      private static const BOSS_DEATH_BURST_RADIUS:Number = 300;

      private static const BOSS_DEATH_BURST_HIT_RADIUS:Number = 95;

      private static const BOSS_FIST_COOLDOWN_FRAMES:int = 30 * 24;

      private static const BOSS_REAPER_COOLDOWN_FRAMES:int = 30 * 18;

      private static const BOSS_DEAD_RISING_COOLDOWN_FRAMES:int = 30 * 20;

      private static const BOSS_DEAD_RISING_MAX:int = 2;

      private static const BOSS_DISTANCE_PHASE_HEALTH_RATIO:Number = 0.5;

      private static const BOSS_RECENT_HIT_DISTANCE_FRAMES:int = 30 * 3;
      
      private var fistAttackSpell:SpellCooldown;
      
      private var reaperSpell:SpellCooldown;
      
      private var isFistAttacking:Boolean;
      
      private var isReaperSpell:Boolean;

      private var isDeadRisingSpell:Boolean;

      private var hasSummonedDeadRisingThisCast:Boolean;
      
      private var spellX:Number;
      
      private var spellY:Number;
      
      private var target:Unit;
      
      private var _fistDamage:Number;

      private var _isBoss:Boolean;

      private var bossDeathBurstEnabled:Boolean;

      private var hasTriggeredBossDeathBurst:Boolean;

      private var bossFistCooldownFrames:int;

      private var bossReaperCooldownFrames:int;

      private var bossReaperInFlight:Boolean;

      private var bossDeadRisingCooldownFrames:int;

      private var bossRecentHitDistanceFrames:int;

      private var bossDistanceRetreatDirection:int;

      private var bossDeadRisingSummons:Array;
      
      public function Skelator(game:StickWar)
      {
         super(game);
         _mc = new _skelator();
         this.init(game);
         addChild(_mc);
         ai = new SkelatorAi(this);
         initSync();
         firstInit();
         this._isBoss = false;
         this.bossDeathBurstEnabled = false;
         this.hasTriggeredBossDeathBurst = false;
         this.bossFistCooldownFrames = 0;
         this.bossReaperCooldownFrames = 0;
         this.bossReaperInFlight = false;
         this.bossDeadRisingCooldownFrames = 0;
         this.bossRecentHitDistanceFrames = 0;
         this.bossDistanceRetreatDirection = -1;
         this.bossDeadRisingSummons = [];
      }
      
      public static function setItem(mc:MovieClip, weapon:String, armor:String, misc:String) : void
      {
         var m:_skelator = _skelator(mc);
         if(Boolean(m.mc.skullhead))
         {
            if(armor != "")
            {
               m.mc.skullhead.gotoAndStop(armor);
            }
         }
         if(Boolean(m.mc.skullstaff))
         {
            if(weapon != "")
            {
               m.mc.skullstaff.gotoAndStop(weapon);
            }
         }
      }
      
      override public function weaponReach() : Number
      {
         return this.WEAPON_REACH;
      }
      
      override public function init(game:StickWar) : void
      {
         initBase();
         this.WEAPON_REACH = game.xml.xml.Chaos.Units.skelator.weaponReach;
         population = game.xml.xml.Chaos.Units.skelator.population;
         _mass = game.xml.xml.Chaos.Units.skelator.mass;
         _maxForce = game.xml.xml.Chaos.Units.skelator.maxForce;
         _dragForce = game.xml.xml.Chaos.Units.skelator.dragForce;
         _scale = game.xml.xml.Chaos.Units.skelator.scale;
         _maxVelocity = game.xml.xml.Chaos.Units.skelator.maxVelocity;
         damageToDeal = game.xml.xml.Chaos.Units.skelator.baseDamage;
         this.createTime = game.xml.xml.Chaos.Units.skelator.cooldown;
         maxHealth = health = game.xml.xml.Chaos.Units.skelator.health;
         this.fistDamage = game.xml.xml.Chaos.Units.skelator.fist.damage;
         loadDamage(game.xml.xml.Chaos.Units.skelator);
         type = Unit.U_SKELATOR;
         this.isFistAttacking = false;
         this.isReaperSpell = false;
         this.isDeadRisingSpell = false;
         this.hasSummonedDeadRisingThisCast = false;
         this.spellX = this.spellY = 0;
         this.fistAttackSpell = new SpellCooldown(game.xml.xml.Chaos.Units.skelator.fist.effect,game.xml.xml.Chaos.Units.skelator.fist.cooldown,game.xml.xml.Chaos.Units.skelator.fist.mana);
         this.reaperSpell = new SpellCooldown(game.xml.xml.Chaos.Units.skelator.reaper.effect,game.xml.xml.Chaos.Units.skelator.reaper.cooldown,game.xml.xml.Chaos.Units.skelator.reaper.mana);
         _mc.stop();
         _mc.width *= _scale;
         _mc.height *= _scale;
         _state = S_RUN;
         MovieClip(_mc.mc.gotoAndPlay(1));
         MovieClip(_mc.gotoAndStop(1));
         drawShadow();
         this.healthBar.y = -mc.mc.height * 1.1;
         this.target = null;
         this._isBoss = false;
         this.bossDeathBurstEnabled = false;
         this.hasTriggeredBossDeathBurst = false;
         this.bossFistCooldownFrames = 0;
         this.bossReaperCooldownFrames = 0;
         this.bossReaperInFlight = false;
         this.bossDeadRisingCooldownFrames = 0;
         this.bossRecentHitDistanceFrames = 0;
         this.bossDistanceRetreatDirection = -1;
         this.bossDeadRisingSummons = [];
      }
      
      override public function setBuilding() : void
      {
         building = team.buildings["UndeadBuilding"];
      }
      
      override public function update(game:StickWar) : void
      {
         var num:int = 0;
         this.fistAttackSpell.update();
         this.reaperSpell.update();
         if(this.bossFistCooldownFrames > 0)
         {
            --this.bossFistCooldownFrames;
         }
         if(this.bossReaperCooldownFrames > 0)
         {
            --this.bossReaperCooldownFrames;
         }
         if(this.bossDeadRisingCooldownFrames > 0)
         {
            --this.bossDeadRisingCooldownFrames;
         }
         if(this.bossRecentHitDistanceFrames > 0)
         {
            --this.bossRecentHitDistanceFrames;
         }
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
            else if(this.isFistAttacking)
            {
               _mc.gotoAndStop("fistAttack");
               num = (_mc.mc.currentFrame - 27) / 5;
               if(_mc.mc.currentFrame >= 27 && (_mc.mc.currentFrame - 27) % 5 == 0 && num < 6)
               {
                  game.projectileManager.initFistAttack(this.spellX,this.spellY,this,num);
               }
               if(_mc.mc.currentFrame == _mc.mc.totalFrames)
               {
                  _state = S_RUN;
                  this.isFistAttacking = false;
               }
            }
            else if(this.isReaperSpell)
            {
               _mc.gotoAndStop("reaperAttack");
               if(_mc.mc.currentFrame == 42)
               {
                  game.projectileManager.initReaper(this,this.target);
               }
               if(_mc.mc.currentFrame == _mc.mc.totalFrames)
               {
                  _state = S_RUN;
                  this.isReaperSpell = false;
               }
            }
            else if(this.isDeadRisingSpell)
            {
               _mc.gotoAndStop("reaperAttack");
               if(_mc.mc.currentFrame >= 42 && !this.hasSummonedDeadRisingThisCast)
               {
                  this.hasSummonedDeadRisingThisCast = true;
                  this.summonBossDeadRising(game);
               }
               if(_mc.mc.currentFrame == _mc.mc.totalFrames)
               {
                  _state = S_RUN;
                  this.isDeadRisingSpell = false;
                  this.hasSummonedDeadRisingThisCast = false;
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
            this.killBossDeadRisingSummons();
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
         Util.animateMovieClip(mc);
         if(!hasDefaultLoadout)
         {
            if(this.isBoss)
            {
               Skelator.setItem(_skelator(mc),BOSS_STAFF_SKIN,BOSS_HEAD_SKIN,"");
            }
            else
            {
               Skelator.setItem(_skelator(mc),team.loadout.getItem(this.type,MarketItem.T_WEAPON),team.loadout.getItem(this.type,MarketItem.T_ARMOR),team.loadout.getItem(this.type,MarketItem.T_MISC));
            }
         }
      }
      
      override public function stateFixForCutToWalk() : void
      {
         if(!this.isFistAttacking && !this.isReaperSpell && !this.isDeadRisingSpell)
         {
            super.stateFixForCutToWalk();
            this.isFistAttacking = false;
            this.isReaperSpell = false;
            this.isDeadRisingSpell = false;
         }
      }
      
      public function fistAttackCooldown() : Number
      {
         if(this.isBoss && this.bossFistCooldownFrames > this.fistAttackSpell.cooldown())
         {
            return this.bossFistCooldownFrames;
         }
         return this.fistAttackSpell.cooldown();
      }
      
      public function reaperCooldown() : Number
      {
         if(this.isBoss && this.bossReaperInFlight)
         {
            return 1;
         }
         if(this.isBoss && this.bossReaperCooldownFrames > this.reaperSpell.cooldown())
         {
            return this.bossReaperCooldownFrames;
         }
         return this.reaperSpell.cooldown();
      }
      
      override public function isBusy() : Boolean
      {
         return !this.notInSpell() || isBusyForSpell;
      }
      
      private function notInSpell() : Boolean
      {
         return !this.isFistAttacking && !this.isReaperSpell && !this.isDeadRisingSpell;
      }

      public function canBossDeadRising() : Boolean
      {
         return this.isBoss && !this.hasBossAbilitySpawnLock() && this.bossDeadRisingCooldownFrames == 0 && this.isBossDistancePhaseActive() && this.getBossDeadRisingSummonCount() < BOSS_DEAD_RISING_MAX && this.notInSpell();
      }

      public function deadRising() : void
      {
         if(!this.canBossDeadRising())
         {
            return;
         }
         if(this.team != null && this.team.enemyTeam != null && this.team.enemyTeam.statue != null)
         {
            forceFaceDirection(this.team.enemyTeam.statue.px - this.px);
         }
         this.isDeadRisingSpell = true;
         this.hasSummonedDeadRisingThisCast = false;
         hasHit = false;
         _state = S_ATTACK;
         this.bossDeadRisingCooldownFrames = BOSS_DEAD_RISING_COOLDOWN_FRAMES;
         team.game.soundManager.playSound("skeletalReaperSound",px,py);
      }

      public function isBossDistancePhaseActive() : Boolean
      {
         return this.isBoss && this.health > 0 && this.health <= this.maxHealth * BOSS_DISTANCE_PHASE_HEALTH_RATIO;
      }

      public function hasRecentBossHitForDistance() : Boolean
      {
         return this.bossRecentHitDistanceFrames > 0;
      }

      public function getBossDistanceRetreatDirection() : int
      {
         return this.bossDistanceRetreatDirection;
      }

      private function summonBossDeadRising(game:StickWar) : void
      {
         var dead:Unit = null;
         var summonCount:int = 0;
         if(game == null || this.team == null)
         {
            return;
         }
         this.pruneBossDeadRisingSummons();
         summonCount = this.getBossDeadRisingSummonCount();
         if(summonCount >= BOSS_DEAD_RISING_MAX)
         {
            return;
         }
         if(game.soundManager != null)
         {
            game.soundManager.playSoundRandom("GhostTower",2,this.px,this.py);
         }
         dead = game.unitFactory.getUnit(Unit.U_DEAD);
         this.team.spawn(dead,game);
         dead.isBossSummoned = true;
         dead.isTowerSpawned = false;
         dead.forceTowerSpawnVisual = true;
         dead.x = dead.px = this.px - this.team.direction * (65 + summonCount * 40);
         dead.y = dead.py = Math.max(70,Math.min(game.map.height - 70,this.py + (summonCount == 0 ? -35 : 35)));
         this.team.population += dead.population;
         game.projectileManager.initTowerSpawn(dead.px,dead.py,this.team,0.6);
         game.projectileManager.initSpawnDrip(dead.px,dead.py,this.team);
         this.bossDeadRisingSummons.push(dead);
      }

      private function getBossDeadRisingSummonCount() : int
      {
         this.pruneBossDeadRisingSummons();
         return this.bossDeadRisingSummons.length;
      }

      private function pruneBossDeadRisingSummons() : void
      {
         var newSummons:Array = [];
         var summon:Unit = null;
         for each(summon in this.bossDeadRisingSummons)
         {
            if(summon != null && summon.isAlive() && !summon.isDieing)
            {
               newSummons.push(summon);
            }
         }
         this.bossDeadRisingSummons = newSummons;
      }

      private function killBossDeadRisingSummons() : void
      {
         var summon:Unit = null;
         if(this.bossDeadRisingSummons == null)
         {
            return;
         }
         for each(summon in this.bossDeadRisingSummons)
         {
            if(summon != null && !summon.isDead)
            {
               summon.health = 0;
               summon.healthBar.health = 0;
               summon.isDieing = true;
            }
         }
         this.bossDeadRisingSummons = [];
      }
      
      public function fistAttack(x:Number, y:Number) : void
      {
         if(!team.tech.isResearched(Tech.SKELETON_FIST_ATTACK))
         {
            return;
         }
         if(this.isBoss && this.bossFistCooldownFrames > 0)
         {
            return;
         }
         if(this.isBoss && this.hasBossAbilitySpawnLock())
         {
            return;
         }
         if(this.notInSpell() && this.fistAttackSpell.spellActivate(this.team))
         {
            this.spellX = x;
            this.spellY = y;
            forceFaceDirection(this.spellX - this.px);
            this.isFistAttacking = true;
            hasHit = false;
            _state = S_ATTACK;
            if(this.isBoss)
            {
               this.bossFistCooldownFrames = BOSS_FIST_COOLDOWN_FRAMES;
            }
            team.game.soundManager.playSound("skeltalFistsSound",px,py);
         }
      }
      
      public function reaperAttack(unit:Unit) : void
      {
         if(unit != null && unit.isAlive())
         {
            if(this.isBoss && this.bossReaperCooldownFrames > 0)
            {
               return;
            }
            if(this.isBoss && this.hasBossAbilitySpawnLock())
            {
               return;
            }
            if(this.notInSpell() && this.reaperSpell.spellActivate(this.team))
            {
               this.target = unit;
               forceFaceDirection(this.target.px - px);
               this.isReaperSpell = true;
               hasHit = false;
               _state = S_ATTACK;
               if(this.isBoss)
               {
                  this.bossReaperInFlight = true;
               }
               team.game.soundManager.playSound("skeletalReaperSound",px,py);
            }
         }
      }

      public function resolveBossReaperControl(hit:Boolean) : void
      {
         if(!this.isBoss)
         {
            return;
         }
         this.bossReaperInFlight = false;
         if(hit)
         {
            this.bossReaperCooldownFrames = BOSS_REAPER_COOLDOWN_FRAMES;
         }
      }

      public function makeBoss(enableDeathBurst:Boolean = false) : void
      {
         if(this._isBoss)
         {
            this.bossDeathBurstEnabled = this.bossDeathBurstEnabled || enableDeathBurst;
            return;
         }
         this._isBoss = true;
         this.isBossUnit = true;
         this.bossAbilitySpawnLockFrames = 30 * 2;
         this.hasDefaultLoadout = false;
         this.bossDeathBurstEnabled = enableDeathBurst;
         maxHealth *= BOSS_HEALTH_MULTIPLIER;
         health = maxHealth;
         this.healthBar.totalHealth = maxHealth;
         this.healthBar.health = health;
         damageToDeal *= BOSS_DAMAGE_MULTIPLIER;
         this._damageToArmour *= BOSS_DAMAGE_MULTIPLIER;
         this._damageToNotArmour *= BOSS_DAMAGE_MULTIPLIER;
         this.fistDamage *= BOSS_DAMAGE_MULTIPLIER;
         if(team != null && team.tech != null)
         {
            team.tech.isResearchedMap[Tech.SKELETON_FIST_ATTACK] = true;
         }
      }

      override public function poison(p:Number) : void
      {
         if(this.isBoss)
         {
            return;
         }
         super.poison(p);
      }

      override public function damage(type:int, amount:int, inflictor:Entity, modifier:Number = 1) : void
      {
         var previousHealth:Number = this.health;
         var hitDirection:int = 0;
         if(this.isBoss)
         {
            modifier *= BOSS_DAMAGE_TAKEN_MULTIPLIER;
            if(Boolean(type & Unit.D_ARROW) || Boolean(type & Unit.D_FIRE))
            {
               modifier *= 1 - BOSS_PROJECTILE_RESISTANCE;
            }
         }
         super.damage(type,amount,inflictor,modifier);
         if(this.isBoss && this.health > 0 && this.health < previousHealth && this.isBossDistancePhaseActive())
         {
            if(this.bossRecentHitDistanceFrames <= 0)
            {
               if(inflictor is Unit)
               {
                  hitDirection = -Util.sgn(Unit(inflictor).px - this.px);
                  if(hitDirection != 0)
                  {
                     this.bossDistanceRetreatDirection = hitDirection;
                  }
               }
               else if(this.team != null)
               {
                  this.bossDistanceRetreatDirection = -this.team.direction;
               }
            }
            this.bossRecentHitDistanceFrames = BOSS_RECENT_HIT_DISTANCE_FRAMES;
         }
         if(this.isBoss && this.bossDeathBurstEnabled && !this.hasTriggeredBossDeathBurst && this.health <= 0)
         {
            this.hasTriggeredBossDeathBurst = true;
            this.killBossDeadRisingSummons();
            this.triggerBossDeathBurst();
         }
      }

      private function triggerBossDeathBurst() : void
      {
         var i:int = 0;
         var angle:Number = NaN;
         var radius:Number = NaN;
         var burstX:Number = NaN;
         var burstY:Number = NaN;
         if(team == null || team.game == null || team.game.projectileManager == null)
         {
            return;
         }
         for(i = 0; i < BOSS_DEATH_BURST_COUNT; i++)
         {
            angle = team.game.random.nextNumber() * Math.PI * 2;
            radius = team.game.random.nextNumber() * BOSS_DEATH_BURST_RADIUS;
            burstX = px + Math.cos(angle) * radius;
            burstY = Math.max(60,Math.min(team.game.map.height - 60,py + Math.sin(angle) * radius));
            team.game.projectileManager.initPoisonFistEffect(burstX,burstY,this,BOSS_DEATH_BURST_HIT_RADIUS,true);
         }
      }

      public function get isBoss() : Boolean
      {
         return this._isBoss;
      }
      
      override public function get damageToArmour() : Number
      {
         return _damageToArmour;
      }
      
      override public function get damageToNotArmour() : Number
      {
         return _damageToNotArmour;
      }
      
      override public function setActionInterface(a:ActionInterface) : void
      {
         super.setActionInterface(a);
         a.setAction(0,0,UnitCommand.REAPER);
         if(team.tech.isResearched(Tech.SKELETON_FIST_ATTACK))
         {
            a.setAction(1,0,UnitCommand.FIST_ATTACK);
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
            if(Math.abs(px - target.px) < this.WEAPON_REACH && Math.abs(py - target.py) < 40 && this.getDirection() == Util.sgn(target.px - px))
            {
               return true;
            }
         }
         return false;
      }
      
      public function get fistDamage() : Number
      {
         return this._fistDamage;
      }
      
      public function set fistDamage(value:Number) : void
      {
         this._fistDamage = value;
      }
   }
}

