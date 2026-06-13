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
   import com.brockw.stickwar.market.MarketItem;
   import flash.display.MovieClip;
   
   public class Spearton extends Unit
   {
      private static const BOSS_WEAPON_SKIN:String = "Golden Jaged";
      
      private static const BOSS_ARMOR_SKIN:String = "HedgeHog Helmet";
      
      private static const BOSS_MISC_SKIN:String = "Lion Sheild";
      
      private static const BOSS_DAMAGE_MULTIPLIER:Number = 1.5;
      
      private static const BOSS_DAMAGE_TAKEN_MULTIPLIER:Number = 0.7;
      
      private static const BOSS_PROJECTILE_RESISTANCE:Number = 0.5;
      
      private static const BOSS_BRACE_RADIUS:Number = 250;

      private static const BOSS_TRIGGER_ALLY_RADIUS:Number = 340;
      
      private static const BOSS_COMBAT_RADIUS:Number = 350;
      
      private static const BOSS_SHIELD_SLAM_RADIUS_X:Number = 110;
      
      private static const BOSS_SHIELD_SLAM_RADIUS_Y:Number = 70;
      
      private static const BOSS_BRACE_DELAY_FRAMES:int = 20;

      private static const BOSS_RECENT_ATTACK_WINDOW_FRAMES:int = 30 * 2;
      
      private static const BOSS_ABILITY_COOLDOWN_FRAMES:int = 30 * 20;
      
      private static var WEAPON_REACH:int;
      
      private static var RAGE_COOLDOWN:int;
      
      private static var RAGE_EFFECT:int;
      
      private var _isBlocking:Boolean;
      
      private var _inBlock:Boolean;
      
      private var shieldwallDamageReduction:Number;
      
      private var shieldBashSpell:SpellCooldown;
      
      private var isShieldBashing:Boolean;
      
      private var stunForce:Number;
      
      private var stunTime:int;
      
      private var stunned:Unit;
      
      private var _isBoss:Boolean;
      
      private var bossAbilityCooldownFrames:int;
      
      private var bossBraceDelayFrames:int;
      
      private var bossShieldSlamActive:Boolean;

      private var bossCommandedShieldBash:Boolean;

      private var bossLastNormalAttackFrame:int;
      
      private var bossShieldSlamStunTime:int;

      private var forcedWeaponSkin:String = "";
      
      private var forcedArmorSkin:String = "";
      
      private var forcedMiscSkin:String = "";
      
      public function Spearton(game:StickWar)
      {
         super(game);
         _mc = new _speartonMc();
         this.init(game);
         addChild(_mc);
         ai = new SpeartonAi(this);
         initSync();
         firstInit();
      }
      
      public static function setItem(mc:MovieClip, weapon:String, armor:String, misc:String) : void
      {
         var m:_speartonMc = _speartonMc(mc);
         if(Boolean(m.mc.helm))
         {
            if(armor != "")
            {
               m.mc.helm.gotoAndStop(armor);
            }
         }
         if(Boolean(m.mc.spear))
         {
            if(weapon != "")
            {
               m.mc.spear.gotoAndStop(weapon);
            }
         }
         if(Boolean(m.mc.shield))
         {
            if(misc != "")
            {
               m.mc.shield.gotoAndStop(misc);
            }
         }
      }
      
      override public function init(game:StickWar) : void
      {
         initBase();
         this.inBlock = false;
         this.isBlocking = false;
         WEAPON_REACH = game.xml.xml.Order.Units.spearton.weaponReach;
         this.stunTime = game.xml.xml.Order.Units.spearton.shieldBash.stunTime;
         this.stunForce = game.xml.xml.Order.Units.spearton.shieldBash.stunForce;
         population = game.xml.xml.Order.Units.spearton.population;
         this.shieldwallDamageReduction = game.xml.xml.Order.Units.spearton.shieldWall.damageReduction;
         _mass = game.xml.xml.Order.Units.spearton.mass;
         _maxForce = game.xml.xml.Order.Units.spearton.maxForce;
         _dragForce = game.xml.xml.Order.Units.spearton.dragForce;
         _scale = game.xml.xml.Order.Units.spearton.scale;
         _maxVelocity = game.xml.xml.Order.Units.spearton.maxVelocity;
         damageToDeal = game.xml.xml.Order.Units.spearton.baseDamage;
         this.createTime = game.xml.xml.Order.Units.spearton.cooldown;
         maxHealth = health = game.xml.xml.Order.Units.spearton.health;
         type = Unit.U_SPEARTON;
         loadDamage(game.xml.xml.Order.Units.spearton);
         _mc.stop();
         _mc.width *= _scale;
         _mc.height *= _scale;
         _state = S_RUN;
         this.isShieldBashing = false;
         this.shieldBashSpell = new SpellCooldown(0,game.xml.xml.Order.Units.spearton.shieldBash.cooldown,game.xml.xml.Order.Units.spearton.shieldBash.mana);
         this._isBoss = false;
         this.bossAbilityCooldownFrames = 0;
         this.bossBraceDelayFrames = 0;
         this.bossShieldSlamActive = false;
         this.bossCommandedShieldBash = false;
         this.bossLastNormalAttackFrame = -999999;
         this.bossShieldSlamStunTime = game.xml.xml.Chaos.Units.knight.charge.stun;
         this.forcedWeaponSkin = "";
         this.forcedArmorSkin = "";
         this.forcedMiscSkin = "";
         MovieClip(_mc.mc.gotoAndPlay(1));
         MovieClip(_mc.gotoAndStop(1));
         drawShadow();
      }
      
      override public function weaponReach() : Number
      {
         return WEAPON_REACH;
      }
      
      override public function setBuilding() : void
      {
         building = team.buildings["BarracksBuilding"];
      }
      
      override public function getDamageToDeal() : Number
      {
         return damageToDeal;
      }
      
      public function shieldBash() : void
      {
         if(this.shieldBashSpell.spellActivate(team) && this._isBlocking)
         {
            this.isShieldBashing = true;
         }
      }

      public function forceSkin(weapon:String, armor:String, misc:String) : void
      {
         this.forcedWeaponSkin = weapon;
         this.forcedArmorSkin = armor;
         this.forcedMiscSkin = misc;
         Spearton.setItem(_speartonMc(mc),this.forcedWeaponSkin,this.forcedArmorSkin,this.forcedMiscSkin);
      }

      public function bossShieldBash() : void
      {
         if(this._isBlocking)
         {
            this.isShieldBashing = true;
            _state = S_RUN;
            hasHit = false;
         }
      }

      public function forcedShieldBash() : void
      {
         if(this._isBlocking)
         {
            this.isShieldBashing = true;
            _state = S_RUN;
            hasHit = false;
         }
      }
      
      public function shieldBashCooldown() : Number
      {
         return this.shieldBashSpell.cooldown();
      }
      
      override public function update(game:StickWar) : void
      {
         var hit:Boolean = false;
         this.shieldBashSpell.update();
         if(this.bossAbilityCooldownFrames > 0)
         {
            --this.bossAbilityCooldownFrames;
         }
         if(this.bossBraceDelayFrames > 0)
         {
            --this.bossBraceDelayFrames;
            if(this.bossBraceDelayFrames == 0)
            {
               if(this.isBoss && this.bossShieldSlamActive)
               {
                  this.bossShieldBash();
               }
               else if(this.bossCommandedShieldBash)
               {
                  this.bossCommandedShieldBash = false;
                  this.forcedShieldBash();
               }
               else
               {
                  this.shieldBash();
               }
            }
         }
         updateCommon(game);
         if(!isDieing)
         {
            updateMotion(game);
            if(_isDualing)
            {
               _mc.gotoAndStop(_currentDual.attackLabel);
               moveDualPartner(_dualPartner,_currentDual.xDiff);
               if(MovieClip(_mc.mc).currentFrame == MovieClip(_mc.mc).totalFrames)
               {
                  _isDualing = false;
                  _state = S_RUN;
                  px += Util.sgn(mc.scaleX) * team.game.getPerspectiveScale(py) * _currentDual.finalXOffset;
                  x = px;
                  dx = 0;
                  dy = 0;
               }
            }
            else if(this.isShieldBashing)
            {
               if(MovieClip(mc.mc).currentFrameLabel == "swing")
               {
                  team.game.soundManager.playSound("swordwrathSwing1",px,py);
               }
               _mc.gotoAndStop("shieldBash");
               _mc.mc.nextFrame();
               if(_mc.mc.currentFrame == 12)
               {
                  hit = this.checkForBlockHit();
                  if(this.bossShieldSlamActive)
                  {
                     this.bossAbilityCooldownFrames = BOSS_ABILITY_COOLDOWN_FRAMES;
                     this.bossShieldSlamActive = false;
                     this.releaseBossBraceFormation();
                  }
               }
               if(_mc.mc.currentFrame == _mc.mc.totalFrames)
               {
                  this.isShieldBashing = false;
                  this.bossCommandedShieldBash = false;
               }
            }
            else if(this.inBlock)
            {
               if(_mc.currentLabel == "shieldBash")
               {
                  _mc.gotoAndStop("block");
                  _mc.mc.gotoAndStop(15);
               }
               else
               {
                  _mc.gotoAndStop("block");
               }
               if(this.isBlocking)
               {
                  if(_mc.mc.currentFrame < 15)
                  {
                     _mc.mc.nextFrame();
                  }
               }
               else
               {
                  _mc.mc.nextFrame();
                  if(_mc.mc.currentFrame == _mc.mc.totalFrames)
                  {
                     this.inBlock = false;
                  }
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
               if(MovieClip(mc.mc).currentFrameLabel == "swing")
               {
                  team.game.soundManager.playSound("swordwrathSwing1",px,py);
               }
               if(!hasHit)
               {
                  hasHit = this.checkForHit();
               }
               if(MovieClip(_mc.mc).totalFrames == MovieClip(_mc.mc).currentFrame)
               {
                  _state = S_RUN;
               }
            }
         }
         else if(isDead == false)
         {
            isDead = true;
            if(_isDualing)
            {
               _mc.gotoAndStop(_currentDual.defendLabel);
               if(MovieClip(_mc.mc).currentFrame == MovieClip(_mc.mc).totalFrames)
               {
                  isDualing = false;
                  mc.filters = [];
               }
            }
            else
            {
               _mc.gotoAndStop(getDeathLabel(game));
            }
            this.team.removeUnit(this,game);
         }
         if(!isDead && MovieClip(_mc.mc).currentFrame == MovieClip(_mc.mc).totalFrames)
         {
            MovieClip(_mc.mc).gotoAndStop(1);
         }
         if(_isDualing || !this.inBlock || isDead)
         {
            Util.animateMovieClip(_mc);
         }
         if(this.forcedWeaponSkin != "" || this.forcedArmorSkin != "" || this.forcedMiscSkin != "")
         {
            Spearton.setItem(_speartonMc(mc),this.forcedWeaponSkin,this.forcedArmorSkin,this.forcedMiscSkin);
         }
         else if(this.isBoss)
         {
            Spearton.setItem(_speartonMc(mc),BOSS_WEAPON_SKIN,BOSS_ARMOR_SKIN,BOSS_MISC_SKIN);
         }
         else if(!hasDefaultLoadout)
         {
            Spearton.setItem(_speartonMc(mc),team.loadout.getItem(this.type,MarketItem.T_WEAPON),team.loadout.getItem(this.type,MarketItem.T_ARMOR),team.loadout.getItem(this.type,MarketItem.T_MISC));
         }
      }
      
      private function shieldHit(unit:Unit) : *
      {
         if(this.stunned == null && unit.team != this.team && unit.pz == 0)
         {
            if(Math.pow(unit.px + unit.dx - dx - px,2) + Math.pow(unit.py + unit.dy - dy - py,2) < Math.pow(5 * unit.hitBoxWidth * (this.perspectiveScale + unit.perspectiveScale) / 2,2))
            {
               this.stunned = unit;
               unit.damage(0,this.damageToDeal,this);
               unit.stun(this.stunTime);
               unit.applyVelocity(this.stunForce * Util.sgn(mc.scaleX));
            }
         }
      }
      
      private function bossShieldHit(unit:Unit) : *
      {
         var deltaX:Number = NaN;
         var deltaY:Number = NaN;
         if(unit.team != this.team && unit.pz == 0)
         {
            deltaX = unit.px + unit.dx - dx - px;
            deltaY = unit.py + unit.dy - dy - py;
            if(Util.sgn(deltaX) == Util.sgn(mc.scaleX) && Math.abs(deltaX) < BOSS_SHIELD_SLAM_RADIUS_X && Math.abs(deltaY) < BOSS_SHIELD_SLAM_RADIUS_Y)
            {
               unit.damage(0,this.damageToDeal,this);
               unit.stun(this.bossShieldSlamStunTime);
               unit.applyVelocity(this.stunForce * Util.sgn(mc.scaleX));
            }
         }
      }
      
      protected function checkForBlockHit() : Boolean
      {
         if(this.bossShieldSlamActive)
         {
            team.game.spatialHash.mapInArea(px - BOSS_SHIELD_SLAM_RADIUS_X,py - BOSS_SHIELD_SLAM_RADIUS_Y,px + BOSS_SHIELD_SLAM_RADIUS_X,py + BOSS_SHIELD_SLAM_RADIUS_Y,this.bossShieldHit);
         }
         else
         {
            this.stunned = null;
            team.game.spatialHash.mapInArea(px,py,px + 30,py + 30,this.shieldHit);
         }
         return true;
      }
      
      public function stopBlocking() : void
      {
         this.isBlocking = false;
         this.inBlock = false;
         if(_state != S_ATTACK)
         {
            _state = S_RUN;
         }
      }
      
      public function startBlocking() : void
      {
         if(team.tech.isResearched(Tech.BLOCK))
         {
            _state = S_RUN;
            hasHit = false;
            this.isBlocking = true;
            this.inBlock = true;
            team.game.soundManager.playSound("speartonHoghSound",px,py);
         }
      }

      override public function setActionInterface(a:ActionInterface) : void
      {
         super.setActionInterface(a);
         if(team.tech.isResearched(Tech.BLOCK))
         {
            a.setAction(0,0,UnitCommand.SPEARTON_BLOCK);
         }
         if(team.tech.isResearched(Tech.SHIELD_BASH))
         {
            a.setAction(1,0,UnitCommand.SHIELD_BASH);
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
            this.bossLastNormalAttackFrame = team.game.frame;
         }
      }
      
      override public function damage(type:int, amount:int, inflictor:Entity, modifier:Number = 1) : void
      {
         if(this.isBoss)
         {
            modifier *= BOSS_DAMAGE_TAKEN_MULTIPLIER;
         }
         if(this.isBoss && Boolean(type & Unit.D_ARROW))
         {
            modifier *= 1 - BOSS_PROJECTILE_RESISTANCE;
         }
         if(this.inBlock)
         {
            super.damage(type,amount - amount * this.shieldwallDamageReduction,inflictor,modifier * (1 - this.shieldwallDamageReduction));
         }
         else
         {
            super.damage(type,amount,inflictor,modifier);
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
      
      public function get isBlocking() : Boolean
      {
         return this._isBlocking;
      }
      
      public function set isBlocking(value:Boolean) : void
      {
         this._isBlocking = value;
      }
      
      public function get inBlock() : Boolean
      {
         return this._inBlock;
      }
      
      public function set inBlock(value:Boolean) : void
      {
         this._inBlock = value;
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
      }

      public function tryBossBraceShieldSlam() : void
      {
         var ally:Spearton = null;
         if(!this.isBoss || this.hasBossAbilitySpawnLock() || this.bossAbilityCooldownFrames > 0 || this.bossBraceDelayFrames > 0 || this.isShieldBashing)
         {
            return;
         }
         if(team.game.gameScreen is CampaignGameScreen && !CampaignGameScreen(team.game.gameScreen).canUseRebelsUnitedBossAbility(this,"spearton"))
         {
            return;
         }
         this.isBossMovementLocked = true;
         for each(ally in team.unitGroups[Unit.U_SPEARTON])
         {
            if(ally != null && ally.isAlive() && ally != this && ally.sqrDistanceToTarget(this) <= BOSS_BRACE_RADIUS * BOSS_BRACE_RADIUS && ally.canJoinBossBraceWithLeader())
            {
               ally.commandBossBraceShieldBash();
            }
         }
         this.startBlocking();
         this.bossBraceDelayFrames = BOSS_BRACE_DELAY_FRAMES;
         this.bossShieldSlamActive = true;
      }

      public function commandBossBraceShieldBash() : void
      {
         if(this.isAlive() && !this.isShieldBashing)
         {
            _state = S_RUN;
            hasHit = false;
            this.isBossMovementLocked = true;
            this.startBlocking();
            this.bossBraceDelayFrames = BOSS_BRACE_DELAY_FRAMES;
            this.bossCommandedShieldBash = true;
         }
      }

      public function get isInBossBraceSequence() : Boolean
      {
         return this.bossBraceDelayFrames > 0 || this.bossCommandedShieldBash || this.bossShieldSlamActive;
      }

      public function hasNearbyCombatSpeartons() : Boolean
      {
         var ally:Spearton = null;
         var nearbyCount:int = 0;
         for each(ally in team.unitGroups[Unit.U_SPEARTON])
         {
            if(ally == null || ally == this || !ally.isAlive() || ally.sqrDistanceToTarget(this) > BOSS_TRIGGER_ALLY_RADIUS * BOSS_TRIGGER_ALLY_RADIUS || !ally.canJoinBossBraceWithLeader())
            {
               continue;
            }
            ++nearbyCount;
        }
         return nearbyCount >= 1;
      }

      public function canJoinBossBraceWithLeader() : Boolean
      {
         var target:Unit = this.ai.getClosestTarget();
         if(target == null || target.team == this.team || !target.isTargetable())
         {
            return false;
         }
         if(this._state == S_ATTACK)
         {
            return true;
         }
         if(this.ai.currentCommand != null && this.ai.currentCommand.type == UnitCommand.ATTACK_MOVE)
         {
            return this.sqrDistanceToTarget(target) <= BOSS_COMBAT_RADIUS * BOSS_COMBAT_RADIUS;
         }
         return this.sqrDistanceToTarget(target) <= BOSS_COMBAT_RADIUS * BOSS_COMBAT_RADIUS && this.mayAttack(target);
      }

      public function get isBoss() : Boolean
      {
         return this._isBoss;
      }

      public function resetBossSpecialDebugState() : void
      {
         this.bossAbilityCooldownFrames = 0;
         this.bossBraceDelayFrames = 0;
         this.bossShieldSlamActive = false;
         this.bossCommandedShieldBash = false;
         this.bossAbilitySpawnLockFrames = 0;
         this.isShieldBashing = false;
         this.isBossMovementLocked = false;
         this.stopBlocking();
      }

      public function get bossCombatRadius() : Number
      {
         return BOSS_COMBAT_RADIUS;
      }

      public function hasRecentBossNormalAttack() : Boolean
      {
         return team != null && team.game != null && team.game.frame - this.bossLastNormalAttackFrame <= BOSS_RECENT_ATTACK_WINDOW_FRAMES;
      }

      private function releaseBossBraceFormation() : void
      {
         var ally:Spearton = null;
         this.isBossMovementLocked = false;
         this.stopBlocking();
         for each(ally in team.unitGroups[Unit.U_SPEARTON])
         {
            if(ally != null && ally.isAlive() && ally.sqrDistanceToTarget(this) <= BOSS_BRACE_RADIUS * BOSS_BRACE_RADIUS)
            {
               ally.bossBraceDelayFrames = 0;
               ally.bossCommandedShieldBash = false;
               ally.isBossMovementLocked = false;
               ally.stopBlocking();
            }
         }
      }
   }
}

