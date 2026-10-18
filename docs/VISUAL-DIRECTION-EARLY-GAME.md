# Early-game visual direction — source review and implementation readiness

Reference requested: [YouTube video 9o4noNCPi-I](https://www.youtube.com/watch?v=9o4noNCPi-I).

**Evidence status (2026-10-18):** The linked YouTube video could not be fetched or viewed through the available browser. **Do not assert specific art, terrain, enemy sprites, exact palette or UI layout from it.** The previous user-uploaded Rogue Defense gameplay clips are a separate, accessible reference; they verify portrait top-to-bottom play, visually distinct Guardian/weapons/enemies, level-up cards, stage progress and dense projectile effects. The following work is *preparation*, not a claim that the linked video's artwork has been reproduced.

## What the user decided

- Make the **machinegun/autocannon** the permanent built-in attack, analogous in role (not implementation) to Rogue Defense's starter Guardian Bullets.
- Prism Beam should be **acquired via level-up**, not equipped at the start.
- The twin/split Prism attack must **hit the chosen enemies**, not simply fan outward and miss them.
- Next version's presentation should take the **early-game aesthetic of the linked video** as a reference, using entirely original Bastion Zero artwork and avoiding extraction/reuse of the reference game's proprietary assets.

## Visual production pipeline prepared now

The file `scripts/visual_profile.gd` holds the current battlefield color and silhouette tokens. The arena renderer uses those tokens for the background, grid, enemy tint and Guardian. The next visual milestone can replace drawing/material details independently of weapon logic.

Suggested separation for next implementation milestone:

| Layer | What may change | Stability rule |
| --- | --- | --- |
| Field | Background motif, track/grid, top spawn/bottom breach | Must stay readable at 720×1280 and on smaller J8 |
| Guardian | Original turret silhouette, barrel rotation, muzzle flash | Preserve position and collision/aim origin |
| Threats | Color-shape silhouettes, damage/armor overlays | Every enemy type identifiable without relying solely on color |
| Projectile effects | Tracers, muzzle bursts, explosions, lasers | Weapon paths follow computed hit geometry; no ornamental beams that miss |
| HUD | Stage label, health, XP, skill row, focus cue | UI remains touchscreen-operable at native J8 resolution |
| Level-up cards | Icons, hierarchy, labels, rarity | Actual mechanics/prerequisites must match text |

### Exact reference review gate

Before authoring a claim of visual fidelity, obtain the actual video as an uploaded clip or at least screenshots covering:
1. Early-stage battlefield with minimal weapon effects
2. Guardian close-up, basic bullet flight and enemies
3. Upgrade choice screen
4. Normal gameplay with multiple enemies and hit effects
5. Result/hangar screen if included

Then record observed palette, shape language, camera/scale, shadows/textures, animation cadence, typography and HUD arrangement with timestamps. Convert those into **original, lightweight vector/procedural assets** for the J8; never extract original art from Unity APK bundles.

## Next-version acceptance

- [ ] Video-specific aesthetic analysis completed from viewable reference.
- [ ] Style guide specifies background, characters, effects, cards and HUD.
- [ ] Original art is integrated behind existing gameplay logic.
- [ ] Every projectile rendering is tied to actual hit simulation.
- [ ] Low-FX option preserves readable target feedback and FPS on J8.
- [ ] Pixel-density, font size and touch UI checked on J8.

