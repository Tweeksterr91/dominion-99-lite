# v0.8.0 — Off the Rails

- Free forward/backward movement and strafing on the left stick or new touch joystick. Full 360° aiming; release movement to stop. Players, bots and minions move with actual world collision. Auto-fire remains enabled; RT still fires manually, RB reloads/attempts active reload, B harvests, A/LB jumps, Y/LT turns 180°.
- Visible traveling projectiles for players, bots and minions. The new starting weapon is a five-shell single-barrel pump shotgun with seven pellets per shot, animated pump, more humanlike first-person arms, and original firing/pump/shell-loading sounds. Classic weapon-lowering reload remains.
- Five rebuilt biome arenas: circular central rotunda, elevated ring, side rotundas, upper balconies, ramps on normal routes and optional genuine jump islands. Low railings are collidable and jumpable. Falling off costs a life.
- Shared time-of-day and weather RNG reveal before each match. Seeded conditions are identical for all LAN players; the reveal does not consume collection time. Lighting, sky and weather particles change with the roll.
- New original 134–146 BPM arena-techno music, a louder mix, and 70% default effects/music. Existing custom settings are retained; old untouched defaults migrate. Brown-noise ambience keeps its separate control.
- Portrait, landscape, controller support, five-round economy, soul stealing/denial and gold-soul protection remain supported.

Install `dominion-99-lite.apk` over the existing game. Same package and development signing identity; versionCode 11. **All LAN players must update to v0.8.0** (protocol 8).

Validated with Godot physics/navigation across all five maps, free move/stop/strafe, ramps, jumpable rails and falling, delayed pellet collisions and damage protections, viewmodel/audio, responsive touch HUD, rules and menu checks. Two actual local game processes exercise 4v4 LAN with landscape host, portrait guest, free controller movement, manual shots, visible projectiles, synchronized weather/time, purchases, shared rolls, hunting and bot takeover. Physical OnePlus/Backbone performance, audio balance and two-phone Wi-Fi behavior still need hardware testing. This remains a development prototype, not finished photorealistic art.

Original code/models/shotgun sounds/music: MIT; adapted Sinbad minions by Zi Ye: CC BY-SA 3.0; ambientCG/Poly Haven: CC0; Rajdhani: SIL OFL. Full notices: ASSET_CREDITS.md.
