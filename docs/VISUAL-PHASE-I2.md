# Phase I.2 — Tactical Level-Up Choice

**Reference:** user-provided four-panel Bastion Zero tactical UI sheet.
This phase implements the third panel (**Level-up choice**), following I.1
Combat HUD; menu/title and enemy codex remain later independent phases.

## Implemented

- New lightweight native `EvolutionChoiceView` uses the reference's
  **LEVEL old → new**, **CHOOSE ONE**, paused combat, three stacked
  colored upgrade cards, synergy footer and deep-navy panel hierarchy.
- Each card uses a procedural static `UpgradeEmblem` (a shield, beam,
  relay, nova, volley or kinetic glyph), actual weapon accent color,
  catalog name, **true next-rank effect description**, owned/next rank,
  and rank pips. Tap any point on the card to apply its existing upgrade.
- Keeps the current `GameCatalog` and `Arena.choose_upgrade()` as
  authoritative. Stale/max-level offerings filtered and rejected as
  before, including guarded callback in Main. No fake active actions.
- Scrolling in a portrait-safe margin container; no fixed-height
  CenterContainer nor horizontally expanding label dividers.
- Zero extra per-frame animation. No external art asset dependency.
  Phase H splash, guardian, combat HUD, stress mode unaffected.
- Mockup REROLL and BANISH are intentionally **not shown** because the
  mechanics do not yet exist. They can be designed and added in a
  dedicated future gameplay feature, not as dead controls.
- Tests cover 3 actual clickable cards, icons, real descriptions, tier
  caps, rank-pips, click-to-choose gameplay transition and stale offers.

## Physical Galaxy J8

Branch: `feature/m1-visual-phase-i2-evolution`
Version: `0.9.1-phase-i2-levelup-debug`, Android code **21**.
Reuses the same Phase H / I.1 package ID
`com.dantesouza.bastionzero.phaseh`, avoiding another launcher icon.
Android CI verifies the original approved premium artwork.

```powershell
git fetch origin --prune
git switch --track origin/feature/m1-visual-phase-i2-evolution
make profile
make check-tools
make phase-i2
make phase-i2-screenshot
```

Accept when three tappable cards fit the J8 width, text does not
clip, rank/cap information matches gameplay, the menu pauses combat
and selecting a card resumes with the correct rank applied. The
27 FPS observed on I.1 during crowded combat remains separate from
the static pause menu and needs later combat optimization.

## Phase I.2.1 — J8 typography correction

J8 screenshot review: keep **CHOOSE ONE** title size at the approved 39,
but increase weapon/support categories to 16, upgrade names to 26, next-rank
descriptions to 20, rank details to 18, synergy to 19, paused state to 17,
and small footer text to 15. Cards have a 215px minimum height, a smaller
top margin (66px), and 12px stack separation so three choices stay legible
in portrait. Card scrolling remains available. Regression tests explicitly
check that the CHOOSE ONE font remains unchanged.
