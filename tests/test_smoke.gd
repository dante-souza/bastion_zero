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
    _expect(GameCatalog.TOTAL_WAVES == 8, "eight waves")
    _expect(bool(ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch", false)), "Android touchscreen taps activate GUI buttons")
    _expect(GameCatalog.next_level_xp(2) > GameCatalog.next_level_xp(1), "XP progression increases")
    _expect(GameCatalog.meta_cost("hull", 0) == 68, "first hull research costs 68")
    _expect(GameCatalog.meta_cost("damage", 8) == -1, "research capped")
    _expect(GameCatalog.reward(0, 1, true) > GameCatalog.reward(0, 1, false), "victory reward")
    var rng := RandomNumberGenerator.new()
    rng.seed = 123
    var levels: Dictionary = {}
    for key in GameCatalog.UPGRADE_ORDER:
        levels[key] = 0
    var offers := GameCatalog.upgrade_offers(levels, rng)
    _expect(offers.size() == 3, "three offers")
    _expect(offers[0] != offers[1] and offers[1] != offers[2] and offers[0] != offers[2], "unique offers")
    var save := SaveData.defaults()
    save["bank"] = 68
    _expect(SaveData.buy_meta(save, "hull"), "buy available upgrade")
    _expect(save["bank"] == 0 and save["meta"]["hull"] == 1, "purchase debit and rank")
    _expect(not SaveData.buy_meta(save, "damage"), "reject unaffordable upgrade")
    var normalized := SaveData.validated({"bank": -4, "meta": {"hull": 800}})
    _expect(normalized["bank"] == 0 and normalized["meta"]["hull"] == 8, "normalize saved values")
    var arena := Arena.new()
    root.add_child(arena)
    arena.begin_run({"hull": 1, "damage": 2})
    _expect(arena.state == "running" and arena.max_hull == 116.0, "run initialization")
    arena.state = "upgrade"
    arena.choose_upgrade("arc")
    _expect(arena.state == "running" and arena.levels["arc"] == 1, "upgrade selection")
    arena.toggle_pause()
    _expect(arena.state == "paused", "pause")
    arena.toggle_pause()
    _expect(arena.state == "running", "resume")
    arena.queue_free()
    var game_scene: Control = (load("res://scenes/main.tscn") as PackedScene).instantiate()
    root.add_child(game_scene)
    _expect(game_scene.mouse_filter == Control.MOUSE_FILTER_IGNORE, "game root leaves battlefield taps unhandled")
    var deploy_button: Button = null
    for node in game_scene.find_children("*", "Button", true, false):
        if (node as Button).text.begins_with("DEPLOY"):
            deploy_button = node as Button
            break
    _expect(deploy_button != null, "hangar deploy button exists")
    if deploy_button != null:
        deploy_button.pressed.emit()
        var active_arena: Arena = game_scene.get("arena")
        _expect(active_arena.state == "running", "deploy button initiates the battle")
    game_scene.queue_free()
    print("RESULT: ", "PASS" if failures == 0 else "%d FAILURES" % failures)
    quit(0 if failures == 0 else 1)
