# Bastion Zero — D.1 + E: guided level-12 showcase and compact HUD

This implementation follows physical J8 feedback: bright Sentinel bullets
appear clearly but Prism, Arc and Nova are easy to miss in a still image; the
two blue UI panels occupy too much of the vertical field.

## D.1 — temporary NORMAL 01 QA mode

Only NORMAL 01 deployed via the hangar starts with level 12, Sentinel 4,
Prism 2, Comet 2, Arc 2, Nova 2, and rate/reach/power 1. Stages outside
showcase mode are unchanged. `STAGE_ONE_SHOWCASE=true` in `GameCatalog`
is deliberately temporary. It must be removed before final progression release.

Guided intro:
| Time | Targets | Intent |
| --- | --- | --- |
| 0 s | Grunt / runner / tank, spread out | Identify outlines and first gunfire |
| 4 s | Pair of runners | See Arc jumping |
| 8 s | Two tanks | Differentiate Prism and Comet |
| 12 s | Mixed compact pack | Catch Nova's area pulse |
| 20 s | One elite | Inspect distinct elite symbol |
| 24 s | Begin original authored wave system | Actual performance and difficulty |

Scripted small targets get *3x HP for showcase visibility only*, not new
weapon damage behavior. Gameplay and XP still use their real encounter data.
The simulation clock controls the timed beats, so pause and upgrade dialogs
pause them. No background timers were added.

## D.1 weapon FX

Prism rays are thicker and last 0.36 s in QA (0.21 s normal), electric Arc
lasts 0.48 s in QA (0.32 s normal), Nova's jade radius stays visible 1.05 s
in QA (0.76 s normal), Comet has a stronger amber nose/trail and short
impact pulse. Art continues to use exact simulation muzzle/endpoints and
true Nova radius. Low-FX avoids the optional full-FX transparent fills and
uses 7 electric segments, versus 12 in full-FX.

## E — compact HUD

`scripts/hud_profile.gd` contains the reference 720x1280 logical viewport
bounds and touch minimum:
- Top: y=8..114, **106 px** versus 150 px before (29% less)
- Bottom: bottom-relative y=-92..-12, **80 px** versus 110 px (27% less)
- Pause: 55x44 minimum, retains finger accessibility
- XP: thin 11-px colored progress bar
- Compact HUD panels use 14px side / 9px vertical insets; modal screens
  retain the original larger design.
- Important data—stage/time, hull, level, kills, events, weapons/FPS, XP—is
  retained. Shorter labels keep the combined demo readable.

## Deployment and test

On the existing Phase D branch, fetch and track the new stacked
`feature/m1-visual-phase-e-hud` branch. All device operations use make:

```powershell
make profile
make check-tools
make phase-e
make phase-e-doctor
make phase-e-screenshot
make phase-e-logs
```

Compare frame(s) from 0–4 s, 8–12 s and 20–24 s, in LOW and FULL FX.
The Galaxy J8 target is a stable frame rate under high effect load—not an
assumed fixed 60 FPS based on one screenshot. Phase E uses a separately
installable ARMv7 package; progression saves are disposable at this stage.
