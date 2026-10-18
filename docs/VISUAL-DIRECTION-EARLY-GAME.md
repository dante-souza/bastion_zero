# Bastion Zero — early Rogue-inspired visual direction (next build)

**Status:** visual research complete for a first implementation pass; game implementation **not yet applied**.
**Reference package:** User-supplied six-frame board `Bastion_Zero_Rogue_Reference_Board(1).jpg` and 2026-10-18 timestamped Markdown analysis `Bastion_Zero_Rogue_Visual_Reference_2026-10-18(1).md`. The original 13:36.9 MP4 exists in another Bastion_0 conversation but is **not mounted in this one**. The six stills and report are sufficient to start; request MP4 only for motion/animation or fine-detail verification.

Reference: [early Rogue gameplay](https://www.youtube.com/watch?v=9o4noNCPi-I). Third-party source material is used **only to study broad aesthetics and gameplay presentation**. No copied artwork, UI imagery, logos, sounds, Unity bundles, visual effects or proprietary text are incorporated.

## Observed reference features

The following are supported by the six provided stills; timestamps refer to the user-supplied analysis of the original recording.

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

Already implemented in v0.2.2: Sentinel Autocannon as built-in, Prism Beam as upgrade-card unlock, independently aimed twin beams, basic upgrade selection, enemy formation logic, 2 stages, local save. **The new visual treatment itself has not been shipped.**

No change to research currency, wave formulas, in-app purchases, online data, or original game save assets is authorized by this brief. Do not ship screenshot references inside the public game package or git repo.

## Remaining optional evidence

If possible, bring the raw 13:37 video into this specific chat before animation-specific work (muzzle cadence, beam motion, particles). A 384×854 source already suffices for composition; a higher-resolution recording would help typography and effect details but is not a blocker for visual shell implementation.
