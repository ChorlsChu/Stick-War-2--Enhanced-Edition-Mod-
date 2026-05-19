package
{
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.events.KeyboardEvent;
   import flash.events.TimerEvent;
   import flash.utils.Timer;
   import flash.utils.getDefinitionByName;
   
   public class HackInjector extends EventDispatcher
   {
      
      public static const VERSION:String = "2.1.0";
      
      public static const TYPE_NORMAL:int = 0;
      
      public static const TYPE_TIMER:int = 1;
      
      public static const REALTIME:int = -1;
      
      public static var instance:* = null;
      
      public var init:Boolean = false;
      
      public var main:* = null;
      
      public var attachedObjects:Object = new Object();
      
      public var keys:Vector.<int> = new Vector.<int>();
      
      public var timers:Vector.<Timer> = new Vector.<Timer>();
      
      public var functions:Vector.<Function> = new Vector.<Function>();
      
      public var functionsDef:Vector.<int> = new Vector.<int>();
      
      public var triggers:Vector.<Boolean> = new Vector.<Boolean>();
      
      public var KEY_BACKSPACE:int = 8;
      
      public var KEY_ENTER:int = 13;
      
      public var KEY_SHIFT:int = 16;
      
      public var KEY_CTRL:int = 17;
      
      public var KEY_ALT:int = 18;
      
      public var KEY_CAPSLOCK:int = 20;
      
      public var KEY_ESC:int = 27;
      
      public var KEY_SPACE:int = 32;
      
      public var KEY_LEFT:int = 37;
      
      public var KEY_UP:int = 38;
      
      public var KEY_RIGHT:int = 39;
      
      public var KEY_DOWN:int = 40;
      
      public var KEY_F1:int = 112;
      
      public var KEY_F2:int = 113;
      
      public var KEY_F3:int = 114;
      
      public var KEY_F4:int = 115;
      
      public var KEY_F5:int = 116;
      
      public var KEY_F6:int = 117;
      
      public var KEY_F7:int = 118;
      
      public var KEY_F8:int = 119;
      
      public var KEY_F9:int = 120;
      
      public var KEY_F10:int = 121;
      
      public var KEY_F11:int = 122;
      
      public var KEY_F12:int = 123;
      
      public var KEY_N0:int = 96;
      
      public var KEY_N1:int = 97;
      
      public var KEY_N2:int = 98;
      
      public var KEY_N3:int = 99;
      
      public var KEY_N4:int = 100;
      
      public var KEY_N5:int = 101;
      
      public var KEY_N6:int = 102;
      
      public var KEY_N7:int = 103;
      
      public var KEY_N8:int = 104;
      
      public var KEY_N9:int = 105;
      
      public var KEY_0:int = 48;
      
      public var KEY_1:int = 49;
      
      public var KEY_2:int = 50;
      
      public var KEY_3:int = 51;
      
      public var KEY_4:int = 52;
      
      public var KEY_5:int = 53;
      
      public var KEY_6:int = 54;
      
      public var KEY_7:int = 55;
      
      public var KEY_8:int = 56;
      
      public var KEY_9:int = 57;
      
      public var KEY_A:int = 65;
      
      public var KEY_B:int = 66;
      
      public var KEY_C:int = 67;
      
      public var KEY_D:int = 68;
      
      public var KEY_E:int = 69;
      
      public var KEY_F:int = 70;
      
      public var KEY_G:int = 71;
      
      public var KEY_H:int = 72;
      
      public var KEY_I:int = 73;
      
      public var KEY_J:int = 74;
      
      public var KEY_K:int = 75;
      
      public var KEY_L:int = 76;
      
      public var KEY_M:int = 77;
      
      public var KEY_N:int = 78;
      
      public var KEY_O:int = 79;
      
      public var KEY_P:int = 80;
      
      public var KEY_Q:int = 81;
      
      public var KEY_R:int = 82;
      
      public var KEY_S:int = 83;
      
      public var KEY_T:int = 84;
      
      public var KEY_U:int = 85;
      
      public var KEY_V:int = 86;
      
      public var KEY_W:int = 87;
      
      public var KEY_X:int = 88;
      
      public var KEY_Y:int = 89;
      
      public var KEY_Z:int = 90;
      
      public function HackInjector()
      {
         super();
         if(instance)
         {
            return;
         }
         instance = this;
      }
      
      public static function setupMain(param1:*) : *
      {
         if(instance)
         {
            instance.main = param1;
         }
      }
      
      public static function initHack() : *
      {
         if(instance)
         {
            instance.INIT();
         }
      }
      
      public static function setObject(param1:String, param2:*) : *
      {
         if(instance)
         {
            instance.attachedObjects[param1] = param2;
         }
      }
      
      public static function get _appDom() : HackInjector
      {
         return instance;
      }
      
      public function initHacks() : void
      {
         // Version 2 campaign keybinds.
         this.registerTimer(this.hack1,this.getKey("T"),100);
         this.registerTimer(this.hack2,this.getKey("I"),100);
         this.registerFunction(this.hack3,this.getKey("J"));
         this.registerFunction(this.hack4,this.getKey("Z"));
         this.registerFunction(this.hack5,this.getKey("L"));
         this.registerFunction(this.hack6,this.getKey("U"));
         this.registerFunction(this.hack7,this.getKey("N"));
         this.registerFunction(this.hack8,this.getKey("O"));
      }
      
      public function hack1(param1:TimerEvent) : void
      {
         var _loc4_:* = undefined;
         var _loc2_:* = _appDom.getDefinition("com.brockw.stickwar.stickwar2");
         var _loc3_:* = _loc2_.instObj.getScreen("campaignGameScreen");
         for(_loc4_ in _loc3_.team.units)
         {
            _loc3_.team.units[_loc4_].health = _loc3_.team.units[_loc4_].maxHealth;
         }
      }
      
      public function hack2(param1:TimerEvent) : void
      {
         var _loc2_:* = _appDom.getDefinition("com.brockw.stickwar.stickwar2");
         var _loc3_:* = _loc2_.instObj.getScreen("campaignGameScreen");
         _loc3_.team.statue.health = _loc3_.team.statue.maxHealth;
      }
      
      public function hack3() : void
      {
         var _loc1_:* = _appDom.getDefinition("com.brockw.stickwar.stickwar2");
         var _loc2_:* = _loc1_.instObj.getScreen("campaignGameScreen");
         _loc2_.team.gold += 500;
      }
      
      public function hack4() : void
      {
         var _loc1_:* = _appDom.getDefinition("com.brockw.stickwar.stickwar2");
         var _loc2_:* = _loc1_.instObj.getScreen("campaignGameScreen");
         _loc2_.team.mana += 500;
      }
      
      public function hack5() : void
      {
         var _loc1_:* = _appDom.getDefinition("com.brockw.stickwar.stickwar2");
         _loc1_.instObj.campaign.campaignPoints += 5;
      }
      
      public function hack6() : void
      {
         var _loc1_:* = _appDom.getDefinition("com.brockw.stickwar.stickwar2");
         var _loc2_:* = _loc1_.instObj.getScreen("campaignGameScreen");
         _loc2_.team.enemyTeam.statue.damage(0,9999999,null);
      }
      
      public function hack7() : void
      {
         var _loc1_:* = _appDom.getDefinition("com.brockw.stickwar.stickwar2");
         var _loc2_:* = _loc1_.instObj.getScreen("campaignGameScreen");
         // Force the campaign population cap to 80 instead of adding in small steps.
         if(_loc2_.team["populationLimit"] < 80)
         {
            _loc2_.team["populationLimit"] = 80;
         }
      }
      
      public function hack8() : void
      {
         var _loc3_:* = undefined;
         var _loc1_:* = _appDom.getDefinition("com.brockw.stickwar.stickwar2");
         var _loc2_:* = _loc1_.instObj.getScreen("campaignGameScreen");
         for each(_loc3_ in _loc2_.team.unitProductionQueue)
         {
            if(_loc3_.length != 0)
            {
               _loc3_[0][1] = _loc3_[0][0].createTime + 9;
            }
         }
      }
      
      public function realtimeTimers(param1:Event) : void
      {
         var e:Event = param1;
         var i:* = 0;
         while(i < this.functionsDef.length)
         {
            if(this.functionsDef[i] == REALTIME && this.triggers[i])
            {
               try
               {
                  this.functions[i](null);
               }
               catch(e:*)
               {
               }
            }
            i++;
         }
      }
      
      public function registerFunction(param1:Function, param2:int) : void
      {
         this.functions.push(param1);
         this.keys.push(param2);
         this.timers.push(null);
         this.triggers.push(false);
         this.functionsDef.push(TYPE_NORMAL);
      }
      
      public function registerTimer(param1:Function, param2:int, param3:int = -1) : void
      {
         var _loc4_:Timer = null;
         this.keys.push(param2);
         this.functionsDef.push(param3 == REALTIME ? REALTIME : TYPE_TIMER);
         this.functions.push(param1);
         this.triggers.push(false);
         if(param3 == REALTIME)
         {
            this.timers.push(null);
         }
         else
         {
            _loc4_ = new Timer(param3);
            _loc4_.addEventListener(TimerEvent.TIMER,param1);
            this.timers.push(_loc4_);
         }
      }
      
      public function hasValue(param1:String) : Boolean
      {
         if(this.attachedObjects[param1])
         {
            return true;
         }
         return false;
      }
      
      public function INIT() : *
      {
         if(this.main)
         {
            if(this.main.stage)
            {
               this.main.stage.addEventListener(KeyboardEvent.KEY_DOWN,this.keyhack);
               this.main.stage.addEventListener(Event.ENTER_FRAME,this.realtimeTimers);
            }
            else
            {
               this.main.addEventListener(Event.ADDED_TO_STAGE,this.initFromStage);
            }
            this.initHacks();
         }
      }
      
      public function initFromStage(param1:Event) : *
      {
         this.main.removeEventListener(Event.ADDED_TO_STAGE,this.initFromStage);
         this.main.stage.addEventListener(KeyboardEvent.KEY_DOWN,this.keyhack);
         this.main.stage.addEventListener(Event.ENTER_FRAME,this.realtimeTimers);
      }
      
      public function keyhack(param1:KeyboardEvent) : *
      {
         var e:KeyboardEvent = param1;
         var key:int = int(e.keyCode);
         var i:* = 0;
         for(; i < this.keys.length; i++)
         {
            if(key == this.keys[i])
            {
               try
               {
                  if(this.functionsDef[i] == TYPE_NORMAL)
                  {
                     this.functions[i]();
                  }
                  else if(this.functionsDef[i] == TYPE_TIMER)
                  {
                     if(this.triggers[i])
                     {
                        this.timers[i].stop();
                     }
                     else
                     {
                        this.timers[i].start();
                     }
                     this.triggers[i] = !this.triggers[i];
                  }
                  else if(this.functionsDef[i] == REALTIME)
                  {
                     this.triggers[i] = !this.triggers[i];
                  }
               }
               catch(e:*)
               {
                  continue;
               }
            }
         }
      }
      
      public function getDefinition(param1:String) : *
      {
         return getDefinitionByName(param1);
      }
      
      public function getKey(param1:String, param2:Boolean = false) : int
      {
         param1 = param1.toUpperCase();
         if(param2)
         {
            switch(param1)
            {
               case "0":
                  return this.KEY_N0;
               case "1":
                  return this.KEY_N1;
               case "2":
                  return this.KEY_N2;
               case "3":
                  return this.KEY_N3;
               case "4":
                  return this.KEY_N4;
               case "5":
                  return this.KEY_N5;
               case "6":
                  return this.KEY_N6;
               case "7":
                  return this.KEY_N7;
               case "8":
                  return this.KEY_N8;
               case "9":
                  return this.KEY_N9;
            }
         }
         else
         {
            switch(param1)
            {
               case "BACKSPACE":
                  return this.KEY_BACKSPACE;
               case "ENTER":
                  return this.KEY_ENTER;
               case "SHIFT":
                  return this.KEY_SHIFT;
               case "CTRL":
                  return this.KEY_CTRL;
               case "ALT":
                  return this.KEY_ALT;
               case "CAPSLOCK":
                  return this.KEY_CAPSLOCK;
               case "ESC":
                  return this.KEY_ESC;
               case "SPACE":
                  return this.KEY_SPACE;
               case "LEFT":
                  return this.KEY_LEFT;
               case "UP":
                  return this.KEY_UP;
               case "RIGHT":
                  return this.KEY_RIGHT;
               case "DOWN":
                  return this.KEY_DOWN;
               case "F1":
                  return this.KEY_F1;
               case "F2":
                  return this.KEY_F2;
               case "F3":
                  return this.KEY_F3;
               case "F4":
                  return this.KEY_F4;
               case "F5":
                  return this.KEY_F5;
               case "F6":
                  return this.KEY_F6;
               case "F7":
                  return this.KEY_F7;
               case "F8":
                  return this.KEY_F8;
               case "F9":
                  return this.KEY_F9;
               case "F10":
                  return this.KEY_F10;
               case "F11":
                  return this.KEY_F11;
               case "F12":
                  return this.KEY_F12;
               case "0":
                  return this.KEY_0;
               case "1":
                  return this.KEY_1;
               case "2":
                  return this.KEY_2;
               case "3":
                  return this.KEY_3;
               case "4":
                  return this.KEY_4;
               case "5":
                  return this.KEY_5;
               case "6":
                  return this.KEY_6;
               case "7":
                  return this.KEY_7;
               case "8":
                  return this.KEY_8;
               case "9":
                  return this.KEY_9;
               case "A":
                  return this.KEY_A;
               case "B":
                  return this.KEY_B;
               case "C":
                  return this.KEY_C;
               case "D":
                  return this.KEY_D;
               case "E":
                  return this.KEY_E;
               case "F":
                  return this.KEY_F;
               case "G":
                  return this.KEY_G;
               case "H":
                  return this.KEY_H;
               case "I":
                  return this.KEY_I;
               case "J":
                  return this.KEY_J;
               case "K":
                  return this.KEY_K;
               case "L":
                  return this.KEY_L;
               case "M":
                  return this.KEY_M;
               case "N":
                  return this.KEY_N;
               case "O":
                  return this.KEY_O;
               case "P":
                  return this.KEY_P;
               case "Q":
                  return this.KEY_Q;
               case "R":
                  return this.KEY_R;
               case "S":
                  return this.KEY_S;
               case "T":
                  return this.KEY_T;
               case "U":
                  return this.KEY_U;
               case "V":
                  return this.KEY_V;
               case "W":
                  return this.KEY_W;
               case "X":
                  return this.KEY_X;
               case "Y":
                  return this.KEY_Y;
               case "Z":
                  return this.KEY_Z;
            }
         }
         return -1;
      }
   }
}
