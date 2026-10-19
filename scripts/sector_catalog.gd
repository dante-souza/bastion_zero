class_name SectorCatalog
extends RefCounted

## Playable maps (sectors). Each one is its own encounter: enemy mix and
## formation cycle, one field rule, pacing and an original cool backdrop.
## Stage numbers stay 1-based. 0.9.7 appends the WARDEN and CONVOY
## formations to the end of every cycle (hard-start openers use the first
## three entries, so they are unchanged).
##
## Field rules:
##   "none"  - no extra rule.
##   "surge" - every `rule_every` seconds, runners pour in from both flanks.
##   "regen" - hostiles repair `regen` of their max HP per second.
##   "drop"  - every `rule_every` seconds, a warm marker telegraphs a drop pod
##             that lands a squad mid-field after `drop_delay` seconds.
##   "fog"   - weapon range is multiplied by `range_scale`.
##
## Backdrop horizon shapes: "crest", "twin", "shelf", "jagged".
## Backdrop colors stay cool: warm belongs to hostiles, green to XP.
const MAPS := [
    {
        "code": "NORMAL 01", "place": "LAST HORIZON", "tag": "NORMAL",
        "brief": "The original line. Mixed waves, no field rule.",
        "seconds": 96.0, "hp": 1.0, "pace": 0.0, "speed": 1.0, "heavy": false, "hard_hp": 1.0,
        "opening": "LINE", "opening_phase": 0.13,
        "cycle": ["LINE", "WEDGE", "PINCER", "RUSH", "ARMORED", "WARDEN"],
        "elite_at": 0.0, "rule": "none",
        "sky_top": Color("#020509"), "sky_bottom": Color("#081e39"),
        "horizon": Color("#168BFF"), "horizon_core": Color("#67D8FF"), "shape": "crest"
    },
    {
        "code": "ELITE 01", "place": "LAST HORIZON", "tag": "ELITE",
        "brief": "Heavier waves and an elite with escorts at 60%.",
        "seconds": 115.0, "hp": 1.33, "pace": 0.24, "speed": 1.0, "heavy": true, "hard_hp": 1.4,
        "opening": "PINCER", "opening_phase": 0.12,
        "cycle": ["ARMORED", "PINCER", "RUSH", "PHALANX", "WEDGE", "CONVOY", "WARDEN"],
        "elite_at": 0.60, "rule": "none",
        "sky_top": Color("#020509"), "sky_bottom": Color("#081e39"),
        "horizon": Color("#168BFF"), "horizon_core": Color("#67D8FF"), "shape": "crest"
    },
    {
        "code": "SWARM 02", "place": "CINDER RIFT", "tag": "SWARM",
        "brief": "Fast, fragile swarms. Runner surges hit both flanks every 15s.",
        "seconds": 100.0, "hp": 0.92, "pace": 0.30, "speed": 1.10, "heavy": false, "hard_hp": 1.9,
        "opening": "RUSH", "opening_phase": 0.10,
        "cycle": ["SWARM", "RUSH", "PINCER", "SWARM", "WEDGE", "CONVOY"],
        "elite_at": 0.0, "rule": "surge", "rule_every": 15.0,
        "rule_label": "RUNNER SURGE",
        "sky_top": Color("#03031a"), "sky_bottom": Color("#111848"),
        "horizon": Color("#5A7DFF"), "horizon_core": Color("#C3CEFF"), "shape": "twin"
    },
    {
        "code": "SIEGE 03", "place": "IRON SHELF", "tag": "SIEGE",
        "brief": "Armored columns that repair 1.5% HP per second. Burst them down.",
        "seconds": 110.0, "hp": 1.20, "pace": 0.10, "speed": 0.95, "heavy": true, "hard_hp": 1.15,
        "opening": "ARMORED", "opening_phase": 0.10,
        "cycle": ["SIEGE", "ARMORED", "PHALANX", "LINE", "SIEGE", "WEDGE", "WARDEN"],
        "elite_at": 0.72, "rule": "regen", "regen": 0.015,
        "rule_label": "NANITE REPAIR",
        "sky_top": Color("#03070b"), "sky_bottom": Color("#14293b"),
        "horizon": Color("#6FA8C8"), "horizon_core": Color("#D4ECF7"), "shape": "shelf"
    },
    {
        "code": "AMBUSH 04", "place": "DROP ZONE", "tag": "AMBUSH",
        "brief": "Drop pods land squads mid-field every 13s. Watch the warm markers.",
        "seconds": 105.0, "hp": 1.12, "pace": 0.18, "speed": 1.0, "heavy": false, "hard_hp": 2.0,
        "opening": "SCATTER", "opening_phase": 0.10,
        "cycle": ["SCATTER", "PINCER", "LINE", "RUSH", "ARMORED", "SCATTER", "WARDEN"],
        "elite_at": 0.0, "rule": "drop", "rule_every": 13.0, "drop_delay": 1.6,
        "rule_label": "DROP POD",
        "sky_top": Color("#010910"), "sky_bottom": Color("#06283c"),
        "horizon": Color("#19B4E6"), "horizon_core": Color("#8FF0FF"), "shape": "jagged"
    },
    {
        "code": "ELITE 02", "place": "NULL EXPANSE", "tag": "ELITE",
        "brief": "Fog cuts weapon range by 18%. Elite at 50% behind armored waves.",
        "seconds": 120.0, "hp": 1.45, "pace": 0.32, "speed": 1.05, "heavy": true, "hard_hp": 1.3,
        "opening": "PHALANX", "opening_phase": 0.10,
        "cycle": ["PHALANX", "SWARM", "SIEGE", "PINCER", "RUSH", "ARMORED", "CONVOY", "WARDEN"],
        "elite_at": 0.50, "rule": "fog", "range_scale": 0.82,
        "rule_label": "NULL FOG",
        "sky_top": Color("#010205"), "sky_bottom": Color("#0b1331"),
        "horizon": Color("#8AA0D8"), "horizon_core": Color("#E1E9FF"), "shape": "crest"
    }
]

static func count() -> int:
    return MAPS.size()

static func get_map(stage: int) -> Dictionary:
    return MAPS[clampi(stage, 1, MAPS.size()) - 1]

static func value(stage: int, key: String, fallback: Variant = null) -> Variant:
    return get_map(stage).get(key, fallback)

static func rule(stage: int) -> String:
    return String(value(stage, "rule", "none"))

static func has_elite(stage: int) -> bool:
    return float(value(stage, "elite_at", 0.0)) > 0.0

## Playtest builds open every sector so a fresh install can test all maps.
static func is_open(stage: int, stage_unlocked: int, playtest: bool) -> bool:
    if stage < 1 or stage > MAPS.size():
        return false
    return playtest or stage <= stage_unlocked

## Hard-start opener for maps without an authored script: three quick beats
## built from the map's own cycle, so the field is busy from second zero.
static func hard_script(stage: int) -> Array:
    if stage == 1 and GameCatalog.STAGE_ONE_SHOWCASE:
        return GameCatalog.SHOWCASE_SCRIPT
    var cycle: Array = value(stage, "cycle", ["LINE"])
    var rng := RandomNumberGenerator.new()
    rng.seed = 7001 + stage * 31
    var beats: Array = []
    var at := 0.0
    for i in range(3):
        var pattern: String = String(cycle[i % cycle.size()])
        var spawns: Array = []
        # Two copies of the pattern, stacked down-field so they arrive staggered.
        for row in range(2):
            for slot in CombatDirector.build(pattern, stage, 0.55, rng):
                spawns.append([String(slot["kind"]), float(slot["x"]), float(slot["y"]) + 150.0 + row * 120.0])
        # Generated beats use the regular hard scaling, not the tougher
        # intro HP that NORMAL 01's hand-placed script was balanced around.
        beats.append({"at": at, "label": "HARD START • " + pattern, "spawns": spawns, "intro": false})
        at += 4.0
    return beats
