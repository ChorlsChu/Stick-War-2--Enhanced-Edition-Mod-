package com.brockw.stickwar.engine
{
   import com.brockw.game.*;
   import com.brockw.stickwar.BaseMain;
   import com.brockw.stickwar.GameScreen;
   import com.brockw.stickwar.engine.Ai.command.*;
   import com.brockw.stickwar.engine.Team.Building;
   import com.brockw.stickwar.engine.Team.Chaos.ChaosHud;
   import com.brockw.stickwar.engine.Team.Hud;
   import com.brockw.stickwar.engine.Team.Order.GoodHud;
   import com.brockw.stickwar.engine.Team.Team;
   import com.brockw.stickwar.engine.multiplayer.MultiplayerGameScreen;
   import com.brockw.stickwar.engine.multiplayer.moves.*;
   import com.brockw.stickwar.engine.units.*;
   import com.smartfoxserver.v2.entities.data.*;
   import com.smartfoxserver.v2.requests.*;
   import flash.display.*;
   import flash.events.*;
   import flash.geom.Point;
   import flash.ui.Keyboard;
   import flash.utils.Timer;
   import flash.utils.getTimer;
   
   public class UserInterface extends Screen
   {
      
      public static const FRAME_RATE:int = 30;
      
      public var keyBoardState:KeyboardState;
      
      public var mouseState:MouseState;
      
      private var _main:BaseMain;
      
      private var _box:Box;
      
      private var SCROLL_SPEED:Number = 100;
      
      private var SCROLL_GAIN:Number = 20;
      
      private var _team:Team;
      
      private var _selectedUnits:SelectedUnits;
      
      private var _pauseMenu:PauseMenu;
      
      private var _hud:Hud;
      
      private var _actionInterface:ActionInterface;
      
      private var _chat:Chat;
      
      private var _isSlowCamera:Boolean;
      
      private var timeOfLastUpdate:Number;
      
      private var _period:Number = 33.333333333333336;
      
      private var _beforeTime:int = 0;
      
      private var _afterTime:int = 0;
      
      private var _timeDiff:int = 0;
      
      private var _sleepTime:int = 0;
      
      private var _overSleepTime:int = 0;
      
      private var _excess:int = 0;
      
      private var gameTimer:Timer;
      
      private var spacePressTimer:int;

      private var poisonedPressTimer:int;
      
      private var replayData:Array;
      
      private var _gameScreen:GameScreen;
      
      public var lastSentScreenPosition:int;
      
      public var isGlobalsEnabled:Boolean = true;
      
      private var isUnitCreationEnabled:Boolean = true;
      
      private var _helpMessage:HelpMessage;
      
      private var _isMusic:Boolean;
      
      private var mouseOverFrames:int;
      
      private var lastButton:SimpleButton;
      
      public function UserInterface(main:BaseMain, gameScreen:GameScreen)
      {
         ++main.loadingFraction;
         this.lastButton = null;
         this.main = main;
         this.gameScreen = gameScreen;
         super();
         ++main.loadingFraction;
         this.mouseOverFrames = 0;
      }
      
      public function init(team:Team) : void
      {
         this.team = team;
         this.isMusic = this.main.soundManager.isMusic;
         this.lastSentScreenPosition = 0;
         this.spacePressTimer = getTimer();
         this.poisonedPressTimer = getTimer();
         this.box = new Box();
         this.selectedUnits = new SelectedUnits(this.gameScreen);
         ++this.main.loadingFraction;
         if(this.gameScreen is MultiplayerGameScreen)
         {
            this.pauseMenu = new MultiplayerPauseMenu(this.gameScreen);
         }
         else
         {
            this.pauseMenu = new CampaignPauseMenu(this.gameScreen);
         }
         ++this.main.loadingFraction;
         this.SCROLL_SPEED = this.gameScreen.game.xml.xml.screenScrollSpeed;
         this.SCROLL_GAIN = this.gameScreen.game.xml.xml.screenScrollGain;
         this.isSlowCamera = false;
         if(team.type == Team.T_GOOD)
         {
            this._hud = new GoodHud();
         }
         else
         {
            this._hud = new ChaosHud();
         }
         this.actionInterface = new ActionInterface(this);
         ++this.main.loadingFraction;
         addChild(this._actionInterface);
         this._actionInterface.mouseEnabled = false;
         this._actionInterface.mouseChildren = false;
         addChild(this._hud);
         this._chat = new Chat(this.gameScreen);
         ++this.main.loadingFraction;
         addChild(this._chat);
         this.gameScreen.addChild(this.pauseMenu);
         this.helpMessage = new HelpMessage(this.gameScreen.game);
         ++this.main.loadingFraction;
         addChild(this.helpMessage);
         this._chat.mouseEnabled = false;
         this._chat.mouseChildren = false;
         this.mouseEnabled = false;
         this.keyBoardState = new KeyboardState(stage);
         this.mouseState = new MouseState(stage);
         this.gameScreen.game.screenX = team.homeX;
         if(this.gameScreen.game.team == this.gameScreen.game.teamB)
         {
            this.gameScreen.game.screenX -= this.gameScreen.game.map.screenWidth;
         }
         this.gameScreen.game.targetScreenX = this.gameScreen.game.screenX;
         this.stage.addEventListener(MouseEvent.MOUSE_DOWN,this.mouseDownEvent);
         this.stage.addEventListener(MouseEvent.MOUSE_UP,this.mouseUpEvent);
         this.stage.addEventListener(Event.MOUSE_LEAVE,this.mouseUpEvent);
         this.hud.hud.defendButton.addEventListener(MouseEvent.CLICK,this.defendButton);
         if(team == this.gameScreen.game.teamA)
         {
            this.hud.hud.garrisonButton.addEventListener(MouseEvent.CLICK,this.garrisonButton);
            this.hud.hud.attackButton.addEventListener(MouseEvent.CLICK,this.attackButton);
            this.hud.hud.leftMinerButton.addEventListener(MouseEvent.CLICK,this.garrisonMinerButton);
            this.hud.hud.rightMinerButton.addEventListener(MouseEvent.CLICK,this.unGarrisonMinerButton);
         }
         else
         {
            this.hud.hud.attackButton.addEventListener(MouseEvent.CLICK,this.garrisonButton);
            this.hud.hud.garrisonButton.addEventListener(MouseEvent.CLICK,this.attackButton);
            this.hud.hud.leftMinerButton.addEventListener(MouseEvent.CLICK,this.unGarrisonMinerButton);
            this.hud.hud.rightMinerButton.addEventListener(MouseEvent.CLICK,this.garrisonMinerButton);
         }
         this.hud.hud.menuButton.addEventListener(MouseEvent.CLICK,this.openMenu);
         ++this.main.loadingFraction;
         this.gameScreen.team.initTeamButtons(this.gameScreen);
         ++this.main.loadingFraction;
         if(team.type == Team.T_GOOD)
         {
            this.gameScreen.game.soundManager.playSoundInBackground("orderInGame");
         }
         else
         {
            this.gameScreen.game.soundManager.playSoundInBackground("chaosInGame");
         }
         this.addChild(this.gameScreen.game.cursorSprite);
         this.hud.hud.lowButton.addEventListener(MouseEvent.CLICK,this.lowButton);
         this.hud.hud.medButton.addEventListener(MouseEvent.CLICK,this.medButton);
         this.hud.hud.highButton.addEventListener(MouseEvent.CLICK,this.highButton);
         if(Boolean(this.hud.hud.fastForward))
         {
            if(!(this.gameScreen is MultiplayerGameScreen))
            {
               this.hud.hud.fastForward.visible = true;
               this.hud.hud.fastForward.addEventListener(MouseEvent.CLICK,this.clickFastForward,true);
               MovieClip(this.hud.hud.fastForward).buttonMode = true;
            }
            else
            {
               this.hud.hud.fastForward.visible = false;
            }
         }
      }
      
      private function exitButton(evt:Event) : void
      {
         trace("hit the quit");
         trace("QUIT GAME");
         this.gameScreen.doMove(new ForfeitMove(),this.team.id);
      }
      
      private function pauseButton(evt:Event) : void
      {
         trace("PAUSE GAME");
         this.gameScreen.doMove(new PauseMove(),this.team.id);
      }
      
      private function openMenu(e:Event) : void
      {
         this.pauseMenu.showMenu();
      }
      
      private function lowButton(e:Event) : void
      {
         this.gameScreen.quality = GameScreen.S_HIGH_QUALITY;
      }
      
      private function medButton(e:Event) : void
      {
         this.gameScreen.quality = GameScreen.S_LOW_QUALITY;
      }
      
      private function highButton(e:Event) : void
      {
         this.gameScreen.quality = GameScreen.S_MEDIUM_QUALITY;
      }
      
      public function cleanUp() : void
      {
         if(Boolean(this.hud.hud.fastForward))
         {
            if(!(this.gameScreen is MultiplayerGameScreen))
            {
               this.hud.hud.fastForward.removeEventListener(MouseEvent.CLICK,this.clickFastForward);
            }
         }
         this.pauseMenu.cleanUp();
         this.pauseMenu = null;
         removeChild(this._hud);
         this.keyBoardState.cleanUp();
         this.mouseState.cleanUp();
         this.stage.removeEventListener(MouseEvent.MOUSE_DOWN,this.mouseDownEvent);
         this.stage.removeEventListener(MouseEvent.MOUSE_UP,this.mouseUpEvent);
         this.stage.removeEventListener(Event.MOUSE_LEAVE,this.mouseUpEvent);
         if(this.team == this.gameScreen.game.teamA)
         {
            this.hud.hud.garrisonButton.removeEventListener(MouseEvent.CLICK,this.garrisonButton);
            this.hud.hud.attackButton.removeEventListener(MouseEvent.CLICK,this.attackButton);
         }
         else
         {
            this.hud.hud.attackButton.removeEventListener(MouseEvent.CLICK,this.garrisonButton);
            this.hud.hud.garrisonButton.removeEventListener(MouseEvent.CLICK,this.attackButton);
         }
         this.hud.hud.defendButton.removeEventListener(MouseEvent.CLICK,this.defendButton);
         this.hud.hud.menuButton.removeEventListener(MouseEvent.CLICK,this.openMenu);
         this.hud.hud.lowButton.removeEventListener(MouseEvent.CLICK,this.lowButton);
         this.hud.hud.medButton.removeEventListener(MouseEvent.CLICK,this.medButton);
         this.hud.hud.highButton.removeEventListener(MouseEvent.CLICK,this.highButton);
         this.hud.hud.leftMinerButton.removeEventListener(MouseEvent.CLICK,this.unGarrisonMinerButton);
         this.hud.hud.rightMinerButton.removeEventListener(MouseEvent.CLICK,this.garrisonMinerButton);
         this._hud = null;
         Util.recursiveRemoval(Sprite(this));
      }
      
      private function economyButton(evt:MouseEvent) : void
      {
      }
      
      private function battlefieldButton(evt:MouseEvent) : void
      {
      }
      
      public function garrisonMinerButton(evt:MouseEvent) : void
      {
         if(!this.isGlobalsEnabled)
         {
            return;
         }
         var m:GlobalMove = new GlobalMove();
         m.globalMoveType = Team.G_GARRISON_MINER;
         this.gameScreen.doMove(m,this.team.id);
         if(this.team.type == Team.T_GOOD)
         {
            this.gameScreen.game.soundManager.playSoundFullVolume("manthefortSoundOrder");
         }
         else
         {
            this.gameScreen.game.soundManager.playSoundFullVolume("manthefortSoundChaos");
         }
      }
      
      public function unGarrisonMinerButton(evt:MouseEvent) : void
      {
         if(!this.isGlobalsEnabled)
         {
            return;
         }
         var m:GlobalMove = new GlobalMove();
         m.globalMoveType = Team.G_UNGARRISON_MINER;
         this.gameScreen.doMove(m,this.team.id);
         if(this.team.type == Team.T_GOOD)
         {
            this.gameScreen.game.soundManager.playSoundFullVolume("defendSoundOrder");
         }
         else
         {
            this.gameScreen.game.soundManager.playSoundFullVolume("defendSoundChaos");
         }
      }
      
      public function garrisonButton(evt:MouseEvent) : void
      {
         if(!this.isGlobalsEnabled)
         {
            return;
         }
         var m:GlobalMove = new GlobalMove();
         m.globalMoveType = Team.G_GARRISON;
         this.gameScreen.doMove(m,this.team.id);
         if(this.team.type == Team.T_GOOD)
         {
            this.gameScreen.game.soundManager.playSoundFullVolume("manthefortSoundOrder");
         }
         else
         {
            this.gameScreen.game.soundManager.playSoundFullVolume("manthefortSoundChaos");
         }
      }
      
      public function defendButton(evt:MouseEvent) : void
      {
         if(!this.isGlobalsEnabled)
         {
            return;
         }
         var m:GlobalMove = new GlobalMove();
         m.globalMoveType = Team.G_DEFEND;
         this.gameScreen.doMove(m,this.team.id);
         if(this.team.type == Team.T_GOOD)
         {
            this.gameScreen.game.soundManager.playSoundFullVolume("defendSoundOrder");
         }
         else
         {
            this.gameScreen.game.soundManager.playSoundFullVolume("defendSoundChaos");
         }
      }
      
      public function attackButton(evt:MouseEvent) : void
      {
         if(!this.isGlobalsEnabled)
         {
            return;
         }
         var m:GlobalMove = new GlobalMove();
         m.globalMoveType = Team.G_ATTACK;
         this.gameScreen.doMove(m,this.team.id);
         if(this.team.type == Team.T_GOOD)
         {
            this.gameScreen.game.soundManager.playSoundFullVolume("attackSoundOrder");
         }
         else
         {
            this.gameScreen.game.soundManager.playSoundFullVolume("attackSoundChaos");
         }
      }

      private function performGlobalMove(globalMoveType:int) : void
      {
         var m:GlobalMove = null;
         if(!this.isGlobalsEnabled)
         {
            return;
         }
         m = new GlobalMove();
         m.globalMoveType = globalMoveType;
         this.gameScreen.doMove(m,this.team.id);
         if(globalMoveType == Team.G_GARRISON)
         {
            this.gameScreen.game.soundManager.playSoundFullVolume(this.team.type == Team.T_GOOD ? "manthefortSoundOrder" : "manthefortSoundChaos");
         }
         else if(globalMoveType == Team.G_DEFEND)
         {
            this.gameScreen.game.soundManager.playSoundFullVolume(this.team.type == Team.T_GOOD ? "defendSoundOrder" : "defendSoundChaos");
         }
         else if(globalMoveType == Team.G_ATTACK)
         {
            this.gameScreen.game.soundManager.playSoundFullVolume(this.team.type == Team.T_GOOD ? "attackSoundOrder" : "attackSoundChaos");
         }
      }
      
      private function tryToSelectABuilding() : void
      {
         var i:String = null;
         var b:Building = null;
         for(i in this.team.buildings)
         {
            b = Building(this.team.buildings[i]);
            if(b.hitAreaMovieClip.hitTestPoint(stage.mouseX,stage.mouseY,true))
            {
               if(this.mouseState.clicked)
               {
                  this.mouseState.mouseDown = false;
                  this.mouseState.oldMouseDown = false;
                  this.mouseState.clicked = false;
                  b.selected = true;
                  this.selectedUnits.add(Unit(b));
                  this.mouseState.clicked = false;
                  if(b.button.currentFrame != 3)
                  {
                     b.button.gotoAndStop(3);
                     Util.animateToNeutral(MovieClip(b.button),-1);
                  }
                  b.button.gotoAndStop(3);
               }
               else
               {
                  if(b.button.currentFrame != 2)
                  {
                     b.button.gotoAndStop(2);
                     Util.animateToNeutral(MovieClip(b.button),-1);
                  }
                  b.button.gotoAndStop(2);
               }
            }
            else
            {
               if(b.button.currentFrame != 1)
               {
                  b.button.gotoAndStop(1);
                  Util.animateToNeutral(MovieClip(b.button),-1);
               }
               b.button.gotoAndStop(1);
            }
            Util.animateMovieClip(MovieClip(b.button),0,-1);
         }
      }
      
      private function clickFastForward(evt:Event) : void
      {
         this.gameScreen.isFastForward = !this.gameScreen.isFastForward;
         this.mouseState.mouseDown = false;
      }
      
      public function update(evt:Event, timeDiff:Number) : void
      {
         var u:Unit = null;
         var loser:Team = null;
         var m:ScreenPositionUpdateMove = null;
         var mouseWidth:int = 0;
         var posX:Number = NaN;
         var posY:Number = NaN;
         var p:Point = null;
         var dposX:Number = NaN;
         var dposY:Number = NaN;
         var wall:Wall = null;
         var candidate:Entity = null;
         var type:int = 0;
         var unit:String = null;
         var x:int = 0;
         var y:int = 0;
         if(!(this.gameScreen is MultiplayerGameScreen))
         {
            if(Boolean(this.hud.hud.fastForward))
            {
               if(this.gameScreen.isFastForward)
               {
                  this.hud.hud.fastForward.gotoAndStop(2);
               }
               else
               {
                  this.hud.hud.fastForward.gotoAndStop(1);
               }
            }
         }
         var delayOnShow:int = 23;
         if(Boolean(this.hud.hud.attackButton.hitTestPoint(stage.mouseX,stage.mouseY,true)))
         {
            if(this.lastButton != this.hud.hud.attackButton && !this.gameScreen.isFastForwardFrame)
            {
               this.mouseOverFrames = 0;
            }
            ++this.mouseOverFrames;
            if(this.mouseOverFrames > delayOnShow)
            {
               if(this.gameScreen.team == this.gameScreen.game.teamB)
               {
                  this.gameScreen.game.tipBox.displayTip("Garrison","Command all units to garrison inside the castle.",0,0,0,0,true);
               }
               else
               {
                  this.gameScreen.game.tipBox.displayTip("Attack","Command all units to attack the enemy.",0,0,0,0,true);
               }
            }
            this.lastButton = this.hud.hud.attackButton;
         }
         else if(Boolean(this.hud.hud.defendButton.hitTestPoint(stage.mouseX,stage.mouseY,true)))
         {
            if(this.lastButton != this.hud.hud.defendButton && !this.gameScreen.isFastForwardFrame)
            {
               this.mouseOverFrames = 0;
            }
            ++this.mouseOverFrames;
            if(this.mouseOverFrames > delayOnShow)
            {
               this.gameScreen.game.tipBox.displayTip("Defend","Command all units to defend the statue.",0,0,0,0,true);
            }
            this.lastButton = this.hud.hud.defendButton;
         }
         else if(Boolean(this.hud.hud.garrisonButton.hitTestPoint(stage.mouseX,stage.mouseY,true)))
         {
            if(this.lastButton != this.hud.hud.garrisonButton && !this.gameScreen.isFastForwardFrame)
            {
               this.mouseOverFrames = 0;
            }
            ++this.mouseOverFrames;
            if(this.mouseOverFrames > delayOnShow)
            {
               if(this.gameScreen.team == this.gameScreen.game.teamA)
               {
                  this.gameScreen.game.tipBox.displayTip("Garrison","Command all units to garrison inside the castle.",0,0,0,0,true);
               }
               else
               {
                  this.gameScreen.game.tipBox.displayTip("Attack","Command all units to attack the enemy.",0,0,0,0,true);
               }
            }
            this.lastButton = this.hud.hud.garrisonButton;
         }
         else if(Boolean(this.hud.hud.rightMinerButton.hitTestPoint(stage.mouseX,stage.mouseY,true)))
         {
            if(this.lastButton != this.hud.hud.rightMinerButton && !this.gameScreen.isFastForwardFrame)
            {
               this.mouseOverFrames = 0;
            }
            ++this.mouseOverFrames;
            if(this.mouseOverFrames > delayOnShow)
            {
               if(this.gameScreen.team == this.gameScreen.game.teamB)
               {
                  this.gameScreen.game.tipBox.displayTip("Garrison Miners","Command all miners to garrison within the castle.",0,0,0,0,true);
               }
               else
               {
                  this.gameScreen.game.tipBox.displayTip("Resume Mining","Command all miners to resume mining.",0,0,0,0,true);
               }
            }
            this.lastButton = this.hud.hud.rightMinerButton;
         }
         else if(Boolean(this.hud.hud.leftMinerButton.hitTestPoint(stage.mouseX,stage.mouseY,true)))
         {
            if(this.lastButton != this.hud.hud.leftMinerButton && !this.gameScreen.isFastForwardFrame)
            {
               this.mouseOverFrames = 0;
            }
            ++this.mouseOverFrames;
            if(this.mouseOverFrames > delayOnShow)
            {
               if(this.gameScreen.team == this.gameScreen.game.teamA)
               {
                  this.gameScreen.game.tipBox.displayTip("Garrison Miners","Command all miners to garrison within the castle.",0,0,0,0,true);
               }
               else
               {
                  this.gameScreen.game.tipBox.displayTip("Resume Mining","Command all miners to resume mining.",0,0,0,0,true);
               }
            }
            this.lastButton = this.hud.hud.leftMinerButton;
         }
         else if(Boolean(this.hud.hud.lowButton.hitTestPoint(stage.mouseX,stage.mouseY,true)))
         {
            if(this.lastButton != this.hud.hud.lowButton && !this.gameScreen.isFastForwardFrame)
            {
               this.mouseOverFrames = 0;
            }
            ++this.mouseOverFrames;
            if(this.mouseOverFrames > delayOnShow)
            {
               this.gameScreen.game.tipBox.displayTip("Toggle Quality","Toggles graphics quality to improve performance for slower computers.",0,0,0,0,true);
            }
            this.lastButton = this.hud.hud.lowButton;
         }
         else
         {
            if(!this.gameScreen.isFastForwardFrame)
            {
               this.mouseOverFrames = 0;
            }
            this.lastButton = null;
         }
         this.helpMessage.update(this.gameScreen.game);
         this.pauseMenu.update();
         this.selectedUnits.update(this.gameScreen.game);
         this.gameScreen.team.checkUnitCreateMouseOver(this.gameScreen);
         this.mouseState.update();
         this.selectedUnits.refresh();
         this.actionInterface.update(this.gameScreen);
         this.selectedUnits.hasChanged = false;
         this._chat.update();
         this.keyBoardState.isDisabled = this.chat.isInput;
         if(this.keyBoardState.isPressed(80) || this.keyBoardState.isPressed(Keyboard.ESCAPE))
         {
            this.pauseMenu.toggleMenu();
         }
         if(this.keyBoardState.isPressed(70) && Boolean(this.hud.hud.fastForward) && this.hud.hud.fastForward.visible)
         {
            this.clickFastForward(null);
         }
         this.gameScreen.game.soundManager.setPosition(this.gameScreen.game.screenX,0);
         if(this.gameScreen.isPaused)
         {
            return;
         }
         if(this.keyBoardState.isPressed(86))
         {
            this.performGlobalMove(Team.G_GARRISON);
         }
         if(this.keyBoardState.isPressed(66))
         {
            this.performGlobalMove(Team.G_DEFEND);
         }
         if(this.keyBoardState.isPressed(78))
         {
            this.performGlobalMove(Team.G_ATTACK);
         }
         if(this.keyBoardState.isPressed(9))
         {
            this.selectedUnits.nextSelectedUnitType();
         }
         if(this.keyBoardState.isPressed(32))
         {
            this.selectedUnits.clear();
            for each(u in this.team.units)
            {
               if(!u.isTowerSpawned && !u.isConfused() && u.type != Unit.U_MINER && u.type != Unit.U_CHAOS_MINER && !u.isDead && u.isGarrisoned == false && u.type != Unit.U_CHAOS_TOWER)
               {
                  this.selectedUnits.add(u);
                  u.selected = true;
               }
            }
            if(getTimer() - this.spacePressTimer < 400 && this.team.forwardUnitNotSpawn != null)
            {
               this.gameScreen.game.targetScreenX = this.team.forwardUnitNotSpawn.px - this.gameScreen.game.map.screenWidth / 2;
               this.isSlowCamera = false;
            }
            this.spacePressTimer = getTimer();
         }
         if(this.keyBoardState.isPressed(71))
         {
            this.tryUngarrisonSelectedUnits();
         }
         if(this.keyBoardState.isPressed(85))
         {
            this.selectFullHealthGarrisonedUnits();
         }
         if(this.keyBoardState.isPressed(73))
         {
            this.selectAllGarrisonedUnits();
         }
         if(this.keyBoardState.isDown(67))
         {
            this.gameScreen.game.targetScreenX += this.SCROLL_SPEED * 1;
            this.isSlowCamera = false;
         }
         if(this.keyBoardState.isDown(90))
         {
            this.gameScreen.game.targetScreenX -= this.SCROLL_SPEED * 1;
            this.isSlowCamera = false;
         }
         if(this.gameScreen.game.showGameOverAnimation)
         {
            this.gameScreen.game.fogOfWar.isFogOn = false;
            loser = this.gameScreen.game.teamA;
            if(this.gameScreen.game.teamA == this.gameScreen.game.winner)
            {
               loser = this.gameScreen.game.teamB;
            }
            this.gameScreen.game.targetScreenX += (loser.statue.px - this.gameScreen.game.map.screenWidth / 2 - this.gameScreen.game.targetScreenX) * 0.3;
            loser.statue.mc.nextFrame();
            Util.animateMovieClip(loser.statue.mc,0);
            if(loser.statue.mc.currentFrame == loser.statue.mc.totalFrames)
            {
               this.gameScreen.game.gameOver = true;
            }
            loser.updateStatue();
         }
         var speed:int = (this.gameScreen.game.targetScreenX - this.gameScreen.game.screenX) * this.SCROLL_GAIN * 1;
         if(this.isSlowCamera)
         {
            speed = (this.gameScreen.game.targetScreenX - this.gameScreen.game.screenX) * 0.05 * 1;
         }
         this.gameScreen.game.screenX += speed;
         if(this.gameScreen.game.screenX > this.gameScreen.game.background.maxScreenX())
         {
            this.gameScreen.game.screenX = this.gameScreen.game.targetScreenX = this.gameScreen.game.background.maxScreenX();
         }
         if(this.gameScreen.game.screenX < this.gameScreen.game.background.minScreenX())
         {
            this.gameScreen.game.screenX = this.gameScreen.game.targetScreenX = this.gameScreen.game.background.minScreenX();
         }
         if(this.gameScreen.game.inEconomy)
         {
            this.gameScreen.game.screenX = this.gameScreen.team.homeX - this.gameScreen.team.direction * this.gameScreen.game.map.screenWidth;
         }
         this.gameScreen.game.battlefield.x = -this.gameScreen.game.screenX;
         this.gameScreen.game.fogOfWar.update(this.gameScreen.game);
         this.gameScreen.game.cursorSprite.x = -this.gameScreen.game.screenX;
         this.gameScreen.game.fogOfWar.x = -this.gameScreen.game.screenX;
         this.gameScreen.game.bloodManager.x = -this.gameScreen.game.screenX;
         this.gameScreen.game.background.update(this.gameScreen.game);
         if(Math.abs(this.lastSentScreenPosition - this.gameScreen.game.screenX) > 100)
         {
            m = new ScreenPositionUpdateMove();
            this.lastSentScreenPosition = m.pos = this.gameScreen.game.screenX;
            this.gameScreen.doMove(m,this.team.id);
         }
         if(this.keyBoardState.isShift)
         {
            this.team.enemyTeam.detectedUserInput(this);
         }
         else
         {
            this.team.detectedUserInput(this);
         }
         if(this.keyBoardState.isPressed(74))
         {
            this.selectPoisonedUnits();
            this.jumpToPoisonedUnitIfDoublePressed();
            this.poisonedPressTimer = getTimer();
         }
         if(this.mouseState.mouseIn && this.stage.mouseY < this.gameScreen.game.battlefield.y + 240)
         {
            mouseWidth = 120;
            if(this.stage.mouseX < mouseWidth)
            {
               this.gameScreen.game.targetScreenX -= this.SCROLL_SPEED * (mouseWidth - stage.mouseX) / mouseWidth;
               this.isSlowCamera = false;
            }
            if(this.stage.mouseX > this.gameScreen.game.map.screenWidth - mouseWidth)
            {
               this.gameScreen.game.targetScreenX -= this.SCROLL_SPEED * (this.gameScreen.game.map.screenWidth - mouseWidth - stage.mouseX) / mouseWidth;
               this.isSlowCamera = false;
            }
         }
         if(this.mouseState.mouseDown)
         {
            posX = this.hud.hud.map.mouseX / this.hud.hud.map.width;
            posY = this.hud.hud.map.mouseY / this.hud.hud.map.height;
            p = this.hud.hud.map.globalToLocal(new Point(this.mouseState.mouseDownX,this.mouseState.mouseDownY));
            dposX = p.x / this.hud.hud.map.width;
            dposY = p.y / this.hud.hud.map.height;
            if(posX >= 0 && posX <= 1 && posY >= 0 && posY <= 1 && dposX >= 0 && dposX <= 1 && dposY >= 0 && dposY <= 1 && !(dposX > 0.95 && dposY < 0.54))
            {
               this.gameScreen.game.targetScreenX = posX * this.gameScreen.game.map.width - this.gameScreen.game.map.screenWidth / 2;
               this.isSlowCamera = false;
            }
         }
         if(!this.actionInterface.isInCommand() && this.stage.mouseY <= 700 - 125)
         {
            this.tryToSelectABuilding();
            if(this.mouseState.clicked)
            {
               if(!this.keyBoardState.isShift)
               {
                  this.selectedUnits.clear();
               }
               for each(wall in this.team.walls)
               {
                  if(wall.checkForHitPoint3(new Point(stage.mouseX,stage.mouseY)))
                  {
                     this.selectedUnits.add(Unit(wall));
                     Unit(wall).selected = true;
                  }
                  else
                  {
                     Unit(wall).selected = false;
                  }
               }
               candidate = this.gameScreen.game.mouseOverUnit;
               if(candidate != null && candidate is Unit && Unit(candidate).team == this.team && !Unit(candidate).isConfused() && !(candidate is Statue))
               {
                  if(this.keyBoardState.isShift)
                  {
                     Unit(candidate).selected = true;
                  }
                  else
                  {
                     Unit(candidate).selected = true;
                  }
                  this.selectedUnits.add(Unit(candidate));
               }
            }
            if(this.mouseState.doubleClicked)
            {
               if(!this.keyBoardState.isShift)
               {
                  this.selectedUnits.clear();
               }
               type = -1;
               if(this.gameScreen.game.mouseOverUnit != null && this.gameScreen.game.mouseOverUnit is Unit && Unit(this.gameScreen.game.mouseOverUnit).team == this.team && !Unit(this.gameScreen.game.mouseOverUnit).isConfused())
               {
                  type = this.gameScreen.game.mouseOverUnit.type;
               }
               for(unit in this.team.units)
               {
                  x = this.team.units[unit].x - this.gameScreen.game.screenX;
                  y = this.team.units[unit].y + this.gameScreen.game.battlefield.y;
                  if(!Unit(this.team.units[unit]).isConfused() && (Unit(this.team.units[unit]).type == type || Unit(this.team.units[unit]).selected && this.keyBoardState.isShift))
                  {
                     Unit(this.team.units[unit]).selected = true;
                  }
                  else
                  {
                     Unit(this.team.units[unit]).selected = false;
                  }
                  if(Unit(this.team.units[unit]).selected)
                  {
                     this.selectedUnits.add(Unit(this.team.units[unit]));
                  }
               }
            }
         }
         this.box.update(this.gameScreen.game.battlefield.mouseX,this.gameScreen.game.battlefield.mouseY);
         if(this.box.isOn)
         {
            for(unit in this.team.units)
            {
               if(this.team.units[unit].isAlive())
               {
                  if(!(Boolean(Unit(this.team.units[unit]).interactsWith & Unit.I_IS_BUILDING)))
                  {
                     x = int(this.team.units[unit].x);
                     y = int(this.team.units[unit].y);
                     if(this.keyBoardState.isShift)
                     {
                        Unit(this.team.units[unit]).selected = !Unit(this.team.units[unit]).isConfused() && (this.box.isInside(x,y,this.team.units[unit].mc.height / 2,20) || Unit(this.team.units[unit]).selected || this.gameScreen.game.mouseOverUnit == this.team.units[unit]);
                     }
                     else
                     {
                        Unit(this.team.units[unit]).selected = !Unit(this.team.units[unit]).isConfused() && (this.box.isInside(x,y,this.team.units[unit].mc.height / 2,20) || this.gameScreen.game.mouseOverUnit == this.team.units[unit]);
                     }
                     if(Unit(this.team.units[unit]).selected)
                     {
                        this.selectedUnits.add(Unit(this.team.units[unit]));
                     }
                  }
               }
            }
         }
         this._hud.update(this.gameScreen.game,this.team);
         this.hud.hud.lowButton.visible = false;
         this.hud.hud.medButton.visible = false;
         this.hud.hud.highButton.visible = false;
         if(this.gameScreen.quality == GameScreen.S_LOW_QUALITY)
         {
            this.hud.hud.lowButton.visible = true;
         }
         else if(this.gameScreen.quality == GameScreen.S_MEDIUM_QUALITY)
         {
            this.hud.hud.medButton.visible = true;
         }
         else if(this.gameScreen.quality == GameScreen.S_HIGH_QUALITY)
         {
            this.hud.hud.highButton.visible = true;
         }
         this.actionInterface.updateActionAlpha(this.gameScreen);
      }

      private function selectPoisonedUnits() : void
      {
         var poisoned:Unit = null;
         this.selectedUnits.clear();
         for each(poisoned in this.team.poisonedUnits)
         {
            if(this.isSelectablePoisonedUnit(poisoned))
            {
               this.selectedUnits.add(poisoned);
               poisoned.selected = true;
            }
         }
      }

      private function jumpToPoisonedUnitIfDoublePressed() : void
      {
         var poisoned:Unit = null;
         if(getTimer() - this.poisonedPressTimer >= 400)
         {
            return;
         }
         for each(poisoned in this.team.poisonedUnits)
         {
            if(this.isSelectablePoisonedUnit(poisoned))
            {
               this.gameScreen.game.targetScreenX = poisoned.px - this.gameScreen.game.map.screenWidth / 2;
               this.isSlowCamera = false;
               return;
            }
         }
      }

      private function isSelectablePoisonedUnit(poisoned:Unit) : Boolean
      {
         return poisoned != null && !poisoned.isDead && !poisoned.isConfused() && poisoned.isPoisoned() && poisoned.team == this.team && !poisoned.isGarrisoned && poisoned.ai != null && poisoned.ai.currentCommand != null && poisoned.ai.currentCommand.type != UnitCommand.GARRISON;
      }

      private function tryUngarrisonSelectedUnits() : void
      {
         var selected:Unit = null;
         var move:UnitMove = null;
         if(this.selectedUnits.selected.length == 0)
         {
            return;
         }
         for each(selected in this.selectedUnits.selected)
         {
            if(selected == null || !selected.isGarrisoned)
            {
               return;
            }
         }
         move = new UnitMove();
         move.moveType = UnitCommand.UNGARRISON;
         for each(selected in this.selectedUnits.selected)
         {
            move.units.push(selected.id);
         }
         this.gameScreen.doMove(move,this.team.id);
         this.gameScreen.game.soundManager.playSoundFullVolume("GarrisonExit");
      }

      private function selectFullHealthGarrisonedUnits() : void
      {
         var key:* = undefined;
         var unit:Unit = null;
         this.selectedUnits.clear();
         for(key in this.team.garrisonedUnits)
         {
            unit = this.team.garrisonedUnits[key];
            if(this.isSelectableFullHealthGarrisonedUnit(unit))
            {
               this.selectedUnits.add(unit);
               unit.selected = true;
            }
         }
      }

      private function selectAllGarrisonedUnits() : void
      {
         var key:* = undefined;
         var unit:Unit = null;
         this.selectedUnits.clear();
         for(key in this.team.garrisonedUnits)
         {
            unit = this.team.garrisonedUnits[key];
            if(unit != null && !unit.isDead && !unit.isConfused() && unit.team == this.team && unit.isGarrisoned)
            {
               this.selectedUnits.add(unit);
               unit.selected = true;
            }
         }
      }

      private function isSelectableFullHealthGarrisonedUnit(unit:Unit) : Boolean
      {
         return unit != null && !unit.isDead && !unit.isConfused() && unit.team == this.team && unit.isGarrisoned && unit.health >= unit.maxHealth;
      }
      
      public function mouseUpEvent(evt:Event) : void
      {
         if(this.gameScreen.game != null && this.gameScreen.game.cusorSprite.contains(this.box))
         {
            this.gameScreen.game.cusorSprite.removeChild(this.box);
            this.box.end();
            this.selectedUnits.hasFinishedSelecting = true;
            if(this.selectedUnits.selected.length == 0)
            {
               this.mouseState.clicked = true;
               this.tryToSelectABuilding();
            }
         }
      }
      
      public function mouseDownEvent(evt:MouseEvent) : void
      {
         if(!this.actionInterface.isInCommand() && evt.stageY <= 700 - 125)
         {
            this.box.start(this.gameScreen.game.battlefield.mouseX,this.gameScreen.game.battlefield.mouseY);
            this.gameScreen.game.cusorSprite.addChild(this.box);
            if(!this.keyBoardState.isShift)
            {
               this.selectedUnits.clear();
            }
            this.selectedUnits.hasFinishedSelecting = false;
         }
      }
      
      public function get hud() : Hud
      {
         return this._hud;
      }
      
      public function set hud(value:Hud) : void
      {
         this._hud = value;
      }
      
      public function get actionInterface() : ActionInterface
      {
         return this._actionInterface;
      }
      
      public function set actionInterface(value:ActionInterface) : void
      {
         this._actionInterface = value;
      }
      
      public function get team() : Team
      {
         return this._team;
      }
      
      public function set team(value:Team) : void
      {
         this._team = value;
      }
      
      public function get selectedUnits() : SelectedUnits
      {
         return this._selectedUnits;
      }
      
      public function set selectedUnits(value:SelectedUnits) : void
      {
         this._selectedUnits = value;
      }
      
      public function get main() : BaseMain
      {
         return this._main;
      }
      
      public function set main(value:BaseMain) : void
      {
         this._main = value;
      }
      
      public function get chat() : Chat
      {
         return this._chat;
      }
      
      public function set chat(value:Chat) : void
      {
         this._chat = value;
      }
      
      public function get gameScreen() : GameScreen
      {
         return this._gameScreen;
      }
      
      public function set gameScreen(value:GameScreen) : void
      {
         this._gameScreen = value;
      }
      
      public function get box() : Box
      {
         return this._box;
      }
      
      public function set box(value:Box) : void
      {
         this._box = value;
      }
      
      public function get isSlowCamera() : Boolean
      {
         return this._isSlowCamera;
      }
      
      public function set isSlowCamera(value:Boolean) : void
      {
         this._isSlowCamera = value;
      }
      
      public function get helpMessage() : HelpMessage
      {
         return this._helpMessage;
      }
      
      public function set helpMessage(value:HelpMessage) : void
      {
         this._helpMessage = value;
      }
      
      public function get isMusic() : Boolean
      {
         return this._isMusic;
      }
      
      public function set isMusic(value:Boolean) : void
      {
         this.gameScreen.game.soundManager.isMusic = value;
         this._isMusic = value;
      }
      
      public function get pauseMenu() : PauseMenu
      {
         return this._pauseMenu;
      }
      
      public function set pauseMenu(value:PauseMenu) : void
      {
         this._pauseMenu = value;
      }
   }
}

