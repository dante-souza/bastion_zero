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
    _expect(VisualProfile.BACKDROP == Color("#020509"), "Phase A uses near-black arena")
    var horizon := ArenaBackground.horizon_points()
    _expect(horizon.size() == ArenaBackground.SEGMENTS + 1, "horizon is a bounded sampled curve")
    if horizon.size() == ArenaBackground.SEGMENTS + 1:
        var left: Vector2 = horizon[0]
        var center: Vector2 = horizon[ArenaBackground.SEGMENTS / 2]
        var right: Vector2 = horizon[ArenaBackground.SEGMENTS]
        _expect(is_equal_approx(left.x, 0.0) and is_equal_approx(right.x, GameCatalog.WORLD_SIZE.x), "horizon spans arena width")
        _expect(is_equal_approx(left.y, right.y) and center.y < left.y, "horizon has symmetric upward crest")
        _expect(center.y < GameCatalog.BREACH_Y and left.y > GameCatalog.BREACH_Y, "horizon frames the defended zone without moving breach logic")
    _expect(ArenaBackground.horizon_y(-400.0) == ArenaBackground.horizon_y(0.0), "horizon clamps outside left edge")
    _expect(ArenaBackground.RADIAL_SECTORS == 32 and ArenaBackground.AURA_RADIUS.x > 400.0, "Phase B.1 uses smooth, bounded backdrop halo")
    _expect(ArenaBackground.AURA_CENTER.y < GameCatalog.GUARDIAN.y, "aura sits behind upper Guardian silhouette")
    _expect(GuardianRenderer.MODULE_DIRECTIONS.size() == 4 and GuardianRenderer.RING_SEGMENTS == 4, "four cardinal Guardian modules")
    _expect(GuardianRenderer.MODULE_TIP_RADIUS < 75.0 and GuardianRenderer.CORE_RADIUS > 12.0, "Guardian keeps J8-safe footprint and visible core")
    _expect(GuardianRenderer.module_point(GameCatalog.GUARDIAN, Vector2.UP).y < GameCatalog.GUARDIAN.y, "top module geometry is world-aligned")
    _expect(GuardianRenderer.module_point(GameCatalog.GUARDIAN, Vector2.RIGHT).x > GameCatalog.GUARDIAN.x, "side pod geometry is world-aligned")
    _expect(VisualProfile.GUARDIAN_RING_BLUE != VisualProfile.GUARDIAN_CORE, "Guardian armor and core are distinguishable")
    _expect(GameCatalog.next_level_xp(2) > GameCatalog.next_level_xp(1), "progressive XP")
    _expect(GameCatalog.meta_cost("hull", 0) == 68, "initial research price")
    _expect(GameCatalog.meta_cost("damage", 8) == -1, "research is capped")
    _expect(bool(ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch", false)), "Android touch reaches GUI")

    var rng := RandomNumberGenerator.new()
    rng.seed = 12345
    var upgrades: Dictionary = {}
    for key in GameCatalog.UPGRADE_ORDER:
        upgrades[key] = 0
    upgrades["gun"] = 1
    var offers: Array[String] = GameCatalog.upgrade_offers(upgrades, rng)
    _expect(offers.size() == 3, "three choices")
    _expect(offers[0] != offers[1] and offers[1] != offers[2] and offers[0] != offers[2], "nonduplicate offers")
    var has_unlock := false
    for key in offers:
        if GameCatalog.WEAPON_ORDER.has(key) and int(upgrades[key]) == 0:
            has_unlock = true
    _expect(has_unlock, "unlock available during early build")
    var sentinel_in_offers := false
    for offered in offers:
        if offered == "gun" or GameCatalog.GUN_MODS.has(offered):
            sentinel_in_offers = true
    _expect(sentinel_in_offers, "early card offers include a Sentinel evolution")

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
    var gun_battle := Arena.new()
    root.add_child(gun_battle)
    gun_battle.begin_run({"hull": 0, "damage": 0}, 1, true)
    gun_battle._spawn_enemy("tank", 360.0, 520.0)
    gun_battle._fire_beam()
    _expect(float(gun_battle.weapon_damage["beam"]) == 0.0, "Prism Beam cannot fire before card unlock")
    gun_battle._fire_gun()
    _expect(gun_battle.projectiles.size() == 1 and gun_battle.projectiles[0]["kind"] == "gun", "machinegun fires one built-in bullet")
    for tick in range(75):
        gun_battle._move_projectiles(1.0 / 60.0)
    _expect(float(gun_battle.weapon_damage["gun"]) > 0.0, "machinegun projectile reaches actual target")
    gun_battle.levels["gun"] = 3
    gun_battle._fire_gun()
    _expect(gun_battle.projectiles.size() == 2, "dual-barrel machinegun upgrade fires two rounds")
    gun_battle.projectiles.clear()
    gun_battle.levels["beam"] = 1
    gun_battle._fire_beam()
    _expect(float(gun_battle.weapon_damage["beam"]) > 0.0, "unlocked Prism hits target center")
    gun_battle.enemies.clear()
    gun_battle._spawn_enemy("tank", 160.0, 650.0)
    gun_battle._spawn_enemy("tank", 565.0, 635.0)
    gun_battle.levels["beam"] = 3
    var before_left: float = float(gun_battle.enemies[0]["hp"])
    var before_right: float = float(gun_battle.enemies[1]["hp"])
    var lanes: Array[int] = gun_battle._beam_target_ids()
    _expect(lanes.size() == 2 and lanes[0] != lanes[1], "split Prism lanes acquire two different enemies")
    gun_battle._fire_beam()
    _expect(float(gun_battle.enemies[0]["hp"]) < before_left and float(gun_battle.enemies[1]["hp"]) < before_right, "both split Prism beams hit their respective targets")
    gun_battle.queue_free()
    _expect(GameCatalog.upgrade_cap("gun_payload") == 3, "kinetic payload card cap")
    _expect(GameCatalog.upgrade_cap("gun_pierce") == 2 and GameCatalog.upgrade_cap("gun_ricochet") == 2, "independent penetration and ricochet caps")
    _expect(GameCatalog.upgrade_category("gun_pierce", 0) == "SENTINEL MOD", "Sentinel mod cards have their own category")
    var fully_upgraded: Dictionary = gun_battle.levels.duplicate()
    for key in GameCatalog.UPGRADE_ORDER:
        fully_upgraded[key] = GameCatalog.upgrade_cap(key)
    var offers_capped: Array[String] = GameCatalog.upgrade_offers(fully_upgraded, rng)
    _expect(offers_capped.is_empty(), "maxed cards disappear from upgrade pool")

    # Payload modifies the actual simulated projectile before contact.
    var payload_battle := Arena.new()
    root.add_child(payload_battle)
    payload_battle.begin_run({}, 1, true)
    payload_battle._spawn_enemy("tank", 360.0, 650.0)
    payload_battle._fire_gun()
    var regular_round: float = payload_battle.projectiles[0]["damage"]
    payload_battle.projectiles.clear()
    payload_battle.levels["gun_payload"] = 2
    payload_battle._fire_gun()
    _expect(is_equal_approx(float(payload_battle.projectiles[0]["damage"]), regular_round * 1.5), "Kinetic Payload actually increases bullet damage")
    payload_battle.queue_free()

    # Sabot Pierce should damage two aligned enemies with one physical round.
    var pierce_battle := Arena.new()
    root.add_child(pierce_battle)
    pierce_battle.begin_run({}, 1, true)
    pierce_battle.levels["gun_pierce"] = 1
    pierce_battle._spawn_enemy("tank", 360.0, 675.0)
    pierce_battle._spawn_enemy("tank", 360.0, 505.0)
    var p_id: int = int(pierce_battle.enemies[0]["id"])
    var q_id: int = int(pierce_battle.enemies[1]["id"])
    pierce_battle._fire_gun()
    for tick in range(110):
        pierce_battle._move_projectiles(1.0 / 60.0)
    _expect(float(pierce_battle.weapon_damage["gun"]) > 7.0, "Sabot Piercer registers more than one hit")
    _expect(float(pierce_battle.enemies[pierce_battle._index_by_id(p_id)]["hp"]) < float(pierce_battle.enemies[pierce_battle._index_by_id(p_id)]["max_hp"]), "piercing hits first target")
    _expect(float(pierce_battle.enemies[pierce_battle._index_by_id(q_id)]["hp"]) < float(pierce_battle.enemies[pierce_battle._index_by_id(q_id)]["max_hp"]), "piercing hits second target")
    pierce_battle.queue_free()

    # Ricochet must retarget a different enemy rather than damaging the same one repeatedly.
    var bounce_battle := Arena.new()
    root.add_child(bounce_battle)
    bounce_battle.begin_run({}, 1, true)
    bounce_battle.levels["gun_ricochet"] = 1
    bounce_battle._spawn_enemy("tank", 215.0, 680.0)
    bounce_battle._spawn_enemy("tank", 540.0, 660.0)
    bounce_battle._fire_gun()
    for tick in range(115):
        bounce_battle._move_projectiles(1.0 / 60.0)
    _expect(float(bounce_battle.enemies[0]["hp"]) < float(bounce_battle.enemies[0]["max_hp"]), "ricochet origin enemy takes damage")
    _expect(float(bounce_battle.enemies[1]["hp"]) < float(bounce_battle.enemies[1]["max_hp"]), "ricochet damages distinct second target")
    bounce_battle.queue_free()

    # Saturation Burst fires real independently targeted rounds (not a decorative fan).
    var volley_battle := Arena.new()
    root.add_child(volley_battle)
    volley_battle.begin_run({}, 1, true)
    volley_battle.levels["gun"] = 3
    volley_battle.levels["gun_volley"] = 2
    volley_battle._spawn_enemy("tank", 200.0, 670.0)
    volley_battle._spawn_enemy("tank", 510.0, 640.0)
    volley_battle._fire_gun()
    var targeted: Dictionary = {}
    for bullet in volley_battle.projectiles:
        targeted[int(bullet["target"])] = true
    _expect(volley_battle.projectiles.size() == 4, "Saturation Burst adds real projectiles")
    _expect(targeted.size() == 2, "Saturation Burst targets separate threats")
    volley_battle.queue_free()
    var arena := Arena.new()
    root.add_child(arena)
    arena.begin_run({"hull": 1, "damage": 2}, 1, true)
    _expect(arena.state == "running" and arena.max_hull == 116.0, "battle initialize")
    _expect(arena.stage == 1 and arena.levels["gun"] == 1 and arena.levels["beam"] == 0, "machinegun is built in and Prism is locked")
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

    # A card showing next rank 3/3 is eligible only while current rank is 2.
    var cap_levels: Dictionary = arena.levels.duplicate()
    cap_levels["gun_payload"] = 2
    _expect(GameCatalog.upgrade_available(cap_levels, "gun_payload"), "final 3/3 level can be acquired from 2/3")
    _expect(GameCatalog.upgrade_description("gun_payload", 3).find("%d") < 0, "Kinetic Payload description has no unformatted placeholder")
    cap_levels["gun_payload"] = 3
    _expect(not GameCatalog.upgrade_available(cap_levels, "gun_payload"), "maxed 3/3 Payload is no longer eligible")
    for selection in range(30):
        var choices: Array[String] = GameCatalog.upgrade_offers(cap_levels, rng)
        _expect(not choices.has("gun_payload"), "max-rank Payload never returns as an offer")
    arena.state = "upgrade"
    arena.levels["gun_payload"] = 2
    arena.choose_upgrade("gun_payload")
    _expect(int(arena.levels["gun_payload"]) == 3 and arena.state == "running", "final rank selection applies correctly")
    arena.state = "upgrade"
    arena.choose_upgrade("gun_payload")
    _expect(int(arena.levels["gun_payload"]) == 3 and arena.state == "upgrade", "duplicate max-rank selection cannot increase rank")

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
        live_arena.state = "upgrade"
        live_arena.levels["gun_payload"] = 2
        var menu_offers: Array[String] = ["gun_payload", "gun", "volley"]
        game.call("_choose_system", menu_offers)
        var ui_cards: Array[Node] = []
        var rank_label_found := false
        var active_menu: ColorRect = game.get("modal")
        for node in active_menu.find_children("*", "Button", true, false):
            if node.has_meta("upgrade_key"):
                ui_cards.append(node)
                if String(node.get_meta("upgrade_key")) == "gun_payload":
                    for lbl in node.find_children("*", "Label", true, false):
                        if String(lbl.text).contains("OWNED 2/3") and String(lbl.text).contains("NEXT 3/3"):
                            rank_label_found = true
                    _expect(float(node.custom_minimum_size.y) >= 180.0, "evolution choice cards have tall readable touch targets")
        _expect(ui_cards.size() == 3 and rank_label_found, "system evolution shows correct owned-to-next rank")
        game.call("_apply_upgrade", "gun_payload")
        _expect(int(live_arena.levels["gun_payload"]) == 3, "UI confirms final Kinetic Payload rank")
        live_arena.state = "upgrade"
        game.call("_choose_system", menu_offers)
        var max_card_visible := false
        active_menu = game.get("modal")
        for node in active_menu.find_children("*", "Button", true, false):
            if node.has_meta("upgrade_key") and String(node.get_meta("upgrade_key")) == "gun_payload":
                max_card_visible = true
        _expect(not max_card_visible, "max-ranked Payload card is hidden even when offered stale data")
        _expect(live_arena.state == "upgrade", "stale card filtering does not unpause battle")

    game.queue_free()
    print("RESULT: ", "PASS" if failures == 0 else "%d FAILURES" % failures)
    quit(0 if failures == 0 else 1)
