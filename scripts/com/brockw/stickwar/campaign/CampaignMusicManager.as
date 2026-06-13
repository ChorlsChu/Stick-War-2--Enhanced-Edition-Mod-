package com.brockw.stickwar.campaign
{
   import com.brockw.stickwar.engine.Team.Team;
   
   public class CampaignMusicManager
   {
      
      public function CampaignMusicManager()
      {
         super();
      }
      
      public function getBackgroundMusic(level:Level) : String
      {
         var title:String = null;
         if(level == null)
         {
            return "chaosInGame";
         }
         title = String(level.title);
         switch(title)
         {
            case "Tutorial":
            case "Silent Assassins: Ninjas Declare War":
            case "Rebels United":
            case "Shadow of the moon: Eclipsors Attack.":
            case "Medusa and the Full Chaos Empire: Final battle":
               return "battleOfTheShadowElves";
            case "Ambush: Native Tribes":
            case "Ambush: Shadowrath Stalkers":
            case "Ambush: Rebels Last Stand":
            case "Ambush: Chaos Breaks the Rebels":
            case "Ambush: Dead Horde":
            case "Ambush: Giants and Eclipsors":
               return "fieldOfMemories";
            case "Blot out the sun: Archidons Declare War":
            case "Magic in the Air: Wizards and monks Declare War ":
            case "The Night is Dark: Juggerknights Attack":
            case " 4 legged Fury: Crawlers Attack":
            case "Medusa's Gates: The Chaos Capital is in sight. ":
               return "enteringTheStronghold";
            case "Massive Battle":
            case "Explosive War: Bombers Attack":
            case "Undead War: Deadly Deads Attack":
            case "Bone Pile: Marrowkai summon war":
               return "chaosInGame";
            default:
               if(Team.getIdFromRaceName(level.oponent.race) == Team.T_GOOD)
               {
                  return "orderInGame";
               }
               return "chaosInGame";
         }
      }

      public function shouldMusicLoop(level:Level) : Boolean
      {
         if(level == null || level.title == null)
         {
            return true;
         }
         if(level.title == "Ambush: Rebels Last Stand")
         {
            return false;
         }
         return true;
      }
   }
}
