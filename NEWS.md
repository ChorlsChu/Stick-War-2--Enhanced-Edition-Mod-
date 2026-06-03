# Changelog

## v1.0.1 - Bug fixes

### Fixed
- Fixed Spearton Boss teleporting instantly during Lost Phase.
- Fixed Spearton Boss helmet floating during certain animations.
- Fixed mouse-edge camera panning causing occasional lag spikes.(Needs more testing but pls inform me if you experienced a crash over this)
- Improved world-layer mouse handling to reduce Flash display-tree overhead during camera movement.

## v1.0.0 - Initial Enhanced Edition Release

### Added
- Added Order faction boss encounters.
- Added Chaos faction boss encounters.
- Added Chaos boss reinforcements in Medusa's Gates.
- Added embedded intro video.
- Added replayable completed levels after finishing the campaign.
- Added upgrade screen access from the campaign map.
- Added player toggles for Archidon, Shadowrath, and Magikill behavior.

### Changed
- Reworked several campaign encounters with stronger boss mechanics.
- Improved campaign enemy AI strategy decisions.
- Reworked Medusa final boss pacing and summons.
- Adjusted campaign point rewards for boss levels.

### Fixed
- Fixed several boss health bar issues.
- Fixed Reaper Control cleanup and friendly-fire behavior.
- Fixed Poison Fists poisoning behavior.
- Fixed intro/map debug overlays showing on-screen.
- Fixed multiple crash cases from debug spawning.

### Performance
- Removed heavy per-frame debug stat display.
- Reduced repeated AI scans and campaign map updates.