package com.brockw.stickwar.engine.units
{
   import com.brockw.game.Util;
   import com.brockw.stickwar.engine.ActionInterface;
   import com.brockw.stickwar.engine.Ai.*;
   import com.brockw.stickwar.engine.Ai.command.*;
   import com.brockw.stickwar.engine.Entity;
   import com.brockw.stickwar.engine.StickWar;
   import com.brockw.stickwar.engine.Team.Tech;
   import com.brockw.stickwar.market.*;
   import flash.display.MovieClip;
   
   public class Knight extends Unit
   {
      
      public static const AUTO_CHARGE_LOCKED:Boolean = true;

      private static const BOSS_WEAPON_SKIN:String = "Rusted Axe";

      private static const BOSS_ARMOR_SKIN:String = "Rust Helmet";

      private static const BOSS_MISC_SKIN:String = "Rusted Shield";

      private static const BOSS_DAMAGE_MULTIPLIER:Number = 1.5;

      private static const BOSS_DAMAGE_TAKEN_MULTIPLIER:Number = 0.7;

      private static const BOSS_PROJECTILE_RESISTANCE:Number = 0.5;

      private static const BOSS_SPELL_RESISTANCE:Number = 0.5;

      private static const BOSS_ABILITY_COOLDOWN_FRAMES:int = 30 * 20;

      private static const BOSS_CHARGE_ALLY_RADIUS:Number = 300;

      private static var WEAPON_REACH:int;
      
      private var chargeVelocity:Number;
      
      private var normalVelocity:Number;
      
      private var chargeSpell:SpellCooldown;
      
      private var isChargeSet:Boolean;
      
      private var chargeForce:Number;
      
      private var normalForce:Number;
      
      private var chargeStunArea:Number;
      
      private var hasCharged:Boolean;
      
      private var stunned:Unit;
      
      private var stunDamage:Number;
      
      private var stunEffect:Number;
      
      private var stunForce:Number;

      private var _isBoss:Boolean;

      private var bossAbilityCooldownFrames:int;
      
      public function Knight(game:StickWar)
      {
         super(game);
         _mc = new _knight();
         this.init(game);
         addChild(_mc);
         ai = new KnightAi(this);
         initSync();
         firstInit();
         this.isChargeSet = false;
         this.chargeForce = 0;
         this.hasCharged = false;
         this.stunned = null;
         this._isBoss = false;
         this.bossAbilityCooldownFrames = 0;
      }
      
      public static function setItem(mc:MovieClip, weapon:String, armor:String, misc:String) : void
      {
         var m:MovieClip = _knight(mc).mc;
         if(Boolean(m.knighthelm))
         {
            if(armor != "")
            {
               m.knighthelm.gotoAndStop(armor);
            }
         }
         if(Boolean(m.knightweapon))
         {
            if(weapon != "")
            {
               m.knightweapon.gotoAndStop(weapon);
            }
         }
         if(Boolean(m.knightshield))
         {
            if(misc != "")
            {
               m.knightshield.gotoAndStop(misc);
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
         WEAPON_REACH = game.xml.xml.Chaos.Units.knight.weaponReach;
         population = game.xml.xml.Chaos.Units.knight.population;
         _mass = game.xml.xml.Chaos.Units.knight.mass;
         _maxForce = this.normalForce = game.xml.xml.Chaos.Units.knight.maxForce;
         this.chargeForce = game.xml.xml.Chaos.Units.knight.charge.force;
         this.stunForce = game.xml.xml.Chaos.Units.knight.charge.stunForce;
         _dragForce = game.xml.xml.Chaos.Units.knight.dragForce;
         _scale = game.xml.xml.Chaos.Units.knight.scale;
         _maxVelocity = this.normalVelocity = game.xml.xml.Chaos.Units.knight.maxVelocity;
         damageToDeal = game.xml.xml.Chaos.Units.knight.baseDamage;
         this.createTime = game.xml.xml.Chaos.Units.knight.cooldown;
         maxHealth = health = game.xml.xml.Chaos.Units.knight.health;
         this.chargeStunArea = game.xml.xml.Chaos.Units.knight.charge.stunArea;
         this.stunDamage = game.xml.xml.Chaos.Units.knight.charge.damage;
         this.stunEffect = game.xml.xml.Chaos.Units.knight.charge.stun;
         this.chargeVelocity = game.xml.xml.Chaos.Units.knight.charge.velocity;
         loadDamage(game.xml.xml.Chaos.Units.knight);
         type = Unit.U_KNIGHT;
         this.chargeSpell = new SpellCooldown(game.xml.xml.Chaos.Units.knight.charge.effect,game.xml.xml.Chaos.Units.knight.charge.cooldown,game.xml.xml.Chaos.Units.knight.charge.mana);
         this._isBoss = false;
         this.bossAbilityCooldownFrames = 0;
         _mc.stop();
         _mc.width *= _scale;
         _mc.height *= _scale;
         _state = S_RUN;
         MovieClip(_mc.mc.gotoAndPlay(1));
         MovieClip(_mc.gotoAndStop(1));
         drawShadow();
      }
      
      override public function setBuilding() : void
      {
         building = team.buildings["BarracksBuilding"];
      }
      
      override public function getDamageToDeal() : Number
      {
         return damageToDeal;
      }
      
      public function getChargeCooldown() : Number
      {
         return this.chargeSpell.cooldown();
      }

      public function canUseChargeAbility() : Boolean
      {
         return true;
      }
      
      public function charge() : void
      {
         if(!this.canUseChargeAbility())
         {
            return;
         }
         if(!team.tech.isResearched(Tech.KNIGHT_CHARGE))
         {
            return;
         }
         if(this._isDualing || this.isDieing || this.isDead || this.isGarrisoned || this.isIncapacitated())
         {
            return;
         }
         if(this.chargeSpell.spellActivate(team))
         {
            team.game.soundManager.playSound("deathKnightChargeSound",px,py);
            this.hasCharged = false;
         }
      }
      
      private function getStunnedUnit(unit:Unit) : void
      {
         if(this.stunned == null && unit.team != this.team && unit.pz == 0)
         {
            if(unit.type == Unit.U_WALL && Math.abs(unit.px - px) < 20)
            {
               this.stunned = unit;
            }
            else if(Math.pow(unit.px + unit.dx - dx - px,2) + Math.pow(unit.py + unit.dy - dy - py,2) < Math.pow(3 * unit.hitBoxWidth * (this.perspectiveScale + unit.perspectiveScale) / 2,2))
            {
               this.stunned = unit;
            }
         }
      }
      
      override public function update(game:StickWar) : void
      {
         if(this.bossAbilityCooldownFrames > 0)
         {
            --this.bossAbilityCooldownFrames;
         }
         this.chargeSpell.update();
         updateCommon(game);
         if(mc.mc.sword != null)
         {
            mc.mc.sword.gotoAndStop(team.loadout.getItem(this.type,MarketItem.T_WEAPON));
         }
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
            else if(this.chargeSpell.inEffect() && this.hasCharged == false)
            {
               if(!this.hasCharged)
               {
                  this.stunned = null;
                  game.spatialHash.mapInArea(this.px - this.chargeStunArea,this.py - this.chargeStunArea,this.px + this.chargeStunArea,this.py + this.chargeStunArea,this.getStunnedUnit);
                  if(this.stunned != null)
                  {
                     this.hasCharged = true;
                     this.stunned.stun(this.stunEffect);
                     this.stunned.damage(0,this.stunDamage,null);
                     this.stunned.applyVelocity(this.stunForce * Util.sgn(mc.scaleX));
                  }
               }
               _mc.gotoAndStop("charge");
               this._maxVelocity = this.chargeVelocity;
               this._maxForce = this.chargeForce;
               this.isChargeSet = true;
               this.walk(team.direction,0,team.direction);
               this.isChargeSet = false;
            }
            else if(_state == S_RUN)
            {
               this._maxVelocity = this.normalVelocity;
               this._maxForce = this.normalForce;
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
                     game.soundManager.playSound("sword1",px,py);
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
         if(isDead || _isDualing)
         {
            Util.animateMovieClip(_mc,0);
         }
         else
         {
            if(MovieClip(_mc.mc).currentFrame == MovieClip(_mc.mc).totalFrames)
            {
               MovieClip(_mc.mc).gotoAndStop(1);
            }
            MovieClip(_mc.mc).nextFrame();
         }
         if(Boolean(_mc.mc.dust))
         {
            Util.animateMovieClipBasic(_mc.mc.dust);
         }
         if(this.isBoss)
         {
            Knight.setItem(_knight(mc),BOSS_WEAPON_SKIN,BOSS_ARMOR_SKIN,BOSS_MISC_SKIN);
         }
         else
         {
            Knight.setItem(_knight(mc),team.loadout.getItem(this.type,MarketItem.T_WEAPON),team.loadout.getItem(this.type,MarketItem.T_ARMOR),team.loadout.getItem(this.type,MarketItem.T_MISC));
         }
      }

      override public function damage(type:int, amount:int, inflictor:Entity, modifier:Number = 1) : void
      {
         if(this.isBoss)
         {
            modifier *= BOSS_DAMAGE_TAKEN_MULTIPLIER;
            if(Boolean(type & Unit.D_ARROW))
            {
               modifier *= 1 - BOSS_PROJECTILE_RESISTANCE;
            }
            if(Boolean(type & Unit.D_FIRE) || inflictor == null)
            {
               modifier *= 1 - BOSS_SPELL_RESISTANCE;
            }
         }
         super.damage(type,amount,inflictor,modifier);
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
         if(this.canUseChargeAbility() && team.tech.isResearched(Tech.KNIGHT_CHARGE))
         {
            a.setAction(0,0,UnitCommand.KNIGHT_CHARGE);
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
            framesInAttack = MovieClip(_mc.mc).totalFrames;
            attackStartFrame = team.game.frame;
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
      
      override protected function isAbleToWalk() : Boolean
      {
         return this._state == S_RUN && (!this.chargeSpell.inEffect() || this.isChargeSet);
      }

      public function makeBoss() : void
      {
         if(this._isBoss)
         {
            return;
         }
         this._isBoss = true;
         this.isBossUnit = true;
         this.bossAbilitySpawnLockFrames = 30 * 2;
         damageToDeal *= BOSS_DAMAGE_MULTIPLIER;
         this._damageToArmour *= BOSS_DAMAGE_MULTIPLIER;
         this._damageToNotArmour *= BOSS_DAMAGE_MULTIPLIER;
         this.hasDefaultLoadout = false;
      }

      public function tryBossCharge() : void
      {
         var ally:Knight = null;
         var target:Unit = null;
         if(!this.isBoss || this.hasBossAbilitySpawnLock() || this.bossAbilityCooldownFrames > 0 || this.isBusy() || this.isGarrisoned || this.campaignBossEscaping)
         {
            return;
         }
         target = this.ai.getClosestTarget();
         if(target == null || target.pz != 0)
         {
            return;
         }
         if(Math.abs(target.px - this.px) < 150 || Math.abs(target.px - this.px) > 450)
         {
            return;
         }
         this.commandBossCharge(true);
         for each(ally in team.unitGroups[Unit.U_KNIGHT])
         {
            if(ally != null && ally != this && ally.isAlive() && !ally.isGarrisoned && ally.sqrDistanceToTarget(this) <= BOSS_CHARGE_ALLY_RADIUS * BOSS_CHARGE_ALLY_RADIUS)
            {
               ally.commandBossCharge(false);
            }
         }
         this.bossAbilityCooldownFrames = BOSS_ABILITY_COOLDOWN_FRAMES;
      }

      public function commandBossCharge(playSound:Boolean = true) : void
      {
         if(this._isDualing || this.isDieing || this.isDead || this.isGarrisoned || this.isIncapacitated())
         {
            return;
         }
         if(playSound)
         {
            team.game.soundManager.playSound("deathKnightChargeSound",px,py);
         }
         this.chargeSpell.forceActivate();
         this.hasCharged = false;
      }

      public function get isBoss() : Boolean
      {
         return this._isBoss;
      }
   }
}

