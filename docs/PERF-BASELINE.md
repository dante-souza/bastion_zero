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
