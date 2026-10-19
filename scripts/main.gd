extends Control

const CYAN := Color("#63eeff")
const GOLD := Color("#ffc96d")
const PALE := Color("#b7c8de")
const GREEN := Color("#8ef3b2")
const VIOLET := Color("#8C6BFF")
## Neon pass: menu panels let the animated backdrop show through.
const SCRIM := Color(0.01, 0.02, 0.06, 0.58)
const PANEL_FILL := Color(0.035, 0.08, 0.16, 0.86)
var arena: Arena
var record: Dictionary
var hud: TacticalHud
var modal: ColorRect
var transition: ScreenTransition
var current_stage := 1
var _last_back_frame := -1
## The first two sectors keep their original node names for tests and tools.
const SECTOR_BUTTON_NAMES := {1: "SectorNormal", 2: "SectorElite"}

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    record = SaveData.load_game()
    arena = Arena.new()
    add_child(arena)
    arena.stats_changed.connect(_stats)
    arena.upgrade_requested.connect(_choose_system)
    arena.run_completed.connect(_results)
    _build_hud()
    transition = ScreenTransition.new()
    add_child(transition)
    resized.connect(_resize_arena)
    _resize_arena()
    _title()

func _resize_arena() -> void:
    if size.x > 0.0 and size.y > 0.0:
        arena.scale = size / GameCatalog.WORLD_SIZE

## Phase I.6: Android back (and Esc on desktop) walks one screen back.
## quit_on_go_back is off, so the app only exits from the title screen.
func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_GO_BACK_REQUEST:
        go_back()


## Returns true when back was consumed; false means "at title, may quit".
func go_back() -> bool:
    # One back press = one step, even if a platform delivers it twice.
    var frame: int = Engine.get_process_frames()
    if frame == _last_back_frame:
        return true
    _last_back_frame = frame
    match arena.state:
        "running":
            _pause()
            return true
        "upgrade":
            return true  # a card must be chosen; back never skips it
        "paused":
            if modal is ThreatGuideView:
                (modal as ThreatGuideView).return_requested.emit()
            else:
                _resume()
            return true
    if modal is ThreatGuideView:
        (modal as ThreatGuideView).return_requested.emit()
        return true
    if modal is TitleMenuView:
        if not Engine.is_editor_hint() and OS.has_feature("mobile"):
            get_tree().quit()
        return false
    _title()
    return true


func _unhandled_input(event: InputEvent) -> void:
    # Android delivers back as a notification; Esc covers desktop testing only.
    if not OS.has_feature("android") and event.is_action_pressed("ui_cancel"):
        go_back()
        get_viewport().set_input_as_handled()
        return
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
    hud.overdrive_requested.connect(func() -> void: arena.trigger_overdrive())
    add_child(hud)
    hud.hide()


func _stats(info: Dictionary) -> void:
    hud.apply_snapshot(info)


## Every screen goes through here so it fades in the same way.
func _show(screen: ColorRect) -> void:
    modal = screen
    add_child(screen)
    transition.reveal(screen)


func _menu_backdrop() -> void:
    arena.show_menu_backdrop(bool(record.get("low_fx", true)))


func _title() -> void:
    hud.hide()
    record = SaveData.validated(record)
    _menu_backdrop()
    _clear()
    var title := TitleMenuView.new()
    title.configure(record)
    title.deploy_requested.connect(_deploy)
    title.hangar_requested.connect(_hangar)
    title.sectors_requested.connect(_sectors)
    title.settings_requested.connect(_settings)
    title.codex_requested.connect(_threat_guide)
    _show(title)


## Opens from title, or while paused without accidentally unpausing Arena.
func _threat_guide(from_pause: bool = false) -> void:
    if from_pause and arena.state != "paused":
        return
    _clear()
    var guide := ThreatGuideView.new()
    guide.name = "ThreatGuide"
    if from_pause:
        guide.return_requested.connect(_show_pause_menu)
    else:
        guide.return_requested.connect(_title)
    _show(guide)


func _sectors() -> void:
    _menu_backdrop()
    hud.hide()
    var content := _screen("SECTORS", "SELECT A MAP", true)
    if GameCatalog.PLAYTEST_TOOLS:
        var hard: bool = bool(record.get("hard_start", false))
        var toggle := _button("START: " + ("HARD  •  LV12 LOADOUT" if hard else "LEVEL 1  •  NORMAL") + "  •  CHANGE", hard)
        toggle.name = "SectorHardStart"
        toggle.pressed.connect(_toggle_hard_start)
        content.add_child(toggle)
    var unlocked: int = int(record.get("stage_unlocked", 1))
    for stage in range(1, SectorCatalog.count() + 1):
        var card := SectorCard.new()
        card.name = SECTOR_BUTTON_NAMES.get(stage, "Sector%d" % stage)
        card.setup(stage, SectorCatalog.is_open(stage, unlocked, GameCatalog.PLAYTEST_TOOLS),
            bool(record.get("low_fx", true)), "LOCKED — CLEAR " + GameCatalog.stage_name(stage - 1))
        card.pressed.connect(_deploy.bind(stage))
        content.add_child(card)
    var back := _button("RETURN TO TITLE", false)
    back.name = "SectorsBack"
    back.pressed.connect(_title)
    content.add_child(back)


func _toggle_hard_start() -> void:
    record["hard_start"] = not bool(record.get("hard_start", false))
    SaveData.write_game(record)
    _sectors()


func _settings() -> void:
    _menu_backdrop()
    hud.hide()
    var content := _screen("SETTINGS", "SYSTEM CONFIGURATION")
    var fx_label := "LOW (J8)" if bool(record.get("low_fx", true)) else "FULL"
    var fx := _button("VISUAL FX: " + fx_label + "  •  CHANGE", true)
    fx.name = "SettingsFx"
    fx.pressed.connect(_settings_toggle_fx)
    content.add_child(fx)
    if GameCatalog.PLAYTEST_TOOLS:
        var line_on: bool = bool(record.get("moving_line", false))
        var line_toggle := _button("MOVING LINE: " + ("ON" if line_on else "OFF") + "  •  PROTOTYPE  •  CHANGE", line_on)
        line_toggle.name = "SettingsMovingLine"
        line_toggle.pressed.connect(_settings_toggle_line)
        content.add_child(line_toggle)
        content.add_child(_label("Hostiles past the line push it down, kills push it up. At the core it drains hull. High line: faster fire and more XP. Low line: shorter range.", 15, PALE, true))
    content.add_child(_label("OFFLINE  •  NO ADS  •  NO PURCHASES", 17, GREEN, true))
    var back := _button("RETURN TO TITLE", false)
    back.name = "SettingsBack"
    back.pressed.connect(_title)
    content.add_child(back)


func _settings_toggle_line() -> void:
    record["moving_line"] = not bool(record.get("moving_line", false))
    SaveData.write_game(record)
    _settings()


func _settings_toggle_fx() -> void:
    record["low_fx"] = not bool(record.get("low_fx", true))
    SaveData.write_game(record)
    _settings()


func _hangar() -> void:
    hud.hide()
    record = SaveData.validated(record)
    _menu_backdrop()
    _clear()
    var hangar := HangarView.new()
    hangar.configure(record)
    hangar.deploy_requested.connect(_deploy)
    hangar.research_requested.connect(_research)
    hangar.fx_requested.connect(_toggle_fx)
    hangar.title_requested.connect(_title)
    _show(hangar)

func _research(kind: String) -> void:
    if SaveData.buy_meta(record, kind):
        SaveData.write_game(record)
    _hangar()

func _toggle_fx() -> void:
    record["low_fx"] = not bool(record["low_fx"])
    SaveData.write_game(record)
    _hangar()

func _deploy(selected_stage: int = 1) -> void:
    if not SectorCatalog.is_open(selected_stage, int(record["stage_unlocked"]), GameCatalog.PLAYTEST_TOOLS):
        return
    current_stage = selected_stage
    _clear()
    hud.show()
    arena.begin_run(record["meta"], current_stage, bool(record["low_fx"]),
        bool(record.get("hard_start", false)), bool(record.get("moving_line", false)))
    transition.deploy(SectorCatalog.get_map(current_stage))

func _pause() -> void:
    if arena.state != "running":
        return
    arena.toggle_pause()
    _show_pause_menu()


func _show_pause_menu() -> void:
    # Returning from the codex stays paused; only RESUME toggles state.
    if arena.state != "paused":
        return
    var content := _screen("MISSION PAUSED", GameCatalog.stage_name(current_stage))
    var resume := _button("RESUME", true)
    resume.pressed.connect(_resume)
    content.add_child(resume)
    var guide := _button("THREAT GUIDE", false)
    guide.name = "PauseThreatGuide"
    guide.pressed.connect(_threat_guide.bind(true))
    content.add_child(guide)
    var retreat := _button("ABANDON RUN (NO ALLOY)", false)
    retreat.pressed.connect(_title)
    content.add_child(retreat)

func _resume() -> void:
    _clear()
    arena.toggle_pause()

func _choose_system(offers: Array[String]) -> void:
    # Filter stale or capped offers before showing the paused tactical UI.
    var eligible: Array[String] = []
    for kind in offers:
        if not eligible.has(kind) and GameCatalog.upgrade_available(arena.levels, kind):
            eligible.append(kind)
    if eligible.is_empty():
        push_warning("System Evolution received no eligible upgrade cards.")
        return
    _clear()
    var choice := EvolutionChoiceView.new()
    choice.configure(eligible, arena.levels, arena.level)
    choice.upgrade_chosen.connect(_apply_upgrade)
    _show(choice)


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
    content.add_child(_label("OVERDRIVE: %d  •  FIRED %d" % [
        roundi(float(stats["damage"].get("overdrive", 0.0))), int(stats.get("overdrives", 0))], 18, PALE, true))
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
    var home := _button("RETURN TO TITLE", false)
    home.pressed.connect(_title)
    content.add_child(home)

func _clear() -> void:
    if is_instance_valid(modal):
        modal.queue_free()
        modal = null

func _screen(heading: String, subheading: String, tall: bool = false) -> VBoxContainer:
    _clear()
    var screen := ColorRect.new()
    screen.color = SCRIM
    screen.mouse_filter = Control.MOUSE_FILTER_STOP
    screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _show(screen)
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
    body.add_child(_neon_label(heading, 44 if tall else 38, CYAN))
    body.add_child(_label(subheading, 25 if tall else 20, GOLD, true))
    body.add_child(_neon_rule())
    return body

func _panel(compact: bool = false) -> PanelContainer:
    var p := PanelContainer.new()
    var style := StyleBoxFlat.new()
    style.bg_color = PANEL_FILL
    style.border_color = CYAN
    style.set_border_width_all(2)
    style.set_corner_radius_all(13)
    # One StyleBox shadow is the panel's neon bloom; no shader needed.
    style.shadow_color = Color(CYAN, 0.22)
    style.shadow_size = 16
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
        style.bg_color = Color(0.05, 0.36, 0.48, 0.92) if accent else Color(0.06, 0.13, 0.24, 0.88)
        if variant == "hover" or variant == "pressed":
            style.bg_color = style.bg_color.lightened(0.16)
        if variant == "disabled":
            style.bg_color = Color(0.05, 0.08, 0.14, 0.80)
        style.border_color = CYAN if accent else Color("#3f85a4")
        if variant == "disabled":
            style.border_color = Color("#24384d")
        style.set_border_width_all(2)
        style.set_corner_radius_all(8)
        if accent and variant != "disabled":
            style.shadow_color = Color(CYAN, 0.30)
            style.shadow_size = 8
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


## Neon heading: a soft same-hue outline reads as a glow on the dark scrim.
func _neon_label(caption: String, font_size: int, color: Color) -> Label:
    var l := _label(caption, font_size, color, true)
    l.add_theme_color_override("font_outline_color", Color(color, 0.28))
    l.add_theme_constant_override("outline_size", 10)
    return l


func _neon_rule() -> ColorRect:
    var rule := ColorRect.new()
    rule.custom_minimum_size.y = 2.0
    rule.color = Color(CYAN, 0.55)
    rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return rule
