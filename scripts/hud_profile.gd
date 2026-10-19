class_name HudProfile
extends RefCounted

## Phase E: compact 720x1280 logical-canvas HUD. Touch-safe pause control.
## Constants are testable; all other screens retain their original padding.
const TOP_START := 8.0
const TOP_END := 114.0
const BOTTOM_START := -92.0
const BOTTOM_END := -12.0
const PAUSE_SIZE := Vector2(55.0, 44.0)
const XP_HEIGHT := 11.0
const HUD_MARGIN_HORIZONTAL := 14
const HUD_MARGIN_VERTICAL := 9

## Phase I.1 tactical overlays (reference: user's compact combat mockup).
## Phase I.6: the header lost its empty bottom band (133 -> 106), the Elite
## strip sits directly under it, and the threat banner is transient: it only
## appears while an event is live, in the first free slot. The persistent HUD
## stack ends at 106 (no Elite) or 132 (Elite) instead of 213.
const TACTICAL_TOP_START := 8.0
const TACTICAL_TOP_END := 106.0
const TACTICAL_ELITE_START := 110.0
const TACTICAL_ELITE_END := 132.0
const TACTICAL_WARNING_START := 110.0
const TACTICAL_WARNING_END := 138.0
const TACTICAL_WARNING_UNDER_ELITE_START := 136.0
const TACTICAL_WARNING_UNDER_ELITE_END := 164.0
const TACTICAL_TRAY_START := -119.0
const TACTICAL_TRAY_END := -10.0

static func top_height() -> float:
    return TOP_END - TOP_START

static func bottom_height() -> float:
    return BOTTOM_END - BOTTOM_START
