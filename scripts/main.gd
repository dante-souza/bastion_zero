extends Control

const CYAN := Color("#63eeff")
const GOLD := Color("#ffc96d")
const PALE := Color("#b7c8de")
const GREEN := Color("#8ef3b2")
var arena: Arena
var record: Dictionary
var hud: TacticalHud
var modal: ColorRect
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
    hud = TacticalHud.new()
    hud.pause_requested.connect(_pause)
    add_child(hud)
    hud.hide()


func _stats(info: Dictionary) -> void:
    hud.apply_snapshot(info)


func _hangar() -> void:
    arena.state = "idle"
    hud.hide()
    record = SaveData.validated(record)
    _clear()
    var hangar := HangarView.new()
    hangar.configure(record)
    hangar.deploy_requested.connect(_deploy)
    hangar.research_requested.connect(_research)
    hangar.fx_requested.connect(_toggle_fx)
    modal = hangar
    add_child(hangar)

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
    var content := _screen("SYSTEM EVOLUTION",
        "LV %d   •   %d THREATS   •   %d KILLS" % [
            arena.level, arena.enemies.size(), arena.kills], true)
    content.add_child(_label("SELECT ONE UPGRADE • THE BATTLE IS PAUSED", 18, PALE, true))
    for kind in eligible:
        var card := _upgrade_card(kind, int(arena.levels.get(kind, 0)))
        card.pressed.connect(_apply_upgrade.bind(kind))
        content.add_child(card)
    var spacer := Control.new()
    spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content.add_child(spacer)
    content.add_child(_label(EvolutionProfile.synergy_summary(arena.levels), 18, GREEN, true))

func _upgrade_card(kind: String, current_rank: int) -> Button:
    var cap: int = GameCatalog.upgrade_cap(kind)
    var next_rank: int = current_rank + 1
    var card := _button("", false)
    card.custom_minimum_size.y = 186.0
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var accent: Color = EvolutionProfile.accent(kind)
    for variant in ["normal", "hover", "pressed"]:
        var card_style := StyleBoxFlat.new()
        card_style.bg_color = Color("#10263C") if variant == "normal" else Color("#1A3B55")
        card_style.border_color = accent
        card_style.border_width_left = 6
        card_style.border_width_right = 2
        card_style.border_width_top = 2
        card_style.border_width_bottom = 2
        card_style.set_corner_radius_all(9)
        card_style.content_margin_left = 12
        card_style.content_margin_right = 12
        card_style.content_margin_top = 7
        card_style.content_margin_bottom = 7
        card.add_theme_stylebox_override(variant, card_style)
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

    var category := _label(
        GameCatalog.upgrade_category(kind, current_rank) + "   •   " + EvolutionProfile.tactical_role(kind),
        15, accent)
    category.mouse_filter = Control.MOUSE_FILTER_IGNORE
    text_stack.add_child(category)

    var title_text := _label(GameCatalog.upgrade_name(kind), 27, CYAN)
    title_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
    text_stack.add_child(title_text)

    # 3/3 on an offered card is the NEXT (final) rank, not the current rank.
    var progress := "OWNED %d/%d  →  NEXT %d/%d" % [
        current_rank, cap, next_rank, cap
    ]
    if next_rank == cap:
        progress += "  (FINAL)"
    progress += "    " + EvolutionProfile.rank_marks(next_rank, cap)
    var rank_text := _label(progress, 17, GOLD)
    rank_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
    text_stack.add_child(rank_text)

    var description := _label(GameCatalog.upgrade_description(kind, next_rank), 19, PALE)
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

func _panel(compact: bool = false) -> PanelContainer:
    var p := PanelContainer.new()
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#122940")
    style.border_color = Color("#367b9b")
    style.set_border_width_all(2)
    style.set_corner_radius_all(13)
    style.content_margin_left = HudProfile.HUD_MARGIN_HORIZONTAL if compact else 18
    style.content_margin_right = HudProfile.HUD_MARGIN_HORIZONTAL if compact else 18
    style.content_margin_top = HudProfile.HUD_MARGIN_VERTICAL if compact else 15
    style.content_margin_bottom = HudProfile.HUD_MARGIN_VERTICAL if compact else 15
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
