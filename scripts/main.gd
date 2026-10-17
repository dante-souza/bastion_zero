extends Control

const CYAN := Color("#62e5ff")
const GOLD := Color("#ffc969")
const PALE := Color("#aebdd3")
var arena: Arena
var record: Dictionary
var hud: Control
var modal: ColorRect
var hud_title: Label
var hud_detail: Label
var xp_bar: ProgressBar

func _ready() -> void:
    # Fullscreen root must not swallow battlefield taps before _unhandled_input.
    # Child GUI buttons still receive events through their own mouse filters.
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
    if size.x > 0 and size.y > 0:
        arena.scale = size / GameCatalog.WORLD_SIZE

func _unhandled_input(event: InputEvent) -> void:
    if arena.state != "running":
        return
    var point := Vector2(-1, -1)
    if event is InputEventScreenTouch and event.pressed:
        point = event.position
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        point = event.position
    if point.x >= 0 and arena.scale.x > 0 and arena.scale.y > 0:
        arena.focus_at(point / arena.scale)
        get_viewport().set_input_as_handled()

func _build_hud() -> void:
    hud = Control.new()
    hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(hud)
    var top := _panel()
    top.anchor_left = 0.02
    top.anchor_right = 0.98
    top.offset_top = 12
    top.offset_bottom = 162
    hud.add_child(top)
    var content := VBoxContainer.new()
    top.add_child(content)
    var header := HBoxContainer.new()
    content.add_child(header)
    hud_title = _label("WAVE 1 / 8", 24, CYAN)
    hud_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(hud_title)
    var pause := _button("PAUSE", false)
    pause.custom_minimum_size = Vector2(115, 45)
    pause.pressed.connect(_pause)
    header.add_child(pause)
    hud_detail = _label("HULL 100  •  LV 1  •  0 KILLS", 18, GOLD)
    content.add_child(hud_detail)
    content.add_child(_label("TAP AN ENEMY TO FOCUS", 17, PALE))
    var bottom := _panel()
    bottom.anchor_left = 0.02
    bottom.anchor_right = 0.98
    bottom.anchor_top = 1
    bottom.anchor_bottom = 1
    bottom.offset_top = -125
    bottom.offset_bottom = -14
    hud.add_child(bottom)
    var stack := VBoxContainer.new()
    bottom.add_child(stack)
    stack.add_child(_label("CORE XP  •  UPGRADE ON LEVEL UP", 17, CYAN))
    xp_bar = ProgressBar.new()
    xp_bar.custom_minimum_size = Vector2(0, 18)
    xp_bar.show_percentage = false
    stack.add_child(xp_bar)
    hud.hide()

func _stats(info: Dictionary) -> void:
    hud_title.text = "WAVE %d/%d   •   %s" % [
        info["wave"], info["total_waves"], GameCatalog.format_time(float(info["time"]))
    ]
    hud_detail.text = "HULL %d/%d   •   LV %d   •   %d KILLS" % [
        ceili(float(info["hull"])), int(info["max_hull"]), info["level"], info["kills"]
    ]
    xp_bar.max_value = int(info["next_xp"])
    xp_bar.value = int(info["xp"])

func _hangar() -> void:
    arena.state = "idle"
    hud.hide()
    var content := _screen("BASTION ZERO", "HANGAR • ORIGINAL OFFLINE GAME")
    content.add_child(_label("Defend your reactor across eight waves. Focus enemies, unlock weapons and research permanent improvements.", 21, PALE, true))
    content.add_child(_label("ALLOY BANK  %d" % int(record["bank"]), 28, GOLD, true))
    content.add_child(_label("RUNS %d • WINS %d • BEST WAVE %d" % [
        record["runs"], record["wins"], record["best_wave"]
    ], 18, PALE, true))
    for kind in ["hull", "damage"]:
        var rank: int = int(record["meta"][kind])
        var cost: int = GameCatalog.meta_cost(kind, rank)
        var caption := "CORE HULL" if kind == "hull" else "WEAPON DAMAGE"
        caption += " %d/%d  •  " % [rank, GameCatalog.META_CAP]
        caption += "MAX" if cost == -1 else "%d ALLOY" % cost
        var button := _button(caption, false)
        button.disabled = cost < 0 or int(record["bank"]) < cost
        button.pressed.connect(_research.bind(kind))
        content.add_child(button)
    var deploy := _button("DEPLOY BASTION →", true)
    deploy.pressed.connect(_deploy)
    content.add_child(deploy)
    content.add_child(_label("NO ADS • NO IAP • v%s" % GameCatalog.GAME_VERSION, 17, PALE, true))

func _research(kind: String) -> void:
    if SaveData.buy_meta(record, kind):
        SaveData.write_game(record)
    _hangar()

func _deploy() -> void:
    _clear()
    hud.show()
    arena.begin_run(record["meta"])

func _pause() -> void:
    if arena.state != "running":
        return
    arena.toggle_pause()
    var content := _screen("MISSION PAUSED", "REACTOR STANDBY")
    var resume := _button("RESUME", true)
    resume.pressed.connect(_resume)
    content.add_child(resume)
    var retreat := _button("RETREAT WITHOUT REWARD", false)
    retreat.pressed.connect(_hangar)
    content.add_child(retreat)

func _resume() -> void:
    _clear()
    arena.toggle_pause()

func _choose_system(offers: Array[String]) -> void:
    var content := _screen("LEVEL UP", "CHOOSE ONE UPGRADE")
    for kind in offers:
        var rank: int = int(arena.levels[kind]) + 1
        var button := _button("%s • RANK %d\n%s" % [
            GameCatalog.upgrade_name(kind), rank,
            GameCatalog.upgrade_description(kind, rank)
        ], false)
        button.custom_minimum_size.y = 94
        button.pressed.connect(_apply_upgrade.bind(kind))
        content.add_child(button)
    content.add_child(_label("COMBOS: PULSE + MINES / RAIL + ARC / ARC + MINES", 16, GOLD, true))

func _apply_upgrade(kind: String) -> void:
    arena.choose_upgrade(kind)
    _clear()

func _results(win: bool, stats: Dictionary) -> void:
    record["bank"] = int(record["bank"]) + int(stats["reward"])
    record["runs"] = int(record["runs"]) + 1
    record["wins"] = int(record["wins"]) + (1 if win else 0)
    record["best_wave"] = maxi(int(record["best_wave"]), int(stats["wave"]))
    record["best_kills"] = maxi(int(record["best_kills"]), int(stats["kills"]))
    var saved_ok := SaveData.write_game(record)
    var content := _screen("VICTORY" if win else "DEFEAT", "AFTER-ACTION REPORT")
    content.add_child(_label("WAVE %d  •  LEVEL %d  •  %d KILLS" % [
        stats["wave"], stats["level"], stats["kills"]
    ], 23, CYAN, true))
    content.add_child(_label("%s SURVIVED" % GameCatalog.format_time(float(stats["time"])), 22, PALE, true))
    content.add_child(_label("+%d ALLOY" % stats["reward"], 30, GOLD, true))
    if not saved_ok:
        content.add_child(_label("SAVE ERROR: PROGRESS MAY BE LOST", 18, Color("#ff527f"), true))
    var replay := _button("RETRY MISSION", true)
    replay.pressed.connect(_deploy)
    content.add_child(replay)
    var back := _button("RETURN TO HANGAR", false)
    back.pressed.connect(_hangar)
    content.add_child(back)

func _clear() -> void:
    if is_instance_valid(modal):
        modal.queue_free()
        modal = null

func _screen(title: String, subheading: String) -> VBoxContainer:
    _clear()
    modal = ColorRect.new()
    modal.color = Color(0.016, 0.026, 0.058, 0.95)
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
    center.custom_minimum_size.y = 850
    scroll.add_child(center)
    var panel := _panel()
    panel.custom_minimum_size.x = 560
    center.add_child(panel)
    var body := VBoxContainer.new()
    body.add_theme_constant_override("separation", 16)
    panel.add_child(body)
    body.add_child(_label(title, 38, CYAN, true))
    body.add_child(_label(subheading, 18, GOLD, true))
    body.add_child(HSeparator.new())
    return body

func _panel() -> PanelContainer:
    var box := PanelContainer.new()
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#10223b")
    style.border_color = Color("#377e9c")
    style.set_border_width_all(2)
    style.set_corner_radius_all(15)
    style.content_margin_left = 18
    style.content_margin_right = 18
    style.content_margin_top = 16
    style.content_margin_bottom = 16
    box.add_theme_stylebox_override("panel", style)
    return box

func _button(caption: String, accent: bool) -> Button:
    var button := Button.new()
    button.text = caption
    button.custom_minimum_size.y = 66
    button.add_theme_font_size_override("font_size", 19)
    for variant in ["normal", "hover", "pressed", "disabled"]:
        var box := StyleBoxFlat.new()
        box.bg_color = Color("#125879") if accent else Color("#1b3352")
        if variant == "hover":
            box.bg_color = box.bg_color.lightened(0.18)
        if variant == "disabled":
            box.bg_color = Color("#131c2e")
        box.border_color = CYAN if accent else Color("#377e9c")
        box.set_border_width_all(2)
        box.set_corner_radius_all(9)
        box.content_margin_top = 12
        box.content_margin_bottom = 12
        box.content_margin_left = 12
        box.content_margin_right = 12
        button.add_theme_stylebox_override(variant, box)
    return button

func _label(caption: String, font_size: int, color: Color, center: bool = false) -> Label:
    var label := Label.new()
    label.text = caption
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    if center:
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    return label
