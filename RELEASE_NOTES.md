# v0.13.0 — Nightfall

- Added sparse soft stars and a modest textured moon to the city sky. Night has the strongest celestial detail, dusk is subdued, and cloud cover obscures stars/moonlight.
- Added slowly drifting sky clouds with shallow 3D density integration and soft lighting. Denser cloud settings follow stormy weather. These are lightweight ray-marched sky volumes for Android's existing Compatibility renderer, without full scene volumetrics or cloud shadows. Reduced fog's sky contribution so celestial details and clouds remain visible while the city retains haze.
- Added restrained world-only soft bloom, depth-aware depth of field, edge chromatic aberration and camera-turn motion blur. Crosshair focus follows actual world hits smoothly; nearby geometry and the aim center stay clear. Depth checks prevent distant blur bleeding across nearby silhouettes. Motion blur is bounded to 2.2 pixels, clears on pause/cuts/rotation and has no temporal history or object motion vectors. HUD and menu text stay sharp; portrait weapons remain on their separate overlay.
- Options → Visual Settings has four independent saved effect switches, all default on. Turning all off removes the lens pass. Camera Motion / Minimal moved to that screen. Offline settings pause the match; LAN stays live.

Install `dominion-99-lite.apk` over the current game. Same package/signing key, versionCode 18. LAN protocol stays 12, compatible with v0.12.0. The 60 FPS cap remains; actual OnePlus 12R performance/appearance and Backbone feel still need device testing.

Validation: real OpenGL Compatibility rendering checks demonstrate distant depth blur with unchanged near geometry, bloom highlights, chromatic edge separation, motion blur/reset and unchanged HUD pixels. Settings persistence, physical crosshair focus, motion bounds/cut/rotation resets, both menu orientations, offline pause, five map conditions, portrait weapon framing, controls and navigation checks pass. Two actual local Godot processes verify 4v4 gameplay and that multiplayer keeps progressing behind visual settings.

Original sky and lens shaders/code use MIT. All component notices: ASSET_CREDITS.md. Source archive and screenshots are attached.
