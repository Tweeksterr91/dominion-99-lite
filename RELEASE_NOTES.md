# v0.10.0 — Touch Fire & Killer Souls

- Auto-fire is available only while holding a touchscreen aiming touch. Controller/mouse aim requires manual shooting (RT / left mouse button). A charged LT lock still requires RT on a controller. Aim-touch release, input switching, pause/backgrounding and missing network heartbeats cancel auto-fire. Movement and HUD touches do not enable it.
- Shooting effects play at half their previous amplitude, including the pump cycle and distant player/bot/minion shots. Reload effects, music, ambience and saved volume settings stay independent.
- Removed the soul-harvesting hand, touchscreen button, controller B harvest binding and keyboard E action. Weapon hands remain.
- Minion orbs automatically fly to the fighter who lands the killing shot. Claimed blue/gold orbs cannot be stolen or destroyed; they credit the killer on arrival. The reward stays with that fighter even if they die. Pending rewards settle before the shop, and particles/ownership/currency replicate from the host. Gold treasure kills still award 90 souls. The obsolete pull-range gift now grants +1 m lock range as TARGET REACH.
- Rival bot ground movement reduced from 5.0 to 3.2 m/s; minions move 15% slower. Player speed stays unchanged. Bots retain brief jump assistance to cross optional platforms.

Install `dominion-99-lite.apk` over the existing installation. Same package and signing certificate; versionCode 15. **All LAN players must update to v0.10.0** (protocol 10).

Validated: real touch/controller input transitions, manual RT, auto-fire release/timeout, measured shooting gains, removed harvesting presentation, killing-shot ownership, automatic blue/gold collection, theft/denial protection, dead-killer and phase-end reward settlement, slower physical bot movement, portrait/landscape weapon framing, reloads, navigation, rules and UI. Two real local game processes verify touch/manual shooting and killer rewards between portrait guest and landscape host, alongside full 4v4 phase/economy and optional-lock integration checks. Physical Android/Backbone feel, audio balance and performance still need device testing.

Original code/audio/art: MIT; full component attribution and licenses are in ASSET_CREDITS.md.
