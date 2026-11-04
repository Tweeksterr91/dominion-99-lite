# v0.9.2 — Portrait weapon perspective

Corrects the overly small, low shotgun from v0.9.1. The weapon now uses a full-screen portrait projection with a fixed vertical field of view. The barrel’s perspective converges on the real crosshair instead of a point near the bottom edge. A tuned side/depth offset shows the barrel, pump, receiver and supporting hand while cropping excess forearm. Landscape keeps its existing pose and renderer.

Updated portrait previews include tall-phone and standard portrait aspect ratios. Projection checks now enforce visible muzzle and receiver positions, center the barrel’s vanishing point, and verify displayed/physical muzzle alignment, rotation and complete reload lowering. Existing free-movement/projectile, lock-on, touch-control and menu checks pass.

Download `dominion-99-lite.apk` and install over the existing game. Same package and signing certificate, versionCode 14. LAN protocol remains 9, compatible with v0.9.0 and v0.9.1.

The screenshots and checks were produced in-engine. Android hardware appearance/performance still needs device testing. Original code: MIT; component asset licenses and credits are in ASSET_CREDITS.md.
