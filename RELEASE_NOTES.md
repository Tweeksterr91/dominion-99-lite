# Dominion '99 (Lite) — v0.1.3

Lower-corner HUD and regenerating shield.

- Health and shield, with numeric readouts and bars, now sit in the lower left quadrant.
- Magazine and reserve ammo now sit in the lower right quadrant.
- Movement, fire, and reload controls moved upward to leave the HUD clear.
- A 100-point shield absorbs incoming damage first. Excess damage reduces health.
- Shield recharges at 20 points per second after four seconds without a hit. New damage restarts that delay; pause freezes recharge. Health still requires pickups.
- Blue shield-hit feedback changes to red when damage reaches health.

Portrait orientation and the fixed 60 FPS cap remain. Shield behavior, combat, and HUD placement passed automated checks at standard portrait and OnePlus 12R screen proportions. Phone performance is still unmeasured.

## Update

Download `dominion-99-lite.apk` from Assets and install it over the previous version. The package and signing key are unchanged; Android version code is now 4. Android 7.0 or newer on ARM64 is required. This is a development build.
