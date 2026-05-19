package com.brockw.stickwar.engine.units
{
   import com.brockw.game.Util;
   import com.brockw.stickwar.engine.ActionInterface;
   import com.brockw.stickwar.engine.Ai.*;
   import com.brockw.stickwar.engine.Ai.command.*;
   import com.brockw.stickwar.engine.Entity;
   import com.brockw.stickwar.engine.StickWar;
   import com.brockw.stickwar.engine.Team.Tech;
   import com.brockw.stickwar.market.MarketItem;
   import flash.display.MovieClip;
   import flash.geom.Point;
   
   public class Archer extends RangedUnit
   {
      private static const BOSS_ARMOR_SKIN:String = "Robin Hood Hat";
      
      private static const BOSS_MISC_SKIN:String = "Robin Hood Quiver";
      
      private static const BOSS_COMMAND_RADIUS:Number = 260;
      
      private static const BOSS_COMMAND_COOLDOWN_FRAMES:int = 30 * 16;
      
      private static const BOSS_RETREAT_COOLDOWN_FRAMES:int = 30 * 20;
      
      private static const BOSS_REINFORCEMENT_COUNT:int = 4;

      private static const BOSS_GARRISON_REGROUP_FRAMES:int = 45;
      
      private static const BOSS_DAMAGE_TAKEN_MULTIPLIER:Number = 1 / 1.75;
      
      private static const BOSS_REAR_GAP:Number = 90;
      
      private var _isCastleArcher:Boolean;
      
      private var isFire:Boolean;
      
      private var archerFireSpellCooldown:SpellCooldown;
      
      private var arrowDamage:Number;
      
      private var bowFrame:int;
      
      private var normalRange:Number;
      
      private var fireArrowRange:Number;
      
      private var areaDamage:Number;
      
      private var area:Number;

      private var _isAutoKiteToggled:Boolean;

      private var _isBoss:Boolean;

      private var bossCommandCooldownFrames:int;

      private var bossRetreatCooldownFrames:int;

      private var bossUsedGarrisonRetreat:Boolean;

      private var _bossIsRegrouping:Boolean;

      private var bossGarrisonRegroupFrames:int;

      private var bossGarrisonRegroupActive:Boolean;
      
      public function Archer(game:StickWar)
      {
         super(game);
         this._isAutoKiteToggled = false;
         _mc = new _archer();
         this.init(game);
         addChild(_mc);
         ai = new ArcherAi(this);
         initSync();
         firstInit();
         this.archerFireSpellCooldown = new SpellCooldown(0,game.xml.xml.Order.Units.archer.fire.cooldown,game.xml.xml.Order.Units.archer.fire.mana);
      }
      
      public static function setItem(mc:MovieClip, weapon:String, armor:String, misc:String) : void
      {
         var m:_archer = _archer(mc);
         if(Boolean(m.mc.archerBag))
         {
            if(misc != "")
            {
               m.mc.archerBag.gotoAndStop(misc);
            }
         }
         if(Boolean(m.mc.head))
         {
            if(armor != "")
            {
               m.mc.head.gotoAndStop(armor);
            }
         }
      }
      
      override public function setActionInterface(a:ActionInterface) : void
      {
         super.setActionInterface(a);
         a.setAction(0,1,UnitCommand.HEAL);
         if(team.tech.isResearched(Tech.ARCHIDON_FIRE))
         {
            a.setAction(0,0,UnitCommand.ARCHER_FIRE);
         }
      }
      
      public function getFireCoolDown() : Number
      {
         return this.archerFireSpellCooldown.cooldown();
      }
      
      override public function init(game:StickWar) : void
      {
         initBase();
         _maximumRange = this.normalRange = game.xml.xml.Order.Units.archer.maximumRange;
         this.fireArrowRange = game.xml.xml.Order.Units.archer.fire.range;
         maxHealth = health = game.xml.xml.Order.Units.archer.health;
         this.createTime = game.xml.xml.Order.Units.archer.cooldown;
         this.projectileVelocity = game.xml.xml.Order.Units.archer.arrowVelocity;
         this.arrowDamage = game.xml.xml.Order.Units.archer.damage;
         population = game.xml.xml.Order.Units.archer.population;
         _mass = game.xml.xml.Order.Units.archer.mass;
         _maxForce = game.xml.xml.Order.Units.archer.maxForce;
         _dragForce = game.xml.xml.Order.Units.archer.dragForce;
         _scale = game.xml.xml.Order.Units.archer.scale;
         _maxVelocity = game.xml.xml.Order.Units.archer.maxVelocity;
         this.loadDamage(game.xml.xml.Order.Units.archer);
         this.areaDamage = 0;
         this.area = 0;
         if(this.isCastleArcher)
         {
            this._maximumRange = this.normalRange = game.xml.xml.Order.Units.archer.castleRange;
            _scale *= 1.1;
            this.area = game.xml.xml.Order.Units.archer.castleArea;
            this.areaDamage = game.xml.xml.Order.Units.archer.castleAreaDamage;
         }
         type = Unit.U_ARCHER;
         _mc.stop();
         _mc.width *= _scale;
         _mc.height *= _scale;
         _state = S_RUN;
         MovieClip(_mc.mc.gotoAndPlay(1));
         MovieClip(_mc.gotoAndStop(1));
         drawShadow();
         this.isFire = false;
         this.bowFrame = 1;
         this._isBoss = false;
         this.bossCommandCooldownFrames = 0;
         this.bossRetreatCooldownFrames = 0;
         this.bossUsedGarrisonRetreat = false;
         this._bossIsRegrouping = false;
         this.bossGarrisonRegroupFrames = 0;
         this.bossGarrisonRegroupActive = false;
      }
      
      override protected function loadDamage(unitXml:XMLList) : void
      {
         var _damage:Number = NaN;
         this.isArmoured = unitXml.armoured == 1 ? true : false;
         if(!this._isCastleArcher)
         {
            _damage = Number(unitXml.damage);
            this._damageToArmour = _damage + Number(unitXml.toArmour);
            this._damageToNotArmour = _damage + Number(unitXml.toNotArmour);
         }
         else
         {
            _damage = Number(unitXml.castleDamage);
            this._damageToArmour = _damage + Number(unitXml.castleToArmour);
            this._damageToNotArmour = _damage + Number(unitXml.castleToNotArmour);
         }
      }
      
      override public function setBuilding() : void
      {
         building = team.buildings["ArcheryBuilding"];
      }
      
      public function archerFireArrow() : void
      {
         if(this.archerFireSpellCooldown.spellActivate(team) && team.tech.isResearched(Tech.ARCHIDON_FIRE))
         {
            this.isFire = true;
            takeBottomTrajectory = false;
            _maximumRange = this.fireArrowRange;
         }
      }
      
      override public function update(game:StickWar) : void
      {
         super.update(game);
         if(this.bossCommandCooldownFrames > 0)
         {
            --this.bossCommandCooldownFrames;
         }
         if(this.bossRetreatCooldownFrames > 0)
         {
            --this.bossRetreatCooldownFrames;
         }
         if(this.bossGarrisonRegroupFrames > 0)
         {
            --this.bossGarrisonRegroupFrames;
            if(this.bossGarrisonRegroupFrames == 0)
            {
               this.releaseBossGarrisonRegroup(game);
            }
         }
         this.archerFireSpellCooldown.update();
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
               if(MovieClip(_mc.mc).currentFrame > MovieClip(_mc.mc).totalFrames / 2 && !hasHit)
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
            }
            else
            {
               _mc.gotoAndStop(getDeathLabel(game));
            }
            this.team.removeUnit(this,game);
         }
         if(isDead)
         {
            Util.animateMovieClip(_mc);
         }
         else
         {
            if(!isDead && MovieClip(_mc.mc).currentFrame == MovieClip(_mc.mc).totalFrames)
            {
               MovieClip(_mc.mc).gotoAndStop(1);
            }
            MovieClip(_mc.mc).nextFrame();
            _mc.mc.stop();
         }
         var bow:MovieClip = _mc.mc.bow;
         if(bow != null)
         {
            bow.gotoAndStop(this.bowFrame);
            if(this.bowFrame != 1)
            {
               if(this.bowFrame == 46)
               {
                  game.soundManager.playSound("BowReady",px,py);
               }
               bow.nextFrame();
               this.bowFrame += 1;
               if(bow.currentFrame == bow.totalFrames)
               {
                  bow.gotoAndStop(1);
                  this.bowFrame = 1;
               }
            }
         }
         if(this.isCastleArcher)
         {
            Archer.setItem(mc,"Default","Basic Helmet","Default");
         }
         else if(this.isBoss)
         {
            Archer.setItem(mc,"Default",BOSS_ARMOR_SKIN,BOSS_MISC_SKIN);
         }
         else if(!hasDefaultLoadout)
         {
            Archer.setItem(mc,team.loadout.getItem(this.type,MarketItem.T_WEAPON),team.loadout.getItem(this.type,MarketItem.T_ARMOR),team.loadout.getItem(this.type,MarketItem.T_MISC));
         }
         if(_mc.mc.bow != null)
         {
            _mc.mc.bow.rotation = bowAngle;
         }
      }
      
      override public function isLoaded() : Boolean
      {
         var bow:MovieClip = _mc.mc.bow;
         return this.bowFrame < 35;
      }
      
      override public function shoot(game:StickWar, target:Unit) : void
      {
         var bow:MovieClip = null;
         var p:Point = null;
         var v:int = 0;
         var damage:int = 0;
         var poison:Number = NaN;
         var fireDamage:Number = NaN;
         if(_state != S_ATTACK)
         {
            bow = _mc.mc.bow;
            if(this.bowFrame != 1)
            {
               return;
            }
            this.bowFrame += 1;
            bow.nextFrame();
            p = bow.localToGlobal(new Point(0,0));
            p = game.battlefield.globalToLocal(p);
            v = projectileVelocity;
            damage = this.arrowDamage;
            poison = 0;
            fireDamage = 0;
            if(this.isFire)
            {
               fireDamage = Number(game.xml.xml.Order.Units.archer.fire.damage);
            }
            game.soundManager.playSoundRandom("launchArrow",5,px,py);
            if(mc.scaleX < 0)
            {
               game.projectileManager.initArrow(p.x,p.y,180 - bowAngle,v,target.y,angleToTargetW(target,v,angleToTarget(target)),this,damage,poison,this.isFire,this.area,this.areaDamage);
            }
            else
            {
               game.projectileManager.initArrow(p.x,p.y,bowAngle,v,target.y,angleToTargetW(target,v,angleToTarget(target)),this,damage,poison,this.isFire,this.area,this.areaDamage);
            }
            this.isFire = false;
            _maximumRange = this.normalRange;
            takeBottomTrajectory = true;
         }
      }
      
      override public function aim(target:Unit) : void
      {
         var a:Number = angleToTarget(target);
         if(Math.abs(normalise(angleToBowSpace(a) - bowAngle)) < 10)
         {
            bowAngle += normalise(angleToBowSpace(a) - bowAngle) * 0.8;
         }
         else
         {
            bowAngle += normalise(angleToBowSpace(a) - bowAngle) * 0.1;
         }
      }
      
      override public function mayAttack(target:Unit) : Boolean
      {
         var CASTLE_WIDTH:int = 200;
         if(!this.isCastleArcher && team.direction * px < team.direction * (this.team.homeX + team.direction * CASTLE_WIDTH))
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
         if(aimedAtUnit(target,angleToTarget(target)) && this.inRange(target))
         {
            return true;
         }
         return false;
      }
      
      override public function walk(x:Number, y:Number, intendedX:int) : void
      {
         if(isAbleToWalk())
         {
            baseWalk(x,y,intendedX);
         }
      }
      
      public function get isCastleArcher() : Boolean
      {
         return this._isCastleArcher;
      }
      
      public function set isCastleArcher(value:Boolean) : void
      {
         if(value)
         {
            this._maximumRange = 500;
            this.healthBar.visible = false;
            isStationary = true;
         }
         this._isCastleArcher = value;
      }

      public function get isAutoKiteToggled() : Boolean
      {
         return this._isAutoKiteToggled;
      }

      public function set isAutoKiteToggled(value:Boolean) : void
      {
         this._isAutoKiteToggled = value;
      }

      public function makeBoss() : void
      {
         this._isBoss = true;
         this.isBossUnit = true;
         this.hasDefaultLoadout = true;
         this.bossAbilitySpawnLockFrames = 30 * 2;
         this.isAutoKiteToggled = true;
         this.damageToDeal *= 1.2;
         this._maxVelocity *= 1.08;
         this.normalRange += 70;
         this.fireArrowRange += 70;
         this._maximumRange = this.normalRange;
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

      public function tryBossCommandFireArrows(game:StickWar) : Boolean
      {
         var ally:Unit = null;
         if(!this.isBoss || this.hasBossAbilitySpawnLock() || this.bossCommandCooldownFrames > 0 || this.archerFireSpellCooldown.cooldown() != 0)
         {
            return false;
         }
         if(this.ai.getClosestTarget() == null || this.ai.getClosestTarget().team == this.team)
         {
            return false;
         }
         this.archerFireArrow();
         for each(ally in this.team.units)
         {
            if(ally is Archer && ally != this && !ally.isDead && Math.abs(ally.px - this.px) < BOSS_COMMAND_RADIUS && Math.abs(ally.py - this.py) < 80)
            {
               Archer(ally).archerFireArrow();
            }
         }
         this.bossCommandCooldownFrames = BOSS_COMMAND_COOLDOWN_FRAMES;
         return true;
      }

      public function shouldBossRetreatRegroup() : Boolean
      {
         return this.isBoss && !this.bossUsedGarrisonRetreat && !this.hasBossAbilitySpawnLock() && this.bossRetreatCooldownFrames == 0 && this.countNearbyCombatArchers() <= 2 && this.countLivingAlliedArchers() <= 2;
      }

      public function bossRetreatAndRegroup(game:StickWar) : void
      {
         var i:int = 0;
         var ally:Unit = null;
         var newArcher:Archer = null;
         var attackMoveCommand:AttackMoveCommand = null;
         var retreatCommand:MoveCommand = null;
         var regroupSlot:int = 0;
         var useGarrisonRegroup:Boolean = false;
         this._bossIsRegrouping = true;
         this.bossRetreatCooldownFrames = BOSS_RETREAT_COOLDOWN_FRAMES;
         useGarrisonRegroup = !this.bossUsedGarrisonRetreat && Math.abs(this.px - this.team.homeX) < 220;
         for(i = 0; i < BOSS_REINFORCEMENT_COUNT; i++)
         {
            newArcher = Archer(game.unitFactory.getUnit(Unit.U_ARCHER));
            this.team.spawn(newArcher,game);
            newArcher.x = newArcher.px = this.team.homeX + this.team.direction * (200 + i * 30);
            newArcher.y = newArcher.py = Math.max(90,Math.min(game.map.height - 90,game.map.height / 2 + (i - 1.5) * 55));
            this.team.population += newArcher.population;
            if(useGarrisonRegroup)
            {
               newArcher.x = newArcher.px = this.team.homeX;
               newArcher.y = newArcher.py = game.map.height / 2;
               this.team.garrison(true,newArcher);
            }
            else
            {
               attackMoveCommand = new AttackMoveCommand(game);
               attackMoveCommand.type = UnitCommand.ATTACK_MOVE;
               attackMoveCommand.goalX = this.team.enemyTeam.statue.px;
               attackMoveCommand.goalY = game.map.height / 2;
               attackMoveCommand.realX = attackMoveCommand.goalX;
               attackMoveCommand.realY = attackMoveCommand.goalY;
               newArcher.ai.setCommand(game,attackMoveCommand);
            }
         }
         for each(ally in this.team.units)
         {
            if(!(ally is Archer) || ally == this || !ally.isAlive())
            {
               continue;
            }
            if(useGarrisonRegroup)
            {
               ally.x = ally.px = this.team.homeX;
               ally.y = ally.py = game.map.height / 2;
               this.team.garrison(true,ally);
            }
            else
            {
               retreatCommand = new MoveCommand(game);
               retreatCommand.type = UnitCommand.MOVE;
               retreatCommand.goalX = this.team.homeX + this.team.direction * (250 + regroupSlot * 28);
               retreatCommand.goalY = Math.max(90,Math.min(game.map.height - 90,game.map.height / 2 + (regroupSlot - 2) * 45));
               retreatCommand.realX = retreatCommand.goalX;
               retreatCommand.realY = retreatCommand.goalY;
               ally.ai.setCommand(game,retreatCommand);
            }
            ++regroupSlot;
         }
         retreatCommand = new MoveCommand(game);
         retreatCommand.type = UnitCommand.MOVE;
         retreatCommand.goalX = this.team.homeX + this.team.direction * 350;
         retreatCommand.goalY = game.map.height / 2;
         retreatCommand.realX = retreatCommand.goalX;
         retreatCommand.realY = retreatCommand.goalY;
         this.ai.setCommand(game,retreatCommand);
        if(useGarrisonRegroup)
        {
            this.x = this.px = this.team.homeX;
            this.y = this.py = game.map.height / 2;
            this.team.garrison(true,this);
            this.bossUsedGarrisonRetreat = true;
            this.bossGarrisonRegroupActive = true;
            this.bossGarrisonRegroupFrames = BOSS_GARRISON_REGROUP_FRAMES;
        }
      }

      public function updateBossRegroupState() : void
      {
         if(this._bossIsRegrouping && this.countNearbyLivingArchers() > 2)
         {
            this._bossIsRegrouping = false;
         }
      }

      public function get bossIsRegrouping() : Boolean
      {
         return this._bossIsRegrouping;
      }

      public function getBossRearLineX() : Number
      {
         var ally:Unit = null;
         var anchor:Archer = null;
         for each(ally in this.team.units)
         {
            if(!(ally is Archer) || ally == this || ally.isDead)
            {
               continue;
            }
            if(anchor == null || ally.team.direction * ally.px > ally.team.direction * anchor.px)
            {
               anchor = Archer(ally);
            }
         }
         if(anchor == null)
         {
            return this.px;
         }
         return anchor.px - this.team.direction * BOSS_REAR_GAP;
      }

      private function countNearbyCombatArchers() : int
      {
         var ally:Unit = null;
         var count:int = 0;
         for each(ally in this.team.units)
         {
            if(ally is Archer && ally != this && !ally.isDead && Math.abs(ally.px - this.px) < 320 && ally.ai.getClosestTarget() != null && ally.ai.getClosestTarget().team != ally.team && Math.abs(ally.ai.getClosestTarget().px - ally.px) < 450)
            {
               ++count;
            }
         }
         return count;
      }

      private function countLivingAlliedArchers() : int
      {
         var ally:Unit = null;
         var count:int = 0;
         for each(ally in this.team.units)
         {
            if(ally is Archer && ally != this && ally.isAlive())
            {
               ++count;
            }
         }
         return count;
      }

      private function countNearbyLivingArchers() : int
      {
         var ally:Unit = null;
         var count:int = 0;
         for each(ally in this.team.units)
         {
            if(ally is Archer && ally != this && ally.isAlive() && Math.abs(ally.px - this.px) < 260 && Math.abs(ally.py - this.py) < 120)
            {
               ++count;
            }
         }
         return count;
      }

      private function releaseBossGarrisonRegroup(game:StickWar) : void
      {
         var unitId:* = null;
         var ally:Unit = null;
         var archersToRelease:Array = [];
         var attackMoveCommand:AttackMoveCommand = null;
         if(!this.bossGarrisonRegroupActive)
         {
            return;
         }
         for(unitId in this.team.garrisonedUnits)
         {
            ally = this.team.garrisonedUnits[unitId];
            if(ally is Archer && ally.isAlive())
            {
               archersToRelease.push(ally);
            }
         }
         for each(ally in archersToRelease)
         {
            ally.ungarrison();
            attackMoveCommand = new AttackMoveCommand(game);
            attackMoveCommand.type = UnitCommand.ATTACK_MOVE;
            attackMoveCommand.goalX = this.team.enemyTeam.statue.px;
            attackMoveCommand.goalY = game.map.height / 2;
            attackMoveCommand.realX = attackMoveCommand.goalX;
            attackMoveCommand.realY = attackMoveCommand.goalY;
            ally.ai.setCommand(game,attackMoveCommand);
         }
         if(this.isGarrisoned)
         {
            this.ungarrison();
         }
         attackMoveCommand = new AttackMoveCommand(game);
         attackMoveCommand.type = UnitCommand.ATTACK_MOVE;
         attackMoveCommand.goalX = this.team.enemyTeam.statue.px;
         attackMoveCommand.goalY = game.map.height / 2;
         attackMoveCommand.realX = attackMoveCommand.goalX;
         attackMoveCommand.realY = attackMoveCommand.goalY;
         this.ai.setCommand(game,attackMoveCommand);
         this.bossGarrisonRegroupActive = false;
      }
   }
}

