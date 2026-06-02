# Stick War 2: Enhanced Edition Mod

`Stick War 2: Enhanced Edition Mod` is a campaign-focused overhaul of `Stick War 2` that expands boss fights, improves enemy behavior, adds new level events, rebalances campaign progression, and fixes several bugs/performance issues from the original game.

This mod is built for players who want the original campaign to feel more dramatic, more reactive, and more boss-heavy while still keeping the classic Stick War 2 feel.

![Thumbnail](thumbnail.jpg)

## How to Play

1. Open `flashplayer_32_sa.exe`, or any standalone Flash Player projector.
2. Drag `Stick_War_2_Upgrades.swf` into the Flash Player window.
3. Start a campaign and play normally.

Modern browsers usually cannot run Flash content directly, so the standalone projector is recommended.

## Main Features

- Expanded campaign boss encounters for both Order and Chaos factions.
- New Chaos boss reinforcements in their own levels and in `Medusa's Gates`.
- Smarter campaign enemy AI with better army advantage checks and less awkward cautious attacks.
- Campaign reinforcements with temporary statue protection to prevent instant wave deletion.
- New boss abilities, passives, cosmetics, and phase behavior.
- Player-side quality-of-life toggles for Archidons, Shadowraths, and Magikill.
- Reworked Medusa final boss encounter with stronger phases and summons.
- Bug fixes for crashes, spell edge cases, health bars, unit control, and campaign screens.
- Performance cleanup for debug overlays, campaign map updates, AI scans, and repeated logic.

## Boss Roster

### Order Bosses

- `Spearton Boss`
  - Uses `Shield Wall` and `Shield Bash`.
  - Commands nearby Speartons to brace with him.
- `Archidon Boss`
  - Uses Fire Arrows.
  - Commands nearby Archidons to use Fire Arrows.
  - Can retreat and regroup with extra archers.
- `Shadowrath Boss`
  - Uses special boss cloak behavior.
  - Can chain cloak after successful attacks.
  - Leads nearby Shadowraths into flanks.
- `Magikill Boss`
  - Uses stun-focused lightning.
  - Summons Swordwraths, Speartons, and Archidons.
  - Protects the enemy statue with a temporary ward.
- `Meric Boss`
  - Can revive fallen allies.
  - Prioritizes stronger units when reviving.

### Chaos Bosses

- `Knight Boss`
  - Uses boss-style charge pressure and enhanced durability.
  - Appears in Chaos boss reinforcements where relevant.
- `Wingidon Boss`
  - Uses `Eclipse Mark`, `Demon Burst Fire`, and `Sky Commander Aura`.
  - Can direct nearby Wingidons toward marked targets.
  - Has anti-arrow pressure behavior to avoid instant archer deletion.
- `Skelator / Marrowkai Boss`
  - Uses `Dead Rising`, `Poison Fists`, and `Reaper Control`.
  - Summons limited Deads during low-health distancing phase.
  - Reaper-controlled units can temporarily attack their own allies.
  - Has poison immunity and poison deathburst behavior.
- `Medusa Boss`
  - Final boss version has stronger health, attacks, summons, and phase pressure.
  - `Look At Me` warns the player when units are turned to stone.

## Boss Abilities

### Wingidon Boss

- `Eclipse Mark`
  - Fires a special marking arrow.
  - Marked units take bonus damage from the next Wingidon/Eclipsor projectile.
  - Nearby Wingidons can be encouraged to focus the marked target.
- `Demon Burst Fire`
  - Fires a short burst of arrows.
  - Hit units are stunned briefly.
- `Sky Commander Aura`
  - Temporarily empowers nearby enemy Wingidons.
  - Boss glows while the aura is active.

### Skelator / Marrowkai Boss

- `Dead Rising`
  - Available below 50% health.
  - Summons Deads beside the boss.
  - Max active summon cap keeps the spell from flooding the map.
- `Poison Fists`
  - Skeletal fists poison units they hit.
  - Poison fist visuals are attached to the fist impact.
- `Reaper Control`
  - Temporarily controls a struck enemy unit.
  - Controlled units cannot be selected by the player.
  - Controlled Magikill can cast spells against its own allies.

## Campaign Changes

- Bosses appear in their own campaign levels.
- Chaos bosses also appear through reinforcements in `Medusa's Gates`.
- Several boss levels reward extra campaign points.
- `Rebels United` is built as a major multi-boss rebel encounter.
- `Medusa's Gates` now includes heavier Chaos Empire pressure.
- The final Medusa battle has improved pacing, music transitions, summons, and boss mechanics.

## Unit Toggles

- `Archidon Auto Kite`
  - Toggle between `Auto Kite` and `Manual Positioning`.
  - Archidons start in `Manual Positioning`.
- `Shadowrath Auto Cloak`
  - Toggle between `Auto Cloak` and `Manual Cloak`.
  - Shadowraths start in `Manual Cloak`.
- `Magikill Autocast`
  - Cycle between `Auto Cast`, `Meteor Only`, and `Disabled Autocast`.
  - Magikill starts with autocast disabled.

## Controls

- `Z` - Scroll camera left
- `C` - Scroll camera right
- `F` - Toggle fast forward
- `P` or `Esc` - Pause
- `Space` - Select all non-miner units
- Double-tap `Space` - Jump camera to your forward unit
- `G` - Garrison or ungarrison selected units
- `U` - Ungarrison full-health units
- `I` - Select all garrisoned units
- `J` - Select poisoned units

## AI Improvements

- Enemy campaign strategy now reacts better to army advantage and disadvantage.
- Hidden Shadowrath forces are counted more intelligently.
- Shadowrath disguise/trap behavior is more coordinated.
- Boss support units stay more relevant around their boss.
- Enemy reinforcements are less likely to be instantly deleted on spawn.
- Expensive AI scans were reduced or cached where possible.

## Bug Fixes and Polish

- Fixed multiple boss health bar issues caused by damage-reduction-only stat changes.
- Fixed debug spawning crashes when spawning units from the wrong empire.
- Fixed Reaper Control cleanup so units return to normal after control ends.
- Fixed Reaper-controlled units hitting flying units when they should not.
- Fixed Magikill friendly-fire spell behavior while Reaper-controlled.
- Fixed Poison Fists behavior so the fist hit applies poison while the effect stays visual.
- Fixed campaign map and intro debug overlays showing on-screen.
- Fixed several lag spikes from repeated debug/stat display updates.
- Fixed campaign map update logic and prewarm behavior.
- Fixed several Shadowrath disguise edge cases.
- Fixed startup intro loading errors by handling failed intro loads safely.

## Performance Notes

This mod includes a lot of new boss logic, but several heavy debug and repeated-update systems were removed or reduced before release:

- Removed large per-frame debug stat overlay updates.
- Removed map coordinate debug display.
- Removed intro frame/debug display.
- Reduced repeated AI target scans through caching.
- Reduced repeated campaign map UI updates.
- Reduced repeated tutorial/enemy command spam.

Normal debug keybind checks are lightweight and only run deeper checks while `Shift` is held.

## Music Notes

Campaign levels use a mix of:

- `battleOfTheShadowElves`
- `enteringTheStronghold`
- `chaosInGame`
- `fieldOfMemories`

The final Medusa level starts with `battleOfTheShadowElves` and later switches to `fieldOfMemories` during the true boss fight.

## Requirements

- Windows is recommended.
- Standalone Flash Player projector is required.
- Included projector: `flashplayer_32_sa.exe`
- Game file: `Stick_War_2_Upgrades.swf`

## Notes for Players

- This is a campaign overhaul, not a full new game.
- Some encounters are intentionally harder than the original campaign.
- Boss fights are designed around pressure, reinforcements, and phase behavior.
- If something feels unusually broken, save your file and report the level, difficulty, and what happened.

## Credits

- Original `Stick War 2` by its original creators.
- Enhanced Edition Mod by ChorlsChu / Charles.
- Modding, scripting, balance changes, boss design, bug fixing, and testing were built on top of the original Flash/AS3 project.

## Disclaimer

This is a fan-made mod project. It is not an official Stick War release.

And yes, commits were absolutely forgotten along the way. The code survived anyway. Somehow.
