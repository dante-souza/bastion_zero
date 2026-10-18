class_name Arena
extends Node2D

signal stats_changed(info: Dictionary)
signal upgrade_requested(offers: Array[String])
signal run_completed(victory: bool, report: Dictionary)

const G := GameCatalog.GUARDIAN
const CYAN := Color("#5feeff")
const GOLD := Color("#ffca66")
const RED := Color("#ff6486")
const BLUE := Color("#7894ff")
const GREEN := Color("#8ef3b2")
const DARK := Color("#091322")
const MAX_ENEMIES := 84
const MAX_BULLETS := 220

var state: String = "idle"
var stage := 1
var elapsed := 0.0
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
var weapon_damage: Dictionary = {}
var rng := RandomNumberGenerator.new()
var low_fx := true
var _spawn_timer := 0.0
var _beam_timer := 0.0
var _volley_timer := 0.0
var _arc_timer := 0.0
var _nova_timer := 0.0
var _hud_timer := 0.0
var _visual_clock := 0.0
var _elite_spawned := false

func _ready() -> void:
    rng.randomize()
    set_process(true)
    set_physics_process(true)

func begin_run(permanent_upgrades: Dictionary, selected_stage: int = 1, reduced_fx: bool = true) -> void:
    meta = permanent_upgrades.duplicate(true)
    stage = clampi(selected_stage, 1, GameCatalog.TOTAL_STAGES)
    low_fx = reduced_fx
    rng.seed = 14057 + stage * 137
    levels = {
        "beam": 1, "volley": 0, "arc": 0, "nova": 0,
        "hull": 0, "rate": 0, "power": 0, "reach": 0
    }
    weapon_damage = {"beam": 0.0, "volley": 0.0, "arc": 0.0, "nova": 0.0}
    elapsed = 0.0
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
    _spawn_timer = 0.8
    _beam_timer = 0.24
    _volley_timer = 1.0
    _arc_timer = 1.3
    _nova_timer = 1.8
    _hud_timer = 0.0
    _visual_clock = 0.0
    _elite_spawned = false
    state = "running"
    stats_changed.emit(snapshot())
    queue_redraw()

func snapshot() -> Dictionary:
    return {
        "stage": stage, "stage_name": GameCatalog.stage_name(stage),
        "state": state, "time": elapsed,
        "duration": GameCatalog.stage_duration(stage),
        "level": level, "xp": xp, "next_xp": GameCatalog.next_level_xp(level),
        "kills": kills, "hull": hull, "max_hull": max_hull,
        "weapons": levels.duplicate(), "focus": focused_id,
        "enemies": enemies.size(), "damage": weapon_damage.duplicate()
    }

func toggle_pause() -> void:
    if state == "running":
        state = "paused"
    elif state == "paused":
        state = "running"
    stats_changed.emit(snapshot())

func focus_at(point: Vector2) -> void:
    if state != "running":
        return
    var nearest := -1
    var shortest := 72.0
    for enemy in enemies:
        var distance: float = (point - Vector2(enemy["pos"])).length()
        if distance < shortest:
            shortest = distance
            nearest = int(enemy["id"])
    focused_id = nearest
    stats_changed.emit(snapshot())

func choose_upgrade(kind: String) -> void:
    if state != "upgrade" or not levels.has(kind):
        return
    if int(levels[kind]) >= GameCatalog.UPGRADE_CAP:
        return
    levels[kind] = int(levels[kind]) + 1
    if kind == "hull":
        max_hull += 22.0
        hull = minf(max_hull, hull + 25.0)
    state = "running"
    stats_changed.emit(snapshot())

func _process(delta: float) -> void:
    if state == "running":
        _visual_clock += delta
        queue_redraw()

func _physics_process(delta: float) -> void:
    if state != "running":
        return
    elapsed += delta
    _spawn_timer -= delta
    if elapsed < GameCatalog.stage_duration(stage) and _spawn_timer <= 0.0:
        _spawn_formation()
        var progress: float = minf(1.0, elapsed / GameCatalog.stage_duration(stage))
        _spawn_timer = (1.32 - 0.59 * progress - float(stage - 1) * 0.12) * rng.randf_range(0.83, 1.2)
    if stage == 2 and not _elite_spawned and elapsed > GameCatalog.stage_duration(stage) * 0.60:
        _elite_spawned = true
        _spawn_enemy("elite", 360.0, 155.0)
    _move_enemies(delta)
    if state != "running":
        return
    _move_projectiles(delta)
    _update_effects(delta)
    _tick_weapons(delta)
    _check_level_up()
    if state != "running":
        return
    _check_finish()
    _hud_timer -= delta
    if _hud_timer <= 0.0:
        _hud_timer = 0.15
        stats_changed.emit(snapshot())

func _spawn_formation() -> void:
    if enemies.size() >= MAX_ENEMIES:
        return
    var phase: float = elapsed / GameCatalog.stage_duration(stage)
    var count := 1
    if phase > 0.28:
        count = 2
    if phase > 0.65 or stage == 2 and phase > 0.40:
        count = 3
    var origin_x: float = rng.randf_range(140.0, 570.0)
    for i in range(count):
        if enemies.size() >= MAX_ENEMIES:
            break
        var choice: float = rng.randf()
        var kind := "grunt"
        if choice < 0.29 + (0.08 if stage == 2 else 0.0):
            kind = "runner"
        elif choice > 0.85 - phase * 0.20:
            kind = "tank"
        var x: float = clampf(origin_x + (i - (count - 1.0) / 2.0) * 92.0, 35.0, 685.0)
        _spawn_enemy(kind, x, 170.0 - i * 46.0)

func _spawn_enemy(kind: String, x: float = 360.0, y: float = 150.0) -> void:
    var hp := 29.0
    var speed := 82.0
    var radius := 16.0
    var hit := 7.0
    var reward_xp := 11
    match kind:
        "runner":
            hp = 17.0
            speed = 144.0
            radius = 12.0
            hit = 6.0
            reward_xp = 9
        "tank":
            hp = 115.0
            speed = 57.0
            radius = 27.0
            hit = 13.0
            reward_xp = 22
        "elite":
            hp = 900.0
            speed = 49.0
            radius = 48.0
            hit = 28.0
            reward_xp = 95
    var scaling: float = 1.0 + (stage - 1) * 0.33 + (elapsed / GameCatalog.stage_duration(stage)) * 0.55
    enemies.append({
        "id": next_enemy_id, "kind": kind, "pos": Vector2(x, y),
        "origin_x": x, "hp": hp * scaling, "max_hp": hp * scaling,
        "speed": speed, "radius": radius, "damage": hit,
        "xp": reward_xp, "slow": 0.0, "stun": 0.0,
        "phase": rng.randf_range(0.0, TAU)
    })
    next_enemy_id += 1

func _move_enemies(delta: float) -> void:
    for i in range(enemies.size() - 1, -1, -1):
        var enemy: Dictionary = enemies[i]
        var pos: Vector2 = enemy["pos"]
        var slow: float = float(enemy["slow"])
        var stun: float = float(enemy["stun"])
        enemy["slow"] = maxf(0.0, slow - delta)
        enemy["stun"] = maxf(0.0, stun - delta)
        if stun <= 0.0:
            pos.y += float(enemy["speed"]) * (0.48 if slow > 0.0 else 1.0) * delta
            pos.x = clampf(float(enemy["origin_x"]) + sin(pos.y * 0.010 + float(enemy["phase"])) * 22.0, 24.0, 696.0)
            enemy["pos"] = pos
        if pos.y >= GameCatalog.BREACH_Y:
            hull = maxf(0.0, hull - float(enemy["damage"]))
            _effect("ring", Vector2(pos.x, GameCatalog.BREACH_Y), Vector2.ZERO, 76.0, RED, 0.42)
            if int(enemy["id"]) == focused_id:
                focused_id = -1
            enemies.remove_at(i)
            if hull <= 0.0:
                _finish(false)
                return

func _move_projectiles(delta: float) -> void:
    for i in range(projectiles.size() - 1, -1, -1):
        var bullet: Dictionary = projectiles[i]
        bullet["life"] = float(bullet["life"]) - delta
        var pos: Vector2 = bullet["pos"]
        var target_idx: int = _index_by_id(int(bullet["target"]))
        var velocity: Vector2 = bullet["velocity"]
        if target_idx >= 0 and String(bullet["kind"]) == "rocket":
            var destination: Vector2 = enemies[target_idx]["pos"]
            var aim: Vector2 = (destination - pos).normalized()
            velocity = velocity.lerp(aim * 670.0, minf(delta * 7.0, 1.0))
            bullet["velocity"] = velocity
        var next: Vector2 = pos + velocity * delta
        bullet["pos"] = next
        var collision := -1
        for enemy in enemies:
            var radius: float = float(enemy["radius"]) + (10.0 if bullet["kind"] == "rocket" else 7.0)
            # Segment collision prevents fast rockets tunneling through runners.
            var along: float = clampf((Vector2(enemy["pos"]) - pos).dot(next - pos) / maxf(0.01, (next - pos).length_squared()), 0.0, 1.0)
            if Vector2(enemy["pos"]).distance_to(pos.lerp(next, along)) <= radius:
                collision = int(enemy["id"])
                break
        if collision >= 0:
            var hit_at: Vector2 = next
            var base_damage: float = float(bullet["damage"])
            if String(bullet["kind"]) == "rocket":
                _damage_by_id(collision, base_damage, "volley")
                if int(levels["volley"]) >= 3:
                    _blast(hit_at, 54.0 + int(levels["volley"]) * 7.0, base_damage * 0.45, "volley", GOLD)
                if int(levels["volley"]) >= 4 and projectiles.size() < MAX_BULLETS - 3:
                    for j in range(3):
                        var velocity_frag := Vector2.from_angle(-PI + j * PI / 2.0) * 450.0
                        projectiles.append({"pos": hit_at, "velocity": velocity_frag, "damage": base_damage * 0.33, "life": 0.36, "target": -1, "kind": "frag"})
            else:
                _damage_by_id(collision, base_damage, "volley")
            _effect("flash", hit_at, Vector2.ZERO, 22.0, GOLD, 0.22)
            projectiles.remove_at(i)
        elif float(bullet["life"]) <= 0.0 or next.y < 110.0 or next.y > 1180.0:
            projectiles.remove_at(i)

func _update_effects(delta: float) -> void:
    for i in range(effects.size() - 1, -1, -1):
        effects[i]["ttl"] = float(effects[i]["ttl"]) - delta
        if float(effects[i]["ttl"]) <= 0.0:
            effects.remove_at(i)

func _tick_weapons(delta: float) -> void:
    var cadence: float = 1.0 + 0.13 * int(levels["rate"])
    _beam_timer -= delta
    _volley_timer -= delta
    _arc_timer -= delta
    _nova_timer -= delta
    if _beam_timer <= 0.0:
        _beam_timer = maxf(0.37, 0.78 - 0.07 * int(levels["beam"])) / cadence
        _fire_beam()
    if int(levels["volley"]) > 0 and _volley_timer <= 0.0:
        _volley_timer = maxf(0.75, 2.35 - 0.19 * int(levels["volley"])) / cadence
        _fire_volley()
    if int(levels["arc"]) > 0 and _arc_timer <= 0.0:
        _arc_timer = maxf(0.85, 2.7 - 0.25 * int(levels["arc"])) / cadence
        _fire_arc()
    if int(levels["nova"]) > 0 and _nova_timer <= 0.0:
        _nova_timer = maxf(1.1, 4.2 - 0.38 * int(levels["nova"])) / cadence
        _fire_nova()

func _range(base: float) -> float:
    return base * (1.0 + 0.12 * int(levels["reach"]))

func _power(base: float) -> float:
    return base * (1.0 + 0.15 * int(levels["power"]) + 0.10 * int(meta.get("damage", 0)))

func _target_index(max_dist: float) -> int:
    var winner := -1
    var highest_y := -100000.0
    for i in range(enemies.size()):
        var enemy: Dictionary = enemies[i]
        if Vector2(enemy["pos"]).distance_to(G) > max_dist:
            continue
        if int(enemy["id"]) == focused_id:
            return i
        var threat: float = Vector2(enemy["pos"]).y + (180.0 if String(enemy["kind"]) == "elite" else 0.0)
        if threat > highest_y:
            winner = i
            highest_y = threat
    return winner

func _fire_beam() -> void:
    var target_idx: int = _target_index(_range(1160.0))
    if target_idx < 0:
        return
    var destination: Vector2 = enemies[target_idx]["pos"]
    var base_angle: float = (destination - G).angle()
    var beams: int = 2 if int(levels["beam"]) >= 3 else 1
    for lane in range(beams):
        var angle: float = base_angle + (float(lane) - (beams - 1.0) / 2.0) * 0.13
        var direction := Vector2.from_angle(angle)
        var end: Vector2 = G + direction * 1300.0
        _effect("beam", G + Vector2(0.0, -42.0), end, 6.0 + int(levels["beam"]), CYAN, 0.22)
        var hits: Array[Dictionary] = []
        for enemy in enemies:
            var offset: Vector2 = Vector2(enemy["pos"]) - G
            var projection: float = offset.dot(direction)
            if projection <= 0.0 or projection > 1300.0:
                continue
            var lateral: float = (offset - direction * projection).length()
            if lateral < float(enemy["radius"]) + 11.0:
                hits.append({"id": int(enemy["id"]), "distance": projection})
        hits.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["distance"]) < float(b["distance"]))
        var pierce: int = 1 + int(levels["beam"])
        for i in range(mini(pierce, hits.size())):
            _damage_by_id(int(hits[i]["id"]), _power(32.0 + int(levels["beam"]) * 12.0), "beam")

func _fire_volley() -> void:
    var target_idx: int = _target_index(_range(1070.0))
    if target_idx < 0:
        return
    var target: Vector2 = enemies[target_idx]["pos"]
    var count := 2 + int(levels["volley"])
    for i in range(count):
        if projectiles.size() >= MAX_BULLETS:
            break
        var pos: Vector2 = G + Vector2((i - (count - 1.0) * 0.5) * 35.0, -30.0)
        var aim: Vector2 = (target + Vector2((i - (count - 1.0) * 0.5) * 36.0, 0.0) - pos).normalized()
        projectiles.append({"pos": pos, "velocity": aim * 610.0, "damage": _power(21.0 + int(levels["volley"]) * 5.0), "life": 1.8, "target": int(enemies[target_idx]["id"]), "kind": "rocket"})

func _fire_arc() -> void:
    var target_idx: int = _target_index(_range(970.0))
    if target_idx < 0:
        return
    var jumps := 1 + int(levels["arc"]) + (1 if int(levels["beam"]) >= 2 else 0)
    var point: Vector2 = G + Vector2(0.0, -35.0)
    var next_id: int = int(enemies[target_idx]["id"])
    var struck: Array[int] = []
    for jump in range(jumps):
        var idx: int = _index_by_id(next_id)
        if idx < 0:
            break
        var pos: Vector2 = enemies[idx]["pos"]
        _effect("beam", point, pos, 3.0, BLUE, 0.27)
        if int(levels["arc"]) >= 3:
            enemies[idx]["stun"] = maxf(float(enemies[idx]["stun"]), 0.33)
        _damage_by_id(next_id, _power(26.0 + int(levels["arc"]) * 8.0) * pow(0.82, jump), "arc")
        struck.append(next_id)
        point = pos
        next_id = -1
        var distance := _range(155.0 + int(levels["arc"]) * 12.0)
        for enemy in enemies:
            var d: float = point.distance_to(enemy["pos"])
            if d < distance and not struck.has(int(enemy["id"])):
                distance = d
                next_id = int(enemy["id"])
        if next_id < 0:
            break

func _fire_nova() -> void:
    var target_idx: int = _target_index(_range(850.0))
    if target_idx < 0:
        return
    var radius := 94.0 + int(levels["nova"]) * 29.0
    var center: Vector2 = enemies[target_idx]["pos"]
    var best_score := -1
    for candidate in enemies:
        var pos: Vector2 = candidate["pos"]
        if pos.distance_to(G) > _range(850.0):
            continue
        var neighbors := 0
        for other in enemies:
            if pos.distance_to(other["pos"]) <= radius:
                neighbors += 1
        if neighbors > best_score:
            best_score = neighbors
            center = pos
    _effect("ring", center, Vector2.ZERO, radius, GREEN, 0.65)
    _blast(center, radius, _power(17.0 + int(levels["nova"]) * 12.0), "nova", GREEN)
    for enemy in enemies:
        if Vector2(enemy["pos"]).distance_to(center) <= radius:
            enemy["slow"] = maxf(float(enemy["slow"]), 1.1 + float(levels["nova"]) * 0.30)
    # Comet Volley + Nova Field: detonations become supercharged.
    if int(levels["volley"]) >= 2 and int(levels["nova"]) >= 2:
        _blast(center, radius * 0.67, _power(24.0), "nova", GOLD)

func _blast(pos: Vector2, radius: float, amount: float, source: String, color: Color) -> void:
    _effect("ring", pos, Vector2.ZERO, radius, color, 0.40)
    var victims: Array[int] = []
    for enemy in enemies:
        if Vector2(enemy["pos"]).distance_to(pos) <= radius + float(enemy["radius"]):
            victims.append(int(enemy["id"]))
    for id in victims:
        _damage_by_id(id, amount, source)

func _index_by_id(id: int) -> int:
    for i in range(enemies.size()):
        if int(enemies[i]["id"]) == id:
            return i
    return -1

func _damage_by_id(id: int, amount: float, source: String) -> float:
    var idx: int = _index_by_id(id)
    if idx < 0:
        return 0.0
    var enemy: Dictionary = enemies[idx]
    var actual: float = minf(maxf(0.0, amount), maxf(0.0, float(enemy["hp"])))
    enemy["hp"] = float(enemy["hp"]) - actual
    weapon_damage[source] = float(weapon_damage.get(source, 0.0)) + actual
    if not low_fx:
        _effect("number", Vector2(enemy["pos"]) + Vector2(0, -15), Vector2.ZERO, actual, GOLD, 0.42)
    if float(enemy["hp"]) <= 0.0:
        _effect("ring", Vector2(enemy["pos"]), Vector2.ZERO, float(enemy["radius"]) * 2.1, RED, 0.36)
        xp += int(enemy["xp"])
        kills += 1
        if focused_id == id:
            focused_id = -1
        enemies.remove_at(idx)
    return actual

func _check_level_up() -> void:
    var needed: int = GameCatalog.next_level_xp(level)
    if xp < needed:
        return
    xp -= needed
    level += 1
    var offers: Array[String] = GameCatalog.upgrade_offers(levels, rng)
    if offers.is_empty():
        return
    state = "upgrade"
    upgrade_requested.emit(offers)
    stats_changed.emit(snapshot())

func _check_finish() -> void:
    if elapsed < GameCatalog.stage_duration(stage):
        return
    if enemies.is_empty():
        _finish(true)

func _finish(victory: bool) -> void:
    if state == "finished":
        return
    state = "finished"
    stats_changed.emit(snapshot())
    run_completed.emit(victory, {
        "stage": stage, "kills": kills, "time": elapsed, "level": level,
        "reward": GameCatalog.reward(kills, stage, victory),
        "damage": weapon_damage.duplicate()
    })

func _effect(kind: String, a: Vector2, b: Vector2, radius: float, color: Color, duration: float) -> void:
    if effects.size() > (46 if low_fx else 100):
        effects.pop_front()
    effects.append({"kind": kind, "a": a, "b": b, "radius": radius, "color": color, "ttl": duration, "duration": duration})

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, GameCatalog.WORLD_SIZE), DARK, true)
    for x in range(80, 721, 80):
        draw_line(Vector2(x, 140), Vector2(x, GameCatalog.BREACH_Y), Color(0.1, 0.22, 0.31, 0.35), 1.0)
    for y in range(180, 1100, 100):
        draw_line(Vector2(0, y), Vector2(720, y), Color(0.1, 0.22, 0.31, 0.35), 1.0)
    draw_rect(Rect2(0, 125, 720, 55), Color("#182b41"), true)
    draw_line(Vector2(0, GameCatalog.BREACH_Y), Vector2(720, GameCatalog.BREACH_Y), RED, 4.0)
    draw_rect(Rect2(0, 1052, 720, 110), Color("#102a3e"), true)
    draw_arc(G, 72.0 + sin(_visual_clock * 3.0) * 4.0, PI, TAU, 32, Color(0.2, 0.76, 0.88, 0.25), 2.0, true)
    draw_circle(G, 48.0, Color("#174368"))
    draw_arc(G, 45.0, 0, TAU, 36, CYAN, 5.0, true)
    draw_colored_polygon(PackedVector2Array([
        G + Vector2(0, -54), G + Vector2(35, 24),
        G + Vector2(0, 12), G + Vector2(-35, 24)
    ]), Color("#46d6f2"))
    draw_circle(G + Vector2(0, -4), 13.0, Color.WHITE)
    for enemy in enemies:
        var at: Vector2 = enemy["pos"]
        var radius: float = enemy["radius"]
        var shade := RED
        match String(enemy["kind"]):
            "runner": shade = GOLD
            "tank": shade = BLUE
            "elite": shade = Color("#e888ff")
        if float(enemy["slow"]) > 0.0:
            draw_arc(at, radius + 10.0, 0, TAU, 22, GREEN, 2.0, true)
        match String(enemy["kind"]):
            "runner":
                draw_colored_polygon(PackedVector2Array([at + Vector2(0, -radius), at + Vector2(radius, radius), at + Vector2(-radius, radius)]), shade)
            "tank":
                draw_rect(Rect2(at - Vector2(radius, radius), Vector2(radius * 2, radius * 2)), shade, true)
                draw_rect(Rect2(at - Vector2(radius * 0.5, radius * 0.5), Vector2(radius, radius)), DARK, true)
            "elite":
                draw_arc(at, radius + 12 + sin(_visual_clock * 3.0) * 3.0, 0, TAU, 48, shade, 3.0, true)
                draw_circle(at, radius, shade)
                draw_circle(at, radius * 0.48, DARK)
            _:
                draw_circle(at, radius, shade)
                draw_circle(at, radius * 0.44, DARK)
        var fraction: float = clampf(float(enemy["hp"]) / float(enemy["max_hp"]), 0.0, 1.0)
        draw_rect(Rect2(at + Vector2(-radius, -radius - 16), Vector2(radius * 2.0, 5)), Color("#29374b"), true)
        draw_rect(Rect2(at + Vector2(-radius, -radius - 16), Vector2(radius * 2.0 * fraction, 5)), GREEN, true)
        if int(enemy["id"]) == focused_id:
            draw_arc(at, radius + 18.0, 0, TAU, 36, GOLD, 3.0, true)
    for bullet in projectiles:
        var pos: Vector2 = bullet["pos"]
        draw_circle(pos, 9.0 if bullet["kind"] == "rocket" else 4.0, GOLD)
        if bullet["kind"] == "rocket":
            draw_line(pos, pos - Vector2(bullet["velocity"]).normalized() * 24.0, Color("#d55686"), 3.0, true)
    for fx in effects:
        var alpha: float = clampf(float(fx["ttl"]) / float(fx["duration"]), 0.0, 1.0)
        var shade: Color = fx["color"]
        shade.a = alpha
        match String(fx["kind"]):
            "beam":
                draw_line(fx["a"], fx["b"], shade, float(fx["radius"]) + 4.0 * alpha, true)
                draw_line(fx["a"], fx["b"], Color(1, 1, 1, alpha), 2.0, true)
            "ring":
                draw_arc(fx["a"], float(fx["radius"]) * (1.0 - 0.35 * alpha), 0, TAU, 28, shade, 4.0, true)
            "flash":
                draw_circle(fx["a"], float(fx["radius"]) * alpha, shade)
            "number":
                if not low_fx:
                    draw_string(ThemeDB.fallback_font, fx["a"] + Vector2(0, -20 * (1.0 - alpha)), "%d" % ceili(float(fx["radius"])), HORIZONTAL_ALIGNMENT_CENTER, -1, 19, shade)
