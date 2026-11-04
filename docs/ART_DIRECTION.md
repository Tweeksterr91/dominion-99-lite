# Dominion '99 (Lite): dark sci-fi visual direction

## Sector 99

A decommissioned containment facility converted into a combat arena. Cold cyan power conduits cut across worn steel and rusted supports. Amber reactor cages hang overhead. Crimson visors identify the hostile Wardens.

The requested references—Turok: Rage Wars, Quake, Unreal Tournament 3, and Quake 3 Arena—guide the atmosphere, weight of the architecture, aggressive silhouettes, and readable arena combat. This project uses original designs and code rather than those games' assets.

## First asset kit

- **Environment:** modular armored walls, ribbed supports, four cover pylons, ceiling trusses, suspended reactor, floor conduits, and Sector 99 signage.
- **D-9 sidearm:** chamfered gunmetal receiver, energy spine, muzzle cage, gloved hand, and armored sleeve.
- **Warden:** broad pale shoulder armor, dark helmet, crimson visor, chest core, segmented legs, and energy rifle.
- **Pickups:** armored health cases with green crosses and amber ammo cases with cartridge markings.
- **HUD:** dark panels, sharp cyan edges, readable status labels, and an amber hit marker.

## Color and visibility

| Role | Color |
| --- | --- |
| Main armor | Gunmetal / desaturated blue-gray |
| Recesses and ceiling | Near-black blue |
| Structural wear | Muted oxidized brown |
| Facility power and player weapon | Cyan |
| Enemy identification | Crimson |
| Ammo and warning markings | Amber |
| Health identification | Green |

Darkness establishes atmosphere while pale armor and emissive identifiers preserve targets' visibility. The portrait camera keeps its horizontal field of view; the weapon stays below and to the right of the aiming area.

## Assets and performance

`scripts/visual_assets.gd` generates the original models. Moving armor pieces use one shared chamfered box mesh. Static architecture and individual models group their pieces into MultiMesh instances by material. `assets/metal.gdshader` adds procedural wear and machining marks without external texture downloads. Illuminated accents use inexpensive unshaded materials rather than post-process bloom. There are no real-time shadows.

Portrait orientation and the fixed 60 FPS cap remain. Actual performance still requires measurement on the OnePlus 12R. Desktop software-renderer screenshots verify appearance and shader compilation, not Android frame rate.

`preview.png` is an in-engine capture with enemies positioned for visibility; it is not concept art. This is an initial asset pass, with room for animation, richer silhouettes, more varied arena architecture, and further surface detail.
