package com.brockw.stickwar.campaign
{
   import com.brockw.stickwar.engine.StickWar;
   import com.brockw.stickwar.engine.Team.Tech;
   import com.brockw.stickwar.engine.units.*;
   
   public class CampaignBossSpawner
   {
      
      private var game:StickWar;
      
      public function CampaignBossSpawner(game:StickWar)
      {
         super();
         this.game = game;
      }
      
      public function cleanUp() : void
      {
         this.game = null;
      }
      
      public function isFactionBossLevel(title:String) : Boolean
      {
         return title == "Tutorial" || title == "Blot out the sun: Archidons Declare War" || title == "Silent Assassins: Ninjas Declare War" || title == "Magic in the Air: Wizards and monks Declare War " || title == "The Night is Dark: Juggerknights Attack" || title == "Shadow of the moon: Eclipsors Attack." || title == "Bone Pile: Marrowkai summon war" || title == "Medusa's Gates: The Chaos Capital is in sight. ";
      }
      
      public function shouldPromoteWestwindBoss(unitType:int, spawnedCount:int) : Boolean
      {
         switch(unitType)
         {
            case Unit.U_SPEARTON:
            case Unit.U_ARCHER:
            case Unit.U_NINJA:
            case Unit.U_MAGIKILL:
            case Unit.U_MONK:
               return spawnedCount == 1;
            default:
               return false;
         }
      }
      
      public function shouldPromoteFactionBoss(title:String, unitType:int, spawnedCount:int) : Boolean
      {
         switch(title)
         {
            case "Tutorial":
               return unitType == Unit.U_SPEARTON && spawnedCount == 1;
            case "Blot out the sun: Archidons Declare War":
               return false;
            case "Silent Assassins: Ninjas Declare War":
               return false;
            case "Magic in the Air: Wizards and monks Declare War ":
               return (unitType == Unit.U_MAGIKILL || unitType == Unit.U_MONK) && spawnedCount == 1;
            case "The Night is Dark: Juggerknights Attack":
               return unitType == Unit.U_KNIGHT && spawnedCount == 1;
            case "Shadow of the moon: Eclipsors Attack.":
               return unitType == Unit.U_WINGIDON && spawnedCount == 1;
            case "Bone Pile: Marrowkai summon war":
               return unitType == Unit.U_SKELATOR && spawnedCount == 1;
            case "Medusa's Gates: The Chaos Capital is in sight. ":
               return (unitType == Unit.U_KNIGHT || unitType == Unit.U_WINGIDON || unitType == Unit.U_SKELATOR) && spawnedCount == 1;
            default:
               return false;
         }
      }
      
      public function configureWestwindBoss(unit:Unit) : void
      {
         if(unit == null)
         {
            return;
         }
         if(unit is Spearton)
         {
            Spearton(unit).makeBoss();
            return;
         }
         if(unit is Archer)
         {
            Archer(unit).makeBoss();
         }
         else if(unit is Ninja)
         {
            Ninja(unit).makeBoss();
         }
         else if(unit is Magikill)
         {
            Magikill(unit).makeBoss();
         }
         else if(unit is Monk)
         {
            Monk(unit).makeBoss();
         }
         else if(unit is Knight)
         {
            Knight(unit).makeBoss();
         }
         else if(unit is Wingidon)
         {
            Wingidon(unit).makeBoss();
         }
         else if(unit is Skelator)
         {
            Skelator(unit).makeBoss();
         }
         unit.isBossMovementLocked = false;
      }
      
      public function configureFactionBoss(unit:Unit, title:String = "") : void
      {
         this.configureWestwindBoss(unit);
         if(unit is Skelator)
         {
            Skelator(unit).makeBoss(title == "Medusa's Gates: The Chaos Capital is in sight. ");
         }
         if(unit != null && title != "Medusa's Gates: The Chaos Capital is in sight. ")
         {
            unit.enableCampaignBossEscape();
         }
      }
      
      public function grantWestwindBossResearch() : void
      {
         if(this.game == null || this.game.teamB == null || this.game.teamB.tech == null)
         {
            return;
         }
         this.game.teamB.tech.isResearchedMap[Tech.ARCHIDON_FIRE] = true;
         this.game.teamB.tech.isResearchedMap[Tech.BLOCK] = true;
         this.game.teamB.tech.isResearchedMap[Tech.SHIELD_BASH] = true;
         this.game.teamB.tech.isResearchedMap[Tech.CLOAK] = true;
         this.game.teamB.tech.isResearchedMap[Tech.CLOAK_II] = true;
         this.game.teamB.tech.isResearchedMap[Tech.MAGIKILL_WALL] = true;
         this.game.teamB.tech.isResearchedMap[Tech.MAGIKILL_POISON] = true;
         this.game.teamB.tech.isResearchedMap[Tech.MONK_CURE] = true;
         this.game.teamB.tech.isResearchedMap[Tech.CASTLE_ARCHER_1] = true;
         this.game.teamB.tech.isResearchedMap[Tech.CASTLE_ARCHER_2] = true;
         this.game.teamB.tech.isResearchedMap[Tech.WINGIDON_SPEED] = true;
      }
      
      public function grantFactionBossResearch(title:String) : void
      {
         if(this.game == null || this.game.teamB == null || this.game.teamB.tech == null)
         {
            return;
         }
         switch(title)
         {
            case "Tutorial":
               this.game.teamB.tech.isResearchedMap[Tech.BLOCK] = true;
               this.game.teamB.tech.isResearchedMap[Tech.SHIELD_BASH] = true;
               break;
            case "Blot out the sun: Archidons Declare War":
               this.game.teamB.tech.isResearchedMap[Tech.ARCHIDON_FIRE] = true;
               break;
            case "Silent Assassins: Ninjas Declare War":
               this.game.teamB.tech.isResearchedMap[Tech.CLOAK] = true;
               this.game.teamB.tech.isResearchedMap[Tech.CLOAK_II] = true;
               break;
            case "Magic in the Air: Wizards and monks Declare War ":
               this.game.teamB.tech.isResearchedMap[Tech.MAGIKILL_WALL] = true;
               this.game.teamB.tech.isResearchedMap[Tech.MAGIKILL_POISON] = true;
               this.game.teamB.tech.isResearchedMap[Tech.MONK_CURE] = true;
               break;
            case "Shadow of the moon: Eclipsors Attack.":
               this.game.teamB.tech.isResearchedMap[Tech.WINGIDON_SPEED] = true;
               break;
            case "Medusa's Gates: The Chaos Capital is in sight. ":
               this.game.teamB.tech.isResearchedMap[Tech.WINGIDON_SPEED] = true;
               this.game.teamB.tech.isResearchedMap[Tech.SKELETON_FIST_ATTACK] = true;
               break;
            case "Bone Pile: Marrowkai summon war":
               this.game.teamB.tech.isResearchedMap[Tech.SKELETON_FIST_ATTACK] = true;
         }
      }
   }
}
