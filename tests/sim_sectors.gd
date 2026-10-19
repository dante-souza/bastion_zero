extends SceneTree

## Headless balance probe: plays every sector start to finish, picking the
## first offered upgrade card, once at LEVEL 1 and SEEDS times at HARD START. Prints one line
## per run. Not part of CI; run with `make sim-sectors`.

## HARD START runs per sector; each extra run reseeds formations and cards.
const SEEDS := 3

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    print("sector        start  result   time   hull     lv  kills  breaches  peak")
    for stage in range(1, SectorCatalog.count() + 1):
        for run in range(1 + SEEDS):
            var hard: bool = run > 0
            var arena := Arena.new()
            root.add_child(arena)
            arena.begin_run({"hull": 0, "damage": 0}, stage, true, hard)
            if run > 1:
                arena.rng.seed = 5000 + run * 977 + stage
            var peak := 0
            var steps := 0
            var limit: int = int((GameCatalog.stage_duration(stage) + 90.0) * 30.0)
            while arena.state != "finished" and steps < limit:
                if arena.state == "upgrade":
                    var offers: Array[String] = GameCatalog.upgrade_offers(arena.levels, arena.rng)
                    if offers.is_empty():
                        break
                    arena.choose_upgrade(offers[0])
                arena._physics_process(1.0 / 30.0)
                peak = maxi(peak, arena.enemies.size())
                steps += 1
            var result: String = "CLEAR" if arena.state == "finished" and arena.hull > 0.0 else (
                "LOST" if arena.state == "finished" else "TIMEOUT")
            print("%-12s  %-5s  %-7s  %5.1f  %3d/%-3d  %2d  %5d  %8d  %4d" % [
                GameCatalog.stage_name(stage), "HARD" if hard else "LV1", result, arena.elapsed,
                ceili(arena.hull), ceili(arena.max_hull), arena.level, arena.kills, arena.breaches, peak])
            arena.queue_free()
    quit(0)
