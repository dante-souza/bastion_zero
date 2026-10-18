class_name VisualProfile
extends RefCounted

## Style tokens shared by the world renderer; original art only.
## CURRENT holds the validated M1R display. Do not claim that these
## colors reproduce the user-linked early-game video (unavailable for inspection).
const BACKDROP := Color("#091322")
const GRID := Color(0.1, 0.22, 0.31, 0.35)
const SPAWN_BAND := Color("#182b41")
const LOWER_ZONE := Color("#102a3e")
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
