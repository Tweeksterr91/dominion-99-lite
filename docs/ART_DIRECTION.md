# Dominion '99 (Lite): auto-runner biomes

The active game is a portrait auto-runner FPS. The references Turok: Rage Wars, Quake, Unreal Tournament 3, and Quake 3 Arena inform the weight of combat and the dark sci-fi weapon/enemy designs. Original stone and natural environments now replace the earlier neon facility.

## Environment kit

- Verdant Ruins: mossy dark greens, aged masonry, hanging growth, and roofed chambers.
- Blue Catacombs: cold blue and gray stone, enclosed hallways, and dim chamber accents.
- Ember Vault: basalt-like stone, warm chamber details, and lava outside the running routes.
- Rootbound Forest: open tree-lined paths, low mossy barriers, and faceted canopies.
- Dune Coast: sandstone, low route walls, faceted dunes, stylized palms, and a coastal palette.

Each has a different connected hallway layout over a shared 5x5 junction grid. Raised paths, visible ledge markings, single/double-jump gaps, and descending routes support movement decisions. Open vertical transitions provide headroom for physical jumps. These are early modular environment treatments, not finished art worlds.

## Character and interface

The D-9 sidearm retains chamfered gunmetal armor, an energy spine, a gloved hand, and an armored sleeve. Wardens have pale shoulder armor and crimson visors. Bots move through the same graph as the player, including their own turn choices and height transitions.

The crosshair is thin, centered, and target-reactive. Route prompts and contextual buttons sit below it. The lower corners retain health and regenerating shield on the left and ammunition on the right. Movement/fire/reload controls are absent.

## Asset implementation

`corridor_map.gd` builds the geometry and uses batched MultiMesh instances. `stone.gdshader` adds original procedural variation and mortar lines. `visual_assets.gd` and `metal.gdshader` provide the original weapon, enemy, and pickup kit. Materials and meshes are shared. There are no real-time shadows or post-process bloom.

The screenshots in `biomes/` are in-engine captures with bots positioned for visibility. They verify the renderer and shaders, not Android performance. Portrait and the 60 FPS cap remain; the OnePlus 12R still needs on-device testing.
