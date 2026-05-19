package
{
   import fl.containers.ScrollPane;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.text.TextField;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol9450")]
   public dynamic class chatBox extends MovieClip
   {
      
      public var userAddBox:TextField;
      
      public var userDisplayListMc:MovieClip;
      
      public var userCodeBox:TextField;
      
      public var addUserButton:SimpleButton;
      
      public var minimizeButton:SimpleButton;
      
      public var scroll:ScrollPane;
      
      public function chatBox()
      {
         super();
      }
   }
}

