# Asset credits and licenses

The project's original code, generated scenery, sidearm, and builder scripts use the MIT license. The following third-party assets retain their own licenses.

## Warden creature / Sinbad

**Sinbad**, copyright 2009–2010 **Zi Ye**, from the OGRE project.

- Source: https://github.com/OGRECave/ogre/blob/master/Samples/Media/packs/Sinbad.zip
- License: **Creative Commons Attribution-ShareAlike 3.0 Unported** — https://creativecommons.org/licenses/by-sa/3.0/
- Applies to `assets/models/warden.glb`, `assets/models/warden_sinbad_body.png`, and `assets/models/warden_sinbad_clothes.png` and adapted Sinbad visual content.
- Adaptations: converted the source mesh and skeleton to glTF, normalized scale and foot placement, reconstructed and baked the original running, idle, and jump clips, rebuilt materials for modern rendering, and added the game's material tinting.
- The adapted model and textures are distributed under **CC BY-SA 3.0**, not the project's MIT code license. Further adaptations of this content must follow that license.

The original source pack's notice identifies the artist as Zi Ye and licenses `Sinbad.mesh`, `Sinbad.skeleton`, `Sinbad.blend`, its textures, and `Sword.mesh` under CC BY-SA 3.0. The sword asset is not used here.

The gameplay screenshots and preview video containing the adapted Sinbad character are also shared under CC BY-SA 3.0, with the attribution above.

## Scanned surfaces / ambientCG

The following ambientCG assets are distributed under **CC0 1.0 Universal**: https://creativecommons.org/publicdomain/zero/1.0/

License information: https://docs.ambientcg.com/license/

| Project folder | Source asset | Maps |
| --- | --- | --- |
| `assets/textures/rock` | https://ambientcg.com/view?id=Rock030 | Color, OpenGL normal, roughness |
| `assets/textures/earth` | https://ambientcg.com/view?id=Ground037 | Color, OpenGL normal, roughness |
| `assets/textures/masonry` | https://ambientcg.com/view?id=Bricks074 | Color, OpenGL normal, roughness |
| `assets/textures/bark` | https://ambientcg.com/view?id=Bark007 | Color, OpenGL normal, roughness |
| `assets/textures/sand` | https://ambientcg.com/view?id=Ground054 | Color, OpenGL normal, roughness |

The original 1K JPG maps are renamed by role; their image content is unchanged. Sources were retrieved on 2026-11-04. Material tinting and tiling happen in the renderer.

## Lighting panorama / Poly Haven

The lighting panorama `assets/textures/lighting/kiara_1_dawn_1k.hdr` is **Kiara 1 Dawn** from **Poly Haven**, CC0. Source: https://polyhaven.com/a/kiara_1_dawn — license: https://polyhaven.com/license . The HDR image content is unchanged.

## Original project assets

`assets/models/sidearm.glb` is generated from the original MIT-licensed `art_sources/build_sidearm.py`. Other generated scenery, foliage geometry, shaders, and the project icon are original MIT-licensed project content.

## Engine

Godot Engine: copyright Godot contributors, MIT license. https://godotengine.org/license/

Godot's bundled third-party components and fonts retain their respective notices and licenses.
