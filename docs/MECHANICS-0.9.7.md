# Mechanics 0.9.7: enemy relationships, Overdrive, Moving Line, new cards

Build `0.9.7-overdrive`. Brief steps 4 and 5. All tuning lives in
`scripts/game_catalog.gd`; mechanic visuals live in `scripts/mechanic_visuals.gd`
so a graphics pass can restyle them in one file.

## Enemy relationships (step 4)

- **Warden** (new hostile, salmon hexagon, 72 HP, slow). Every hostile inside its
  130 px aura is **shielded** and takes 45% damage. Wardens are never shielded,
  always show an HP bar and take +20% from Arc. Formation **WARDEN**: a Warden
  trailing a screen of grunts (plus a tank when heavy or late).
- **Convoy**: formation **CONVOY**, tanks escorting runners. Escorted runners ride in
  formation behind their tank, shielded (yellow hex). When the tank dies they break
  loose: unshielded and 35% faster. Banner warns yellow like other armored waves.
- **Elite phase II** now also spawns a Warden next to the Elite.
- Both formations are appended to the end of every sector cycle (hard-start openers
  use the first three entries, so they are unchanged).

Why this matters for tap-to-focus [Provável]: focus pulls *every* weapon onto one
target. Focusing a Warden opens a whole group, but leaves the front line alone.
The bot table below shows the cost: a bot that focused every Warden lost more runs
than one that never focused. [Certo on the sim, Chute on how it feels by hand]

## Overdrive (step 5)

- Kills charge it (grunt/runner 1, tank 3, Warden 4, Elite 12; full at 50;
  HARD START charges at 70%). The **OVERDRIVE** button sits right of the Guardian,
  above the weapon tray.
- Fires at the focused target, else the densest cluster: 240 damage (scaled by
  Amplifier and Alloy damage) in a 165 px blast that **ignores shields**, then
  +40% fire rate for 4 s. The strike's own kills don't refill it.

## Moving Line prototype (step 5, behind a flag)

Off by default. **SETTINGS → MOVING LINE** (playtest builds only, saved).

- Every hostile leans on the line (capped at 12 weight units so a packed field
  can't spiral it alone); hostiles past it push much harder; kills push it up.
- High line (≥70%): +12% fire rate, +20% XP. Low line (≤30%): −15% range.
  At 0% the core loses 5 hull/s. Overdrive also slams the line up 25% and
  shoves hostiles past it back.
- Kill criterion from the brief: if after 5 runs you never look at the Line, drop it.

## New level-up cards (3 ranks each)

| Card | Category | Effect |
|---|---|---|
| Overdrive Capacitor | OVERDRIVE | +30%/+60% charge; rank 3: +90% and a 6 s surge |
| Overdrive Yield | OVERDRIVE | +40% damage and +15% radius per rank; rank 2 stuns survivors; rank 3 refunds 30% charge |
| Shield Breaker | TARGET PRIORITY | shielded take 60/75/90%; rank 2: Wardens take +40%; rank 3: dying Wardens burst |
| Target Uplink | TARGET PRIORITY | focus takes +20% per rank; rank 2: killing it charges Overdrive; rank 3: lock jumps to the next Warden |
| Line Anchor | MOVING LINE | kills push the line 35% harder per rank; only offered with the Line on |

## Balance probe

`make sim-sectors` now also runs LEVEL 1 with the Line and HARD START with the
Line, fires Overdrive whenever ready, and prints Overdrive uses and the line's
average and lowest value. Output on this commit:

```
sector        start  result   time   hull     lv  kills  breaches  peak  od  line
NORMAL 01     LV1    CLEAR     97.1  100/100  15    155         0     7   3  -
NORMAL 01     LINE   CLEAR     96.6  100/100  16    155         0     6   3  avg  86% low  59%
NORMAL 01     HARD   LOST      33.8    0/100  15    100         7    35   1  avg  40% low  13%
NORMAL 01     HARD   CLEAR     98.2   84/100  22    412         2    36   6  -
NORMAL 01     HARD   CLEAR     99.0   68/100  22    410         4    35   6  -
NORMAL 01     HARD   CLEAR     97.7   63/100  22    410         1    36   6  -
ELITE 01      LV1    CLEAR    115.0  100/100  20    265         0    11   7  -
ELITE 01      LINE   CLEAR    115.0  100/100  21    265         0     8   7  avg  88% low  53%
ELITE 01      HARD   CLEAR    119.1  100/100  27    564         0    27  10  avg  91% low  55%
ELITE 01      HARD   CLEAR    121.9  100/100  26    569         0    36  10  -
ELITE 01      HARD   CLEAR    123.6   63/100  26    567         1    37  10  -
ELITE 01      HARD   CLEAR    123.8  100/100  26    568         0    41  10  -
SWARM 02      LV1    CLEAR    100.5  122/122  19    311         0    14   6  -
SWARM 02      LINE   CLEAR    100.0  100/100  20    307         0    11   6  avg  90% low  59%
SWARM 02      HARD   CLEAR    103.5  100/100  25    620         0    31   9  avg  91% low  58%
SWARM 02      HARD   CLEAR    106.2  122/122  24    612         0    44   8  -
SWARM 02      HARD   CLEAR    104.2  100/100  24    616         0    42   8  -
SWARM 02      HARD   CLEAR    105.9  100/100  24    617         0    49   8  -
SIEGE 03      LV1    CLEAR    110.3  100/100  21    236         0    16   8  -
SIEGE 03      LINE   CLEAR    110.0  122/122  22    241         0    17   7  avg  76% low  16%
SIEGE 03      HARD   CLEAR    114.0  122/122  29    543         0    26  12  avg  94% low  55%
SIEGE 03      HARD   CLEAR    116.6  100/100  27    551         0    45  13  -
SIEGE 03      HARD   CLEAR    116.0  100/100  27    547         0    41  12  -
SIEGE 03      HARD   CLEAR    116.0  100/100  27    546         0    32  12  -
AMBUSH 04     LV1    CLEAR    105.0  100/100  18    250         0    11   5  -
AMBUSH 04     LINE   CLEAR    105.0  122/122  19    248         0    12   5  avg  86% low  47%
AMBUSH 04     HARD   CLEAR    113.7  100/100  24    518         0    46   8  avg  69% low  41%
AMBUSH 04     HARD   CLEAR    115.9  100/100  24    524         0    53   8  -
AMBUSH 04     HARD   CLEAR    116.3   75/100  24    515         2    55   7  -
AMBUSH 04     HARD   CLEAR    116.9   44/122  23    505         6    57   7  -
ELITE 02      LV1    CLEAR    120.0  100/100  22    316         0    29   9  -
ELITE 02      LINE   CLEAR    120.0   68/100  23    313         3    30   8  avg  75% low   3%
ELITE 02      HARD   CLEAR    124.9  100/100  30    658         0    40  13  avg  89% low  48%
ELITE 02      HARD   CLEAR    130.6  100/100  28    664         0    51  13  -
ELITE 02      HARD   CLEAR    126.3  100/100  28    658         0    39  13  -
ELITE 02      HARD   CLEAR    133.6    9/144  27    650         8    60  12  -
```

Known: NORMAL 01 HARD START with the Line on is lost around 34 s (its authored
showcase floods the field). The Line is off by default, so normal hard runs are
unaffected. [Certo]
