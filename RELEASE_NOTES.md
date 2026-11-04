# Dominion '99 (Lite) — v0.2.0

First auto-runner FPS build with contextual route choices and biome corridors.

## Mechanics

- Automatic forward running, firing when the crosshair is on a visible bot, and reloads when the magazine empties.
- Removed the movement pad, manual fire button, and reload button.
- Drag to aim while another thumb chooses LEFT, AHEAD, RIGHT, JUMP, or DOWN.
- Queue a direction for the next junction; DOWN selects an available descending hallway.
- Real single jumps, midair double jumps, raised landing platforms, and drops. Watch the ledge-distance cue and time takeoff.
- Six bots travel the same connected hallways, cross junctions, fight on sight, and respawn after defeat.
- Endless runs track distance, junctions, and kills. A missed landing/block returns to the hallway start and costs 25 shield/health.

## Maps and HUD

- Five initial biome treatments with different connected layouts: Verdant Ruins, Blue Catacombs, Ember Vault, Rootbound Forest, and Dune Coast.
- Replaced facility energy rails with stone, moss, basalt, trees, dunes, and coastal colors.
- New crosshair reacts to targets and hits.
- Portrait orientation, fixed 60 FPS cap, lower-left health/shield, and lower-right ammo remain.

This version is offline with bots. Online player encounters are not implemented. The environments are an initial low-poly pass; actual OnePlus 12R frame rate remains unmeasured.

## Validation and update

Automated checks cover all five connected/different layouts, shared bot traversal, auto-fire targeting, auto-reload, two-thumb input, shield, portrait HUD, pause/restart, and real-physics single jump, double jump, drop, and queued turn. All five biome shaders were checked in rendered desktop captures.

Download `dominion-99-lite.apk` from Assets and install over your current version. The package and signing key are unchanged; Android version code is 5. Requires Android 7.0 or newer on ARM64. This is a development build.
