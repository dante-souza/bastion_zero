class_name TacticalHud
extends Control

## Phase I.1: native J8 tactical overlay. Every field is from Arena.snapshot,
## which is emitted ~6.7 times per second; no new per-frame HUD render loop.
signal pause_requested

const ICE := Color("#E8FCFF")
const CYAN := Color("#5FEFFF")
const MINT := Color("#6BBD98")
const WARM := Color("#EFC187")
const THREAT := Color("#FF923D")
const ELITE := Color("#F44A60")
const MUTED := Color("#8CA8B9")
const SLOT_NAMES := ["SENTINEL", "PRISM", "COMET", "ARC", "NOVA"]
const SLOT_KEYS := ["gun", "beam", "volley", "arc", "nova"]
const SLOT_COLORS := [
    Color("#28D9FF"), VisualProfile.PRISM_BEAM,
    VisualProfile.COMET_BODY, VisualProfile.ARC_BOLT, VisualProfile.NOVA_FIELD
]

var stage_label: Label
var time_label: Label
var hull_label: Label
var warning_label: Label
var warning_panel: PanelContainer
var elite_panel: PanelContainer
var elite_label: Label
var elite_bar: ProgressBar
var xp_bar: ProgressBar
var xp_label: Label
var fps_label: Label
var slot_labels: Array[Label] = []


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _construct()


func _construct() -> void:
    var top := _frame(0.025, 0.975, HudProfile.TACTICAL_TOP_START,
        HudProfile.TACTICAL_TOP_END)
    top.name = "TacticalTop"
    add_child(top)
    var info_column := _column(3)
    top.add_child(info_column)
    var header := HBoxContainer.new()
    header.add_theme_constant_override("separation", 8)
    info_column.add_child(header)
    var title := _column(0)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title)
    stage_label = _label("STAGE 01 • NORMAL", 15, WARM)
    stage_label.name = "StageLabel"
    title.add_child(stage_label)
    time_label = _label("00:00 / 01:36", 27, CYAN)
    time_label.name = "Timer"
    title.add_child(time_label)

    var pause := Button.new()
    pause.name = "Pause"
    pause.text = "Ⅱ"
    pause.custom_minimum_size = HudProfile.PAUSE_SIZE
    pause.add_theme_font_size_override("font_size", 25)
    pause.add_theme_color_override("font_color", ICE)
    pause.add_theme_stylebox_override("normal", _style(Color("#0E2737"), Color("#3D799A"), 2))
    pause.add_theme_stylebox_override("hover", _style(Color("#14364B"), CYAN, 2))
    pause.add_theme_stylebox_override("pressed", _style(Color("#205475"), CYAN, 2))
    pause.pressed.connect(func() -> void: pause_requested.emit())
    header.add_child(pause)
    hull_label = _label("HULL 100/100 • LV 1 • 0 KILLS", 15, ICE)
    hull_label.name = "HullAndKills"
    info_column.add_child(hull_label)

    warning_panel = _frame(0.025, 0.975, HudProfile.TACTICAL_WARNING_START,
        HudProfile.TACTICAL_WARNING_END, Color("#21150B"), Color("#8C502B"))
    warning_panel.name = "ThreatBanner"
    warning_panel.visible = false
    add_child(warning_panel)
    warning_label = _label("INCOMING", 15, THREAT)
    warning_label.name = "ThreatText"
    warning_panel.add_child(warning_label)

    elite_panel = _frame(0.025, 0.975, HudProfile.TACTICAL_ELITE_START,
        HudProfile.TACTICAL_ELITE_END, Color("#160E17"), Color("#7A2F43"))
    elite_panel.name = "EliteStrip"
    elite_panel.visible = false
    add_child(elite_panel)
    var elite_row := HBoxContainer.new()
    elite_row.add_theme_constant_override("separation", 10)
    elite_panel.add_child(elite_row)
    elite_label = _label("ELITE", 13, ELITE)
    elite_label.name = "EliteName"
    elite_row.add_child(elite_label)
    elite_bar = _bar(ELITE, 8)
    elite_bar.name = "EliteHP"
    elite_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    elite_row.add_child(elite_bar)

    var tray := _frame(0.025, 0.975, HudProfile.TACTICAL_TRAY_START,
        HudProfile.TACTICAL_TRAY_END)
    tray.name = "WeaponTray"
    add_child(tray)
    var tray_stack := _column(5)
    tray.add_child(tray_stack)
    var xp_row := HBoxContainer.new()
    xp_row.add_theme_constant_override("separation", 7)
    tray_stack.add_child(xp_row)
    xp_label = _label("LV 1", 15, MINT)
    xp_label.name = "Level"
    xp_row.add_child(xp_label)
    xp_bar = _bar(MINT, 8)
    xp_bar.name = "XP"
    xp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    xp_row.add_child(xp_bar)
    fps_label = _label("FPS —", 12, MUTED)
    fps_label.name = "FPS"
    xp_row.add_child(fps_label)

    var slots := HBoxContainer.new()
    slots.name = "WeaponSlots"
    slots.add_theme_constant_override("separation", 5)
    tray_stack.add_child(slots)
    for i in range(SLOT_KEYS.size()):
        var card := PanelContainer.new()
        card.name = SLOT_KEYS[i].capitalize() + "Slot"
        card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        card.custom_minimum_size.y = 45
        card.mouse_filter = Control.MOUSE_FILTER_IGNORE
        card.add_theme_stylebox_override("panel",
            _style(Color("#071826"), SLOT_COLORS[i], 2))
        slots.add_child(card)
        var rank := _label("", 13, SLOT_COLORS[i])
        rank.name = "SlotRank"
        rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        rank.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        card.add_child(rank)
        slot_labels.append(rank)


func apply_snapshot(info: Dictionary) -> void:
    var stage: int = int(info.get("stage", 1))
    stage_label.text = "STAGE %02d • %s" % [stage, "ELITE" if stage == 2 else "NORMAL"]
    time_label.text = "%s  /  %s" % [
        GameCatalog.format_time(float(info.get("time", 0.0))),
        GameCatalog.format_time(float(info.get("duration", 0.0)))
    ]
    hull_label.text = "HULL %d/%d   •   LV %d   •   %d KILLS" % [
        ceili(float(info.get("hull", 0.0))), ceili(float(info.get("max_hull", 100.0))),
        int(info.get("level", 1)), int(info.get("kills", 0))
    ]
    var threats: int = int(info.get("enemies", 0))
    var event: String = String(info.get("event", ""))
    warning_panel.visible = threats > 0 or not event.is_empty()
    if not event.is_empty():
        warning_label.text = "ALERT  •  " + event
    else:
        warning_label.text = "INCOMING  •  %s  •  %d HOSTILES" % [
            String(info.get("formation", "LINE")), threats
        ]

    var maximum: float = float(info.get("elite_max_hp", 0.0))
    elite_panel.visible = maximum > 0.0
    if maximum > 0.0:
        var health: float = clampf(float(info.get("elite_hp", 0.0)), 0.0, maximum)
        elite_label.text = "ELITE  •  %d%%" % roundi(100.0 * health / maximum)
        elite_bar.max_value = maximum
        elite_bar.value = health

    xp_label.text = "LV %d" % int(info.get("level", 1))
    xp_bar.max_value = maxi(1, int(info.get("next_xp", 1)))
    xp_bar.value = clampi(int(info.get("xp", 0)), 0, int(xp_bar.max_value))
    fps_label.text = "FPS %d" % Engine.get_frames_per_second()
    var ranks: Dictionary = info.get("weapons", {})
    for i in range(SLOT_KEYS.size()):
        var rank: int = int(ranks.get(SLOT_KEYS[i], 0))
        slot_labels[i].text = "%s\n%s" % [SLOT_NAMES[i], "R%d" % rank if rank > 0 else "—"]
        slot_labels[i].modulate.a = 1.0 if rank > 0 else 0.38


func _frame(left: float, right: float, top: float, bottom: float,
        fill: Color = Color("#091927"), edge: Color = Color("#254052")) -> PanelContainer:
    var panel := PanelContainer.new()
    panel.mouse_filter = Control.MOUSE_FILTER_PASS
    panel.anchor_left = left
    panel.anchor_right = right
    panel.anchor_top = 1.0 if top < 0.0 else 0.0
    panel.anchor_bottom = 1.0 if bottom < 0.0 else 0.0
    panel.offset_top = top
    panel.offset_bottom = bottom
    panel.add_theme_stylebox_override("panel", _style(fill, edge, 1))
    return panel


func _column(gap: int) -> VBoxContainer:
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", gap)
    return column


func _style(fill: Color, edge: Color, border: int) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = fill
    s.border_color = edge
    s.set_border_width_all(border)
    s.set_corner_radius_all(7)
    s.content_margin_left = 10
    s.content_margin_right = 10
    s.content_margin_top = 5
    s.content_margin_bottom = 5
    return s


func _label(value: String, font: int, tint: Color) -> Label:
    var label := Label.new()
    label.text = value
    label.add_theme_font_size_override("font_size", font)
    label.add_theme_color_override("font_color", tint)
    label.autowrap_mode = TextServer.AUTOWRAP_OFF
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return label


func _bar(tint: Color, height: float) -> ProgressBar:
    var bar := ProgressBar.new()
    bar.show_percentage = false
    bar.custom_minimum_size.y = height
    bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    bar.add_theme_stylebox_override("background", _style(Color("#10212B"), Color.TRANSPARENT, 0))
    bar.add_theme_stylebox_override("fill", _style(tint, Color.TRANSPARENT, 0))
    return bar
