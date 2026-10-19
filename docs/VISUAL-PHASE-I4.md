# Phase I.4 — Threat Language / Field Guide

**Design reference:** the Threat Language screen in the user's four-panel
Bastion Zero tactical concept sheet, adapted truthfully to gameplay.

## Actual in-game vocabulary

- Guardian blue/cyan with shield horizon; colored weapon effects.
- **HOSTILE Grunt:** bright green ring (not loot).
- **HOSTILE Runner:** orange downward-pointing wedge with side-to-side motion.
- **HOSTILE Tank:** yellow square with central armor diamond, slower than Runner.
- **HOSTILE Elite:** magenta quarter-rings with orange outer ring, high HP.
- Gold ring = tapped targeting focus; jade ring = slowed status.
- Mint bar = health on damaged targets, tanks and elites.
- Red breach = hull damage; orange banner = real incoming formation.
- Experience is credited automatically on enemy kills: **no dropped XP
  diamonds or collectible shards** exist, so we don't depict any.

All exact hue tokens come from `VisualProfile` and the existing
`EnemyRenderer` / `Arena`, not mockup-only or future mechanics.

## Real navigation and pause safety

- Tactical Title retains the three approved HANGAR / SECTORS / SETTINGS
  buttons plus a small separate **THREAT GUIDE** action.
- Guide is a scrolling, native 2-column card collection with real glyphs,
  readable descriptions and a genuine RETURN button.
- Combat Pause gains a THREAT GUIDE action too. It **returns to Pause**
  with the arena still paused; only explicit RESUME restarts combat.
- `ThreatLanguage.banner()` and `color_for_event()` provide contextual
  live combat warnings: red breach, magenta elite, yellow armored,
  orange incoming waves. No fake countdown or special boss abilities.
- No new combat loops, no new per-frame draw work, no network dependencies.

## J8 / Gitflow

Branch `feature/m1-visual-phase-i4-threat-language`, stacked on I.3.
Version `0.9.3-phase-i4-threat-language-debug`, Android version code 23;
same package `com.dantesouza.bastionzero.phaseh` as I.3. Existing premium
art and app icon remain. GitHub CI validates and builds ARMv7.

```powershell
git fetch origin --prune
git switch --track origin/feature/m1-visual-phase-i4-threat-language
make profile
make check-tools
make phase-i4
make phase-i4-screenshot
```

Acceptance: title opens/returns guide, correct green hostile labeling,
portrait scrollable guide, pause opens/returns without unpausing,
formation alerts remain readable, combat frame rate remains comparable.
