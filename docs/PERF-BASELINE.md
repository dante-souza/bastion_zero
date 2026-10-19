# Performance baseline (after I6)

Goal: find where the 27–28 FPS in the J8 Elite fight comes from before adding
mechanics. Nothing here changes gameplay or visuals.

## What changed

- **Bullet-vs-enemy sweep** (`Arena._move_projectiles`) reads enemy ids,
  positions and radii from packed arrays copied once per tick, with a box
  reject before the swept-segment test. Before, every bullet/enemy pair did
  several String-keyed Dictionary lookups.
- **`_index_by_id`** is O(1) through a self-validating id → index cache, so
  `_damage_by_id` and homing no longer scan the enemy list.
- **Nova cluster search** (enemies × enemies) runs on the same packed
  positions with squared distances.
- **Backdrop** (gradient, aura fan, horizon) draws on its own `Backdrop`
  child behind combat. In LOW FX it is recorded once per run instead of every
  frame; FULL FX still redraws it for the halo pulse.
- **Perf probe**: every 2 s while a run is live the game prints one line to
  logcat:

  ```
  BastionZero perf: fps=28 sim=0.90ms/tick ticks/frame=2.00 draw=3.10ms process_ms=… draw_calls=… primitives=… enemies=… bullets=… fx=… low_fx=true showcase=true
  ```

  `sim` and `draw` are this game's own script time; `process_ms`,
  `draw_calls` and `primitives` come from the engine.

## Desktop numbers (headless, same machine, `tests/bench_combat.gd`)

| Scene | Before | After |
|---|---|---|
| NORMAL 01 showcase, 30 s, per physics tick | 110–134 µs | 60–68 µs |
| Saturated: 84 enemies × 220 bullets, per tick | 13.2–13.4 ms | 2.2 ms |
| Elite fight `_draw` recording, per frame | — | ~0.33–0.43 ms |

Outcome check: 60-second runs of NORMAL 01 and ELITE 01, showcase on and off,
end with identical kills, XP, hull, breaches and per-weapon damage before and
after. [Certo]

## Reading it

- [Provável] The showcase scene is not CPU-bound in script. Desktop script
  cost is under 0.5 ms per frame; even at 10× slower on the J8's Cortex-A53
  that is ~5 ms of a 36 ms frame. The rest would be the engine's canvas
  work and the GPU.
- [Certo] The saturation case was a real cliff: 84 × 220 would have cost tens
  of ms per tick on the J8, and Godot runs extra physics ticks when frames are
  slow, which makes it worse. It is ~6× cheaper now.
- [Chute] The brief's beam/arc scans are not hotspots: they fire a few times
  per second and cost tens of µs each.

## Next measurement on the J8

1. `make phase-i6` equivalent for this build, play NORMAL 01 (showcase on)
   into the Elite, then ELITE 01 (no showcase), then `make logs`.
2. Compare frame time (1000 / fps) to `sim × ticks/frame + draw`:
   - If the script share is small, the cost is in rendering. Next step:
     cut draw calls per enemy (cached per-enemy canvas items, fewer
     antialiased arcs), guided by `draw_calls` and `primitives`.
   - If `sim` is large, the next step is a spatial grid for the sweep.
   - If `ticks/frame` sits near 2, physics is catching up for slow frames;
     fixing the frame cost fixes that too.

## Step 2: baked enemy bodies (after the neon pass)

The J8 Elite fight (ELITE 01, HARD START, LOW FX) ran at 20–24 FPS with
~30 enemies and 14–17 FPS with 40–49. Our own drawing took 15–24 ms per
frame, and slow frames triggered up to 4 catch-up physics ticks each.

- **Enemy bodies are baked once** (`EnemySpriteCache`, a 2× atlas on a
  SubViewport) and stamped by `EnemyBodyLayer` as one textured quad each.
  One texture and one material for the whole swarm, so it batches. The
  per-frame parts (slow, flash, focus, health bar, Elite pulse and rage)
  stay vector in `EnemyRenderer.draw_overlays`.
- **Catch-up capped at 2 ticks per frame**
  (`physics/common/max_physics_steps_per_frame=2`, was 8). A heavy frame
  now slows the game a little instead of making the next frame heavier.
- New enemy kinds opt in with `EnemySpriteCache.register(kind, half_extent,
  paint)`; a kind nobody registers keeps vector drawing.

Desktop, real renderer (xvfb + opengl3), 45 enemies incl. an Elite, LOW FX:

| | Vector | Baked |
|---|---|---|
| Draw calls per frame | 349 | 11 |
| Primitives per frame | 10,276 | 473 |
| Script draw time | 1.4–1.5 ms | 0.36–0.43 ms |

Pixel comparison of every kind in both FX modes: identical apart from
edge antialiasing (0.1% of pixels differ visibly). [Certo] Expected on the
J8 [Provável]: draw script falls from ~16–24 ms to ~4–6 ms in the Elite
fight. Confirm with `make perf-clean`, play, then `make enemies`.
