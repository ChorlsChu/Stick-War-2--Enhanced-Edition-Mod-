package com.brockw.stickwar.engine.units
{
   import com.brockw.game.Util;
   import com.brockw.stickwar.engine.ActionInterface;
   import com.brockw.stickwar.engine.Ai.*;
   import com.brockw.stickwar.engine.Ai.command.*;
   import com.brockw.stickwar.engine.Entity;
   import com.brockw.stickwar.engine.StickWar;
   import com.brockw.stickwar.engine.Team.Team;
   import com.brockw.stickwar.engine.Team.Tech;
   import com.brockw.stickwar.market.MarketItem;
   import flash.display.MovieClip;
   import flash.geom.Point;
   
   public class Monk extends Unit
   {
      
      private static const BOSS_WEAPON_SKIN:String = "Golden Staff";
      
      private static const BOSS_REVIVE_RANGE:Number = 180;

      private static const BOSS_DESPERATION_RADIUS:Number = 220;

      private static const BOSS_REAR_GAP:Number = 140;

      private static const BOSS_SHADOWRATH_HEAL_MULTIPLIER:Number = 2;
      
      private static const BOSS_REVIVE_COOLDOWN_FRAMES:int = 30 * 30;
      
      private static const BOSS_DAMAGE_TAKEN_MULTIPLIER:Number = 1 / 1.65;
      
      private static var WEAPON_REACH:int;
      
      private var cureSpellCooldown:SpellCooldown;
      
      private var healSpellCooldown:SpellCooldown;
      
      private var slowSpellCooldown:SpellCooldown;
      
      private var isCuring:Boolean;
      
      private var isHealing:Boolean;
      
      private var isSlowing:Boolean;
      
      private var isShielding:Boolean;

      private var isReviving:Boolean;
      
      private var spellX:Number;
      
      private var spellY:Number;
      
      private var _isCureToggled:Boolean;
      
      private var cureTarget:Unit;
      
      private var _healAmount:Number;
      
      private var _healDuration:Number;
      
      private var _isHealToggled:Boolean;
      
      private var healTarget:Unit;
      
      private var _isBoss:Boolean;
      
      private var bossReviveCooldownFrames:int;

      private var bossReviveTarget:Unit;
      
      public function Monk(game:StickWar)
      {
         super(game);
         _mc = new _cleric();
         this.init(game);
         addChild(_mc);
         ai = new MonkAi(this);
         initSync();
         firstInit();
      }
      
      public static function setItem(mc:MovieClip, weapon:String, armor:String, misc:String) : void
      {
         var m:_cleric = _cleric(mc);
         if(Boolean(m.mc.clericwand))
         {
            if(weapon != "")
            {
               m.mc.clericwand.gotoAndStop(weapon);
            }
         }
      }
      
      override public function weaponReach() : Number
      {
         return WEAPON_REACH;
      }
      
      override public function init(game:StickWar) : void
      {
         initBase();
         WEAPON_REACH = game.xml.xml.Order.Units.magikill.weaponReach;
         population = game.xml.xml.Order.Units.monk.population;
         _mass = game.xml.xml.Order.Units.monk.mass;
         _maxForce = game.xml.xml.Order.Units.monk.maxForce;
         _dragForce = game.xml.xml.Order.Units.monk.dragForce;
         _scale = game.xml.xml.Order.Units.monk.scale;
         _maxVelocity = game.xml.xml.Order.Units.monk.maxVelocity;
         damageToDeal = game.xml.xml.Order.Units.monk.baseDamage;
         this.createTime = game.xml.xml.Order.Units.monk.cooldown;
         loadDamage(game.xml.xml.Order.Units.monk);
         maxHealth = health = game.xml.xml.Order.Units.monk.health;
         this._healAmount = game.xml.xml.Order.Units.monk.heal.amount;
         this._healDuration = game.xml.xml.Order.Units.monk.heal.duration;
         type = Unit.U_MONK;
         _mc.stop();
         _mc.width *= _scale;
         _mc.height *= _scale;
         _state = S_RUN;
         MovieClip(_mc.mc.gotoAndPlay(1));
         MovieClip(_mc.gotoAndStop(1));
         drawShadow();
         this.healSpellCooldown = new SpellCooldown(game.xml.xml.Order.Units.monk.heal.effect,game.xml.xml.Order.Units.monk.heal.cooldown,game.xml.xml.Order.Units.monk.heal.mana);
         this.cureSpellCooldown = new SpellCooldown(game.xml.xml.Order.Units.monk.cure.effect,game.xml.xml.Order.Units.monk.cure.cooldown,game.xml.xml.Order.Units.monk.cure.mana);
         this.slowSpellCooldown = new SpellCooldown(game.xml.xml.Order.Units.monk.slow.effect,game.xml.xml.Order.Units.monk.slow.cooldown,game.xml.xml.Order.Units.monk.slow.mana);
         this.isCuring = false;
         this.isHealing = false;
         this.isShielding = false;
         this.isReviving = false;
         this.cureTarget = null;
         this.healTarget = null;
         this._isCureToggled = true;
         this._isHealToggled = true;
         this._isBoss = false;
         this.bossReviveCooldownFrames = 0;
         this.bossReviveTarget = null;
      }
      
      override public function setBuilding() : void
      {
         building = team.buildings["TempleBuilding"];
      }
      
      override public function getDamageToDeal() : Number
      {
         return damageToDeal;
      }
      
      override public function update(game:StickWar) : void
      {
         var target:Unit = null;
         var p:Point = null;
         if(this.bossReviveCooldownFrames > 0)
         {
            --this.bossReviveCooldownFrames;
         }
         this.healSpellCooldown.update();
         this.cureSpellCooldown.update();
         this.slowSpellCooldown.update();
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
            else if(this.isHealing == true)
            {
               _mc.gotoAndStop("attack_1");
               if(MovieClip(_mc.mc).currentFrame == 25 && !hasHit)
               {
                  if(this.healTarget != null)
                  {
                     this.healTarget.heal(this.getHealAmountForTarget(this.healTarget),this.healDuration);
                     team.game.soundManager.playSound("HealSpellFinish",this.healTarget.px,this.healTarget.py);
                  }
                  hasHit = true;
               }
               if(MovieClip(_mc.mc).currentFrame == MovieClip(_mc.mc).totalFrames)
               {
                  this.isHealing = false;
                  _state = S_RUN;
               }
            }
            else if(this.isCuring == true)
            {
               _mc.gotoAndStop("attack_2");
               if(MovieClip(_mc.mc).currentFrame == 25 && !hasHit)
               {
                  this.cureTarget.cure();
                  trace("DO THE CURE",this.cureTarget,this.cureTarget.id);
                  team.game.soundManager.playSound("PoisonCureSpellFinish",this.cureTarget.px,this.cureTarget.py);
                  hasHit = true;
               }
               if(MovieClip(_mc.mc).currentFrame == MovieClip(_mc.mc).totalFrames)
               {
                  MovieClip(_mc.mc).gotoAndStop(1);
                  this.isCuring = false;
                  _state = S_RUN;
               }
            }
            else if(this.isSlowing == true)
            {
               _mc.gotoAndStop("attack_1");
               if(MovieClip(_mc.mc).currentFrame == Math.floor(MovieClip(_mc.mc).totalFrames / 2) && !hasHit)
               {
                  if(int(this.spellX) in game.units)
                  {
                     target = game.units[this.spellX];
                     p = mc.mc.clericwand.localToGlobal(new Point(0,0));
                     p = game.battlefield.globalToLocal(p);
                     game.projectileManager.initSlowDart(p.x,p.y,0,this,target);
                  }
                  hasHit = true;
               }
               if(MovieClip(_mc.mc).currentFrame == MovieClip(_mc.mc).totalFrames)
               {
                  this.isSlowing = false;
                  _state = S_RUN;
               }
            }
            else if(this.isReviving == true)
            {
               _mc.gotoAndStop("attack_2");
               if(MovieClip(_mc.mc).currentFrame == 25 && !hasHit)
               {
                  this.performBossRevive(game);
                  hasHit = true;
               }
               if(MovieClip(_mc.mc).currentFrame == MovieClip(_mc.mc).totalFrames)
               {
                  MovieClip(_mc.mc).gotoAndStop(1);
                  this.isReviving = false;
                  this.bossReviveTarget = null;
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
                  if(hasHit)
                  {
                  }
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
         if(isDead)
         {
            Util.animateMovieClip(mc,3);
         }
         else
         {
            MovieClip(_mc.mc).nextFrame();
            _mc.mc.stop();
         }
         if(this.isBoss)
         {
            Monk.setItem(_cleric(mc),BOSS_WEAPON_SKIN,"","");
         }
         else if(!hasDefaultLoadout)
         {
            Monk.setItem(_cleric(mc),team.loadout.getItem(this.type,MarketItem.T_WEAPON),"","");
         }
      }
      
      override public function setActionInterface(a:ActionInterface) : void
      {
         super.setActionInterface(a);
         a.setAction(0,0,UnitCommand.HEAL);
         if(team.tech.isResearched(Tech.MONK_CURE))
         {
            a.setAction(1,0,UnitCommand.CURE);
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
            attackStartFrame = team.game.frame;
            framesInAttack = MovieClip(_mc.mc).totalFrames;
            trace(framesInAttack);
         }
      }
      
      override public function isBusy() : Boolean
      {
         return this.isCuring || this.isHealing || this.isShielding || this.isReviving || isBusyForSpell;
      }
      
      public function healSpell(personToHeal:Unit) : Boolean
      {
         if(!this.isBusy() && this.healSpellCooldown.spellActivate(team))
         {
            this.isHealing = true;
            _state = S_ATTACK;
            hasHit = false;
            this.healTarget = personToHeal;
            team.game.soundManager.playSound("HealSpellFinish",px,py);
            return true;
         }
         return false;
      }

      public function isBossPriorityHealTarget(target:Unit) : Boolean
      {
         return this.isBoss && target != null && target.team == this.team && target is Ninja && Ninja(target).isBoss && Ninja(target).bossIsRetreating && target.health < target.maxHealth;
      }

      public function getHealAmountForTarget(target:Unit) : Number
      {
         if(this.isBossPriorityHealTarget(target))
         {
            return this.healAmount * BOSS_SHADOWRATH_HEAL_MULTIPLIER;
         }
         return this.healAmount;
      }
      
      public function cureSpell(personToCure:Unit) : void
      {
         if(!this.isBusy() && team.tech.isResearched(Tech.MONK_CURE) && this.cureSpellCooldown.spellActivate(team))
         {
            this.cureTarget = personToCure;
            this.isCuring = true;
            _state = S_ATTACK;
            hasHit = false;
            team.game.soundManager.playSound("PoisonCureSpellStart",px,py);
         }
      }
      
      public function slowDartSpell(target:int) : void
      {
         var t:Unit = null;
         if(!this.isSlowing && this.slowSpellCooldown.spellActivate(this.team))
         {
            this.spellX = target;
            if(int(target) in team.game.units)
            {
               t = team.game.units[target];
               forceFaceDirection(t.px - this.px);
               this.isSlowing = true;
               hasHit = false;
               _state = S_ATTACK;
            }
         }
      }
      
      public function healCooldown() : Number
      {
         return this.healSpellCooldown.cooldown();
      }
      
      public function cureCooldown() : Number
      {
         return this.cureSpellCooldown.cooldown();
      }
      
      public function slowDartCooldown() : Number
      {
         return this.slowSpellCooldown.cooldown();
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
         if(!this.isCuring && !this.isHealing)
         {
            super.stateFixForCutToWalk();
         }
      }
      
      public function get isCureToggled() : Boolean
      {
         return this._isCureToggled;
      }
      
      public function set isCureToggled(value:Boolean) : void
      {
         this._isCureToggled = value;
      }
      
      public function get isHealToggled() : Boolean
      {
         return this._isHealToggled;
      }
      
      public function set isHealToggled(value:Boolean) : void
      {
         this._isHealToggled = value;
      }
      
      public function get healAmount() : Number
      {
         return this._healAmount;
      }
      
      public function set healAmount(value:Number) : void
      {
         this._healAmount = value;
      }
      
      public function get healDuration() : Number
      {
         return this._healDuration;
      }
      
      public function set healDuration(value:Number) : void
      {
         this._healDuration = value;
      }

      public function makeBoss() : void
      {
         this._isBoss = true;
         this.isBossUnit = true;
         this.hasDefaultLoadout = true;
         this.bossAbilitySpawnLockFrames = 30 * 2;
         this.healAmount *= 1.2;
         this.healDuration *= 0.75;
      }

      override public function damage(type:int, amount:int, inflictor:Entity, modifier:Number = 1) : void
      {
         if(this.isBoss)
         {
            modifier *= BOSS_DAMAGE_TAKEN_MULTIPLIER;
         }
         super.damage(type,amount,inflictor,modifier);
      }

      public function get isBoss() : Boolean
      {
         return this._isBoss;
      }

      public function tryBossRevive(game:StickWar) : Boolean
      {
         var deadUnits:Array = null;
         if(!this.isBoss || this.hasBossAbilitySpawnLock() || this.bossReviveCooldownFrames > 0 || this.isBusy())
         {
            return false;
         }
         deadUnits = this.team.deadUnits;
         this.bossReviveTarget = this.getBestReviveCandidate(deadUnits);
         if(this.bossReviveTarget == null || Math.abs(this.bossReviveTarget.px - this.px) > BOSS_REVIVE_RANGE)
         {
            this.bossReviveTarget = null;
            return false;
         }
         forceFaceDirection(this.bossReviveTarget.px - this.px);
         this.isReviving = true;
         _state = S_ATTACK;
         hasHit = false;
         game.soundManager.playSound("PoisonCureSpellStart",px,py);
         return true;
      }

      private function performBossRevive(game:StickWar) : void
      {
         var reviveUnit:Unit = null;
         var deadUnits:Array = null;
         var index:int = 0;
         if(this.bossReviveTarget == null)
         {
            return;
         }
         deadUnits = this.team.deadUnits;
         if(deadUnits.indexOf(this.bossReviveTarget) == -1 || Math.abs(this.bossReviveTarget.px - this.px) > BOSS_REVIVE_RANGE)
         {
            return;
         }
         reviveUnit = game.unitFactory.getUnit(this.bossReviveTarget.type);
         this.team.spawn(reviveUnit,game);
         reviveUnit.health = reviveUnit.maxHealth * 0.5;
         reviveUnit.x = reviveUnit.px = this.bossReviveTarget.px;
         reviveUnit.y = reviveUnit.py = this.bossReviveTarget.py;
         this.team.population += reviveUnit.population;
         index = deadUnits.indexOf(this.bossReviveTarget);
         if(index != -1)
         {
            deadUnits.splice(index,1);
         }
         this.team.removeUnitCompletely(this.bossReviveTarget,game);
         this.bossReviveCooldownFrames = BOSS_REVIVE_COOLDOWN_FRAMES;
         game.projectileManager.initTowerSpawn(reviveUnit.px,reviveUnit.py,this.team,0.5);
         game.soundManager.playSound("TowerCapture",reviveUnit.px,reviveUnit.py);
      }

      private function getBestReviveCandidate(deadUnits:Array) : Unit
      {
         var corpse:Unit = null;
         var best:Unit = null;
         var bestPriority:int = -999;
         var priority:int = 0;
         var inCombat:Boolean = this.team.enemyTeam.currentAttackState == Team.G_ATTACK;
         var desperationRevive:Boolean = this.shouldUseDesperationRevive();
         for each(corpse in deadUnits)
         {
            if(corpse == null || corpse.isBossSummoned || Math.abs(corpse.px - this.px) > BOSS_REVIVE_RANGE)
            {
               continue;
            }
            priority = this.getRevivePriority(corpse,inCombat,desperationRevive);
            if(priority > bestPriority)
            {
               bestPriority = priority;
               best = corpse;
            }
         }
         return best;
      }

      private function getRevivePriority(corpse:Unit, inCombat:Boolean, desperationRevive:Boolean) : int
      {
         if(desperationRevive)
         {
            if(corpse.type == Unit.U_SPEARTON)
            {
               return 100;
            }
            if(corpse.type == Unit.U_NINJA)
            {
               return 90;
            }
            if(corpse.type == Unit.U_MAGIKILL)
            {
               return 80;
            }
            if(corpse.type == Unit.U_MONK)
            {
               return 75;
            }
            if(corpse.type == Unit.U_ENSLAVED_GIANT)
            {
               return 70;
            }
            if(corpse.type == Unit.U_ARCHER)
            {
               return 60;
            }
            if(corpse.type == Unit.U_SWORDWRATH)
            {
               return 50;
            }
            return 40;
         }
         if(inCombat)
         {
            if(corpse.type == Unit.U_SPEARTON)
            {
               return 100;
            }
            if(corpse.type == Unit.U_NINJA)
            {
               return 90;
            }
            if(corpse.type == Unit.U_MAGIKILL)
            {
               return 80;
            }
            if(corpse.type == Unit.U_MONK)
            {
               return 70;
            }
            if(corpse.type == Unit.U_SWORDWRATH || corpse.type == Unit.U_ARCHER)
            {
               return -100;
            }
            return 10;
         }
         return 1;
      }

      private function shouldUseDesperationRevive() : Boolean
      {
         var ally:Unit = null;
         var enemy:Unit = null;
         var nearbyLivingAllies:int = 0;
         var threateningEnemies:int = 0;
         for each(ally in this.team.units)
         {
            if(ally != null && ally != this && ally.isAlive() && !ally.isGarrisoned && Math.abs(ally.px - this.px) < BOSS_DESPERATION_RADIUS)
            {
               ++nearbyLivingAllies;
            }
         }
         for each(enemy in this.team.enemyTeam.units)
         {
            if(enemy != null && enemy.isAlive() && enemy.isTargetable() && Math.abs(enemy.px - this.px) < BOSS_DESPERATION_RADIUS)
            {
               ++threateningEnemies;
            }
         }
         return nearbyLivingAllies == 0 && threateningEnemies > 0;
      }

      public function getBossRearLineX() : Number
      {
         var ally:Unit = null;
         var anchor:Unit = null;
         for each(ally in this.team.units)
         {
            if(ally == null || ally == this || !ally.isAlive() || ally.isGarrisoned || ally is Monk || ally.type == Unit.U_MINER || ally.type == Unit.U_CHAOS_MINER)
            {
               continue;
            }
            if(anchor == null || ally.team.direction * ally.px > ally.team.direction * anchor.px)
            {
               anchor = ally;
            }
         }
         if(anchor == null)
         {
            return this.team.homeX + this.team.direction * 160;
         }
         return anchor.px - this.team.direction * BOSS_REAR_GAP;
      }
   }
}

