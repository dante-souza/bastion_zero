# Bastion Zero — Visual Phase C: enemy silhouettes

**Branch:** `feature/m1-visual-phase-c-enemies`, stacked on Phase B.3.
**Goal:** distinguish threats instantly using shape **and** hue on Samsung Galaxy J8.

## Original geometry

| Kind | Visual language | Simulation radius |
|---|---|---|
| grunt | Lime #52F52A bright hollow circle with cyan center | 16 |
| runner | Orange #FF9A37 forward-pointing hollow triangle | 12 |
| tank | Gold #F4DE45 square outline, nested diamond shield | 27 |
| elite | Magenta #F66AD9 with orange perimeter and four segment arcs | 48 |

`scripts/enemy_renderer.gd` centralizes drawing only. Small runner/grunt
silhouettes extend to >=19 logical px for visual clarity; actual collision,
touch-focus radii and damage calculations continue using unchanged enemy
`radius`. There are no new shaders, particles, textures, or sprite atlases.

State readability is preserved: jade ring when slowed, white brief hit arc,
amber target-lock arc, red larger elite-enraged arc. Health bars still use the
real `hp/max_hp` and appear on all armored/elite enemies, all focused enemies,
and damaged light enemies. Full-health unfocused grunt/runner bars are hidden
to reduce battlefield noise. Combat data is never hidden from focused targets.

Low-FX avoids translucent runner fill and optional elite halo; only compact
polyline/arc geometry is used. The 84-enemy ceiling and all existing hit
logic, formations, stats, upgrades, and balance remain intact.

## Validation

Automated Godot smoke tests check palette/shape/size contracts, real collision
radii, HP display conditions, and existing combat invariants. J8 physical
validation should compare grunts, runners, tanks and ELITE 01 on LOW/FULL
FX, with the existing 60-FPS HUD sampled over sustained dense waves.

From repository root on Phase C branch:

```powershell
make check-tools
make check
make phase-c
make phase-c-doctor
make phase-c-screenshot
make phase-c-logs
```

Only Git commands are needed to switch/sync branches; phone operations
remain Makefile-only. Phase C has an isolated `com.dantesouza.bastionzero.phasec`
debug package. Development saves can be erased.
