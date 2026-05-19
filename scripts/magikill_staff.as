package
{
   import flash.display.MovieClip;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2012")]
   public dynamic class magikill_staff extends MovieClip
   {
      
      public var fireloopwizstaff:MovieClip;
      
      public function magikill_staff()
      {
         super();
         addFrameScript(0,this.frame1);
      }
      
      internal function frame1() : *
      {
         stop();
      }
   }
}

