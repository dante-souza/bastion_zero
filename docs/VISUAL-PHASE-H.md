# Bastion Zero — Phase H Premium Visual Pass

**Direction:** user-approved cinematic *The Last Horizon* branding.
**Branch:** `feature/m1-visual-phase-h-premium`
**Android:** `0.8.0-phase-h-premium-debug`, isolated ARMv7 package
`com.dantesouza.bastionzero.phaseh`.

## What is committed

All six original, approved premium PNG/WebP files are now committed in
`assets/branding/` — not downloaded dynamically, and not reconstructed
from an older procedural placeholder:

- `premium_splash_720.png`: 720×1280 Godot boot splash,
  configured by `project.godot`;
- `premium_hangar_hero.webp`: 680×380 artwork featuring the Guardian,
  blue defense horizon and dark atmospheric lighting;
- `premium_hangar_background.webp`: low-opacity Hangar backdrop;
- `premium_guardian_launcher_192.png`: Android launcher;
- `premium_guardian_foreground_432.png`: Android adaptive foreground;
- `premium_guardian_background_432.png`: Android adaptive background.

`export_presets.cfg` references the exact three Phase H launcher image
assets; older Phase G and other preset definitions are unmodified.

## Visual/UI implementation

The native `HangarView` retains working Deploy, Research, FX and
progression controls. The UI uses refined navy/cyan surfaces, glowing
deploy accents, quiet line dividers and consistent font hierarchy.
No UI buttons are baked into images. The Hangar's actual header, research
costs, alloy, runs, wins, stage lock and FPS-related gameplay are preserved.

Phase F's dense NORMAL 01 test mode remains as-is, pending a separate
performance milestone. Android's immediate neutral-gray system launch
screen can remain platform-controlled even with the premium app icon.
The following Godot splash is our branded premium illustration.

## Standard GitHub-first workflow

The same workflow used in prior phases is now restored:

```powershell
git fetch origin --prune
git switch feature/m1-visual-phase-h-premium
git merge --ff-only origin/feature/m1-visual-phase-h-premium
make profile
make check-tools
make phase-h
make phase-h-doctor
make phase-h-screenshot
```

The GitHub Android job checks the SHA-256 of every image, imports them
with Godot and packages them inside the APK. `make phase-h` retrieves the
latest successful Phase H artifact and installs it on the J8, no Android
Studio, manual download or local Godot executable required.

For an *optional later image revision* only, the checksum-verified
`make phase-h-art ART_BUNDLE=...` importer remains available.

## Acceptance on the physical J8

1. Launcher has the premium Guardian rather than the old Phase G icon.
2. Godot splash shows full-resolution clean art (no old blocky typography).
3. Hangar art includes the complete Guardian and horizon, behind real controls.
4. Alloy, research, deploy and FX remain legible and functional.
5. Dense combat is unchanged from Phase F; performance is measured separately.

## Phase H.1 — J8 Hangar layout repair (0.8.1)

Real J8 screenshots reveal that horizontally expanding colored divider rectangles
compress MISSION CONTROL and RESEARCH LAB headings into vertical letters and
stretch into enormous translucent panels. A full-screen premium background also
repeats the Guardian behind mission controls.

Fixed by replacing each heading HBox with a full-width VBox and 2px hairline,
explicitly disabling word-wrap on headings. Removed duplicate background and
fixed 720x1220 CenterContainer; content now flows through a scrolling
MarginContainer with 25px safe side margins. Shortened the hero and button
heights slightly while preserving 50px+ touch targets. Regression smoke checks
assert the proper UI hierarchy. Version incremented to 0.8.1/code 19.

**Same Phase H Android package, no new launcher icon.** Update the existing
`feature/m1-visual-phase-h-premium` branch and run `make phase-h`.
