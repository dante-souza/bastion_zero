# Bastion Zero — Phase F: high-pressure QA and tactical Evolution UI

This is a substantial combined development step on top of the accepted Phase E
compact HUD, prompted by a live J8 test showing a readable but nearly empty
arena at 9–22 seconds and 100% remaining hull.

## NORMAL 01 pressure showcase

- Starts at LV12 with gun 4, Prism/Comet/Arc/Nova 2 and rate/power/reach 1.
- Scripted introductions: **9** foes at deployment, **8** at 4s,
  **10** at 8s, **12** at 12s, **9** at 18s (including **one elite plus escorts**),
  and **10** at 22s. These scripted beats can overlap naturally with surviving foes.
- Regular authored formations start **12s**, rather than 24s, and deploy
  every ~**1.20s** thereafter, subject to the existing 84-enemy cap.
- All showcase foes have **1.65× baseline HP, 1.18× speed, 1.35× hull breach
  damage**. Authored scripted light foes receive an additional 2.8× HP,
  while the early scripted elite receives an additional 2× HP.
- Only `Arena.begin_run(..., showcase=true)` with NORMAL 01 opts in.
  Normal regular play and ELITE 01 retain the existing balance.
- This stage is now intended to be a *stress-test*, not a gentle demo.
  More simultaneous enemies and weapon effects may expose J8 frame drops.
  Capture real FPS under pressure before claiming stable performance.
- Same real hitboxes and weapon balance. Spawns remain bounded by `MAX_ENEMIES`
  and simulation time pauses during level-up decisions.
- QA overrides are explicitly **temporary** until real progression design.

## System Evolution — Phase F

`EvolutionProfile` introduces color/role/rank UI tokens without owning any
combat rules. The selection screen now displays level, alive threats and kills,
pauses gameplay as before, and keeps only eligible upgrade options.
Cards retain 186px touch targets with a thick category-color edge:
Sentinel cyan, Prism magenta, Comet amber, Arc blue, Nova jade, support
steel/gold. Each card shows tactical role, upgrade name, precise
`OWNED n/N → NEXT n+1/N` text, pips, and a plain-language mechanical
description. The footer reports only *currently unlocked* synergy pairs,
instead of advertising unavailable combinations.

All card hit areas remain a single native Godot Button. No nested clickable
layers, subscriptions, assets or monetization.

## Android

Dedicated Phase F ARMv7 package:
`com.dantesouza.bastionzero.phasef`. Makefile-only:

```powershell
make profile
make check-tools
make check
make phase-f
make phase-f-doctor
make phase-f-screenshot
make phase-f-logs
```

This build must pass both Godot smoke validation and Android export CI before
installation. Observe heavy effect rendering, enemy ceiling, remaining hull and
upgrade modal on J8.
