# Phase I.5 — Color Language

**Goal:** the Threat Guide stops explaining color collisions and the
palette stops having them. One rule, enforced by tests:

> **Cool is yours. Warm is hostile. Green is growth (XP) only.**

Mechanics, balance, spawn patterns and the premium app are unchanged.

## Why

Phase I.4 documented the real palette faithfully, which exposed three
places where the player's own effects shared a hue with an enemy, plus
green meaning five different things:

| Before (I.4)              | Clashed with                  |
|---------------------------|-------------------------------|
| Prism `#FF56DD` magenta   | Elite `#F66AD9` magenta       |
| Comet impact `#FF9B45`    | Runner `#FF9A37` orange       |
| Elite rim `#FF793D` orange| Runner `#FF9A37` orange       |
| Target lock `#FFCA66` gold| Tank `#F4DE45` yellow         |
| Grunt `#52F52A` green     | XP, enemy HP bar, slow, Nova  |

The I.4 guide had to print "GREEN RINGS ARE ENEMIES" twice. Green-ring
grunts were also the most recognizable trait shared with the reference
game the design should evoke without copying.

## New tokens (`scripts/visual_profile.gd`)

```
YOURS (cool)                          HOSTILE (warm)
  Sentinel rounds  #31D6FF cyan         Grunt   #FF5FA8 rose ring
  Prism beam       #B77CFF violet       Runner  #FF9A37 orange wedge
  Arc relay        #79A3FF blue         Tank    #F4DE45 yellow square
  Nova field/slow  #2FE3C8 teal         Elite   #FF3B52 crimson, rim #FFC2CB
  Comet            #DDF3FF ice white
  Target lock      #9FF6FF ice        SIGNALS
  Damage numbers   #EAF6FF ice          Enemy HP  #F5EBDD ivory
                                        Breach    #FF6486 red
GROWTH                                  Enraged   #FFE9EC white-hot halo
  XP               #6BBD98 green
```

- Grunt rose matches the drifters already drawn on the I.3 title screen.
- Slow keeps Nova's color on purpose: Nova Field is its only source.
- The Comet+Nova supercharge blast and damage numbers left gold.

## Typed event severity

`Arena._announce(text, kind, seconds)` sets the event text and a kind:
`info`, `formation`, `elite`, `breach`. The snapshot carries
`event_kind`; `ThreatLanguage.color_for(kind, formation)` picks the
banner color. Rewording a message can no longer change its color, and
friendly status lines (DEFENSE ONLINE, SHOWCASE) render cyan without the
ALERT prefix. The ▼◆■ banner glyphs were dropped (no bundled font
guarantees them on the J8).

## Threat Guide

- Rule sentence replaces the green-ring warning label.
- Target focus and Slowed move to YOURS, with their own glyphs.
- Section headings: cyan YOURS, orange HOSTILE, neutral SIGNALS.

## Tests

`tests/test_smoke.gd` adds a palette guard: every color in
`VisualProfile.FRIENDLY_SET` must sit at RGB distance ≥ 0.30 from every
color in `HOSTILE_SET`, and no hostile hue may fall in the green band.
The I.4 palette fails this guard (Prism vs Elite is 0.09).

## J8 / Gitflow

Branch `feature/m1-visual-phase-i5-color-language`, stacked on I.4.
Version `0.9.4-phase-i5-color-language-debug`, Android version code 24;
same package `com.dantesouza.bastionzero.phaseh`. Run `make phase-i5`.
