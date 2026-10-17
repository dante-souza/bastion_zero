# Bastion Zero

An original **free, offline, no-monetization** Android-first tower-defense roguelite built with **Godot 4.4+ and GDScript**.

> **Milestone 1:** source-complete vertical slice. Automated and physical-device validation are required before calling it a stable release.

## Playable vertical slice

- Defend a stationary reactor through **8 waves (~5 min 36 s)**.
- Four weapons: **Pulse Array**, **Arc Conductor**, **Rail Lance**, **Nova Mines**.
- Manual tap-to-focus targeting, otherwise automatic nearest-target acquisition.
- Three enemy classes (grunt, runner, tank), plus major enemies in waves 4 and 8.
- On each XP level-up, select one of three offered upgrades.
- Multi-weapon synergies: Pulse/Mines, Rail/Arc and Arc/Mines.
- Persistent earned **alloy** buys permanent hull or weapon damage upgrades. No in-app purchases or real-money exchange.
- Main menu/hangar, pause, retry, victory, defeat and run statistics.
- All graphics drawn procedurally: no third-party art assets or copyrighted game content.

## Requirements and quickstart

1. Install **Godot 4.4.1 stable**, or a compatible 4.4+ version.
2. Open `project.godot` with the project manager; press **F6/F5** to run the main scene/project.
3. Press **DEPLOY BASTION**. Click/tap an enemy to focus it. Click blank space to release focus.
4. Select upgrades between XP levels; the battle stops while selecting.
5. After a run, spend alloy on permanent research in the hangar.

For CLI import, tests and headless smoke boot:

```bash
godot --headless --path . --editor --quit --quit-after 240
godot --headless --path . --script res://tests/test_smoke.gd
godot --headless --path . --quit-after 10
```

A GitHub Actions workflow runs these checks on each PR/push. The test output, not the presence of this workflow, determines whether validation has passed.

## Android debug build — Galaxy J8

The Samsung Galaxy J8 running Android 10 supports **32-bit armeabi-v7a**. The project's export preset `Android J8 Debug` targets this ABI.

**No Godot installation is needed on the phone.** Download the GitHub Actions debug APK artifact:

1. Open [Android J8 debug APK — GitHub Actions](https://github.com/dante-souza/bastion_zero/actions/workflows/android-j8.yml).
2. Open a **successful** workflow run on the feature branch.
3. Under **Artifacts**, download `Bastion-Zero-M1-J8-ARMv7-debug` (a ZIP).
4. Extract `bastion-zero-j8-debug.apk` from the ZIP and copy it to the phone.
5. On the J8, open the APK with **My Files**, approve **Allow from this source** if prompted, and install.

Alternative with Android Debug Bridge on the Windows PC:

```powershell
adb devices -l
adb install -r .\bastion-zero-j8-debug.apk
```

The CI debug APK is signed with an **ephemeral debug keystore**, which changes between workflow runs. If Android reports `INSTALL_FAILED_UPDATE_INCOMPATIBLE` after you installed an earlier debug APK, uninstall the previous app before installing the new one. **Uninstalling erases the game's local save**, so test data should not be treated as durable. A stable project-controlled signing key will be needed before release.

### Local Godot export

Install Godot 4.4.1 and matching export templates, Android SDK, and JDK 17. Configure the Android SDK and Java SDK paths in Godot's Editor Settings. Select the existing `Android J8 Debug` preset under **Project > Export**, then export a debug APK.

**This APK is for sideloaded QA, not a Play Store release.** A Play Store release requires a signed AAB and ARM64 support.

## Repository branches

`feature/m1-playable-game` → PR to `dev` → test/approve → merge to `dev`. Later, a separate PR `dev` → `main` and a v0.1.0 tag, after Android acceptance. No squash merges required.

## Milestone 1 acceptance

- [ ] GitHub Actions import and tests green
- [ ] Opens on Android portrait without crash
- [ ] HUD readable on 720×1280 and smaller devices
- [ ] All four weapons fire and focus targeting works
- [ ] Boss and win/loss endings tested
- [ ] Research persists across app restarts
- [ ] Signed release APK/AAB tested before tagging

## License

Copyright (c) 2026 Bastion Zero contributors. Code licensed **AGPL-3.0-or-later**, see `LICENSE`. This game is an independent original work, not associated with Rogue Defense or its publisher.
