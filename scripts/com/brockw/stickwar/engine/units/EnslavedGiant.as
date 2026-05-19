package com.brockw.stickwar.engine.units
{
   import com.brockw.game.Util;
   import com.brockw.stickwar.engine.Ai.*;
   import com.brockw.stickwar.engine.StickWar;
   import com.brockw.stickwar.engine.Team.Tech;
   import com.brockw.stickwar.market.MarketItem;
   import flash.display.MovieClip;
   import flash.geom.Point;
   
   public class EnslavedGiant extends RangedUnit
   {
      
      private static const WEAPON_REACH:int = 90;
      
      private var target:Unit;
      
      private var scaleI:Number;
      
      private var scaleII:Number;
      
      private var hasGrowled:Boolean;
      
      public function EnslavedGiant(game:StickWar)
      {
         super(game);
         _mc = new _giantMc();
         this.init(game);
         addChild(_mc);
         ai = new EnslavedGiantAi(this);
         initSync();
         firstInit();
      }
      
      public static function setItem(mc:MovieClip, weapon:String, armor:String, misc:String) : void
      {
         var m:_giantMc = _giantMc(mc);
         if(Boolean(m.mc.giantbag))
         {
            if(weapon != "")
            {
               m.mc.giantbag.gotoAndStop(weapon);
            }
         }
      }
      
      override public function applyVelocity(xf:Number, yf:Number = 0, zf:Number = 0) : void
      {
      }
      
      override public function init(game:StickWar) : void
      {
         initBase();
         this.hasGrowled = false;
         _maximumRange = game.xml.xml.Order.Units.giant.maximumRange;
         population = game.xml.xml.Chaos.Units.giant.population;
         maxHealth = health = game.xml.xml.Order.Units.giant.health;
         this.createTime = game.xml.xml.Order.Units.giant.cooldown;
         projectileVelocity = game.xml.xml.Order.Units.giant.projectileVelocity;
         _mass = game.xml.xml.Order.Units.giant.mass;
         _maxForce = game.xml.xml.Order.Units.giant.maxForce;
         _dragForce = game.xml.xml.Order.Units.giant.dragForce;
         _scale = game.xml.xml.Order.Units.giant.scale;
         _maxVelocity = game.xml.xml.Order.Units.giant.maxVelocity;
         this.scaleI = game.xml.xml.Order.Units.giant.growthIScale;
         this.scaleII = game.xml.xml.Order.Units.giant.growthIIScale;
         type = Unit.U_ENSLAVED_GIANT;
         loadDamage(game.xml.xml.Order.Units.giant);
         _mc.stop();
         _mc.width *= _scale;
         _mc.height *= _scale;
         _state = S_RUN;
         MovieClip(_mc.mc.gotoAndPlay(1));
         MovieClip(_mc.gotoAndStop(1));
         drawShadow();
         this.healthBar.y = -mc.mc.height * 1.1;
         aimXOffset = 50 * 2 - 35;
         aimYOffset = -90 * 2 + 102;
      }
      
      override public function setBuilding() : void
      {
         building = team.buildings["SiegeBuilding"];
      }
      
      override public function update(game:StickWar) : void
      {
         var p:Point = null;
         var yVel:Number = NaN;
         if(!this.hasGrowled)
         {
            this.hasGrowled = true;
            team.game.soundManager.playSoundRandom("GiantGrowl",6,px,py);
         }
         stunTimeLeft = 0;
         _dz = 0;
         if(team.tech.isResearched(Tech.GIANT_GROWTH_II))
         {
            if(_scale != this.scaleII)
            {
               health = game.xml.xml.Order.Units.giant.healthII - (maxHealth - health);
               maxHealth = game.xml.xml.Order.Units.giant.healthII;
               healthBar.totalHealth = maxHealth;
            }
            this.pheight *= this.scaleII / this.scaleI;
            _scale = this.scaleII;
         }
         else if(team.tech.isResearched(Tech.GIANT_GROWTH_I))
         {
            if(_scale != this.scaleI)
            {
               health = game.xml.xml.Order.Units.giant.healthI - (maxHealth - health);
               maxHealth = game.xml.xml.Order.Units.giant.healthI;
               healthBar.totalHealth = maxHealth;
            }
            this.pheight *= this.scaleI / _scale;
            _scale = this.scaleI;
         }
         p = _mc.localToGlobal(new Point(50,-90));
         p = this.globalToLocal(p);
         aimXOffset = p.x;
         aimYOffset = p.y + 25;
         super.update(game);
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
                  px += Util.sgn(mc.scaleX) * _currentDual.finalXOffset * this.scaleX * this._scale * _worldScaleX * this.perspectiveScale;
                  dx = 0;
                  dy = 0;
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
               if(MovieClip(_mc.mc).currentFrame == 1)
               {
                  team.game.soundManager.playSound("BoulderThrowSound",px,py);
               }
               if(MovieClip(_mc.mc).currentFrame == 33)
               {
                  p = _mc.localToGlobal(new Point(50,-90));
                  p = game.battlefield.globalToLocal(p);
                  yVel = 0;
                  if(inRange(this.target))
                  {
                     yVel = angleToTargetW(this.target,projectileVelocity,angleToTarget(this.target));
                  }
                  if(mc.scaleX < 0)
                  {
                     game.projectileManager.initBoulder(p.x,p.y,180 - bowAngle,projectileVelocity,0,yVel,this,damageToDeal,false);
                  }
                  else
                  {
                     game.projectileManager.initBoulder(p.x,p.y,bowAngle,projectileVelocity,0,yVel,this,damageToDeal,false);
                  }
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
            team.game.soundManager.playSoundRandom("GiantDeath",3,px,py);
            if(_isDualing)
            {
               _mc.gotoAndStop(_currentDual.defendLabel);
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
         MovieClip(_mc.mc).nextFrame();
         _mc.mc.stop();
         if(!hasDefaultLoadout)
         {
            EnslavedGiant.setItem(mc,team.loadout.getItem(this.type,MarketItem.T_WEAPON),"","");
         }
      }
      
      override public function aim(target:Unit) : void
      {
         var a:Number = angleToTarget(target);
         if(target != null && this._state == Unit.S_ATTACK && !inRange(target))
         {
            return;
         }
         if(Math.abs(normalise(angleToBowSpace(a) - bowAngle)) < 10)
         {
            bowAngle += normalise(angleToBowSpace(a) - bowAngle) * 1;
         }
         else
         {
            bowAngle += normalise(angleToBowSpace(a) - bowAngle) * 1;
         }
      }
      
      override public function shoot(game:StickWar, target:Unit) : void
      {
         var id:int = 0;
         if(_state != S_ATTACK)
         {
            id = team.game.random.nextInt() % this._attackLabels.length;
            _mc.gotoAndStop("attack_" + this._attackLabels[id]);
            MovieClip(_mc.mc).gotoAndStop(1);
            _state = S_ATTACK;
            this.target = target;
         }
      }
      
      override public function stateFixForCutToWalk() : void
      {
         if(_state != S_ATTACK)
         {
            super.stateFixForCutToWalk();
         }
      }
      
      override protected function isAbleToWalk() : Boolean
      {
         return _state == S_RUN;
      }
   }
}

