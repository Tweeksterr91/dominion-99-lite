# v0.4.0 — Souls & Ash / LAN foundation

Portrait auto-runner combat now has a complete five-round match loop and local Wi-Fi/direct-IP multiplayer.

- Five lives per player, restored each round; 2:45 collection → up to 1:00 shop → shared roll → 2:45 hunting.
- PvE minions drop blue essence over their bodies. Pull it with an extending hand, steal it, or shoot it to deny souls.
- Three weapon profiles and health/shield/damage/reload upgrades; one subtle shared RNG benefit per player per round.
- Clear portrait HUD: amber arrows, jumping-person icon below ahead, corner lives/souls/frags, health/shield and ammo, active reload ring. Empty magazines wait for a tap to start reloading.
- Live title demo, main menu, five-map bot campaign, saved options, multiplayer formats 1v1 through 4v4.
- Actual ENet phone-hosted LAN rooms on UDP 27799, ready checks, bot filling, host authority, local movement prediction, compressed snapshot fragments, and disconnected guest bot takeover.

Install over the previous APK. Same application ID and signing certificate; versionCode 7. Connect phones to the same Wi-Fi or hotspot, host a room, enter its displayed IP on the other phone, ready up, then start.

Validated: match rules/economy, portrait HUD, multi-touch, actual PvE aiming/fire and drops, tap/active reload, essence stealing/denial/credit, shop/reveal/respawn/pause, real-collision jumps/drop/turns, and two-process 4v4 LAN through shopping and hunting. Physical Android multiplayer and OnePlus 12R frame rate still need device testing. Fixed 60 FPS cap; no frame-rate toggle.

This is a development prototype. Campaign is a sequence of bot arena matches; weapon profiles share the current modeled sidearm. No Internet matchmaking or live-match rejoin. Keep the host game open.

Original code/art MIT; adapted Sinbad creature by Zi Ye CC BY-SA 3.0; ambientCG/Poly Haven CC0; Rajdhani SIL OFL. Full notices: ASSET_CREDITS.md. Gameplay screenshots/video containing Sinbad are CC BY-SA 3.0.
