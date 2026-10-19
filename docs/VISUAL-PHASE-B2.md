# Bastion Zero — Visual Phase B.2: combat-aware Guardian

**Branch:** `feature/m1-visual-phase-b-guardian` (continues Phase B.1).
**Scope:** physical barrel alignment, muzzle light, visible upgrade count,
localized hull breach feedback. There is deliberately no balance change.

## Single source of truth

`GuardianRenderer.sentinel_barrel_count(gun_rank, volley_rank)` gives the
existing built-in Sentinel + dual-barrel rank + independent Saturation shots.

`GuardianRenderer.sentinel_muzzle(center, index, count)` preserves the
original centered 25-pixel barrel spacing and `y=-45` launch coordinate.
`Arena._fire_gun()` now calls it instead of duplicating the math.

When a physical round is appended to `projectiles`, an associated
`gun_visual_lanes` dictionary records its real muzzle, normalized actual
velocity and firing visual-clock timestamp. The Guardian renderer paints
the barrel along that exact vector, terminating at the same muzzle position.
The short flash appears only when real rounds were emitted.

On upgrading `gun` or `gun_volley`, the visual lane cache clears, and
the new barrel count is rendered immediately. Full-FX adds a narrow 14-px
tip streak; default J8 low-FX retains a short small flash.

A real hull breach sets `_guardian_damage_until` and the Guardian renderer
draws a short translucent red ring. This visual state does not create any
additional hitpoints, collisions, enemies, or damage calculations.

## Tests

Godot smoke assertions verify that the count agrees for base, dual and
Saturation levels; real gun projectiles and visual records agree exactly
at spawn; rendered aim vectors follow actual velocities; a breach creates
a feedback timer without changing its six points of health damage.

## Intentional non-goals

The original four cardinal module housings from B.1 remain structurally
static and anchored to the chassis. Barrel overlays themselves show the
physical firing paths. Prism still uses its existing collision-tested ray
origins; beam color/beam mounts are a future weapon-VFX task.
Enemy silhouettes and heavy HUD/upgrade panels are not part of B.2.

## Android (Make only)

From the Phase B branch after `git pull --ff-only`:

```powershell
make check-tools
make phase-b
make phase-b-doctor
make phase-b-screenshot
make phase-b-logs
```

`make phase-b` selects the latest **successful** Phase B ARMv7 APK,
verifies SHA256, and reinstalls only the Phase B test application.
Saves are disposable during these early graphics tests.
