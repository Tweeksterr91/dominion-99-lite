# Dominion '99 (Lite): grounded dark sci-fi

The goal is a more realistic look for the portrait auto-runner FPS. Turok: Rage Wars, Quake, Unreal Tournament 3, and Quake 3 Arena inform combat weight and atmosphere. The initial block-built kit was a prototype; the active visual pass now uses scanned surface materials and imported animated geometry.

## Biomes

- Verdant Ruins: weathered masonry, mossy ground, bark, and enclosed chambers.
- Blue Catacombs: cold blue-gray stone and roofed hallways.
- Ember Vault: darker rock, warm accents, and lava outside the routes.
- Rootbound Forest: grass/soil scans, textured trunks, open canopy, and leaf geometry.
- Dune Coast: scanned sand, rounded dunes, low stone walls, and outdoor sky.

Each biome has a different connected layout over the shared 5x5 junction grid. Scenery uses batches and repeated meshes, with round columns, smoother mounds, and individual leaf shapes. This is still modular art that needs further refinement rather than finished photorealistic scenery.

## Characters, weapon, and movement

The first-person sidearm is generated in Blender with bevels, barrel details, a grip, a glove, and an armored sleeve. Recoil, a small running motion, and automatic-reload tilt provide motion without disrupting the aiming camera.

The creature is adapted from Sinbad by Zi Ye, under CC BY-SA 3.0. Its source mesh is 7,612 triangles with a 69-joint skeleton. The original run, idle, and jump clips are reconstructed from the source skeleton and baked to glTF. A material shader reduces the original fantasy colors. It is a licensed fantasy creature as a pipeline foundation, not a photorealistic human character. Character animation stops while gameplay is paused.

The thin crosshair remains target-reactive. Route controls stay below it. Health and shield remain lower left, ammunition lower right. The original auto-runner mechanics remain.

## Materials and lighting

Scanned 1K color, OpenGL normal, and roughness maps come from ambientCG (CC0). World-space tiling and mipmapped anisotropic filtering replace the former coarse surface noise. A Poly Haven HDR panorama provides reflections and outdoor sky. One short-range directional shadow map and 2x anti-aliasing improve depth and edges.

All assets are bundled for offline play. The fixed 60 FPS cap remains; richer materials, animation, and shadows increase rendering cost, and actual OnePlus 12R performance still needs measuring. Desktop software-renderer captures establish appearance and animation correctness, not Android performance.

## Sources and licenses

See [ASSET_CREDITS.md](../ASSET_CREDITS.md) for creator attribution, source links, modifications, and component licenses. Code, original sidearm, and generated scenery are MIT; adapted Sinbad assets and gameplay previews containing them are CC BY-SA 3.0. Scanned surface maps and the lighting panorama are CC0. The in-game menu has ART CREDITS.

The images in `biomes/` are in-engine captures with bots positioned for visibility. The release's short video records an actual auto-run with a queued turn and automatic shooting.

## Souls & Ash interface (v0.4.0)

Use transparent screen-edge statistics, Rajdhani typography, warm amber vector navigation, and icy blue essence accents. The center remains open for aim and the active reload ring. Jump uses an original jumping-person glyph below the ahead arrow. Menus layer typography over a running in-engine demo; match shopping and shared rolls freeze combat behind a subtle full-screen gradient. The open essence glove is an original Blender asset with a blue palm focus. Full asset notices remain in ASSET_CREDITS.md.
