# Bastion Zero — Phase H Premium Visual Pass

**User-approved direction:** The Last Horizon (four cinematic concept images).
**Branch:** `feature/m1-visual-phase-h-premium`.
**Android:** 0.8.0-phase-h-premium-debug, isolated ARMv7 J8 package.

## Approved source art and accurate implementation

The user approved four rendered concepts, covering portrait splash, Hangar UI,
premium circular launcher emblem, and minimal no-text Guardian startup art.
Images were produced during the design session, not scraped from games.
A downloadable Phase H artwork bundle contains six deployment assets:

- `premium_splash_720.png` — high-quality Godot boot splash, 720x1280;
- `premium_hangar_hero.webp` — 680x380 text-free Guardian/horizon hero
  cropped from the approved cinematic startup artwork;
- `premium_hangar_background.webp` — restrained behind native menu controls;
- `premium_guardian_launcher_192.png` — launcher icon;
- `premium_guardian_foreground_432.png` — adaptive foreground;
- `premium_guardian_background_432.png` — adaptive background.

**Do not paste the full menu mockup as UI.** Every deploy, research and FX
control is a real Godot Button on `HangarView` with active signal handlers
from Phase G. Native premium style uses dark navy, thin luminous cyan/blue
lines, glowing deploy edge, true section rules, touch-safe controls, clear
alloy/progression indicators and a quiet system footer. The Phase F attack
showcase and all save/progression mechanics are unchanged.

## Reproducible installation

The six approved binary assets cannot be represented accurately as handwritten
SVG. They are supplied as a separately downloadable ZIP and verified byte-for-
byte by `scripts/phase_h_assets.py` (allowlisted paths and SHA-256). It copies
art into `assets/branding` and updates the native boot splash and the **Phase
H export preset only**, leaving older phases intact. Import is idempotent.
The Github Android job requires checksums before producing a Phase H APK.

PowerShell from Phase H branch:
```powershell
$bundle = Join-Path $env:USERPROFILE 'Downloads\\bastion_zero_phase_h_art_bundle.zip'
make phase-h-art ART_BUNDLE="$bundle"
make phase-h-art-check
git add assets/branding/premium_* project.godot export_presets.cfg
git commit -m "assets(branding): import approved Phase H premium Last Horizon art"
git push origin feature/m1-visual-phase-h-premium
make phase-h
make phase-h-screenshot
```
If `git add` doesn't expand the wildcard on PowerShell, use
`git add assets/branding project.godot export_presets.cfg`.

## Visual/quality checks

- Compare cold-start system icon and actual Godot boot screen separately.
- Inspect icon, full cinematic splash and Hangar (without baked UI text).
- Check all real buttons, research affordability, stage lock and FPS.
- No Internet permission, ads, telemetry, or external image download.
- Prior heavy-combat J8 screenshots showed FPS dropping below 30 in dense
  waves. This branding milestone cannot be treated as combat optimization.
