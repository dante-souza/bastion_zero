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
    _expect(load("res://assets/branding/last_horizon_boot.png") is Texture2D,
        "native Godot boot splash imports as a PNG texture")
    _expect(load("res://assets/branding/guardian_launcher_192.png") is Texture2D,
        "Android launcher icon is an imported 192px PNG")
    _expect(load("res://assets/branding/guardian_adaptive_foreground_432.png") is Texture2D
        and load("res://assets/branding/guardian_adaptive_background_432.png") is Texture2D,
        "Android 8+ adaptive icon foreground/background resources import")
    _expect(load("res://assets/branding/guardian_icon.svg") != null,
        "Last Horizon app icon resource imports")
    _expect(HangarView.HERO != null and HangarView.HERO.get_size().x >= 680.0,
        "Hangar visual uses J8-readable same-Guardian horizon artwork")
    _expect(EvolutionProfile.tactical_role("beam") == "PRECISE ENERGY LANE",
        "Phase F labels Prism role clearly")
    _expect(EvolutionProfile.accent("beam") == VisualProfile.PRISM_BEAM and
        EvolutionProfile.accent("nova") == VisualProfile.NOVA_FIELD,
        "Evolution card accents use actual weapon colors")
    _expect(EvolutionProfile.rank_marks(2, 4) == "●●○○" and
        EvolutionProfile.rank_marks(3, 3) == "●●●",
        "Upgrade rank pips accurately show progress and cap")
    _expect(EvolutionProfile.synergy_summary(GameCatalog.SHOWCASE_LOADOUT).contains("PRISM + ARC") and
        EvolutionProfile.synergy_summary(GameCatalog.SHOWCASE_LOADOUT).contains("COMET + NOVA"),
        "Synergy labels reflect real unlocked weapon pairs")
    _expect(HudProfile.top_height() <= 110.0 and HudProfile.top_height() >= 100.0,
        "Phase E compacts top HUD by roughly 30 percent")
    _expect(HudProfile.bottom_height() <= 82.0,
        "Phase E compacts bottom HUD by roughly 27 percent")
    _expect(HudProfile.PAUSE_SIZE.x >= 44.0 and HudProfile.PAUSE_SIZE.y >= 44.0,
        "pause remains a touch-safe control")
    _expect(HudProfile.XP_HEIGHT <= 12.0, "XP progress bar is slimmer")
    _expect(HudProfile.TACTICAL_TOP_END < HudProfile.TACTICAL_WARNING_START and
        HudProfile.TACTICAL_WARNING_END < HudProfile.TACTICAL_ELITE_START,
        "I.1 tactical header, warnings and elite health never overlap")
    _expect(HudProfile.TACTICAL_TRAY_START < -110.0 and
        HudProfile.TACTICAL_TRAY_END == -10.0,
        "five-weapon tray stays below Guardian")
    _expect(TacticalHud.SLOT_KEYS.size() == 5 and
        TacticalHud.SLOT_KEYS == GameCatalog.WEAPON_ORDER,
        "tactical status slots map to five real equipped weapon types")
    _expect(TacticalHud.SLOT_COLORS[1] == VisualProfile.PRISM_BEAM and
        TacticalHud.SLOT_COLORS[4] == VisualProfile.NOVA_FIELD,
        "status slot colors match existing combat effects")
    _expect(WeaponEffects.ARC_SEGMENTS_LOW < WeaponEffects.ARC_SEGMENTS_FULL,
        "J8 low-FX chain lighting remains cheaper after readability pass")
    _expect(VisualProfile.PRISM_BEAM == Color("#FF56DD"), "Phase D Prism uses magenta identity")
    _expect(VisualProfile.NOVA_FIELD == Color("#47E7A8"), "Phase D Nova uses jade identity")
    _expect(VisualProfile.COMET_TRAIL != VisualProfile.GUN_TRACER, "Comet trails differ from gun tracers")
    _expect(VisualProfile.ARC_BOLT != VisualProfile.PRISM_BEAM, "Arc relay distinct from Prism")
    var lightning_low: PackedVector2Array = WeaponEffects.lightning_points(Vector2(10, 20), Vector2(210, 220), true)
    var lightning_full: PackedVector2Array = WeaponEffects.lightning_points(Vector2(10, 20), Vector2(210, 220), false)
    _expect(lightning_low.size() < lightning_full.size(), "J8 low-FX lightning uses fewer vertices")
    _expect(lightning_full[0] == Vector2(10, 20) and lightning_full[lightning_full.size() - 1] == Vector2(210, 220), "lightning shares exact real chain endpoints")
    _expect(GameCatalog.STAGE_ONE_SHOWCASE and GameCatalog.SHOWCASE_START_LEVEL == 12,
        "pressure QA starts at level 12")
    _expect(GameCatalog.SHOWCASE_SCRIPT.size() == 6 and GameCatalog.SHOWCASE_ELITE_TIME == 18.0,
        "six deterministic pressure encounters with earlier escorted elite")
    _expect(GameCatalog.SHOWCASE_FORMATIONS_START == 12.0 and GameCatalog.SHOWCASE_FORMATION_INTERVAL <= 1.2,
        "normal formations overlap the second half of QA encounters")
    _expect(GameCatalog.SHOWCASE_HP_SCALE > 1.0 and GameCatalog.SHOWCASE_SPEED_SCALE > 1.0
        and GameCatalog.SHOWCASE_DAMAGE_SCALE > 1.0, "showcase challenges both offense and defense")
    var preview := Arena.new()
    root.add_child(preview)
    preview.begin_run({}, 1, true, true)
    _expect(preview.showcase_active and preview.level == 12 and preview.showcase_script_index == 1,
        "QA deployment starts with first pressure wave")
    _expect(preview.enemies.size() == 9 and not preview.showcase_regular_spawns_unlocked,
        "nine differentiated threats are immediately visible")
    _expect(int(preview.levels["gun"]) == 4 and int(preview.levels["beam"]) == 2
        and int(preview.levels["volley"]) == 2 and int(preview.levels["arc"]) == 2
        and int(preview.levels["nova"]) == 2, "five strong starting weapon ranks remain")
    _expect(float(preview.enemies[0]["hp"]) > 29.0 * 4.0,
        "scripted grunt has enough HP for powerful weapons")
    _expect(float(preview.enemies[0]["speed"]) > 82.0 and
        float(preview.enemies[0]["damage"]) > 7.0, "QA foes move faster and hit harder")
    preview.elapsed = 4.0
    preview._tick_showcase_script()
    _expect(preview.enemies.size() == 17 and preview.showcase_script_index == 2, "eight fast flankers at second four")
    preview.elapsed = 8.0
    preview._tick_showcase_script()
    _expect(preview.enemies.size() == 27 and preview.showcase_script_index == 3, "armored formation reaches 27 threats")
    preview.elapsed = 12.0
    preview._tick_showcase_script()
    _expect(preview.enemies.size() == 39 and preview.showcase_script_index == 4
        and preview.showcase_regular_spawns_unlocked, "swarm pressure and standard formations overlap")
    preview.elapsed = 18.0
    preview._tick_showcase_script()
    _expect(preview.enemies.size() == 48 and preview.showcase_script_index == 5
        and preview._showcase_elite_spawned, "elite enters with escorts")
    var boss_count := 0
    for enemy in preview.enemies:
        if String(enemy["kind"]) == "elite":
            boss_count += 1
            _expect(float(enemy["max_hp"]) > 900.0 * 2.5, "QA elite survives long enough to inspect")
    _expect(boss_count == 1, "scripted pressure spawns exactly one elite")
    preview.elapsed = 22.0
    preview._tick_showcase_script()
    _expect(preview.enemies.size() == 58 and preview.showcase_script_index == 6,
        "second flank brings authored pressure to 58 enemies before regular formations")
    preview._tick_showcase_script()
    _expect(preview.enemies.size() == 58 and boss_count == 1, "no duplicate scripted encounters")
    preview.queue_free()
    var normal_preview := Arena.new()
    root.add_child(normal_preview)
    normal_preview.begin_run({}, 1, true, false)
    _expect(not normal_preview.showcase_active and normal_preview.level == 1 and int(normal_preview.levels["beam"]) == 0 and normal_preview.enemies.is_empty(), "ordinary run remains unchanged when showcase disabled")
    _expect(normal_preview.showcase_regular_spawns_unlocked, "normal runs allow immediate formations")
    normal_preview._spawn_enemy("grunt", 145.0, 445.0)
    _expect(is_equal_approx(float(normal_preview.enemies[0]["hp"]), 29.0), "normal grunt HP never receives temporary showcase multiplier")
    normal_preview.queue_free()
    var stage2_preview := Arena.new()
    root.add_child(stage2_preview)
    stage2_preview.begin_run({}, 2, true, true)
    _expect(not stage2_preview.showcase_active and stage2_preview.level == 1 and int(stage2_preview.levels["nova"]) == 0, "ELITE 01 never receives the NORMAL 01 showcase")
    stage2_preview.queue_free()
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
    _expect(GuardianRenderer.MODULE_TIP_RADIUS < 90.0 and GuardianRenderer.CORE_RADIUS > 12.0, "Guardian keeps J8-safe footprint and visible core")
    _expect(GuardianRenderer.ART != null and GuardianRenderer.ART.get_size().x >= 320.0, "Guardian illustrated SVG imports as a real Texture2D")
    _expect(GuardianRenderer.DISPLAY_SIZE >= 200.0, "Guardian is larger than the original wireframe design")
    _expect(VisualProfile.GUARDIAN_AURA.a > 0.35, "near-black arena has a visible soft lower-field gradient")
    _expect(GuardianRenderer.module_point(GameCatalog.GUARDIAN, Vector2.UP).y < GameCatalog.GUARDIAN.y, "top module geometry is world-aligned")
    _expect(GuardianRenderer.module_point(GameCatalog.GUARDIAN, Vector2.RIGHT).x > GameCatalog.GUARDIAN.x, "side pod geometry is world-aligned")
    _expect(VisualProfile.GUARDIAN_RING_BLUE != VisualProfile.GUARDIAN_CORE, "Guardian armor and core are distinguishable")
    _expect(GuardianRenderer.sentinel_barrel_count(1, 0) == 1, "B.2 one built-in barrel")
    _expect(GuardianRenderer.sentinel_barrel_count(3, 0) == 2, "B.2 dual barrel visible after rank three")
    _expect(GuardianRenderer.sentinel_barrel_count(3, 2) == 4, "B.2 saturation upgrade gives four real channels")
    var left_muzzle: Vector2 = GuardianRenderer.sentinel_muzzle(GameCatalog.GUARDIAN, 0, 2)
    var right_muzzle: Vector2 = GuardianRenderer.sentinel_muzzle(GameCatalog.GUARDIAN, 1, 2)
    _expect(left_muzzle.x < GameCatalog.GUARDIAN.x and right_muzzle.x > GameCatalog.GUARDIAN.x, "paired muzzles straddle Guardian")
    _expect(is_equal_approx(left_muzzle.y, GameCatalog.GUARDIAN.y - 45.0), "B.2 preserves original launch height")
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
    _expect(VisualProfile.GRUNT == Color("#52F52A"), "Phase C grunts use neon green")
    _expect(VisualProfile.RUNNER == Color("#FF9A37"), "Phase C runners use orange")
    _expect(VisualProfile.TANK == Color("#F4DE45"), "Phase C armored enemies use gold")
    _expect(VisualProfile.ELITE != VisualProfile.GRUNT and VisualProfile.ELITE != VisualProfile.RUNNER, "elites have distinct magenta identity")
    _expect(EnemyRenderer.visual_radius("runner", 12.0) >= 18.0, "small runners remain visible on J8")
    _expect(EnemyRenderer.visual_radius("grunt", 16.0) >= 18.0, "grunt ring remains visible on J8")
    _expect(EnemyRenderer.visual_radius("tank", 27.0) == 27.0, "armored silhouette uses existing tank scale")
    _expect(EnemyRenderer.visual_radius("elite", 48.0) == 48.0, "elite scale unchanged")
    var triangle: PackedVector2Array = EnemyRenderer.triangle_vertices(Vector2(80.0, 80.0), 19.0)
    _expect(triangle.size() == 3 and triangle[0].y > triangle[1].y, "runner geometry forms forward/down-pointing triangle")
    _expect(not EnemyRenderer.show_health("grunt", 1.0, false), "full-health grunts omit noisy floating bars")
    _expect(EnemyRenderer.show_health("grunt", 0.70, false), "damaged grunts reveal their real health")
    _expect(EnemyRenderer.show_health("runner", 1.0, true), "focused runner shows health bar")
    _expect(EnemyRenderer.show_health("elite", 1.0, false), "elites always show health bar")
    var gun_battle := Arena.new()
    root.add_child(gun_battle)
    gun_battle.begin_run({"hull": 0, "damage": 0}, 1, true)
    gun_battle._spawn_enemy("tank", 360.0, 520.0)
    gun_battle._fire_beam()
    _expect(float(gun_battle.weapon_damage["beam"]) == 0.0, "Prism Beam cannot fire before card unlock")
    gun_battle._fire_gun()
    _expect(gun_battle.projectiles.size() == 1 and gun_battle.projectiles[0]["kind"] == "gun", "machinegun fires one built-in bullet")
    _expect(gun_battle.gun_visual_lanes.size() == gun_battle.projectiles.size(), "each physical bullet has one visual lane")
    if gun_battle.gun_visual_lanes.size() == 1:
        _expect(Vector2(gun_battle.gun_visual_lanes[0]["muzzle"]) == GuardianRenderer.sentinel_muzzle(GameCatalog.GUARDIAN, 0, 1), "barrel tip and bullet origin agree")
        _expect(Vector2(gun_battle.gun_visual_lanes[0]["direction"]).is_equal_approx(Vector2(gun_battle.projectiles[0]["velocity"]).normalized()), "barrel aims along real fired round")
    for tick in range(75):
        gun_battle._move_projectiles(1.0 / 60.0)
    _expect(float(gun_battle.weapon_damage["gun"]) > 0.0, "machinegun projectile reaches actual target")
    gun_battle.levels["gun"] = 3
    gun_battle._fire_gun()
    _expect(gun_battle.projectiles.size() == 2, "dual-barrel machinegun upgrade fires two rounds")
    _expect(gun_battle.gun_visual_lanes.size() == 2, "both dual muzzles appear during burst")
    if gun_battle.gun_visual_lanes.size() == 2:
        var dual_matches := true
        for barrel in range(2):
            dual_matches = dual_matches and Vector2(gun_battle.gun_visual_lanes[barrel]["muzzle"]) == Vector2(gun_battle.projectiles[barrel]["pos"])
        _expect(dual_matches, "both displayed muzzles equal physical projectile origins")
    gun_battle.projectiles.clear()
    gun_battle.levels["beam"] = 1
    gun_battle._fire_beam()
    _expect(float(gun_battle.weapon_damage["beam"]) > 0.0, "unlocked Prism hits target center")
    _expect(gun_battle.effects.any(func(e: Dictionary) -> bool:
        return String(e["kind"]) == "beam" and Color(e["color"]) == VisualProfile.PRISM_BEAM),
        "live Prism effect stores magenta ray from damage simulation")
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
    _expect(volley_battle.gun_visual_lanes.size() == 4, "Saturation Burst draws four real barrels")
    if volley_battle.gun_visual_lanes.size() == 4:
        var all_aligned := true
        for lane in range(4):
            all_aligned = all_aligned and Vector2(volley_battle.gun_visual_lanes[lane]["muzzle"]) == Vector2(volley_battle.projectiles[lane]["pos"])
        _expect(all_aligned, "all Saturation barrels launch actual rounds")
    _expect(targeted.size() == 2, "Saturation Burst targets separate threats")
    var effect_battle := Arena.new()
    root.add_child(effect_battle)
    effect_battle.begin_run({}, 1, true, false)
    effect_battle.levels["volley"] = 1
    effect_battle.levels["arc"] = 1
    effect_battle.levels["nova"] = 1
    effect_battle._spawn_enemy("tank", 360.0, 560.0)
    effect_battle._spawn_enemy("tank", 430.0, 570.0)
    effect_battle._fire_volley()
    _expect(effect_battle.projectiles.size() == 3 and String(effect_battle.projectiles[0]["kind"]) == "rocket",
        "Phase D Comet still emits real three-lane missiles")
    effect_battle._fire_arc()
    _expect(effect_battle.effects.any(func(e: Dictionary) -> bool: return String(e["kind"]) == "arc"),
        "live Arc Relay uses lightning-specific effect")
    effect_battle._fire_nova()
    _expect(effect_battle.effects.any(func(e: Dictionary) -> bool:
        return String(e["kind"]) == "nova" and Color(e["color"]) == VisualProfile.NOVA_FIELD),
        "live Nova Field uses jade pulse at real blast position")
    _expect(float(effect_battle.weapon_damage["arc"]) > 0.0 and float(effect_battle.weapon_damage["nova"]) > 0.0,
        "Arc and Nova presentation changes do not prevent real damage")
    effect_battle.queue_free()
    volley_battle.queue_free()
    var arena := Arena.new()
    root.add_child(arena)
    arena.begin_run({"hull": 1, "damage": 2}, 1, true)
    _expect(arena.state == "running" and arena.max_hull == 116.0, "battle initialize")
    _expect(arena.stage == 1 and arena.levels["gun"] == 1 and arena.levels["beam"] == 0, "machinegun is built in and Prism is locked")
    arena._spawn_enemy("runner", 210.0, 140.0)
    _expect(arena.enemies.size() == 1 and Vector2(arena.enemies[0]["pos"]).y < GameCatalog.GUARDIAN.y, "enemy spawns above Guardian")
    _expect(float(arena.enemies[0]["radius"]) == 12.0, "runner collision size is unchanged by its enlarged outline")
    arena._spawn_enemy("grunt", 300.0, 140.0)
    _expect(float(arena.enemies.back()["radius"]) == 16.0, "grunt collision size unchanged")
    arena.enemies.pop_back()
    var breach_visual := Arena.new()
    root.add_child(breach_visual)
    breach_visual.begin_run({}, 1, true)
    breach_visual._spawn_enemy("runner", 200.0, GameCatalog.BREACH_Y + 1.0)
    breach_visual._move_enemies(0.0)
    _expect(breach_visual._guardian_damage_until > breach_visual._visual_clock, "actual breach sets short localized Guardian damage flash")
    _expect(is_equal_approx(breach_visual.hull, breach_visual.max_hull - 6.0), "damage visual does not modify hull damage balance")
    breach_visual.queue_free()
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
    var title_view: TitleMenuView = game.get("modal") as TitleMenuView
    _expect(title_view != null, "Phase I.3 opens tactical title before Hangar")
    if title_view != null:
        var art: TitleHorizonArt = title_view.find_child("TitleBattlefieldArt", true, false) as TitleHorizonArt
        var guardian_icon: TextureRect = title_view.find_child("TitleGuardian", true, false) as TextureRect
        var deploy_primary: Button = title_view.find_child("DeployPrimary", true, false) as Button
        var nav: HBoxContainer = title_view.find_child("TitleNavigation", true, false) as HBoxContainer
        _expect(art != null and guardian_icon != null and guardian_icon.texture != null,
            "title uses original gameplay Guardian and clean defensive horizon art")
        _expect(deploy_primary != null and nav != null and nav.get_child_count() == 3,
            "large DEPLOY action plus HANGAR/SECTORS/SETTINGS native navigation")
        var heading: Label = title_view.find_child("BastionWordmark", true, false) as Label
        var zero: Label = title_view.find_child("ZeroWordmark", true, false) as Label
        _expect(heading != null and zero != null and
            heading.text == "BASTION" and zero.text == "Z E R O",
            "native two-line title follows approved tactical reference")
        var sectors_button: Button = title_view.find_child("OpenSectors", true, false) as Button
        if sectors_button != null:
            sectors_button.pressed.emit()
            var sector_normal: Button = (game.get("modal") as ColorRect).find_child(
                "SectorNormal", true, false) as Button
            var sector_elite: Button = (game.get("modal") as ColorRect).find_child(
                "SectorElite", true, false) as Button
            _expect(sector_normal != null and sector_elite != null and sector_elite.disabled,
                "SECTORS opens real Normal deployment and properly locked Elite")
        game.call("_title")
        var settings_title: TitleMenuView = game.get("modal") as TitleMenuView
        var settings_button: Button = settings_title.find_child("OpenSettings", true, false) as Button
        if settings_button != null:
            settings_button.pressed.emit()
            var fx_button: Button = (game.get("modal") as ColorRect).find_child(
                "SettingsFx", true, false) as Button
            _expect(fx_button != null, "SETTINGS opens working native graphics control")
        game.call("_title")
        var open_hangar: Button = (game.get("modal") as TitleMenuView).find_child(
            "OpenHangar", true, false) as Button
        _expect(open_hangar != null, "HANGAR navigation has real button")
        if open_hangar != null:
            open_hangar.pressed.emit()
    var hangar_view: HangarView = game.get("modal") as HangarView
    _expect(hangar_view != null, "Phase G Hangar stays accessible from tactical title")
    if hangar_view != null:
        var mission: VBoxContainer = hangar_view.find_child("MissionControlHeading", true, false) as VBoxContainer
        var research_heading: VBoxContainer = hangar_view.find_child("ResearchLabHeading", true, false) as VBoxContainer
        _expect(mission != null and research_heading != null,
            "Hangar section titles stack vertically rather than sharing stretchable HBox rows")
        if mission != null and research_heading != null:
            for section in [mission, research_heading]:
                var heading: Label = section.find_child("SectionLabel", true, false) as Label
                var hairline: ColorRect = section.find_child("Hairline", true, false) as ColorRect
                _expect(heading != null and hairline != null,
                    "Each heading has a dedicated fixed-height divider")
                if heading != null and hairline != null:
                    _expect(heading.autowrap_mode == TextServer.AUTOWRAP_OFF
                        and hairline.custom_minimum_size.y <= 2.0
                        and hairline.size_flags_vertical == Control.SIZE_SHRINK_CENTER,
                        "Hangar headings cannot turn into vertical letters or huge blue blocks")
        _expect(hangar_view.find_child("PremiumBackdrop", true, false) == null
            and hangar_view.find_child("HangarMargins", true, false) != null,
            "Hangar uses one Guardian hero and content-driven portrait scrolling")
        var hero_art: TextureRect = hangar_view.find_child("HorizonArtwork", true, false) as TextureRect
        _expect(hero_art != null and hero_art.texture != null,
            "Hangar shows real Guardian/Horizon hero illustration")
        _expect(hangar_view.find_child("DeployNormal", true, false) != null and
            hangar_view.find_child("ResearchControls", true, false) != null and
            hangar_view.find_child("VisualFx", true, false) != null,
            "Deploy, research and graphics controls survive visual redesign")
        var progression: VBoxContainer = hangar_view.find_child("ProgressSummary", true, false) as VBoxContainer
        var balance_label: Label = hangar_view.find_child("AlloyBalance", true, false) as Label
        var stats_label: Label = hangar_view.find_child("ProgressStats", true, false) as Label
        _expect(progression != null and balance_label != null and stats_label != null,
            "Phase G progression uses a real vertically stacked panel")
        if balance_label != null and stats_label != null:
            _expect(balance_label.autowrap_mode == TextServer.AUTOWRAP_OFF
                and stats_label.autowrap_mode == TextServer.AUTOWRAP_OFF,
                "Alloy and run stats never collapse into vertical letters")
            _expect(balance_label.text.begins_with("ALLOY BANK") and
                stats_label.text.begins_with("RUNS"),
                "Balance and progress labels remain readable and complete")
        var build_label_visible := false
        for label_node in hangar_view.find_children("*", "Label", true, false):
            if String((label_node as Label).text) == "BUILD  " + GameCatalog.GAME_VERSION:
                build_label_visible = true
        _expect(GameCatalog.GAME_VERSION.begins_with("0.9.2") and build_label_visible,
            "Hangar footer displays current Phase G patch version")
    var deploy: Button
    if hangar_view != null:
        deploy = hangar_view.find_child("DeployNormal", true, false) as Button
        _expect(hangar_view.find_child("BackToTitle", true, false) != null,
            "HANGAR can return to tactical title without losing its real research actions")
    _expect(deploy != null, "Hangar retains real Normal deployment button")
    if deploy != null:
        deploy.pressed.emit()
        var live_arena: Arena = game.get("arena")
        _expect(live_arena.state == "running" and live_arena.stage == 1, "deployment opens Normal 1")
        var tactical: TacticalHud = game.get("hud") as TacticalHud
        _expect(tactical != null and tactical.visible, "tactical combat HUD is shown upon deployment")
        if tactical != null:
            _expect(tactical.find_child("WeaponSlots", true, false) != null and
                tactical.slot_labels.size() == 5, "five weapon ranks are displayed as status cards")
            _expect(tactical.find_child("Pause", true, false) != null and
                tactical.find_child("ThreatBanner", true, false) != null and
                tactical.find_child("EliteStrip", true, false) != null,
                "tactical HUD contains pause, real threat warnings and boss HP")
            tactical.apply_snapshot(live_arena.snapshot())
            _expect(tactical.slot_labels[0].text.contains("R4") and
                tactical.slot_labels[1].text.contains("R2"),
                "weapons show actual starting ranks, not invented mockup mechanics")
            _expect(not tactical.elite_panel.visible,
                "elite health strip hides without living elite")
            live_arena._spawn_enemy("elite", 350.0, 200.0)
            tactical.apply_snapshot(live_arena.snapshot())
            _expect(tactical.elite_panel.visible and tactical.elite_bar.max_value > 0.0,
                "elite health bar reads a real elite's max HP")
            live_arena.enemies.back()["hp"] = float(live_arena.enemies.back()["max_hp"]) * 0.25
            tactical.apply_snapshot(live_arena.snapshot())
            _expect(is_equal_approx(tactical.elite_bar.value / tactical.elite_bar.max_value, 0.25),
                "elite bar decreases with actual elite HP")
            live_arena.enemies.pop_back()
            tactical.apply_snapshot(live_arena.snapshot())
            _expect(not tactical.elite_panel.visible, "elite bar hides after elite is removed")
        live_arena.state = "upgrade"
        live_arena.levels["gun_payload"] = 2
        # LV12 has maxed gun; test with three eligible upgrades.
        var menu_offers: Array[String] = ["gun_payload", "gun_pierce", "gun_ricochet"]
        game.call("_choose_system", menu_offers)
        var ui_cards: Array[Node] = []
        var rank_label_found := false
        var active_menu: ColorRect = game.get("modal")
        var choice: EvolutionChoiceView = active_menu as EvolutionChoiceView
        _expect(choice != null, "Phase I.2 renders a dedicated native evolution screen")
        if choice != null:
            _expect(choice.find_child("EvolutionScroll", true, false) != null and
                choice.find_child("EvolutionMargins", true, false) != null,
                "evolution cards scroll within J8 safe margins")
            _expect(choice.find_child("EvolutionTitle", true, false) != null and
                choice.find_child("SynergySummary", true, false) != null,
                "choose-one heading and real synergy summary are present")
            var choose_header: Label = choice.find_child("EvolutionTitle", true, false) as Label
            _expect(choose_header != null and
                choose_header.get_theme_font_size("font_size") == 39,
                "approved CHOOSE ONE heading typography stays unchanged")
            _expect(choice.find_child("LevelAdvance", true, false) != null and
                choice.find_child("EvolutionFooter", true, false) != null,
                "upgrade menu identifies level progression and paused state")
        for node in active_menu.find_children("*", "Button", true, false):
            if node.has_meta("upgrade_key"):
                ui_cards.append(node)
                if String(node.get_meta("upgrade_key")) == "gun_payload":
                    for lbl in node.find_children("*", "Label", true, false):
                        if String(lbl.text).contains("OWNED 2/3") and String(lbl.text).contains("NEXT 3/3"):
                            rank_label_found = true
                    _expect(float(node.custom_minimum_size.y) >= 210.0, "larger evolution text has space inside each touch card")
                    var readable_name: Label = node.find_child("ChoiceName", true, false) as Label
                    var readable_body: Label = node.find_child("ChoiceDescription", true, false) as Label
                    var readable_rank: Label = node.find_child("ChoiceRank", true, false) as Label
                    _expect(readable_name != null and readable_body != null
                        and readable_rank != null and
                        readable_name.get_theme_font_size("font_size") >= 26 and
                        readable_body.get_theme_font_size("font_size") >= 20 and
                        readable_rank.get_theme_font_size("font_size") >= 18,
                        "J8 evolution cards enlarge the small fonts, not CHOOSE ONE")
                    _expect(node.find_child("UpgradeIcon", true, false) is UpgradeEmblem,
                        "upgrade option has real geometric icon instead of decorative screenshot")
                    _expect(node.find_child("ChoiceName", true, false) is Label and
                        node.find_child("ChoiceDescription", true, false) is Label and
                        node.find_child("ChoicePips", true, false) is Label,
                        "choice card exposes upgrade name, mechanic and rank pips")
                    var normal_style: StyleBoxFlat = node.get_theme_stylebox("normal") as StyleBoxFlat
                    _expect(normal_style != null and normal_style.border_width_left >= 6,
                        "evolution cards have distinct colored tactical edge")
        _expect(ui_cards.size() == 3 and rank_label_found, "system evolution shows correct owned-to-next rank")
        var selected_button: Button
        for button in ui_cards:
            if String(button.get_meta("upgrade_key")) == "gun_payload":
                selected_button = button as Button
        _expect(selected_button != null, "offered Kinetic Payload is selectable")
        if selected_button != null:
            selected_button.pressed.emit()
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
