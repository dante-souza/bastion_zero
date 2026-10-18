# Bastion Zero — Visual Phase B.1 (Guardian + smooth background)

**Branch:** `feature/m1-visual-phase-b-guardian` (stacked on Phase A).
**Goal:** A playable, original procedural rendition of the user-approved
four-module blue circular Guardian with an uncluttered near-black background.

## Visual translation and constraints

The selected reference has a central dark-blue glass lens, bright cyan eye,
thick cyan body ring, four roughly symmetric compass-direction mechanical pods,
segmented outer electric-blue armor and a smooth navy/black radial falloff.
Godot `CanvasItem` primitives reproduce these *shapes and visual language*
rather than embedding the reference image or a generated illustration.

- `scripts/guardian_renderer.gd`: independent static drawing helper, four
  compass pods, lens, nested metal/cyan/blue rings and subtle lens pulse.
- Outer ring radius 54 logical px; cardinal tips radius 72, safely inside the
  lower HUD boundary at y≈1158 when Guardian is at y=1080.
- `scripts/arena_background.gd`: single vertex-colored quad from near-black
  to midnight navy and a smoothly interpolated radial halo centered near the
  defending zone, with 20 triangles in J8 low-FX / 32 in full-FX.
- Existing Phase A electric-blue shallow horizon retained; no tile grid,
  heavy particle system, noise textures, shader bloom or image asset.
- `scripts/visual_profile.gd`: centralized B.1 palette, no new assets.
- `scripts/arena.gd`: only the old Guardian draw commands were replaced with
  `GuardianRenderer.draw_to(...)`; all combat logic stays as-is.

## Deliberately deferred to B.2

The top/bottom modules are stabilizers and left/right pods are visual mount
housings **only** in B.1. The Sentinel *still* launches from its existing
`G + Vector2(offset, -45)` points, and Prism uses its existing real beam
segment. Gun pods do not yet rotate toward enemy tracking vectors. Do not
mistake the approved static art for validated muzzle/target alignment.

B.2 will connect barrel position/direction, actual muzzle effects, damage
flash and upgrade-linked visuals to simulated weapons without altering combat
balance. HUD and enemy-shape refinements remain Phases E/C.

## J8 testing

```powershell
git fetch origin --prune
git switch --track origin/feature/m1-visual-phase-b-guardian
git pull --ff-only origin feature/m1-visual-phase-b-guardian
make phase-b
make phase-b-doctor
make phase-b-screenshot
make phase-b-logs
```

If the branch already exists locally, use `git switch feature/m1-visual-phase-b-guardian`.
For separate LOW/FULL comparisons use the hangar FX toggle before deploying.
Only mark the physical 30 FPS sustained target after J8 gameplay testing.

The Phase B.1 debug APK uses `com.dantesouza.bastionzero.phaseb` (ARMv7)
and has its own downloaded artifact/cache directory; saves may be erased.

## B.2 continuation

The same branch now continues with physical Sentinel barrel overlays, real tip flashes, upgrade count and hull-breach feedback; see [Phase B.2](VISUAL-PHASE-B2.md). B.1's note about deferred muzzle alignment reflects the original B.1 snapshot only.
