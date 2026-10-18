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
const TACTICAL_TOP_START := 8.0
const TACTICAL_TOP_END := 133.0
const TACTICAL_WARNING_START := 138.0
const TACTICAL_WARNING_END := 172.0
const TACTICAL_ELITE_START := 176.0
const TACTICAL_ELITE_END := 213.0
const TACTICAL_TRAY_START := -119.0
const TACTICAL_TRAY_END := -10.0

static func top_height() -> float:
    return TOP_END - TOP_START

static func bottom_height() -> float:
    return BOTTOM_END - BOTTOM_START
