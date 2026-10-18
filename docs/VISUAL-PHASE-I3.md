# Phase I.3 — Tactical Title/Menu

User-approved first panel from the Bastion Zero tactical UI reference,
adapted to the existing electric-blue Guardian / Last Horizon brand.

## Implemented

- A dedicated `TitleMenuView` becomes the actual starting screen (instead
  of entering the research Hangar automatically).
- BASTION / ZERO split wordmark in warm gold and muted mint, subtitle
  DEFEND THE LINE, sparse geometric enemies and thin cyan horizon below
  the real `assets/guardian_phase_b3.svg` silhouette.
- One large mint **DEPLOY** action starts NORMAL 01; best stage and run
  count reflect saved progress, not placeholder scores.
- Three genuine bottom navigation buttons:
  **HANGAR** opens existing research/progression screen, now with a title
  return button; **SECTORS** shows playable NORMAL 01 and ELITE 01 with
  the existing saved unlock rule; **SETTINGS** exposes real LOW/FULL
  graphics selection that writes the existing `low_fx` setting.
- Results and abandon actions return to the new title instead of always
  jumping into the research Hangar.
- The title uses Godot-native, touch-sized buttons over a single static
  geometry illustration. No extra gameplay loops, online content,
  monetization, fake combat systems or screenshot-only controls.
- Phase I.2.1 font correction carried forward: larger descriptions, ranks,
  category text and support/footer fonts; **CHOOSE ONE stays 39**.
- All existing Phases I.1 HUD and H cinematic branding continue unchanged.

## J8 and Gitflow

Branch: `feature/m1-visual-phase-i3-title-menu`, stacked on I.2.
Android: `0.9.2-phase-i3-title-menu-debug`, code 22.
Reuses package `com.dantesouza.bastionzero.phaseh` — no extra home-screen
icon. GitHub CI validates the native menu and exports ARMv7 debug APK;
local Godot and manual asset import are not needed.

```powershell
git fetch origin --prune
git switch --track origin/feature/m1-visual-phase-i3-title-menu
make profile
make check-tools
make phase-i3
make phase-i3-screenshot
```

Device checks: title fits 720×1280, its three nav actions work, Elite remains
locked until cleared, both graphics modes still work, and normal DEPLOY
opens the full existing stress-test combat scene. Test enlarged evolution
card text separately; a little vertical scrolling is acceptable.
