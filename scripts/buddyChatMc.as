package
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.text.TextField;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol10160")]
   public dynamic class buddyChatMc extends MovieClip
   {
      
      public var buddyText:TextField;
      
      public var chatWindow:chatWindowMC;
      
      public var status:MovieClip;
      
      public var maximizeButton:SimpleButton;
      
      public function buddyChatMc()
      {
         super();
      }
   }
}

