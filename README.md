# Dominion '99 (Lite)

A modern take on the classic fps arena shooter, with a bit more depth.

**[Download Android APK — v0.1.2](https://github.com/Tweeksterr91/dominion-99-lite/releases/download/v0.1.2/dominion-99-lite.apk)** · **[All releases](https://github.com/Tweeksterr91/dominion-99-lite/releases)**

A small portrait-only offline FPS prototype for Android, built for editing on a phone with **Godot 4.3 or newer**. Features an original dark sci-fi containment arena, armored enemies, a pulse-style pistol, and procedural metal surfaces. Uses the Compatibility renderer, batched low-poly geometry, no real-time shadows, and synthesized audio.

![Sector 99 — in-engine portrait preview](docs/preview.png)

[Visual direction and asset kit](docs/ART_DIRECTION.md)

## Install the ready-made APK

A signed development APK, `dominion-99-lite.apk`, is also available alongside this source archive. Download it on your OnePlus 12R, open it from Downloads, approve installation for the app opening it if Android asks, then tap Install. Godot is not required to play the APK. This is an early development build, not a store release.

## Open and edit on your OnePlus 12R

1. Install the official **Godot Editor** for Android from Google Play or https://godotengine.org/download/android/. Use the standard editor; this project uses GDScript, not C#.
2. Download and extract `dominion-99-lite.zip` with your phone's file manager into a writable folder such as `Documents/Godot/Dominion99Lite`. Extract the files; do not open the project inside the ZIP.
3. Open Godot's Project Manager, tap **Import**, and select the extracted `project.godot`. Grant folder access when Android asks.
4. Open the project, hold your phone upright in portrait, and tap **Run Project** (the play triangle). Tap **DEPLOY** in the game.
5. Touch and drag on the left to move. Drag on the right to aim. Tap or hold **FIRE**; tap **RELOAD**. The **II** button pauses. The game uses a fixed 60 FPS cap with no frame-rate toggle.

The editor interface is easier with a Bluetooth keyboard or mouse, but neither is required for play. Exact Android editor UI labels can vary by version. This download is editable source, **not an installable APK**. You can run it inside the Android editor; packaging a standalone APK is a separate step that depends on your editor version's Android export support and available export tools/templates.

## Game rules

- Survive three waves: 5, 7, and 9 enemies. Three pistol hits defeat an enemy.
- Green boxes restore 30 health; amber boxes give 24 reserve rounds.
- Your pistol holds 12 rounds and takes 1.25 seconds to reload.
- Enemies shoot when they see you. Use the four pillars as cover.
- Pickups and reserve ammo replenish between waves. Every third defeated enemy drops a pickup.
- This is a single-player prototype: no multiplayer, saved progression, ads, accounts, or network requirement.

Desktop controls: WASD, mouse aim, left click, R to reload, Esc to pause.

## Edit on the phone

- `scripts/main.gd`: enemy behavior, combat, lighting, HUD, and touch controls.
- `scripts/visual_assets.gd`: original environment, weapon, enemy, and pickup models.
- `assets/metal.gdshader`: procedural metal surfaces.
- `docs/ART_DIRECTION.md`: visual palette and asset design notes.
- `project.godot`: project title, portrait layout, renderer.
- `main.tscn`: entry scene.
- For a first change, adjust `SPEED`, `MAG_SIZE`, or `LAST_WAVE` at the top of `main.gd`. The arena is generated when the game starts, so the editor's 3D viewport is initially empty.

## Performance

The OnePlus 12R's Snapdragon 8 Gen 2 is a reasonable target for this small scene. The game uses a fixed **60 FPS cap** with no frame-rate toggle. Actual FPS still depends on the device and temperature. Test on the actual phone, especially during wave 3 and while warm. Enemy steering is deliberately simple; it is not production pathfinding.

## Licensing

Original source and icon in this project are provided under the MIT license. Godot and its default fonts have their own licenses; retain Godot's required notices if distributing an exported game. This prototype's name has not been checked for trademark availability.

## Publishing future builds

Keep each version in its own GitHub Release with the APK and notes about the changes. Increase `version/code` in `export_presets.cfg` for every APK update and set a matching `version/name` (for example `0.1.3`). Reuse the original signing key to allow Android to update the installed game. Keep signing keys and credentials outside this repository; they are excluded by `.gitignore`.

The first build was exported with Godot 4.6.3 and the standard ARM64 Android debug template. This is a development build; a store release needs release signing.
