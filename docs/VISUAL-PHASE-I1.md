# Bastion Zero — Phase I.1: tactical combat HUD

The user-supplied four-panel screenshot establishes the visual target.
This first subphase implements **combat HUD only**; the level-up, title menu,
and threat codex are separate next subphases.

- Native `TacticalHud` with compact stage/time and hull/level/kills,
  touch-safe pause button, real formation/event banner, real live-elite
  health bar, level XP, FPS, and 5 always-present weapon-rank status slots.
- Sentinel cyan, Prism magenta, Comet amber, Arc electric blue, Nova jade.
  Inactive weapons are dimmed; cards are **not** falsely interactive.
- `Arena.snapshot()` reports `elite_hp`/`elite_max_hp` from a live elite.
  The health bar is conditional, uses actual damage, and disappears on death.
- Status updates follow the existing `Arena.stats_changed` signal every
  ~0.15s. No new per-frame HUD animations or gameplay loops.
- Tactical HUD uses small independent top/banner/boss/tray overlays,
  rather than tall continuous panels. Touching battlefield enemies still
  uses the existing focus handler.
- The Phase H approved cinematic splash, icon and repaired Hangar remain
  unchanged. Phase F showcase pressure and gameplay remain unchanged.
- The image reference's Warden, reroll, banish and other unimplemented
  features are **not** being fabricated as cosmetics.

## Same Android app for the J8

Branch: `feature/m1-visual-phase-i1-combat-hud` (stacked on Phase H).
Artifact: `Bastion-Zero-Phase-I1-J8-ARMv7`.
Version: `0.9.0-phase-i1-tactical-hud-debug`, Android version code 20.
**Reuses package `com.dantesouza.bastionzero.phaseh`** to avoid adding
another launcher icon. Saves are disposable in this debug run. APK signing
is controlled by the existing GitHub CI keystore.

```powershell
git fetch origin --prune
git switch --track origin/feature/m1-visual-phase-i1-combat-hud
make profile
make check-tools
make phase-i1
make phase-i1-doctor
make phase-i1-screenshot
```

On-device verification: actual counts/time, real elite health changes,
warnings and weapon ranks, pause, tap-to-focus outside HUD, and steady
FPS during the Phase F stress showcase. Physical J8 verification remains
necessary beyond automated tests.
