# v0.7.0 — Trigger & Reload

- **RT: manual fire**, while crosshair auto-fire remains enabled. Hold RT to shoot at the current aim, including misses. Manual and automatic firing share the same cooldown and magazine, preventing double-speed shots.
- **RB: reload / active reload**. X remains an alternate reload input. Explicit controller/keyboard reloads also support partly used magazines without discarding remaining rounds. Touch taps continue to start reload only when empty.
- **B: harvest souls**. **Y/LT: 180° turn**, **A/LB: jump/double jump**, Start pauses. Prompts and controller guide reflect the new layout. Existing default profiles migrate automatically; unrelated custom bindings are preserved where possible.
- Classic weapon-lowering reload presentation: gun dips fully below the screen, original mechanical reload foley plays, then the gun rises back. Drop distance adapts to portrait and landscape projection. Active reload produces a quicker raise with a brief ready delay.
- Original lowering/raising sounds follow effects volume and offline pause. No GoldenEye assets or sounds are used.
- Manual shots can immediately deny blue essence; indestructible gold remains protected. Collection/hunting damage restrictions remain enforced by the host.
- LAN manual-fire state uses heartbeat, release, pause cleanup and timeout protection against stuck firing.

Install `dominion-99-lite.apk` over the existing installation. Same application ID and signing certificate; versionCode 10. **All LAN participants must update to v0.7.0** (protocol 7).

Validated: binding migration, held RT cadence/release/timeout, automatic-fire coexistence, actual raycast target damage, blue denial and gold immunity, RB tactical/active reload, ammunition conservation, down/hold/up motion, reload audio, B harvest/Y reverse; existing controller navigation, portrait/landscape rotation, physics traversal, economy and match tests. Two-process 4v4 LAN passes with a landscape host, portrait guest, and controller-originated manual shots. Physical Backbone, phone audio mix and frame rate still need hardware testing.

Original project content and reload foley: MIT; adapted Sinbad minions by Zi Ye: CC BY-SA 3.0; ambientCG/Poly Haven: CC0; Rajdhani: SIL OFL. Full notices: ASSET_CREDITS.md.
