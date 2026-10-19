# Sectors (playable maps) and HARD START

Build `0.9.6-sectors`. Six playable sectors, all reachable from **SECTORS** on the
title screen. Data lives in `scripts/sector_catalog.gd`; NORMAL 01 and ELITE 01
keep their original balance exactly, except that 0.9.7 appends the WARDEN and CONVOY
formations to every cycle (see docs/MECHANICS-0.9.7.md).

| # | Code | Place | Identity | Field rule | Horizon |
|---|------|-------|----------|-----------|---------|
| 1 | NORMAL 01 | Last Horizon | mixed waves | none | crest |
| 2 | ELITE 01 | Last Horizon | heavier waves, elite at 60% | none | crest |
| 3 | SWARM 02 | Cinder Rift | fast, fragile runner swarms | runner surge on both flanks every 15s | twin ridges, indigo |
| 4 | SIEGE 03 | Iron Shelf | armored columns, SIEGE wall formation, elite at 72% | hostiles repair 1.5% max HP/s | flat shelf with ribs, steel |
| 5 | AMBUSH 04 | Drop Zone | SCATTER spreads, mid-field drops | drop pod every 13s (warm marker, lands after 1.6s) | sawtooth, teal-blue |
| 6 | ELITE 02 | Null Expanse | heaviest waves, elite at 50% | fog: weapon range -18% | wide crest, pale steel + mist |

New formations: **SWARM** (two runner knots), **SIEGE** (tank wall, warns yellow like other
armored formations), **SCATTER** (loose spread). Backdrops stay cool (blue band or
near-neutral); the drop pod marker is warm because it announces a hostile. A smoke test
enforces the backdrop hue rule.

## HARD START (playtest builds)

`GameCatalog.PLAYTEST_TOOLS = true` opens every sector on a fresh install and adds the
**START: HARD / LEVEL 1** toggle at the top of SECTORS (saved in the save file, defaults
to HARD). Title **DEPLOY** follows the same toggle. A hard start on any sector:

- starts at **LV12** with the QA loadout (Sentinel 4, four weapons at 2, rate/power/reach 1);
- opens with authored pressure: NORMAL 01 keeps its six-beat showcase script; other
  sectors get three beats built from their own formation cycle;
- applies the showcase HP/speed/breach-damage scaling, times a per-sector `hard_hp`,
  and keeps escalating: hostile HP grows by up to +200% over the stage and the formation
  interval shrinks from 1.2s to 0.65s;
- grants 70% XP per kill so the run cannot level its way out of the pressure.

Set `PLAYTEST_TOOLS = false` for a release build: locks follow progression again and
every run starts at level 1.

## Balance probe

`make sim-sectors` (or `godot --headless --path . --script res://tests/sim_sectors.gd`)
plays every sector headless, picking the first offered card, once at LV1 and three
times at HARD START. It ignores target focus, so a person should do better than this bot.
Output on this commit:

```
sector        start  result   time   hull     lv  kills  breaches  peak
NORMAL 01     LV1    CLEAR     96.0  100/100  14    150         0     6
NORMAL 01     HARD   CLEAR     98.6   29/100  22    400         4    36
NORMAL 01     HARD   CLEAR     99.0    2/100  21    394         6    34
NORMAL 01     HARD   CLEAR     98.0   30/100  21    392         5    36
ELITE 01      LV1    CLEAR    115.8  122/122  19    243         0    11
ELITE 01      HARD   LOST      87.9    0/100  20    307         8    48
ELITE 01      HARD   CLEAR    128.5   29/100  24    514         4    53
ELITE 01      HARD   CLEAR    126.3   63/100  25    521         1    38
SWARM 02      LV1    CLEAR    100.1  100/100  18    308         0    12
SWARM 02      HARD   CLEAR    106.7  100/100  24    621         0    51
SWARM 02      HARD   CLEAR    106.8   68/100  23    609         4    53
SWARM 02      HARD   CLEAR    106.3   33/122  23    607        11    55
SIEGE 03      LV1    CLEAR    111.0  100/100  21    240         0    15
SIEGE 03      HARD   CLEAR    121.2  100/100  27    534         0    64
SIEGE 03      HARD   CLEAR    123.5   85/122  27    542         1    68
SIEGE 03      HARD   CLEAR    123.1  100/100  27    542         0    71
AMBUSH 04     LV1    CLEAR    105.6  100/100  18    248         0     9
AMBUSH 04     HARD   CLEAR    115.8   83/100  23    509         2    54
AMBUSH 04     HARD   LOST     109.3    0/122  22    468        14    50
AMBUSH 04     HARD   LOST      98.7    0/100  21    408        11    52
ELITE 02      LV1    CLEAR    120.9   17/100  21    297         9    26
ELITE 02      HARD   CLEAR    129.0   88/122  27    634         1    48
ELITE 02      HARD   CLEAR    133.6   78/144  27    632         3    56
ELITE 02      HARD   LOST     119.5    0/166  26    568        13    66
```
