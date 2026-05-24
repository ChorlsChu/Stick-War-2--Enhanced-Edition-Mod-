# Stick War 2: Enhanced Edition(Mod)

`Stick War 2: Enhanced Edition(Mod)` is a campaign overhaul built on top of the original game, with expanded boss encounters, new campaign mechanics, AI changes, balance tweaks, bug fixes, and performance work.

This summary compares the mod against:
- `Stick War 2 OG Backup`

## How to Play

1. Open a standalone Flash Player projector.
2. Drag `Stick_War_2_Upgrades.swf` into the Flash Player window.
3. Wait for the game to load, then start playing.

## Requirements

- A standalone Flash Player projector is required.
- Modern web browsers will not run the game.

## Overview

This mod focuses on:
- expanding the campaign with faction bosses and reinforcements
- adding more distinctive level mechanics, especially for Shadowrath and Medusa encounters
- improving campaign pacing and spectacle
- fixing long-standing bugs and reducing avoidable lag spikes

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
  - normal cloak path removed
  - boss uses special cloak path only
  - chain-cloak behavior retained
  - retreat behavior simplified:
    - no Meric-heal retreat
    - no emergency statue-defense comeback
    - retreat, garrison, and stay gone
- `Magikill Boss`
  - starts with autocast disabled by default
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
- `Medusa final fight`
  - summon controller reworked toward event-driven bookkeeping
  - summon tracking and active-count handling improved

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
  - removed campaign-only forced `Bone Bag` override every update
  - Chaos miner loadout now respects armory choice
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
