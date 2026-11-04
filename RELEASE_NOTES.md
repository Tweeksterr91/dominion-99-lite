# Dominion '99 (Lite) — v0.3.0

First visual foundation toward a more realistic dark sci-fi game.

## Graphics and animation

- Scanned 1K color, normal, and roughness maps for stone, masonry, ground, bark, and sand, with smooth filtering and world-space tiling.
- Surface and character textures have preserved mipmapped, mobile-compressed imports. The optimized APK is approximately 45 MB.
- An imported textured creature replaces the rigid box-built enemies. Its real skeleton plays running, idle, and jumping clips; the model is an adapted Sinbad asset by Zi Ye.
- A newly modeled, beveled sidearm with barrel details, a grip, a glove, recoil, running movement, and automatic-reload tilt.
- Rounded columns and trunks, smoother dunes, and individual leaf-shaped foliage instead of solid canopy blobs.
- HDR environment reflections, outdoor sky, short-range directional shadows, and 2x edge anti-aliasing.
- ART CREDITS in the menu and asset licenses in the repository.

This is a foundation, not finished photorealism. The character is a licensed fantasy creature, and the modular scenery still needs further art refinement. These changes provide a working model/animation/material pipeline that can accept better production assets without requiring you to model or animate.

## Preserved mechanics

Portrait, auto-run, aim-triggered fire, auto-reload, contextual route choices, jumps/double jumps, drops, shared-corridor bots, the fixed 60 FPS cap, and the lower-corner health/shield/ammo HUD remain. This build is offline.

## Verification and update

Checked actual skeletal joint movement, animation pause, combat, controls, credits navigation, all biome layouts, HUD, and collision traversal. All five biomes were rendered, and a five-second gameplay preview is included. Rendering cost has increased; actual frame rate still needs checking on the OnePlus 12R. The 60 FPS cap is a target, not a measured guarantee.

Download `dominion-99-lite.apk` from Assets and install over your current version. The original package and signing key are preserved; Android version code is 6. Android 7.0 or newer on ARM64 is required. This is a development build.

Creature model: Sinbad © Zi Ye, adapted under CC BY-SA 3.0 (https://creativecommons.org/licenses/by-sa/3.0/). Scanned surfaces: ambientCG, CC0. Lighting: Poly Haven, CC0. Gameplay previews containing Sinbad are CC BY-SA 3.0. Full attribution and modification details: ASSET_CREDITS.md in the repository.
