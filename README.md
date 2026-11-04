# Dominion '99 (Lite)

A modern take on the classic fps arena shooter, with a bit more depth.

**[Download Android APK — v0.2.0](https://github.com/Tweeksterr91/dominion-99-lite/releases/download/v0.2.0/dominion-99-lite.apk)** · **[All releases](https://github.com/Tweeksterr91/dominion-99-lite/releases)**

A portrait auto-runner FPS for Android. Movement, firing, and reloading happen automatically; the player concentrates on aim, route choices, jumps, double jumps, and drops. This is an **offline development prototype with bots**, not online multiplayer.

![In-engine auto-runner preview](docs/preview.png)

## Install on your phone

Download `dominion-99-lite.apk` from the latest release, open it from Downloads, and tap Install or Update. Approve installation for the app opening the APK if Android asks. Godot is not needed to play. New APKs use the original package and signing key, so they can install over previous versions.

## Play

1. Hold the phone upright. Tap the biome selector to choose a map, then START RUN.
2. The character runs forward automatically. Drag the open play area to aim independently of the run direction.
3. The crosshair turns amber over a visible bot. The pistol fires while the crosshair is on that bot and reloads automatically when empty. There are no fire, reload, running, or strafing controls.
4. Queue LEFT, AHEAD, or RIGHT for the next junction. A checkmark confirms the selected route. The route happens when you reach the junction. If nothing is queued, the runner continues ahead when possible, otherwise takes an available turn.
5. Route labels show JUMP, 2x JUMP, or DROP when the next hallway changes elevation. DOWN queues an available descending hallway at the next junction; it is not a crouch button.
6. Press JUMP just before a marked ledge. Tap JUMP AGAIN while airborne for higher double-jump landings. Only two jumps are available before landing. An on-screen cue shows the approaching ledge distance. Missing a landing or getting blocked returns you to the start of that hallway and costs 25 shield/health.
7. One thumb can aim while the other uses the contextual controls. Six bots traverse the same hallway graph and can pass through junctions on their own routes. Defeated bots respawn farther away.
8. Health and regenerating shield stay in the lower left. Magazine and reserve ammo stay in the lower right. Green pickups restore health, amber pickups supply ammo. Shield recharges at 20 per second after four seconds without damage.

The II button pauses. You can resume or change biome to start a fresh run. This is an endless survival route prototype, with distance, junction, and kill counters rather than the old three-wave arena mode. There are no accounts, ads, online players, or saved progression.

Desktop controls: mouse aim, A/Left or D/Right for a queued turn, W/Up for ahead, S/Down for a descending route, Space for jump/double jump, Esc to pause. Mouse clicks do not fire.

## Biomes

Each biome has a different connected layout built from a shared 25-junction grid, with loops, crossings, and routes at different heights. These are initial low-poly environment treatments.

| Biome | Environment | Preview |
| --- | --- | --- |
| Verdant Ruins | Mossy green masonry and overgrown chambers | [View](docs/biomes/ruins.png) |
| Blue Catacombs | Cool blue-gray stone corridors | [View](docs/biomes/catacombs.png) |
| Ember Vault | Basalt-colored chambers, warm details, lava outside routes | [View](docs/biomes/volcanic.png) |
| Rootbound Forest | Open tree-lined routes and low mossy walls | [View](docs/biomes/forest.png) |
| Dune Coast | Sandstone routes, dunes, stylized palms, and coastal colors | [View](docs/biomes/dunes.png) |

## Edit on your OnePlus 12R

Install the official Godot Editor for Android from Google Play or https://godotengine.org/download/android/. Download and extract this repository's source ZIP, import its `project.godot`, and tap Run Project. Use the standard editor; this project uses GDScript. The arena is generated at runtime, so the editor viewport is initially empty.

- `scripts/runner.gd`: active auto-runner mode, aiming, auto combat, route decisions, bots, and UI.
- `scripts/corridor_map.gd`: connected biome layouts, floors, walls, jump gaps, and scenery.
- `scripts/runner_reticle.gd`: target-reactive crosshair.
- `scripts/main.gd`: reusable combat, shield, audio, weapon, pickup, and UI helpers; also retains the older arena implementation for reference.
- `scripts/visual_assets.gd`: original weapon, enemy, and pickup models.
- `assets/stone.gdshader` and `assets/metal.gdshader`: original procedural surfaces.
- `docs/ART_DIRECTION.md`: visual design notes.

Built with Godot 4.6.3, Compatibility renderer, simple batched geometry, and no real-time shadows. The game has a fixed **60 FPS cap**; actual performance still needs testing on the OnePlus 12R.

## Validation

Run these from the project directory:

```sh
godot --headless --path . --script tests/runner_smoke.gd
godot --headless --path . --script tests/traversal.gd
```

The first checks auto reload, crosshair-triggered fire, two-thumb controls, all five connected/different layouts, shared bot routes, shield, portrait HUD, pause, and restart. The second checks real physics traversal: automatic running, a queued corner, single jump, double jump, and drop. `tests/smoke.gd` checks the older shared combat/arena base.

## Future APK updates

Use a new numbered GitHub Release for each APK and increase `version/code` and `version/name` in `export_presets.cfg`. Keep using the original signing key for development updates. Keys and credentials stay outside the repository. This is a development-signed build; store distribution needs release signing.

Original code and assets use the MIT license. Godot and its bundled fonts retain their own licenses. The project name has not been checked for trademark availability.
