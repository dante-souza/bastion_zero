class_name TitleMenuView
extends ColorRect

## Phase I.3 native tactical landing page based on the user's reference:
## two-line title, hero Guardian/defense arc, dominant DEPLOY, real nav.
signal deploy_requested(stage: int)
signal hangar_requested
signal sectors_requested
signal settings_requested

const BG := Color("#020911")
const GOLD := Color("#EFC187")
const MINT := Color("#6BBD98")
const MUTED := Color("#8CA8B9")
const CYAN := Color("#5FEFFF")
const INK := Color("#DAEAF1")
const EDGE := Color("#263846")

var record: Dictionary = {}


func configure(saved: Dictionary) -> void:
    record = saved.duplicate(true)


func _ready() -> void:
    color = BG
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _build()


func _build() -> void:
    var scroll := ScrollContainer.new()
    scroll.name = "TitleScroll"
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    add_child(scroll)

    var safe := MarginContainer.new()
    safe.name = "TitleSafeMargins"
    safe.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    safe.add_theme_constant_override("margin_left", 30)
    safe.add_theme_constant_override("margin_right", 30)
    safe.add_theme_constant_override("margin_top", 26)
    safe.add_theme_constant_override("margin_bottom", 36)
    scroll.add_child(safe)

    var stack := VBoxContainer.new()
    stack.name = "TitleContent"
    stack.add_theme_constant_override("separation", 11)
    safe.add_child(stack)

    var sky := Control.new()
    sky.name = "QuietSky"
    sky.custom_minimum_size.y = 45
    sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stack.add_child(sky)

    var title := _text("BASTION", 65, GOLD, true)
    title.name = "BastionWordmark"
    stack.add_child(title)
    var subtitle := _text("Z E R O", 63, MINT, true)
    subtitle.name = "ZeroWordmark"
    stack.add_child(subtitle)
    stack.add_child(_text("D E F E N D   T H E   L I N E", 16, MUTED, true))

    var art := TitleHorizonArt.new()
    art.name = "TitleBattlefieldArt"
    stack.add_child(art)

    var best := _text("BEST STAGE  %d   •   %d RUNS" % [
        int(record.get("best_stage", 0)), int(record.get("runs", 0))], 15, MUTED, true)
    best.name = "BestProgress"
    stack.add_child(best)

    var deploy := _button("D E P L O Y", true, 78.0)
    deploy.name = "DeployPrimary"
    deploy.pressed.connect(func() -> void: deploy_requested.emit(1))
    stack.add_child(deploy)
    var mission_line := "NORMAL 01  •  PRESSURE SHOWCASE" if GameCatalog.STAGE_ONE_SHOWCASE else "NORMAL 01  •  FIRST DEFENSE"
    stack.add_child(_text(mission_line, 14, MUTED, true))

    var nav := HBoxContainer.new()
    nav.name = "TitleNavigation"
    nav.add_theme_constant_override("separation", 10)
    stack.add_child(nav)
    var hangar := _button("HANGAR", false, 67.0)
    hangar.name = "OpenHangar"
    hangar.pressed.connect(func() -> void: hangar_requested.emit())
    nav.add_child(hangar)
    var sectors := _button("SECTORS", false, 67.0)
    sectors.name = "OpenSectors"
    sectors.pressed.connect(func() -> void: sectors_requested.emit())
    nav.add_child(sectors)
    var settings := _button("SETTINGS", false, 67.0)
    settings.name = "OpenSettings"
    settings.pressed.connect(func() -> void: settings_requested.emit())
    nav.add_child(settings)

    stack.add_child(_text("OFFLINE  •  NO ADS  •  NO PURCHASES", 13, MINT, true))
    stack.add_child(_text("BUILD " + GameCatalog.GAME_VERSION, 12, MUTED, true))


func _button(caption: String, primary: bool, height: float) -> Button:
    var b := Button.new()
    b.text = caption
    b.custom_minimum_size.y = height
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.add_theme_font_size_override("font_size", 27 if primary else 17)
    b.add_theme_color_override("font_color", BG if primary else GOLD)
    b.add_theme_color_override("font_disabled_color", MUTED)
    for state in ["normal", "hover", "pressed", "disabled"]:
        var style := StyleBoxFlat.new()
        style.bg_color = MINT if primary else Color("#071722")
        if state == "hover" or state == "pressed":
            style.bg_color = style.bg_color.lightened(0.13)
        if state == "disabled":
            style.bg_color = BG
        style.border_color = MINT if primary else EDGE
        style.set_border_width_all(2)
        style.set_corner_radius_all(10)
        style.anti_aliasing = true
        style.content_margin_left = 5
        style.content_margin_right = 5
        b.add_theme_stylebox_override(state, style)
    return b


func _text(value: String, font_size: int, ink: Color, centered: bool = false) -> Label:
    var label := Label.new()
    label.text = value
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", ink)
    label.autowrap_mode = TextServer.AUTOWRAP_OFF
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    if centered:
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    return label
