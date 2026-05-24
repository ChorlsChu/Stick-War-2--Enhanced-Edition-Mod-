package com.brockw.stickwar.engine.units
{
   import com.brockw.game.Util;
   import com.brockw.stickwar.campaign.Campaign;
   import com.brockw.stickwar.engine.ActionInterface;
   import com.brockw.stickwar.engine.Ai.*;
   import com.brockw.stickwar.engine.Ai.command.*;
   import com.brockw.stickwar.engine.Entity;
   import com.brockw.stickwar.engine.StickWar;
   import com.brockw.stickwar.engine.Team.Tech;
   import com.brockw.stickwar.market.MarketItem;
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.utils.Dictionary;
   
   public class Medusa extends Unit
   {
      private static const BOSS_CAPE_SKIN:String = "Snake Cape";

      private static const BOSS_CROWN_SKIN:String = "Jewel Crown";

      private static const BOSS_REGEN_DELAY_FRAMES:int = 30 * 3;

      private static const BOSS_FALLBACK_DEFAULT_FRAMES:int = 30 * 2;
      
      private var WEAPON_REACH:int;
      
      private var snakeFrames:Dictionary;
      
      private var poisonSpell:SpellCooldown;
      
      private var stoneSpell:SpellCooldown;
      
      private var inPoisonSpell:Boolean;
      
      private var inStoneSpell:Boolean;
      
      private var targetUnit:Unit;

      private var bossRegenRate:Number;

      private var lastDamageFrame:int;

      private var bossFallbackUntilFrame:int;
      
      public function Medusa(game:StickWar)
      {
         super(game);
         _mc = new _medusaMc();
         this.snakeFrames = new Dictionary();
         this.bossRegenRate = 0;
         this.lastDamageFrame = 0;
         this.bossFallbackUntilFrame = 0;
         this.init(game);
         addChild(_mc);
         ai = new MedusaAi(this);
         initSync();
         firstInit();
      }
      
      public static function setItem(mc:MovieClip, weapon:String, armor:String, misc:String) : void
      {
         var m:_medusaMc = _medusaMc(mc);
         if(Boolean(m.mc.medusacape))
         {
            if(armor != "")
            {
               m.mc.medusacape.gotoAndStop(armor);
            }
         }
         if(Boolean(m.mc.medusacrown))
         {
            if(misc != "")
            {
               m.mc.medusacrown.gotoAndStop(misc);
            }
         }
      }
      
      override public function weaponReach() : Number
      {
         return this.WEAPON_REACH;
      }
      
      override public function playDeathSound() : void
      {
         team.game.soundManager.playSoundRandom("Medusa",3,px,py);
      }
      
      override public function init(game:StickWar) : void
      {
         var d:DisplayObject = null;
         initBase();
         this.WEAPON_REACH = game.xml.xml.Chaos.Units.medusa.weaponReach;
         population = game.xml.xml.Chaos.Units.medusa.population;
         _mass = game.xml.xml.Chaos.Units.medusa.mass;
         _maxForce = game.xml.xml.Chaos.Units.medusa.maxForce;
         _dragForce = game.xml.xml.Chaos.Units.medusa.dragForce;
         _scale = game.xml.xml.Chaos.Units.medusa.scale;
         _maxVelocity = game.xml.xml.Chaos.Units.medusa.maxVelocity;
         damageToDeal = game.xml.xml.Chaos.Units.medusa.baseDamage;
         this.createTime = game.xml.xml.Chaos.Units.medusa.cooldown;
         maxHealth = health = game.xml.xml.Chaos.Units.medusa.health;
         loadDamage(game.xml.xml.Chaos.Units.medusa);
         type = Unit.U_MEDUSA;
         _mc.stop();
         _mc.width *= _scale;
         _mc.height *= _scale;
         _state = S_RUN;
         MovieClip(_mc.mc.gotoAndPlay(1));
         MovieClip(_mc.gotoAndStop(1));
         drawShadow();
         this.inPoisonSpell = this.inStoneSpell = false;
         for(var i:int = 0; i < _mc.mc.snakes.numChildren; i++)
         {
            d = _mc.mc.snakes.getChildAt(i);
            if(d is MovieClip)
            {
               this.snakeFrames[d.name] = int(game.random.nextNumber() * MovieClip(d).totalFrames);
            }
         }
         this.poisonSpell = new SpellCooldown(game.xml.xml.Chaos.Units.medusa.poison.effect,game.xml.xml.Chaos.Units.medusa.poison.cooldown,game.xml.xml.Chaos.Units.medusa.poison.mana);
         this.stoneSpell = new SpellCooldown(game.xml.xml.Chaos.Units.medusa.stone.effect,game.xml.xml.Chaos.Units.medusa.stone.cooldown,game.xml.xml.Chaos.Units.medusa.stone.mana);
         this.bossRegenRate = game.xml.xml.garrisonHealRate;
         this.lastDamageFrame = game.frame;
         this.bossFallbackUntilFrame = 0;
      }
      
      override public function isBusy() : Boolean
      {
         return !this.notInSpell() || isBusyForSpell;
      }
      
      private function notInSpell() : Boolean
      {
         return !this.inPoisonSpell && !this.inStoneSpell;
      }
      
      public function poisonSpray() : void
      {
         if(!this.isBossMedusa() && !team.tech.isResearched(Tech.MEDUSA_POISON))
         {
            return;
         }
         if(this.poisonSpell.spellActivate(team))
         {
            team.game.soundManager.playSound("acidPoolSound",px,py);
            this.inPoisonSpell = true;
            _state = S_ATTACK;
         }
      }
      
      public function poisonPoolCooldown() : Number
      {
         return this.poisonSpell.cooldown();
      }
      
      public function stoneCooldown() : Number
      {
         return this.stoneSpell.cooldown();
      }
      
      public function stone(unit:Unit) : void
      {
         if(this.stoneSpell.spellActivate(team))
         {
            team.game.soundManager.playSound("medusaPetrifySound",px,py);
            this.inStoneSpell = true;
            this.targetUnit = unit;
            _state = S_ATTACK;
         }
      }
      
      override public function setBuilding() : void
      {
         building = team.buildings["MedusaBuilding"];
      }
      
      override public function getDamageToDeal() : Number
      {
         return damageToDeal;
      }
      
      override public function update(game:StickWar) : void
      {
         var i:int = 0;
         var d:DisplayObject = null;
         this.poisonSpell.update();
         this.stoneSpell.update();
         updateCommon(game);
         if(!isDieing)
         {
            if(this.isBossMedusa() && this.health < this.maxHealth && game.frame - this.lastDamageFrame >= BOSS_REGEN_DELAY_FRAMES)
            {
               this.heal(this.bossRegenRate,1);
            }
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
            else if(this.inPoisonSpell)
            {
               _mc.gotoAndStop("poisonAttack");
               if(MovieClip(_mc.mc).currentFrame == 3)
               {
                  game.projectileManager.initPoisonPool(this.px,this.py,this,0);
               }
               if(MovieClip(_mc.mc).totalFrames == MovieClip(_mc.mc).currentFrame)
               {
                  _state = S_RUN;
                  this.inPoisonSpell = false;
               }
            }
            else if(this.inStoneSpell)
            {
               _mc.gotoAndStop("stoneAttack");
               if(MovieClip(_mc.mc).currentFrame == 20)
               {
                  if(Boolean(this.targetUnit))
                  {
                     if(this.targetUnit.isArmoured)
                     {
                        this.targetUnit.stoneAttack(game.xml.xml.Chaos.Units.medusa.stone.damageToArmour);
                     }
                     else
                     {
                        this.targetUnit.stoneAttack(game.xml.xml.Chaos.Units.medusa.stone.damageToNotArmour);
                     }
                  }
               }
               if(MovieClip(_mc.mc).totalFrames == MovieClip(_mc.mc).currentFrame)
               {
                  _state = S_RUN;
                  this.inStoneSpell = false;
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
               if(MovieClip(_mc.mc).currentFrame > MovieClip(_mc.mc).totalFrames / 2 && !hasHit)
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
         if(!isDead)
         {
            for(i = 0; i < _mc.mc.snakes.numChildren; i++)
            {
               d = _mc.mc.snakes.getChildAt(i);
               if(d is MovieClip)
               {
                  this.snakeFrames[d.name] = (this.snakeFrames[d.name] + 1) % MovieClip(d).totalFrames;
                  MovieClip(d).gotoAndStop(this.snakeFrames[d.name]);
               }
            }
            if(_mc.mc.multisnakes2 != null)
            {
               _mc.mc.multisnakes2.gotoAndStop((_mc.mc.multisnakes1.currentFrame + 10) % _mc.mc.multisnakes1.totalFrames);
            }
         }
         Util.animateMovieClip(_mc);
         if(this.isBossMedusa())
         {
            hasDefaultLoadout = true;
            Medusa.setItem(_medusaMc(mc),"",BOSS_CAPE_SKIN,BOSS_CROWN_SKIN);
         }
         else if(!hasDefaultLoadout)
         {
            Medusa.setItem(_medusaMc(mc),team.loadout.getItem(this.type,MarketItem.T_WEAPON),team.loadout.getItem(this.type,MarketItem.T_ARMOR),team.loadout.getItem(this.type,MarketItem.T_MISC));
         }
      }
      
      override public function setActionInterface(a:ActionInterface) : void
      {
         super.setActionInterface(a);
         a.setAction(0,0,UnitCommand.STONE);
         if(team.tech.isResearched(Tech.MEDUSA_POISON))
         {
            a.setAction(1,0,UnitCommand.POISON_POOL);
         }
      }
      
      public function enableSuperMedusa() : void
      {
         this.health = this.maxHealth = team.game.xml.xml.Chaos.Units.medusa.superHealth;
         if(team.game.main != null && team.game.main.campaign != null)
         {
            if(team.game.main.campaign.difficultyLevel == Campaign.D_HARD)
            {
               this.health = this.maxHealth = this.maxHealth * 1.25;
            }
            else if(team.game.main.campaign.difficultyLevel == Campaign.D_INSANE)
            {
               this.health = this.maxHealth = this.maxHealth * 1.5;
            }
         }
         this.scale = team.game.xml.xml.Chaos.Units.medusa.superScale;
         _damageToArmour = team.game.xml.xml.Chaos.Units.medusa.superDamage;
         _damageToNotArmour = team.game.xml.xml.Chaos.Units.medusa.superDamage;
         this.stoneSpell = new SpellCooldown(team.game.xml.xml.Chaos.Units.medusa.stone.effect,team.game.xml.xml.Chaos.Units.medusa.stone.superCooldown,team.game.xml.xml.Chaos.Units.medusa.stone.mana);
         maxHealth = this.maxHealth;
         healthBar.totalHealth = maxHealth;
         this.lastDamageFrame = team.game.frame;
         this.bossFallbackUntilFrame = 0;
         hasDefaultLoadout = true;
         this.cure();
      }

      override public function poison(p:Number) : void
      {
         if(this.isBossMedusa())
         {
            if(this.poisonDamage > 0)
            {
               this.cure();
            }
            return;
         }
         super.poison(p);
      }

      override public function damage(type:int, amount:int, inflictor:Entity, modifier:Number = 1) : void
      {
         super.damage(type,amount,inflictor,modifier);
         if(amount > 0 && team != null && this.health > 0)
         {
            this.lastDamageFrame = team.game.frame;
         }
      }
      
      override public function attack() : void
      {
         var id:int = 0;
         if(this.isBossFallbackActive())
         {
            return;
         }
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
            if(Math.abs(px - target.px) < this.WEAPON_REACH && Math.abs(py - target.py) < 40 && this.getDirection() == Util.sgn(target.px - px))
            {
               return true;
            }
         }
         return false;
      }
      
      override public function stateFixForCutToWalk() : void
      {
         if(!this.inPoisonSpell && !this.inStoneSpell)
         {
            super.stateFixForCutToWalk();
            this.inPoisonSpell = false;
            this.inStoneSpell = false;
         }
      }

      public function triggerBossFallback(frames:int = 0) : void
      {
         if(!this.isBossMedusa() || team == null || !this.isAlive() || this.isDualing)
         {
            return;
         }
         if(frames <= 0)
         {
            frames = BOSS_FALLBACK_DEFAULT_FRAMES;
         }
         this.bossFallbackUntilFrame = team.game.frame + frames;
         this.inPoisonSpell = false;
         this.inStoneSpell = false;
         this.targetUnit = null;
         hasHit = false;
         attackStartFrame = 0;
         framesInAttack = 0;
         _state = S_RUN;
         _mc.gotoAndStop("run");
         MovieClip(_mc.mc).gotoAndPlay(1);
      }

      public function isBossFallbackActive() : Boolean
      {
         return this.isBossMedusa() && team != null && team.game.frame < this.bossFallbackUntilFrame;
      }

      private function isBossMedusa() : Boolean
      {
         return team != null && this.maxHealth >= team.game.xml.xml.Chaos.Units.medusa.superHealth;
      }
   }
}

