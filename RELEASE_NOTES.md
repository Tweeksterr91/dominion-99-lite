# v0.12.0 — Boroughs & Careers

- Neo-Prohibition New York art foundation: stepped Art Deco skyline silhouettes, 48 inaccessible 3D backdrop buildings, water towers, amber windows, small foliage patches and vines. Structural piers, tower bases and masonry supports make raised paths part of buildings. A lower roof catches missed jumps; an outer fence/boundary keeps players inside while leaving skyline views open.
- Expanded, shared random spawn pool for players, bots and minions. Spawn candidates are validated against navigation and collision after baking, with separation checks to reduce crowding.
- One match cycle: 82.5-second collection, up to 30-second armory, 3-second shared gift reveal and 82.5-second hunting. Five lives each. Removed round-number HUD; time of day uses descriptive labels without clock hours. Opening weather reveal remains 6 seconds.
- Armory hides owned weapons. Tight Choke costs 45 souls per stack, reducing shotgun spread 18% per stack, up to three stacks. Removed purchasable reload-speed, health and armor upgrades/packs; damage and ammo purchases remain. Free RNG gifts and map health pickups remain.
- Carbon Carbine replaces the Needle name and gets an original textured matte military model. Added Warden Sniper: 180 souls, five rounds, 110 base damage and slower cadence, with a scoped military model. Bots cannot buy it. Both have original shot sounds; the wheel supports all seven weapons. Scattergun now uses six visible shotgun pellets.
- Directional red damage edges track the incoming shot relative to the player's view and replicate over LAN.
- Heroes / Campaigns foundation: 24 named profiles (8 male, 8 female, 4 anthropomorphic, 4 robotic), individual bios, five named chapters apiece, unique shared-map routes and career objectives. Independent saved wins, frags, souls and unlocks; existing campaign progress migrates to Rook. Heroes currently share the Sentinel combat model: this update does not include 24 finished character meshes or cinematic campaigns.

Install `dominion-99-lite.apk` over the existing game to retain settings/careers. Same package/signing identity, versionCode 17. **All LAN players must update to v0.12.0** (protocol 12).

Validation: shared spawn/navigation and safe-boundary checks; five maps; one-match flow; owned shop filtering and choke spread; rifle visibility/materials and bot sniper restriction; four damage directions, aim rotation and fading; 24 unique hero routes and independent saved campaign progress; touch/controller movement, reload/lock, weapon wheel, inventory and portrait/landscape framing. Two actual local Godot processes test 4v4 flow/economy, lock-on, killer rewards and the seven-weapon armory with directional damage replication. Android/Backbone feel and actual phone performance still need device testing.

Original new models, synthesized audio, city geometry/sky, emblems and career content use MIT. Full notices: ASSET_CREDITS.md.
