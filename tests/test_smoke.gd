extends SceneTree

var failures := 0

func _initialize() -> void:
    call_deferred("_run")

func _expect(ok: bool, label: String) -> void:
    if ok:
        print("PASS ", label)
    else:
        failures += 1
        push_error("FAIL " + label)

func _run() -> void:
    _expect(GameCatalog.TOTAL_STAGES == 2, "normal and elite stages")
    _expect(GameCatalog.stage_name(1) == "NORMAL 01", "stage one name")
    _expect(GameCatalog.stage_name(2) == "ELITE 01", "stage two name")
    _expect(GameCatalog.stage_duration(2) > GameCatalog.stage_duration(1), "elite lasts longer")
    _expect(GameCatalog.GUARDIAN.y > GameCatalog.BREACH_Y, "guardian below defensive line")
    _expect(GameCatalog.next_level_xp(2) > GameCatalog.next_level_xp(1), "progressive XP")
    _expect(GameCatalog.meta_cost("hull", 0) == 68, "initial research price")
    _expect(GameCatalog.meta_cost("damage", 8) == -1, "research is capped")
    _expect(bool(ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch", false)), "Android touch reaches GUI")

    var rng := RandomNumberGenerator.new()
    rng.seed = 12345
    var upgrades: Dictionary = {}
    for key in GameCatalog.UPGRADE_ORDER:
        upgrades[key] = 0
    upgrades["beam"] = 1
    var offers: Array[String] = GameCatalog.upgrade_offers(upgrades, rng)
    _expect(offers.size() == 3, "three choices")
    _expect(offers[0] != offers[1] and offers[1] != offers[2] and offers[0] != offers[2], "nonduplicate offers")
    var has_unlock := false
    for key in offers:
        if GameCatalog.WEAPON_ORDER.has(key) and int(upgrades[key]) == 0:
            has_unlock = true
    _expect(has_unlock, "unlock available during early build")

    var legacy := SaveData.validated({"bank": 12, "meta": {"hull": 2}, "runs": 3, "wins": 2})
    _expect(legacy["bank"] == 12 and legacy["meta"]["hull"] == 2, "v1 player progress migrates")
    _expect(legacy["stage_unlocked"] == 1 and legacy["low_fx"], "new fields get defaults")
    var wallet := SaveData.defaults()
    wallet["bank"] = 68
    _expect(SaveData.buy_meta(wallet, "hull"), "research purchase")
    _expect(wallet["bank"] == 0 and wallet["meta"]["hull"] == 1, "purchase persisted in state")
    SaveData.record_run(wallet, 1, true, {"reward": 94, "kills": 5})
    _expect(wallet["stage_unlocked"] == 2 and wallet["best_stage"] == 1, "victory unlocks elite")
    _expect(wallet["wins"] == 1 and wallet["bank"] == 94, "reward and victory tracked")
    _expect(CombatDirector.pattern_for(1, 0.0, 0) == "LINE", "Normal opens with line formation")
    _expect(CombatDirector.pattern_for(2, 0.0, 0) == "PINCER", "Elite opens with pincer")
    _expect(CombatDirector.pattern_for(2, 40.0, 0) != CombatDirector.pattern_for(1, 40.0, 0), "stages use distinct encounter pacing")
    var formations: Array[Dictionary] = CombatDirector.formation(2, 85.0, 3, rng)
    _expect(formations.size() >= 3, "authored late-game formations have multiple enemies")
    var formation_safe := true
    for member in formations:
        if float(member["x"]) < 40.0 or float(member["x"]) > 680.0:
            formation_safe = false
    _expect(formation_safe, "spawned enemies remain in battlefield lanes")
    _expect(is_equal_approx(GameCatalog.damage_factor("tank", "beam"), 0.72), "tank armor resists beams")
    _expect(GameCatalog.damage_factor("tank", "volley") > 1.0, "Comet Volley counters tank armor")
    _expect(GameCatalog.damage_factor("runner", "arc") > 1.0, "Arc Relay counters runners")
    var arena := Arena.new()
    root.add_child(arena)
    arena.begin_run({"hull": 1, "damage": 2}, 1, true)
    _expect(arena.state == "running" and arena.max_hull == 116.0, "battle initialize")
    _expect(arena.stage == 1 and arena.levels["beam"] == 1, "starting weapon and stage")
    arena._spawn_enemy("runner", 210.0, 140.0)
    _expect(arena.enemies.size() == 1 and Vector2(arena.enemies[0]["pos"]).y < GameCatalog.GUARDIAN.y, "enemy spawns above Guardian")
    var enemy_id: int = int(arena.enemies[0]["id"])
    var dealt: float = arena._damage_by_id(enemy_id, 11.5, "beam")
    _expect(is_equal_approx(dealt, 11.5) and is_equal_approx(float(arena.weapon_damage["beam"]), 11.5), "damage meter records applied damage")
    arena.focus_at(Vector2(arena.enemies[0]["pos"]))
    _expect(arena.focused_id == enemy_id, "tap enemy prioritizes target")
    arena.state = "upgrade"
    arena.choose_upgrade("arc")
    _expect(arena.state == "running" and arena.levels["arc"] == 1, "weapon upgrade activated")
    arena.toggle_pause()
    _expect(arena.state == "paused", "pause")
    arena.toggle_pause()
    _expect(arena.state == "running", "resume")
    arena._spawn_enemy("tank", 450.0, 170.0)
    var tank_id: int = int(arena.enemies.back()["id"])
    var tank_dealt := arena._damage_by_id(tank_id, 10.0, "beam")
    _expect(is_equal_approx(tank_dealt, 7.2), "armor applies during actual damage calculation")
    _expect(arena.weapon_damage["beam"] >= 18.7, "damage meter tracks armor-adjusted results")
    var elite_battle := Arena.new()
    root.add_child(elite_battle)
    elite_battle.begin_run({"hull": 0, "damage": 0}, 2, true)
    elite_battle._elite_spawned = true
    elite_battle._spawn_enemy("elite", 360.0, 195.0)
    elite_battle.enemies[0]["hp"] = float(elite_battle.enemies[0]["max_hp"]) * 0.49
    elite_battle._process_elite_phase()
    _expect(elite_battle._elite_enraged and elite_battle.enemies.size() == 3, "elite summons escorts at half health")
    elite_battle._process_elite_phase()
    _expect(elite_battle.enemies.size() == 3, "elite escorts summon only once")
    elite_battle.queue_free()
    arena._finish(false)
    _expect(arena.state == "finished", "stage loss ends battle")
    arena.queue_free()

    var game: Control = (load("res://scenes/main.tscn") as PackedScene).instantiate()
    root.add_child(game)
    _expect(game.mouse_filter == Control.MOUSE_FILTER_IGNORE, "fullscreen UI does not swallow taps")
    var deploy: Button
    for node in game.find_children("*", "Button", true, false):
        if (node as Button).text.begins_with("DEPLOY"):
            deploy = node as Button
            break
    _expect(deploy != null, "hangar contains deploy button")
    if deploy != null:
        deploy.pressed.emit()
        var live_arena: Arena = game.get("arena")
        _expect(live_arena.state == "running" and live_arena.stage == 1, "deployment opens Normal 1")
    game.queue_free()
    print("RESULT: ", "PASS" if failures == 0 else "%d FAILURES" % failures)
    quit(0 if failures == 0 else 1)
