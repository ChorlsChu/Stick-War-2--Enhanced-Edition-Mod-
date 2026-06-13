package com.brockw.stickwar.engine.projectile
{
   import com.brockw.stickwar.engine.*;
   import com.brockw.stickwar.engine.units.Unit;
   import flash.display.*;
   import flash.utils.Dictionary;
   
   public class ElectricWall extends Projectile
   {
      
      private static const HEAVY_TICK_WALL_COUNT:int = 3;

      private static const HEAVY_TICK_MULTIPLIER:int = 2;

      private static var activeLightningWalls:int = 0;

      private static var nextTickOffset:int = 0;

      internal var spellMc:MovieClip;

      public var controlledFriendlyFire:Boolean;
      
      private var wallArea:Number;
      
      private var frequency:Number;
      
      public var applyBossStun:Boolean;
      
      public var bossStunFrames:int;

      private var bossStunnedUnits:Dictionary;

      private var childClips:Array;

      private var tickOffset:int;

      private var countedActive:Boolean;
      
      public function ElectricWall(game:StickWar)
      {
         var mc:DisplayObject = null;
         super();
         type = ELECTRIC_WALL;
         this.spellMc = new electricWallMc();
         this.addChild(this.spellMc);
         this.controlledFriendlyFire = false;
         this.childClips = [];
         for(var i:* = 0; i < this.spellMc.numChildren; i++)
         {
            mc = this.spellMc.getChildAt(i);
            if(mc is MovieClip)
            {
               MovieClip(mc).gotoAndStop(Math.floor(game.random.nextNumber() * MovieClip(mc).totalFrames));
               this.childClips.push(mc);
            }
         }
         this.wallArea = game.xml.xml.Order.Units.magikill.electricWall.area;
         this.frequency = game.xml.xml.Order.Units.magikill.electricWall.frequency;
         this.applyBossStun = false;
         this.bossStunFrames = int(this.frequency) + 1;
         this.bossStunnedUnits = new Dictionary();
         this.tickOffset = 0;
         this.countedActive = false;
      }
      
      override public function cleanUp() : void
      {
         super.cleanUp();
         this.releaseActiveCount();
         removeChild(this.spellMc);
         this.spellMc = null;
         this.childClips = null;
      }

      public function resetForUse() : void
      {
         if(this.countedActive)
         {
            this.releaseActiveCount();
         }
         this.visible = true;
         this.controlledFriendlyFire = false;
         this.applyBossStun = false;
         this.bossStunFrames = int(this.frequency) + 1;
         this.bossStunnedUnits = new Dictionary();
         this.tickOffset = nextTickOffset;
         nextTickOffset = (nextTickOffset + 2) % Math.max(1,int(this.frequency));
         this.countedActive = true;
         ++activeLightningWalls;
      }
      
      override public function update(game:StickWar) : void
      {
         var mc:MovieClip = null;
         var effectiveFrequency:int = this.getEffectiveFrequency();
         this.visible = true;
         this.spellMc.nextFrame();
         if(activeLightningWalls < HEAVY_TICK_WALL_COUNT || game.frame % 2 == 0)
         {
            for(var i:* = 0; i < this.childClips.length; i++)
            {
               mc = MovieClip(this.childClips[i]);
               mc.nextFrame();
               if(mc.currentFrame == mc.totalFrames)
               {
                  mc.gotoAndStop(1);
               }
            }
         }
         if((game.frame + this.tickOffset) % effectiveFrequency == 0)
         {
            game.spatialHash.mapInArea(this.px - this.wallArea,0,this.px + this.wallArea,game.map.height,this.hitElectricWall);
         }
         if(this.isReadyForCleanup())
         {
            this.visible = false;
            this.releaseActiveCount();
         }
      }
      
      private function hitElectricWall(unit:Unit) : void
      {
         if(!this.controlledFriendlyFire && unit.team != this.team || this.controlledFriendlyFire && unit.team == this.team && unit != this.inflictor && !unit.isBossUnit && unit.type != Unit.U_STATUE)
         {
            if(Math.abs(unit.px - this.px) < this.wallArea)
            {
               unit.damage(Unit.D_NO_SOUND | Unit.D_NO_BLOOD,damageToDeal * this.getDamageTickMultiplier(),null);
               if(this.applyBossStun && this.bossStunnedUnits[unit.id] !== true)
               {
                  this.bossStunnedUnits[unit.id] = true;
                  unit.stun(this.bossStunFrames);
               }
            }
         }
      }

      private function getEffectiveFrequency() : int
      {
         return Math.max(1,int(this.frequency)) * this.getDamageTickMultiplier();
      }

      private function getDamageTickMultiplier() : int
      {
         return activeLightningWalls >= HEAVY_TICK_WALL_COUNT ? HEAVY_TICK_MULTIPLIER : 1;
      }

      private function releaseActiveCount() : void
      {
         if(this.countedActive)
         {
            this.countedActive = false;
            activeLightningWalls = Math.max(0,activeLightningWalls - 1);
         }
      }
      
      override public function isReadyForCleanup() : Boolean
      {
         return this.spellMc.currentFrame == this.spellMc.totalFrames;
      }
      
      override public function isInFlight() : Boolean
      {
         return this.spellMc.currentFrame != this.spellMc.totalFrames;
      }
   }
}

