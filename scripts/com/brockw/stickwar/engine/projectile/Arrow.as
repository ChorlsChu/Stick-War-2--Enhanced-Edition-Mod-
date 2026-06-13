package com.brockw.stickwar.engine.projectile
{
   import com.brockw.game.Util;
   import com.brockw.stickwar.engine.StickWar;
   import flash.filters.GlowFilter;
   import flash.geom.ColorTransform;
   
   public class Arrow extends Projectile
   {
      
      private var mc:arrowMc;

      private var explosionOnHit:Boolean;

      private var explosionDamage:Number;

      private var explosionTriggered:Boolean;
      
      public function Arrow(game:StickWar)
      {
         super();
         isFire = false;
         type = ARROW;
         hasArrowDeath = true;
         this.mc = new arrowMc();
         addChild(this.mc);
         this.explosionOnHit = false;
         this.explosionDamage = 0;
         this.explosionTriggered = false;
      }

      public function setExplosionOnHit(damage:Number) : void
      {
         this.explosionOnHit = damage > 0;
         this.explosionDamage = damage;
         this.explosionTriggered = false;
      }
      
      public function setArrowGraphics(fire:Boolean, style:int = 0) : void
      {
         this.mc.transform.colorTransform = new ColorTransform();
         this.mc.scaleX = 1;
         this.mc.scaleY = 1;
         this.mc.filters = [];
         if(fire)
         {
            this.mc.gotoAndStop(2);
         }
         else
         {
            this.mc.gotoAndStop(1);
         }
         if(style == 1)
         {
            this.mc.transform.colorTransform = new ColorTransform(0.25,1.2,0.35,1,30,180,45,0);
            this.mc.filters = [new GlowFilter(65280,1,8,8,3,1)];
            this.mc.scaleX = 1.2;
         }
         else if(style == 2)
         {
            this.mc.transform.colorTransform = new ColorTransform(1.3,0.95,0.25,1,190,120,0,0);
            this.mc.filters = [new GlowFilter(16766720,1,7,7,3,1)];
            this.mc.scaleX = 1.15;
         }
         else if(style == 3)
         {
            this.mc.transform.colorTransform = new ColorTransform(0.35,0.85,1.35,1,25,90,210,0);
            this.mc.filters = [new GlowFilter(6750207,1,7,7,3,1)];
         }
         else if(style == 4)
         {
            this.mc.transform.colorTransform = new ColorTransform(1.6,0.2,0.15,1,255,20,5,0);
            this.mc.filters = [new GlowFilter(16711680,1,14,14,5,1),new GlowFilter(16737792,0.8,6,6,3,1)];
            this.mc.scaleX = 1.25;
            this.mc.scaleY = 1.08;
         }
      }
      
      override public function update(game:StickWar) : void
      {
         var wasInFlight:Boolean = this.isInFlight();
         super.update(game);
         Util.animateMovieClip(this.mc);
         if(!this.isInFlight())
         {
            if(this.explosionOnHit && !this.explosionTriggered && wasInFlight)
            {
               this.explosionTriggered = true;
               game.projectileManager.initNuke(this.px,this.py,this.inflictor,this.explosionDamage);
               game.soundManager.playSoundRandom("mediumExplosion",3,this.px,this.py);
            }
            this.mc.gotoAndStop(3);
         }
      }

      override public function isReadyForCleanup() : Boolean
      {
         return this.framesDead > 45;
      }
   }
}

