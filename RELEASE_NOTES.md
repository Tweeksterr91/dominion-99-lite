# v0.9.0 — Lock & Load

- Empty magazines automatically start reloading as soon as the final shot is fired, when reserve ammunition is available. The active-reload timing bonus still works with RB/X or a touch tap; partial reloads remain available.
- Removed instant 180° turns and the U-turn touch button. Enemy player bots turn at 90°/second, minions at 65°/second, and must face their target before shooting.
- Optional LT hold-to-lock (Y held is an alternate; touch gets a circular hold button). Amber rectangular corner brackets identify a visible enemy/minion. An outer ring hugs the reload ring and charges for 0.7 seconds, turning green when ready. Shooting is blocked while this optional mode acquires; normal shooting still works outside lock mode. Release, obstruction, death or range loss clears the lock. Targeting and charge are validated by the LAN host.
- Corrected local-axis scaling of rotated ramp/guardrail meshes to match collision geometry. Railings are more visible. Added two roofed stone gatehouses per biome, with enclosed rooms, columns, cover and real arched doorways.
- Dark environment rolls only: dark sunset, storm front, overcast dusk or nighttime, with biome-appropriate weather. No sunny daytime rolls.
- New original PBR skin, steel, fabric and walnut texture maps, smoother hand geometry, extra shotgun details and a smaller/lower portrait weapon position. These remain prototype assets, with further art refinement possible.

Install `dominion-99-lite.apk` over the existing installation. Same package and signing identity; versionCode 12. **All LAN players must update to v0.9.0** (protocol 9).

Validation: free-movement physics, all five biome navigation layouts, ramps/jump platforms, collision-based projectiles and damage protection, final-shell automatic reload and active bonus, lock acquisition/gating/target loss/release, slow bot turning/facing, responsive touch/controller switching and portrait/landscape positioning. Two real local Godot processes verify authoritative LAN lock-on between landscape host and portrait guest; the full 4v4 economy/phase test is also retained. Physical OnePlus/Backbone graphics, frame rate, audio and Wi-Fi still need device testing.

Original code, generated models/PBR maps/music/effects: MIT. Adapted Sinbad minions by Zi Ye: CC BY-SA 3.0. ambientCG/Poly Haven: CC0. Rajdhani: SIL OFL. Full notices: ASSET_CREDITS.md.
