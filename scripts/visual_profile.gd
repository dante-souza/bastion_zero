class_name VisualProfile
extends RefCounted

## Original arcade palette, based on broad aesthetic observations of
## user-provided reference video. No third-party game assets are used.
## Phase B.1 adds the Guardian palette and a restrained, smoothly shaded arena.
const BACKDROP := Color("#020509")
const HORIZON_BLUE := Color("#168BFF")
const HORIZON_CORE := Color("#67D8FF")
const HORIZON_HALO_OUTER := Color(0.086, 0.545, 1.0, 0.065)
const HORIZON_HALO_INNER := Color(0.12, 0.70, 1.0, 0.17)
const BACKGROUND_SPECK := Color(0.24, 0.43, 0.60, 0.17)
const BREACH := Color("#ff6486")
const BACKDROP_MID := Color("#030a16")
const BACKDROP_BOTTOM := Color("#061325")
const GUARDIAN_AURA := Color(0.04, 0.25, 0.60, 0.16)
const GUARDIAN_HULL := Color("#174368")
const GUARDIAN_CORE := Color("#24EAFF")
const GUARDIAN_RING_LIGHT := Color("#17D7FF")
const GUARDIAN_RING_BLUE := Color("#126DEF")
const GUARDIAN_STEEL := Color("#789BC8")
const GUARDIAN_METAL := Color("#18365C")
const GUARDIAN_SHADOW := Color("#030D1D")
const GUARDIAN_LENS := Color("#071F9B")
const GUARDIAN_LENS_INNER := Color("#135FFC")
const GUARDIAN_EYE := Color("#DAFFFF")
const GUARDIAN_DAMAGE := Color("#FF6379")
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
