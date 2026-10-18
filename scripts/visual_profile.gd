class_name VisualProfile
extends RefCounted

## Original arcade palette, based on broad aesthetic observations of
## user-provided reference video. No third-party game assets are used.
## Phase A updates only world backdrop/horizon; other silhouettes remain M1R.
const BACKDROP := Color("#020509")
const HORIZON_BLUE := Color("#168BFF")
const HORIZON_CORE := Color("#67D8FF")
const HORIZON_HALO_OUTER := Color(0.086, 0.545, 1.0, 0.065)
const HORIZON_HALO_INNER := Color(0.12, 0.70, 1.0, 0.17)
const BACKGROUND_SPECK := Color(0.24, 0.43, 0.60, 0.17)
const BREACH := Color("#ff6486")
const GUARDIAN_HULL := Color("#174368")
const GUARDIAN_CORE := Color("#46d6f2")
const TARGET_LOCK := Color("#ffca66")
const RUNNER := Color("#ffca66")
const TANK := Color("#7894ff")
const ELITE := Color("#e888ff")
const GRUNT := Color("#ff6486")
const HIT := Color("#ffffff")
const GUN_TRACER := Color("#5feeff")

static func enemy_tint(kind: String) -> Color:
    match kind:
        "runner": return RUNNER
        "tank": return TANK
        "elite": return ELITE
    return GRUNT
