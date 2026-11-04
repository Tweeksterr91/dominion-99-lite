# v0.9.1 — Portrait weapon framing

Fixes the long, protruding forearms and shotgun in portrait. The first-person rig now uses its own transparent, landscape-shaped rendering frame at the bottom of the screen. It keeps the natural landscape pose and proportions while cropping the excess forearms; changing the world-camera FOV no longer exposes more of the arms. Landscape presentation stays the same.

The harvesting hand and muzzle flash use the same frame. Touch passes through to the HUD. Reload lowering and the displayed/physical muzzle alignment are verified across portrait, landscape and tall-phone/tablet aspect ratios. The world view, crosshair, movement, lock-on and match progress stay independent of weapon framing.

Install `dominion-99-lite.apk` over the existing game. Same package and signing certificate, versionCode 13. LAN protocol remains 9, compatible with v0.9.0.

Validation: in-engine portrait/landscape captures; projection, rotation, muzzle alignment and reload checks; free movement/projectile combat, optional lock-on, touch controls and menu regression checks. Android hardware appearance and performance still need device testing. Original code: MIT; full asset attribution and licenses are in ASSET_CREDITS.md.
