# v0.6.0 — Rotate & Play

- One APK supports automatic portrait and landscape rotation, including either landscape direction. Rotation preserves the current match, inventory, lives, and round timer. Options also offers Auto/Portrait/Landscape preference, so you can force landscape for a Backbone even when system auto-rotation is off.
- Dedicated landscape HUD, menus, shop, shared-roll reveal, options and campaign layouts. Health/shield and ammo remain at the screen edges; aim stays centered. Camera projection adjusts to the aspect ratio; Android cutout margins protect the edge UI.
- Standard Android USB-C/Bluetooth gamepad support, including the Backbone Android control scheme, through Godot's native controller mapping. Hot-plug support and automatic touch/controller HUD switching.
- Right stick aims; left stick/D-pad chooses routes. A/RB jump, B/LT reverse, X/RT reload/active timing, Y/LB harvest, Start pauses, View opens the guide. Face-button labels adapt to recognized PlayStation/Nintendo names; firing stays automatic.
- Controller-only menu navigation and shop use. LAN IP entry uses the phone's keyboard.
- Controller Settings: independent aim sensitivity, radial deadzone, curved fine-aim response, stick swapping, saved primary button remapping, and reset. Holding a trigger does not retrigger active reload.
- Controller disconnect pauses offline play and restores touch input. LAN matches continue with touch fallback.

Install `dominion-99-lite.apk` as an update. Same application ID and signing certificate; versionCode 9. Existing settings/campaign progress are retained. The original five-round rules, treasure minions, gold souls, team outlines, audio, and fixed 60 FPS cap remain.

Validated with standard synthetic gamepad events: controller-only launch/navigation, analog aim and route choices, face/shoulder/trigger actions, active reload timing, remapping/persistence, stick swap, deadzone, hot-plug fallback, shop/guide navigation, phone/tablet landscape and portrait bounds, centered reticle and state-preserving rotation. Existing combat, rules/economy, animations, gold souls and real-collision traversal tests pass. Two-process 4v4 LAN passes with a landscape host, portrait guest, and controller-originated turn-around action.

A physical Backbone and other Android controllers are not attached to the build environment: hardware mappings, device audio/performance and rotation still need phone testing. This build uses the standard Android gamepad path and user-adjustable bindings, without a Backbone-specific SDK dependency.

Original project code/art/audio: MIT; adapted Sinbad minions by Zi Ye: CC BY-SA 3.0; ambientCG/Poly Haven: CC0; Rajdhani: SIL OFL. Full notices: ASSET_CREDITS.md. Screenshots/video containing Sinbad are CC BY-SA 3.0.
