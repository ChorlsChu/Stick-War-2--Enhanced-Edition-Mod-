package
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol284")]
   public dynamic class signUpScreenMc extends MovieClip
   {
      
      public var form:form2;
      
      public var playButton:SimpleButton;
      
      public function signUpScreenMc()
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

