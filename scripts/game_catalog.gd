class_name GameCatalog
extends RefCounted

## All tuning is centralized for transparent, non-monetized progression.
const GAME_VERSION := "0.1.1"
const TOTAL_WAVES := 8
const WAVE_SECONDS := 42.0
const WORLD_SIZE := Vector2(720.0, 1280.0)
const CORE_POSITION := Vector2(360.0, 670.0)
const STARTING_HEALTH := 100
const UPGRADE_CAP := 5
const META_CAP := 8

const UPGRADE_ORDER: Array[String] = [
    "pulse", "arc", "rail", "mine", "hull", "rate", "power", "reach"
]

static func upgrade_name(key: String) -> String:
    match key:
        "pulse": return "PULSE ARRAY"
        "arc": return "ARC CONDUCTOR"
        "rail": return "RAIL LANCE"
        "mine": return "NOVA MINES"
        "hull": return "REINFORCED HULL"
        "rate": return "OVERCLOCK"
        "power": return "AMPLIFIER"
        "reach": return "LONG-RANGE RADAR"
    return key.to_upper()

static func upgrade_description(key: String, next_rank: int) -> String:
    match key:
        "pulse": return "+pulse damage and projectile speed. Rank %d" % next_rank
        "arc": return "Lightning chains across nearby enemies. Rank %d" % next_rank
        "rail": return "Precision piercing strike. Rank %d" % next_rank
        "mine": return "Area explosions around approaching threats. Rank %d" % next_rank
        "hull": return "+22 maximum hull and repair 20 hull."
        "rate": return "+12% fire rate for every equipped weapon."
        "power": return "+14% damage for every equipped weapon."
        "reach": return "+12% targeting and chain range."
    return "System enhancement."

static func next_level_xp(level: int) -> int:
    return 12 + int(pow(float(maxi(1, level)), 1.4) * 8.0)

static func upgrade_offers(levels: Dictionary, rng: RandomNumberGenerator, count: int = 3) -> Array[String]:
    var candidates: Array[String] = []
    for key in UPGRADE_ORDER:
        if int(levels.get(key, 0)) < UPGRADE_CAP:
            candidates.append(key)
    # Fisher-Yates: predictable/testable given the RNG seed.
    for i in range(candidates.size() - 1, 0, -1):
        var j: int = rng.randi_range(0, i)
        var old: String = candidates[i]
        candidates[i] = candidates[j]
        candidates[j] = old
    return candidates.slice(0, mini(count, candidates.size()))

static func meta_cost(stat: String, current_rank: int) -> int:
    if stat != "hull" and stat != "damage":
        return -1
    if current_rank < 0 or current_rank >= META_CAP:
        return -1
    return 40 + int(28.0 * pow(1.5, float(current_rank)))

static func reward(kills: int, wave: int, victory: bool) -> int:
    return 10 + maxi(0, kills) / 3 + clampi(wave, 1, TOTAL_WAVES) * 6 + (70 if victory else 0)

static func format_time(seconds: float) -> String:
    var value: int = maxi(0, int(seconds))
    return "%02d:%02d" % [value / 60, value % 60]
