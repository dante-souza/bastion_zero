extends SceneTree

## Headless combat-simulation benchmark (no rendering, desktop CPU).
## Absolute numbers are not J8 numbers; compare runs on the same machine.
##   godot --headless --path . --script res://tests/bench_combat.gd

const TICK := 1.0 / 60.0

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    _bench_showcase()
    _bench_saturated()
    await _bench_draw()
    quit(0)

## NORMAL 01 showcase, 30 simulated seconds: the scripted J8 stress scene.
func _bench_showcase() -> void:
    var arena := Arena.new()
    root.add_child(arena)
    arena.begin_run({}, 1, true, true)
    var ticks := 0
    var peak_enemies := 0
    var peak_bullets := 0
    var started := Time.get_ticks_usec()
    while arena.elapsed < 30.0 and arena.state != "finished":
        if arena.state == "upgrade":
            var offers: Array[String] = GameCatalog.upgrade_offers(arena.levels, arena.rng)
            arena.state = "upgrade"
            arena.choose_upgrade(offers[0] if not offers.is_empty() else "hull")
            if arena.state == "upgrade":
                arena.state = "running"
        arena._physics_process(TICK)
        ticks += 1
        peak_enemies = maxi(peak_enemies, arena.enemies.size())
        peak_bullets = maxi(peak_bullets, arena.projectiles.size())
    var spent := Time.get_ticks_usec() - started
    print("BENCH showcase: %d ticks, %.1f us/tick, peak %d enemies / %d bullets, %d kills" % [
        ticks, float(spent) / maxf(1.0, ticks), peak_enemies, peak_bullets, arena.kills])
    arena.queue_free()

## Worst case the caps allow: MAX_ENEMIES enemies that never die and a full
## bullet budget, so every tick pays the full projectile-vs-enemy sweep.
func _bench_saturated() -> void:
    var arena := Arena.new()
    root.add_child(arena)
    arena.begin_run({}, 1, true, true)
    arena.enemies.clear()
    arena.projectiles.clear()
    for i in range(Arena.MAX_ENEMIES):
        arena._spawn_enemy("tank", 40.0 + float(i % 12) * 58.0, 180.0 + float(i / 12) * 70.0)
    for enemy in arena.enemies:
        enemy["hp"] = 1.0e12
        enemy["max_hp"] = 1.0e12
        enemy["speed"] = 0.0
    var ticks := 600
    var spent := 0
    for t in range(ticks):
        # Keep the bullet budget full with slow rounds below the formation so
        # each tick sweeps MAX_BULLETS x MAX_ENEMIES pairs.
        while arena.projectiles.size() < Arena.MAX_BULLETS:
            var lane: float = 20.0 + float(arena.projectiles.size() % 34) * 20.0
            arena.projectiles.append({"pos": Vector2(lane, 1150.0), "velocity": Vector2(0.0, -60.0),
                "damage": 1.0, "life": 0.5, "target": -1, "kind": "gun",
                "pierce_left": 0, "ricochet_left": 0, "hit_ids": []})
        arena.state = "running"
        arena.elapsed = 1.0
        var started := Time.get_ticks_usec()
        arena._physics_process(TICK)
        spent += Time.get_ticks_usec() - started
    print("BENCH saturated: %d enemies, %d bullets, %.1f us/tick" % [
        arena.enemies.size(), arena.projectiles.size(), float(spent) / float(ticks)])
    arena.queue_free()

## Script-side _draw cost while the showcase runs in the tree. Headless drops
## the GPU work, so this is only the cost of recording draw commands.
func _bench_draw() -> void:
    var arena := Arena.new()
    root.add_child(arena)
    arena.begin_run({}, 1, true, true)
    var frames := 0
    var draw_total := 0.0
    var peak_draw := 0.0
    var peak_enemies := 0
    # Real time: physics runs at 60 Hz, so this takes ~26 s. Measure from the
    # Elite's entrance (18 s) on, the scene the J8 showed at 27-28 FPS.
    while arena.elapsed < 26.0 and arena.state != "finished":
        if arena.state == "upgrade":
            arena.state = "running"
        await process_frame
        if arena.elapsed < GameCatalog.SHOWCASE_ELITE_TIME:
            continue
        frames += 1
        draw_total += arena.perf_total_draw_usec()
        peak_draw = maxf(peak_draw, arena.perf_total_draw_usec())
        peak_enemies = maxi(peak_enemies, arena.enemies.size())
    print("BENCH draw (elite fight): %d frames, ~%.1f us/frame, peak %.1f us, peak %d enemies" % [
        frames, draw_total / maxf(1.0, frames), peak_draw, peak_enemies])

    arena.queue_free()
