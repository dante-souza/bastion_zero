# Phase I.6 — Playtest Fixes

Source: three J8 screenshots of the I.5 build (level-up at LV 16, Elite
fight at 7% and 62%). Every item below was visible in them. No balance,
spawn or weapon-mechanic changes.

## Combat HUD frees the top of the playfield

```
I.5 (logical px)                 I.6
  8–133  header (35 px empty)      8–106  header, empty band removed
138–172  banner, always on       110–132  Elite strip (only with an Elite)
176–213  Elite strip             110–138  banner, transient
                                 136–164  banner when an Elite is alive
```

- The banner is **transient**: it shows only while an Arena event is live
  (formation arrival, Elite, breach, status). The permanent
  "INCOMING • N HOSTILES" line is gone.
- The banner takes the first free slot (under the header, or under the
  Elite strip while an Elite lives), so it never floats over a gap.
- Persistent HUD now ends at y 106 (no Elite) or 132 (Elite), versus 213.

## Level-up cards

- Cards are pushed into the bottom (thumb) half by a spacer; content that
  is taller than the screen still scrolls.
- Rank pips moved onto the rank row, and each card grows with its wrapped
  description, so a two-line text can no longer push pips through the
  border (the Prism card bug).
- Player-facing copy per rank, read from Arena's real thresholds:
  - Prism pierces 1 + rank enemies; twin beam at rank 3; rank 2 gives Arc +1 jump.
  - Comets: 2 + rank per salvo; area burst at rank 3; fragments at rank 4.
  - Arc strikes 1 + rank enemies; stun at rank 3.
  - Nova grows blast and slow every rank; Comet R2 + Nova R2 detonate twice.
  - No more "target(s)", "Unlock x / y" or trailing "Rank 3".
- Every upgrade has its own icon silhouette (`UpgradeEmblem.shape_for`).
  Sentinel shows tracer rounds; Prism shows a prism and ray.

## Combat clutter

- Health bars: Tanks, Elites and the focused target only. Damaged swarm
  units no longer each grow a bar.
- Kill pops: the enemy's hue blooms to white and the stroke thins instead
  of fading in alpha, which turned orange and rose into brown and maroon
  circles over the navy field.

## Android back

`application/config/quit_on_go_back=false`; `Main.go_back()` handles
`NOTIFICATION_WM_GO_BACK_REQUEST` one screen at a time:

| Where            | Back does                     |
|------------------|-------------------------------|
| Combat           | Pause                         |
| Pause menu       | Resume                        |
| Threat Guide     | Return to Pause or Title      |
| Level-up choice  | Nothing (a card is required)  |
| Hangar, Sectors, Settings, Results | Title       |
| Title            | Quit (mobile only)            |

A duplicated back in the same frame is ignored. Esc mirrors it on desktop.

## J8 / Gitflow

Branch `feature/m1-visual-phase-i6-playtest-fixes`, stacked on I.5.
Version `0.9.5-phase-i6-playtest-fixes-debug`, Android version code 25;
same package `com.dantesouza.bastionzero.phaseh`. Run `make phase-i6`.
