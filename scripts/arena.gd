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
const DARK := VisualProfile.BACKDROP
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
var _gun_timer := 0.0
var _beam_timer := 0.0
var _volley_timer := 0.0
var _arc_timer := 0.0
var _nova_timer := 0.0
var _hud_timer := 0.0
var _visual_clock := 0.0
var _elite_spawned := false
var _elite_enraged := false
var formation_index := 0
var formation_name := "LINE"
var breaches := 0
var combat_event := "DEFENSE ONLINE"
var event_time := 0.0

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
        "gun": 1, "beam": 0, "volley": 0, "arc": 0, "nova": 0,
        "hull": 0, "rate": 0, "power": 0, "reach": 0
    }
    weapon_damage = {"gun": 0.0, "beam": 0.0, "volley": 0.0, "arc": 0.0, "nova": 0.0}
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
    _gun_timer = 0.10
    _beam_timer = 0.24
    _volley_timer = 1.0
    _arc_timer = 1.3
    _nova_timer = 1.8
    _hud_timer = 0.0
    _visual_clock = 0.0
    _elite_spawned = false
    _elite_enraged = false
    formation_index = 0
    formation_name = "LINE"
    breaches = 0
    combat_event = "DEFENSE ONLINE"
    event_time = 3.0
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
        "enemies": enemies.size(), "damage": weapon_damage.duplicate(),
        "formation": formation_name, "breaches": breaches,
        "event": combat_event if event_time > 0.0 else ""
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
    event_time = maxf(0.0, event_time - delta)
    _spawn_timer -= delta
    if elapsed < GameCatalog.stage_duration(stage) and _spawn_timer <= 0.0:
        _spawn_formation()
        var progress: float = minf(1.0, elapsed / GameCatalog.stage_duration(stage))
        _spawn_timer = maxf(1.30, 2.55 - 0.74 * progress - float(stage - 1) * 0.24) * rng.randf_range(0.85, 1.15)
    if stage == 2 and not _elite_spawned and elapsed > GameCatalog.stage_duration(stage) * 0.60:
        _elite_spawned = true
        _spawn_enemy("elite", 360.0, 155.0)
        combat_event = "ELITE SIGNATURE DETECTED"
        event_time = 4.0
    _move_enemies(delta)
    if state != "running":
        return
    _process_elite_phase()
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
    formation_name = CombatDirector.pattern_for(stage, elapsed, formation_index)
    var members: Array[Dictionary] = CombatDirector.formation(stage, elapsed, formation_index, rng)
    var created := 0
    for member in members:
        if enemies.size() >= MAX_ENEMIES:
            break
        _spawn_enemy(String(member["kind"]), float(member["x"]), float(member["y"]))
        created += 1
    if created > 0:
        combat_event = "THREATS: %s" % formation_name
        event_time = 2.4
        formation_index += 1


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
        "phase": rng.randf_range(0.0, TAU), "flash": 0.0
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
        enemy["flash"] = maxf(0.0, float(enemy["flash"]) - delta)
        if stun <= 0.0:
            var kind: String = String(enemy["kind"])
            var pace: float = float(enemy["speed"])
            if kind == "elite" and _elite_enraged:
                pace *= 1.35
            pos.y += pace * (0.48 if slow > 0.0 else 1.0) * delta
            var amplitude: float = 18.0
            var frequency: float = 0.010
            if kind == "runner":
                amplitude = 66.0
                frequency = 0.023
            elif kind == "tank":
                amplitude = 7.0
            elif kind == "elite":
                amplitude = 19.0
            pos.x = clampf(float(enemy["origin_x"]) + sin(pos.y * frequency + float(enemy["phase"])) * amplitude, 24.0, 696.0)
            enemy["pos"] = pos
        if pos.y >= GameCatalog.BREACH_Y:
            hull = maxf(0.0, hull - float(enemy["damage"]))
            breaches += 1
            combat_event = "BREACH!  -%d HULL" % roundi(float(enemy["damage"]))
            event_time = 2.0
            _effect("ring", Vector2(pos.x, GameCatalog.BREACH_Y), Vector2.ZERO, 76.0, RED, 0.42)
            if int(enemy["id"]) == focused_id:
                focused_id = -1
            enemies.remove_at(i)
            if hull <= 0.0:
                _finish(false)
                return

func _process_elite_phase() -> void:
    if stage != 2 or not _elite_spawned or _elite_enraged:
        return
    for enemy in enemies:
        if String(enemy["kind"]) != "elite":
            continue
        if float(enemy["hp"]) / maxf(1.0, float(enemy["max_hp"])) > 0.55:
            return
        _elite_enraged = true
        combat_event = "ELITE PHASE II - ESCORTS"
        event_time = 5.0
        var at: Vector2 = enemy["pos"]
        _effect("ring", at, Vector2.ZERO, 148.0, RED, 0.80)
        if enemies.size() <= MAX_ENEMIES - 2:
            _spawn_enemy("runner", clampf(at.x - 150.0, 40.0, 680.0), at.y - 35.0)
            _spawn_enemy("runner", clampf(at.x + 150.0, 40.0, 680.0), at.y - 35.0)
        return


func _move_projectiles(delta: float) -> void:
    for i in range(projectiles.size() - 1, -1, -1):
        var bullet: Dictionary = projectiles[i]
        bullet["life"] = float(bullet["life"]) - delta
        var pos: Vector2 = bullet["pos"]
        var target_idx: int = _index_by_id(int(bullet["target"]))
        var velocity: Vector2 = bullet["velocity"]
        var kind: String = String(bullet["kind"])
        # Both rockets and the basic cannon track the assigned threat. The
        # cannon makes smaller corrections, avoiding the old missing shots.
        if target_idx >= 0 and (kind == "rocket" or kind == "gun"):
            var destination: Vector2 = enemies[target_idx]["pos"]
            var aim: Vector2 = (destination - pos).normalized()
            var bullet_speed := 670.0 if kind == "rocket" else (1250.0 if int(levels["gun"]) >= 4 else 1100.0)
            var turning := 7.0 if kind == "rocket" else (9.0 if int(levels["gun"]) >= 4 else 6.0)
            velocity = velocity.lerp(aim * bullet_speed, minf(delta * turning, 1.0))
            bullet["velocity"] = velocity
        var next: Vector2 = pos + velocity * delta
        bullet["pos"] = next
        var collision := -1
        for enemy in enemies:
            var radius: float = float(enemy["radius"]) + (10.0 if kind == "rocket" else (9.0 if kind == "gun" else 7.0))
            # Swept segment-vs-circle collision prevents high-speed tunneling.
            var path: Vector2 = next - pos
            var along: float = clampf((Vector2(enemy["pos"]) - pos).dot(path) / maxf(0.01, path.length_squared()), 0.0, 1.0)
            if Vector2(enemy["pos"]).distance_to(pos.lerp(next, along)) <= radius:
                collision = int(enemy["id"])
                break
        if collision >= 0:
            var hit_at: Vector2 = next
            var base_damage: float = float(bullet["damage"])
            if kind == "rocket":
                _damage_by_id(collision, base_damage, "volley")
                if int(levels["volley"]) >= 3:
                    _blast(hit_at, 54.0 + int(levels["volley"]) * 7.0, base_damage * 0.45, "volley", GOLD)
                if int(levels["volley"]) >= 4 and projectiles.size() < MAX_BULLETS - 3:
                    for j in range(3):
                        var velocity_frag := Vector2.from_angle(-PI + j * PI / 2.0) * 450.0
                        projectiles.append({"pos": hit_at, "velocity": velocity_frag, "damage": base_damage * 0.33, "life": 0.36, "target": -1, "kind": "frag"})
            elif kind == "gun":
                _damage_by_id(collision, base_damage, "gun")
            else:
                _damage_by_id(collision, base_damage, "volley")
            _effect("flash", hit_at, Vector2.ZERO, 12.0 if kind == "gun" else 22.0, CYAN if kind == "gun" else GOLD, 0.14 if kind == "gun" else 0.22)
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
    _gun_timer -= delta
    _beam_timer -= delta
    _volley_timer -= delta
    _arc_timer -= delta
    _nova_timer -= delta
    if _gun_timer <= 0.0:
        var gun_cadence := 0.17 if int(levels["gun"]) == 1 else 0.13
        _gun_timer = gun_cadence / cadence
        _fire_gun()
    if int(levels["beam"]) > 0 and _beam_timer <= 0.0:
        _beam_timer = maxf(0.49, 0.87 - 0.055 * int(levels["beam"])) / cadence
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

func _fire_gun() -> void:
    var target_idx: int = _target_index(_range(1170.0))
    if target_idx < 0 or projectiles.size() >= MAX_BULLETS - 2:
        return
    var enemy: Dictionary = enemies[target_idx]
    var target: Vector2 = enemy["pos"]
    var speed := 1250.0 if int(levels["gun"]) >= 4 else 1100.0
    var barrels := 2 if int(levels["gun"]) >= 3 else 1
    for barrel in range(barrels):
        var offset: float = (float(barrel) - (barrels - 1.0) * 0.5) * 32.0
        var muzzle: Vector2 = G + Vector2(offset, -45.0)
        var flight: float = muzzle.distance_to(target) / (speed + float(enemy["speed"]))
        var lead: Vector2 = target + Vector2(0.0, float(enemy["speed"]) * flight * 0.75)
        var velocity: Vector2 = (lead - muzzle).normalized() * speed
        projectiles.append({
            "pos": muzzle, "velocity": velocity,
            "damage": _power(7.0 + 2.0 * (int(levels["gun"]) - 1)),
            "life": 1.45, "target": int(enemy["id"]), "kind": "gun"
        })
    if not low_fx:
        _effect("flash", G + Vector2(0, -45), Vector2.ZERO, 11.0, CYAN, 0.10)

func _beam_target_ids() -> Array[int]:
    # The primary beam always aims through its target center. On the dual-beam
    # tier, the other beam selects a second valid enemy or converges on the first.
    var chosen: Array[int] = []
    var primary: int = _target_index(_range(1160.0))
    if primary < 0:
        return chosen
    chosen.append(int(enemies[primary]["id"]))
    if int(levels["beam"]) < 3:
        return chosen
    var second := -1
    var highest_y := -100000.0
    for enemy in enemies:
        if int(enemy["id"]) == chosen[0]:
            continue
        if Vector2(enemy["pos"]).distance_to(G) > _range(1160.0):
            continue
        if float(Vector2(enemy["pos"]).y) > highest_y:
            highest_y = Vector2(enemy["pos"]).y
            second = int(enemy["id"])
    chosen.append(second if second >= 0 else chosen[0])
    return chosen

func _fire_beam() -> void:
    if int(levels["beam"]) <= 0:
        return
    var targets: Array[int] = _beam_target_ids()
    if targets.is_empty():
        return
    for lane in range(targets.size()):
        var idx: int = _index_by_id(targets[lane])
        if idx < 0:
            continue
        var muzzle_offset := 0.0
        if targets.size() == 2:
            muzzle_offset = -25.0 if lane == 0 else 25.0
        var start: Vector2 = G + Vector2(muzzle_offset, -42.0)
        var destination: Vector2 = enemies[idx]["pos"]
        var direction: Vector2 = (destination - start).normalized()
        var end: Vector2 = start + direction * 1300.0
        _effect("beam", start, end, 4.0 + int(levels["beam"]), CYAN, 0.16)
        var hits: Array[Dictionary] = []
        for enemy in enemies:
            var offset: Vector2 = Vector2(enemy["pos"]) - start
            var projection: float = offset.dot(direction)
            if projection <= 0.0 or projection > 1300.0:
                continue
            var lateral: float = (offset - direction * projection).length()
            if lateral <= float(enemy["radius"]) + 7.0:
                hits.append({"id": int(enemy["id"]), "distance": projection})
        hits.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return float(x["distance"]) < float(y["distance"]))
        var pierce: int = 1 + int(levels["beam"])
        for i in range(mini(pierce, hits.size())):
            _damage_by_id(int(hits[i]["id"]), _power(28.0 + int(levels["beam"]) * 8.0), "beam")
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
    var effective: float = amount * GameCatalog.damage_factor(String(enemy["kind"]), source)
    var actual: float = minf(maxf(0.0, effective), maxf(0.0, float(enemy["hp"])))
    enemy["flash"] = 0.16
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
        "damage": weapon_damage.duplicate(), "breaches": breaches,
        "formations": formation_index
    })

func _effect(kind: String, a: Vector2, b: Vector2, radius: float, color: Color, duration: float) -> void:
    if effects.size() > (46 if low_fx else 100):
        effects.pop_front()
    effects.append({"kind": kind, "a": a, "b": b, "radius": radius, "color": color, "ttl": duration, "duration": duration})

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, GameCatalog.WORLD_SIZE), DARK, true)
    for x in range(80, 721, 80):
        draw_line(Vector2(x, 140), Vector2(x, GameCatalog.BREACH_Y), VisualProfile.GRID, 1.0)
    for y in range(180, 1100, 100):
        draw_line(Vector2(0, y), Vector2(720, y), VisualProfile.GRID, 1.0)
    draw_rect(Rect2(0, 125, 720, 55), VisualProfile.SPAWN_BAND, true)
    draw_line(Vector2(0, GameCatalog.BREACH_Y), Vector2(720, GameCatalog.BREACH_Y), RED, 4.0)
    draw_rect(Rect2(0, 1052, 720, 110), VisualProfile.LOWER_ZONE, true)
    draw_arc(G, 72.0 + sin(_visual_clock * 3.0) * 4.0, PI, TAU, 32, Color(0.2, 0.76, 0.88, 0.25), 2.0, true)
    draw_circle(G, 48.0, VisualProfile.GUARDIAN_HULL)
    draw_arc(G, 45.0, 0, TAU, 36, CYAN, 5.0, true)
    draw_colored_polygon(PackedVector2Array([
        G + Vector2(0, -54), G + Vector2(35, 24),
        G + Vector2(0, 12), G + Vector2(-35, 24)
    ]), VisualProfile.GUARDIAN_CORE)
    draw_circle(G + Vector2(0, -4), 13.0, Color.WHITE)
    for enemy in enemies:
        var at: Vector2 = enemy["pos"]
        var radius: float = enemy["radius"]
        var shade: Color = VisualProfile.enemy_tint(String(enemy["kind"]))
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
        if float(enemy["flash"]) > 0.0:
            draw_arc(at, radius + 5.0, 0, TAU, 26, Color(1, 1, 1, 0.8), 2.4, true)
        if enemy["kind"] == "tank":
            draw_arc(at, radius + 7.0, 0, TAU, 24, Color("#8a9ee2"), 2.0, true)
        if enemy["kind"] == "elite" and _elite_enraged:
            draw_arc(at, radius + 21.0, 0, TAU, 36, RED, 4.0, true)
        var fraction: float = clampf(float(enemy["hp"]) / float(enemy["max_hp"]), 0.0, 1.0)
        draw_rect(Rect2(at + Vector2(-radius, -radius - 16), Vector2(radius * 2.0, 5)), Color("#29374b"), true)
        draw_rect(Rect2(at + Vector2(-radius, -radius - 16), Vector2(radius * 2.0 * fraction, 5)), GREEN, true)
        if int(enemy["id"]) == focused_id:
            draw_arc(at, radius + 18.0, 0, TAU, 36, GOLD, 3.0, true)
    for bullet in projectiles:
        var pos: Vector2 = bullet["pos"]
        if bullet["kind"] == "gun":
            draw_line(pos, pos - Vector2(bullet["velocity"]).normalized() * 18.0, CYAN, 2.8, true)
            draw_circle(pos, 3.0, Color.WHITE)
        else:
            draw_circle(pos, 9.0 if bullet["kind"] == "rocket" else 4.0, GOLD)
            if bullet["kind"] == "rocket":
                draw_line(pos, pos - Vector2(bullet["velocity"]).normalized() * 24.0, Color("#d55686"), 3.0, true)
    for fx in effects:
        var alpha: float = clampf(float(fx["ttl"]) / float(fx["duration"]), 0.0, 1.0)
        var shade: Color = fx["color"]
        shade.a = alpha
        match String(fx["kind"]):
            "beam":
                draw_line(fx["a"], fx["b"], shade, float(fx["radius"]) + 2.0 * alpha, true)
                draw_line(fx["a"], fx["b"], Color(1, 1, 1, alpha * 0.50), 1.4, true)
            "ring":
                draw_arc(fx["a"], float(fx["radius"]) * (1.0 - 0.35 * alpha), 0, TAU, 28, shade, 4.0, true)
            "flash":
                draw_circle(fx["a"], float(fx["radius"]) * alpha, shade)
            "number":
                if not low_fx:
                    draw_string(ThemeDB.fallback_font, fx["a"] + Vector2(0, -20 * (1.0 - alpha)), "%d" % ceili(float(fx["radius"])), HORIZONTAL_ALIGNMENT_CENTER, -1, 19, shade)
