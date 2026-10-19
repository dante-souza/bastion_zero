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
# Phase I.5: the selection outline is the player's mark, so it is cool ice,
# never gold (gold reads as an armored Tank).
const TARGET_LOCK := Color("#9FF6FF")
# Phase C enemy silhouette tokens match approved broad color directions.
const RUNNER := Color("#FF9A37")
const TANK := Color("#F4DE45")
const TANK_SHIELD := Color("#FFF19B")
# Phase I.5 threat language: warm = hostile, cool = yours, green = XP only.
# Grunts leave neon green (it read as loot and as the reference game);
# the rose matches the title-screen drifters. Elites move from magenta
# (which Prism shared) to crimson with a pale rim instead of an orange one
# (which Runners shared).
const ELITE := Color("#FF3B52")
const ELITE_RIM := Color("#FFC2CB")
const GRUNT := Color("#FF5FA8")
const ENEMY_INTERIOR := Color("#06131B")
const ENEMY_CENTER := Color("#C8FFFF")
const ENEMY_ENRAGED := Color("#FFE9EC")
const HEALTH_TRACK := Color("#273A4B")
const HEALTH_FILL := Color("#F5EBDD")
const HIT := Color("#ffffff")
const GUN_TRACER := Color("#31D6FF")
const PRISM_BEAM := Color("#B77CFF")
const PRISM_CORE := Color("#F3ECFF")
const ARC_BOLT := Color("#79A3FF")
const ARC_HOT := Color("#CFE7FF")
const NOVA_FIELD := Color("#2FE3C8")
## Slow is applied only by Nova Field, so the status ring keeps its source color.
const ENEMY_SLOWED := NOVA_FIELD
const COMET_BODY := Color("#DDF3FF")
const COMET_TRAIL := Color("#B9D3FF")
const COMET_HOT := Color("#FFFFFF")
const COMET_IMPACT := Color("#BDE8FF")
const DAMAGE_NUMBER := Color("#EAF6FF")
const XP_GREEN := Color("#6BBD98")

## Colors the player owns, and colors that mean "this hurts you".
## tests/test_smoke.gd keeps the two sets visually apart.
const FRIENDLY_SET := [GUN_TRACER, PRISM_BEAM, ARC_BOLT, NOVA_FIELD,
    COMET_BODY, COMET_IMPACT, TARGET_LOCK, DAMAGE_NUMBER]
const HOSTILE_SET := [GRUNT, RUNNER, TANK, ELITE]

static func enemy_tint(kind: String) -> Color:
    match kind:
        "runner": return RUNNER
        "tank": return TANK
        "elite": return ELITE
    return GRUNT
