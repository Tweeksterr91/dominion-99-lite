# Automatic killer rewards (v0.10.0)

The soul-harvest button and separate absorbing-hand model are removed from active gameplay. Blue/gold orbs now home directly to the killing fighter’s body and are protected in transit. Weapon hands and the corrected portrait weapon framing remain. The controller guide shows manual RT fire, with auto-fire reserved for a held touchscreen aim touch. Shooting/pump effects are mixed at half their prior amplitude.

Earlier iteration notes follow.

# Centered portrait weapon perspective (v0.9.2)

The v0.9.1 bottom subframe made the weapon too small and shifted its vanishing point below the crosshair. The replacement uses a full-screen weapon projection with the landscape vertical field of view, plus a tuned lateral/depth offset. The barrel, receiver and supporting hand stay visible, excess forearm is cropped, and the weapon perspective converges on the actual screen-center crosshair. Landscape keeps its existing pose.

Earlier iteration notes follow.

# Portrait framing correction (v0.9.1)

The hands/weapon render into a separate transparent landscape-shaped frame, anchored at the bottom of a portrait screen. The world camera keeps its own field of view. This crops the long forearms as landscape does and preserves the original pose, rather than translating the rig farther into the tall camera frustum. Landscape retains its original rendering path. The muzzle, harvesting hand and reload animation follow the framed presentation.

Earlier iteration notes follow.

# Lock & Load visual pass (v0.9.0)

Rotated ramps and railings now scale in their local axes, matching the actual collision shapes. Two roofed stone gatehouses add enclosed rooms and arched entrances to every biome. Existing circular arenas and elevated paths remain connected. Environment rolls are restricted to dark sunset, storm front, overcast dusk and night.

Original PBR textures add skin variation/pores, metal wear, cloth weave and walnut grain to the first-person models. Hand surfaces are smoother and the shotgun has additional receiver/trigger details. Portrait places the weapon lower, smaller and farther forward to reduce screen coverage. The materials are synthesized original maps; further realism still needs dedicated art work.

An amber target bracket identifies the locked enemy. The outer acquisition ring turns green on completion and sits just outside the separate active-reload ring. Touch gets a hold-to-lock circle above the movement joystick. Instant-turn controls are removed.

Earlier iteration notes follow.

# Dominion '99 (Lite): free arena direction (v0.8.0)

The active game is a free-moving arena FPS with portrait and landscape layouts. Its five biome arenas use circular rotundas, a raised ring, side chambers, upper balconies and ramps, with optional jump islands and jumpable low railings. Bots and minions use navigation over real collision geometry.

The starting weapon is an original single-barrel pump shotgun with anatomical first-person arms, a moving fore-end and dedicated synthesized audio. Its visible pellets, enemy bolts, seeded lighting and biome-appropriate weather reinforce combat feedback. Time and weather are revealed before the match. Original arena techno replaces the earlier ambient loops, with brown-noise ambience underneath.

The art remains a prototype with scanned 1K surfaces, original Sentinel players and adapted Sinbad minions. It is not finished photorealistic scenery. Actual OnePlus 12R rendering performance and controller behavior require device testing. Sources and component licenses are recorded in [ASSET_CREDITS.md](../ASSET_CREDITS.md).

The notes below document earlier iterations; rail movement and their older map layouts are no longer active.

# Dominion '99 (Lite): grounded dark sci-fi

The earlier goal was a more realistic look for the portrait auto-runner FPS. Turok: Rage Wars, Quake, Unreal Tournament 3, and Quake 3 Arena inform combat weight and atmosphere. The initial block-built kit was a prototype; the active visual pass now uses scanned surface materials and imported animated geometry.

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

## Sentinels & Gold (v0.5.0)

Players use the original Sentinel: rounded graphite ceramic armor, enclosed respirator helmet, luminous visor, titanium joints, and team enamel. A restrained inverted-hull outline identifies blue/red teams and remains occluded by walls. It has an original skeleton and three original animation clips. Smaller Sinbad-derived minions use muted green/violet/rust variants; the rare Gilded Revenant gains a gold crown and crystals. Indestructible gold essence contrasts with deniable blue essence. Jump and harvest gain complete rings; a circular U-turn sits below jump. Five quiet synthesized minor-key industrial soundscapes and filtered brown noise support the dark environments without competing with combat feedback.

## Rotate & Play (v0.6.0)

Portrait keeps the established corner HUD and circular center-bottom actions. Landscape uses a wider camera view, compact center-bottom touch actions, an open center crosshair, and menus laid out across two columns. Controller input hides touch actions and displays compact binding prompts; amber brackets indicate menu focus. Safe-area insets keep edge statistics clear of Android cutouts in either orientation. Switching orientation or input device preserves the live match.

## Trigger & Reload (v0.7.0)

Reload uses a clear lower/hold/raise motion: the existing weapon drops below the camera edge, mechanical foley marks the reload, and it returns smoothly. Camera-aware displacement keeps the gun out of frame in portrait as well as landscape. Active reload speeds up the return while allowing a brief ready interval. Two original synthesized foley clips provide the lowering mechanism and final ready click; no GoldenEye content is reused. Controller prompts show RT fire, RB reload, B harvest, Y reverse, and A jump, with LB jump and LT reverse shortcuts.
