# Stick War 2: Enhanced Edition(Mod)

`Stick War 2: Enhanced Edition(Mod)` is a campaign overhaul built on top of the original game, with expanded boss encounters, new campaign mechanics, AI changes, balance tweaks, bug fixes, and performance work.

## How to Play

1. Open a standalone Flash Player projector.
2. Drag `Stick_War_2_Upgrades.swf` into the Flash Player window.
3. Wait for the game to load, then start playing.

## Keybinds

- `Z`: Scroll camera left
- `C`: Scroll camera right
- `F`: Toggle fast forward
- `P` or `Esc`: Pause
- `Space`: Select all non-miner units
- Double-tap `Space`: Jump camera to your forward unit
- `G`: Garrison/Ungarrison selected units
- `U`: Ungarrison units that are full-health
- `I`: Select all garrisoned units
- `J`: Select poisoned units

## Overview

This mod focuses on:
- expanding the campaign with faction bosses and reinforcements
- adding more distinctive level mechanics, especially for Shadowrath and Medusa encounters
- improving campaign pacing and spectacle
- fixing long-standing bugs and reducing avoidable lag spikes

## Unit Toggles

- `Archidon Auto Kite`
  - Select an `Archidon` and use its action toggle button to switch between:
  - `Auto Kite`: retreats while reloading if enemies get too close
  - `Manual Positioning`: holds its ground unless you move it
  - `Archidon` starts with `Manual Positioning` by default
- `Shadowrath Auto Cloak`
  - Select a `Shadowrath` and use its action toggle button to switch between:
  - `Auto Cloak`: automatically cloaks when enemies enter engage range
  - `Manual Cloak`: only cloaks when commanded manually
  - `Shadowrath` starts with `Manual Cloak` by default
- `Magikill Autocast`
  - Select a `Magikill` and use its action toggle button to cycle between:
  - `Auto Cast`: autocasts all valid spells
  - `Meteor Only`: only autocasts Meteor(For saving mana)
  - `Disabled Autocast`: does not autocast spells
  - `Magikill` starts with `Disabled Autocast` by default

## Requirements

- A standalone Flash Player projector is required.
- Modern web browsers will not run the game.

## Features Added

- Added a `Westwind/Rebel boss` style campaign boss system for major campaign encounters.
- Added `faction boss promotion` for campaign levels:
  - `Spearton Boss`
  - `Archidon Boss`
  - `Shadowrath Boss`
  - `Magikill Boss`
  - `Monk Boss`
- Added a `Shadowrath disguise system` on `Silent Assassins: Ninjas Declare War`:
  - enemy Shadowraths can disguise as fake miners
  - fake miners can use mining and prayer slots
  - disguised Shadowraths count as hidden military for AI decisions
- Added `Shadowrath trap AI`:
  - hidden-force counting
  - bait/lure behavior
  - partial reveal
  - full reveal escalation
  - strategy pause/interrupt when the player gains advantage
- Added a `custom Magikill autocast system`:
  - multiple autocast modes
  - weighted spell selection
  - smarter spell-pick behavior than the OG enemy casting flow
- Added `Shadowrath debug tools` during development:
  - full vision
  - enemy Shadowrath spawn
  - force disguise
  - allied Spearton + Archidon spawn
  - these debug keybinds were later removed from the public gameplay path
- Expanded `campaign reinforcements`:
  - no longer Insane-only
  - bosses always appear on relevant boss levels
  - escort and reinforcement composition scales by difficulty
- Added `reinforcement statue protection`:
  - temporary damage immunity when reinforcements trigger
  - duration scales by difficulty
- Expanded `Magikill Boss summon system`:
  - summon pool includes:
    - `Spearton`
    - `Swordwrath`
    - `Archidon`
  - per-type caps:
    - `3 Speartons`
    - `2 Swordwraths`
    - `2 Archidons`
- Added custom `Medusa boss cosmetics`:
  - `Snake Cape`
  - `Jewel Crown`
- Added `level-specific gameplay prewarm` for rare unit classes.
- Added `campaign map prewarm` for map frames and the banner/flag turning animation.

## Boss and Gameplay Changes

- `Shadowrath Boss`
  - boss uses special cloak behavior instead of the normal Shadowrath cloak path
  - retreat behavior simplified:
    - no Meric-heal retreat
    - retreat, garrison, and stay gone
- `Magikill Boss`
  - uses a simpler boss-only generic enemy casting path
  - boss summon remains separate from standard player autocast logic
  - boss stun remains the stun/lightning wall spell, not a separate generic lightning ability
- `Shadowrath level`
  - enemy Swordwrath cap increased to `6`
  - disguise defense radius widened
  - spawn and return-to-defend disguise lock added
  - disguised miners reveal on damage instead of the older passive proximity model
- `Fake miner slot logic`
  - disguised Shadowraths try alternate slot reassignment before revealing back
- `Medusa Gates Level`
  - Chaos Empire can now use Medusa Units
- `Medusa final fight`
  - She now summons more minions based on difficulty
  - She has more health
  - Faster melee attacks
- `Enemy Order Levels`
  - They now reward you 2 upgrade points instead of one for fighting bosses on each level
  - Rebels United(Westwind) level rewards you 3 upgrade points for fighting all bosses together

## Boss Special Abilities

- `Spearton Boss`
  - uses `Shield Wall` and `Shield Bash`
  - commands nearby `Speartons` to brace with him
- `Archidon Boss`
  - uses `Fire Arrows`
  - commands nearby `Archers` to use `Fire Arrows`
  - retreats to base and regroups if too few allied archers remain nearby
  - instantly spawns `4` more archers during regroup
  - has stronger/faster kiting behavior than normal `Archidons`
- `Shadowrath Boss`
  - uses a longer-lasting special cloak
  - can immediately chain into cloak again after a successful cloaked hit
  - prioritizes support targets and flanks them
  - can lead nearby `Shadowraths` into coordinated flanks
  - suffers a longer recovery if the special cloak attempt ends poorly
- `Magikill Boss`
  - lightning spell deals low damage but stuns enemies for a longer time
  - can summon `Swordwraths`, `Speartons`, and `Archidons`
  - summoned bodyguards stay close and return to protect the boss
- `Meric Boss`
  - can revive fallen allies
  - revival priority favors stronger units first, especially `Speartons`, then `Shadowraths`, then `Magikills`

## Fixes

- Fixed `Shadowrath disguise` edge cases:
  - no more instant reveal just because a fake slot changed
  - no more instant disguise right on spawn after dedicated lock was added
  - travel-to-slot no longer causes premature reveal
- Fixed `campaign map banner/floor effect` after map prewarm:
  - restored the spinning base effect under the banner
- Fixed `Statue.damage()` crash caused by using an undefined `game` variable.
- Fixed startup `IOErrorEvent` / `Load Never Completed` intro loader errors by handling failed external intro loads safely.
- Fixed `MinerChaos` loadout bug:
  - removed campaign-only forced `Bone Bag` override every update which causes FPS drops
- Fixed `tutorial lag spike` caused by repeatedly issuing `enemyTeam.attack(true)` every update after the tutorial phase.
- Fixed `Magikill autocast default` consistency so both normal and boss Magikill can start disabled.

## Performance Optimizations

- Optimized `campaign map screen`:
  - cached title/story text updates
  - cached map frame updates
  - cached autosave visibility updates
  - removed repeated per-frame flag mouse setup
  - prewarmed nearby map frames and turning banner animation
- Added `campaign gameplay prewarm`:
  - immediate prewarm for starting rare units
  - delayed queue for later unit classes
- Optimized `EnemyTeamAi`:
  - changed major strategy refresh from constant re-pick to army-change/aggression dirtying
- Optimized `Team`:
  - added army-change version tracking for event-style AI refresh
- Optimized `UnitAi`:
  - added same-frame cache for `getClosestSpellableTarget()`
  - `getClosestTarget()` cache also used similarly
- Optimized `NinjaAi`:
  - reduced expensive boss helper scans
  - simplified Shadowrath squad follow/flank behavior
  - removed Meric-retreat scan
  - removed emergency statue-defense comeback logic
- Optimized `ArcherAi`:
  - reduced repeated same-frame target fetch in boss rear-line logic
- Optimized `MagikillAi`:
  - added same-frame caches for spell target selection
  - split boss casting away from player-style autocast logic
- Optimized `MonkAi` and `SpeartonAi` with low-risk cleanup and reduced repeated work.
- Optimized `CampaignCutScene2`:
  - Medusa summon tracking moved toward cached/event-driven flow
  - cleanup reduced to safety-pass role instead of main bookkeeping path

## AI and Strategy Differences From OG

- Campaign enemy AI is more customized than the original game:
  - faction bosses
  - hidden Shadowrath military accounting
  - Shadowrath trap, lure, and full-push progression
  - reinforcement statue shield
  - boss-specific research grants
- Boss-required research is granted automatically in campaign setup for relevant boss levels:
  - `BLOCK`
  - `SHIELD_BASH`
  - `ARCHIDON_FIRE`
  - `CLOAK`
  - `CLOAK_II`
  - `MAGIKILL_WALL`
  - `MAGIKILL_POISON`
  - `MONK_CURE`

## Major Files Changed

- `scripts/com/brockw/stickwar/campaign/CampaignGameScreen.as`
- `scripts/com/brockw/stickwar/campaign/CampaignScreen.as`
- `scripts/com/brockw/stickwar/campaign/controllers/CampaignTutorial.as`
- `scripts/com/brockw/stickwar/campaign/controllers/CampaignCutScene2.as`
- `scripts/com/brockw/stickwar/singleplayer/EnemyTeamAi.as`
- `scripts/com/brockw/stickwar/singleplayer/EnemyGoodTeamAi.as`
- `scripts/com/brockw/stickwar/singleplayer/EnemyChaosTeamAi.as`
- `scripts/com/brockw/stickwar/engine/Ai/UnitAi.as`
- `scripts/com/brockw/stickwar/engine/Ai/NinjaAi.as`
- `scripts/com/brockw/stickwar/engine/Ai/MagikillAi.as`
- `scripts/com/brockw/stickwar/engine/units/Magikill.as`
- `scripts/com/brockw/stickwar/engine/units/MinerChaos.as`
- `scripts/com/brockw/stickwar/engine/units/Statue.as`


Note: Yes I only have few commits and yes I keep forgotting to commmit them :P
