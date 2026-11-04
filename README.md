# Dominion '99 (Lite)

A dark sci-fi arena FPS for Android with free movement, portrait/landscape play, controller support, soul harvesting, and team deathmatches.

**[Download APK — v0.8.0](https://github.com/Tweeksterr91/dominion-99-lite/releases/download/v0.8.0/dominion-99-lite.apk)** · **[Releases](https://github.com/Tweeksterr91/dominion-99-lite/releases)**

Development prototype for the OnePlus 12R, built with Godot 4.6.3. Fixed **60 FPS cap**, automatic portrait/landscape rotation. Actual phone performance and Wi-Fi behavior still need device testing.

![Landscape controller HUD](docs/landscape.png)

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

- Rotate the phone at any point. The game reflows between portrait and landscape without restarting the match. Both landscape directions are supported, with screen-edge safe-area margins and an orientation-aware field of view. In Options, SCREEN cycles Auto → Portrait → Landscape. Auto follows the phone's rotation setting; the Portrait/Landscape choices lock that view and still allow either direction.
- **Free movement:** the left touch joystick or controller left stick moves forward/backward and strafes. Release it to stop. Drag the open play area or use the right stick to look freely through 360°. Auto-fire remains enabled over valid targets; controller RT adds manual fire.
- Jump/double-jump with the circular jumping-person button. The circular U-turn button below it turns 180°. Harvest sits beside jump. Old junction arrows are removed. Players, rival bots and minions use real movement and collisions; bots navigate the same ramps and optional jump links.
- Each biome has a central rotunda, raised ring, side chambers, upper balconies and optional jump islands. Ramps connect the normal routes. Low railings stop ordinary walking but can be jumped over. Falling into the void consumes a life and respawns the player.
- Before the match, a six-second shared RNG reveal picks time of day and biome-appropriate weather. Dawn/day/dusk/night affect sky, lighting and visibility; rain, snow, fog, ash or dust appear where appropriate. The full collection timer starts after the reveal and navigation preparation.
- **An empty magazine waits for a tap anywhere to start reloading.** The crosshair ring shows reload progress. A second tap in the amber segment completes it early. An early/late tap uses the bonus attempt but allows normal completion. Dragging an existing aim touch does not count as a new tap. Touch play has no separate reload button. RB/X on a controller or R on a keyboard explicitly reloads a partly used magazine too, preserving unspent rounds. The weapon drops below the screen during reloading with original mechanical foley, then rises back into view. An active reload brings it up quickly with a short ready delay.
- Lives sit at the upper left; souls and frags at the upper right. The phase timer sits at the top center. Health and regenerating shield hug the bottom left; ammo and reserve hug the bottom right. No dark HUD panels.
- Green pickups restore health; amber pickups supply ammunition. Shield recovers at 20/second after four seconds without damage, modified by gifts.
- Pause freezes offline matches. **LAN matches continue behind the pause menu.** Keep the host app in the foreground.

Desktop testing: WASD/arrows move and strafe, mouse aims, left mouse button fires manually, Space jumps/double-jumps, Q turns 180°, E harvests, R reloads/attempts active reload, Esc pauses.

## Backbone and other Android controllers

The game accepts Godot's standard Android/SDL gamepad mapping over **USB-C or Bluetooth**, covering Backbone Android, Xbox-style, PlayStation-style, and other mapped Android controllers. It detects connection/disconnection and switches between touch and controller input. The previous default layout migrates automatically to RB reload, B harvest, and Y reverse; unrelated custom jump/pause bindings are retained when possible.

These paths have been tested with synthetic standard gamepad events; **physical Backbone and other hardware still need device testing**. Vendor firmware, unusual HID mappings, and OS-reserved buttons can vary. A controller companion app is not required by the game.

| Controller input | Action |
| --- | --- |
| Left stick / D-pad | Move forward/backward and strafe |
| Right stick | Aim; shooting remains automatic over a valid enemy |
| A / south face button, or LB | Jump / double jump |
| Y / north face button, or LT | Reverse 180° |
| RB (X also works) | Reload / active reload; partial magazines can be reloaded |
| B / east face button | Harvest souls |
| RT, held | Manual firing at the crosshair; auto-fire stays enabled |
| Start / Menu | Pause / resume |
| View / Select | Controller guide |

Menus use the left stick or D-pad, south face button to select, and east face button to go back. The shop and menus are navigable by controller; entering a LAN IP still uses the phone's keyboard. Recognized PlayStation and Nintendo names receive matching face-button labels; other pads use A/B/X/Y labels by position.

**Options → Controller Settings** provides independent stick aim sensitivity (50–300%), a radial deadzone (10–35%, default 18%), stick swapping, saved primary button remapping, and restore defaults. Small stick inputs get a curved response for fine aiming. Shoulder shortcuts apply unless assigned another action. RB requires a fresh press for the active-reload attempt; holding it does not consume the bonus. RT uses a trigger threshold and release hysteresis to fire continuously at the weapon's normal rate. Manual and automatic shots share one cooldown, so they cannot double the firing rate.

Touch controls hide when a controller is used and return on touch. The controller HUD retains health, shield, ammo, timer, crosshair, environment caption, and button prompts. Disconnecting pauses offline play; LAN stays live and offers touch fallback. Reconnect and press a button or move a stick to resume controller input. Orientation and controller changes do not reset lives, equipment, or round progress.

## Menus and campaign

The Godot splash image is disabled. Android may still briefly show the app icon during native startup. The title screen runs a real AI-controlled gameplay demonstration behind the logo. Tap to enter the main menu: **Single Player Campaign**, **Multiplayer**, **Options**, **Quit Game**, and art credits.

The initial campaign is a sequence of bot matches across five biome maps, unlocked by winning: Verdant Ruins, Blue Catacombs, Ember Vault, Rootbound Forest, and Dune Coast. It is a match-based campaign foundation, without story cinematics. Options persist aiming sensitivity from 50%–300% in 10% steps, with a 180% reset, invert aim, separate effects/music/ambience volumes, camera motion, and the screen-orientation preference. Everyone starts with a five-shell, single-barrel pump shotgun. Other shop weapons currently share the older sidearm model with size adjustments. Anatomical first-person arms and an open harvesting hand replace the old glove shapes. Shotgun pellets and enemy bolts travel visibly; collision, rather than an immediate hitscan, determines damage.

## Players, minions and audio

Players now use an original, rigged **Sentinel** armored humanoid, larger than every minion type. Blue team (team 0) has blue armor accents and a blue silhouette outline; red team (team 1) has red accents and a red outline. Outlines respect walls. Running, idle, and jump animations are original to this player model. The smaller creatures retain their separate Sinbad-derived design.

| Minion | Health | Behavior | Souls dropped |
| --- | --- | --- | --- |
| Scavenger | 65 | Standard ranged minion | 15 blue |
| Stalker | 40 | Faster, lighter, violet-toned | 15 blue |
| Brute | 110 | Slower, tougher, heavier hits | 20 blue |
| Gilded Revenant | 80 | Rare gold-crowned treasure minion; flees instead of attacking | 90 gold |

One treasure minion appears at a seeded random time between 55 and 125 seconds into each collection phase. Its six gold clusters can be harvested or stolen by either team. **Gold souls cannot be destroyed**, never trigger denial shots or spend ammo, and persist until collection ends. Ordinary blue essence can still be shot away and expires after 25 seconds.

Each biome has its own original 134–146 BPM arena-techno loop, layered with a quiet brown-noise rumble. Effects and music default to 70%; the new music mix is louder. Custom volume choices are preserved; old untouched defaults migrate. The pump shotgun has original blast, pump, shell-loading and ready sounds. Music and ambience have independent mute/volume controls and pause with offline play. The audio is synthesized from scratch; no third-party tracks or samples are used. Reproduce the music and shotgun audio with `art_sources/build_arena_audio.py`; `build_soundscapes.py` retains the original brown-noise generator (Python, NumPy/SciPy and ffmpeg). `art_sources/build_sentinel.py` generates the original player model and animations in Blender.

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

- `scripts/free_arena.gd`: active game, free combat, host/client movement and match conditions.
- `scripts/free_motion.gd`, `free_brain.gd`, `free_map.gd`: physical movement, navigation AI and circular multilevel maps.
- `scripts/arena_projectiles.gd`, `arena_weather.gd`: swept visible projectiles and seeded environment effects.
- `scripts/free_hud.gd`, `touch_stick.gd`: responsive HUD and touch movement, extending the common HUD.
- `scripts/souls_arena.gd`, `match_rules.gd`, `lan_session.gd`: shared menus, economy, match flow and LAN transport.
- `scripts/controller_input.gd`: standardized gamepads, free movement, analog look, remapping and hot-plug handling.
- `scripts/essence_cloud.gd`, `minion_types.gd`, `map_soundscape.gd`: essence, enemy variants and map audio.
- `scripts/runner.gd`, `main.gd`, `corridor_map.gd`, `rail_motion.gd`: earlier prototypes and reusable art helpers; rail traversal is not active gameplay.
- `art_sources/`: original Blender and audio generation scripts.

See [asset credits and licenses](ASSET_CREDITS.md). Original code, generated scenery, Sentinel player/animations, sidearm, hand, icons, and synthesized audio (including reload foley) use MIT. The adapted Sinbad creature and its textures use CC BY-SA 3.0; scans and lighting panorama are CC0. Rajdhani uses SIL OFL. Screenshots/video containing Sinbad are CC BY-SA 3.0 with attribution in ASSET_CREDITS.md.

## Validation and releases

```sh
godot --headless --path . --script tests/free_arena_test.gd
godot --headless --path . --script tests/free_biomes.gd
godot --headless --path . --script tests/free_controls.gd
godot --headless --path . --script tests/match_rules_test.gd
godot --headless --path . --script tests/ui_navigation.gd
```

For the two-process LAN integration test, start `tests/lan_free_peer.gd -- host`, then `tests/lan_free_peer.gd -- client` in separate Godot processes on the same machine (UDP 27819). Both must report PASS. The test uses a landscape host, portrait guest, real ENet transport, controller movement/manual shots, synchronized conditions, shopping, shared rolls, hunting, and disconnected-player bot takeover. All LAN players must use v0.8.0 (protocol 8). Older rail tests explicitly use `tests/legacy_fixture.gd` to cover the reusable earlier systems.

Every update gets a numbered GitHub Release with a new APK. Increase `version/code` and `version/name`, keep the original signing key outside the repository, and verify the APK before upload. Current builds use development signing; store distribution requires release signing.
