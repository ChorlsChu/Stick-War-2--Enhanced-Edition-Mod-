package com.brockw.stickwar.engine.units
{
   import com.brockw.game.Util;
   import com.brockw.stickwar.engine.ActionInterface;
   import com.brockw.stickwar.engine.Ai.*;
   import com.brockw.stickwar.engine.Ai.command.*;
   import com.brockw.stickwar.engine.Entity;
   import com.brockw.stickwar.engine.StickWar;
   import com.brockw.stickwar.campaign.CampaignGameScreen;
   import com.brockw.stickwar.engine.Team.Team;
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

      private static const BOSS_TRIPLE_SHOT_COOLDOWN_FRAMES:int = 30 * 12;

      private static const BOSS_EXECUTE_COOLDOWN_FRAMES:int = 30 * 24;

      private static const BOSS_ARROW_STORM_COOLDOWN_FRAMES:int = 30 * 40;

      private static const BOSS_EXPLOSION_ARROW_COOLDOWN_FRAMES:int = 30 * 38;

      private static const BOSS_ABILITY_CHECK_INTERVAL:int = 6;

      private static const BOSS_PENDING_SHOT_DELAY_FRAMES:int = 22;

      private static const BOSS_ARROW_STORM_RANGE_BONUS:Number = 650;

      private static const BOSS_ARROW_STORM_MIN_RANGE_BONUS:Number = 580;

      private static const BOSS_ARROW_STORM_RANGE_BUFFER:Number = 30;

      private static const BOSS_EXPLOSION_ARROW_DAMAGE_SCALE:Number = 0.7;

      private static const BOSS_EXPLOSION_ARROW_MIN_DISTANCE:Number = 230;

      private static const BOSS_EXPLOSION_ARROW_SETUP_DISTANCE:Number = 330;

      private static const BOSS_EXPLOSION_ARROW_SETUP_TIMEOUT_FRAMES:int = 30 * 3;
      
      private static const BOSS_DAMAGE_TAKEN_MULTIPLIER:Number = 1 / 1.75;
      
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

      private var bossTripleShotCooldownFrames:int;

      private var bossExecuteCooldownFrames:int;

      private var bossArrowStormCooldownFrames:int;

      private var bossExplosionArrowCooldownFrames:int;

      private var bossArrowStormQueue:Array;

      private var bossPendingShot:Object;

      private var bossExplosionSetupTarget:Unit;

      private var bossExplosionSetupUntilFrame:int;
      
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
         this.bossTripleShotCooldownFrames = 0;
         this.bossExecuteCooldownFrames = 0;
         this.bossArrowStormCooldownFrames = 0;
         this.bossExplosionArrowCooldownFrames = 0;
         this.bossArrowStormQueue = [];
         this.bossPendingShot = null;
         this.bossExplosionSetupTarget = null;
         this.bossExplosionSetupUntilFrame = 0;
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
      
      public function archerFireArrow() : Boolean
      {
         if(this.archerFireSpellCooldown.spellActivate(team) && team.tech.isResearched(Tech.ARCHIDON_FIRE))
         {
            this.isFire = true;
            takeBottomTrajectory = false;
            _maximumRange = this.fireArrowRange;
            return true;
         }
         return false;
      }
      
      override public function update(game:StickWar) : void
      {
         super.update(game);
         if(this.bossCommandCooldownFrames > 0)
         {
            --this.bossCommandCooldownFrames;
         }
         if(this.bossTripleShotCooldownFrames > 0)
         {
            --this.bossTripleShotCooldownFrames;
         }
         if(this.bossExecuteCooldownFrames > 0)
         {
            --this.bossExecuteCooldownFrames;
         }
         if(this.bossArrowStormCooldownFrames > 0)
         {
            --this.bossArrowStormCooldownFrames;
         }
         if(this.bossExplosionArrowCooldownFrames > 0)
         {
            --this.bossExplosionArrowCooldownFrames;
         }
         this.updateBossPendingShot(game);
         this.updateBossExplosionSetup(game);
         this.updateBossArrowStormQueue(game);
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
         if(this.isBoss && this.bossPendingShot != null)
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
         this.enableCampaignBossEscape();
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

      public function tryBossAbilities(game:StickWar) : Boolean
      {
         if(!this.isBoss || this.hasBossAbilitySpawnLock() || this.bossPendingShot != null || this.bossExplosionSetupTarget != null || this.bossArrowStormQueue.length > 0 || game.frame % BOSS_ABILITY_CHECK_INTERVAL != 0)
         {
            return false;
         }
         if(game.gameScreen is CampaignGameScreen && !CampaignGameScreen(game.gameScreen).canUseRebelsUnitedBossAbility(this,"archer"))
         {
            return false;
         }
         if(this.tryBossExplosionArrow(game))
         {
            return true;
         }
         if(this.tryBossExecuteShot(game))
         {
            return true;
         }
         if(this.tryBossTripleShot(game))
         {
            return true;
         }
         if(this.tryBossArrowStorm(game))
         {
            return true;
         }
         return this.tryBossCommandFireArrows(game);
      }

      public function tryBossCommandFireArrows(game:StickWar) : Boolean
      {
         var ally:Unit = null;
         var target:Unit = null;
         if(!this.isBoss || this.hasBossAbilitySpawnLock() || this.bossCommandCooldownFrames > 0 || this.archerFireSpellCooldown.cooldown() != 0)
         {
            return false;
         }
         target = this.ai.getClosestTarget();
         if(target == null || target.team == this.team || !this.inRange(target) || !team.tech.isResearched(Tech.ARCHIDON_FIRE))
         {
            return false;
         }
         if(!this.archerFireArrow())
         {
            return false;
         }
         for each(ally in this.team.units)
         {
            if(ally is Archer && ally != this && !ally.isDead && Math.abs(ally.px - this.px) < BOSS_COMMAND_RADIUS && Math.abs(ally.py - this.py) < 80)
            {
               Archer(ally).archerFireArrow();
            }
         }
         this.bossCommandCooldownFrames = BOSS_COMMAND_COOLDOWN_FRAMES;
         this.notifyBossAbility(game,"ARCHER BOSS: Fire Arrows");
         return true;
      }

      private function tryBossExecuteShot(game:StickWar) : Boolean
      {
         var target:Unit = null;
         if(this.bossExecuteCooldownFrames > 0 || this.team.enemyTeam.currentAttackState != Team.G_DEFEND)
         {
            return false;
         }
         target = this.findBossExecuteTarget();
         if(target == null)
         {
            return false;
         }
         this.startBossPendingShot(game,"poison",target);
         return true;
      }

      private function tryBossExplosionArrow(game:StickWar) : Boolean
      {
         var target:Unit = null;
         if(this.bossExplosionArrowCooldownFrames > 0 || this.isRebelsUnitedLevel(game))
         {
            return false;
         }
         target = this.findBossExplosionArrowTarget();
         if(target == null)
         {
            return false;
         }
         if(Math.abs(target.px - this.px) < BOSS_EXPLOSION_ARROW_MIN_DISTANCE)
         {
            this.startBossExplosionSetup(game,target);
            return true;
         }
         this.startBossPendingShot(game,"explosion",target);
         return true;
      }

      private function isRebelsUnitedLevel(game:StickWar) : Boolean
      {
         var campaignScreen:CampaignGameScreen = null;
         if(game == null || !(game.gameScreen is CampaignGameScreen))
         {
            return false;
         }
         campaignScreen = CampaignGameScreen(game.gameScreen);
         return campaignScreen.main != null && campaignScreen.main.campaign != null && campaignScreen.main.campaign.getCurrentLevel() != null && campaignScreen.main.campaign.getCurrentLevel().title == "Rebels United";
      }

      private function tryBossTripleShot(game:StickWar) : Boolean
      {
         var target:Unit = null;
         if(this.bossTripleShotCooldownFrames > 0)
         {
            return false;
         }
         target = this.findBossTripleShotTarget();
         if(target == null)
         {
            return false;
         }
         this.startBossPendingShot(game,"triple",target);
         return true;
      }

      private function tryBossArrowStorm(game:StickWar) : Boolean
      {
         var archers:Array = null;
         var targetPoint:Point = null;
         var i:int = 0;
         if(this.bossArrowStormCooldownFrames > 0 || this.bossArrowStormQueue.length > 0 || this.team.enemyTeam.currentAttackState != Team.G_ATTACK)
         {
            return false;
         }
         archers = this.getNearbyBossStormArchers();
         targetPoint = this.getBossStormTargetPoint(game);
         if(targetPoint == null)
         {
            return false;
         }
         if(!this.hasValidBossStormShooter(archers,targetPoint.x,targetPoint.y))
         {
            return false;
         }
         this.startBossPendingShot(game,"storm",null,targetPoint,archers);
         return true;
      }

      private function startBossArrowStormQueue(game:StickWar, targetPoint:Point, archers:Array) : void
      {
         var i:int = 0;
         if(targetPoint == null || archers == null)
         {
            return;
         }
         this.queueBossStormArrow(this,targetPoint.x,targetPoint.y,0,0);
         for(i = 0; i < archers.length; i++)
         {
            this.queueBossStormArrow(Archer(archers[i]),targetPoint.x,targetPoint.y,i + 1,4 + game.random.nextInt() % 21);
         }
      }

      private function startBossPendingShot(game:StickWar, shotType:String, target:Unit, targetPoint:Point = null, archers:Array = null) : void
      {
         this.bossPendingShot = {
            type: shotType,
            target: target,
            targetPoint: targetPoint,
            archers: archers,
            frame: game.frame + BOSS_PENDING_SHOT_DELAY_FRAMES
         };
         this.startBossDrawAnimation(target,targetPoint);
      }

      private function startBossExplosionSetup(game:StickWar, target:Unit) : void
      {
         this.bossExplosionSetupTarget = target;
         this.bossExplosionSetupUntilFrame = game.frame + BOSS_EXPLOSION_ARROW_SETUP_TIMEOUT_FRAMES;
         this.notifyBossAbility(game,"ARCHER BOSS: Explosion Setup");
      }

      public function updateBossExplosionSetup(game:StickWar) : void
      {
         var distance:Number = NaN;
         if(this.bossExplosionSetupTarget == null)
         {
            return;
         }
         if(!this.bossExplosionSetupTarget.isAlive() || game.frame > this.bossExplosionSetupUntilFrame || this.bossExplosionArrowCooldownFrames > 0)
         {
            this.bossExplosionSetupTarget = null;
            return;
         }
         distance = Math.abs(this.bossExplosionSetupTarget.px - this.px);
         if(distance >= BOSS_EXPLOSION_ARROW_MIN_DISTANCE)
         {
            this.startBossPendingShot(game,"explosion",this.bossExplosionSetupTarget);
            this.bossExplosionSetupTarget = null;
         }
      }

      public function handleBossExplosionSetupMovement(game:StickWar) : Boolean
      {
         var target:Unit = null;
         var away:int = 0;
         if(this.bossExplosionSetupTarget == null || this.bossPendingShot != null)
         {
            return false;
         }
         target = this.bossExplosionSetupTarget;
         if(target == null || !target.isAlive())
         {
            this.bossExplosionSetupTarget = null;
            return false;
         }
         if(Math.abs(target.px - this.px) >= BOSS_EXPLOSION_ARROW_SETUP_DISTANCE)
         {
            return false;
         }
         away = Util.sgn(this.px - target.px);
         if(away == 0)
         {
            away = this.team.direction;
         }
         if(Math.abs(this.px - this.team.homeX) < 220 && away == -this.team.direction)
         {
            away = this.team.direction;
         }
         this.walk(away,0,away);
         this.faceDirection(target.px - this.px);
         return true;
      }

      private function startBossDrawAnimation(target:Unit, targetPoint:Point = null) : void
      {
         if(target != null)
         {
            this.faceDirection(target.px - this.px);
            this.aim(target);
         }
         else if(targetPoint != null)
         {
            this.faceDirection(targetPoint.x - this.px);
            this.aimBossArrowAtPoint(this,targetPoint.x,targetPoint.y,0);
         }
         if(this.bowFrame == 1)
         {
            this.bowFrame = 2;
         }
      }

      private function updateBossPendingShot(game:StickWar) : void
      {
         var shotType:String = null;
         var target:Unit = null;
         var targetPoint:Point = null;
         var archers:Array = null;
         if(this.bossPendingShot == null)
         {
            return;
         }
         if(game.frame < int(this.bossPendingShot.frame))
         {
            return;
         }
         shotType = String(this.bossPendingShot.type);
         target = this.bossPendingShot.target as Unit;
         targetPoint = this.bossPendingShot.targetPoint as Point;
         archers = this.bossPendingShot.archers as Array;
         this.bossPendingShot = null;
         if(shotType == "poison")
         {
            if(target != null && target.isAlive() && this.fireBossArrowAtTarget(game,target,this.arrowDamage,12,0,1))
            {
               this.bossExecuteCooldownFrames = BOSS_EXECUTE_COOLDOWN_FRAMES;
               this.notifyBossAbility(game,"ARCHER BOSS: Poison Arrow");
            }
         }
         else if(shotType == "triple")
         {
            if(target != null && target.isAlive() && this.fireBossTripleShot(game,target))
            {
               this.bossTripleShotCooldownFrames = BOSS_TRIPLE_SHOT_COOLDOWN_FRAMES;
               this.notifyBossAbility(game,"ARCHER BOSS: Triple Shot");
            }
         }
         else if(shotType == "storm")
         {
            if(targetPoint != null && archers != null)
            {
               this.startBossArrowStormQueue(game,targetPoint,archers);
               this.bossArrowStormCooldownFrames = BOSS_ARROW_STORM_COOLDOWN_FRAMES;
               this.notifyBossAbility(game,"ARCHER BOSS: Arrow Storm");
            }
         }
         else if(shotType == "explosion")
         {
            if(target != null && target.isAlive() && this.fireBossExplosionArrow(game,target))
            {
               this.bossExplosionArrowCooldownFrames = BOSS_EXPLOSION_ARROW_COOLDOWN_FRAMES;
               this.notifyBossAbility(game,"ARCHER BOSS: Explosion Arrow");
            }
         }
      }

      private function hasValidBossStormShooter(archers:Array, targetX:Number, targetY:Number) : Boolean
      {
         var i:int = 0;
         if(this.canBossStormArrowReach(this,targetX,targetY,0))
         {
            return true;
         }
         for(i = 0; i < archers.length; i++)
         {
            if(this.canBossStormArrowReach(Archer(archers[i]),targetX,targetY,i + 1))
            {
               return true;
            }
         }
         return false;
      }

      private function canBossStormArrowReach(archer:Archer, targetX:Number, targetY:Number, index:int) : Boolean
      {
         var oldMaximumRange:Number = NaN;
         var spreadX:Number = NaN;
         if(archer == null || !archer.isAlive())
         {
            return false;
         }
         spreadX = (index % 7 - 3) * 38;
         oldMaximumRange = archer._maximumRange;
         archer._maximumRange = archer.normalRange + BOSS_ARROW_STORM_RANGE_BONUS;
         if(archer.angleToPoint(targetX + spreadX) == -1.35)
         {
            archer._maximumRange = oldMaximumRange;
            return false;
         }
         archer._maximumRange = oldMaximumRange;
         return true;
      }

      private function queueBossStormArrow(archer:Archer, targetX:Number, targetY:Number, index:int, delayFrames:int) : void
      {
         var archerTarget:Point = this.getBossStormTargetPointForArcher(this.team.game,archer,targetX,targetY,index);
         this.bossArrowStormQueue.push({
            archer: archer,
            targetX: archerTarget.x,
            targetY: archerTarget.y,
            index: index,
            frame: this.team.game.frame + delayFrames
         });
      }

      private function updateBossArrowStormQueue(game:StickWar) : void
      {
         var readIndex:int = 0;
         var writeIndex:int = 0;
         var entry:Object = null;
         if(this.bossArrowStormQueue == null || this.bossArrowStormQueue.length == 0)
         {
            return;
         }
         for(readIndex = 0; readIndex < this.bossArrowStormQueue.length; readIndex++)
         {
            entry = this.bossArrowStormQueue[readIndex];
            this.aimBossArrowAtPoint(Archer(entry.archer),Number(entry.targetX),Number(entry.targetY),int(entry.index));
            if(game.frame >= int(entry.frame))
            {
               this.fireBossStormArrowAtPoint(game,Archer(entry.archer),Number(entry.targetX),Number(entry.targetY),int(entry.index));
            }
            else
            {
               this.bossArrowStormQueue[writeIndex] = entry;
               ++writeIndex;
            }
         }
         this.bossArrowStormQueue.length = writeIndex;
      }

      private function findBossExecuteTarget() : Unit
      {
         var enemy:Unit = null;
         var best:Unit = null;
         var bestDistance:Number = Number.MAX_VALUE;
         var distance:Number = NaN;
         for each(enemy in this.team.enemyTeam.units)
         {
            if(enemy == null || !enemy.isAlive() || enemy.health > enemy.maxHealth * 0.15)
            {
               continue;
            }
            distance = Math.abs(enemy.px - this.px);
            if(distance <= this.normalRange + 260 && distance < bestDistance)
            {
               best = enemy;
               bestDistance = distance;
            }
         }
         return best;
      }

      private function findBossExplosionArrowTarget() : Unit
      {
         var enemy:Unit = null;
         var best:Unit = null;
         var score:Number = 0;
         var bestScore:Number = 0;
         for each(enemy in this.team.enemyTeam.units)
         {
            if(enemy == null || !enemy.isAlive() || Math.abs(enemy.px - this.px) > this.normalRange + 180 || Math.abs(enemy.px - this.px) > Number(this.team.game.xml.xml.Order.Units.magikill.nuke.range))
            {
               continue;
            }
            score = this.getBossTripleShotTargetScore(enemy) + enemy.population;
            if(score > bestScore)
            {
               best = enemy;
               bestScore = score;
            }
         }
         return best;
      }

      private function findBossTripleShotTarget() : Unit
      {
         var enemy:Unit = null;
         var best:Unit = null;
         var score:Number = 0;
         var bestScore:Number = 0;
         var distance:Number = NaN;
         for each(enemy in this.team.enemyTeam.units)
         {
            if(enemy == null || !enemy.isAlive())
            {
               continue;
            }
            distance = Math.abs(enemy.px - this.px);
            if(distance > this.normalRange + 100)
            {
               continue;
            }
            score = this.getBossTripleShotTargetScore(enemy);
            if(score > bestScore)
            {
               best = enemy;
               bestScore = score;
            }
         }
         return best;
      }

      private function getBossTripleShotTargetScore(target:Unit) : Number
      {
         var enemy:Unit = null;
         var score:Number = 1;
         if(target.type == Unit.U_SPEARTON || target.type == Unit.U_GIANT || target.type == Unit.U_ENSLAVED_GIANT)
         {
            score += 4;
         }
         if(target.type == Unit.U_MAGIKILL || target.type == Unit.U_MONK)
         {
            score += 2;
         }
         for each(enemy in this.team.enemyTeam.units)
         {
            if(enemy != null && enemy != target && enemy.isAlive() && Math.abs(enemy.px - target.px) < 115 && Math.abs(enemy.py - target.py) < 90)
            {
               score += 1;
            }
         }
         return score;
      }

      private function getNearbyBossStormArchers() : Array
      {
         var ally:Unit = null;
         var archers:Array = [];
         for each(ally in this.team.units)
         {
            if(ally is Archer && ally != this && ally.isAlive() && Math.abs(ally.px - this.px) < 520 && Math.abs(ally.py - this.py) < 180)
            {
               archers.push(ally);
            }
         }
         return archers;
      }

      private function getBossStormTargetPoint(game:StickWar) : Point
      {
         var enemy:Unit = null;
         var count:int = 0;
         var sumY:Number = 0;
         var frontX:Number = NaN;
         var distance:Number = NaN;
         for each(enemy in this.team.enemyTeam.units)
         {
            if(enemy == null || !enemy.isAlive())
            {
               continue;
            }
            distance = Math.abs(enemy.px - this.px);
            if(distance < this.normalRange + BOSS_ARROW_STORM_MIN_RANGE_BONUS || distance > this.normalRange + BOSS_ARROW_STORM_RANGE_BONUS)
            {
               continue;
            }
            if(count == 0 || this.team.direction * enemy.px < this.team.direction * frontX)
            {
               frontX = enemy.px;
            }
            sumY += enemy.py;
            ++count;
         }
         if(count == 0)
         {
            return null;
         }
         return new Point(frontX - this.team.direction * 120,Math.max(80,Math.min(game.map.height - 80,sumY / count)));
      }

      private function getBossStormTargetPointForArcher(game:StickWar, archer:Archer, fallbackX:Number, fallbackY:Number, index:int) : Point
      {
         var enemy:Unit = null;
         var best:Unit = null;
         var candidates:Array = [];
         var chosen:Unit = null;
         var bestScore:Number = Number.MAX_VALUE;
         var score:Number = NaN;
         var laneOffset:Number = NaN;
         var distance:Number = NaN;
         if(archer == null)
         {
            return new Point(fallbackX,fallbackY);
         }
         laneOffset = (index % 7 - 3) * 42;
         for each(enemy in this.team.enemyTeam.units)
         {
            if(enemy == null || !enemy.isAlive())
            {
               continue;
            }
            distance = Math.abs(enemy.px - archer.px);
            if(distance >= archer.normalRange + BOSS_ARROW_STORM_MIN_RANGE_BONUS && distance <= archer.normalRange + BOSS_ARROW_STORM_RANGE_BONUS)
            {
               candidates.push(enemy);
            }
            score = Math.abs(enemy.py - (archer.py + laneOffset)) + Math.abs(enemy.px - archer.px) * 0.18;
            if(score < bestScore)
            {
               best = enemy;
               bestScore = score;
            }
         }
         if(candidates.length > 0)
         {
            chosen = Unit(candidates[index % candidates.length]);
            return new Point(chosen.px - this.team.direction * 80,chosen.py);
         }
         if(best == null)
         {
            return new Point(fallbackX,fallbackY);
         }
         return new Point(best.px - this.team.direction * 80,best.py);
      }

      private function fireBossTripleShot(game:StickWar, target:Unit) : Boolean
      {
         var firedCount:int = 0;
         if(this.fireBossArrowAtTarget(game,target,this.arrowDamage * 0.9,0,-3.5,2))
         {
            ++firedCount;
         }
         if(this.fireBossArrowAtTarget(game,target,this.arrowDamage,0,0,2))
         {
            ++firedCount;
         }
         if(this.fireBossArrowAtTarget(game,target,this.arrowDamage * 0.9,0,3.5,2))
         {
            ++firedCount;
         }
         return firedCount > 0;
      }

      private function fireBossExplosionArrow(game:StickWar, target:Unit) : Boolean
      {
         return this.fireBossArrowAtTarget(game,target,this.arrowDamage,0,0,4,true,Number(game.xml.xml.Order.Units.magikill.nuke.damage) * BOSS_EXPLOSION_ARROW_DAMAGE_SCALE);
      }

      private function fireBossArrowAtTarget(game:StickWar, target:Unit, damage:Number, poison:Number, dyOffset:Number = 0, arrowStyle:int = 0, useFireVisual:Boolean = false, explosionDamage:Number = 0) : Boolean
      {
         var bow:MovieClip = null;
         var p:Point = null;
         var v:int = 0;
         var angle:Number = NaN;
         var rotation:Number = NaN;
         if(target == null || !target.isAlive())
         {
            return false;
         }
         bow = _mc.mc.bow;
         if(bow == null)
         {
            return false;
         }
         p = bow.localToGlobal(new Point(0,0));
         p = game.battlefield.globalToLocal(p);
         v = this.projectileVelocity;
         angle = this.angleToTarget(target);
         if(angle == -1.35)
         {
            return false;
         }
         rotation = this.angleToBowSpace(angle);
         game.soundManager.playSoundRandom("launchArrow",5,px,py);
         if(target.px < this.px)
         {
            game.projectileManager.initArrow(p.x,p.y,180 - rotation,v,target.y,angleToTargetW(target,v,angle) + dyOffset,this,damage,poison,useFireVisual,0,0,arrowStyle,explosionDamage);
         }
         else
         {
            game.projectileManager.initArrow(p.x,p.y,rotation,v,target.y,angleToTargetW(target,v,angle) + dyOffset,this,damage,poison,useFireVisual,0,0,arrowStyle,explosionDamage);
         }
         return true;
      }

      private function fireBossStormArrowAtPoint(game:StickWar, archer:Archer, targetX:Number, targetY:Number, index:int) : Boolean
      {
         var bow:MovieClip = null;
         var p:Point = null;
         var v:int = 0;
         var spreadX:Number = NaN;
         var spreadY:Number = NaN;
         var angle:Number = NaN;
         var dy:Number = NaN;
         var rotation:Number = NaN;
         var oldMaximumRange:Number = NaN;
         var direction:int = 0;
         if(archer == null || !archer.isAlive())
         {
            return false;
         }
         bow = archer.mc.mc.bow;
         if(bow == null)
         {
            return false;
         }
         spreadX = (index % 7 - 3) * 38;
         spreadY = (int(index / 7) % 5 - 2) * 26;
         targetX += spreadX;
         targetY = Math.max(70,Math.min(game.map.height - 70,targetY + spreadY));
         v = archer.projectileVelocity;
         oldMaximumRange = archer._maximumRange;
         archer._maximumRange = archer.normalRange + BOSS_ARROW_STORM_RANGE_BONUS;
         angle = archer.angleToPoint(targetX);
         if(angle == -1.35)
         {
            direction = Util.sgn(targetX - archer.px);
            if(direction == 0)
            {
               direction = archer.team.direction;
            }
            targetX = archer.px + direction * Math.max(120,archer._maximumRange - BOSS_ARROW_STORM_RANGE_BUFFER);
            angle = archer.angleToPoint(targetX);
            if(angle == -1.35)
            {
               archer._maximumRange = oldMaximumRange;
               return false;
            }
         }
         dy = archer.dyToPoint(targetX,targetY,angle);
         archer._maximumRange = oldMaximumRange;
         rotation = archer.angleToBowSpace(angle);
         archer.faceDirection(targetX - archer.px);
         archer.bowAngle = rotation;
         bow.rotation = rotation;
         if(archer.bowFrame == 1)
         {
            archer.bowFrame = 2;
         }
         p = bow.localToGlobal(new Point(0,0));
         p = game.battlefield.globalToLocal(p);
         game.soundManager.playSoundRandom("launchArrow",5,archer.px,archer.py);
         if(targetX < archer.px)
         {
            game.projectileManager.initArrow(p.x,p.y,180 - rotation,v,targetY,dy,archer,archer.arrowDamage * 1.15,0,false,0,0,3);
         }
         else
         {
            game.projectileManager.initArrow(p.x,p.y,rotation,v,targetY,dy,archer,archer.arrowDamage * 1.15,0,false,0,0,3);
         }
         return true;
      }

      private function aimBossArrowAtPoint(archer:Archer, targetX:Number, targetY:Number, index:int) : Boolean
      {
         var oldMaximumRange:Number = NaN;
         var spreadX:Number = NaN;
         var spreadY:Number = NaN;
         var angle:Number = NaN;
         var rotation:Number = NaN;
         var direction:int = 0;
         if(archer == null || !archer.isAlive())
         {
            return false;
         }
         spreadX = (index % 7 - 3) * 38;
         spreadY = (int(index / 7) % 5 - 2) * 26;
         targetX += spreadX;
         targetY = Math.max(70,Math.min(archer.team.game.map.height - 70,targetY + spreadY));
         oldMaximumRange = archer._maximumRange;
         archer._maximumRange = archer.normalRange + BOSS_ARROW_STORM_RANGE_BONUS;
         angle = archer.angleToPoint(targetX);
         if(angle == -1.35)
         {
            direction = Util.sgn(targetX - archer.px);
            if(direction == 0)
            {
               direction = archer.team.direction;
            }
            targetX = archer.px + direction * Math.max(120,archer._maximumRange - BOSS_ARROW_STORM_RANGE_BUFFER);
            angle = archer.angleToPoint(targetX);
            if(angle == -1.35)
            {
               archer._maximumRange = oldMaximumRange;
               return false;
            }
         }
         archer._maximumRange = oldMaximumRange;
         rotation = archer.angleToBowSpace(angle);
         archer.faceDirection(targetX - archer.px);
         archer.bowAngle = rotation;
         if(archer.mc != null && archer.mc.mc != null && archer.mc.mc.bow != null)
         {
            archer.mc.mc.bow.rotation = rotation;
         }
         if(archer.bowFrame == 1)
         {
            archer.bowFrame = 2;
         }
         return true;
      }

      private function angleToPoint(targetX:Number) : Number
      {
         var v:Number = this.projectileVelocity;
         var g:Number = StickWar.GRAVITY;
         var x:Number = Math.abs(targetX - this.px);
         var zDiff:Number = this.aimYOffset;
         var t:Number = Math.pow(v,4) - g * (g * x * x + 2 * zDiff * v * v);
         if(t <= 0 || x > this._maximumRange)
         {
            return -1.35;
         }
         return Math.atan2(v * v - Math.sqrt(t),g * x);
      }

      private function dyToPoint(targetX:Number, targetY:Number, theta:Number) : Number
      {
         var v:Number = this.projectileVelocity;
         var g:Number = StickWar.GRAVITY;
         var zDiff:Number = this.aimYOffset;
         var top:Number = v * v * Util.sin(theta) * Util.sin(theta) + 2 * g * -zDiff;
         var t:Number = NaN;
         if(top < 0)
         {
            top = 0;
         }
         t = (v * Util.sin(theta) + Math.sqrt(top)) / g;
         if(Math.abs(t) < 0.001)
         {
            return (targetY - this.py) / 5;
         }
         return (targetY - this.py) / t;
      }

      private function notifyBossAbility(game:StickWar, message:String) : void
      {
         if(game != null && game.gameScreen is CampaignGameScreen)
         {
            CampaignGameScreen(game.gameScreen).showDebugBossAbility(message);
         }
      }
   }
}
