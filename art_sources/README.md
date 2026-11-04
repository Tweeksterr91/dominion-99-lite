# Asset builders

These scripts are development tools; players only need the APK.

- `build_sidearm.py`: original MIT-licensed Blender sidearm builder. Run with `blender --background --python art_sources/build_sidearm.py`.
- `read_ogre_skeleton.py`: reads the original Sinbad skeleton and saves `Sinbad.json` beside it. Run with Python and the source `Sinbad.skeleton` path.
- `convert_creature.py`: loads the original `Sinbad.blend` and reconstructs its animations from `Sinbad.json`. Run `blender --background PATH/TO/Sinbad.blend --python art_sources/convert_creature.py -- PATH/TO/SOURCE_FOLDER`. This exports the adapted model to `assets/models/warden.glb`.

Download the Sinbad source pack from the link in `ASSET_CREDITS.md`. Its model, animations, and textures are CC BY-SA 3.0; the conversion scripts are MIT.

- `build_viewmodel_textures.py`: generates the original skin/steel/cloth/walnut PBR maps with Python, NumPy, SciPy and Pillow. Run this before `blender --background --python art_sources/build_pump_viewmodel.py` to rebuild the textured shotgun/arms and harvesting hand. Godot extracts embedded images beside the GLBs; the corresponding PNG import settings use VRAM compression and mipmaps for mobile.
