package com.brockw.stickwar
{
   import com.brockw.game.*;
   import com.brockw.stickwar.campaign.*;
   import com.brockw.stickwar.engine.multiplayer.*;
   import com.google.analytics.GATracker;
   import flash.display.*;
   import flash.events.*;
   import flash.external.ExternalInterface;
   import flash.net.URLRequest;
   import flash.system.Security;
   
   [Frame(factoryClass="com.brockw.stickwar.CampaignPreloader")]
   [SWF(frameRate="30",width="850",height="700")]
   public class stickwar2 extends BaseMain
   {
      public static var instObj:*;
      
      private var campaignMenuScreen:CampaignMenuScreen;
      
      private var _postGameScreen:PostGameScreen;
      
      public function stickwar2()
      {
         instObj = this;
         super();
         var xmlLoader:XMLLoader = new XMLLoader();
         this.xml = xmlLoader;
         isCampaignDebug = xmlLoader.xml.campaignDebug == 1;
         postGameScreen = new PostGameScreen(this);
         addScreen("postGame",postGameScreen);
         addScreen("campaignMap",new CampaignScreen(this));
         addScreen("campaignGameScreen",new CampaignGameScreen(this));
         addScreen("campaignUpgradeScreen",new CampaignUpgradeScreen(this));
         addScreen("summary",new EndOfGameSummary(this));
         addScreen("mainMenu",this.campaignMenuScreen = new CampaignMenuScreen(this));
         this.campaign = new Campaign(0,0);
         this.addEventListener(Event.ADDED_TO_STAGE,this.addedToStage);
      }
      
      private function addedToStage(evt:Event) : void
      {
         var paramObj:Object = null;
         var apiPath:String = null;
         var request:URLRequest = null;
         var loader:Loader = null;
         showScreen("mainMenu");
         tracker = null;
         if(ExternalInterface.available)
         {
            tracker = new GATracker(this,"UA-36522838-2","AS3",false);
            tracker.trackPageview("/play");
            tracker.trackEvent("hostname","url",stage.loaderInfo.url);
         }
         if(xml.xml.isKongregate == 1)
         {
            paramObj = LoaderInfo(stage.root.loaderInfo).parameters;
            apiPath = paramObj.kongregate_api_path || "http://www.kongregate.com/flash/API_AS3_Local.swf";
            isKongregate = true;
            Security.allowDomain(apiPath);
            request = new URLRequest(apiPath);
            loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE,this.loadComplete);
            loader.load(request);
            this.addChild(loader);
         }
      }
      
      internal function loadComplete(event:Event) : void
      {
         kongregate = event.target.content;
         kongregate.services.connect();
      }
   }
}

