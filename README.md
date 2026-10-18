# Bastion Zero

**Bastion Zero** is an original Android-first, offline, no-ads, no-IAP directional tower-defense roguelite made with **Godot 4.4.1** (GDScript, GL Compatibility).

> **M1R v0.2.4 — System Evolution UI refinement.** The early radial-arena M1 design was rejected after comparing gameplay reference recordings. M1R contains a new combat runtime. GitHub CI validates code/export; only a physical J8 playtest can validate tactile gameplay and performance.

## Play the M1R demo

- **NORMAL 01**: defend the lower breach line against authored line, wedge, pincer, rush and armored formations in a ~96-second stage.
- **ELITE 01**: unlocked after winning NORMAL 01; ~115-second stage with tougher formations, an elite encounter that gains speed and summons escorts below 55% HP.
- Your **Guardian** starts with the **Sentinel Autocannon**. It fires fast individually simulated cyan rounds and remains viable with independent Kinetic Payload (damage), Sabot Piercer (pass-through), Ricochet Routing (bounces), Saturation Burst (separately aimed extra shots), plus the original cadence/dual-barrel/smart-tracking ranks. **Prism Beam** is separately acquired from level-up cards. Touch an enemy to prioritize it temporarily.
- Evolve four **original** weapons: Prism Beam (unlockable penetration + accurately targeted twin beam), Comet Volley (homing multi-rocket salvo + explosive/splitting missiles), Arc Relay (chains + stun), and Nova Field (slow pulse + blast).
- Every XP level-up pauses battle to offer three distinct build choices, including a Sentinel evolution and a new-weapon unlock while each is available. The taller System Evolution panel now shows separate category, weapon name, exact description, and **OWNED rank → NEXT rank**; fully maxed upgrades disappear from the offer pool. Synergies: Prism/Arc and Comet/Nova.
- Local alloy rewards and permanent hull/damage research; stage unlocks and graphics settings persist.
- Battle HUD shows hull, stage timer, XP, selected weapons and approximate FPS. After each run: damage breakdown by weapon.
- **Enemy counterplay:** tanks resist Prism Beam but take more Comet Volley and Nova Field damage; agile runners are vulnerable to Arc Relay. Hit feedback, wave cues and breach statistics are visible during combat.
- Low-effects mode is enabled by default for the **Samsung Galaxy J8 (Android 10, ARMv7)**.
- No reference-game assets, code or accounts are included. See [M1R design and acceptance](docs/M1R-DIRECTIONAL-DEFENSE-REBUILD.md).

### Quick start on desktop

Download Godot 4.4.1, open `project.godot`, press F5. On the hangar select **DEPLOY • NORMAL 01**. Pause with **II**, tap threats, select weapon evolutions and return after a run.

Headless checks:

```bash
godot --headless --path . --editor --quit --quit-after 240
godot --headless --path . --script res://tests/test_smoke.gd
godot --headless --path . --quit-after 10
```

## Samsung J8 APK

Open [Android J8 debug APK CI runs](https://github.com/dante-souza/bastion_zero/actions/workflows/android-j8.yml), select a **successful M1R run**, download the `Bastion-Zero-M1R-J8-ARMv7` artifact, unzip and sideload `bastion-zero-j8-debug.apk`. The build uses the 32-bit ARMv7 export preset.

PowerShell (from APK directory):

```powershell
adb devices -l
adb -s 38c19745 install -r .\bastion-zero-j8-debug.apk
```

**Debug signing**: If no persistent `BASTION_DEBUG_KEYSTORE_BASE64` GitHub Actions secret is configured, the CI pipeline generates an ephemeral key for each run. Android will reject an overwrite with mismatched signatures. Uninstalling first will erase Bastion Zero's local save. To preserve updates, configure a stable debug signing keystore (see `docs/ANDROID-SIGNING.md`) before continuing regular phone playtests.

## Local developer setup (Windows + ADB)

A `Makefile` and standard-library Python helpers provide safe updates and Galaxy J8 APK operations. See [Local developer workflow](docs/LOCAL-DEVELOPMENT.md). Quick commands from the repository root:

```powershell
make help
make doctor
make apk
make reinstall-run   # WARNING: deletes current Bastion Zero save
make installed
make sync            # safe fast-forward of local main/dev/feature
```

The Make targets explicitly select J8 serial `38c19745` when a Moto G41 is also connected. `make reinstall-run` verifies the APK before uninstalling. Stable debug signing is still recommended to avoid local save deletion between CI builds.

## Development flow

`feature/m1-playable-game` → Draft [PR #1](https://github.com/dante-souza/bastion_zero/pull/1) to `dev`, awaiting J8 gameplay validation. Then merge without squash and promote through normal Gitflow. Never merge reference third-party assets, extracted saves or binaries.

## License

Copyright (c) 2026 Bastion Zero contributors. Code licensed **AGPL-3.0-or-later** (`LICENSE`).

## Visual direction for next build

The [early-game visual direction](docs/VISUAL-DIRECTION-EARLY-GAME.md) is informed by the user's uploaded gameplay recording, without importing third-party art. **Phase A is implemented on `feature/m1-visual-phase-a`**: a near-black arena, a quiet playfield, a shallow electric-blue horizon, and minimal breach markers. Full-FX adds a restrained halo and sparse static speckles; low-FX omits them for the Samsung J8. The original Guardian and enemy drawing remain in place until the subsequent visual phases. See [Phase A implementation and validation](docs/VISUAL-PHASE-A.md).
