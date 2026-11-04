# v0.11.0 — Plasma Armory

- Removed the shadow gradient from title and main menu screens; the gameplay demonstration remains visible.
- Three rounds per match. Collection/hunting are each 82.5 seconds, shopping is up to 30 seconds, and the shared perk reveal is 3 seconds. The opening weather reveal remains 6 seconds. Treasure spawn timing is scaled to the shorter collection phase.
- Hold LB for the weapon wheel, select with the aim stick/D-pad, and release to equip. B cancels. Touch gets a hold-and-drag wheel button; desktop uses Tab plus mouse. A jumps; LB is now the wheel. The match stays live while selecting, with movement/aim/fire suppressed.
- Every player starts with the pump shotgun and a blue/red team-colored plasma scythe. Pump ammunition has unlimited reserve while magazine reloads and active reload remain. The scythe has unlimited use, a short forward melee arc, original swing sound/animation, and respects walls and team damage rules.
- Acquire all six weapons together. Each keeps separate magazine/reserve counts across combat swaps, with no free refill from switching or cancelled reloads. Ownership persists across rounds, and ammunition resets each round.
- New sawed-off double-barrel shotgun upgrade for 140 souls: two shells, wider ten-pellet blasts, unlimited reserve and its own model. The original pump remains selectable. The scythe also appears on other players/bots with the correct team color.
- LT holds one target until release, even if another enemy crosses the aim. Losing visibility/range or losing the target resets charge without switching to a different enemy; release/re-press to acquire another.
- Rival bot turning reduced to 65°/s and minion turning to 50°/s. Bot firing cooldowns are 30% longer; minion attack cooldowns are 25% longer. Previously reduced movement speeds remain.

Install `dominion-99-lite.apk` over the existing game. Same package/signing identity, versionCode 16. **All LAN players must update to v0.11.0** (protocol 11).

Validation: three-round timing and reset rules; no start-menu gradient; inventory/purchases; infinite shotgun and melee use; per-weapon ammo and cancelled reloads; controller/touch wheel selection and remapping; melee range, team protection and wall occlusion; double-barrel pellets; sticky lock; slower bot cadence; portrait/landscape framing and existing collection/navigation/UI checks. Two actual local game processes verify wheel selection, all-weapon ownership, finite ammo across swaps and team-colored scythes, alongside the full 4v4 match/economy, lock and killer-reward tests. Physical Android/Backbone feel, visuals and performance still need device testing.

Original armory models, wheel UI and synthesized scythe audio: MIT. Full component notices: ASSET_CREDITS.md.
