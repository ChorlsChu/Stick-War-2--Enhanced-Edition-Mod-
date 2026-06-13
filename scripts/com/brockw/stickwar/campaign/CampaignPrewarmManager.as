package com.brockw.stickwar.campaign
{
   import com.brockw.stickwar.engine.StickWar;
   import com.brockw.stickwar.engine.units.Unit;
   
   public class CampaignPrewarmManager
   {
      
      private static const PREWARM_INTERVAL_FRAMES:int = 10;
      
      private var delayedQueue:Array;
      
      private var nextPrewarmFrame:int;
      
      private var game:StickWar;
      
      public function CampaignPrewarmManager()
      {
         super();
         this.delayedQueue = [];
         this.nextPrewarmFrame = PREWARM_INTERVAL_FRAMES;
      }
      
      public function initialize(level:Level, game:StickWar, reinforcementUnits:Array) : void
      {
         var immediateUnits:Array = [];
         var delayedUnits:Array = [];
         this.game = game;
         this.nextPrewarmFrame = PREWARM_INTERVAL_FRAMES;
         if(level == null || game == null || game.unitFactory == null)
         {
            this.delayedQueue = [];
            return;
         }
         this.addUnitsFromSource(immediateUnits,level.player.startingUnits);
         this.addUnitsFromSource(immediateUnits,level.oponent.startingUnits);
         this.addUnitsFromSource(immediateUnits,this.getImmediateUnitsForLevel(level.title));
         this.addUnitsFromSource(delayedUnits,reinforcementUnits);
         this.addUnitsFromSource(delayedUnits,this.getDelayedUnitsForLevel(level.title));
         this.removeDuplicatesAgainst(delayedUnits,immediateUnits);
         this.runImmediate(immediateUnits);
         this.delayedQueue = delayedUnits;
      }
      
      public function process() : void
      {
         var nextType:int = 0;
         if(this.delayedQueue == null || this.delayedQueue.length == 0 || this.game == null)
         {
            return;
         }
         if(this.game.frame < this.nextPrewarmFrame)
         {
            return;
         }
         nextType = int(this.delayedQueue.shift());
         this.prewarmUnitType(nextType);
         this.nextPrewarmFrame = this.game.frame + PREWARM_INTERVAL_FRAMES;
      }
      
      public function reset() : void
      {
         this.delayedQueue = [];
         this.nextPrewarmFrame = 0;
         this.game = null;
      }
      
      public function get queueLength() : int
      {
         return this.delayedQueue != null ? this.delayedQueue.length : 0;
      }
      
      private function runImmediate(unitTypes:Array) : void
      {
         var unitType:int = 0;
         if(unitTypes == null)
         {
            return;
         }
         for each(unitType in unitTypes)
         {
            this.prewarmUnitType(unitType);
         }
      }
      
      private function prewarmUnitType(unitType:int) : void
      {
         var warmUnit:Unit = null;
         if(this.game == null || this.game.unitFactory == null || unitType <= 0)
         {
            return;
         }
         warmUnit = this.game.unitFactory.getUnit(unitType);
         if(warmUnit == null)
         {
            return;
         }
         if(warmUnit.mc != null)
         {
            warmUnit.mc.gotoAndStop(1);
         }
         this.game.unitFactory.returnUnit(unitType,warmUnit);
      }
      
      private function addUnitsFromSource(dest:Array, source:*) : void
      {
         var nested:* = undefined;
         if(dest == null || source == null)
         {
            return;
         }
         if(source is Array)
         {
            for each(nested in source)
            {
               this.addUnitsFromSource(dest,nested);
            }
            return;
         }
         this.addUnitType(dest,int(source));
      }
      
      private function addUnitType(dest:Array, unitType:int) : void
      {
         if(dest == null || !this.shouldPrewarmUnitType(unitType) || dest.indexOf(unitType) != -1)
         {
            return;
         }
         dest.push(unitType);
      }
      
      private function removeDuplicatesAgainst(dest:Array, existing:Array) : void
      {
         var i:int = 0;
         if(dest == null || existing == null)
         {
            return;
         }
         i = dest.length - 1;
         while(i >= 0)
         {
            if(existing.indexOf(dest[i]) != -1)
            {
               dest.splice(i,1);
            }
            i--;
         }
      }
      
      private function shouldPrewarmUnitType(unitType:int) : Boolean
      {
         switch(unitType)
         {
            case Unit.U_SPEARTON:
            case Unit.U_ARCHER:
            case Unit.U_NINJA:
            case Unit.U_MAGIKILL:
            case Unit.U_MONK:
            case Unit.U_BOMBER:
            case Unit.U_GIANT:
            case Unit.U_KNIGHT:
            case Unit.U_DEAD:
            case Unit.U_CAT:
            case Unit.U_WINGIDON:
            case Unit.U_SKELATOR:
            case Unit.U_MEDUSA:
            case Unit.U_ENSLAVED_GIANT:
               return true;
            default:
               return false;
         }
      }
      
      private function getImmediateUnitsForLevel(title:String) : Array
      {
         switch(title)
         {
            case "Tutorial":
               return [Unit.U_SPEARTON,Unit.U_ARCHER];
            case "Blot out the sun: Archidons Declare War":
               return [Unit.U_ARCHER];
            case "Silent Assassins: Ninjas Declare War":
               return [Unit.U_NINJA];
            case "Magic in the Air: Wizards and monks Declare War ":
               return [Unit.U_MAGIKILL,Unit.U_MONK];
            case "Rebels United":
               return [Unit.U_SPEARTON,Unit.U_ARCHER,Unit.U_NINJA,Unit.U_MAGIKILL,Unit.U_MONK];
            case "Explosive War: Bombers Attack":
               return [Unit.U_BOMBER,Unit.U_GIANT];
            case "The Night is Dark: Juggerknights Attack":
            case "Undead War: Deadly Deads Attack":
               return [Unit.U_KNIGHT,Unit.U_DEAD];
            case " 4 legged Fury: Crawlers Attack":
               return [Unit.U_CAT,Unit.U_BOMBER];
            case "Shadow of the moon: Eclipsors Attack.":
               return [Unit.U_WINGIDON,Unit.U_KNIGHT];
            case "Bone Pile: Marrowkai summon war":
               return [Unit.U_SKELATOR,Unit.U_DEAD,Unit.U_KNIGHT];
            case "Medusa's Gates: The Chaos Capital is in sight. ":
               return [Unit.U_MEDUSA,Unit.U_KNIGHT,Unit.U_DEAD,Unit.U_SKELATOR,Unit.U_WINGIDON,Unit.U_GIANT,Unit.U_CAT,Unit.U_BOMBER];
            default:
               return [];
         }
      }
      
      private function getDelayedUnitsForLevel(title:String) : Array
      {
         switch(title)
         {
            case "Rebels United":
               return [Unit.U_SPEARTON,Unit.U_ARCHER,Unit.U_NINJA,Unit.U_MAGIKILL,Unit.U_MONK];
            case "Explosive War: Bombers Attack":
               return [Unit.U_BOMBER,Unit.U_GIANT];
            case "Medusa's Gates: The Chaos Capital is in sight. ":
               return [Unit.U_MEDUSA,Unit.U_KNIGHT,Unit.U_DEAD,Unit.U_SKELATOR,Unit.U_WINGIDON,Unit.U_GIANT,Unit.U_CAT,Unit.U_BOMBER,Unit.U_ENSLAVED_GIANT];
            default:
               return [];
         }
      }
   }
}
