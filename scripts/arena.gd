class_name Arena
extends Node2D

signal stats_changed(stats: Dictionary)
signal upgrade_requested(offers: Array[String])
signal run_completed(victory: bool, report: Dictionary)

const C := GameCatalog.CORE_POSITION
const CYAN := Color(0.23, 0.88, 0.99)
const GOLD := Color(1.0, 0.76, 0.27)
const PINK := Color(1.0, 0.32, 0.56)
const BLUE := Color(0.40, 0.54, 1.0)

var state: String = "idle"
var elapsed := 0.0
var wave := 1
var level := 1
var xp := 0
var kills := 0
var hull := 100.0
var max_hull := 100.0
var focused_id := -1
var next_enemy_id := 1
var levels: Dictionary = {}
var meta: Dictionary = {"hull": 0, "damage": 0}
var enemies: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()

var _spawn_timer := 0.0
var _pulse_timer := 0.0
var _arc_timer := 0.0
var _rail_timer := 0.0
var _mine_timer := 0.0
var _hud_timer := 0.0
var _visual_clock := 0.0
var _boss_spawned: Dictionary = {}

func _ready() -> void:
    rng.randomize()
    set_process(true)
    set_physics_process(true)

func begin_run(permanent_upgrades: Dictionary) -> void:
    meta = permanent_upgrades.duplicate(true)
    levels = {
        "pulse": 1, "arc": 0, "rail": 0, "mine": 0,
        "hull": 0, "rate": 0, "power": 0, "reach": 0
    }
    elapsed = 0.0
    wave = 1
    level = 1
    xp = 0
    kills = 0
    next_enemy_id = 1
    focused_id = -1
    max_hull = float(GameCatalog.STARTING_HEALTH + int(meta.get("hull", 0)) * 16)
    hull = max_hull
    enemies.clear()
    projectiles.clear()
    effects.clear()
    _boss_spawned.clear()
    _spawn_timer = 0.9
    _pulse_timer = 0.2
    _arc_timer = 1.0
    _rail_timer = 2.0
    _mine_timer = 2.5
    _hud_timer = 0.0
    state = "running"
    stats_changed.emit(snapshot())
    queue_redraw()

func snapshot() -> Dictionary:
    return {
        "state": state,
        "wave": wave,
        "total_waves": GameCatalog.TOTAL_WAVES,
        "time": elapsed,
        "level": level,
        "xp": xp,
        "next_xp": GameCatalog.next_level_xp(level),
        "kills": kills,
        "hull": hull,
        "max_hull": max_hull,
        "weapons": levels.duplicate(),
        "focus": focused_id
    }

func toggle_pause() -> void:
    if state == "running":
        state = "paused"
    elif state == "paused":
        state = "running"
    stats_changed.emit(snapshot())

func focus_at(world_point: Vector2) -> void:
    if state != "running":
        return
    var closest := -1
    var distance := 58.0
    for enemy in enemies:
        var d: float = world_point.distance_to(enemy["pos"])
        if d < distance:
            closest = int(enemy["id"])
            distance = d
    focused_id = closest
    stats_changed.emit(snapshot())

func choose_upgrade(key: String) -> void:
    if state != "upgrade" or not levels.has(key):
        return
    if int(levels[key]) >= GameCatalog.UPGRADE_CAP:
        return
    levels[key] = int(levels[key]) + 1
    if key == "hull":
        max_hull += 22.0
        hull = minf(max_hull, hull + 20.0)
    state = "running"
    stats_changed.emit(snapshot())

func _process(delta: float) -> void:
    _visual_clock += delta
    queue_redraw()

func _physics_process(delta: float) -> void:
    if state != "running":
        return
    elapsed += delta
    _update_waves()
    _spawn_timer -= delta
    if _spawn_timer <= 0.0 and elapsed < GameCatalog.TOTAL_WAVES * GameCatalog.WAVE_SECONDS:
        _spawn_enemy(_roll_enemy_type())
        _spawn_timer = maxf(0.54, 1.7 - float(wave) * 0.115) * rng.randf_range(0.75, 1.2)
    _move_enemies(delta)
    if state != "running":
        return
    _move_projectiles(delta)
    _update_effects(delta)
    _tick_weapons(delta)
    _check_level_up()
    if state != "running":
        return
    _check_victory()
    _hud_timer -= delta
    if _hud_timer <= 0.0:
        _hud_timer = 0.15
        stats_changed.emit(snapshot())

func _update_waves() -> void:
    var new_wave: int = mini(GameCatalog.TOTAL_WAVES, int(elapsed / GameCatalog.WAVE_SECONDS) + 1)
    if new_wave != wave:
        wave = new_wave
        _effect("shockwave", C, C, 165.0, GOLD, 0.9)
    if (wave == 4 or wave == 8) and not _boss_spawned.has(wave):
        _boss_spawned[wave] = true
        _spawn_enemy("boss")

func _roll_enemy_type() -> String:
    var roll: float = rng.randf()
    if wave >= 3 and roll < 0.13 + wave * 0.012:
        return "tank"
    if roll < 0.38:
        return "runner"
    return "grunt"

func _spawn_enemy(kind: String) -> void:
    var angle: float = rng.randf_range(0.0, TAU)
    var pos := C + Vector2.from_angle(angle) * 760.0
    var health: float = 25.0
    var speed: float = 52.0
    var radius: float = 15.0
    var damage: float = 5.0
    var xp_value := 4
    match kind:
        "runner":
            health = 16.0
            speed = 95.0
            radius = 11.0
            damage = 4.0
            xp_value = 4
        "tank":
            health = 110.0
            speed = 34.0
            radius = 24.0
            damage = 12.0
            xp_value = 11
        "boss":
            health = 700.0
            speed = 28.0
            radius = 47.0
            damage = 24.0
            xp_value = 90
    var mult: float = 1.0 + (wave - 1) * 0.19
    enemies.append({
        "id": next_enemy_id,
        "kind": kind, "pos": pos, "hp": health * mult, "max_hp": health * mult,
        "speed": speed * (1.0 + wave * 0.012),
        "radius": radius, "damage": damage, "xp": xp_value
    })
    next_enemy_id += 1

func _move_enemies(delta: float) -> void:
    for i in range(enemies.size() - 1, -1, -1):
        var enemy: Dictionary = enemies[i]
        var direction: Vector2 = (C - enemy["pos"]).normalized()
        enemy["pos"] += direction * float(enemy["speed"]) * delta
        if enemy["pos"].distance_to(C) <= 32.0 + float(enemy["radius"]):
            hull = maxf(0.0, hull - float(enemy["damage"]))
            _effect("shockwave", C, C, 82.0, PINK, 0.5)
            if focused_id == int(enemy["id"]):
                focused_id = -1
            enemies.remove_at(i)
            if hull <= 0.0:
                _finish(false)
                return

func _move_projectiles(delta: float) -> void:
    for i in range(projectiles.size() - 1, -1, -1):
        var bullet: Dictionary = projectiles[i]
        bullet["pos"] += bullet["velocity"] * delta
        bullet["life"] = float(bullet["life"]) - delta
        var hit_id := -1
        for enemy in enemies:
            if bullet["pos"].distance_to(enemy["pos"]) <= float(enemy["radius"]) + 7.0:
                hit_id = int(enemy["id"])
                break
        if hit_id >= 0:
            var at: Vector2 = bullet["pos"]
            _damage_by_id(hit_id, float(bullet["damage"]))
            _effect("hit", at, at, 22.0, CYAN, 0.22)
            projectiles.remove_at(i)
        elif float(bullet["life"]) <= 0.0:
            projectiles.remove_at(i)

func _update_effects(delta: float) -> void:
    for i in range(effects.size() - 1, -1, -1):
        effects[i]["ttl"] = float(effects[i]["ttl"]) - delta
        if float(effects[i]["ttl"]) <= 0.0:
            effects.remove_at(i)

func _tick_weapons(delta: float) -> void:
    var cadence: float = 1.0 + int(levels["rate"]) * 0.12
    _pulse_timer -= delta
    _arc_timer -= delta
    _rail_timer -= delta
    _mine_timer -= delta
    if _pulse_timer <= 0.0:
        _pulse_timer = 0.59 / cadence
        _fire_pulse()
    if int(levels["arc"]) > 0 and _arc_timer <= 0.0:
        _arc_timer = maxf(0.75, 2.1 - int(levels["arc"]) * 0.13) / cadence
        _fire_arc()
    if int(levels["rail"]) > 0 and _rail_timer <= 0.0:
        _rail_timer = maxf(1.1, 3.4 - int(levels["rail"]) * 0.28) / cadence
        _fire_rail()
    if int(levels["mine"]) > 0 and _mine_timer <= 0.0:
        _mine_timer = maxf(1.2, 4.0 - int(levels["mine"]) * 0.35) / cadence
        _fire_mine()

func _range(base: float) -> float:
    return base * (1.0 + int(levels["reach"]) * 0.12)

func _damage(base: float) -> float:
    return base * (1.0 + int(levels["power"]) * 0.14 + int(meta.get("damage", 0)) * 0.1)

func _target_index(max_distance: float) -> int:
    var limit: float = max_distance
    var result := -1
    for i in range(enemies.size()):
        var enemy: Dictionary = enemies[i]
        var dist: float = C.distance_to(enemy["pos"])
        if int(enemy["id"]) == focused_id and dist <= max_distance:
            return i
        if dist < limit:
            limit = dist
            result = i
    return result

func _fire_pulse() -> void:
    var idx: int = _target_index(_range(520.0))
    if idx == -1:
        return
    var aim: Vector2 = (enemies[idx]["pos"] - C).normalized()
    projectiles.append({
        "pos": C + aim * 40.0,
        "velocity": aim * (720.0 + int(levels["pulse"]) * 70.0),
        "damage": _damage(12.0 + int(levels["pulse"]) * 5.0),
        "life": 1.2
    })
    _effect("hit", C + aim * 44.0, C + aim * 44.0, 14.0, CYAN, 0.12)

func _fire_arc() -> void:
    var idx: int = _target_index(_range(450.0))
    if idx == -1:
        return
    var jumps: int = 1 + int(levels["arc"])
    var point: Vector2 = C
    var next_id: int = int(enemies[idx]["id"])
    var seen: Array[int] = []
    for jump in range(jumps):
        var next_index: int = _index_by_id(next_id)
        if next_index == -1:
            break
        var hit_pos: Vector2 = enemies[next_index]["pos"]
        var damage: float = _damage(15.0 + int(levels["arc"]) * 5.0) * pow(0.83, jump)
        _damage_by_id(next_id, damage)
        _effect("beam", point, hit_pos, 3.0, BLUE, 0.28)
        seen.append(next_id)
        point = hit_pos
        var limit: float = _range(145.0)
        next_id = -1
        for enemy in enemies:
            var d: float = point.distance_to(enemy["pos"])
            if not seen.has(int(enemy["id"])) and d < limit:
                limit = d
                next_id = int(enemy["id"])
        if next_id == -1:
            break

func _fire_rail() -> void:
    var idx: int = _target_index(_range(650.0))
    if idx == -1:
        return
    var direction: Vector2 = (enemies[idx]["pos"] - C).normalized()
    var end: Vector2 = C + direction * 840.0
    _effect("beam", C, end, 8.0, GOLD, 0.3)
    var pierced := 0
    var max_pierce: int = 2 + int(levels["rail"]) / 2
    var hit_ids: Array[int] = []
    for enemy in enemies:
        var offset: Vector2 = enemy["pos"] - C
        var projection: float = offset.dot(direction)
        if projection > 0.0 and projection <= 840.0:
            var deviation: float = (offset - direction * projection).length()
            if deviation < float(enemy["radius"]) + 13.0:
                hit_ids.append(int(enemy["id"]))
    for id in hit_ids:
        if pierced >= max_pierce:
            break
        _damage_by_id(id, _damage(70.0 + int(levels["rail"]) * 22.0))
        pierced += 1
    # ARC + RAIL: the rail discharge seeks one additional conductive target.
    if int(levels["arc"]) >= 2 and not hit_ids.is_empty():
        var bonus: int = _target_index(_range(420.0))
        if bonus >= 0:
            _damage_by_id(int(enemies[bonus]["id"]), _damage(24.0))

func _fire_mine() -> void:
    var best_idx: int = -1
    var best_score := -1
    var reach: float = _range(560.0)
    var radius: float = 92.0 + int(levels["mine"]) * 7.0
    for i in range(enemies.size()):
        var pos: Vector2 = enemies[i]["pos"]
        if pos.distance_to(C) > reach:
            continue
        var score := 0
        for e in enemies:
            if pos.distance_to(e["pos"]) < radius:
                score += 1
        if score > best_score:
            best_idx = i
            best_score = score
    if best_idx == -1:
        return
    var blast: Vector2 = enemies[best_idx]["pos"]
    _effect("shockwave", blast, blast, radius, GOLD, 0.55)
    var victims: Array[int] = []
    for enemy in enemies:
        if blast.distance_to(enemy["pos"]) <= radius + float(enemy["radius"]):
            victims.append(int(enemy["id"]))
    for id in victims:
        _damage_by_id(id, _damage(35.0 + int(levels["mine"]) * 14.0))
    # PULSE + MINES: fragmentation bonus increases with pulse array level.
    if int(levels["pulse"]) >= 3:
        for id in victims:
            _damage_by_id(id, _damage(9.0 + int(levels["pulse"]) * 3.0))
    # ARC + MINES: charged blast damages a surviving nearby foe.
    if int(levels["arc"]) >= 3:
        var nearest: int = _nearest_to(blast, radius * 1.7)
        if nearest >= 0:
            _damage_by_id(int(enemies[nearest]["id"]), _damage(22.0))

func _nearest_to(pos: Vector2, radius: float) -> int:
    var result := -1
    var closest := radius
    for i in range(enemies.size()):
        var d: float = pos.distance_to(enemies[i]["pos"])
        if d < closest:
            closest = d
            result = i
    return result

func _index_by_id(id: int) -> int:
    for i in range(enemies.size()):
        if int(enemies[i]["id"]) == id:
            return i
    return -1

func _damage_by_id(id: int, amount: float) -> void:
    var idx: int = _index_by_id(id)
    if idx < 0:
        return
    var enemy: Dictionary = enemies[idx]
    enemy["hp"] = float(enemy["hp"]) - amount
    if float(enemy["hp"]) <= 0.0:
        var point: Vector2 = enemy["pos"]
        _effect("shockwave", point, point, float(enemy["radius"]) * 2.1, PINK, 0.35)
        xp += int(enemy["xp"])
        kills += 1
        if focused_id == id:
            focused_id = -1
        enemies.remove_at(idx)

func _check_level_up() -> void:
    var cost: int = GameCatalog.next_level_xp(level)
    if xp < cost:
        return
    xp -= cost
    level += 1
    var offers: Array[String] = GameCatalog.upgrade_offers(levels, rng)
    if offers.is_empty():
        return
    state = "upgrade"
    stats_changed.emit(snapshot())
    upgrade_requested.emit(offers)

func _check_victory() -> void:
    if elapsed < GameCatalog.TOTAL_WAVES * GameCatalog.WAVE_SECONDS:
        return
    for enemy in enemies:
        if enemy["kind"] == "boss":
            return
    _finish(true)

func _finish(victory: bool) -> void:
    if state == "finished":
        return
    state = "finished"
    stats_changed.emit(snapshot())
    run_completed.emit(victory, {
        "wave": wave, "kills": kills, "time": elapsed, "level": level,
        "reward": GameCatalog.reward(kills, wave, victory)
    })

func _effect(kind: String, a: Vector2, b: Vector2, radius: float, color: Color, duration: float) -> void:
    effects.append({
        "kind": kind, "a": a, "b": b, "radius": radius,
        "color": color, "ttl": duration, "duration": duration
    })

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, GameCatalog.WORLD_SIZE), Color(0.027, 0.048, 0.095), true)
    for y in range(0, 1281, 80):
        draw_line(Vector2(0, y), Vector2(720, y), Color(0.09, 0.19, 0.30, 0.48), 1.0)
    for x in range(0, 721, 80):
        draw_line(Vector2(x, 0), Vector2(x, 1280), Color(0.09, 0.19, 0.30, 0.48), 1.0)
    var pulse: float = sin(_visual_clock * 2.2) * 5.0
    draw_arc(C, 106.0 + pulse, 0, TAU, 80, Color(0.12, 0.49, 0.61, 0.24), 2.0, true)
    draw_arc(C, 178.0 - pulse, 0, TAU, 80, Color(0.12, 0.38, 0.59, 0.14), 2.0, true)
    draw_circle(C, 47.0, Color(0.04, 0.17, 0.28))
    draw_arc(C, 47.0, 0, TAU, 64, CYAN, 5.0, true)
    draw_circle(C, 26.0, CYAN)
    draw_circle(C, 13.0, Color.WHITE)
    var core_triangle := PackedVector2Array([
        C + Vector2(0, -28), C + Vector2(25, 20), C + Vector2(-25, 20)
    ])
    draw_colored_polygon(core_triangle, Color(0.06, 0.23, 0.40))
    for enemy in enemies:
        var at: Vector2 = enemy["pos"]
        var rad: float = float(enemy["radius"])
        var color: Color = PINK
        match String(enemy["kind"]):
            "runner": color = Color(0.99, 0.64, 0.31)
            "tank": color = Color(0.70, 0.40, 0.99)
            "boss": color = Color(1.0, 0.25, 0.37)
        draw_circle(at, rad + 4.0, color.darkened(0.64))
        draw_circle(at, rad, color)
        draw_circle(at, rad * 0.44, Color(0.09, 0.10, 0.20))
        if enemy["kind"] == "boss":
            draw_arc(at, rad + 15.0 + sin(_visual_clock * 3.0) * 3.0, 0, TAU, 56, color, 3.0, true)
        var health_part: float = clampf(float(enemy["hp"]) / float(enemy["max_hp"]), 0.0, 1.0)
        draw_rect(Rect2(at + Vector2(-rad, -rad - 15), Vector2(rad * 2.0, 4)), Color(0.18, 0.25, 0.34))
        draw_rect(Rect2(at + Vector2(-rad, -rad - 15), Vector2(rad * 2.0 * health_part, 4)), CYAN)
        if int(enemy["id"]) == focused_id:
            draw_arc(at, rad + 12, 0, TAU, 40, GOLD, 3.0, true)
            draw_line(at + Vector2(-rad - 18, 0), at + Vector2(-rad - 8, 0), GOLD, 3)
            draw_line(at + Vector2(rad + 8, 0), at + Vector2(rad + 18, 0), GOLD, 3)
    for bullet in projectiles:
        draw_circle(bullet["pos"], 12, Color(0.15, 0.62, 0.82, 0.32))
        draw_circle(bullet["pos"], 6, CYAN)
    for fx in effects:
        var alpha: float = clampf(float(fx["ttl"]) / float(fx["duration"]), 0.0, 1.0)
        var color: Color = fx["color"]
        color.a = alpha
        match String(fx["kind"]):
            "beam":
                draw_line(fx["a"], fx["b"], color, float(fx["radius"]) + 6.0 * alpha, true)
                draw_line(fx["a"], fx["b"], Color(1, 1, 1, alpha), 2.0, true)
            "shockwave":
                draw_arc(fx["a"], float(fx["radius"]) * (1.0 - alpha * 0.5), 0, TAU, 48, color, 5.0, true)
            "hit":
                draw_circle(fx["a"], float(fx["radius"]) * (1.0 - alpha * 0.4), color)
