# Bastion Zero — Visual Phase A: arena and horizon

**Status:** Code implemented on `feature/m1-visual-phase-a` (2026-10-18); CI and physical device checks are acceptance gates, not presumed to have passed.

## Scope and visual contract

- Source-only procedural artwork for a 720 × 1280 logical portrait battlefield.
- Replace the previous blue-gray battlefield with near-black `#020509`.
- Remove the visible 80 px tile grid, opaque upper spawn strip, opaque lower strip, and bright full-width red breach rule.
- Add an electric-blue `#168BFF` horizon, sampled as a symmetric smooth curve: crest `(360, 990)` and edges at `y = 1120`. It draws **behind** the current Guardian, so it remains a pure visual layer.
- Preserve small red tick marks at `BREACH_Y = 1040`, showing where enemies breach without implying that the curved horizon itself is a collision boundary.
- In full-FX mode only: two soft, transparent halo strokes and 12 faint, fixed speckles; no particles, bloom shader, randomness, or external textures.
- In default low-FX (Galaxy J8) mode: omit halo and speckles; draw only two clean blue strokes and the boundary ticks.

## Architecture

`scripts/arena_background.gd` owns pure curve sampling and draw commands; `scripts/visual_profile.gd` owns color tokens. `Arena._draw()` calls `ArenaBackground.draw_to(self, low_fx, _visual_clock)` before the unchanged Guardian, enemies, projectiles, and effects.

**Unchanged:** `GameCatalog.WORLD_SIZE`, `GUARDIAN`, `BREACH_Y`, all waves/formations, targeting, weapon fire, collision checks, hit points, controls, stage progression, and saves. The horizon is illustrative, not gameplay geometry.

## Validation

Automated (GitHub action **Godot validation** on feature-branch push):

```bash
godot --headless --path . --editor --quit --quit-after 240
godot --headless --path . --script res://tests/test_smoke.gd
godot --headless --path . --quit-after 10
```

Added smoke assertions: exact near-black palette, bounded 49-point curve, symmetry, full-field span, and crest/edge placement relative to the original breach threshold.

Manual desktop/J8 checks still required:

1. Launch NORMAL 01 and ELITE 01; verify no grid, rectangular bands, or thick red rule in either.
2. Confirm the blue shallow arc appears *behind* Guardian; Guardian/enemies remain visible with heavy combat.
3. Toggle LOW and FULL FX from hangar; LOW must show neither halo nor speckles.
4. Walk an enemy into the breach: it must register at the same old straight threshold `y = 1040`, **not** when crossing the arc.
5. Inspect touch targeting, pause, upgrade modal, victory/loss, and return to hangar.
6. On physical J8, check sustained 30 FPS target during dense waves and capture screenshots of both FX settings.

## Exclusions

No Guardian silhouette redesign (Phase B), enemy redesign (C), weapon rendering overhaul (D), HUD overhaul (E), or System Evolution overhaul (F). No reference-game footage or art committed.
