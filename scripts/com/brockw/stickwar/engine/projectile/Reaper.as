package com.brockw.stickwar.engine.projectile
{
   import com.brockw.game.Util;
   import com.brockw.stickwar.engine.StickWar;
   import com.brockw.stickwar.engine.units.Skelator;
   import com.brockw.stickwar.engine.units.Unit;
   import flash.display.MovieClip;
   import flash.filters.GlowFilter;
   import flash.geom.ColorTransform;
   
   public class Reaper extends DirectedProjectile
   {
      
      private var spellMc:MovieClip;

      private static const BOSS_REAPER_CONTROL_FRAMES:int = 30 * 10;
      
      public var target:Unit;
      
      public function Reaper(game:StickWar)
      {
         super(game);
         type = REAPER;
         this.spellMc = new grimreaper();
         addChild(this.spellMc);
         this.spellMc.scaleX *= 1.5;
         this.spellMc.scaleY *= 1.5;
      }
      
      override public function update(game:StickWar) : void
      {
         var dz:Number = NaN;
         visible = true;
         if(this.inflictor is Skelator && Skelator(this.inflictor).isBoss)
         {
            this.spellMc.transform.colorTransform = new ColorTransform(0.35,1.35,0.35,1,20,120,20,0);
            this.spellMc.filters = [new GlowFilter(65280,1,12,12,4,1)];
         }
         else
         {
            this.spellMc.transform.colorTransform = new ColorTransform();
            this.spellMc.filters = [];
         }
         if(!this.target.isAlive())
         {
            if(this.inflictor is Skelator && Skelator(this.inflictor).isBoss)
            {
               Skelator(this.inflictor).resolveBossReaperControl(false);
            }
            this.visible = false;
            _inFlight = false;
            return;
         }
         this.scaleX = game.backScale + py / game.map.height * (game.frontScale - game.backScale);
         this.scaleY = game.backScale + py / game.map.height * (game.frontScale - game.backScale);
         var targetScale:int = Util.sgn(this.target.px - startX);
         if(targetScale != Util.sgn(this.scaleX))
         {
            scaleX *= -1;
         }
         var nx:Number = _startX + t / timeOfFlight * (this.target.px - _startX);
         var ny:Number = _startY + t / timeOfFlight * (this.target.py - _startY);
         var nz:Number = _startZ + t / timeOfFlight * (this.target.pz - _startZ);
         var dx:Number = nx - px;
         var dy:Number = ny - py;
         dz = nz - pz;
         px = nx;
         py = ny;
         pz = nz;
         this.x = px;
         this.y = pz + py;
         if(pz > 0 && dz > 0)
         {
            dz = dx = dy = 0;
         }
         t += 1;
         if(t >= timeOfFlight)
         {
            this.target.reaperCurse(inflictor);
            this.target.poison(this.poisonDamage);
            if(this.inflictor is Skelator && Skelator(this.inflictor).isBoss)
            {
               this.target.reaperControl(BOSS_REAPER_CONTROL_FRAMES);
               this.target.poison(this.target.team.game.xml.xml.Chaos.Units.medusa.poison.poison);
               Skelator(this.inflictor).resolveBossReaperControl(true);
            }
            this.target.damage(0,this.damageToDeal,null);
            this.target.stun(this.stunTime);
            this.target.slow(this.slowFrames);
            _inFlight = false;
            visible = false;
         }
      }
   }
}

