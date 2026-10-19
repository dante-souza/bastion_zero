class_name CombatDirector
extends RefCounted

## Small, authored formation vocabulary shared by every sector.
## Original patterns, deterministic given stage, time, index and RNG.
## Each sector picks its opening and its cycle in SectorCatalog.
const PATTERNS := ["LINE", "PINCER", "WEDGE", "ARMORED", "RUSH", "PHALANX",
    "SWARM", "SIEGE", "SCATTER"]

static func pattern_for(stage: int, elapsed: float, formation_index: int) -> String:
    var phase: float = clampf(elapsed / GameCatalog.stage_duration(stage), 0.0, 1.0)
    if phase < float(SectorCatalog.value(stage, "opening_phase", 0.0)):
        return String(SectorCatalog.value(stage, "opening", "LINE"))
    var cycle: Array = SectorCatalog.value(stage, "cycle", ["LINE"])
    return String(cycle[formation_index % cycle.size()])

static func formation(stage: int, elapsed: float, index: int, rng: RandomNumberGenerator) -> Array[Dictionary]:
    var phase: float = clampf(elapsed / GameCatalog.stage_duration(stage), 0.0, 1.0)
    return build(pattern_for(stage, elapsed, index), stage, phase, rng)

static func build(pattern: String, stage: int, phase: float, rng: RandomNumberGenerator) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var center: float = rng.randf_range(245.0, 475.0)
    var heavy: bool = bool(SectorCatalog.value(stage, "heavy", false))
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
            if heavy:
                result.append(_slot("tank", center + 168.0, 16.0))
        "RUSH":
            for i in range(3 + (1 if heavy or phase >= 0.70 else 0)):
                var x: float = center + (float(i) - 1.5) * 108.0
                result.append(_slot("runner", x, 154.0 - i * 22.0))
        "PHALANX":
            result.append(_slot("tank", center - 135.0, 152.0))
            result.append(_slot("tank", center + 135.0, 152.0))
            result.append(_slot("runner", center, 75.0))
            result.append(_slot("grunt", center - 10.0, 0.0))
        "SWARM":
            # Two tight runner knots, one per half of the field.
            var knot: int = 3 + (1 if phase >= 0.50 else 0)
            for side in [-1.0, 1.0]:
                var cx: float = 360.0 + side * rng.randf_range(130.0, 230.0)
                for i in range(knot):
                    result.append(_slot("runner", cx + (float(i) - (knot - 1.0) * 0.5) * 44.0,
                        150.0 - absf(float(i) - (knot - 1.0) * 0.5) * 26.0))
        "SIEGE":
            # A slow armored wall with grunts sheltering behind it.
            var tanks: int = 3 if phase < 0.60 else 4
            for i in range(tanks):
                result.append(_slot("tank", center + (float(i) - (tanks - 1.0) * 0.5) * 112.0, 160.0))
            result.append(_slot("grunt", center - 60.0, 70.0))
            result.append(_slot("grunt", center + 60.0, 70.0))
        "SCATTER":
            # Loose, unpredictable spread that splits the turret's attention.
            var loose: int = 5 + (1 if phase >= 0.45 else 0)
            for i in range(loose):
                var x: float = 70.0 + (580.0 * (float(i) + rng.randf_range(0.15, 0.85)) / float(loose))
                result.append(_slot("runner" if i % 2 else "grunt", x, rng.randf_range(40.0, 170.0)))
    return result

static func _slot(kind: String, x: float, y: float) -> Dictionary:
    return {"kind": kind, "x": clampf(x, 40.0, 680.0), "y": y}
