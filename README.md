# Dominion '99 (Lite)

A dark sci-fi portrait auto-runner FPS for Android: aim, choose routes, harvest essence, and hunt rivals.

**[Download APK — v0.4.0](https://github.com/Tweeksterr91/dominion-99-lite/releases/download/v0.4.0/dominion-99-lite.apk)** · **[Releases](https://github.com/Tweeksterr91/dominion-99-lite/releases)**

Development prototype for the OnePlus 12R, built with Godot 4.6.3. Fixed **60 FPS cap**, portrait orientation. Actual phone performance and Wi-Fi behavior still need device testing.

![Portrait gameplay HUD](docs/preview.png)

## Install and update

Open the latest release while signed into the GitHub account with access to this private repository. Download `dominion-99-lite.apk`, open it from Downloads, and choose Install or Update. Allow installation from the app opening the APK if Android asks. The package and development signing key are preserved between versions; Godot is not needed to play. Keep the existing installation to retain settings and campaign unlocks.

## Match flow

A match has **five rounds**. Everyone starts **each round with five lives**.

1. **Collection — 2:45.** Players cannot damage each other. Kill smaller PvE minions; each drops three hovering blue essence clusters above its corpse. Tap the blue essence icon on the left to extend a hand and draw nearby visible essence into it. Souls are credited on arrival. A closer collector can steal a cluster already being pulled. Hold the crosshair on essence for 0.55 seconds to shoot and deny it; nobody receives those souls. Pulling suppresses your own denial shots.
2. **Shop — up to 1:00.** Spend souls on three weapon profiles, damage/health/shield/reload upgrades, health restoration, or reserve ammo. Ready up when done; the shop closes early if everyone is ready. Movement and combat stop during shopping.
3. **Shared roll — 6 seconds.** Every player receives one small random passive benefit. Everyone sees all rolls before hunting begins. Benefits include +2% damage, +5 shield, 3% faster reload, +1 m pull reach, or slightly earlier shield recovery. Gifts stack across rounds.
4. **Hunting — 2:45.** Fight the opposing team; friendly fire is disabled. Death consumes one life and respawns after three seconds while lives remain. An eliminated player spectates until the next round. Eliminating a team ends hunting early.

Round standings prioritize remaining team lives, then frags, then collected essence. The team with more round wins wins the match; equal round wins are a draw. Souls, owned weapons, upgrades, gifts, and match frags persist between rounds. Health, shield, lives, and starting ammunition reset for the next round.

## Controls and HUD

- The character runs automatically. Drag the open play area to aim; a visible enemy under the crosshair is shot automatically. There is no running, strafing, or fire button.
- Amber left/ahead/right arrows queue the next junction decision. The jumping-person icon sits below the ahead arrow. Tap once to jump, twice for a double jump; DOWN queues an available descending route. Route hints identify elevated paths. Missing a landing returns the runner to that hallway's start and costs 25 shield/health.
- **An empty magazine waits for a tap anywhere to start reloading.** The crosshair ring shows reload progress. A second tap in the amber segment completes it early. An early/late tap uses the bonus attempt but allows normal completion. Dragging an existing aim touch does not count as a new tap. There is no separate reload button.
- Lives sit at the upper left; souls and frags at the upper right. The phase timer sits at the top center. Health and regenerating shield hug the bottom left; ammo and reserve hug the bottom right. No dark HUD panels.
- Green pickups restore health; amber pickups supply ammunition. Shield recovers at 20/second after four seconds without damage, modified by gifts.
- Pause freezes offline matches. **LAN matches continue behind the pause menu.** Keep the host app in the foreground.

Desktop testing: mouse aim, A/D/W/S (or arrows) for routes, Space to jump/double jump, E to pull essence, R or mouse tap to reload, Esc to pause.

## Menus and campaign

The title screen runs a real AI-controlled gameplay demonstration behind the logo. Tap to enter the main menu: **Single Player Campaign**, **Multiplayer**, **Options**, **Quit Game**, and art credits.

The initial campaign is a sequence of bot matches across five biome maps, unlocked by winning: Verdant Ruins, Blue Catacombs, Ember Vault, Rootbound Forest, and Dune Coast. It is a match-based campaign foundation, without story cinematics. Options persist aim sensitivity, invert aim, sound volume, and camera motion. Weapon profiles currently share the modeled sidearm with size adjustments.

## Local Wi-Fi / direct-IP multiplayer

**1v1, 2v2, 3v3, and 4v4** use a phone as the authoritative ENet host. Empty slots are filled with bots. At least two human phones are required to launch a LAN match; Practice With Bots works offline in every format.

1. Install the same game version on all phones and connect to the same Wi-Fi or phone hotspot.
2. Host: Multiplayer → team format → Host Room. The lobby displays the host's local IP address and UDP port **27799**.
3. Guests: Multiplayer → Join Room. Enter the host's numeric Wi-Fi IP address, connect, and tap Ready.
4. Host taps Start Match after guests are ready. The next human joins the opposing team first.

Wi-Fi networks with client isolation can block phone-to-phone traffic; try a private router or hotspot. This version has no Internet matchmaking, cloud server, account login, or NAT traversal. A disconnected guest is replaced by a bot; if the host leaves, guests return to the menu. Rejoining an ongoing match is not supported yet.

The host validates movement/actions, hits, damage, purchases, essence ownership, and rolls. Clients predict local movement and receive compressed, bounded UDP snapshot fragments. Two real local game processes have been tested through collection, shopping, shared rolls, hunting, purchases, and disconnect takeover. Testing on two physical Android phones remains necessary.

## Source and assets

Import `project.godot` in the official Godot Editor for Android to edit on your phone. The world is built at runtime. The Compatibility renderer uses scanned 1K materials, mipmaps, 2x anti-aliasing, and one short-range directional shadow map. This is an evolving art foundation, with an animated imported creature and original modeled weapon/essence hand.

- `scripts/souls_arena.gd`: active game, menus, combat, AI, local prediction and host simulation.
- `scripts/match_rules.gd`: five-round rules, economy, team protection, rolls.
- `scripts/lan_session.gd`: LAN rooms, readiness, validated actions and snapshot transport.
- `scripts/rail_motion.gd`: shared host/client autorun and real jump physics.
- `scripts/arena_hud.gd`, `match_reticle.gd`, `ui_glyph.gd`: portrait UI and original vector icons.
- `scripts/essence_cloud.gd`: shared essence, stealing, denial, batched particles.
- `scripts/corridor_map.gd`, `visual_assets.gd`: five connected layouts, art and animation helpers.
- `scripts/runner.gd`, `main.gd`: earlier prototype and reusable foundation.
- `art_sources/`: editable Blender generation and conversion scripts.

See [asset credits and licenses](ASSET_CREDITS.md). Original code, generated scenery, sidearm, hand, and icons use MIT. The adapted Sinbad creature and its textures use CC BY-SA 3.0; scans and lighting panorama are CC0. Rajdhani uses SIL OFL. Screenshots/video containing Sinbad are CC BY-SA 3.0 with attribution in ASSET_CREDITS.md.

## Validation and releases

```sh
godot --headless --path . --script tests/match_rules_test.gd
godot --headless --path . --script tests/souls_game_test.gd
godot --headless --path . --script tests/ui_navigation.gd --quit-after 120
godot --headless --path . --script tests/rail_traversal.gd
```

For the two-process LAN integration test, start `tests/lan_game_peer.gd -- host`, then `tests/lan_game_peer.gd -- client` in separate Godot processes on the same machine (UDP 27809). Both must report PASS. The test advances timers to exercise all phases quickly. Legacy tests remain for the shared arena and older runner.

Every update gets a numbered GitHub Release with a new APK. Increase `version/code` and `version/name`, keep the original signing key outside the repository, and verify the APK before upload. Current builds use development signing; store distribution requires release signing.
