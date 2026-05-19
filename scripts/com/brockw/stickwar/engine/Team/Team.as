package com.brockw.stickwar.engine.Team
{
   import com.brockw.game.Util;
   import com.brockw.stickwar.GameScreen;
   import com.brockw.stickwar.engine.Ai.*;
   import com.brockw.stickwar.engine.Ai.command.*;
   import com.brockw.stickwar.engine.Entity;
   import com.brockw.stickwar.engine.StickWar;
   import com.brockw.stickwar.engine.Team.Chaos.*;
   import com.brockw.stickwar.engine.Team.Order.*;
   import com.brockw.stickwar.engine.UserInterface;
   import com.brockw.stickwar.engine.multiplayer.moves.*;
   import com.brockw.stickwar.engine.units.*;
   import com.brockw.stickwar.market.*;
   import com.brockw.stickwar.singleplayer.SingleplayerGameScreen;
   import flash.display.MovieClip;
   import flash.geom.ColorTransform;
   import flash.text.TextField;
   import flash.utils.Dictionary;
   import flash.utils.getTimer;
   
   public class Team
   {
      
      public static const POP_CAP:int = 50;
      
      public static const T_GOOD:int = 0;
      
      public static const T_CHAOS:int = 1;
      
      public static const T_ELEMENTAL:int = 2;
      
      public static const T_RANDOM:int = 3;
      
      public static const SPAWN_OFFSET_X:int = 100;
      
      public static const G_GARRISON:int = 0;
      
      public static const G_DEFEND:int = 1;
      
      public static const G_ATTACK:int = 2;
      
      public static const G_GARRISON_MINER:int = 3;
      
      public static const G_UNGARRISON_MINER:int = 4;
      
      public var averagePosition:Number;
      
      public var medianPosition:Number;
      
      public var attackingForcePopulation:int;
      
      private var _unitsAvailable:Dictionary;
      
      protected var _handicap:Number;
      
      protected var buildingHighlights:Array;
      
      private var _loadout:Loadout;
      
      private var _type:int;
      
      private var _isAi:Boolean;
      
      public var register:int;
      
      private var _name:int;
      
      private var _healthModifier:Number;
      
      private var _direction:int;
      
      private var _homeX:int;
      
      private var _gold:int;
      
      private var _mana:int;
      
      private var _isEnemy:Boolean;
      
      private var _currentAttackState:int;
      
      private var _units:Array;
      
      private var _deadUnits:Array;
      
      private var _enemyTeam:Team;
      
      private var _ai:TeamAi;
      
      private var _forwardUnit:Unit;
      
      private var _forwardUnitNotSpawn:Unit;
      
      private var _game:StickWar;
      
      protected var _castleBack:Entity;
      
      protected var _castleFront:Entity;
      
      protected var _statue:Statue;
      
      private var _id:int;
      
      protected var _population:int;
      
      protected var _unitProductionQueue:Dictionary;
      
      protected var buttonOver:MovieClip;
      
      protected var sameButtonCount:int;
      
      protected var _unitInfo:Dictionary;
      
      protected var _buttonInfoMap:Dictionary;
      
      protected var _base:Entity;
      
      protected var _buildings:Dictionary;
      
      protected var _tech:Tech;
      
      private var _castleDefence:CastleDefence;
      
      private var _hit:Boolean;
      
      private var _garrisonedUnits:Dictionary;
      
      private var _poisonedUnits:Dictionary;
      
      private var VISION_LENGTH:Number;
      
      private var _numberOfCats:int;
      
      private var _unitGroups:Dictionary;
      
      private var _walls:Array;
      
      private var passiveIncomeAmount:Number;
      
      private var passiveIncomeAmountUpgraded1:Number;
      
      private var passiveIncomeAmountUpgraded2:Number;
      
      private var passiveIncomeAmountUpgraded3:Number;
      
      public var techAllowed:Dictionary;
      
      private var passiveMana:Number;
      
      private var passiveManaUpgraded1:Number;
      
      private var passiveManaUpgraded2:Number;
      
      private var passiveManaUpgraded3:Number;
      
      private var _realName:String;
      
      private var _lastScreenLookPosition:int;
      
      private var populationLimit:int;
      
      private var _isMember:Boolean;
      
      private var spawnedUnit:Unit;
      
      private var timeSinceSpawnedUnit:int;
      
      private var towerSpawnDelay:int;
      
      private var hasSpawnHill:Boolean;
      
      private var _pauseCount:int;
      
      private var _rating:int;
      
      private var _damageModifier:Number;
      
      private var _statueType:String;
      
      private var _originalType:int;
      
      public function Team(game:StickWar)
      {
         super();
         this.rating = 0;
         this._pauseCount = 0;
         this.spawnedUnit = null;
         this.timeSinceSpawnedUnit = 0;
         this.lastScreenLookPosition = 0;
         this._type = T_GOOD;
         this.techAllowed = null;
         this._units = new Array();
         this._deadUnits = new Array();
         this.game = game;
         this.isEnemy = false;
         this.medianPosition = 0;
         this._unitProductionQueue = new Dictionary();
         this._buildings = new Dictionary();
         this.unitInfo = new Dictionary();
         this.hit = false;
         this._garrisonedUnits = new Dictionary();
         this.loadout = new Loadout();
         this._poisonedUnits = new Dictionary();
         this.numberOfCats = 0;
         this.VISION_LENGTH = game.xml.xml.visionSize;
         this.unitGroups = new Dictionary();
         this._isAi = false;
         this._walls = [];
         this.buildingHighlights = [];
         this.passiveIncomeAmount = game.xml.xml.passiveIncome;
         this.passiveIncomeAmountUpgraded1 = game.xml.xml.passiveIncomeUpgraded1;
         this.passiveIncomeAmountUpgraded2 = game.xml.xml.passiveIncomeUpgraded2;
         this.passiveIncomeAmountUpgraded3 = game.xml.xml.passiveIncomeUpgraded3;
         this.passiveMana = game.xml.xml.passiveMana;
         this.passiveManaUpgraded1 = game.xml.xml.passiveManaUpgraded1;
         this.passiveManaUpgraded2 = game.xml.xml.passiveManaUpgraded2;
         this.passiveManaUpgraded3 = game.xml.xml.passiveManaUpgraded3;
         this.currentAttackState = Team.G_DEFEND;
         this.populationLimit = game.xml.xml.populationLimit;
         this.healthModifier = 1;
         this._isMember = true;
         this.towerSpawnDelay = game.xml.xml.towerSpawnDelay;
         this._statueType = "default";
         this._damageModifier = 1;
         this._originalType = 0;
      }
      
      public static function getTeamFromId(id:int, game:StickWar, health:int, techAllowed:Dictionary, handicap:* = 1, healthModifier:Number = 1) : Team
      {
         var original:int = id;
         if(id == Team.T_RANDOM)
         {
            id = game.random.nextInt() % 2;
         }
         var team:Team = null;
         if(id == Team.T_GOOD)
         {
            team = new TeamGood(game,health,techAllowed,handicap,healthModifier);
         }
         else if(id == Team.T_CHAOS)
         {
            team = new TeamChaos(game,health,techAllowed,handicap,healthModifier);
         }
         else
         {
            team = new TeamGood(game,health,techAllowed,handicap,healthModifier);
         }
         team.originalType = original;
         return team;
      }
      
      public static function getIdFromRaceName(name:String) : int
      {
         if(name == "Order")
         {
            return Team.T_GOOD;
         }
         if(name == "Chaos")
         {
            return Team.T_CHAOS;
         }
         if(name == "Elemental")
         {
            return Team.T_ELEMENTAL;
         }
         return -1;
      }
      
      public static function getRaceNameFromId(id:int) : String
      {
         if(id == Team.T_GOOD)
         {
            return "Order";
         }
         if(id == Team.T_CHAOS)
         {
            return "Chaos";
         }
         if(id == Team.T_ELEMENTAL)
         {
            return "Elemental";
         }
         if(id == Team.T_RANDOM)
         {
            return "Random";
         }
         return "";
      }
      
      public function get damageModifier() : Number
      {
         return this._damageModifier;
      }
      
      public function set damageModifier(value:Number) : void
      {
         this._damageModifier = value;
      }
      
      public function addWall(x:Number) : Wall
      {
         var w:Wall = new Wall(this.game,this);
         w.id = this.game.getNextUnitId();
         w.setLocation(x);
         this._walls.push(w);
         w.addToScene(this.game.battlefield);
         this.game.units[w.id] = w;
         return w;
      }
      
      public function removeWall(w:Wall) : void
      {
         this._walls.splice(this._walls.indexOf(w),1);
         w.removeFromScene(this.game.battlefield);
         delete this.game.units[w.id];
         this.game.projectileManager.initWallExplosion(w.px,this.game.map.height / 5,this);
         this.game.projectileManager.initWallExplosion(w.px,2 * this.game.map.height / 5,this);
         this.game.projectileManager.initWallExplosion(w.px,3 * this.game.map.height / 5,this);
         this.game.projectileManager.initWallExplosion(w.px,4 * this.game.map.height / 5,this);
         this.game.projectileManager.initWallExplosion(w.px,5 * this.game.map.height / 5,this);
      }
      
      public function garrisonMiner(isLocal:Boolean = false) : void
      {
         var unit:String = null;
         var u:UnitMove = new UnitMove();
         u.moveType = UnitCommand.GARRISON;
         for(unit in this.units)
         {
            if(this.units[unit].type == this.getMinerType())
            {
               u.units.push(this.units[unit].id);
            }
         }
         u.arg0 = this.homeX;
         u.arg1 = this.game.gameScreen.game.map.height / 2;
         if(!isLocal)
         {
            this.game.gameScreen.doMove(u,this.id);
         }
         else
         {
            u.execute(this.game);
         }
      }
      
      public function unGarrisonMiner(isLocal:Boolean = false) : void
      {
         var u:Unit = null;
         var m:UnitMove = null;
         for each(u in this.units)
         {
            if(u.type == this.getMinerType())
            {
               if(MinerAi(u.ai).targetOre != null)
               {
                  m = new UnitMove();
                  m.moveType = UnitCommand.MOVE;
                  m.units.push(u.id);
                  m.owner = this.id;
                  m.arg0 = MinerAi(u.ai).targetOre.x;
                  m.arg1 = MinerAi(u.ai).targetOre.y;
                  m.arg4 = MinerAi(u.ai).targetOre.id;
                  if(!isLocal)
                  {
                     this.game.gameScreen.doMove(m,this.id);
                  }
                  else
                  {
                     m.execute(this.game);
                  }
               }
               else
               {
                  m = new UnitMove();
                  m.moveType = UnitCommand.ATTACK_MOVE;
                  m.units.push(u.id);
                  m.owner = this.id;
                  m.arg0 = this.homeX + this.direction * 900;
                  m.arg1 = this.game.gameScreen.game.map.height / 2;
                  if(!isLocal)
                  {
                     this.game.gameScreen.doMove(m,this.id);
                  }
                  else
                  {
                     m.execute(this.game);
                  }
               }
            }
         }
      }
      
      public function garrison(isLocal:Boolean = false, specificUnit:Unit = null) : void
      {
         var unit:String = null;
         var u:UnitMove = new UnitMove();
         u.moveType = UnitCommand.GARRISON;
         if(specificUnit == null)
         {
            for(unit in this.units)
            {
               u.units.push(this.units[unit].id);
            }
         }
         else
         {
            u.units.push(specificUnit.id);
         }
         u.arg0 = this.homeX;
         u.arg1 = this.game.gameScreen.game.map.height / 2;
         if(!isLocal)
         {
            this.game.gameScreen.doMove(u,this.id);
         }
         else
         {
            u.execute(this.game);
         }
         this.currentAttackState = Team.G_GARRISON;
      }
      
      public function getMinerType() : int
      {
         return 0;
      }
      
      public function defend(isLocal:Boolean = false) : void
      {
         var unit:String = null;
         var u:Unit = null;
         var m:UnitMove = null;
         var attackMoveUnits:* = new UnitMove();
         attackMoveUnits.moveType = UnitCommand.ATTACK_MOVE;
         var moveUnits:* = new UnitMove();
         moveUnits.moveType = UnitCommand.MOVE;
         for(unit in this.units)
         {
            u = this.units[unit];
            if((u.type == Unit.U_MINER || u.type == Unit.U_CHAOS_MINER) && MinerAi(u.ai).targetOre != null)
            {
               m = new UnitMove();
               m.moveType = UnitCommand.MOVE;
               m.units.push(u.id);
               m.owner = this.id;
               m.arg0 = MinerAi(u.ai).targetOre.x;
               m.arg1 = MinerAi(u.ai).targetOre.y;
               m.arg4 = MinerAi(u.ai).targetOre.id;
               if(!isLocal)
               {
                  this.game.gameScreen.doMove(m,this.id);
               }
               else
               {
                  m.execute(this.game);
               }
            }
            else if(this.direction * u.px > this.direction * (this.homeX + this.direction * 900))
            {
               moveUnits.units.push(u.id);
            }
            else
            {
               attackMoveUnits.units.push(u.id);
            }
         }
         moveUnits.owner = this.id;
         moveUnits.arg0 = this.homeX + this.direction * 900;
         moveUnits.arg1 = this.game.gameScreen.game.map.height / 2;
         attackMoveUnits.owner = this.id;
         attackMoveUnits.arg0 = this.homeX + this.direction * 900;
         attackMoveUnits.arg1 = this.game.gameScreen.game.map.height / 2;
         if(!isLocal)
         {
            this.game.gameScreen.doMove(moveUnits,this.id);
            this.game.gameScreen.doMove(attackMoveUnits,this.id);
         }
         else
         {
            moveUnits.execute(this.game);
            attackMoveUnits.execute(this.game);
         }
         this.currentAttackState = Team.G_DEFEND;
      }
      
      public function attack(isLocal:Boolean = false, toPosition:Boolean = false, position:Number = 0) : void
      {
         var unit:String = null;
         var u:Unit = null;
         var m:UnitMove = null;
         var attackMoveUnits:* = new UnitMove();
         attackMoveUnits.moveType = UnitCommand.ATTACK_MOVE;
         for(unit in this.units)
         {
            u = this.units[unit];
            if(u.type == Unit.U_MINER || u.type == Unit.U_CHAOS_MINER)
            {
               if(MinerAi(u.ai).targetOre != null)
               {
                  m = new UnitMove();
                  m.moveType = UnitCommand.MOVE;
                  m.units.push(u.id);
                  m.owner = this.id;
                  m.arg0 = MinerAi(u.ai).targetOre.x;
                  m.arg1 = MinerAi(u.ai).targetOre.y;
                  m.arg4 = MinerAi(u.ai).targetOre.id;
                  if(!isLocal)
                  {
                     this.game.gameScreen.doMove(m,this.id);
                  }
                  else
                  {
                     m.execute(this.game);
                  }
               }
               else if(this.direction * u.px < this.direction * (this.homeX + this.direction * 900))
               {
                  m = new UnitMove();
                  m.moveType = UnitCommand.MOVE;
                  m.units.push(u.id);
                  m.owner = this.id;
                  m.arg0 = this.homeX + this.direction * 900;
                  m.arg1 = 100;
                  if(!isLocal)
                  {
                     this.game.gameScreen.doMove(m,this.id);
                  }
                  else
                  {
                     m.execute(this.game);
                  }
               }
            }
            else
            {
               attackMoveUnits.units.push(u.id);
            }
         }
         attackMoveUnits.owner = this.id;
         if(toPosition)
         {
            attackMoveUnits.arg0 = position;
         }
         else if(this.enemyTeam.forwardUnit == null)
         {
            attackMoveUnits.arg0 = this.enemyTeam.statue.px;
         }
         else
         {
            attackMoveUnits.arg0 = this.enemyTeam.statue.px;
         }
         attackMoveUnits.arg1 = this.game.gameScreen.game.map.height / 2;
         if(!isLocal)
         {
            this.game.gameScreen.doMove(attackMoveUnits,this.id);
         }
         else
         {
            attackMoveUnits.execute(this.game);
         }
         this.currentAttackState = Team.G_ATTACK;
      }
      
      public function cleanUpUnits() : void
      {
         var building:String = null;
         var unit:Unit = null;
         while(this._deadUnits.length != 0)
         {
            this.removeUnitCompletely(this._deadUnits.pop(),this.game);
         }
         this._deadUnits = [];
         for(building in this._unitProductionQueue)
         {
            this._unitProductionQueue[building] = [];
         }
         this.population = 0;
         this.castleDefence.cleanUpUnits();
         delete this.tech.isResearchedMap[Tech.CASTLE_ARCHER_1];
         for each(unit in this._units)
         {
            this.removeUnitCompletely(unit,this.game);
         }
      }
      
      public function cleanUp() : void
      {
         var unit:Unit = null;
         var unitType:int = 0;
         this._ai.cleanUp();
         this._ai = null;
         for each(unit in this._units)
         {
            if(this.game.battlefield.contains(unit))
            {
               this.game.battlefield.removeChild(unit);
            }
            this.game.unitFactory.returnUnit(unit.type,unit);
         }
         for each(unitType in this.unitGroups)
         {
            this.unitGroups[unitType] = [];
         }
         this._units = null;
         this._deadUnits = null;
         this.game = null;
         this._unitProductionQueue = null;
         this._buildings = null;
         this.unitInfo = null;
         this._garrisonedUnits = null;
         this._loadout = null;
         this._enemyTeam = null;
         this._castleDefence.cleanUp();
         this._castleDefence = null;
         this._tech.cleanUp();
         this._tech = null;
         this._base.cleanUp();
         this._base = null;
         this.buttonInfoMap = null;
         this.buttonOver = null;
         this._forwardUnit = null;
         this._forwardUnitNotSpawn = null;
         this._castleBack = null;
         this._castleFront = null;
         this._statue = null;
      }
      
      public function getNumberOfMiners() : int
      {
         return 0;
      }
      
      public function getVisionRange() : Number
      {
         var a:Number = this.game.team.homeX;
         var b:Number = a;
         if(this.game.team.forwardUnit != null)
         {
            b = this.game.team.forwardUnit.x;
         }
         if(b * this.direction > a * this.direction)
         {
            a = b;
         }
         return a + this.direction * this.VISION_LENGTH;
      }
      
      public function createUnit(unit:int) : Boolean
      {
         return false;
      }
      
      public function queueUnit(unit:Unit) : void
      {
         if(this.buttonInfoMap != null)
         {
            if(String(unit.type) in this.buttonInfoMap)
            {
               ++this.buttonInfoMap[unit.type][3];
            }
         }
         this._unitProductionQueue[this.unitInfo[unit.type][2]].push([unit,0]);
      }
      
      public function dequeueUnit(type:int, backwards:Boolean) : Unit
      {
         var i:int = 0;
         var u:Unit = null;
         var building:int = int(this.unitInfo[type][2]);
         var unit:Unit = null;
         if(backwards)
         {
            for(i = this._unitProductionQueue[building].length - 1; i >= 0; i--)
            {
               u = this._unitProductionQueue[building][i][0];
               if(u.type == type)
               {
                  unit = u;
                  this._unitProductionQueue[building].splice(i,1);
                  break;
               }
            }
         }
         else
         {
            for(i = 0; i < this._unitProductionQueue[building].length; i++)
            {
               u = this._unitProductionQueue[building][i][0];
               if(u.type == type)
               {
                  unit = u;
                  this._unitProductionQueue[building].splice(i,1);
                  break;
               }
            }
         }
         if(unit == null)
         {
            return null;
         }
         if(this.buttonInfoMap != null)
         {
            if(String(unit.type) in this.buttonInfoMap)
            {
               --this.buttonInfoMap[unit.type][3];
            }
         }
         return unit;
      }
      
      public function initTeamButtons(gameScreen:GameScreen) : void
      {
      }
      
      public function spawnUnitGroup(u:Array) : void
      {
         var type:int = 0;
         var newUnit:Unit = null;
         var c:int = 0;
         for each(type in u)
         {
            if(this.unitsAvailable == null || type in this.unitsAvailable)
            {
               newUnit = this.game.unitFactory.getUnit(type);
               this.spawn(newUnit,this.game);
               newUnit.x = newUnit.px = this.homeX + 100;
               newUnit.y = newUnit.py = c * this.game.map.height / u.length;
               this.population += newUnit.population;
            }
            c++;
         }
      }
      
      public function checkUnitCreateMouseOver(gameScreen:GameScreen) : void
      {
         var m:MovieClip = null;
         var key:String = null;
         var overlay:MovieClip = null;
         var button:MovieClip = null;
         var cancelButtonMc:MovieClip = null;
         var number:TextField = null;
         var underlay:MovieClip = null;
         var highlight:MovieClip = null;
         var k:int = 0;
         var tip:XMLList = null;
         var c:UnitCreateMove = null;
         var x:int = gameScreen.stage.mouseX;
         var y:int = gameScreen.stage.mouseY;
         var isCanceling:Boolean = false;
         for each(m in this.buildingHighlights)
         {
            if(m != null)
            {
               m.visible = false;
            }
         }
         for(key in this.buttonInfoMap)
         {
            overlay = this.buttonInfoMap[key][1];
            button = this.buttonInfoMap[key][0];
            cancelButtonMc = this.buttonInfoMap[key][4];
            number = TextField(MovieClip(this.buttonInfoMap[key][0]).getChildByName("number"));
            underlay = MovieClip(this.buttonInfoMap[key][8]);
            highlight = MovieClip(this.buttonInfoMap[key][7]);
            if(Boolean(this.unitsAvailable) && !(key in this.unitsAvailable))
            {
               button.visible = false;
               overlay.visible = false;
               cancelButtonMc.visible = false;
            }
            else
            {
               button.visible = true;
               overlay.visible = true;
               if(underlay != null)
               {
                  underlay.visible = true;
               }
               number.text = "" + this.buttonInfoMap[key][3];
               if(this.buttonInfoMap[key][3] > 0)
               {
                  cancelButtonMc.visible = true;
                  if(cancelButtonMc.hitTestPoint(x,y,false) && gameScreen.userInterface.mouseState.clicked)
                  {
                     c = new UnitCreateMove();
                     c.unitType = -int(key);
                     gameScreen.doMove(c,this.id);
                     isCanceling = true;
                  }
               }
               else
               {
                  cancelButtonMc.visible = false;
               }
               k = int(this.unitInfo[key][2]);
               if(this._unitProductionQueue[k].length != 0 && Unit(this._unitProductionQueue[k][0][0]).type == int(key))
               {
                  this.drawTimerOverlay(this.buttonInfoMap[key][6],overlay,this._unitProductionQueue[k][0][1] / Unit(this._unitProductionQueue[k][0][0]).createTime);
               }
               else
               {
                  this.buttonInfoMap[key][6].graphics.clear();
               }
               if(number.text == "0")
               {
                  number.text = "";
               }
               tip = this.buttonInfoMap[key][2];
               overlay.visible = true;
               if(isCanceling == false && button.hitTestPoint(x,y,false))
               {
                  if(gameScreen.userInterface.mouseState.clicked)
                  {
                     if(this.gold < this.unitInfo[int(key)][0])
                     {
                        this.game.gameScreen.userInterface.helpMessage.showMessage("Not enough gold to construct unit");
                        this.game.soundManager.playSoundFullVolume("UnitMakeFail");
                     }
                     else if(this.mana < this.unitInfo[int(key)][1])
                     {
                        this.game.gameScreen.userInterface.helpMessage.showMessage("Not enough mana to construct unit");
                        this.game.soundManager.playSoundFullVolume("UnitMakeFail");
                     }
                     else
                     {
                        c = new UnitCreateMove();
                        c.unitType = int(key);
                        gameScreen.doMove(c,this.id);
                        this.game.soundManager.playSoundFullVolume("UnitMake");
                     }
                  }
                  highlight.visible = true;
                  overlay.visible = false;
                  this.updateButtonOverXML(this.game,tip);
               }
            }
         }
      }
      
      public function init() : void
      {
         this._population = 0;
         this._castleBack.x = this.homeX;
         this._castleBack.py = this._castleBack.y = -this.game.battlefield.y;
         this._castleBack.scaleX *= this.direction;
         this._castleFront.x = this.homeX;
         this._castleFront.y = -this.game.battlefield.y;
         this._castleFront.py = this.game.map.height / 2 + 40;
         this._castleFront.scaleX *= this.direction;
         this.statue.x = this.homeX + this.direction * 500;
         this.statue.py = this.game.map.height / 2;
         this.statue.px = this.statue.x;
         this.statue.y = this.statue.py;
         this.statue.scaleX *= 0.8;
         this.statue.scaleY *= 0.8;
         this.statue.scaleX *= this.direction;
         this.base.x = this.homeX - this.direction * this.game.map.screenWidth;
         this.base.scaleX = this.direction;
         this.base.py = 0;
         this.base.px = this.base.x;
         this.base.y = -this.game.map.y;
         this.base.mouseEnabled = true;
         this.castleFront.cacheAsBitmap = true;
         this.castleBack.cacheAsBitmap = true;
         this.statue.cacheAsBitmap = true;
         this.statue.team = this;
      }
      
      public function get isEnemy() : Boolean
      {
         return this._isEnemy;
      }
      
      public function set isEnemy(value:Boolean) : void
      {
         this._isEnemy = value;
      }
      
      public function get game() : StickWar
      {
         return this._game;
      }
      
      public function set game(value:StickWar) : void
      {
         this._game = value;
      }
      
      public function spawnUnit(type:int, game:StickWar) : void
      {
         var unit:Unit = null;
         if(type >= 0)
         {
            if(this.unitsAvailable != null && !(type in this.unitsAvailable))
            {
               return;
            }
            if(!(type in this.unitInfo))
            {
               return;
            }
            unit = null;
            if(this.gold >= this.unitInfo[type][0] && this.mana >= this.unitInfo[type][1])
            {
               unit = Unit(game.unitFactory.getUnit(int(type)));
               if(unit.population + this._population > this.populationLimit)
               {
                  game.unitFactory.returnUnit(unit.type,unit);
                  unit = null;
               }
               else
               {
                  this.gold -= this.unitInfo[type][0];
                  this.mana -= this.unitInfo[type][1];
               }
            }
            else if(this == game.team)
            {
               if(this.gold < this.unitInfo[type][0])
               {
                  game.gameScreen.userInterface.helpMessage.showMessage("Not enough gold to construct unit");
               }
               else if(this.mana < this.unitInfo[type][1])
               {
                  game.gameScreen.userInterface.helpMessage.showMessage("Not enough mana to construct unit");
               }
            }
            if(unit != null)
            {
               this.queueUnit(unit);
               this._population += unit.population;
            }
         }
         else if(this.dequeueUnit(-int(type),true) != null)
         {
            this.gold += int(this.unitInfo[-type][0]);
            this.mana += int(this.unitInfo[-type][1]);
            unit = Unit(game.unitFactory.getUnit(-int(type)));
            this._population -= unit.population;
         }
      }
      
      public function spawn(unit:Unit, game:StickWar) : void
      {
         unit.isTowerSpawned = false;
         unit.isDead = false;
         unit.isDieing = false;
         unit.team = this;
         unit.setBuilding();
         var c:ColorTransform = unit.mc.transform.colorTransform;
         var r:int = game.random.nextInt();
         if(this.isEnemy)
         {
            c.redOffset = 75;
         }
         else
         {
            c.redOffset = 0;
            c.blueOffset = 0;
            c.greenOffset = 0;
         }
         unit.isOnFire = false;
         unit.mc.transform.colorTransform = c;
         unit.id = game.getNextUnitId();
         game.units[unit.id] = unit;
         if(unit.building == null)
         {
            unit.x = unit.px = this.homeX + this.direction * SPAWN_OFFSET_X;
            unit.y = unit.py = game.map.height / 2;
         }
         else if(unit.type == Unit.U_MINER || unit.type == Unit.U_CHAOS_MINER)
         {
            unit.x = unit.px = unit.team.homeX;
            unit.y = unit.py = 100;
         }
         else
         {
            unit.x = unit.px = unit.team.base.x + this.direction * (unit.building.hitAreaMovieClip.x + unit.building.hitAreaMovieClip.width / 2);
            unit.y = unit.py = 100;
         }
         unit.x = -100;
         unit.y = -100;
         unit.init(game);
         unit.healthBar.reset();
         this.units.push(unit);
         game.battlefield.addChildAt(unit,0);
         unit.ai.init();
         var m:AttackMoveCommand = new AttackMoveCommand(game);
         if(unit.type == Unit.U_MINER || unit.type == Unit.U_CHAOS_MINER)
         {
            m.goalX = this.homeX + this.direction * 850 + game.random.nextNumber() * 40 - 20;
         }
         else
         {
            m.goalX = this.homeX + this.direction * 1000;
         }
         if(unit.type == Unit.U_CAT)
         {
            ++this.numberOfCats;
         }
         m.goalY = game.map.height / 2 + game.random.nextNumber() * 60 - 30;
         unit.ai.setCommand(game,m);
         unit.cure();
         this.unitGroups[unit.type].push(unit);
         if(game.main.isKongregate)
         {
            if(unit.type == Unit.U_SPEARTON)
            {
               if(this.unitGroups[unit.type].length == 10)
               {
                  game.main.kongregateReportStatistic("speartons300",1);
               }
            }
            if(this.population == 80)
            {
               game.main.kongregateReportStatistic("maxPopulation",1);
            }
         }
         if(this.currentAttackState == Team.G_GARRISON)
         {
            this.garrison(true,unit);
         }
         if(unit.type == Unit.U_MINER || unit.type == Unit.U_CHAOS_MINER)
         {
            MinerAi(unit.ai).targetOre = null;
            MinerAi(unit.ai).isUnassigned = true;
         }
         if(this == game.team)
         {
            game.soundManager.playSoundFullVolume("UnitReady");
         }
         unit.hasDefaultLoadout = this.loadout.unitHasDefaultLoadout(unit.type);
      }
      
      public function spawnMiners() : void
      {
      }
      
      public function removeUnit(unit:Unit, game:StickWar) : void
      {
         if(unit.type == Unit.U_CAT)
         {
            --this.numberOfCats;
         }
         unit.cure();
         this._deadUnits.push(unit);
         if(!unit.isTowerSpawned)
         {
            this._population -= unit.population;
         }
         this.unitGroups[unit.type].splice(this.unitGroups[unit.type].indexOf(unit),1);
         if(unit.id in this.garrisonedUnits)
         {
            delete this.garrisonedUnits[unit.id];
         }
      }
      
      public function detectedUserInput(userInterface:UserInterface) : void
      {
      }
      
      public function removeUnitCompletely(unit:Unit, game:StickWar) : void
      {
         this._units.splice(this._units.indexOf(unit),1);
         delete game.units[unit.id];
         if(game.battlefield.contains(unit))
         {
            game.battlefield.removeChild(unit);
         }
         var index:int = int(this.unitGroups[unit.type].indexOf(unit));
         if(index != -1)
         {
            this.unitGroups[unit.type].splice(index,1);
         }
         game.unitFactory.returnUnit(unit.type,unit);
         if(unit.id in this.garrisonedUnits)
         {
            delete this.garrisonedUnits[unit.id];
         }
      }
      
      protected function singlePlayerDebugInputSwitch(userInterface:UserInterface, unitType:int, key:int) : void
      {
         var c:UnitCreateMove = null;
         if(userInterface.keyBoardState.isPressed(key))
         {
            c = new UnitCreateMove();
            if(userInterface.gameScreen is SingleplayerGameScreen && userInterface.gameScreen.isDebug && userInterface.keyBoardState.isShift)
            {
               c.unitType = unitType;
               userInterface.gameScreen.doMove(c,userInterface.gameScreen.team.enemyTeam.id);
            }
            else if(this.gold < this.unitInfo[int(unitType)][0])
            {
               this.game.gameScreen.userInterface.helpMessage.showMessage("Not enough gold to construct unit");
               this.game.soundManager.playSoundFullVolume("UnitMakeFail");
            }
            else if(this.mana < this.unitInfo[int(unitType)][1])
            {
               this.game.gameScreen.userInterface.helpMessage.showMessage("Not enough mana to construct unit");
               this.game.soundManager.playSoundFullVolume("UnitMakeFail");
            }
            else
            {
               c = new UnitCreateMove();
               c.unitType = int(unitType);
               userInterface.gameScreen.doMove(c,this.id);
               this.game.soundManager.playSoundFullVolume("UnitMake");
            }
         }
      }
      
      public function updateButtonOverXML(game:StickWar, item:XMLList) : void
      {
         ++this.sameButtonCount;
         if(this.sameButtonCount > 3)
         {
            game.tipBox.displayTip(item.child("name"),item.child("info"),item.child("cooldown"),item.child("gold"),item.child("mana"),item.child("population"));
         }
         this.hit = true;
      }
      
      public function updateButtonOver(game:StickWar, title:String, info:String, time:int, gold:int, mana:int, population:int) : void
      {
         ++this.sameButtonCount;
         if(this.sameButtonCount > 3)
         {
            game.tipBox.displayTip(title,info,time,gold,mana,population);
         }
         this.hit = true;
      }
      
      public function updateButtonOverPost(game:StickWar) : void
      {
         if(!game.gameScreen.isFastForwardFrame)
         {
            if(!this.hit)
            {
               this.buttonOver = null;
               this.sameButtonCount = 0;
            }
            this.hit = false;
         }
      }
      
      protected function getSpawnUnitType(game:StickWar) : int
      {
         return -1;
      }
      
      private function spawnMiddleUnit(game:StickWar) : Unit
      {
         if(game.map.hills.length == 0)
         {
            return null;
         }
         var type:int = this.getSpawnUnitType(game);
         var newUnit:Unit = game.unitFactory.getUnit(type);
         this.spawn(newUnit,game);
         newUnit.x = newUnit.px = game.map.hills[0].px;
         newUnit.y = newUnit.py = game.map.height / 2;
         newUnit.isTowerSpawned = true;
         game.soundManager.playSoundFullVolumeRandom("GhostTower",2);
         var attackMoveCommand:AttackMoveCommand = new AttackMoveCommand(game);
         attackMoveCommand.type = UnitCommand.ATTACK_MOVE;
         attackMoveCommand.goalX = this.enemyTeam.statue.px;
         attackMoveCommand.goalY = game.map.height / 2;
         attackMoveCommand.realX = this.enemyTeam.statue.px;
         attackMoveCommand.realY = game.map.height / 2;
         newUnit.ai.setCommand(game,attackMoveCommand);
         var scale:Number = 1;
         if(this.tech.isResearched(Tech.TOWER_SPAWN_II))
         {
            scale = 1.5;
         }
         game.projectileManager.initTowerSpawn(game.map.hills[0].px,game.map.height / 2,this,scale);
         return newUnit;
      }
      
      public function updateStatue() : void
      {
         if(this._statueType != "default")
         {
            this.statue.mc.statue.gotoAndStop(this._statueType);
         }
         else
         {
            this.statue.mc.statue.gotoAndStop("default");
         }
      }
      
      public function update(game:StickWar) : void
      {
         var w:Wall = null;
         var isDebug:Boolean = false;
         var queue:Array = null;
         var unit:String = null;
         var controllingTeam:Team = null;
         var currentUnit:Unit = null;
         var garrisonMove:UnitMove = null;
         if(game.map.hills.length != 0)
         {
            controllingTeam = game.map.hills[0].getControllingTeam(game);
            if(controllingTeam == this)
            {
               if(this.tech.isResearched(Tech.TOWER_SPAWN_I))
               {
                  if(this.spawnedUnit != null)
                  {
                     if(!this.spawnedUnit.isAlive())
                     {
                        this.spawnedUnit = null;
                     }
                     this.timeSinceSpawnedUnit = game.frame;
                  }
                  else if(game.frame - this.timeSinceSpawnedUnit > this.towerSpawnDelay)
                  {
                     this.spawnedUnit = this.spawnMiddleUnit(game);
                  }
               }
            }
         }
         if(game.frame % (30 * 5) == 0)
         {
            if(this.tech.isResearched(Tech.BANK_PASSIVE_3))
            {
               this.gold += this.passiveIncomeAmountUpgraded3;
               this.mana += this.passiveManaUpgraded3;
            }
            else if(this.tech.isResearched(Tech.BANK_PASSIVE_2))
            {
               this.gold += this.passiveIncomeAmountUpgraded2;
               this.mana += this.passiveManaUpgraded2;
            }
            else if(this.tech.isResearched(Tech.BANK_PASSIVE_1))
            {
               this.gold += this.passiveIncomeAmountUpgraded1;
               this.mana += this.passiveManaUpgraded1;
            }
            else
            {
               this.gold += this.passiveIncomeAmount;
               this.mana += this.passiveMana;
            }
         }
         for each(w in this._walls)
         {
            w.update(game);
         }
         this.tech.update(game);
         isDebug = game.gameScreen is SingleplayerGameScreen;
         for each(queue in this._unitProductionQueue)
         {
            if(queue.length != 0)
            {
               if(queue[0][1] > Unit(queue[0][0]).createTime || isDebug)
               {
                  this.spawn(Unit(queue[0][0]),game);
                  this.dequeueUnit(Unit(queue[0][0]).type,false);
               }
               else
               {
                  ++queue[0][1];
               }
            }
         }
         this._castleDefence.update(game);
         this._ai.update(game);
         this.statue.update(game);
         if(this._units.length != 0)
         {
            this._forwardUnit = null;
            this._forwardUnitNotSpawn = null;
            for(unit in this._units)
            {
               currentUnit = this._units[unit];
               if(Boolean(currentUnit.isAlive()) && (this._forwardUnit == null || currentUnit.px * this.direction > this._forwardUnit.px * this.direction))
               {
                  this._forwardUnit = currentUnit;
               }
               if(Boolean(currentUnit.isAlive()) && Boolean(!currentUnit.isTowerSpawned) && (this._forwardUnitNotSpawn == null || currentUnit.px * this.direction > this._forwardUnitNotSpawn.px * this.direction))
               {
                  this._forwardUnitNotSpawn = currentUnit;
               }
               if(!currentUnit.isDead)
               {
                  if(!currentUnit.isSlow() || game.frame % 2 == 0)
                  {
                     currentUnit.update(game);
                  }
               }
            }
         }
         else
         {
            this._forwardUnit = null;
         }
         for(unit in this._deadUnits)
         {
            this._deadUnits[unit].update(game);
         }
         if(this._deadUnits.length > 0 && Unit(this._deadUnits[0]).timeOfDeath > 30 * 20)
         {
            this.removeUnitCompletely(this._deadUnits[0],game);
            this._deadUnits[0] = this._deadUnits[this._deadUnits.length - 1];
            this._deadUnits.length -= 1;
         }
         for(unit in this.garrisonedUnits)
         {
            if(garrisonMove == null)
            {
               garrisonMove = new UnitMove();
               garrisonMove.moveType = UnitCommand.MOVE;
               garrisonMove.owner = this.id;
               garrisonMove.arg0 = this.homeX - this.direction * game.map.screenWidth / 3;
               garrisonMove.arg1 = game.map.height / 2;
            }
            garrisonMove.units.push(this.garrisonedUnits[unit].id);
         }
         if(garrisonMove != null)
         {
            garrisonMove.execute(game);
         }
      }
      
      public function drawTimerOverlay(mc:MovieClip, overlay:MovieClip, fraction:Number) : void
      {
         mc.graphics.clear();
         mc.y = -1;
         var width:int = overlay.width;
         var height:int = overlay.height + 1;
         mc.graphics.beginFill(0,1);
         mc.graphics.moveTo(width / 2,0);
         mc.graphics.lineTo(width / 2,height / 2);
         var theta:Number = fraction * 2 * Math.PI;
         var cornerAngle:Number = Math.atan2(width / 2,height / 2);
         var a:Number = theta;
         if(theta < cornerAngle)
         {
            mc.graphics.lineTo(width / 2 + Util.tan(theta) * height / 2,0);
         }
         else if(theta <= Math.PI / 2)
         {
            mc.graphics.lineTo(width,Util.tan(theta - cornerAngle) * height / 2);
         }
         else if(theta <= Math.PI - cornerAngle)
         {
            mc.graphics.lineTo(width,height / 2 + Util.tan(theta - Math.PI / 2) * height / 2);
         }
         else if(theta <= Math.PI)
         {
            mc.graphics.lineTo(width / 2 + Util.tan(Math.PI - theta) * height / 2,height);
         }
         else if(theta <= Math.PI + cornerAngle)
         {
            mc.graphics.lineTo(0 + Util.tan(Math.PI + cornerAngle - theta) * height / 2,height);
         }
         else if(theta <= Math.PI / 2 + Math.PI)
         {
            mc.graphics.lineTo(0,height - Util.tan(theta - Math.PI - cornerAngle) * height / 2);
         }
         else if(theta <= 2 * Math.PI - cornerAngle)
         {
            mc.graphics.lineTo(0,height / 2 - Util.tan(theta - 2 * Math.PI - Math.PI / 2) * height / 2);
         }
         else
         {
            mc.graphics.lineTo(width / 2 + Util.tan(theta) * height / 2,0);
         }
         if(theta <= cornerAngle)
         {
            mc.graphics.lineTo(width,0);
         }
         if(theta <= Math.PI - cornerAngle)
         {
            mc.graphics.lineTo(width,height);
         }
         if(theta <= cornerAngle + Math.PI)
         {
            mc.graphics.lineTo(0,height);
         }
         if(theta <= 2 * Math.PI - cornerAngle)
         {
            mc.graphics.lineTo(0,0);
         }
         mc.graphics.lineTo(width / 2,0);
      }
      
      private function sortOnX(a:Unit, b:Unit) : int
      {
         return a.px - b.px;
      }

      private function countsAsHiddenMilitary(unit:Unit) : Boolean
      {
         return unit is Miner && Miner(unit).isShadowrathDisguise;
      }
      
      private function isMilitaryFilter(unit:Unit, i:int, a:Array) : Boolean
      {
         return (unit.type != Unit.U_MINER && unit.type != Unit.U_CHAOS_MINER || this.countsAsHiddenMilitary(unit)) && unit.isAlive();
      }
      
      public function calculateStatistics() : void
      {
         var unit:Unit = null;
         var copyOfUnits:Array = null;
         this.averagePosition = 0;
         this.attackingForcePopulation = 0;
         var n:int = 0;
         for each(unit in this.units)
         {
            if((unit.type != Unit.U_MINER && unit.type != Unit.U_CHAOS_MINER || this.countsAsHiddenMilitary(unit)) && unit.isAlive())
            {
               if(this.countsAsHiddenMilitary(unit))
               {
                  n += 4;
                  this.averagePosition += unit.px * 4;
                  this.attackingForcePopulation += 4;
               }
               else
               {
                  n += unit.population;
                  this.averagePosition += unit.px * unit.population;
                  this.attackingForcePopulation += unit.population;
               }
            }
         }
         if(n > 0)
         {
            this.averagePosition /= n;
         }
         copyOfUnits = this.units.filter(this.isMilitaryFilter);
         copyOfUnits.sort(this.sortOnX);
         if(copyOfUnits.length > 0)
         {
            this.medianPosition = copyOfUnits[Math.floor(copyOfUnits.length / 2)].px;
         }
      }
      
      public function get enemyTeam() : Team
      {
         return this._enemyTeam;
      }
      
      public function set enemyTeam(value:Team) : void
      {
         this._enemyTeam = value;
      }
      
      public function get units() : Array
      {
         return this._units;
      }
      
      public function set units(value:Array) : void
      {
         this._units = value;
      }
      
      public function get ai() : TeamAi
      {
         return this._ai;
      }
      
      public function set ai(value:TeamAi) : void
      {
         this._ai = value;
      }
      
      public function get name() : int
      {
         return this._name;
      }
      
      public function set name(value:int) : void
      {
         this._name = value;
      }
      
      public function get type() : int
      {
         return this._type;
      }
      
      public function set type(value:int) : void
      {
         this._type = value;
      }
      
      public function get direction() : int
      {
         return this._direction;
      }
      
      public function set direction(value:int) : void
      {
         this._direction = value;
      }
      
      public function get homeX() : int
      {
         return this._homeX;
      }
      
      public function set homeX(value:int) : void
      {
         this._homeX = value;
      }
      
      public function get forwardUnit() : Unit
      {
         return this._forwardUnit;
      }
      
      public function set forwardUnit(value:Unit) : void
      {
         this._forwardUnit = value;
      }
      
      public function get gold() : int
      {
         return this._gold;
      }
      
      public function set gold(value:int) : void
      {
         this._gold = value;
      }
      
      public function get statue() : Statue
      {
         return this._statue;
      }
      
      public function set statue(value:Statue) : void
      {
         this._statue = value;
      }
      
      public function get id() : int
      {
         return this._id;
      }
      
      public function set id(value:int) : void
      {
         this._id = value;
      }
      
      public function get population() : int
      {
         return this._population;
      }
      
      public function set population(value:int) : void
      {
         this._population = value;
      }
      
      public function get castleBack() : Entity
      {
         return this._castleBack;
      }
      
      public function set castleBack(value:Entity) : void
      {
         this._castleBack = value;
      }
      
      public function get castleFront() : Entity
      {
         return this._castleFront;
      }
      
      public function set castleFront(value:Entity) : void
      {
         this._castleFront = value;
      }
      
      public function get base() : Entity
      {
         return this._base;
      }
      
      public function set base(value:Entity) : void
      {
         this._base = value;
      }
      
      public function get buildings() : Dictionary
      {
         return this._buildings;
      }
      
      public function set buildings(value:Dictionary) : void
      {
         this._buildings = value;
      }
      
      public function get tech() : Tech
      {
         return this._tech;
      }
      
      public function set tech(value:Tech) : void
      {
         this._tech = value;
      }
      
      public function get castleDefence() : CastleDefence
      {
         return this._castleDefence;
      }
      
      public function set castleDefence(value:CastleDefence) : void
      {
         this._castleDefence = value;
      }
      
      public function get hit() : Boolean
      {
         return this._hit;
      }
      
      public function set hit(value:Boolean) : void
      {
         this._hit = value;
      }
      
      public function get mana() : int
      {
         return this._mana;
      }
      
      public function set mana(value:int) : void
      {
         this._mana = value;
      }
      
      public function get garrisonedUnits() : Dictionary
      {
         return this._garrisonedUnits;
      }
      
      public function set garrisonedUnits(value:Dictionary) : void
      {
         this._garrisonedUnits = value;
      }

      public function get deadUnits() : Array
      {
         return this._deadUnits;
      }
      
      public function get loadout() : Loadout
      {
         return this._loadout;
      }
      
      public function set loadout(value:Loadout) : void
      {
         this._loadout = value;
      }
      
      public function get poisonedUnits() : Dictionary
      {
         return this._poisonedUnits;
      }
      
      public function set poisonedUnits(value:Dictionary) : void
      {
         this._poisonedUnits = value;
      }
      
      public function get numberOfCats() : int
      {
         return this._numberOfCats;
      }
      
      public function set numberOfCats(value:int) : void
      {
         this._numberOfCats = value;
      }
      
      public function get unitGroups() : Dictionary
      {
         return this._unitGroups;
      }
      
      public function set unitGroups(value:Dictionary) : void
      {
         this._unitGroups = value;
      }
      
      public function get unitInfo() : Dictionary
      {
         return this._unitInfo;
      }
      
      public function set unitInfo(value:Dictionary) : void
      {
         this._unitInfo = value;
      }
      
      public function get unitProductionQueue() : Dictionary
      {
         return this._unitProductionQueue;
      }
      
      public function set unitProductionQueue(value:Dictionary) : void
      {
         this._unitProductionQueue = value;
      }
      
      public function get isAi() : Boolean
      {
         return this._isAi;
      }
      
      public function set isAi(value:Boolean) : void
      {
         this._isAi = value;
      }
      
      public function get walls() : Array
      {
         return this._walls;
      }
      
      public function set walls(value:Array) : void
      {
         this._walls = value;
      }
      
      public function get unitsAvailable() : Dictionary
      {
         return this._unitsAvailable;
      }
      
      public function set unitsAvailable(value:Dictionary) : void
      {
         this._unitsAvailable = value;
      }
      
      public function get handicap() : Number
      {
         return this._handicap;
      }
      
      public function set handicap(value:Number) : void
      {
         this._handicap = value;
      }
      
      public function get realName() : String
      {
         return this._realName;
      }
      
      public function set realName(value:String) : void
      {
         this._realName = value;
      }
      
      public function get lastScreenLookPosition() : int
      {
         return this._lastScreenLookPosition;
      }
      
      public function set lastScreenLookPosition(value:int) : void
      {
         this._lastScreenLookPosition = value;
      }
      
      public function get currentAttackState() : int
      {
         return this._currentAttackState;
      }
      
      public function set currentAttackState(value:int) : void
      {
         this._currentAttackState = value;
      }
      
      public function get buttonInfoMap() : Dictionary
      {
         return this._buttonInfoMap;
      }
      
      public function set buttonInfoMap(value:Dictionary) : void
      {
         this._buttonInfoMap = value;
      }
      
      public function get healthModifier() : Number
      {
         return this._healthModifier;
      }
      
      public function set healthModifier(value:Number) : void
      {
         this._healthModifier = value;
      }
      
      public function get isMember() : Boolean
      {
         return this._isMember;
      }
      
      public function set isMember(value:Boolean) : void
      {
         this._isMember = value;
      }
      
      public function get forwardUnitNotSpawn() : Unit
      {
         return this._forwardUnitNotSpawn;
      }
      
      public function set forwardUnitNotSpawn(value:Unit) : void
      {
         this._forwardUnitNotSpawn = value;
      }
      
      public function get pauseCount() : int
      {
         return this._pauseCount;
      }
      
      public function set pauseCount(value:int) : void
      {
         this._pauseCount = value;
      }
      
      public function get rating() : int
      {
         return this._rating;
      }
      
      public function set rating(value:int) : void
      {
         this._rating = value;
      }
      
      public function get statueType() : String
      {
         return this._statueType;
      }
      
      public function set statueType(value:String) : void
      {
         this._statueType = value;
      }
      
      public function get originalType() : int
      {
         return this._originalType;
      }
      
      public function set originalType(value:int) : void
      {
         this._originalType = value;
      }
   }
}

