# System Evolution UI refresh — v0.2.4

Status: **Implemented, pending physical J8 visual confirmation**.

## Reported issue

The user supplied a Galaxy J8 screenshot with an upgrade selection at level 12. The Kinetic Payload card showed `RANK 3/3` and a literal `Rank %d/3` in its description.

- The former was ambiguous: in version 0.2.3, the rank on a card is its **proposed next rank**, not the rank already owned. Thus displaying 3/3 can correctly mean the *final* upgrade from 2/3.
- The latter was a formatting issue caused by a literal percent sign preceding a formatter; that redundant rank text has been removed while keeping `+25% damage per Sentinel round.`.
- Eligibility remains keyed to actual owned ranks: `GameCatalog.upgrade_available()` checks `owned < cap`. The UI checks every offered item again before creating a card, and the upgrade action rejects stale selections.

## Updated layout

- The System Evolution panel uses a wider, taller layout optimized for the 720×1280 logical portrait canvas; scroll remains enabled on smaller screens.
- Each full-width clickable card uses an independent category label, large weapon/modifier title, `OWNED X/Y → NEXT Z/Y` rank progression, and a legible descriptive paragraph.
- For last-rank purchases, the rank line displays `(FINAL)`. The rank-3/3 card is not shown *after* acquiring rank 3.
- Upgraded fonts: heading 44; card title 28; description 21; category/rank 18; status line 25.
- The existing card wording, color hierarchy, core button behavior and synergy reminder remain.

## QA checks

- [x] Godot smoke tests cover max rank eligibility, stale offer filtering, exact rank labels and tall clickable cards.
- [ ] J8 portrait screenshot validates readability, no overflow, and one-tap selection.
- [ ] A real stage maxes Kinetic Payload; subsequent level-up does not offer the same modification.
- [ ] No `%d` literal appears in descriptions.
- [ ] Pause/resume and 3-choice stage upgrade flow still operate on J8.
