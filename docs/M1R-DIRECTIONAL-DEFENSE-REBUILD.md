# Bastion Zero — Milestone 1R: directional defense rebuild

Status: **M1R implementation in progress** · 2026-10-17

## Why the first vertical slice is not acceptable

The current Godot M1 prototype has a core at world center and enemies spawn around a radial arena. This is not the desired gameplay. The PR remains **Draft**; passing CI validates code and export only, not the correct game design.

### Evidence available

- User-supplied gameplay videos: `simplified version.mp4` and `Rogue Defense_ Hybrid Tower TD - Tips, Cheats, and Strategy Guide!.mp4`.
- Installed app package `com.cyberjoy.x3`: `base.apk`, `split_UnityDataAssetPack.apk`, `split_config.arm64_v8a.apk`. APK integrity verified.
- Unity 2022.3 with IL2CPP. Asset-bundle filenames distinguish bullets, enemies, guardian/role, turret, core, dome and battle scenes. **Asset bundle counts are not mechanics counts.**
- G41 external-data `.bin` file is a *possible* save, not a proven or portable player-save backup; do not commit save files, account data, or third-party assets.

### What the video visibly supports

1. Portrait battlefield with a Guardian near the bottom, while enemies advance primarily from the upper region.
2. Geometric enemy silhouettes and bright, long-range laser/projectile/area-effect attacks.
3. Numbered Normal/Elite stages, elapsed time/stage progress, on-screen health and pause controls.
4. Three-card level-up decisions; observed labels include Cruise Shooting, Heavy Cruise, Bullet Explosion, Penetration Boost, Volley Missile, Distortion Field.
5. An out-of-battle ecosystem with Guardian, Skill, Chips, Gear and Loadout views, and combat damage statistics.
6. Ad-linked refreshes and other monetization in the reference; **not to be replicated**.

The videos do **not** establish exact spawn tables, probability distributions, formulas, serialization, controls for moving the Guardian, or which bundled assets are actively used.

## Our independent game design decisions

The following are **proposals for Bastion Zero**, not claims about how Rogue Defense is implemented.

### A. Battlefield and controls

- Maintain a Godot 4 Android-first portrait field, logical resolution 720×1280.
- Defender/Guardian anchored near `(360, 1090)`. Enemies enter across a spawn band on the upper edge, flowing towards a defended lower zone; no 360-degree radial spawning.
- Landscape has a combat HUD with stage/time/progress on top, hull near bottom, weapon icons and pause.
- Primary fire is automatic. Tapping an enemy prioritizes it temporarily; default targeting is nearest **threat to the defended zone**. Do not assume the Guardian is movable unless explicitly chosen later.
- Three enemy silhouettes with distinct speed/health/behavior, plus one elite variation in the milestone.

### B. Weapon and upgrade identity

Build four original weapons with visually different trajectories and targeting rules:

| Weapon | Base behavior | Meaningful upgrades |
|---|---|---|
| **Prism Beam** | focused upward beam | penetration, additional beam, temporary overcharge |
| **Comet Volley** | multi-projectile salvo | side volley, split-on-hit, explosion |
| **Arc Relay** | jumps between nearby enemies | more jumps, stun, chain range |
| **Nova Field** | timed area pulses | larger radius, slow, explosive detonation |

- Give 3 distinct upgrade choices per level up. Each upgrade modifies observable gameplay (counts, pattern, geometry, control effect) and may also modify numbers.
- At least 2 cross-weapon synergies; transparent prerequisites; no ad-driven rerolls.
- Separate design data from rendering and combat runtime to facilitate balancing and tests.

### C. Stages and progression

- M1R must ship **two playable stages**: Normal 1 (intro/formation progression) and Elite 1 (denser formations + a distinct elite encounter), or an equivalent short two-stage demo.
- Each stage has a deliberate beginning, wave/spawn timeline, difficulty escalation, success/failure, and after-action damage-by-weapon statistics.
- Rewards are fixed earned alloy, not purchased currency.
- Reuse save infrastructure, but version/migrate the data schema when adding stage unlocks, loadouts and build records.
- No ads, IAP, subscriptions, behavioral monetization, online login or copied proprietary content.
- More extensive chip/gear crafting, branching campaigns and broad guardian progression remain future milestones; show only fully implemented menus.

### D. Android constraints

- Samsung Galaxy J8 SM-J810M, Android 10, **armeabi-v7a**, is the low-end primary acceptance device.
- Moto G41 Android 12 can be used as a secondary Android test device.
- Use Godot GL Compatibility and inexpensive geometry/effects. Offer a reduced-effects option and visible FPS diagnostics in debug builds.
- **Before distributing repeat builds, configure a stable signing identity**; today's CI-generated keystore causes Android signature mismatch and requires an uninstall that deletes test saves.

## Milestone acceptance tests

- [ ] An APK launches and accepts touchscreen input on J8.
- [ ] Guardian visibly defends the **bottom** of the field against enemies advancing from **above**.
- [ ] Both stages can be won and lost, with distinct enemy formations and an elite encounter.
- [ ] All four weapon families and at least two cross-weapon synergies are observable in combat.
- [ ] Level-up pauses/interrupts play appropriately and offers three actionable choices.
- [ ] Upgrade options have genuinely distinct visual/mechanical effects; no empty or duplicate choices.
- [ ] Enemy prioritization works by touch on a physical phone.
- [ ] Pause/resume, retry, result screen, rewards and local saving work.
- [ ] Weapon-by-weapon after-action statistics appear and are consistent with counted hits.
- [ ] Headless import, gameplay smoke tests, build/export checks and physical J8 playtest pass.
- [ ] No unlicensed assets, decompiled source, ad SDK, purchase path, cloud login or private G41 data enter the repo.

## Suggested implementation sequence (large blocks, not dozens of tiny phases)

1. **Battlefield rebuild** — delete radial movement assumptions; introduce upper spawn strip, threatened bottom zone, guardian, proper HUD, seeded scenario spawner.
2. **Combat systems** — four weapon behaviors, chain/pierce/explosion/area effects, upgrade options with meaningful gameplay transformations.
3. **Stage/game shell** — Normal+Elite director, transitions, difficulty scaling, rewards/statistics, local saves and streamlined menu.
4. **J8 validation** — CI + repeat-signing, APK export, Android performance instrumentation, phone playtest, fix discovered faults before marking PR ready.

## Separate save-state research

A Moto G41 external file `/sdcard/Android/data/com.cyberjoy.x3/files/URR2biHjfBf6LbO3SCWwTOgYBD83.bin` had SHA-256 baseline:

`c4f0e969de7c5164a96a04019011abefabc04fd26a232b5797101f184e80048d`

Only a **candidate**, with no proof it is a complete or transferable game save. Make an ordinary, durable in-game progression change, exit to main menu, and compute SHA-256 again. If changed, take another copy for private comparison. If unchanged, inspect the external-file inventory and consider private Unity PlayerPrefs or cloud-backed storage. **Never root or modify the primary G41 solely to copy the reference save.**

## Definition of done

`M1R` is done when someone can install the J8 APK, play two real directional-defense stages, choose tactical upgrades, see results, and accurately recognize the intended **type of gameplay** without being shown the reference game. The previous arena-survival prototype fails this gate and must not be merged unchanged.

## M1R implementation status

- [x] Bottom Guardian and upper-edge directional enemy field implemented.
- [x] Normal 01 and Elite 01 scenario director with stage unlock and elite encounter.
- [x] Prism Beam, Comet Volley, Arc Relay and Nova Field (with pattern evolution).
- [x] Three upgrade choices per level and two weapon synergies.
- [x] After-action per-weapon applied damage, earned alloy, persistent research.
- [x] Low-effects mode, FPS readout, touch-target preference.
- [ ] CI smoke tests and Android artifact confirmed on M1R head commit.
- [ ] Physical J8 QA for visual/readability, performance, touch and victory/loss.
- [ ] Stable debug signing secret provisioned and upgrade install verified.

Design tuning in this milestone is independent and provisional. Weapon balance must be playtested and reworked from feedback, not assumed from the reference game.
