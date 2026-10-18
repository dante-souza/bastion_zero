# Bastion Zero — early Rogue-inspired visual direction (next build)

**Status:** 13:36.9 video directly inspected on 2026-10-18. Phase A (near-black arena and blue horizon) implemented on `feature/m1-visual-phase-a`; Phases B–F remain planned. Sentinel upgrades remain as in M1R.
**Reference package:** User-supplied six-frame board `Bastion_Zero_Rogue_Reference_Board(1).jpg` and 2026-10-18 timestamped Markdown analysis `Bastion_Zero_Rogue_Visual_Reference_2026-10-18(1).md`. The original MP4 was subsequently uploaded here and directly analyzed (H.264, 384×854 portrait, 30 fps). The six stills accurately capture the art direction. Derived contact sheets and a timestamped analysis report were generated for local review, and are not imported as game assets.

Reference: [early Rogue gameplay](https://www.youtube.com/watch?v=9o4noNCPi-I). Third-party source material is used **only to study broad aesthetics and gameplay presentation**. No copied artwork, UI imagery, logos, sounds, Unity bundles, visual effects or proprietary text are incorporated.

## Observed reference features

The following are supported by the user-provided board **and** direct sampling of the complete uploaded recording. These are visible observations, not inferred combat formulas.

| Reference frame | Observation | Original Bastion Zero treatment |
|---|---|---|
| 01:40 — machine-gun streams | Almost black background, thin cyan streaks, green circular foes, glowing arc above low defender | A fast and trackable Sentinel Autocannon, quiet field and defensive blue horizon |
| 03:00 — boss and beam | Large orange boss emblem and magenta linear beam above blue core, many colored effects | Distinct original boss *circuit sigil*, magenta Prism laser only after unlocking, clear effect priority |
| 04:20 — upgrade choice | Three horizontal, rounded, outlined cards with icon, name, description and rank/star cue; black dimmed play | Three actual mechanics cards with **NEW**, **UPGRADE** or **COMBO** labels, no paid/ad refresh |
| 07:45 — quiet field | Cyan core near bottom with luminous curved horizon and scattered circular foes | Smaller lower HUD and a visually prominent core; no heavy floor grid |
| 10:05 — chain choices | Three simple, large upgrade cards, colored skill badges | Weapon-specific iconography, rank/prerequisite shown honestly |
| 12:20 — geometric swarm | Luminous green rings; yellow square/diamond outlines; narrow blue tracers | Enemies remain distinct in groups of 30+, limited overlapping particle effects |

**Caution:** a screenshot does not establish animation cadence, exact movement, progression order or hit rules; these must remain original design decisions.

## Visual language — approved implementation targets

- **Composition:** 720×1280 portrait logical canvas, consistent world-to-screen transform; defend bottom, threats enter top. Keep roughly 80% of the combat field visually quiet. Do not imitate source-game HUD pixel-for-pixel.
- **Background:** near-black `#020509`, gentle muted star-speckle/noise if cheap; **remove the visible regular tile grid**. J8 reduced-FX mode removes all optional background particles.
- **Defense horizon:** low electric-blue `#168BFF` semicircular/shallow arc behind Guardian, around 76–84% of height. Subtle outer cyan halo; no giant opaque lower strip across gameplay.
- **Guardian:** own circular/circuit shield emblem, central rotating barrel, cyan muzzle point; aim should follow the same target used by the actual Autocannon. Keep original distinct silhouette and proportions.
- **Enemy coding:** grunts => lime `#52F52A` circular outline; runners => orange `#FF9A37` triangular outline; tanks => gold `#F4DE45` square or diamond with internal shielding strokes; elites => larger original orange/magenta segmented circuit symbol with separate HP bar. Shape differentiation, not just color.
- **Sentinel Autocannon:** cyan `#31D6FF` projectile streaks short enough to see their movement, actual swept collision, small short-lived impact glow `#D2FFFF`. The built-in attack always fires at visible threats. Multibarrel unlocks must show two *real* paths and collisions.
- **Prism Beam:** acquired separately through a level-up card. Its visual identity becomes magenta `#FF56DD` rather than default cyan. Centerline rendering must exactly match hit testing; split beams individually lock enemies and visibly connect to their targets.
- **Nova/area effects:** fine jade ring `#47E7A8` and translucent interior so enemies remain legible. Explosions and hostile warnings use amber/orange. Never fill the screen with opaque pulses.
- **HUD:** compact top-left pause; central stage/progress/time; top-right optional speed toggle only once implemented. Hull in lower-left; weapon indicators in lower-right; ensure touch targets >=44 logical px and no obscuring lower weapon fire.
- **Level-up overlay:** translucent dim layer, "SYSTEM EVOLUTION" heading, 3 horizontally stretched cards stacked vertically; each card shows original icon, title, status badge ("NEW"/"UPGRADE"/"COMBO"), rank, one precise line describing mechanic. Never reproduce third-party branded ad/refresh controls. Upgrade offer selection must remain safe on small J8 screens.

## Implementation plan for next large milestone (visual shell)

1. **VisualProfile expansion:** expose palette, shape and low-FX rules centrally; geometry renderer gets pure helper functions for background/horizon, Guardian, enemy silhouettes and fired projectiles. Keep combat logic and visuals separable.
2. **World renderer:** eliminate visible grid in favor of near-black negative space, add luminous lower arc and original Guardian circuit-barrel. Retain actual muzzle origin and world-space targeting.
3. **Enemy renderer:** outline-only green circles/yellow squares/orange triangles; original boss symbol and distinguishable hit/shield/slow feedback. Validate readability at 30, 50 and 80 on-screen enemies.
4. **Weapon renderer:** cyan physical bullets, magenta acquired laser, jade fields and compact explosions. Render from simulation segments rather than decorative guesses.
5. **Upgrade/HUD:** rebuild selection screens as legible 3-card presentation; no ads, no real-money economy, no imitation logos.
6. **J8 acceptance:** 30 FPS sustained target in dense waves with low-FX, all weapon collisions correct, no excessive text overlap, pause/unpause and save remain functional; screenshot/short recording required.

## Existing gameplay work and non-goals

Already implemented in v0.2.3: Sentinel Autocannon built-in, selectable **Kinetic Payload**, **Sabot Piercer**, **Ricochet Routing**, **Saturation Burst** upgrades, guaranteed Sentinel evolution in offers while unmaxed, Prism Beam separately unlockable, independently aimed twin beams, 2 stages and local saves. **Only visual Phase A is implemented on its dedicated branch; later visual phases are not yet shipped.**

No change to research currency, wave formulas, in-app purchases, online data, or original game save assets is authorized by this brief. Do not ship screenshot references inside the public game package or git repo.

## Remaining optional evidence

**Resolved:** the source video is now accessible for direct inspection. A higher resolution would help small font details but is not a blocker. Do not commit the copyrighted footage or reference stills.

## Direct video review — verified moments

| Time | Visible detail |
|---|---|
| 00:15 | Default cyan bullets from a blue core striking green circle outlines |
| 00:38 | Distortion Field (New), Volley Shot and Bullets Boost upgrade choices |
| 01:24 | Magenta laser separately active alongside cyan bullets |
| 03:19 | Beam Amplification, Volley Shot and Piercing Bullet choices |
| 04:05 | Large orange boss emblem with multiple weapons simultaneously active |
| 05:00–05:26 | Penetration Boost, Volley Missile, Bullets Boost, Flame Bullet choices |
| 06:18 | Per-weapon DPS and damage statistics after the stage |
| 07:10–08:02 | New stage starts with basic bullets; Beam and Flame Missile offered as New |
| 09:34–09:58 | Magenta beam and cyan bullets remain distinct channels |
| 11:34–11:58 | Translucent jade control field among green circles and yellow squares |
| 13:10 | Impact Enhancement, Explosion Spread and Shotgun Barrage (Chain) |

The original UI offers ad-based refresh; Bastion Zero does not reproduce monetization. All graphics and gameplay behaviors must be original.

