extends Control

const CYAN := Color("#63eeff")
const GOLD := Color("#ffc96d")
const PALE := Color("#b7c8de")
const GREEN := Color("#8ef3b2")
var arena: Arena
var record: Dictionary
var hud: Control
var modal: ColorRect
var hud_title: Label
var hud_detail: Label
var hud_tools: Label
var hud_cue: Label
var xp_bar: ProgressBar
var current_stage := 1

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    record = SaveData.load_game()
    arena = Arena.new()
    add_child(arena)
    arena.stats_changed.connect(_stats)
    arena.upgrade_requested.connect(_choose_system)
    arena.run_completed.connect(_results)
    _build_hud()
    resized.connect(_resize_arena)
    _resize_arena()
    _hangar()

func _resize_arena() -> void:
    if size.x > 0.0 and size.y > 0.0:
        arena.scale = size / GameCatalog.WORLD_SIZE

func _unhandled_input(event: InputEvent) -> void:
    if arena.state != "running":
        return
    var location := Vector2(-1.0, -1.0)
    if event is InputEventScreenTouch and event.pressed:
        location = event.position
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        location = event.position
    if location.x >= 0.0 and arena.scale.x > 0.0 and arena.scale.y > 0.0:
        arena.focus_at(location / arena.scale)
        get_viewport().set_input_as_handled()

func _build_hud() -> void:
    hud = Control.new()
    hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(hud)
    var top := _panel()
    top.anchor_left = 0.02
    top.anchor_right = 0.98
    top.offset_top = 8
    top.offset_bottom = 158
    hud.add_child(top)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 6)
    top.add_child(stack)
    var title_row := HBoxContainer.new()
    stack.add_child(title_row)
    hud_title = _label("NORMAL 01 • 00:00", 23, CYAN)
    hud_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_row.add_child(hud_title)
    var pause_button := _button("II", false)
    pause_button.custom_minimum_size = Vector2(78, 43)
    pause_button.pressed.connect(_pause)
    title_row.add_child(pause_button)
    hud_detail = _label("HULL 100/100  •  LV 1", 18, GOLD)
    stack.add_child(hud_detail)
    hud_cue = _label("Tap a threat to prioritize it.", 17, PALE)
    stack.add_child(hud_cue)
    var bottom := _panel()
    bottom.anchor_left = 0.02
    bottom.anchor_right = 0.98
    bottom.anchor_top = 1.0
    bottom.anchor_bottom = 1.0
    bottom.offset_top = -122
    bottom.offset_bottom = -12
    hud.add_child(bottom)
    var bottom_stack := VBoxContainer.new()
    bottom_stack.add_theme_constant_override("separation", 4)
    bottom.add_child(bottom_stack)
    hud_tools = _label("PRISM • 0 KILLS • 0 FPS", 16, GREEN)
    bottom_stack.add_child(hud_tools)
    xp_bar = ProgressBar.new()
    xp_bar.custom_minimum_size = Vector2(0, 18)
    xp_bar.show_percentage = false
    bottom_stack.add_child(xp_bar)
    hud.hide()

func _stats(info: Dictionary) -> void:
    hud_title.text = "%s  •  %s / %s" % [
        info["stage_name"], GameCatalog.format_time(float(info["time"])),
        GameCatalog.format_time(float(info["duration"]))
    ]
    hud_detail.text = "HULL %d/%d   •   LEVEL %d   •   %d KILLS" % [
        ceili(float(info["hull"])), ceili(float(info["max_hull"])),
        int(info["level"]), int(info["kills"])
    ]
    var unlocked: Array[String] = []
    for key in GameCatalog.WEAPON_ORDER:
        if int(info["weapons"].get(key, 0)) > 0:
            unlocked.append(GameCatalog.upgrade_name(key))
    if bool(info.get("showcase", false)):
        hud_tools.text = "SHOWCASE • %d ACTIVE WEAPONS • FPS %d" % [
            unlocked.size(), Engine.get_frames_per_second()]
    else:
        hud_tools.text = " + ".join(unlocked) + "  •  FPS %d" % Engine.get_frames_per_second()
    var current_event: String = String(info.get("event", ""))
    hud_cue.text = current_event if not current_event.is_empty() else "FORMATION: %s  •  BREACHES: %d" % [
        String(info.get("formation", "LINE")), int(info.get("breaches", 0))
    ]
    xp_bar.max_value = int(info["next_xp"])
    xp_bar.value = int(info["xp"])

func _hangar() -> void:
    arena.state = "idle"
    hud.hide()
    record = SaveData.validated(record)
    var content := _screen("BASTION ZERO", "GUARDIAN HANGAR  •  M1R")
    content.add_child(_label("Hold the lower defense line. Build evolving weapon combinations and survive the enemy advance.", 20, PALE, true))
    content.add_child(_label(
        "NORMAL 01 QA SHOWCASE: START LEVEL 7 + ALL WEAPONS."
        if GameCatalog.STAGE_ONE_SHOWCASE else
        "STARTER: SENTINEL AUTOCANNON. Unlock Prism Beam from level-up cards.",
        16, GREEN, true))
    content.add_child(_label("TANKS: RESIST PRISM; COMET/NOVA HIT HARD. RUNNERS: WEAK TO ARC.", 15, GREEN, true))
    content.add_child(_label("ALLOY BANK: %d" % int(record["bank"]), 27, GOLD, true))
    content.add_child(_label("RUNS %d   •   WINS %d   •   BEST STAGE %d" % [
        record["runs"], record["wins"], record["best_stage"]
    ], 17, PALE, true))
    for stage in range(1, GameCatalog.TOTAL_STAGES + 1):
        var start := _button("DEPLOY  •  " + GameCatalog.stage_name(stage), true)
        start.disabled = stage > int(record["stage_unlocked"])
        start.pressed.connect(_deploy.bind(stage))
        content.add_child(start)
    for kind in ["hull", "damage"]:
        var rank: int = int(record["meta"][kind])
        var cost: int = GameCatalog.meta_cost(kind, rank)
        var label_text := "HULL RESEARCH" if kind == "hull" else "WEAPON DAMAGE"
        label_text += "  %d/%d  •  " % [rank, GameCatalog.META_CAP]
        label_text += "MAX" if cost < 0 else "%d ALLOY" % cost
        var research := _button(label_text, false)
        research.disabled = cost < 0 or int(record["bank"]) < cost
        research.pressed.connect(_research.bind(kind))
        content.add_child(research)
    var fx := _button("VISUAL FX: LOW (J8)" if bool(record["low_fx"]) else "VISUAL FX: FULL", false)
    fx.pressed.connect(_toggle_fx)
    content.add_child(fx)
    content.add_child(_label("OFFLINE • NO ADS • NO PURCHASES • v%s" % GameCatalog.GAME_VERSION, 16, GREEN, true))

func _research(kind: String) -> void:
    if SaveData.buy_meta(record, kind):
        SaveData.write_game(record)
    _hangar()

func _toggle_fx() -> void:
    record["low_fx"] = not bool(record["low_fx"])
    SaveData.write_game(record)
    _hangar()

func _deploy(selected_stage: int = 1) -> void:
    if selected_stage > int(record["stage_unlocked"]):
        return
    current_stage = selected_stage
    _clear()
    hud.show()
    arena.begin_run(record["meta"], current_stage, bool(record["low_fx"]),
        GameCatalog.STAGE_ONE_SHOWCASE and current_stage == 1)

func _pause() -> void:
    if arena.state != "running":
        return
    arena.toggle_pause()
    var content := _screen("MISSION PAUSED", GameCatalog.stage_name(current_stage))
    var resume := _button("RESUME", true)
    resume.pressed.connect(_resume)
    content.add_child(resume)
    var retreat := _button("ABANDON RUN (NO ALLOY)", false)
    retreat.pressed.connect(_hangar)
    content.add_child(retreat)

func _resume() -> void:
    _clear()
    arena.toggle_pause()

func _choose_system(offers: Array[String]) -> void:
    # The catalog is authoritative. The UI also filters stale offerings,
    # making it impossible to display an already-maxed upgrade card.
    var eligible: Array[String] = []
    for kind in offers:
        if not eligible.has(kind) and GameCatalog.upgrade_available(arena.levels, kind):
            eligible.append(kind)
    if eligible.is_empty():
        push_warning("System Evolution received no eligible upgrade cards.")
        return
    var content := _screen("SYSTEM EVOLUTION", "LEVEL %d  •  CHOOSE ONE" % arena.level, true)
    content.add_child(_label("Choose your next tactical evolution.", 21, PALE, true))
    for kind in eligible:
        var card := _upgrade_card(kind, int(arena.levels.get(kind, 0)))
        card.pressed.connect(_apply_upgrade.bind(kind))
        content.add_child(card)
    var spacer := Control.new()
    spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content.add_child(spacer)
    content.add_child(_label("SYNERGIES: PRISM + ARC   /   COMET + NOVA", 19, GOLD, true))

func _upgrade_card(kind: String, current_rank: int) -> Button:
    var cap: int = GameCatalog.upgrade_cap(kind)
    var next_rank: int = current_rank + 1
    var card := _button("", false)
    card.custom_minimum_size.y = 192.0
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    card.set_meta("upgrade_key", kind)
    card.tooltip_text = GameCatalog.upgrade_description(kind, next_rank)

    # A transparent, non-intercepting content layer gives us individual
    # typography control without sacrificing the entire clickable card.
    var padding := MarginContainer.new()
    padding.mouse_filter = Control.MOUSE_FILTER_IGNORE
    padding.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for side in ["left", "right"]:
        padding.add_theme_constant_override("margin_" + side, 19)
    for side in ["top", "bottom"]:
        padding.add_theme_constant_override("margin_" + side, 13)
    card.add_child(padding)

    var text_stack := VBoxContainer.new()
    text_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
    text_stack.add_theme_constant_override("separation", 4)
    padding.add_child(text_stack)

    var category := _label("[" + GameCatalog.upgrade_category(kind, current_rank) + "]", 18, GREEN)
    category.mouse_filter = Control.MOUSE_FILTER_IGNORE
    text_stack.add_child(category)

    var title_text := _label(GameCatalog.upgrade_name(kind), 28, CYAN)
    title_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
    text_stack.add_child(title_text)

    # 3/3 on an offered card is the NEXT (final) rank, not the current rank.
    var progress := "OWNED %d/%d  →  NEXT %d/%d" % [
        current_rank, cap, next_rank, cap
    ]
    if next_rank == cap:
        progress += "  (FINAL)"
    var rank_text := _label(progress, 18, GOLD)
    rank_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
    text_stack.add_child(rank_text)

    var description := _label(GameCatalog.upgrade_description(kind, next_rank), 21, PALE)
    description.mouse_filter = Control.MOUSE_FILTER_IGNORE
    text_stack.add_child(description)
    return card

func _apply_upgrade(kind: String) -> void:
    if arena.state != "upgrade" or not GameCatalog.upgrade_available(arena.levels, kind):
        push_warning("Stale or max-rank upgrade rejected: " + kind)
        return
    arena.choose_upgrade(kind)
    _clear()

func _results(victory: bool, stats: Dictionary) -> void:
    SaveData.record_run(record, current_stage, victory, stats)
    var saved_ok: bool = SaveData.write_game(record)
    hud.hide()
    var content := _screen("STAGE CLEARED" if victory else "DEFENSE BREACHED", GameCatalog.stage_name(current_stage))
    content.add_child(_label("%s SURVIVED   •   %d KILLS   •   LEVEL %d" % [
        GameCatalog.format_time(float(stats["time"])), int(stats["kills"]), int(stats["level"])
    ], 20, PALE, true))
    content.add_child(_label("+%d ALLOY" % int(stats["reward"]), 31, GOLD, true))
    content.add_child(_label("BREACHES: %d  •  FORMATIONS: %d" % [
        int(stats.get("breaches", 0)), int(stats.get("formations", 0))
    ], 17, PALE, true))
    content.add_child(_label("DAMAGE BY WEAPON", 22, CYAN, true))
    for key in GameCatalog.WEAPON_ORDER:
        var dmg: float = float(stats["damage"].get(key, 0.0))
        content.add_child(_label("%s: %d" % [GameCatalog.upgrade_name(key), roundi(dmg)], 18, PALE, true))
    if victory and current_stage < GameCatalog.TOTAL_STAGES:
        content.add_child(_label("NEXT STAGE UNLOCKED!", 21, GREEN, true))
        var next := _button("DEPLOY NEXT STAGE", true)
        next.pressed.connect(_deploy.bind(current_stage + 1))
        content.add_child(next)
    if not saved_ok:
        content.add_child(_label("SAVE FAILED: PROGRESS MAY BE LOST", 17, Color("#ff6689"), true))
    var replay := _button("RETRY THIS STAGE", true)
    replay.pressed.connect(_deploy.bind(current_stage))
    content.add_child(replay)
    var home := _button("RETURN TO HANGAR", false)
    home.pressed.connect(_hangar)
    content.add_child(home)

func _clear() -> void:
    if is_instance_valid(modal):
        modal.queue_free()
        modal = null

func _screen(heading: String, subheading: String, tall: bool = false) -> VBoxContainer:
    _clear()
    modal = ColorRect.new()
    modal.color = Color(0.015, 0.025, 0.05, 0.96)
    modal.mouse_filter = Control.MOUSE_FILTER_STOP
    modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(modal)
    var scroll := ScrollContainer.new()
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    modal.add_child(scroll)
    var center := CenterContainer.new()
    center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    center.size_flags_vertical = Control.SIZE_EXPAND_FILL
    center.custom_minimum_size.y = 1240.0 if tall else 1090.0
    scroll.add_child(center)
    var panel := _panel()
    panel.custom_minimum_size.x = 620.0 if tall else 564.0
    if tall:
        panel.custom_minimum_size.y = 1080.0
    center.add_child(panel)
    var body := VBoxContainer.new()
    body.add_theme_constant_override("separation", 19 if tall else 15)
    panel.add_child(body)
    body.add_child(_label(heading, 44 if tall else 38, CYAN, true))
    body.add_child(_label(subheading, 25 if tall else 20, GOLD, true))
    body.add_child(HSeparator.new())
    return body

func _panel() -> PanelContainer:
    var p := PanelContainer.new()
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#122940")
    style.border_color = Color("#367b9b")
    style.set_border_width_all(2)
    style.set_corner_radius_all(13)
    style.content_margin_left = 18
    style.content_margin_right = 18
    style.content_margin_top = 15
    style.content_margin_bottom = 15
    p.add_theme_stylebox_override("panel", style)
    return p

func _button(caption: String, accent: bool) -> Button:
    var b := Button.new()
    b.text = caption
    b.custom_minimum_size.y = 65
    b.add_theme_font_size_override("font_size", 19)
    for variant in ["normal", "hover", "pressed", "disabled"]:
        var style := StyleBoxFlat.new()
        style.bg_color = Color("#146884") if accent else Color("#1b3653")
        if variant == "hover" or variant == "pressed":
            style.bg_color = style.bg_color.lightened(0.16)
        if variant == "disabled":
            style.bg_color = Color("#142033")
        style.border_color = CYAN if accent else Color("#3f85a4")
        style.set_border_width_all(2)
        style.set_corner_radius_all(8)
        style.content_margin_top = 10
        style.content_margin_bottom = 10
        style.content_margin_left = 12
        style.content_margin_right = 12
        b.add_theme_stylebox_override(variant, style)
    return b

func _label(caption: String, font_size: int, color: Color, center: bool = false) -> Label:
    var l := Label.new()
    l.text = caption
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.add_theme_font_size_override("font_size", font_size)
    l.add_theme_color_override("font_color", color)
    if center:
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    return l
