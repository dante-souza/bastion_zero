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
const BACKDROP_BOTTOM := Color("#081e39")
const GUARDIAN_AURA := Color(0.05, 0.33, 0.76, 0.42)
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
# Phase C enemy silhouette tokens match approved broad color directions.
const RUNNER := Color("#FF9A37")
const TANK := Color("#F4DE45")
const TANK_SHIELD := Color("#FFF19B")
const ELITE := Color("#F66AD9")
const ELITE_ORANGE := Color("#FF793D")
const GRUNT := Color("#52F52A")
const ENEMY_INTERIOR := Color("#06131B")
const ENEMY_CENTER := Color("#C8FFFF")
const ENEMY_SLOWED := Color("#47E7A8")
const ENEMY_ENRAGED := Color("#FF4768")
const HEALTH_TRACK := Color("#273A4B")
const HEALTH_FILL := Color("#7BF5A6")
const HIT := Color("#ffffff")
const GUN_TRACER := Color("#31D6FF")
const PRISM_BEAM := Color("#FF56DD")
const ARC_BOLT := Color("#79A3FF")
const ARC_HOT := Color("#CFE7FF")
const NOVA_FIELD := Color("#47E7A8")
const COMET_BODY := Color("#FFB545")
const COMET_TRAIL := Color("#F16A42")
const COMET_HOT := Color("#FFF4BB")
const COMET_IMPACT := Color("#FF9B45")

static func enemy_tint(kind: String) -> Color:
    match kind:
        "runner": return RUNNER
        "tank": return TANK
        "elite": return ELITE
    return GRUNT
