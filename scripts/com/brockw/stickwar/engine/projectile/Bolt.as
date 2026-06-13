package com.brockw.stickwar.engine.projectile
{
   import com.brockw.game.Util;
   import com.brockw.stickwar.engine.StickWar;
   import flash.filters.GlowFilter;
   import flash.geom.ColorTransform;
   
   public class Bolt extends Projectile
   {
      
      private var mc:boltMc;
      
      public function Bolt(game:StickWar)
      {
         super();
         isFire = false;
         type = BOLT;
         hasArrowDeath = true;
         this.mc = new boltMc();
         addChild(this.mc);
      }
      
      public function setArrowGraphics(fire:Boolean, style:int = 0) : void
      {
         this.mc.transform.colorTransform = new ColorTransform();
         this.mc.filters = [];
         if(fire)
         {
            this.mc.gotoAndStop(2);
         }
         else
         {
            this.mc.gotoAndStop(1);
         }
         if(style == 4)
         {
            this.mc.transform.colorTransform = new ColorTransform(0.15,0.08,0.22,1,10,0,25,0);
            this.mc.filters = [new GlowFilter(3342387,1,12,12,4,1),new GlowFilter(0,0.8,5,5,2,1)];
         }
         else if(style == 5)
         {
            this.mc.transform.colorTransform = new ColorTransform(1.45,0.25,0.12,1,180,20,0,0);
            this.mc.filters = [new GlowFilter(13369344,1,12,12,4,1),new GlowFilter(16737792,0.7,5,5,2,1)];
         }
      }
      
      override public function update(game:StickWar) : void
      {
         super.update(game);
         Util.animateMovieClip(this.mc);
         if(!this.isInFlight())
         {
            this.mc.gotoAndStop(3);
         }
      }

      override public function isReadyForCleanup() : Boolean
      {
         return this.framesDead > 45;
      }
   }
}

