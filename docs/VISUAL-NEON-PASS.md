# Neon pass: living maps, glow and transitions

Rendering only. No enemy, weapon, card or balance logic changed
(`make sim-sectors` prints the same table as before this branch).

## What changed

| Area | Before | After |
|------|--------|-------|
| Arena backdrop | ~40 CanvasItem polygons/lines rebuilt by GDScript every frame | one full-screen shader, `shaders/sector_backdrop.gdshader`, animated by `TIME` (no per-frame GDScript) |
| Maps | same blue sky, only the horizon shape differed | each sector has its own scene (table below) plus a scrolling perspective floor, rising motes and a pulse that runs along the horizon |
| Units | flat strokes | `NeonGlowLayer`: one additive radial quad under each enemy and the Guardian (shots and blasts too on FULL) |
| Menus | opaque dark panels | panels are translucent over an animated violet MENU backdrop; neon borders via StyleBox shadow |
| SECTORS | text buttons | map cards with a live cropped preview of the sector's own backdrop |
| Transitions | instant swaps | every screen fades and lifts in (0.22 s); deploy fades in from black behind a scan line and shows a mission card (sector, place, field rule) |

| Sector | Scene | Moving element |
|--------|-------|----------------|
| NORMAL 01 Last Horizon | horizon | floor, motes, horizon pulse |
| ELITE 01 Last Horizon | aurora | two violet ribbons over the upper field |
| SWARM 02 Cinder Rift | rift | slow, soft fissure down the middle; fast falling streaks (FULL) |
| SIEGE 03 Iron Shelf | foundry | hex plating lit by a scanning bar; struts under the shelf |
| AMBUSH 04 Drop Zone | radar | sweep and range rings around the Guardian |
| ELITE 02 Null Expanse | null | void-eye arcs, drifting fog (2 octaves on FULL), stars (FULL) |

Palette rule holds: every backdrop color, including the new per-sector `accent`
and the MENU colors, is cool or near-neutral; tests enforce it. Glows reuse each
unit's own tint, so warm halos are always hostile.

## Cost on the J8 (not measured on device yet)

- [Provável] CPU goes **down**: the old backdrop was the biggest per-frame
  GDScript draw block; the shader needs none. The glow layer adds one
  `draw_texture_rect` per enemy (84 max) and batches into few draw calls,
  since every quad shares one 64 px texture.
- [Provável] GPU goes up: one full-screen fragment pass of roughly 60-120
  ALU ops per pixel, plus overdraw from the glow quads. Adreno 506 should
  absorb it, but this is the thing to watch.
- [Chute] Net FPS in the Elite fight stays near today's 27-28.
- Quality toggle: the existing **VISUAL FX: LOW (J8) / FULL** setting.
  LOW drops motes, streaks, stars and the second fog octave, and draws glow
  only under units and the Guardian. Every map keeps its scene on LOW.

Check on device with `make fresh` then `make logs` (the `BastionZero perf:` line).
If FPS drops, the first knobs are `NeonGlowLayer.UNIT_SPREAD` (overdraw) and
the `floor_alpha`/motes blocks in the shader.
