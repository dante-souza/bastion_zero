undefined
**Phase I.2 — Tactical Level-Up Choice:** visually distinct native
three-card evolution screen with real upgrade effects, rank progression,
procedural icons and paused battle state. Phase I.1 HUD and premium
brand remain. J8: `make phase-i2` on the matching branch; installs over
Phase H/I.1 package without adding another icon.

## Phase I.3 — Tactical Title/Menu

The posted UI reference now drives a new native title landing page: warm/mint
two-line BASTION / ZERO wordmark, sparse threat shapes, cyan defensive
horizon, the original Guardian artwork, a large real DEPLOY action, saved
best-stage indicator, and real HANGAR / SECTORS / SETTINGS navigation.
Hangar research and FX, locked Elite stage selection, combat, saves, premium
app icon and cinematic splash all remain functional. Phase I.2's enlarged
upgrade-card fonts are included **without resizing CHOOSE ONE**. Run
`make phase-i3` after updating the branch.

## Phase I.4 — Threat Language / Field Guide

A native, offline field guide accessible from the tactical Title and Pause
screens teaches the actual Guardian, four existing enemy silhouettes and
combat statuses. Green Grunts are **hostile**, unlike the user reference's
green XP diamonds; Bastion Zero awards XP directly. Warnings now reflect
real breach (red), armored (yellow) and elite (magenta) events. The pause
codex returns to the paused game without starting combat. Same premium J8
app ID; `make phase-i4` deploys the new build. Details in
`docs/VISUAL-PHASE-I4.md`.

## Phase I.5 — Color Language

One rule for every pixel in combat: **cool is yours, warm is hostile,
green is XP only.** Grunts become rose rings (matching the title drifters),
Elites crimson, Prism violet, Comets ice-white and Nova teal, so no
weapon shares a hue with an enemy. HUD warning colors now come from typed
event kinds instead of message text, and a test guards the palette.
Same premium J8 app ID; `make phase-i5` deploys it. Details in
`docs/VISUAL-PHASE-I5.md`.

## Phase I.6 — Playtest Fixes

Fixes from J8 playtest screenshots: the combat header is compact and the
threat banner transient, so enemies are no longer hidden under a 213 px HUD
stack; level-up cards sit in the thumb zone, grow with their text, use
real per-rank copy and distinct icons; health bars only on Tanks, Elites
and the focused target; kill pops bloom to white instead of fading to
brown; Android back pauses or steps back instead of quitting mid-run.
`make phase-i6` deploys it. Details in `docs/VISUAL-PHASE-I6.md`.

## Neon pass — Living Maps

Each of the six sectors now has its own animated backdrop (aurora, rift,
foundry scan, radar sweep, null fog) drawn by one GPU shader, units carry a
cheap additive neon glow, menus float over an animated violet backdrop,
SECTORS shows live map cards, and screens fade in with a mission card on
deploy. Rendering only; VISUAL FX LOW/FULL stays the quality toggle.
Details and J8 cost notes in `docs/VISUAL-NEON-PASS.md`.
