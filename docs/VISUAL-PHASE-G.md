# Bastion Zero — Phase G: The Last Horizon

**Branch:** `feature/m1-visual-phase-g-identity-hangar`
**Build:** `0.7.0-phase-g-horizon-debug`, ARMv7 Galaxy J8.
**Concept approved:** **The Last Horizon** — a lone Guardian protecting
a luminous electric-blue shallow boundary from sparse colored threat silhouettes.

## Unified visual identity

- `icon.svg`, `assets/branding/guardian_icon.svg`: a new 192px vector
  centered cyan/navy circular reactor with four cardinal housings, not the
  provisional 2026 triangle emblem. Android uses the project icon.
- `assets/branding/last_horizon_splash.svg`: source-vector 720x1280
  design, referencing the same original Guardian assembly from
  `assets/guardian_phase_b3.svg` plus dark navy sky, sparse
  orange/green/yellow threat markers and blue defensive horizon.
- `assets/branding/last_horizon_boot.png`: a 540x960 palette PNG built
  specifically for **native Godot boot_splash/image** compatibility,
  visible during engine startup. It uses the same palette and composition;
  the pixel-rendered native boot is intentionally lightweight. It is not
  a copy of any reference game's art.
- `assets/branding/last_horizon_hero.svg`: a 680x380 vector hero art
  for the new hangar; it embeds the very same original Guardian SVG
  geometry that appears in gameplay rather than inventing another machine.
- `project.godot` configures a dark native boot-splash color, a real PNG
  image, and appropriate image filtering/scaling.

## Hangar structure

New `scripts/hangar_view.gd` is an independent Godot ColorRect/Control
command UI. `Main._hangar()` composes it and connects signals to existing
`_deploy`, `_research` and `_toggle_fx` owners. No save or combat logic
moved into the view, and no additional gameplay asset is imported.

Hierarchy: large **BASTION ZERO** wordmark, **THE LAST HORIZON**
subtitle, Guardian/horizon hero art, mission controls (prominent NORMAL
and correctly locked ELITE), alloy/runs/wins/best progression strip,
real HULL/DAMAGE Research, LOW/FULL graphics control, offline/no-ads
footer. All controls remain native, touch-sized and scrollable at 720x1280.

## Constraints and acceptance

- No paid systems, ads, network permission, telemetry or login.
- Offline, J8 low-FX compatibility; static texture art and native UI only.
- Real boot image must load without unsupported vector boot format.
- The old triangle is gone; app icon, cold startup, Hangar, gameplay
  unmistakably share the circular cyan Guardian and arc language.
- Stage unlocking, alloy purchases, low/full FX and saves unchanged.
- GitHub CI validates SVG/PNG resource import, button/signal wiring,
  and previous full combat smoke tests. Physical cold-start/visual
  screenshots and hangar scrolling must be reviewed on J8.

## Makefile-only J8 testing

```powershell
make phase-g
make phase-g-doctor
make phase-g-screenshot
make phase-g-logs
```

A physical screenshot after cold start verifies the Hangar but cannot
fully validate the *transient* native boot splash; a short screen recording
is more appropriate for that part.

## Android launcher integration

The Phase G **Android** export preset explicitly supplies native launcher PNGs,
not only the desktop-facing `icon.svg`:

- `guardian_launcher_192.png` — 192×192 complete emblem;
- `guardian_adaptive_foreground_432.png` — 432×432 transparent Guardian layer;
- `guardian_adaptive_background_432.png` — 432×432 navy background.

This gives Android 10 launchers the correct adaptive icon. Other milestone
presets remain unchanged, so old test builds are not unexpectedly rebranded.
