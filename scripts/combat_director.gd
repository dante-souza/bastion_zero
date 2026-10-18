class_name CombatDirector
extends RefCounted

## Small, authored formation vocabulary used by both stages.
## Original patterns, deterministic given stage, time, index and RNG.
const PATTERNS := ["LINE", "PINCER", "WEDGE", "ARMORED", "RUSH", "PHALANX"]

static func pattern_for(stage: int, elapsed: float, formation_index: int) -> String:
    var phase: float = clampf(elapsed / GameCatalog.stage_duration(stage), 0.0, 1.0)
    if stage == 1 and phase < 0.13:
        return "LINE"
    if stage == 2 and phase < 0.12:
        return "PINCER"
    if stage == 1:
        var normal := ["LINE", "WEDGE", "PINCER", "RUSH", "ARMORED"]
        return normal[formation_index % normal.size()]
    var elite := ["ARMORED", "PINCER", "RUSH", "PHALANX", "WEDGE"]
    return elite[formation_index % elite.size()]

static func formation(stage: int, elapsed: float, index: int, rng: RandomNumberGenerator) -> Array[Dictionary]:
    var pattern: String = pattern_for(stage, elapsed, index)
    var result: Array[Dictionary] = []
    var center: float = rng.randf_range(245.0, 475.0)
    var phase: float = clampf(elapsed / GameCatalog.stage_duration(stage), 0.0, 1.0)
    match pattern:
        "LINE":
            var count: int = 2 + (1 if phase >= 0.35 else 0) + (1 if phase >= 0.75 else 0)
            for i in range(count):
                var x: float = center + (float(i) - (count - 1.0) * 0.5) * 98.0
                result.append(_slot("grunt" if i % 3 else "runner", x, 155.0))
        "PINCER":
            result.append(_slot("runner", 96.0, 145.0))
            result.append(_slot("runner", 624.0, 145.0))
            result.append(_slot("grunt", 176.0, 92.0))
            result.append(_slot("grunt", 544.0, 92.0))
        "WEDGE":
            result.append(_slot("grunt", center, 175.0))
            result.append(_slot("runner", center - 103.0, 93.0))
            result.append(_slot("runner", center + 103.0, 93.0))
            if phase >= 0.40:
                result.append(_slot("grunt", center - 178.0, 20.0))
                result.append(_slot("grunt", center + 178.0, 20.0))
        "ARMORED":
            result.append(_slot("tank", center, 164.0))
            result.append(_slot("grunt", center - 115.0, 88.0))
            result.append(_slot("grunt", center + 115.0, 88.0))
            if stage == 2:
                result.append(_slot("tank", center + 168.0, 16.0))
        "RUSH":
            for i in range(3 + (1 if stage == 2 or phase >= 0.70 else 0)):
                var x: float = center + (float(i) - 1.5) * 108.0
                result.append(_slot("runner", x, 154.0 - i * 22.0))
        "PHALANX":
            result.append(_slot("tank", center - 135.0, 152.0))
            result.append(_slot("tank", center + 135.0, 152.0))
            result.append(_slot("runner", center, 75.0))
            result.append(_slot("grunt", center - 10.0, 0.0))
    return result

static func _slot(kind: String, x: float, y: float) -> Dictionary:
    return {"kind": kind, "x": clampf(x, 40.0, 680.0), "y": y}
