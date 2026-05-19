package
{
   import flash.display.MovieClip;
   import flash.text.TextField;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol1606")]
   public dynamic class InGameChatMc extends MovieClip
   {
      
      public var chatInput:TextField;
      
      public var backBox:MovieClip;
      
      public var backOfChat:MovieClip;
      
      public var chatOutput:TextField;
      
      public function InGameChatMc()
      {
         super();
      }
   }
}

