extends SceneTree

## Headless balance probe: plays every sector start to finish, picking the
## first offered upgrade card, once at LEVEL 1, once at LEVEL 1 with the
## Moving Line, and SEEDS times at HARD START. Prints one line per run.
## The bot fires Overdrive as soon as it is ready and never taps to focus.
## (A bot that focused every Warden lost more runs: focus pulls every weapon
## off the front line, so it is a real trade-off, not a free win.)
## Not part of CI; run with `make sim-sectors`.

## HARD START runs per sector; each extra run reseeds formations and cards.
const SEEDS := 3

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    print("sector        start  result   time   hull     lv  kills  breaches  peak  od  line")
    for stage in range(1, SectorCatalog.count() + 1):
        for run in range(3 + SEEDS):
            var hard: bool = run > 2 or run == 2
            var with_line: bool = run == 1 or run == 2
            var arena := Arena.new()
            root.add_child(arena)
            arena.begin_run({"hull": 0, "damage": 0}, stage, true, hard, with_line)
            if run > 3:
                arena.rng.seed = 5000 + run * 977 + stage
            var peak := 0
            var steps := 0
            var line_sum := 0.0
            var line_low := 1.0
            var limit: int = int((GameCatalog.stage_duration(stage) + 90.0) * 30.0)
            while arena.state != "finished" and steps < limit:
                if arena.state == "upgrade":
                    var offers: Array[String] = GameCatalog.upgrade_offers(arena.levels, arena.rng)
                    if offers.is_empty():
                        break
                    arena.choose_upgrade(offers[0])
                if arena.overdrive_ready():
                    arena.trigger_overdrive()
                arena._physics_process(1.0 / 30.0)
                peak = maxi(peak, arena.enemies.size())
                line_sum += arena.line
                line_low = minf(line_low, arena.line)
                steps += 1
            var result: String = "CLEAR" if arena.state == "finished" and arena.hull > 0.0 else (
                "LOST" if arena.state == "finished" else "TIMEOUT")
            print("%-12s  %-5s  %-7s  %5.1f  %3d/%-3d  %2d  %5d  %8d  %4d  %2d  %s" % [
                GameCatalog.stage_name(stage), "HARD" if hard else ("LINE" if with_line else "LV1"),
                result, arena.elapsed, ceili(arena.hull), ceili(arena.max_hull), arena.level,
                arena.kills, arena.breaches, peak, arena.overdrives_fired,
                "avg %3d%% low %3d%%" % [roundi(100.0 * line_sum / maxf(1.0, steps)), roundi(line_low * 100.0)] if with_line else "-"])
            arena.queue_free()
    quit(0)

