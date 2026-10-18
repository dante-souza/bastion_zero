# Bastion Zero

**Bastion Zero** is an original Android-first, offline, no-ads, no-IAP directional tower-defense roguelite made with **Godot 4.4.1** (GDScript, GL Compatibility).

> **M1R v0.2.4 — System Evolution UI refinement.** The early radial-arena M1 design was rejected after comparing gameplay reference recordings. M1R contains a new combat runtime. GitHub CI validates code/export; only a physical J8 playtest can validate tactile gameplay and performance.

## Play the M1R demo

- **NORMAL 01**: defend the lower breach line against authored line, wedge, pincer, rush and armored formations in a ~96-second stage.
- **ELITE 01**: unlocked after winning NORMAL 01; ~115-second stage with tougher formations, an elite encounter that gains speed and summons escorts below 55% HP.
- Your **Guardian** starts with the **Sentinel Autocannon**. It fires fast individually simulated cyan rounds and remains viable with independent Kinetic Payload (damage), Sabot Piercer (pass-through), Ricochet Routing (bounces), Saturation Burst (separately aimed extra shots), plus the original cadence/dual-barrel/smart-tracking ranks. **Prism Beam** is separately acquired from level-up cards. Touch an enemy to prioritize it temporarily.
- Evolve four **original** weapons: Prism Beam (unlockable penetration + accurately targeted twin beam), Comet Volley (homing multi-rocket salvo + explosive/splitting missiles), Arc Relay (chains + stun), and Nova Field (slow pulse + blast).
- Every XP level-up pauses battle to offer three distinct build choices, including a Sentinel evolution and a new-weapon unlock while each is available. The taller System Evolution panel now shows separate category, weapon name, exact description, and **OWNED rank → NEXT rank**; fully maxed upgrades disappear from the offer pool. Synergies: Prism/Arc and Comet/Nova.
- Local alloy rewards and permanent hull/damage research; stage unlocks and graphics settings persist.
- Battle HUD shows hull, stage timer, XP, selected weapons and approximate FPS. After each run: damage breakdown by weapon.
- **Enemy counterplay:** tanks resist Prism Beam but take more Comet Volley and Nova Field damage; agile runners are vulnerable to Arc Relay. Hit feedback, wave cues and breach statistics are visible during combat.
- Low-effects mode is enabled by default for the **Samsung Galaxy J8 (Android 10, ARMv7)**.
- No reference-game assets, code or accounts are included. See [M1R design and acceptance](docs/M1R-DIRECTIONAL-DEFENSE-REBUILD.md).

### Quick start on desktop

Download Godot 4.4.1, open `project.godot`, press F5. On the hangar select **DEPLOY • NORMAL 01**. Pause with **II**, tap threats, select weapon evolutions and return after a run.

Headless checks:

```bash
godot --headless --path . --editor --quit --quit-after 240
godot --headless --path . --script res://tests/test_smoke.gd
godot --headless --path . --quit-after 10
```

## Samsung J8 APK

The build uses the 32-bit ARMv7 export preset. Routine device operations are **Makefile-only**. For the current Phase B.1 visual test:

```powershell
make phase-b
make phase-b-doctor
make phase-b-screenshot
make phase-b-logs
```

Phase B.1 ships as `com.dantesouza.bastionzero.phaseb` alongside Phase A and M1R. `make phase-b` downloads a SHA-256-verified APK from the matching GitHub Actions run, caches it in `dist/phase-b/`, reinstalls and launches. Development saves for the selected package are disposable.

See [Makefile-first Android routines](docs/LOCAL-DEVELOPMENT.md) for install overrides, safe profile selection, checks and troubleshooting.

**Debug signing**: If no persistent `BASTION_DEBUG_KEYSTORE_BASE64` GitHub Actions secret is configured, the CI pipeline generates an ephemeral key for each run. Android will reject an overwrite with mismatched signatures. Uninstalling first will erase Bastion Zero's local save. To preserve updates, configure a stable debug signing keystore (see `docs/ANDROID-SIGNING.md`) before continuing regular phone playtests.

## Local developer setup (Windows + ADB)

A `Makefile` and standard-library Python helpers provide safe updates and Galaxy J8 APK operations. See [Local developer workflow](docs/LOCAL-DEVELOPMENT.md). Quick commands from the repository root:

```powershell
make help
make profile
make phase-b            # fetch + reinstall + run Guardian Phase B.1 on J8
make phase-b-doctor
make phase-b-screenshot
make check-tools
make sync               # fast-forward local branches
```

The Make targets explicitly select J8 serial `38c19745` even when other phones are connected. Profile-aware targets keep M1R, Phase A and Phase B packages and APKs separate. During early visual development, saves may be erased; stable signing will matter once progression testing begins.

## Development flow

`feature/m1-playable-game` → Draft [PR #1](https://github.com/dante-souza/bastion_zero/pull/1) to `dev`, awaiting J8 gameplay validation. Then merge without squash and promote through normal Gitflow. Never merge reference third-party assets, extracted saves or binaries.

## License

Copyright (c) 2026 Bastion Zero contributors. Code licensed **AGPL-3.0-or-later** (`LICENSE`).

## Visual direction for next build

The [early-game visual direction](docs/VISUAL-DIRECTION-EARLY-GAME.md) is informed by the user's uploaded gameplay recording, without importing third-party art. **Phase A is implemented on `feature/m1-visual-phase-a`**: a near-black arena, a quiet playfield, a shallow electric-blue horizon, and minimal breach markers. Full-FX adds a restrained halo and sparse static speckles; low-FX omits them for the Samsung J8. The original Guardian and enemy drawing remain in place until the subsequent visual phases. See [Phase A implementation and validation](docs/VISUAL-PHASE-A.md).

## Guardian Phase B.1 — selected circular design

The first playable Guardian visual pass uses an **original procedural**
approximation of the user-selected blue circular lens, four cardinal mechanical
pods, segmented cyan/royal-blue armor rings and a smooth lower-arena radial glow.
The existing Sentinel projectile spawn positions and all combat behavior are
unchanged pending B.2 firing/aim alignment. No third-party art or generated image
is bundled with the APK. See [Phase B.1 specification](docs/VISUAL-PHASE-B1.md).

## Guardian Phase B.2 — combat-aware visuals

The Phase B branch now additionally aligns visually rendered Sentinel barrels
and muzzle flashes with the **actual fired projectile positions and velocities**.
Base, dual and Saturation upgrades display the appropriate barrel count, and
hull breaches pulse the Guardian's outer rim. This is strictly a presentation
layer; combat math is unchanged. See [Phase B.2 details](docs/VISUAL-PHASE-B2.md).

## B.3 visual-fidelity correction

After the first real J8 screenshot showed a Guardian that remained too close to
thin neon wireframe geometry, B.3 switches to a larger, original **SVG-based**
blue reactor chassis and strengthens the smooth lower-field navy aura. The
barrel and combat fidelity from B.2 remains intact. Run `make phase-b` after
updating the existing branch. See [B.3 notes](docs/VISUAL-PHASE-B3.md).

## Phase C — readable enemy silhouettes

Four combat categories are now drawn using original geometric shapes instead
of the earlier red/purple filled primitives: green hollow circles (grunts),
orange triangles (runners), yellow armored squares (tanks), and a larger
magenta/orange segmented elite sigil. All hitboxes and combat math remain
unchanged. Health-bar noise is reduced for undamaged basic enemies. See
[Phase C details](docs/VISUAL-PHASE-C.md). J8: `make phase-c`.

**Phase C J8 installation:** `make phase-c` after checking out
`feature/m1-visual-phase-c-enemies`. The APK's isolated package keeps existing
M1R/Phase A/Phase B installations independent.

### Phase D visual showcase (temporary QA)

To let us review all weapons and enemy types immediately in the Android build,
NORMAL 01 in the Phase D branch starts at **player LEVEL 7**, with the Sentinel
at rank 3 and Prism Beam, Comet Volley, Arc Relay and Nova Field at rank 1.
Three starter enemy types appear immediately; an elite visual test encounter
spawns at 14 seconds. Only this showcase launch has the boost; Stage 2 and
normal non-showcase logic are unchanged. `GameCatalog.STAGE_ONE_SHOWCASE` is
an explicit, temporary testing switch to disable before normal game balancing.

### Phase D — weapon effects

Prism Beam now draws magenta rays directly over its existing physical hit
segments; Arc Relay gets electric-blue zigzags through the same exact chain
endpoints; Comet Volley has amber rockets and short orange impact sparks; and
Nova Field paints a translucent jade pulse at its real area-damage center.
J8 LOW FX keeps only inexpensive shapes and shorter electrical paths.
See `docs/VISUAL-PHASE-D.md`.

**Phase D J8 deployment:** switch to the `feature/m1-visual-phase-d-weapons`
branch and run `make phase-d`. Isolated install: `com.dantesouza.bastionzero.phased`.
