# v0.5.0 — Sentinels & Gold

- Full circles around the jump and harvest buttons; a new spectral-flame soul icon.
- Godot splash image disabled. Android's native startup may briefly show the game's app icon.
- New original armored Sentinel player model with its own skeleton and running, idle, and jump clips. Players are larger than minions; blue/red armor accents and wall-respecting blue/red outlines identify teams.
- Circular 180° U-turn button directly below jump; reverses movement without teleporting. Desktop shortcut: Q. Works over LAN with local prediction and host validation.
- Default aim sensitivity increased to 180%. Options offer 50–300% adjustment in 10% steps, reset, and saved preferences. Earlier low/normal/high choices migrate to faster equivalents.
- Five original ambient industrial/techno music loops, one per biome, plus a quiet brown-noise layer. Separate saved effects/music/ambience volumes and mute; offline pause suspends audio.
- Scavenger, fast/light Stalker, and slow/heavy Brute minions have different health, movement and attacks.
- Rare Gilded Revenant treasure minion appears once per collection phase at a random time, flees players, and drops 90 gold souls—six times an ordinary minion. Gold can be harvested or stolen by either team, cannot be destroyed, does not waste denial ammunition, and remains until collection ends.

The five-round collection/shop/shared-roll/hunting flow remains. LAN protocol updated: **all participating phones must install v0.5.0**. Same application ID and signing certificate; versionCode 8. Install as an update over the previous APK.

Validated: portrait control layout, actual touch navigation, precise 180° reversal and continued collision movement, saved sensitivity, animated Sentinel joints and team outline materials, minion stats/speed, scheduled treasure spawn, gold denial immunity and collection by both teams, looping audio/mute, existing combat/reload/essence/shop/respawn rules, real collision jumps/drop, and two-process 4v4 LAN with reversals, minion variants and gold snapshots. Physical Android multiplayer, audio mix and OnePlus 12R frame rate still need phone testing. Portrait, fixed 60 FPS cap.

Original Sentinel, rig/animations, audio, controls and code: MIT. Adapted Sinbad minions by Zi Ye: CC BY-SA 3.0. ambientCG/Poly Haven: CC0. Rajdhani: SIL OFL. Full notices in ASSET_CREDITS.md. Screenshots/video containing Sinbad are CC BY-SA 3.0.
