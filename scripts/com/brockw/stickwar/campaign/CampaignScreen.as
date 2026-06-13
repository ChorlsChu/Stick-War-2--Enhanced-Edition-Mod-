package com.brockw.stickwar.campaign
{
   import com.brockw.game.KeyboardState;
   import com.brockw.game.Screen;
   import com.brockw.stickwar.BaseMain;
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.*;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.net.URLRequest;
   import flash.net.navigateToURL;
   
   public class CampaignScreen extends Screen
   {
      private static const BOTTOM_PANEL_TARGET_Y:Number = 1192.15;

      private static const REPLAY_MAP_MIN_ZOOM:Number = 0.75;

      private static const REPLAY_MAP_MAX_ZOOM:Number = 1.65;

      private static const REPLAY_MAP_EDGE_PADDING_X:Number = 0;

      private static const REPLAY_MAP_EDGE_PADDING_Y:Number = 0;
      
      private var main:BaseMain;
      
      private var txtDisplayLevel:GenericText;
      
      private var btnNextLevel:GenericButton;
      
      private var btnMainMenu:GenericButton;
      
      private var mc:campaignMap;

      private var mapBackdrop:Sprite;
      
      private var keyboard:KeyboardState;
      
      private var currentDisplayedLevelText:String;
      
      private var currentDisplayedMapFrame:int;
      
      private var currentAutoSaveVisible:Boolean;

      private var completedMapFrame:int;

      private var selectedReplayLevel:int;

      private var replayFlagArrived:Boolean;

      private var replayClickZones:Array;

      private var isMapPanning:Boolean;

      private var mapPanStartMouse:Point;

      private var mapPanStartMap:Point;

      private var mapPanMoved:Boolean;

      private var mapHiddenFrames:int;

      private var mapStartDelayFrames:int;

      private var mapCanAdvance:Boolean;

      private var mapStartDelayApplied:Boolean;

      public function CampaignScreen(main:BaseMain)
      {
         super();
         this.main = main;
         this.mc = new campaignMap();
         this.mapBackdrop = new Sprite();
         addChild(this.mapBackdrop);
         addChild(this.mc);
         this.mc.x = -657.7;
         this.mc.y = -584.9;
      }
      
      override public function maySwitchOnDisconnect() : Boolean
      {
         return false;
      }
      
      override public function enter() : void
      {
         this.main.soundManager.playSoundInBackground("loginMusic");
         this.keyboard = new KeyboardState(this.main.stage);
         this.currentDisplayedLevelText = "";
         this.currentDisplayedMapFrame = -1;
         this.currentAutoSaveVisible = !this.main.campaign.isAutoSaveEnabled;
         this.completedMapFrame = this.main.campaign.levels.length;
         this.selectedReplayLevel = -1;
         this.replayFlagArrived = false;
         this.isMapPanning = false;
         this.mapPanStartMouse = null;
         this.mapPanStartMap = null;
         this.mapPanMoved = false;
         this.mapHiddenFrames = 0;
         this.mapStartDelayFrames = 0;
         this.mapCanAdvance = false;
         this.mapStartDelayApplied = false;
         this.mapBackdrop.visible = this.main.campaign.isGameFinished();
         if(this.main.campaign.isGameFinished())
         {
            this.updateMapBackdrop();
            this.resetCompletedMapTransform();
         }
         this.clearReplayClickZones();
         if(this.main.campaign.isGameFinished())
         {
            this.mc.gotoAndStop("level" + this.completedMapFrame);
            this.syncMapToCurrentFrame();
            this.removeDuplicateReplayFlags();
         }
         else if(this.main.campaign.currentLevel != 0)
         {
            this.mc.gotoAndStop("level" + this.main.campaign.currentLevel);
            this.syncMapToCurrentFrame();
         }
         else
         {
            this.mc.gotoAndStop(1);
            this.mc.map.stop();
            this.syncMapToCurrentFrame();
         }
         addEventListener(Event.ENTER_FRAME,this.update);
         addEventListener(MouseEvent.CLICK,this.click);
         addEventListener(MouseEvent.MOUSE_DOWN,this.startMapPan);
         this.main.stage.addEventListener(MouseEvent.MOUSE_UP,this.stopMapPan);
         this.main.stage.addEventListener(MouseEvent.MOUSE_MOVE,this.updateMapPan);
         this.main.stage.addEventListener(MouseEvent.MOUSE_WHEEL,this.zoomCompletedMap);
         this.mc.bottomPanel.campaignButtons.autoSaveEnabled.addEventListener(MouseEvent.CLICK,this.disableSave);
         this.mc.bottomPanel.campaignButtons.autoSaveDisabled.addEventListener(MouseEvent.CLICK,this.enableSave);
         this.mc.bottomPanel.campaignButtons.playOnline.addEventListener(MouseEvent.CLICK,this.upgradesClick);
         this.mc.bottomPanel.campaignButtons.strategyGuide.addEventListener(MouseEvent.CLICK,this.strategyGuideClick);
         this.mc.saveGamePrompt.visible = false;
         this.mc.saveGamePrompt.okButton.addEventListener(MouseEvent.CLICK,this.okButton);
         this.mc.text.mouseEnabled = false;
         this.mc.title.mouseEnabled = false;
         if(this.hasReplayFlag())
         {
            MovieClip(this.mc.map.playbuttonflag.turning).mouseEnabled = false;
            MovieClip(this.mc.map.playbuttonflag.turning).mouseChildren = false;
            MovieClip(this.mc.map.playbuttonflag).buttonMode = true;
         }
         this.prewarmMapAssets();
         if(this.main.campaign.isGameFinished())
         {
            this.resetCompletedMapTransform();
            this.centerCompletedMapOnScreen();
            this.createReplayClickZones();
            this.bringReplayFlagToFront();
         }
         if(this.main.campaign.currentLevel == 0)
         {
            this.main.showScreen("campaignGameScreen",false,true);
         }
      }

      private function prewarmMapAssets() : void
      {
         var frames:Array = [];
         var turning:MovieClip = null;
         var restoreOuterFrame:int = this.mc.currentFrame;
         var restoreMapFrame:int = this.mc.map.currentFrame;
         var restoreTurningFrame:int = 1;
         var restoreTurningVisible:Boolean = false;
         var baseFrame:int = this.main.campaign.isGameFinished() ? this.completedMapFrame : this.main.campaign.currentLevel;
         if(!this.hasReplayFlag())
         {
            return;
         }
         turning = MovieClip(this.mc.map.playbuttonflag.turning);
         restoreTurningFrame = turning.currentFrame;
         restoreTurningVisible = turning.visible;
         this.addPrewarmMapFrame(frames,baseFrame == 0 ? 1 : baseFrame);
         this.addPrewarmMapFrame(frames,baseFrame + 1);
         this.addPrewarmMapFrame(frames,baseFrame + 2);
         this.runMapFramePrewarm(frames);
         turning.visible = true;
         turning.gotoAndStop(1);
         if(turning.totalFrames > 1)
         {
            turning.gotoAndStop(2);
         }
         this.mc.gotoAndStop(restoreOuterFrame);
         this.mc.map.gotoAndStop(restoreMapFrame);
         turning.visible = restoreTurningVisible;
         if(restoreTurningVisible)
         {
            turning.gotoAndPlay(restoreTurningFrame);
         }
         else
         {
            turning.gotoAndStop(restoreTurningFrame);
         }
      }

      private function addPrewarmMapFrame(frames:Array, frame:int) : void
      {
         if(frame < 1 || frame > this.mc.totalFrames || frames.indexOf(frame) != -1)
         {
            return;
         }
         frames.push(frame);
      }

      private function runMapFramePrewarm(frames:Array) : void
      {
         var frame:int = 0;
         for each(frame in frames)
         {
            this.mc.gotoAndStop(frame);
            this.mc.map.gotoAndStop(frame);
         }
      }
      
      private function strategyGuideClick(e:Event) : void
      {
         var url:URLRequest = new URLRequest("http://www.stickpage.com/stickempiresguide.shtml");
         navigateToURL(url,"_blank");
         if(Boolean(this.main.tracker))
         {
            this.main.tracker.trackEvent("link","http://www.stickpage.com/stickempiresguide.shtml");
         }
         this.main.soundManager.playSoundFullVolume("clickButton");
      }
      
      private function upgradesClick(e:Event) : void
      {
         this.main.showScreen("campaignUpgradeScreen",false,true);
         this.main.soundManager.playSoundFullVolume("clickButton");
      }
      
      private function okButton(even:Event) : void
      {
         this.mc.saveGamePrompt.visible = false;
         this.main.soundManager.playSoundFullVolume("clickButton");
      }
      
      private function enableSave(evt:Event) : void
      {
         this.main.campaign.isAutoSaveEnabled = true;
         this.saveGame();
         this.main.soundManager.playSoundFullVolume("clickButton");
      }
      
      private function disableSave(evt:Event) : void
      {
         this.main.campaign.isAutoSaveEnabled = false;
         this.main.soundManager.playSoundFullVolume("clickButton");
      }
      
      private function saveGame() : void
      {
         this.main.campaign.save();
         if(this.main.tracker != null)
         {
            this.main.tracker.trackEvent(this.main.campaign.getLevelDescription(),"save");
         }
         this.mc.saveGamePrompt.visible = true;
         this.mc.saveGamePrompt.messageText.text = this.main.campaign.isGameFinished() ? "Upgrades Saved" : "Game saved at " + this.main.campaign.getCurrentLevel().title;
      }
      
      private function click(evt:MouseEvent) : void
      {
         var replayLevel:int = -1;
         if(this.mapPanMoved)
         {
            this.mapPanMoved = false;
            return;
         }
         if(this.main.campaign.isGameFinished())
         {
            replayLevel = this.getReplayLevelFromClickTarget(evt.target,evt.stageX,evt.stageY);
            if(replayLevel != -1)
            {
               this.main.soundManager.playSoundFullVolume("clickButton");
               this.clickCompletedReplayLevel(replayLevel);
               return;
            }
         }
         if(this.hasReplayFlag() && evt.target == this.mc.map.playbuttonflag && this.mc.currentFrameLabel == "level" + (this.main.campaign.currentLevel + 1))
         {
            this.main.soundManager.playSoundFullVolume("clickButton");
            this.clickPlay(null);
         }
      }

      private function clickCompletedReplayLevel(levelIndex:int) : void
      {
         levelIndex = Math.max(0,Math.min(this.main.campaign.levels.length - 1,levelIndex));
         if(this.selectedReplayLevel == levelIndex && this.replayFlagArrived)
         {
            this.main.campaign.replayLevel = levelIndex;
            this.main.campaign.isReplay = true;
            this.main.showScreen("campaignGameScreen",false,true);
            return;
         }
         this.selectedReplayLevel = levelIndex;
         this.replayFlagArrived = false;
         this.currentDisplayedLevelText = "";
         this.jumpCompletedMapToSelectedLevel();
      }

      private function jumpCompletedMapToSelectedLevel() : void
      {
         if(!this.main.campaign.isGameFinished() || this.selectedReplayLevel == -1)
         {
            return;
         }
         this.mc.gotoAndStop("level" + (this.selectedReplayLevel + 1));
         this.currentDisplayedMapFrame = this.mc.currentFrame;
         this.mc.map.gotoAndStop(this.currentDisplayedMapFrame);
         this.removeDuplicateReplayFlags();
         this.replayFlagArrived = true;
         if(this.hasReplayFlag() && this.mc.map.playbuttonflag.turning != null)
         {
            this.mc.map.playbuttonflag.turning.visible = true;
            MovieClip(this.mc.map.playbuttonflag.turning).play();
         }
         this.bringReplayFlagToFront();
      }

      private function getReplayLevelFromClickTarget(target:Object, stageX:Number, stageY:Number) : int
      {
         var current:DisplayObject = target as DisplayObject;
         var levelNumber:int = -1;
         if(this.hasReplayFlag() && target == this.mc.map.playbuttonflag)
         {
            levelNumber = this.getLevelNumberFromFrameLabel(this.mc.currentFrameLabel);
            if(levelNumber <= 0)
            {
               levelNumber = this.selectedReplayLevel == -1 ? this.main.campaign.levels.length : this.selectedReplayLevel + 1;
            }
            return Math.max(0,Math.min(this.main.campaign.levels.length - 1,levelNumber - 1));
         }
         while(current != null && current != this.mc)
         {
            levelNumber = this.getLevelNumberFromDisplayName(current.name);
            if(levelNumber > 0)
            {
               return Math.max(0,Math.min(this.main.campaign.levels.length - 1,levelNumber - 1));
            }
            current = current.parent;
         }
         return this.getReplayLevelFromCompletedMapPoint(stageX,stageY);
      }

      private function getReplayLevelFromCompletedMapPoint(stageX:Number, stageY:Number) : int
      {
         var dx:Number = 0;
         var dy:Number = 0;
         var local:Point = this.mc.map.globalToLocal(new Point(stageX,stageY));
         var zone:Sprite = null;
         var levelNumber:int = -1;
         var radius:Number = 14;
         var radiusSq:Number = radius * radius;
         if(this.replayClickZones == null)
         {
            return -1;
         }
         for each(zone in this.replayClickZones)
         {
            dx = local.x - zone.x;
            dy = local.y - zone.y;
            if(dx * dx + dy * dy <= radiusSq)
            {
               levelNumber = this.getLevelNumberFromDisplayName(zone.name);
               return levelNumber <= 0 ? -1 : levelNumber - 1;
            }
         }
         return -1;
      }

      private function createReplayClickZones() : void
      {
         var spot:Array = null;
         var zone:Sprite = null;
         var radius:Number = 10;
         var spots:Array = [
            [563,523,0],
            [538,358,1],
            [511,430,2],
            [283,470,3],
            [-231,416,4],
            [250,295,5],
            [123,190,6],
            [177,11,7],
            [267,-245,8],
            [-152,-421,9],
            [-322,-207,10],
            [-149,-53,11],
            [-36,38,12],
            [-13,114,13]
         ];
         this.clearReplayClickZones();
         this.replayClickZones = [];
         for each(spot in spots)
         {
            zone = new Sprite();
            zone.name = "replayLevel" + (int(spot[2]) + 1);
            zone.graphics.beginFill(0x770000,0.85);
            zone.graphics.drawCircle(0,0,radius);
            zone.graphics.endFill();
            zone.x = Number(spot[0]);
            zone.y = Number(spot[1]);
            zone.buttonMode = true;
            zone.mouseChildren = false;
            this.mc.map.addChild(zone);
            this.replayClickZones.push(zone);
         }
      }

      private function clearReplayClickZones() : void
      {
         var zone:Sprite = null;
         if(this.replayClickZones == null)
         {
            return;
         }
         for each(zone in this.replayClickZones)
         {
            if(zone.parent != null)
            {
               zone.parent.removeChild(zone);
            }
         }
         this.replayClickZones = null;
      }

      private function startMapPan(evt:MouseEvent) : void
      {
         if(!this.main.campaign.isGameFinished() || this.isBottomPanelClick(evt.target))
         {
            return;
         }
         this.isMapPanning = true;
         this.mapPanStartMouse = new Point(evt.stageX,evt.stageY);
         this.mapPanStartMap = new Point(this.mc.map.x,this.mc.map.y);
         this.mapPanMoved = false;
      }

      private function updateMapPan(evt:MouseEvent) : void
      {
         if(!this.isMapPanning || this.mapPanStartMouse == null || this.mapPanStartMap == null)
         {
            return;
         }
         if(Math.abs(evt.stageX - this.mapPanStartMouse.x) > 6 || Math.abs(evt.stageY - this.mapPanStartMouse.y) > 6)
         {
            this.mapPanMoved = true;
         }
         this.mc.map.x = this.mapPanStartMap.x + evt.stageX - this.mapPanStartMouse.x;
         this.mc.map.y = this.mapPanStartMap.y + evt.stageY - this.mapPanStartMouse.y;
         this.clampCompletedMapToScreen();
      }

      private function zoomCompletedMap(evt:MouseEvent) : void
      {
         var before:Point = null;
         var after:Point = null;
         var scale:Number = 1;
         var nextScale:Number = 1;
         if(!this.main.campaign.isGameFinished())
         {
            return;
         }
         before = this.mc.map.globalToLocal(new Point(evt.stageX,evt.stageY));
         scale = evt.delta > 0 ? 1.12 : 0.9;
         nextScale = this.clamp(this.mc.map.scaleX * scale,REPLAY_MAP_MIN_ZOOM,REPLAY_MAP_MAX_ZOOM);
         this.mc.map.scaleX = nextScale;
         this.mc.map.scaleY = nextScale;
         after = this.mc.map.localToGlobal(before);
         this.mc.map.x += evt.stageX - after.x;
         this.mc.map.y += evt.stageY - after.y;
         this.clampCompletedMapToScreen();
      }

      private function stopMapPan(evt:MouseEvent) : void
      {
         this.isMapPanning = false;
      }

      private function isBottomPanelClick(target:Object) : Boolean
      {
         var current:DisplayObject = target as DisplayObject;
         while(current != null && current != this.mc)
         {
            if(current == this.mc.bottomPanel || current == this.mc.saveGamePrompt || current == this.mc.text || current == this.mc.title)
            {
               return true;
            }
            current = current.parent;
         }
         return false;
      }

      private function clamp(value:Number, min:Number, max:Number) : Number
      {
         return Math.max(min,Math.min(max,value));
      }

      private function resetCompletedMapTransform() : void
      {
         if(this.mc == null || this.mc.map == null)
         {
            return;
         }
         this.mc.map.x = 0;
         this.mc.map.y = 0;
         this.mc.map.scaleX = 1;
         this.mc.map.scaleY = 1;
      }

      private function centerCompletedMapOnScreen() : void
      {
         var bounds:Rectangle = null;
         if(this.mc == null || this.mc.map == null)
         {
            return;
         }
         bounds = this.mc.map.getBounds(this.main.stage);
         this.mc.map.x += this.main.stage.stageWidth / 2 - (bounds.left + bounds.width / 2);
         this.mc.map.y += this.main.stage.stageHeight / 2 - (bounds.top + bounds.height / 2);
         this.clampCompletedMapToScreen();
      }

      private function bringReplayFlagToFront() : void
      {
         var flag:DisplayObject = this.getReplayFlag();
         if(flag == null || this.mc == null || this.mc.map == null)
         {
            return;
         }
         this.removeDuplicateReplayFlags();
         flag = this.getReplayFlag();
         if(flag != null && flag.parent == this.mc.map)
         {
            this.mc.map.setChildIndex(flag,this.mc.map.numChildren - 1);
         }
      }

      private function removeDuplicateReplayFlags() : void
      {
         var i:int = 0;
         var child:DisplayObject = null;
         var flag:DisplayObject = this.getReplayFlag();
         if(flag == null || this.mc == null || this.mc.map == null)
         {
            return;
         }
         try
         {
            i = this.mc.map.numChildren - 1;
            while(i >= 0)
            {
               child = this.mc.map.getChildAt(i);
               if(child != flag && child != null && child.name == "playbuttonflag" && child.parent == this.mc.map)
               {
                  this.mc.map.removeChild(child);
               }
               --i;
            }
         }
         catch(e:Error)
         {
            return;
         }
      }

      private function hasReplayFlag() : Boolean
      {
         return this.getReplayFlag() != null;
      }

      private function getReplayFlag() : DisplayObject
      {
         var flag:DisplayObject = null;
         try
         {
            if(this.mc != null && this.mc.map != null && "playbuttonflag" in this.mc.map && this.mc.map.playbuttonflag != null)
            {
               flag = this.mc.map.playbuttonflag as DisplayObject;
            }
         }
         catch(e:Error)
         {
            flag = null;
         }
         return flag;
      }

      private function clampCompletedMapToScreen() : void
      {
         var bounds:Rectangle = null;
         var screenWidth:Number = this.main.stage.stageWidth;
         var screenHeight:Number = this.main.stage.stageHeight;
         var minLeft:Number = REPLAY_MAP_EDGE_PADDING_X;
         var minTop:Number = REPLAY_MAP_EDGE_PADDING_Y;
         var maxRight:Number = screenWidth - REPLAY_MAP_EDGE_PADDING_X;
         var maxBottom:Number = screenHeight - REPLAY_MAP_EDGE_PADDING_Y;
         bounds = this.mc.map.getBounds(this.main.stage);
         if(bounds.width <= screenWidth)
         {
            this.mc.map.x += screenWidth / 2 - (bounds.left + bounds.width / 2);
         }
         else
         {
            if(bounds.left > minLeft)
            {
               this.mc.map.x -= bounds.left - minLeft;
            }
            bounds = this.mc.map.getBounds(this.main.stage);
            if(bounds.right < maxRight)
            {
               this.mc.map.x += maxRight - bounds.right;
            }
         }
         bounds = this.mc.map.getBounds(this.main.stage);
         if(bounds.height <= screenHeight)
         {
            this.mc.map.y += screenHeight / 2 - (bounds.top + bounds.height / 2);
         }
         else
         {
            if(bounds.top > minTop)
            {
               this.mc.map.y -= bounds.top - minTop;
            }
            bounds = this.mc.map.getBounds(this.main.stage);
            if(bounds.bottom < maxBottom)
            {
               this.mc.map.y += maxBottom - bounds.bottom;
            }
         }
      }

      private function updateMapBackdrop() : void
      {
         this.mapBackdrop.graphics.clear();
         this.mapBackdrop.graphics.beginFill(11772983,1);
         this.mapBackdrop.graphics.drawRect(0,0,this.main.stage.stageWidth,this.main.stage.stageHeight);
         this.mapBackdrop.graphics.endFill();
      }

      private function getLevelNumberFromDisplayName(name:String) : int
      {
         var i:int = 0;
         var c:int = 0;
         var digits:String = "";
         var lower:String = name == null ? "" : name.toLowerCase();
         var index:int = lower.indexOf("level");
         if(index == -1)
         {
            return -1;
         }
         i = index + 5;
         while(i < lower.length)
         {
            c = lower.charCodeAt(i);
            if(c >= 48 && c <= 57)
            {
               break;
            }
            ++i;
         }
         while(i < lower.length)
         {
            c = lower.charCodeAt(i);
            if(c < 48 || c > 57)
            {
               break;
            }
            digits += lower.charAt(i);
            ++i;
         }
         return digits == "" ? -1 : int(digits);
      }

      private function getLevelNumberFromFrameLabel(label:String) : int
      {
         if(label == null || label.indexOf("level") != 0)
         {
            return -1;
         }
         return int(label.substr(5));
      }
      
      public function update(evt:Event) : void
      {
         var targetFrameLabel:String = null;
         var isCompleted:Boolean = this.main.campaign.isGameFinished();
         if(!this.main.isKongregate && this.main.isCampaignDebug && this.keyboard.isDown(78) && this.keyboard.isShift)
         {
            ++this.main.campaign.currentLevel;
            ++this.main.campaign.campaignPoints;
            if(this.main.campaign.isGameFinished())
            {
               this.main.showScreen("summary",false,true);
            }
            else
            {
               this.leave();
               this.enter();
            }
         }
         targetFrameLabel = isCompleted && this.selectedReplayLevel != -1 ? this.mc.currentFrameLabel : (isCompleted ? "level" + this.completedMapFrame : "level" + (this.main.campaign.currentLevel + 1));
         this.mc.stop();
         if(!this.canAdvanceMapThisFrame())
         {
            this.syncMapToCurrentFrame();
            this.updateLevelDisplayText();
            return;
         }
         if(this.mc.currentFrameLabel != targetFrameLabel)
         {
            this.stepMapTowardLevel(targetFrameLabel);
            if(this.mc.currentFrameLabel == targetFrameLabel)
            {
               this.main.soundManager.playSoundFullVolume("SelectRaceSound");
               if(!isCompleted && this.main.campaign.isAutoSaveEnabled == true)
               {
                  this.saveGame();
               }
            }
            this.replayFlagArrived = false;
            if(this.hasReplayFlag())
            {
               this.mc.map.playbuttonflag.turning.visible = false;
               MovieClip(this.mc.map.playbuttonflag.turning).stop();
            }
         }
         else
         {
            if(isCompleted && this.selectedReplayLevel != -1)
            {
               this.replayFlagArrived = true;
            }
            if(this.hasReplayFlag())
            {
               this.mc.map.playbuttonflag.turning.visible = true;
               MovieClip(this.mc.map.playbuttonflag.turning).play();
            }
            this.mc.bottomPanel.y += (BOTTOM_PANEL_TARGET_Y - this.mc.bottomPanel.y) * 1;
         }
         this.updateLevelDisplayText();
         if(this.currentDisplayedMapFrame != this.mc.currentFrame)
         {
            this.currentDisplayedMapFrame = this.mc.currentFrame;
            this.mc.map.gotoAndStop(this.currentDisplayedMapFrame);
            if(isCompleted)
            {
               this.bringReplayFlagToFront();
            }
         }
         if(this.currentAutoSaveVisible != this.main.campaign.isAutoSaveEnabled)
         {
            this.currentAutoSaveVisible = this.main.campaign.isAutoSaveEnabled;
            this.mc.bottomPanel.campaignButtons.autoSaveDisabled.visible = !this.currentAutoSaveVisible;
            this.mc.bottomPanel.campaignButtons.autoSaveEnabled.visible = this.currentAutoSaveVisible;
         }
      }

      private function stepMapTowardLevel(targetFrameLabel:String) : void
      {
         var currentLevel:int = this.getLevelNumberFromFrameLabel(this.mc.currentFrameLabel);
         var targetLevel:int = this.getLevelNumberFromFrameLabel(targetFrameLabel);
         if(currentLevel > targetLevel && this.mc.currentFrame > 1)
         {
            this.mc.prevFrame();
            return;
         }
         this.mc.nextFrame();
      }

      private function syncMapToCurrentFrame() : void
      {
         if(this.mc == null || this.mc.map == null)
         {
            return;
         }
         this.currentDisplayedMapFrame = this.mc.currentFrame;
         this.mc.map.gotoAndStop(this.currentDisplayedMapFrame);
      }

      private function canAdvanceMapThisFrame() : Boolean
      {
         if(this.mapCanAdvance)
         {
            return true;
         }
         if(!this.visible)
         {
            ++this.mapHiddenFrames;
            return false;
         }
         if(this.mapHiddenFrames > 2 && !this.mapStartDelayApplied)
         {
            this.mapStartDelayFrames = 16;
            this.mapStartDelayApplied = true;
         }
         if(this.mapStartDelayFrames > 0)
         {
            --this.mapStartDelayFrames;
            return false;
         }
         this.mapCanAdvance = true;
         return true;
      }

      private function updateLevelDisplayText() : void
      {
         var level:Level = this.main.campaign.isGameFinished() && this.selectedReplayLevel != -1 ? Level(this.main.campaign.levels[this.selectedReplayLevel]) : this.main.campaign.getCurrentLevel();
         var levelText:String = null;
         if(level == null)
         {
            return;
         }
         levelText = level.title + "|" + level.storyName;
         if(this.currentDisplayedLevelText == levelText)
         {
            return;
         }
         this.currentDisplayedLevelText = levelText;
         this.mc.text.text = level.storyName;
         this.mc.title.text = level.title;
      }
      
      override public function leave() : void
      {
         this.keyboard.cleanUp();
         removeEventListener(Event.ENTER_FRAME,this.update);
         removeEventListener(MouseEvent.CLICK,this.click);
         removeEventListener(MouseEvent.MOUSE_DOWN,this.startMapPan);
         this.main.stage.removeEventListener(MouseEvent.MOUSE_UP,this.stopMapPan);
         this.main.stage.removeEventListener(MouseEvent.MOUSE_MOVE,this.updateMapPan);
         this.main.stage.removeEventListener(MouseEvent.MOUSE_WHEEL,this.zoomCompletedMap);
         this.mc.bottomPanel.campaignButtons.autoSaveEnabled.removeEventListener(MouseEvent.CLICK,this.disableSave);
         this.mc.bottomPanel.campaignButtons.autoSaveDisabled.removeEventListener(MouseEvent.CLICK,this.enableSave);
         this.mc.bottomPanel.campaignButtons.playOnline.removeEventListener(MouseEvent.CLICK,this.upgradesClick);
         this.mc.saveGamePrompt.okButton.removeEventListener(MouseEvent.CLICK,this.okButton);
         this.clearReplayClickZones();
      }
      
      private function clickMainMenu(evt:MouseEvent) : void
      {
         this.main.showScreen("login");
         this.main.soundManager.playSoundFullVolume("clickButton");
      }
      
      private function clickPlay(evt:MouseEvent) : void
      {
         this.main.showScreen("campaignGameScreen",false,true);
         this.main.soundManager.playSoundFullVolume("clickButton");
      }
   }
}
