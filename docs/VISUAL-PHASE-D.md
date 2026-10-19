# Bastion Zero — Phase D weapons and NORMAL 01 engine showcase

**Branch** `feature/m1-visual-phase-d-weapons`, based on Phase C.
**Goal:** make each of the four unlockable weapons immediately identifiable
in a physical J8 playtest, with all effects tied to actual combat events.

## Phase D visual contract

- Sentinel: cyan `#31D6FF` real projectile streak + small white nose.
- Prism: magenta `#FF56DD` linear ray. Both render endpoints are the same
  endpoints used for penetration collision testing; a thin white core remains.
- Comet: amber nose, short orange exhaust, warm impact rings/sparks.
  Rockets still home and fragment according to existing mechanics.
- Arc: blue-lavender zigzag connects exact real chain endpoints. This is a
  stylization of an already-calculated damage jump; the low-FX version uses
  six sections and full-FX ten. Gameplay hit determination is unchanged.
- Nova: jade `#47E7A8` expanding translucent circle and luminous outline,
  only at the actual chosen area-damage center and radius.
- `WeaponEffects` owns all projectile/effect drawings, while `Arena`
  retains *all* damage, collision, weapon priorities, ranges and firing cadence.
- Effects have no bloom shader, runtime textures or random draw calls;
  low-FX draws fewer strokes, no heavy fills.

## Temporary NORMAL 01 visual showcase

**Only the Phase D build's NORMAL 01 deployment** passes `showcase=true`
to `Arena.begin_run`, which defaults to `false` for all ordinary call sites.
The global toggle `GameCatalog.STAGE_ONE_SHOWCASE` is explicitly temporary
and set to true only while collecting visual/engine QA screenshots.

- Start at **player level 7** with Sentinel rank 3 (two barrels),
  Prism rank 1, Comet rank 1, Arc rank 1, Nova rank 1.
- Spawn one grunt, one runner, one tank at the very beginning so distinct
  colors and engine effects are visible rather than waiting on formations.
- Spawn an elite at 14 seconds to expose its Phase C segmented silhouette.
  This is visual-test only; the real Stage 2 boss rules are untouched.
- Initial enemies still use their real health/radii and can be shot/killed.
  Existing wave formations continue to appear, so the game is fully playable.
- QA HUD uses a compact weapons counter to keep the bottom panel readable.
- All persistent economy/save logic, regular NORMAL 01 without the showcase
  argument, and ELITE 01 remain untouched.

**This is not final game progression**. Disable the showcase flag and
revisit stage balance when the graphics are accepted.

## Validation + J8

Smoke tests check real original combat damage, magenta Prism effect,
Arc endpoint alignment, jade Nova pulse, mixed showcase spawns/levels and
normal-play compatibility. `make check` and GitHub Android CI are gates.

```powershell
git fetch origin --prune
git switch --track origin/feature/m1-visual-phase-d-weapons
make check-tools
make phase-d
make phase-d-doctor
make phase-d-screenshot
make phase-d-logs
```

If the branch already exists, switch locally and fast-forward instead of
re-running `--track`. Saves in the isolated Phase D package are disposable.
