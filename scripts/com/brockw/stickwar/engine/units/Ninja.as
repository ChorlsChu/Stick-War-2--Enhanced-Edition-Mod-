package com.brockw.stickwar.engine.units
{
   import com.brockw.game.Util;
   import com.brockw.stickwar.engine.ActionInterface;
   import com.brockw.stickwar.engine.Ai.*;
   import com.brockw.stickwar.engine.Ai.command.*;
   import com.brockw.stickwar.engine.Entity;
   import com.brockw.stickwar.engine.StickWar;
   import com.brockw.stickwar.campaign.CampaignGameScreen;
   import com.brockw.stickwar.engine.Team.Tech;
   import com.brockw.stickwar.market.*;
   import flash.display.MovieClip;
   import flash.filters.DropShadowFilter;
   import flash.geom.Point;
   
   public class Ninja extends Unit
   {
      
      private static const BOSS_RETREAT_HEALTH_RATIO:Number = 0.5;
      
      private static const BOSS_RETURN_HEALTH_RATIO:Number = 1;

      private static const BOSS_LOST_HEALTH_RATIO:Number = 0.05;
      
      private static const BOSS_ARMOR_SKIN:String = "Tribal Ninja";
      
      private static const BOSS_WEAPON_SKIN:String = "Knifed Pole";
      
      private static const BOSS_MISC_SKIN:String = "Katana";
      
      private static const BOSS_DAMAGE_TAKEN_MULTIPLIER:Number = 1 / 1.75;
      
      private static const BOSS_ESCAPE_INVISIBLE_FRAMES:int = 30 * 3;

      private static const BOSS_WHIFF_PENALTY_FRAMES:int = 30 * 20;

      private static const BOSS_SPECIAL_CLOAK_DURATION_FRAMES:int = 30 * 12;

      private static const BOSS_CHAIN_CLOAK_DURATION_FRAMES:int = 45;

      private static const BOSS_CHAIN_CLOAK_DELAY_FRAMES:int = 15;
      
      private static var WEAPON_REACH:int;
      
      private var _stealthSpellTimer:SpellCooldown;
      
      private var stealthSpellGlow:DropShadowFilter;
      
      private var isDash:Boolean;
      
      private var ninjaCopyDistance:Number;
      
      private var dontStealth:Boolean;
      
      private var ninjaStealthVelocity:Number;
      
      private var normalVelocity:Number;
      
      private var currentStacks:int;
      
      private var maxStacks:int;
      
      private var currentTarget:Unit;
      
      private var stackDamage:int;
      
      private var furyEffect:int;
      
      private var lastHitFrame:int;

      private var _isAutoCloakToggled:Boolean;
      
      private var _isBoss:Boolean;
      
      private var bossPendingChainCloak:Boolean;

      private var bossPendingChainCloakFrames:int;
      
      private var _bossIsRetreating:Boolean;
      
      private var _bossEmergencySortie:Boolean;
      
      private var bossRetreatCooldownFrames:int;
      
      private var bossEscapeInvisibleFrames:int;

      private var bossWhiffPenaltyFrames:int;

      private var bossSpecialCloakActive:Boolean;

      private var bossSpecialCloakHit:Boolean;

      private var bossCloakWasActive:Boolean;

      private var bossImmediateSpecialReady:Boolean;

      private var bossNeedsSpecialReset:Boolean;
      
      public function Ninja(game:StickWar)
      {
         super(game);
         _mc = new _ninja();
         this.init(game);
         addChild(_mc);
         ai = new NinjaAi(this);
         initSync();
         firstInit();
         this.dontStealth = true;
         this.ninjaCopyDistance = 1;
         this._isAutoCloakToggled = false;
         this._isBoss = false;
         this.bossPendingChainCloak = false;
         this.bossPendingChainCloakFrames = 0;
         this._bossIsRetreating = false;
         this._bossEmergencySortie = false;
         this.bossRetreatCooldownFrames = 0;
         this.bossEscapeInvisibleFrames = 0;
         this.bossWhiffPenaltyFrames = 0;
         this.bossSpecialCloakActive = false;
         this.bossSpecialCloakHit = false;
         this.bossCloakWasActive = false;
         this.bossImmediateSpecialReady = false;
         this.bossNeedsSpecialReset = false;
      }
      
      public static function setItemForMc(mc:MovieClip, weapon:String, armor:String, misc:String) : void
      {
         if(Boolean(mc.ninjahead))
         {
            if(armor != "")
            {
               mc.ninjahead.gotoAndStop(armor);
            }
         }
         if(Boolean(mc.ninjastaff))
         {
            if(weapon != "")
            {
               mc.ninjastaff.gotoAndStop(weapon);
            }
         }
         if(Boolean(mc.ninjasword))
         {
            if(misc != "")
            {
               mc.ninjasword.gotoAndStop(misc);
            }
         }
         if(Boolean(mc.weaponGroup))
         {
            if(Boolean(mc.weaponGroup.ninjastaff))
            {
               if(weapon != "")
               {
                  mc.weaponGroup.ninjastaff.gotoAndStop(weapon);
               }
            }
            if(Boolean(mc.weaponGroup.ninjasword))
            {
               if(misc != "")
               {
                  mc.weaponGroup.ninjasword.gotoAndStop(misc);
               }
            }
         }
      }
      
      public static function setItem(mc:MovieClip, weapon:String, armor:String, misc:String) : void
      {
         var m:_ninja = _ninja(mc);
         setItemForMc(m.mc,weapon,armor,misc);
         if(Boolean(m.shadow1))
         {
            setItemForMc(m.shadow1,weapon,armor,misc);
         }
         if(Boolean(m.shadow2))
         {
            setItemForMc(m.shadow2,weapon,armor,misc);
         }
      }
      
      override public function weaponReach() : Number
      {
         return WEAPON_REACH;
      }
      
      override public function init(game:StickWar) : void
      {
         initBase();
         this._stealthSpellTimer = new SpellCooldown(game.xml.xml.Order.Units.ninja.stealth.effect,game.xml.xml.Order.Units.ninja.stealth.cooldown,game.xml.xml.Order.Units.ninja.stealthMana);
         WEAPON_REACH = game.xml.xml.Order.Units.ninja.weaponReach;
         population = game.xml.xml.Order.Units.ninja.population;
         _mass = game.xml.xml.Order.Units.ninja.mass;
         _maxForce = game.xml.xml.Order.Units.ninja.maxForce;
         _dragForce = game.xml.xml.Order.Units.ninja.dragForce;
         _scale = game.xml.xml.Order.Units.ninja.scale;
         _maxVelocity = this.normalVelocity = game.xml.xml.Order.Units.ninja.maxVelocity;
         this.createTime = game.xml.xml.Order.Units.ninja.cooldown;
         this.ninjaCopyDistance = game.xml.xml.Order.Units.ninja.ninjaCopyDistance;
         loadDamage(game.xml.xml.Order.Units.ninja);
         maxHealth = health = game.xml.xml.Order.Units.ninja.health;
         this.maxStacks = game.xml.xml.Order.Units.ninja.fury.stacks;
         this.stackDamage = game.xml.xml.Order.Units.ninja.fury.bonus;
         this.furyEffect = game.xml.xml.Order.Units.ninja.fury.furyEffect;
         this.currentStacks = 0;
         this.currentTarget = null;
         this.lastHitFrame = 0;
         this.ninjaStealthVelocity = game.xml.xml.Order.Units.ninja.stealth.maxVelocity;
         this.stealthSpellGlow = new DropShadowFilter();
         this.stealthSpellGlow.knockout = true;
         this.stealthSpellGlow.angle = 0;
         this.stealthSpellGlow.distance = 0;
         this.stealthSpellGlow.color = 0;
         type = Unit.U_NINJA;
         _mc.stop();
         _mc.width *= _scale;
         _mc.height *= _scale;
         _state = S_RUN;
         MovieClip(_mc.mc.gotoAndPlay(1));
         MovieClip(_mc.gotoAndStop(1));
         drawShadow();
         this.isDash = true;
      }
      
      override public function setBuilding() : void
      {
         building = team.buildings["BarracksBuilding"];
      }
      
      override public function getDamageToDeal() : Number
      {
         return damageToDeal;
      }
      
      public function stealthCooldown() : Number
      {
         return this._stealthSpellTimer.cooldown();
      }
      
      private function activateStealth(isBossSpecial:Boolean, ignoreCooldown:Boolean = false, bossEffectFrames:int = -1) : Boolean
      {
         if(this.isBoss && !isBossSpecial)
         {
            return false;
         }
         if(team.tech.isResearched(Tech.CLOAK))
         {
            if(ignoreCooldown)
            {
               if(bossEffectFrames >= 0)
               {
                  this._stealthSpellTimer.forceActivateWithEffect(bossEffectFrames);
               }
               else
               {
                  this._stealthSpellTimer.forceActivate();
               }
            }
            else if(bossEffectFrames >= 0 ? !this._stealthSpellTimer.spellActivateWithEffect(team,bossEffectFrames) : !this._stealthSpellTimer.spellActivate(team))
            {
               return false;
            }
            this.dontStealth = false;
            if(this.isBoss && !this._bossIsRetreating)
            {
               this.bossSpecialCloakActive = true;
               this.bossSpecialCloakHit = false;
            }
            team.game.soundManager.playSound("ninjaCloakSound",px,py);
            return true;
         }
         return false;
      }

      public function stealth() : Boolean
      {
         return this.activateStealth(false);
      }

      public function bossSpecialStealth(ignoreCooldown:Boolean = false, isChainCloak:Boolean = false) : Boolean
      {
         var usedImmediateReady:Boolean = this.bossImmediateSpecialReady;
         if(!isChainCloak && team.game.gameScreen is CampaignGameScreen && !CampaignGameScreen(team.game.gameScreen).canUseRebelsUnitedBossAbility(this,"shadowrathCloak"))
         {
            return false;
         }
         var didActivate:Boolean = this.activateStealth(true,ignoreCooldown || usedImmediateReady,isChainCloak ? BOSS_CHAIN_CLOAK_DURATION_FRAMES : BOSS_SPECIAL_CLOAK_DURATION_FRAMES);
         if(didActivate && usedImmediateReady)
         {
            this.bossImmediateSpecialReady = false;
         }
         return didActivate;
      }
      
      override protected function checkForHit() : Boolean
      {
         var poisonDamage:Number = NaN;
         var target:Unit = ai.getClosestTarget();
         if(target == null)
         {
            return false;
         }
         var dir:int = Util.sgn(target.px - px);
         if(_mc.mc.tip == null)
         {
            return false;
         }
         var p2:Point = MovieClip(_mc.mc.tip).localToGlobal(new Point(0,0));
         if(target.checkForHitPoint(p2,target))
         {
            if(this.currentTarget != target || team.game.frame - this.lastHitFrame > this.furyEffect)
            {
               this.currentStacks = 0;
            }
            if(this.currentStacks > this.maxStacks)
            {
               this.currentStacks = this.maxStacks;
            }
            if(target is Statue)
            {
               target.damage(0,this.stackDamage * this.currentStacks + _damageToArmour,null);
            }
            else if(target.isArmoured)
            {
               target.damage(0,this.stackDamage * this.currentStacks + this.damageToArmour,null);
            }
            else
            {
               target.damage(0,this.stackDamage * this.currentStacks + this.damageToNotArmour,null);
            }
            poisonDamage = 0;
            if(team.tech.isResearched(Tech.CLOAK_II))
            {
               poisonDamage = Number(team.game.xml.xml.Order.Units.ninja.stealth.poison2);
            }
            else if(team.tech.isResearched(Tech.CLOAK))
            {
               poisonDamage = Number(team.game.xml.xml.Order.Units.ninja.stealth.poison);
            }
            if(!this.dontStealth)
            {
               target.poison(poisonDamage);
            }
            ++this.currentStacks;
            this.lastHitFrame = team.game.frame;
            this.currentTarget = target;
            return true;
         }
         return false;
      }
      
      override public function update(game:StickWar) : void
      {
         if(this.bossRetreatCooldownFrames > 0)
         {
            --this.bossRetreatCooldownFrames;
         }
         if(this.bossEscapeInvisibleFrames > 0)
         {
            --this.bossEscapeInvisibleFrames;
         }
         if(this.bossWhiffPenaltyFrames > 0)
         {
            --this.bossWhiffPenaltyFrames;
         }
         if(this.bossPendingChainCloakFrames > 0)
         {
            --this.bossPendingChainCloakFrames;
         }
         this._stealthSpellTimer.update();
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
            else if(this.isDash && _state == S_RUN)
            {
               if(Math.abs(_dx) + Math.abs(_dy) > 1)
               {
                  if(!this.dontStealth)
                  {
                     _mc.gotoAndStop("stealth");
                     this._maxVelocity = this.ninjaStealthVelocity;
                  }
                  else
                  {
                     _mc.gotoAndStop("run");
                     if(Boolean(_mc.shadow1) && Boolean(_mc.shadow2))
                     {
                        _mc.shadow1.x = _mc.mc.x - Math.abs(dx) * 10 * this.ninjaCopyDistance;
                        _mc.shadow2.x = _mc.mc.x - Math.abs(dx) * 20 * this.ninjaCopyDistance;
                        _mc.shadow1.y = _mc.mc.y - dy * 5 * this.ninjaCopyDistance;
                        _mc.shadow2.y = _mc.mc.y - dy * 10 * this.ninjaCopyDistance;
                     }
                     this._maxVelocity = this.normalVelocity;
                  }
               }
               else
               {
                  _mc.gotoAndStop("stand");
               }
            }
            else if(_state == S_RUN)
            {
               if(Math.abs(_dx) + Math.abs(_dy) > 0.1)
               {
                  if(this._stealthSpellTimer.inEffect() || this.bossEscapeInvisibleFrames > 0)
                  {
                     _mc.gotoAndStop("stealth");
                     this._maxVelocity = this.ninjaStealthVelocity;
                  }
                  else
                  {
                     _mc.gotoAndStop("run");
                     this._maxVelocity = this.normalVelocity;
                  }
               }
               else
               {
                  _mc.gotoAndStop("stand");
               }
            }
            else if(_state == S_ATTACK)
            {
               if(mc.mc.swing != null)
               {
                  team.game.soundManager.playSoundRandom("ninjaSwipe",4,px,py);
               }
               if(!hasHit)
               {
                  hasHit = this.checkForHit();
                  if(hasHit)
                  {
                     if(this.isBoss && !this.dontStealth)
                     {
                        this.markBossSpecialCloakHit();
                        if(!(this.currentTarget is Statue))
                        {
                           this.bossPendingChainCloak = true;
                           this.bossPendingChainCloakFrames = BOSS_CHAIN_CLOAK_DELAY_FRAMES;
                        }
                     }
                     this.dontStealth = true;
                     game.soundManager.playSound("sword1",px,py);
                  }
               }
               if(MovieClip(_mc.mc).totalFrames == MovieClip(_mc.mc).currentFrame)
               {
                  _state = S_RUN;
                  this.dontStealth = true;
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
         if(!(isDead && MovieClip(_mc.mc).currentFrame == MovieClip(_mc.mc).totalFrames))
         {
            Util.animateMovieClip(_mc);
         }
         if(!this._stealthSpellTimer.inEffect() && this.bossEscapeInvisibleFrames == 0)
         {
            this.dontStealth = true;
         }
         if(this.isBoss)
         {
            this.updateBossCloakPenaltyState();
         }
         if(!this.dontStealth || this.bossEscapeInvisibleFrames > 0)
         {
            mc.filters = [this.stealthSpellGlow];
            mc.mc.alpha = 1;
         }
         else
         {
            mc.filters = [];
            mc.mc.alpha = 1;
         }
         if(this.isBoss)
         {
            Ninja.setItem(_ninja(mc),BOSS_WEAPON_SKIN,BOSS_ARMOR_SKIN,BOSS_MISC_SKIN);
         }
         else if(!hasDefaultLoadout)
         {
            Ninja.setItem(_ninja(mc),team.loadout.getItem(this.type,MarketItem.T_WEAPON),team.loadout.getItem(this.type,MarketItem.T_ARMOR),team.loadout.getItem(this.type,MarketItem.T_MISC));
         }
         this.updateBossRetreatState();
      }
      
      override public function isTargetable() : Boolean
      {
         return !isDead && !isDieing && !this._isDualing && this.dontStealth && this.bossEscapeInvisibleFrames == 0;
      }
      
      override public function setActionInterface(a:ActionInterface) : void
      {
         super.setActionInterface(a);
         a.setAction(2,0,UnitCommand.NINJA_STACK);
         if(team.tech.isResearched(Tech.CLOAK))
         {
            a.setAction(0,0,UnitCommand.STEALTH);
            a.setAction(1,0,UnitCommand.CURE);
         }
      }
      
      override public function get damageToArmour() : Number
      {
         var assasinateDamage:Number = NaN;
         if(!this.dontStealth)
         {
            assasinateDamage = 0;
            if(team.tech.isResearched(Tech.CLOAK_II))
            {
               assasinateDamage = Number(team.game.xml.xml.Order.Units.ninja.stealth.damageToArmour2);
            }
            else if(team.tech.isResearched(Tech.CLOAK))
            {
               assasinateDamage = Number(team.game.xml.xml.Order.Units.ninja.stealth.damageToArmour);
            }
            return _damageToArmour + int(assasinateDamage);
         }
         return _damageToArmour;
      }
      
      override public function get damageToNotArmour() : Number
      {
         var assasinateDamage:Number = NaN;
         if(!this.dontStealth)
         {
            assasinateDamage = 0;
            if(team.tech.isResearched(Tech.CLOAK_II))
            {
               assasinateDamage = Number(team.game.xml.xml.Order.Units.ninja.stealth.damageToNotArmour2);
            }
            else if(team.tech.isResearched(Tech.CLOAK))
            {
               assasinateDamage = Number(team.game.xml.xml.Order.Units.ninja.stealth.damageToNotArmour);
            }
            return _damageToNotArmour + int(assasinateDamage);
         }
         return _damageToNotArmour;
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
         }
      }
      
      override public function mayAttack(target:Unit) : Boolean
      {
         if(framesInAttack > team.game.frame - attackStartFrame)
         {
            return false;
         }
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

      public function get isAutoCloakToggled() : Boolean
      {
         return this._isAutoCloakToggled;
      }

      public function set isAutoCloakToggled(value:Boolean) : void
      {
         this._isAutoCloakToggled = value;
      }

      public function makeBoss() : void
      {
         this._isBoss = true;
         this.isBossUnit = true;
         this.hasDefaultLoadout = true;
         this.bossAbilitySpawnLockFrames = 30;
         this.isAutoCloakToggled = true;
         this.damageToDeal *= 1.25;
         this.normalVelocity *= 1.12;
         this._maxVelocity = this.normalVelocity;
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

      public function get isAttackAnimationActive() : Boolean
      {
         return _state == S_ATTACK;
      }

      public function tryBossChainCloak() : Boolean
      {
         if(!this.isBoss || this.hasBossAbilitySpawnLock() || !this.bossPendingChainCloak || this.bossPendingChainCloakFrames > 0 || _state == S_ATTACK || this._bossIsRetreating || this.hasBossWhiffPenalty())
         {
            return false;
         }
         this.bossPendingChainCloak = false;
         this.bossPendingChainCloakFrames = 0;
         return this.bossSpecialStealth(true,true);
      }

      public function isBossSpecialTargetingActive() : Boolean
      {
         return this.bossSpecialCloakActive || this.bossPendingChainCloak;
      }

      public function shouldBossRetreat() : Boolean
      {
         if(this.campaignBossEscaping)
         {
            return false;
         }
         return this.isBoss && !this.hasBossAbilitySpawnLock() && !this._bossIsRetreating && !this._bossEmergencySortie && this.health <= this.maxHealth * BOSS_RETREAT_HEALTH_RATIO && this.health > this.maxHealth * BOSS_LOST_HEALTH_RATIO;
      }

      public function startBossRetreat() : void
      {
         this._bossIsRetreating = true;
         this._bossEmergencySortie = false;
         this.bossRetreatCooldownFrames = 30 * 15;
         this.bossImmediateSpecialReady = false;
         this.triggerBossEscapeCloak();
      }

      public function updateBossRetreatState() : void
      {
         if(this._bossIsRetreating && !this._bossEmergencySortie && this.health >= this.maxHealth * BOSS_RETURN_HEALTH_RATIO)
         {
            this._bossIsRetreating = false;
         }
      }

      public function get bossIsRetreating() : Boolean
      {
         return this._bossIsRetreating;
      }

      public function startBossEmergencySortie() : void
      {
         this.enterBossFinalStand();
      }

      public function beginBossRecovery() : void
      {
         this._bossEmergencySortie = false;
         this._bossIsRetreating = true;
         this.dontStealth = true;
      }

      public function get bossEmergencySortie() : Boolean
      {
         return this._bossEmergencySortie;
      }

      public function get bossReturnHealthRatio() : Number
      {
         return BOSS_RETURN_HEALTH_RATIO;
      }

      public function shouldStartBossLostPhase() : Boolean
      {
         return this.campaignBossEscapeEnabled && !this.campaignBossEscaping && this.health <= this.maxHealth * BOSS_LOST_HEALTH_RATIO;
      }

      public function get bossIsCautious() : Boolean
      {
         return this._bossIsRetreating;
      }

      public function get bossInFinalStand() : Boolean
      {
         return this._bossEmergencySortie;
      }

      public function finishBossCautious() : void
      {
         this._bossIsRetreating = false;
      }

      public function enterBossFinalStand() : void
      {
         if(this._bossEmergencySortie || this.campaignBossEscaping)
         {
            return;
         }
         this._bossEmergencySortie = true;
         this._bossIsRetreating = false;
         this.bossRetreatCooldownFrames = 0;
         this.bossWhiffPenaltyFrames = 0;
         this.bossPendingChainCloak = false;
         this.bossPendingChainCloakFrames = 0;
         this.bossNeedsSpecialReset = false;
         this.bossSpecialCloakActive = false;
         this.bossSpecialCloakHit = false;
         this.bossEscapeInvisibleFrames = 0;
         this.bossImmediateSpecialReady = true;
         this.dontStealth = true;
      }

      public function triggerBossEscapeCloak() : void
      {
         this.bossPendingChainCloak = false;
         this.bossPendingChainCloakFrames = 0;
         this.bossNeedsSpecialReset = false;
         this.bossSpecialCloakActive = false;
         this.bossSpecialCloakHit = false;
         this.bossEscapeInvisibleFrames = BOSS_ESCAPE_INVISIBLE_FRAMES;
         this.dontStealth = false;
         this.team.game.projectileManager.initStealthWallExplosion(this.px,this.py,this.team);
         this.team.game.soundManager.playSound("mediumExplosion3",this.px,this.py);
      }

      public function failBossSpecial() : void
      {
         this.bossPendingChainCloak = false;
         this.bossPendingChainCloakFrames = 0;
         this.bossSpecialCloakActive = false;
         this.bossSpecialCloakHit = false;
         this.bossWhiffPenaltyFrames = BOSS_WHIFF_PENALTY_FRAMES;
         this.bossNeedsSpecialReset = true;
         this.dontStealth = true;
      }

      public function get needsBossSpecialReset() : Boolean
      {
         return this.bossNeedsSpecialReset;
      }

      public function finishBossSpecialReset() : void
      {
         this.bossNeedsSpecialReset = false;
      }

      public function hasBossWhiffPenalty() : Boolean
      {
         return this.bossWhiffPenaltyFrames > 0;
      }

      public function get isStealthed() : Boolean
      {
         return !this.dontStealth;
      }

      private function markBossSpecialCloakHit() : void
      {
         this.bossSpecialCloakHit = true;
         this.bossSpecialCloakActive = false;
         this._stealthSpellTimer.endEffect();
      }

      private function updateBossCloakPenaltyState() : void
      {
         var stealthActive:Boolean = this._stealthSpellTimer.inEffect();
         if(this.bossCloakWasActive && !stealthActive && this.bossSpecialCloakActive && !this.bossSpecialCloakHit)
         {
            this.bossWhiffPenaltyFrames = BOSS_WHIFF_PENALTY_FRAMES;
            this.bossPendingChainCloak = false;
            this.bossPendingChainCloakFrames = 0;
            this.bossNeedsSpecialReset = true;
         }
         if(!stealthActive)
         {
            this.bossSpecialCloakActive = false;
            this.bossSpecialCloakHit = false;
         }
         this.bossCloakWasActive = stealthActive;
      }
   }
}

