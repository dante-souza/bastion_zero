class_name GameCatalog
extends RefCounted

## Bastion Zero's original combat balance; no third-party game resources.
const GAME_VERSION := "0.5.1-showcase-hud"
## D.1: temporary, isolated visual-QA progression for NORMAL 01 only.
## Does not change any normal run or ELITE 01 gameplay.
const STAGE_ONE_SHOWCASE := true
const SHOWCASE_START_LEVEL := 12
const SHOWCASE_LOADOUT := {
    "gun": 4, "beam": 2, "volley": 2, "arc": 2, "nova": 2,
    "rate": 1, "power": 1, "reach": 1
}
const SHOWCASE_ELITE_TIME := 20.0
const SHOWCASE_FORMATIONS_START := 24.0
const SHOWCASE_INTRO_HP_SCALE := 3.0
const SHOWCASE_SCRIPT := [
    {
        "at": 0.0, "label": "IDENTIFY • GRUNT / RUNNER / TANK",
        "spawns": [
            ["grunt", 145.0, 445.0], ["runner", 360.0, 415.0],
            ["tank", 565.0, 470.0]
        ]
    },
    {
        "at": 4.0, "label": "ARC RELAY • RUNNER PAIR",
        "spawns": [
            ["runner", 260.0, 350.0], ["runner", 465.0, 350.0]
        ]
    },
    {
        "at": 8.0, "label": "PRISM + COMET • ARMOR",
        "spawns": [
            ["tank", 235.0, 340.0], ["tank", 475.0, 355.0]
        ]
    },
    {
        "at": 12.0, "label": "NOVA • MIXED CLUSTER",
        "spawns": [
            ["grunt", 250.0, 360.0], ["runner", 310.0, 340.0],
            ["grunt", 395.0, 350.0], ["tank", 455.0, 390.0]
        ]
    },
    {
        "at": 20.0, "label": "ELITE • VISUAL TARGET",
        "spawns": [["elite", 360.0, 240.0]]
    }
]
const WORLD_SIZE := Vector2(720.0, 1280.0)
const GUARDIAN := Vector2(360.0, 1080.0)
const BREACH_Y := 1040.0
const TOTAL_STAGES := 2
const STAGE_SECONDS := [96.0, 115.0]
const STARTING_HEALTH := 100
const UPGRADE_CAP := 4
const META_CAP := 8
const UPGRADE_ORDER: Array[String] = [
    "gun", "gun_payload", "gun_pierce", "gun_ricochet", "gun_volley",
    "beam", "volley", "arc", "nova", "hull", "rate", "power", "reach"
]
const WEAPON_ORDER: Array[String] = ["gun", "beam", "volley", "arc", "nova"]
const GUN_MODS: Array[String] = ["gun_payload", "gun_pierce", "gun_ricochet", "gun_volley"]

static func upgrade_cap(key: String) -> int:
    match key:
        "gun_payload": return 3
        "gun_pierce": return 2
        "gun_ricochet": return 2
        "gun_volley": return 2
    return UPGRADE_CAP

static func upgrade_category(key: String, current_rank: int) -> String:
    if WEAPON_ORDER.has(key) and current_rank == 0:
        return "NEW WEAPON"
    if GUN_MODS.has(key):
        return "SENTINEL MOD"
    if WEAPON_ORDER.has(key):
        return "WEAPON EVOLUTION"
    return "SUPPORT SYSTEM"


## Enemy/weapon interactions are explicit, stable, and independent of monetization.
## Multipliers are applied before HP-capped accounting.
static func damage_factor(enemy_kind: String, weapon: String) -> float:
    if enemy_kind == "tank":
        match weapon:
            "beam": return 0.72
            "volley": return 1.30
            "nova": return 1.18
    elif enemy_kind == "runner":
        match weapon:
            "arc": return 1.32
            "volley": return 0.90
    elif enemy_kind == "elite":
        match weapon:
            "beam": return 0.90
            "volley": return 1.12
    return 1.0

static func stage_name(stage: int) -> String:
    return "NORMAL 01" if stage <= 1 else "ELITE 01"

static func stage_duration(stage: int) -> float:
    return STAGE_SECONDS[clampi(stage, 1, TOTAL_STAGES) - 1]

static func upgrade_name(key: String) -> String:
    match key:
        "gun": return "SENTINEL AUTOCANNON"
        "gun_payload": return "KINETIC PAYLOAD"
        "gun_pierce": return "SABOT PIERCER"
        "gun_ricochet": return "RICOCHET ROUTING"
        "gun_volley": return "SATURATION BURST"
        "beam": return "PRISM BEAM"
        "volley": return "COMET VOLLEY"
        "arc": return "ARC RELAY"
        "nova": return "NOVA FIELD"
        "hull": return "REINFORCED HULL"
        "rate": return "OVERCLOCK"
        "power": return "AMPLIFIER"
        "reach": return "RANGE ARRAY"
    return key.to_upper()

static func upgrade_description(key: String, rank: int) -> String:
    match key:
        "gun":
            match rank:
                2: return "Faster automatic fire (+30% cadence)."
                3: return "Dual-barrel bursts: two aimed rounds per volley."
                _: return "Smart tracers: faster rounds and improved tracking."
        "gun_payload": return "+25% damage per Sentinel round."
        "gun_pierce": return "Round passes through %d additional target(s)." % rank
        "gun_ricochet": return "After piercing, ricochet to up to %d nearby target(s)." % rank
        "gun_volley": return "+%d separately aimed Sentinel rounds per burst." % rank
        "beam": return "Unlock pinpoint beam / +pierce; twin beam acquires another enemy."
        "volley": return "Unlock rockets / add lanes, then split + blast. Rank %d" % rank
        "arc": return "Unlock chain lightning / more jumps and stun. Rank %d" % rank
        "nova": return "Unlock field / bigger slow pulse and detonation. Rank %d" % rank
        "hull": return "+22 maximum hull, repair 25."
        "rate": return "+13% fire rate for every weapon."
        "power": return "+15% damage for every weapon."
        "reach": return "+12% targeting range for every weapon."
    return "System upgrade."

static func next_level_xp(level: int) -> int:
    return 15 + int(pow(float(maxi(1, level)), 1.32) * 7.0)

static func upgrade_available(levels: Dictionary, key: String) -> bool:
    return UPGRADE_ORDER.has(key) and int(levels.get(key, 0)) < upgrade_cap(key)

static func upgrade_offers(levels: Dictionary, rng: RandomNumberGenerator, count: int = 3) -> Array[String]:
    var available: Array[String] = []
    var locked: Array[String] = []
    var sentinel_options: Array[String] = []
    for key in UPGRADE_ORDER:
        if upgrade_available(levels, key):
            available.append(key)
            if WEAPON_ORDER.has(key) and int(levels.get(key, 0)) == 0:
                locked.append(key)
            if key == "gun" or GUN_MODS.has(key):
                sentinel_options.append(key)
    if available.is_empty():
        return []
    _shuffle(available, rng)
    _shuffle(locked, rng)
    _shuffle(sentinel_options, rng)
    var offers: Array[String] = []
    # Always offer an undiscovered weapon, where possible, to avoid an
    # upgrade-only run with no access to the four combat systems.
    if not locked.is_empty() and offers.size() < count:
        offers.append(locked[0])
    # At least one Sentinel evolution while there is an unmaxed gun card.
    if not sentinel_options.is_empty() and offers.size() < count:
        offers.append(sentinel_options[0])
    for key in available:
        if offers.size() >= count:
            break
        if not offers.has(key):
            offers.append(key)
    return offers

static func _shuffle(items: Array[String], rng: RandomNumberGenerator) -> void:
    for i in range(items.size() - 1, 0, -1):
        var j: int = rng.randi_range(0, i)
        var temp: String = items[i]
        items[i] = items[j]
        items[j] = temp

static func meta_cost(stat: String, rank: int) -> int:
    if not ["hull", "damage"].has(stat) or rank < 0 or rank >= META_CAP:
        return -1
    return 40 + int(28.0 * pow(1.5, float(rank)))

static func reward(kills: int, stage: int, victory: bool) -> int:
    return 12 + maxi(0, kills) / 3 + clampi(stage, 1, TOTAL_STAGES) * 9 + (80 if victory else 0)

static func format_time(seconds: float) -> String:
    var t: int = maxi(0, int(seconds))
    return "%02d:%02d" % [t / 60, t % 60]
