class_name GameCatalog
extends RefCounted

## Bastion Zero's original combat balance; no third-party game resources.
const GAME_VERSION := "0.9.7-overdrive"
## Phase F: temporary stress showcase on NORMAL 01 only. Not production balance.
const STAGE_ONE_SHOWCASE := true
## Playtest builds open every sector and offer the HARD START toggle
## (LV12 loadout + pressure scaling on any map). Turn off for release.
const PLAYTEST_TOOLS := true
const SHOWCASE_START_LEVEL := 12
const SHOWCASE_LOADOUT := {
    "gun": 4, "beam": 2, "volley": 2, "arc": 2, "nova": 2,
    "rate": 1, "power": 1, "reach": 1
}
const SHOWCASE_ELITE_TIME := 18.0
const SHOWCASE_FORMATIONS_START := 12.0
const SHOWCASE_HP_SCALE := 1.65
const SHOWCASE_INTRO_HP_SCALE := 2.8
const SHOWCASE_ELITE_HP_SCALE := 2.0
const SHOWCASE_SPEED_SCALE := 1.18
const SHOWCASE_DAMAGE_SCALE := 1.35
const SHOWCASE_FORMATION_INTERVAL := 1.20
## HARD START keeps escalating: hostile HP grows by up to +HARD_HP_RAMP
## and formations arrive faster as the stage clock runs out.
const HARD_HP_RAMP := 2.0
const HARD_INTERVAL_END := 0.65
## Less XP per kill so a hard run cannot level its way out of the pressure.
const HARD_XP_SCALE := 0.7
const SHOWCASE_SCRIPT := [
    {
        "at": 0.0, "label": "PRESSURE • THREE FRONTS",
        "spawns": [
            ["grunt", 95.0, 390.0],
            ["runner", 185.0, 430.0],
            ["grunt", 270.0, 385.0],
            ["tank", 370.0, 465.0],
            ["runner", 455.0, 370.0],
            ["grunt", 550.0, 390.0],
            ["tank", 625.0, 495.0],
            ["runner", 325.0, 260.0],
            ["grunt", 510.0, 255.0]
        ]
    },
    {
        "at": 4.0, "label": "SWARM • FAST FLANKS",
        "spawns": [
            ["runner", 85.0, 295.0],
            ["runner", 170.0, 325.0],
            ["runner", 245.0, 300.0],
            ["grunt", 315.0, 350.0],
            ["grunt", 410.0, 335.0],
            ["runner", 500.0, 290.0],
            ["runner", 575.0, 315.0],
            ["runner", 650.0, 295.0]
        ]
    },
    {
        "at": 8.0, "label": "SIEGE • ARMORED WALL",
        "spawns": [
            ["tank", 90.0, 350.0],
            ["tank", 190.0, 365.0],
            ["tank", 290.0, 325.0],
            ["tank", 395.0, 335.0],
            ["tank", 495.0, 360.0],
            ["tank", 605.0, 340.0],
            ["grunt", 140.0, 240.0],
            ["runner", 350.0, 270.0],
            ["grunt", 555.0, 240.0],
            ["runner", 640.0, 255.0]
        ]
    },
    {
        "at": 12.0, "label": "OVERRUN • MIXED SWARM",
        "spawns": [
            ["grunt", 88.0, 370.0],
            ["runner", 155.0, 355.0],
            ["tank", 225.0, 365.0],
            ["grunt", 290.0, 350.0],
            ["runner", 355.0, 345.0],
            ["grunt", 420.0, 360.0],
            ["tank", 490.0, 355.0],
            ["runner", 555.0, 370.0],
            ["grunt", 630.0, 360.0],
            ["runner", 220.0, 220.0],
            ["runner", 430.0, 230.0],
            ["tank", 350.0, 220.0]
        ]
    },
    {
        "at": 18.0, "label": "ELITE • ESCORTED ASSAULT",
        "spawns": [
            ["elite", 360.0, 225.0],
            ["runner", 105.0, 260.0],
            ["runner", 195.0, 290.0],
            ["grunt", 260.0, 315.0],
            ["tank", 465.0, 315.0],
            ["runner", 530.0, 290.0],
            ["runner", 625.0, 260.0],
            ["grunt", 145.0, 360.0],
            ["grunt", 575.0, 365.0]
        ]
    },
    {
        "at": 22.0, "label": "COUNTERATTACK • DOUBLE FLANK",
        "spawns": [
            ["runner", 90.0, 285.0],
            ["runner", 160.0, 310.0],
            ["grunt", 235.0, 325.0],
            ["tank", 315.0, 340.0],
            ["tank", 415.0, 335.0],
            ["grunt", 485.0, 315.0],
            ["runner", 555.0, 300.0],
            ["runner", 635.0, 285.0],
            ["grunt", 270.0, 230.0],
            ["grunt", 440.0, 235.0]
        ]
    }
]
const WORLD_SIZE := Vector2(720.0, 1280.0)
const GUARDIAN := Vector2(360.0, 1080.0)
const BREACH_Y := 1040.0
## Must match SectorCatalog.MAPS.size() (checked by tests/test_smoke.gd).
const TOTAL_STAGES := 6
const STARTING_HEALTH := 100
const UPGRADE_CAP := 4
const META_CAP := 8
const UPGRADE_ORDER: Array[String] = [
    "gun", "gun_payload", "gun_pierce", "gun_ricochet", "gun_volley",
    "beam", "volley", "arc", "nova", "hull", "rate", "power", "reach",
    "od_capacitor", "od_yield", "breaker", "uplink", "line_anchor"
]
const WEAPON_ORDER: Array[String] = ["gun", "beam", "volley", "arc", "nova"]
const GUN_MODS: Array[String] = ["gun_payload", "gun_pierce", "gun_ricochet", "gun_volley"]
const OVERDRIVE_MODS: Array[String] = ["od_capacitor", "od_yield"]
const PRIORITY_MODS: Array[String] = ["breaker", "uplink"]
## Cards a run only offers when it seeded the key in its levels (see Arena.begin_run).
const CONDITIONAL_UPGRADES: Array[String] = ["line_anchor"]

## Enemy relationships. Hostiles inside a Warden's aura, and Runners riding
## behind a living escort Tank, are shielded: they take SHIELD_TAKEN of the damage.
## Wardens themselves are never shielded, so focusing one is the counter.
const SHIELD_TAKEN := 0.45
const WARDEN_AURA := 130.0
## Runners whose escort dies break loose and sprint.
const LOOSE_SPEED_SCALE := 1.35

## Overdrive: an active strike the player fires from the HUD. Kills charge it;
## it hits the focused target (else the densest cluster) and ignores shields.
const OVERDRIVE_FULL := 50.0
## HARD START kills come fast; charge slower so the strike stays a decision.
const HARD_OVERDRIVE_SCALE := 0.7
const OVERDRIVE_RADIUS := 165.0
const OVERDRIVE_DAMAGE := 240.0
const OVERDRIVE_BOOST_SECONDS := 4.0
const OVERDRIVE_BOOST_CADENCE := 1.4

## Moving Line prototype (off unless the playtest setting turns it on).
## Line value 1.0 sits at LINE_TOP_Y, 0.0 at the breach line. Every living
## hostile leans on it (LINE_DRIFT), those past it push harder (LINE_PUSH);
## kills push it up. At 0.0 the core takes LINE_CORE_DPS.
const LINE_START := 0.6
const LINE_DRIFT := 0.0026
const LINE_DRIFT_CAP := 12.0
const LINE_TOP_Y := 360.0
const LINE_PUSH := 0.0055
const LINE_KILL := 0.006
const LINE_CORE_DPS := 5.0
const LINE_HIGH := 0.70
const LINE_LOW := 0.30
const LINE_HIGH_CADENCE := 1.12
const LINE_HIGH_XP := 1.2
const LINE_LOW_RANGE := 0.85
const LINE_SLAM := 0.25

static func upgrade_cap(key: String) -> int:
    match key:
        "gun_payload": return 3
        "gun_pierce": return 2
        "gun_ricochet": return 2
        "gun_volley": return 2
        "od_capacitor", "od_yield", "breaker", "uplink", "line_anchor": return 3
    return UPGRADE_CAP


## Overdrive charge per kill, by enemy weight.
static func overdrive_charge_for(kind: String) -> float:
    match kind:
        "tank": return 3.0
        "warden": return 4.0
        "elite": return 12.0
    return 1.0


## How hard a hostile leans on (or a kill lifts) the Moving Line.
static func line_weight(kind: String) -> float:
    match kind:
        "tank": return 2.0
        "elite": return 4.0
    return 1.0

static func upgrade_category(key: String, current_rank: int) -> String:
    if WEAPON_ORDER.has(key) and current_rank == 0:
        return "NEW WEAPON"
    if GUN_MODS.has(key):
        return "SENTINEL MOD"
    if OVERDRIVE_MODS.has(key):
        return "OVERDRIVE"
    if PRIORITY_MODS.has(key):
        return "TARGET PRIORITY"
    if key == "line_anchor":
        return "MOVING LINE"
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
    elif enemy_kind == "warden":
        match weapon:
            "arc": return 1.20
    return 1.0

static func stage_name(stage: int) -> String:
    return String(SectorCatalog.value(stage, "code", "NORMAL 01"))

static func stage_duration(stage: int) -> float:
    return float(SectorCatalog.value(stage, "seconds", 96.0))

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
        "od_capacitor": return "OVERDRIVE CAPACITOR"
        "od_yield": return "OVERDRIVE YIELD"
        "breaker": return "SHIELD BREAKER"
        "uplink": return "TARGET UPLINK"
        "line_anchor": return "LINE ANCHOR"
    return key.to_upper()

static func upgrade_description(key: String, rank: int) -> String:
    match key:
        "gun":
            match rank:
                2: return "Faster automatic fire (+30% cadence)."
                3: return "Dual-barrel bursts: two aimed rounds per volley."
                _: return "Smart tracers: faster rounds and improved tracking."
        "gun_payload": return "+25% damage per Sentinel round."
        # Phase I.6: player-facing copy per rank, read from Arena's real
        # thresholds (beam pierce = 1 + rank, twin beam at 3; comets = 2 + rank,
        # blast at 3, fragments at 4; arc strikes = 1 + rank, stun at 3;
        # nova radius and slow grow every rank).
        "gun_pierce": return "Rounds pass through %s." % _count(rank, "extra enemy", "extra enemies")
        "gun_ricochet": return "After piercing, rounds bounce to %s nearby." % _count(rank, "enemy", "enemies")
        "gun_volley": return "+%s per burst, each aimed separately." % _count(rank, "Sentinel round", "Sentinel rounds")
        "beam":
            match rank:
                1: return "Unlock a beam that pierces up to 2 enemies in a line."
                2: return "Beam pierces up to 3 enemies. Arc Relay chains +1 jump."
                3: return "Twin beam: a second ray locks onto another enemy."
                _: return "Beam pierces up to %d enemies, fires faster and hits harder." % (1 + rank)
        "volley":
            match rank:
                1: return "Unlock homing comets: 3 per salvo."
                2: return "4 comets per salvo. With Nova Field rank 2, novas detonate twice."
                3: return "5 comets per salvo; every impact bursts in an area."
                _: return "%d comets per salvo; impacts split into 3 fragments." % (2 + rank)
        "arc":
            match rank:
                1: return "Unlock chain lightning that strikes 2 enemies."
                2: return "Lightning strikes 3 enemies and reaches further."
                3: return "Lightning strikes 4 enemies and briefly stuns each one."
                _: return "Lightning strikes %d enemies, faster and harder." % (1 + rank)
        "nova":
            match rank:
                1: return "Unlock a field that blasts the densest cluster and slows it."
                2: return "Wider blast, longer slow. With Comet Volley rank 2, it detonates twice."
                _: return "Wider blast, longer slow and a faster pulse."
        "hull": return "+22 maximum hull, repair 25."
        "rate": return "+13% fire rate for every weapon."
        "power": return "+15% damage for every weapon."
        "reach": return "+12% targeting range for every weapon."
        "od_capacitor":
            match rank:
                3: return "Overdrive charges 90% faster and its fire-rate surge lasts 6 seconds."
                _: return "Overdrive charges %d%% faster from kills." % (30 * rank)
        "od_yield":
            match rank:
                1: return "Overdrive strike: +40% damage and a wider blast."
                2: return "Overdrive strike: +80% damage; survivors are stunned."
                _: return "Overdrive strike: +120% damage; refunds 30% of its charge."
        "breaker":
            match rank:
                1: return "Shields block less: shielded enemies take 60% damage."
                2: return "Shielded enemies take 75% damage; Wardens take 40% more."
                _: return "Shielded enemies take 90% damage; a dying Warden bursts."
        "uplink":
            match rank:
                1: return "Your focused target takes 20% more damage."
                2: return "Focused target takes 40% more; killing it charges Overdrive."
                _: return "Focused target takes 60% more; the lock jumps to the next Warden."
        "line_anchor": return "Kills push the Moving Line up %d%% harder." % (35 * rank)
    return "System upgrade."

static func _count(n: int, one: String, many: String) -> String:
    return "%d %s" % [n, one if n == 1 else many]

static func next_level_xp(level: int) -> int:
    return 15 + int(pow(float(maxi(1, level)), 1.32) * 7.0)

static func upgrade_available(levels: Dictionary, key: String) -> bool:
    if CONDITIONAL_UPGRADES.has(key) and not levels.has(key):
        return false
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
