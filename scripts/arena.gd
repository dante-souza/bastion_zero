class_name Arena
extends Node2D

signal stats_changed(info: Dictionary)
signal upgrade_requested(offers: Array[String])
signal run_completed(victory: bool, report: Dictionary)

const G := GameCatalog.GUARDIAN
const CYAN := Color("#5feeff")
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
## Visual-only state derived from physically spawned Sentinel rounds and breaches.
var gun_visual_lanes: Array[Dictionary] = []
var _guardian_damage_until := -1.0
var _elite_spawned := false
var _elite_enraged := false
var formation_index := 0
var formation_name := "LINE"
var breaches := 0
var combat_event := "DEFENSE ONLINE"
## Phase I.5: severity travels as a kind, never parsed back out of the copy.
var combat_event_kind := ThreatLanguage.KIND_INFO
var event_time := 0.0
var showcase_active := false
var showcase_script_index := 0
var showcase_regular_spawns_unlocked := false
var _showcase_elite_spawned := false
## Sector (map) state: hard-start opener, field-rule timer and pending drop pods.
var _hard_script: Array = []
var _hard_formations_start := GameCatalog.SHOWCASE_FORMATIONS_START
var _rule_timer := 0.0
var _range_scale := 1.0
var pending_drops: Array[Dictionary] = []
## 0.9.7 mechanics: enemy relationships, Overdrive and the Moving Line prototype.
var overdrive_charge := 0.0
var overdrive_boost := 0.0
var overdrives_fired := 0
var line_enabled := false
var line := GameCatalog.LINE_START
var _line_core_warned := false
var wardens_alive := 0
var shielded_count := 0
var _pending_shocks: Array[Vector2] = []

func _ready() -> void:
    rng.randomize()
    set_process(true)
    set_physics_process(true)

func begin_run(permanent_upgrades: Dictionary, selected_stage: int = 1, reduced_fx: bool = true, showcase: bool = false, moving_line: bool = false) -> void:
    meta = permanent_upgrades.duplicate(true)
    stage = clampi(selected_stage, 1, GameCatalog.TOTAL_STAGES)
    low_fx = reduced_fx
    # HARD START: any sector can open at LV12 with the QA loadout and pressure.
    showcase_active = showcase
    _hard_script = SectorCatalog.hard_script(stage) if showcase_active else []
    _hard_formations_start = GameCatalog.SHOWCASE_FORMATIONS_START if stage == 1 else 6.0
    _rule_timer = float(SectorCatalog.value(stage, "rule_every", 0.0)) * (0.5 if showcase_active else 1.0)
    _range_scale = float(SectorCatalog.value(stage, "range_scale", 1.0))
    pending_drops.clear()
    rng.seed = 14057 + stage * 137
    levels = {
        "gun": 1, "beam": 0, "volley": 0, "arc": 0, "nova": 0,
        "gun_payload": 0, "gun_pierce": 0, "gun_ricochet": 0, "gun_volley": 0,
        "hull": 0, "rate": 0, "power": 0, "reach": 0,
        "od_capacitor": 0, "od_yield": 0, "breaker": 0, "uplink": 0
    }
    line_enabled = moving_line
    line = GameCatalog.LINE_START
    _line_core_warned = false
    if line_enabled:
        # Line Anchor is only offered while the Line exists.
        levels["line_anchor"] = 0
    overdrive_charge = 0.0
    overdrive_boost = 0.0
    overdrives_fired = 0
    wardens_alive = 0
    shielded_count = 0
    _pending_shocks.clear()
    weapon_damage = {"gun": 0.0, "beam": 0.0, "volley": 0.0, "arc": 0.0, "nova": 0.0, "overdrive": 0.0}
    elapsed = 0.0
    level = 1
    if showcase_active:
        level = GameCatalog.SHOWCASE_START_LEVEL
        for key in GameCatalog.SHOWCASE_LOADOUT:
            levels[key] = int(GameCatalog.SHOWCASE_LOADOUT[key])
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
    gun_visual_lanes.clear()
    _guardian_damage_until = -1.0
    _elite_spawned = false
    _elite_enraged = false
    _showcase_elite_spawned = false
    showcase_script_index = 0
    showcase_regular_spawns_unlocked = not showcase_active
    formation_index = 0
    formation_name = "LINE"
    breaches = 0
    _announce("DEFENSE ONLINE", ThreatLanguage.KIND_INFO, 3.0)
    if SectorCatalog.rule(stage) != "none":
        _announce("%s  •  %s" % [SectorCatalog.value(stage, "place", ""),
            SectorCatalog.value(stage, "rule_label", "")], ThreatLanguage.KIND_INFO, 3.0)
    if showcase_active:
        _tick_showcase_script()
        _spawn_timer = 0.55
    state = "running"
    stats_changed.emit(snapshot())
    queue_redraw()

func snapshot() -> Dictionary:
    # Live elite HP for a real health bar; never infer boss health from time.
    var elite_hp := 0.0
    var elite_max_hp := 0.0
    for enemy in enemies:
        if String(enemy["kind"]) == "elite":
            elite_hp = maxf(0.0, float(enemy["hp"]))
            elite_max_hp = float(enemy["max_hp"])
            break
    return {
        "stage": stage, "stage_name": GameCatalog.stage_name(stage),
        "state": state, "time": elapsed,
        "duration": GameCatalog.stage_duration(stage),
        "level": level, "xp": xp, "next_xp": GameCatalog.next_level_xp(level),
        "kills": kills, "hull": hull, "max_hull": max_hull,
        "weapons": levels.duplicate(), "focus": focused_id,
        "enemies": enemies.size(), "damage": weapon_damage.duplicate(),
        "elite_hp": elite_hp, "elite_max_hp": elite_max_hp,
        "formation": formation_name, "breaches": breaches,
        "showcase": showcase_active,
        "sector": SectorCatalog.value(stage, "place", ""),
        "tag": SectorCatalog.value(stage, "tag", "NORMAL"),
        "rule": SectorCatalog.rule(stage),
        "showcase_beat": showcase_script_index,
        "overdrive": clampf(overdrive_charge / GameCatalog.OVERDRIVE_FULL, 0.0, 1.0),
        "overdrive_ready": overdrive_ready(), "overdrive_boost": overdrive_boost,
        "line_on": line_enabled, "line": line,
        "wardens": wardens_alive, "shielded": shielded_count,
        "event": combat_event if event_time > 0.0 else "",
        "event_kind": combat_event_kind if event_time > 0.0 else ""
    }

func _announce(text: String, kind: String, seconds: float) -> void:
    combat_event = text
    combat_event_kind = kind
    event_time = seconds


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
    if int(levels[kind]) >= GameCatalog.upgrade_cap(kind):
        return
    levels[kind] = int(levels[kind]) + 1
    if kind == "gun" or kind == "gun_volley":
        # Rebuild idle barrels at the new upgrade count.
        gun_visual_lanes.clear()
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
    if showcase_active:
        _tick_showcase_script()
    if not showcase_active or showcase_regular_spawns_unlocked:
        _spawn_timer -= delta
        if elapsed < GameCatalog.stage_duration(stage) and _spawn_timer <= 0.0:
            _spawn_formation()
            var progress: float = minf(1.0, elapsed / GameCatalog.stage_duration(stage))
            if showcase_active:
                _spawn_timer = lerpf(GameCatalog.SHOWCASE_FORMATION_INTERVAL,
                    GameCatalog.HARD_INTERVAL_END, progress) * rng.randf_range(0.90, 1.10)
            else:
                _spawn_timer = maxf(1.30, 2.55 - 0.74 * progress - float(SectorCatalog.value(stage, "pace", 0.0))) * rng.randf_range(0.85, 1.15)
    _tick_field_rule(delta)
    if SectorCatalog.has_elite(stage) and not _elite_spawned and elapsed > GameCatalog.stage_duration(stage) * float(SectorCatalog.value(stage, "elite_at", 0.0)):
        _elite_spawned = true
        _spawn_enemy("elite", 360.0, 155.0)
        _announce("ELITE SIGNATURE DETECTED", ThreatLanguage.KIND_ELITE, 4.0)
    _move_enemies(delta)
    if state != "running":
        return
    _refresh_relationships()
    _tick_line(delta)
    if state != "running":
        return
    overdrive_boost = maxf(0.0, overdrive_boost - delta)
    _process_elite_phase()
    _move_projectiles(delta)
    _update_effects(delta)
    _tick_weapons(delta)
    _release_shocks()
    _check_level_up()
    if state != "running":
        return
    _check_finish()
    _hud_timer -= delta
    if _hud_timer <= 0.0:
        _hud_timer = 0.15
        stats_changed.emit(snapshot())

## Scripted visual demonstration: fixed, spaced beats before normal wave pressure.
## Time is simulation time (so pause/upgrade screens pause the sequence).
func _tick_showcase_script() -> void:
    if not showcase_active:
        return
    while showcase_script_index < _hard_script.size():
        var beat: Dictionary = _hard_script[showcase_script_index]
        if elapsed < float(beat["at"]):
            break
        for spec in beat["spawns"]:
            if enemies.size() >= MAX_ENEMIES:
                break
            var kind: String = String(spec[0])
            _spawn_enemy(kind, float(spec[1]), float(spec[2]), bool(beat.get("intro", true)))
            if kind == "elite":
                _showcase_elite_spawned = true
        _announce("SHOWCASE • " + String(beat["label"]), ThreatLanguage.KIND_INFO, 3.2)
        showcase_script_index += 1
    if not showcase_regular_spawns_unlocked and elapsed >= _hard_formations_start:
        showcase_regular_spawns_unlocked = true
        _spawn_timer = 0.55
        _announce("SHOWCASE • FORMATIONS ONLINE", ThreatLanguage.KIND_INFO, 2.6)


## Sector field rules (see SectorCatalog). They stop with the stage clock so
## a cleared field still ends the run.
func _tick_field_rule(delta: float) -> void:
    for i in range(pending_drops.size() - 1, -1, -1):
        var drop: Dictionary = pending_drops[i]
        drop["t"] = float(drop["t"]) - delta
        if float(drop["t"]) <= 0.0:
            pending_drops.remove_at(i)
            _land_drop(drop["pos"])
    var every: float = float(SectorCatalog.value(stage, "rule_every", 0.0))
    if every <= 0.0 or elapsed >= GameCatalog.stage_duration(stage):
        return
    _rule_timer -= delta
    if _rule_timer > 0.0:
        return
    _rule_timer = every
    match SectorCatalog.rule(stage):
        "surge":
            var per_side: int = 3 + (1 if elapsed > GameCatalog.stage_duration(stage) * 0.5 else 0)
            for side in [0, 1]:
                for i in range(per_side):
                    if enemies.size() >= MAX_ENEMIES:
                        break
                    var x: float = (70.0 + i * 34.0) if side == 0 else (650.0 - i * 34.0)
                    _spawn_enemy("runner", x, 165.0 - i * 30.0)
            _announce("RUNNER SURGE • BOTH FLANKS", ThreatLanguage.KIND_FORMATION, 2.2)
        "drop":
            var at := Vector2(rng.randf_range(120.0, 600.0), rng.randf_range(430.0, 610.0))
            pending_drops.append({"pos": at, "t": float(SectorCatalog.value(stage, "drop_delay", 1.6)),
                "duration": float(SectorCatalog.value(stage, "drop_delay", 1.6))})
            _announce("DROP POD INBOUND", ThreatLanguage.KIND_FORMATION, 2.0)


func _land_drop(at: Vector2) -> void:
    var squad: Array[String] = ["grunt", "grunt", "runner"]
    if elapsed > GameCatalog.stage_duration(stage) * 0.5:
        squad.append("tank")
    for i in range(squad.size()):
        if enemies.size() >= MAX_ENEMIES:
            break
        var angle: float = TAU * float(i) / float(squad.size())
        _spawn_enemy(squad[i], clampf(at.x + cos(angle) * 46.0, 40.0, 680.0), at.y + sin(angle) * 34.0)
    _effect("ring", at, Vector2.ZERO, 92.0, ThreatLanguage.WARNING, 0.55)


func _spawn_formation() -> void:
    if enemies.size() >= MAX_ENEMIES:
        return
    formation_name = CombatDirector.pattern_for(stage, elapsed, formation_index)
    var members: Array[Dictionary] = CombatDirector.formation(stage, elapsed, formation_index, rng)
    var created := 0
    var ids: Array[int] = []
    for member in members:
        if enemies.size() >= MAX_ENEMIES:
            break
        ids.append(_spawn_enemy(String(member["kind"]), float(member["x"]), float(member["y"])))
        var escort_slot: int = int(member.get("escort", -1))
        if escort_slot >= 0 and escort_slot < ids.size() - 1:
            attach_escort(ids[ids.size() - 1], ids[escort_slot])
        created += 1
    if created > 0:
        _announce("THREATS: %s" % formation_name, ThreatLanguage.KIND_FORMATION, 2.4)
        formation_index += 1


func _spawn_enemy(kind: String, x: float = 360.0, y: float = 150.0, intro_only: bool = false) -> int:
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
        "warden":
            hp = 72.0
            speed = 64.0
            radius = 19.0
            hit = 9.0
            reward_xp = 18
    var scaling: float = float(SectorCatalog.value(stage, "hp", 1.0)) + (elapsed / GameCatalog.stage_duration(stage)) * 0.55
    speed *= float(SectorCatalog.value(stage, "speed", 1.0))
    # Stress-test pressure only applies to opt-in HARD START deployments.
    # Standard runs retain each sector's own HP, speed and breach damage.
    if showcase_active:
        scaling *= GameCatalog.SHOWCASE_HP_SCALE * float(SectorCatalog.value(stage, "hard_hp", 1.0)) * (1.0 + GameCatalog.HARD_HP_RAMP
            * minf(1.0, elapsed / GameCatalog.stage_duration(stage)))
        speed *= GameCatalog.SHOWCASE_SPEED_SCALE
        hit *= GameCatalog.SHOWCASE_DAMAGE_SCALE
        reward_xp = maxi(1, roundi(reward_xp * GameCatalog.HARD_XP_SCALE))
        if intro_only:
            scaling *= (GameCatalog.SHOWCASE_ELITE_HP_SCALE
                if kind == "elite" else GameCatalog.SHOWCASE_INTRO_HP_SCALE)
    enemies.append({
        "id": next_enemy_id, "kind": kind, "pos": Vector2(x, y),
        "origin_x": x, "hp": hp * scaling, "max_hp": hp * scaling,
        "speed": speed, "radius": radius, "damage": hit,
        "xp": reward_xp, "slow": 0.0, "stun": 0.0,
        "phase": rng.randf_range(0.0, TAU), "flash": 0.0,
        "shield": 0, "escort": -1, "escort_offset": Vector2.ZERO
    })
    next_enemy_id += 1
    return next_enemy_id - 1


## A Runner rides behind its escort Tank, shielded, until the Tank dies.
func attach_escort(rider_id: int, tank_id: int) -> void:
    var rider: int = _index_by_id(rider_id)
    var tank: int = _index_by_id(tank_id)
    if rider < 0 or tank < 0:
        return
    enemies[rider]["escort"] = tank_id
    enemies[rider]["escort_offset"] = Vector2(enemies[rider]["pos"]) - Vector2(enemies[tank]["pos"])

func _move_enemies(delta: float) -> void:
    var regen: float = float(SectorCatalog.value(stage, "regen", 0.0)) * delta
    for i in range(enemies.size() - 1, -1, -1):
        var enemy: Dictionary = enemies[i]
        var pos: Vector2 = enemy["pos"]
        if regen > 0.0:
            enemy["hp"] = minf(float(enemy["max_hp"]), float(enemy["hp"]) + float(enemy["max_hp"]) * regen)
        var slow: float = float(enemy["slow"])
        var stun: float = float(enemy["stun"])
        enemy["slow"] = maxf(0.0, slow - delta)
        enemy["stun"] = maxf(0.0, stun - delta)
        enemy["flash"] = maxf(0.0, float(enemy["flash"]) - delta)
        if int(enemy["escort"]) >= 0:
            continue  # placed after its tank moves, below
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
            elif kind == "warden":
                amplitude = 10.0
            pos.x = clampf(float(enemy["origin_x"]) + sin(pos.y * frequency + float(enemy["phase"])) * amplitude, 24.0, 696.0)
            enemy["pos"] = pos
        if pos.y >= GameCatalog.BREACH_Y:
            hull = maxf(0.0, hull - float(enemy["damage"]))
            _guardian_damage_until = _visual_clock + 0.32
            breaches += 1
            _announce("BREACH!  -%d HULL" % roundi(float(enemy["damage"])), ThreatLanguage.KIND_BREACH, 2.0)
            _effect("ring", Vector2(pos.x, GameCatalog.BREACH_Y), Vector2.ZERO, 76.0, RED, 0.42)
            if int(enemy["id"]) == focused_id:
                focused_id = -1
            enemies.remove_at(i)
            if hull <= 0.0:
                _finish(false)
                return
    # Escorted runners ride behind their tank; a dead tank sets them loose.
    for enemy in enemies:
        var escort_id: int = int(enemy["escort"])
        if escort_id < 0:
            continue
        var tank: int = _index_by_id(escort_id)
        if tank >= 0:
            enemy["pos"] = Vector2(enemies[tank]["pos"]) + Vector2(enemy["escort_offset"])
        else:
            _break_loose(enemy)

## The escort died: the Runner keeps its place, loses its shield and sprints.
func _break_loose(enemy: Dictionary) -> void:
    enemy["escort"] = -1
    enemy["shield"] = 0
    enemy["speed"] = float(enemy["speed"]) * GameCatalog.LOOSE_SPEED_SCALE
    var pos: Vector2 = enemy["pos"]
    # Keep x continuous with the runner weave used by _move_enemies.
    enemy["origin_x"] = pos.x - sin(pos.y * 0.023 + float(enemy["phase"])) * 66.0
    _effect("ring", pos, Vector2.ZERO, 30.0, VisualProfile.RUNNER, 0.30)


## Shield flags for this tick: 2 = riding a living escort, 1 = inside a Warden
## aura. Wardens never shield each other.
func _refresh_relationships() -> void:
    var warden_spots: Array[Vector2] = []
    for enemy in enemies:
        if String(enemy["kind"]) == "warden":
            warden_spots.append(enemy["pos"])
    wardens_alive = warden_spots.size()
    shielded_count = 0
    var reach: float = GameCatalog.WARDEN_AURA * GameCatalog.WARDEN_AURA
    for enemy in enemies:
        var shield := 0
        if int(enemy["escort"]) >= 0:
            shield = 2
        elif not warden_spots.is_empty() and String(enemy["kind"]) != "warden":
            var pos: Vector2 = enemy["pos"]
            for spot in warden_spots:
                if pos.distance_squared_to(spot) <= reach:
                    shield = 1
                    break
        enemy["shield"] = shield
        if shield > 0:
            shielded_count += 1


func shield_taken() -> float:
    return minf(1.0, GameCatalog.SHIELD_TAKEN + 0.15 * int(levels.get("breaker", 0)))


func line_y() -> float:
    return lerpf(GameCatalog.BREACH_Y, GameCatalog.LINE_TOP_Y, line)


## Moving Line prototype: hostiles past the line push it toward the core.
func _tick_line(delta: float) -> void:
    if not line_enabled:
        return
    var at: float = line_y()
    var crowd := 0.0
    var past := 0.0
    for enemy in enemies:
        var weight: float = GameCatalog.line_weight(String(enemy["kind"]))
        crowd += weight
        if Vector2(enemy["pos"]).y > at:
            past += weight
    # The crowd lean saturates so a packed HARD START field cannot spiral the
    # line to the core on its own; hostiles past the line always count.
    var pressure: float = minf(crowd, GameCatalog.LINE_DRIFT_CAP) * GameCatalog.LINE_DRIFT \
        + past * GameCatalog.LINE_PUSH
    line = clampf(line - pressure * delta, 0.0, 1.0)
    if line > 0.0:
        if line > 0.10:
            _line_core_warned = false
        return
    hull = maxf(0.0, hull - GameCatalog.LINE_CORE_DPS * delta)
    _guardian_damage_until = _visual_clock + 0.20
    if not _line_core_warned:
        _line_core_warned = true
        _announce("LINE AT THE CORE  •  HULL DRAINING", ThreatLanguage.KIND_BREACH, 2.4)
    if hull <= 0.0:
        _finish(false)


func overdrive_ready() -> bool:
    return overdrive_charge >= GameCatalog.OVERDRIVE_FULL


## Player-triggered strike (HUD button). Hits the focused target, else the
## densest cluster in range; ignores shields. Returns false when it cannot fire.
func trigger_overdrive() -> bool:
    if state != "running" or not overdrive_ready() or enemies.is_empty():
        return false
    var yield_rank: int = int(levels.get("od_yield", 0))
    var radius: float = GameCatalog.OVERDRIVE_RADIUS * (1.0 + 0.15 * yield_rank)
    var center: Vector2
    var focus: int = _index_by_id(focused_id)
    if focus >= 0:
        center = enemies[focus]["pos"]
    else:
        center = _densest_point(radius)
    overdrive_boost = GameCatalog.OVERDRIVE_BOOST_SECONDS + (2.0 if int(levels.get("od_capacitor", 0)) >= 3 else 0.0)
    overdrives_fired += 1
    _effect("overdrive", G + Vector2(0.0, -48.0), center, radius, VisualProfile.OVERDRIVE, 0.62)
    var victims: Array[int] = []
    for enemy in enemies:
        if Vector2(enemy["pos"]).distance_to(center) <= radius + float(enemy["radius"]):
            victims.append(int(enemy["id"]))
    var amount: float = _power(GameCatalog.OVERDRIVE_DAMAGE) * (1.0 + 0.40 * yield_rank)
    for id in victims:
        _damage_by_id(id, amount, "overdrive")
        if yield_rank >= 2:
            var idx: int = _index_by_id(id)
            if idx >= 0:
                enemies[idx]["stun"] = maxf(float(enemies[idx]["stun"]), 1.2)
    # Set after the strike so its own kills never refill it.
    overdrive_charge = GameCatalog.OVERDRIVE_FULL * 0.30 if yield_rank >= 3 else 0.0
    if line_enabled:
        # Line slam: the strike shoves the line and everything past it back up.
        line = minf(1.0, line + GameCatalog.LINE_SLAM)
        var at: float = line_y()
        for enemy in enemies:
            var pos: Vector2 = enemy["pos"]
            if pos.y > at and int(enemy["escort"]) < 0:
                enemy["pos"] = Vector2(pos.x, maxf(at - 20.0, pos.y - 110.0))
    _announce("OVERDRIVE", ThreatLanguage.KIND_INFO, 1.6)
    stats_changed.emit(snapshot())
    return true


func _densest_point(radius: float) -> Vector2:
    var best: Vector2 = enemies[0]["pos"]
    var best_score := -1
    for candidate in enemies:
        var pos: Vector2 = candidate["pos"]
        if pos.distance_to(G) > _range(1170.0):
            continue
        var neighbors := 0
        for other in enemies:
            if pos.distance_squared_to(other["pos"]) <= radius * radius:
                neighbors += 1
        if neighbors > best_score:
            best_score = neighbors
            best = pos
    return best


## Shield Breaker rank 3: a dying Warden bursts. Deferred so a burst never
## removes enemies while another weapon is still walking the list.
func _release_shocks() -> void:
    while not _pending_shocks.is_empty():
        var at: Vector2 = _pending_shocks.pop_back()
        _blast(at, GameCatalog.WARDEN_AURA, _power(60.0), "overdrive", VisualProfile.OVERDRIVE)


## Target Uplink rank 3: the lock jumps to the nearest Warden, else the
## nearest shielded hostile.
func _next_priority_target(from: Vector2, exclude: int) -> int:
    var best := -1
    var best_score := INF
    for enemy in enemies:
        var id: int = int(enemy["id"])
        if id == exclude:
            continue
        var kind: String = String(enemy["kind"])
        if kind != "warden" and int(enemy["shield"]) == 0:
            continue
        var score: float = from.distance_to(enemy["pos"]) - (10000.0 if kind == "warden" else 0.0)
        if score < best_score:
            best_score = score
            best = id
    return best


func _process_elite_phase() -> void:
    if not SectorCatalog.has_elite(stage) or not _elite_spawned or _elite_enraged:
        return
    for enemy in enemies:
        if String(enemy["kind"]) != "elite":
            continue
        if float(enemy["hp"]) / maxf(1.0, float(enemy["max_hp"])) > 0.55:
            return
        _elite_enraged = true
        _announce("ELITE PHASE II - WARDEN + ESCORTS", ThreatLanguage.KIND_ELITE, 5.0)
        var at: Vector2 = enemy["pos"]
        _effect("ring", at, Vector2.ZERO, 148.0, RED, 0.80)
        if enemies.size() <= MAX_ENEMIES - 2:
            _spawn_enemy("runner", clampf(at.x - 150.0, 40.0, 680.0), at.y - 35.0)
            _spawn_enemy("runner", clampf(at.x + 150.0, 40.0, 680.0), at.y - 35.0)
        if enemies.size() < MAX_ENEMIES:
            # A Warden shields the enraged Elite: focus it to open the boss up.
            _spawn_enemy("warden", at.x, at.y - 72.0)
        return


func _move_projectiles(delta: float) -> void:
    for i in range(projectiles.size() - 1, -1, -1):
        var bullet: Dictionary = projectiles[i]
        bullet["life"] = float(bullet["life"]) - delta
        var pos: Vector2 = bullet["pos"]
        var target_idx: int = _index_by_id(int(bullet["target"]))
        var velocity: Vector2 = bullet["velocity"]
        var kind: String = String(bullet["kind"])
        if target_idx >= 0 and (kind == "rocket" or kind == "gun"):
            var destination: Vector2 = enemies[target_idx]["pos"]
            var aim: Vector2 = (destination - pos).normalized()
            var bullet_speed: float = 670.0 if kind == "rocket" else (1250.0 if int(levels["gun"]) >= 4 else 1100.0)
            var turning: float = 7.0 if kind == "rocket" else (9.0 if int(levels["gun"]) >= 4 else 6.0)
            velocity = velocity.lerp(aim * bullet_speed, minf(delta * turning, 1.0))
            bullet["velocity"] = velocity
        var next: Vector2 = pos + velocity * delta
        bullet["pos"] = next
        var collision := -1
        var along_first := 2.0
        for enemy in enemies:
            var enemy_id: int = int(enemy["id"])
            if kind == "gun" and Array(bullet.get("hit_ids", [])).has(enemy_id):
                continue
            var radius: float = float(enemy["radius"]) + (10.0 if kind == "rocket" else (9.0 if kind == "gun" else 7.0))
            # Check the swept path; choose earliest physical contact, not spawn-array order.
            var path: Vector2 = next - pos
            var along: float = clampf((Vector2(enemy["pos"]) - pos).dot(path) / maxf(0.01, path.length_squared()), 0.0, 1.0)
            if along < along_first and Vector2(enemy["pos"]).distance_to(pos.lerp(next, along)) <= radius:
                collision = enemy_id
                along_first = along
        if collision >= 0:
            var hit_at: Vector2 = pos.lerp(next, along_first)
            var base_damage: float = float(bullet["damage"])
            if kind == "rocket":
                _damage_by_id(collision, base_damage, "volley")
                if int(levels["volley"]) >= 3:
                    _blast(hit_at, 54.0 + int(levels["volley"]) * 7.0, base_damage * 0.45, "volley", VisualProfile.COMET_IMPACT)
                if int(levels["volley"]) >= 4 and projectiles.size() < MAX_BULLETS - 3:
                    for j in range(3):
                        var velocity_frag := Vector2.from_angle(-PI + j * PI / 2.0) * 450.0
                        projectiles.append({"pos": hit_at, "velocity": velocity_frag, "damage": base_damage * 0.33, "life": 0.36, "target": -1, "kind": "frag"})
                projectiles.remove_at(i)
            elif kind == "gun":
                _damage_by_id(collision, base_damage, "gun")
                var touched: Array = bullet.get("hit_ids", [])
                touched.append(collision)
                bullet["hit_ids"] = touched
                if int(bullet["pierce_left"]) > 0:
                    # Penetration carries on in the same direction, never rehitting targets.
                    bullet["pierce_left"] = int(bullet["pierce_left"]) - 1
                    bullet["damage"] = base_damage * 0.86
                    bullet["target"] = -1
                    bullet["pos"] = next
                elif int(bullet["ricochet_left"]) > 0:
                    var bounced_id: int = _nearest_unhit_enemy(hit_at, touched, 500.0)
                    if bounced_id >= 0:
                        bullet["ricochet_left"] = int(bullet["ricochet_left"]) - 1
                        bullet["target"] = bounced_id
                        bullet["pos"] = hit_at
                        bullet["velocity"] = (Vector2(enemies[_index_by_id(bounced_id)]["pos"]) - hit_at).normalized() * 1100.0
                        bullet["damage"] = base_damage * 0.74
                        _effect("beam", hit_at, Vector2(enemies[_index_by_id(bounced_id)]["pos"]), 1.0, CYAN, 0.08)
                    else:
                        projectiles.remove_at(i)
                else:
                    projectiles.remove_at(i)
            else:
                _damage_by_id(collision, base_damage, "volley")
                projectiles.remove_at(i)
            _effect("flash" if kind == "gun" else "impact",
                hit_at, Vector2.ZERO, 12.0 if kind == "gun" else 22.0,
                VisualProfile.GUN_TRACER if kind == "gun" else VisualProfile.COMET_IMPACT,
                0.14 if kind == "gun" else (0.34 if showcase_active else 0.24))
        elif float(bullet["life"]) <= 0.0 or next.y < 110.0 or next.y > 1180.0:
            projectiles.remove_at(i)

func _nearest_unhit_enemy(point: Vector2, touched: Array, radius: float) -> int:
    var result := -1
    var shortest: float = radius
    for enemy in enemies:
        var id: int = int(enemy["id"])
        if touched.has(id):
            continue
        var distance: float = point.distance_to(enemy["pos"])
        if distance < shortest:
            shortest = distance
            result = id
    return result
func _update_effects(delta: float) -> void:
    for i in range(effects.size() - 1, -1, -1):
        effects[i]["ttl"] = float(effects[i]["ttl"]) - delta
        if float(effects[i]["ttl"]) <= 0.0:
            effects.remove_at(i)

func _tick_weapons(delta: float) -> void:
    var cadence: float = (1.0 + 0.13 * int(levels["rate"])) \
        * (GameCatalog.OVERDRIVE_BOOST_CADENCE if overdrive_boost > 0.0 else 1.0) \
        * (GameCatalog.LINE_HIGH_CADENCE if line_enabled and line >= GameCatalog.LINE_HIGH else 1.0)
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
    return base * (1.0 + 0.12 * int(levels["reach"])) * _range_scale \
        * (GameCatalog.LINE_LOW_RANGE if line_enabled and line <= GameCatalog.LINE_LOW else 1.0)

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

func _gun_target_ids(count: int) -> Array[int]:
    var result: Array[int] = []
    var index: int = _target_index(_range(1170.0))
    if index < 0:
        return result
    var main_id: int = int(enemies[index]["id"])
    result.append(main_id)
    var others: Array[Dictionary] = []
    for enemy in enemies:
        var id: int = int(enemy["id"])
        if id == main_id or Vector2(enemy["pos"]).distance_to(G) > _range(1170.0):
            continue
        others.append({"id": id, "y": float(Vector2(enemy["pos"]).y)})
    others.sort_custom(func(first: Dictionary, second: Dictionary) -> bool: return float(first["y"]) > float(second["y"]))
    for other in others:
        if result.size() >= count:
            break
        result.append(int(other["id"]))
    while result.size() < count:
        result.append(main_id)
    return result

func _fire_gun() -> void:
    var count: int = GuardianRenderer.sentinel_barrel_count(int(levels["gun"]), int(levels["gun_volley"]))
    if projectiles.size() >= MAX_BULLETS - count:
        return
    var targets: Array[int] = _gun_target_ids(count)
    if targets.is_empty():
        return
    var speed: float = 1250.0 if int(levels["gun"]) >= 4 else 1100.0
    gun_visual_lanes.clear()
    for barrel in range(count):
        var target_idx: int = _index_by_id(targets[barrel])
        if target_idx < 0:
            continue
        var enemy: Dictionary = enemies[target_idx]
        var target: Vector2 = enemy["pos"]
        var muzzle: Vector2 = GuardianRenderer.sentinel_muzzle(G, barrel, count)
        var flight: float = muzzle.distance_to(target) / (speed + float(enemy["speed"]))
        var lead: Vector2 = target + Vector2(0.0, float(enemy["speed"]) * flight * 0.75)
        var velocity: Vector2 = (lead - muzzle).normalized() * speed
        gun_visual_lanes.append({
            "muzzle": muzzle, "direction": velocity.normalized(),
            "fired_at": _visual_clock
        })
        projectiles.append({
            "pos": muzzle, "velocity": velocity,
            "damage": _power(7.0 + 2.0 * (int(levels["gun"]) - 1)) * (1.0 + 0.25 * int(levels["gun_payload"])),
            "life": 1.50 + float(levels["gun_ricochet"]) * 0.30,
            "target": int(enemy["id"]), "kind": "gun",
            "pierce_left": int(levels["gun_pierce"]), "ricochet_left": int(levels["gun_ricochet"]),
            "hit_ids": []
        })
    # Tip flashes are rendered directly from gun_visual_lanes (actual muzzles).
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
        _effect("beam", start, end, 4.0 + int(levels["beam"]), VisualProfile.PRISM_BEAM,
            0.36 if showcase_active else 0.21)
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
        _effect("arc", point, pos, 3.0, VisualProfile.ARC_BOLT,
            0.48 if showcase_active else 0.32)
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
    _effect("nova", center, Vector2.ZERO, radius, VisualProfile.NOVA_FIELD,
        1.05 if showcase_active else 0.76)
    _blast(center, radius, _power(17.0 + int(levels["nova"]) * 12.0), "nova", VisualProfile.NOVA_FIELD)
    for enemy in enemies:
        if Vector2(enemy["pos"]).distance_to(center) <= radius:
            enemy["slow"] = maxf(float(enemy["slow"]), 1.1 + float(levels["nova"]) * 0.30)
    # Comet Volley + Nova Field: detonations become supercharged.
    if int(levels["volley"]) >= 2 and int(levels["nova"]) >= 2:
        _blast(center, radius * 0.67, _power(24.0), "nova", VisualProfile.COMET_HOT)

func _blast(pos: Vector2, radius: float, amount: float, source: String, color: Color) -> void:
    if source != "nova":
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
    var kind: String = String(enemy["kind"])
    var effective: float = amount * GameCatalog.damage_factor(kind, source)
    # Overdrive ignores shields; everything else is cut while one holds.
    if int(enemy.get("shield", 0)) > 0 and source != "overdrive":
        effective *= shield_taken()
    if kind == "warden" and int(levels.get("breaker", 0)) >= 2:
        effective *= 1.4
    if id == focused_id:
        effective *= 1.0 + 0.20 * int(levels.get("uplink", 0))
    var actual: float = minf(maxf(0.0, effective), maxf(0.0, float(enemy["hp"])))
    enemy["flash"] = 0.16
    enemy["hp"] = float(enemy["hp"]) - actual
    weapon_damage[source] = float(weapon_damage.get(source, 0.0)) + actual
    if not low_fx:
        _effect("number", Vector2(enemy["pos"]) + Vector2(0, -15), Vector2.ZERO, actual, VisualProfile.DAMAGE_NUMBER, 0.42)
    if float(enemy["hp"]) <= 0.0:
        # Phase I.5: a kill pops in the enemy's own color; red rings are reserved
        # for danger (breach, enraged elite) so they never read as a hazard zone.
        _effect("pop", Vector2(enemy["pos"]), Vector2.ZERO, float(enemy["radius"]) * 2.1,
            VisualProfile.enemy_tint(String(enemy["kind"])), 0.26)
        _on_kill(enemy, id)
        enemies.remove_at(_index_by_id(id))
    return actual

func _on_kill(enemy: Dictionary, id: int) -> void:
    var kind: String = String(enemy["kind"])
    var high_line: bool = line_enabled and line >= GameCatalog.LINE_HIGH
    xp += roundi(int(enemy["xp"]) * (GameCatalog.LINE_HIGH_XP if high_line else 1.0))
    kills += 1
    var capacitor: int = int(levels.get("od_capacitor", 0))
    var charge: float = GameCatalog.overdrive_charge_for(kind) * (1.9 if capacitor >= 3 else 1.0 + 0.30 * capacitor)
    if showcase_active:
        charge *= GameCatalog.HARD_OVERDRIVE_SCALE
    if id == focused_id and int(levels.get("uplink", 0)) >= 2:
        charge += 4.0
    overdrive_charge = minf(GameCatalog.OVERDRIVE_FULL, overdrive_charge + charge)
    if line_enabled:
        line = minf(1.0, line + GameCatalog.LINE_KILL * GameCatalog.line_weight(kind)
            * (1.0 + 0.35 * int(levels.get("line_anchor", 0))))
    if kind == "warden" and int(levels.get("breaker", 0)) >= 3:
        _pending_shocks.append(Vector2(enemy["pos"]))
    if focused_id == id:
        focused_id = _next_priority_target(enemy["pos"], id) if int(levels.get("uplink", 0)) >= 3 else -1


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
        "formations": formation_index, "overdrives": overdrives_fired
    })

func _effect(kind: String, a: Vector2, b: Vector2, radius: float, color: Color, duration: float) -> void:
    if effects.size() > (46 if low_fx else 100):
        effects.pop_front()
    effects.append({"kind": kind, "a": a, "b": b, "radius": radius, "color": color, "ttl": duration, "duration": duration})

func _draw() -> void:
    ArenaBackground.draw_to(self, low_fx, _visual_clock, stage)
    if line_enabled:
        MechanicVisuals.draw_line_marker(self, line_y(), line, low_fx, _visual_clock)
    for enemy in enemies:
        if String(enemy["kind"]) == "warden":
            MechanicVisuals.draw_warden_aura(self, enemy["pos"], low_fx, _visual_clock)
    for drop in pending_drops:
        EnemyRenderer.draw_drop_marker(self, drop, _visual_clock)
    var damage_fraction: float = clampf((_guardian_damage_until - _visual_clock) / 0.32, 0.0, 1.0)
    GuardianRenderer.draw_to(self, G, low_fx, _visual_clock,
        GuardianRenderer.sentinel_barrel_count(int(levels.get("gun", 1)), int(levels.get("gun_volley", 0))),
        gun_visual_lanes, damage_fraction)
    for enemy in enemies:
        var focused: bool = int(enemy["id"]) == focused_id
        if String(enemy["kind"]) == "warden":
            MechanicVisuals.draw_warden(self, enemy, low_fx, _visual_clock, focused)
        else:
            EnemyRenderer.draw_to(self, enemy, low_fx, _visual_clock, focused, _elite_enraged)
        if int(enemy["shield"]) > 0:
            MechanicVisuals.draw_shield_mark(self, enemy, low_fx)
    for bullet in projectiles:
        WeaponEffects.draw_projectile(self, bullet, low_fx)
    for fx in effects:
        if String(fx["kind"]) == "overdrive":
            MechanicVisuals.draw_overdrive(self, fx, low_fx)
        else:
            WeaponEffects.draw_effect(self, fx, low_fx, _visual_clock)
