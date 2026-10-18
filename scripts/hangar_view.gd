class_name HangarView
extends ColorRect

## Phase G — The Last Horizon. Native Godot controls and a reused Guardian
## illustration. The existing Main script remains owner of gameplay and saves.
signal deploy_requested(stage: int)
signal research_requested(kind: String)
signal fx_requested

const HERO: Texture2D = preload("res://assets/branding/last_horizon_hero.svg")
## These high-fidelity, user-approved image assets are optional until the
## accompanying Phase H bundle is imported and committed. The legacy art
## remains a valid offline fallback (so CI and source checkouts still work).
const PREMIUM_HERO_PATH := "res://assets/branding/premium_hangar_hero.webp"
const PREMIUM_BACKGROUND_PATH := "res://assets/branding/premium_hangar_background.webp"

static func branded_hero_path() -> String:
    return PREMIUM_HERO_PATH if ResourceLoader.exists(PREMIUM_HERO_PATH) else "res://assets/branding/last_horizon_hero.svg"

const CYAN := Color("#65E9FF")
const PALE := Color("#B7C8DE")
const GOLD := Color("#FFC96D")
const GREEN := Color("#8EF3B2")
const PANEL := Color("#081B32")
const BORDER := Color("#2675AF")
const SECONDARY := Color("#7299C5")

var record: Dictionary = {}

func configure(saved_record: Dictionary) -> void:
    record = saved_record.duplicate(true)


func _ready() -> void:
    color = Color("#020814")
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    if ResourceLoader.exists(PREMIUM_BACKGROUND_PATH):
        var bg := TextureRect.new()
        bg.name = "PremiumBackdrop"
        bg.texture = load(PREMIUM_BACKGROUND_PATH) as Texture2D
        bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        bg.modulate.a = 0.23
        bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(bg)
    _build()


func _build() -> void:
    var scroll := ScrollContainer.new()
    scroll.name = "HangarScroll"
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    add_child(scroll)

    var centered := CenterContainer.new()
    centered.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    centered.custom_minimum_size = Vector2(720.0, 1220.0)
    scroll.add_child(centered)

    var margin := MarginContainer.new()
    margin.custom_minimum_size.x = 666.0
    margin.add_theme_constant_override("margin_left", 8)
    margin.add_theme_constant_override("margin_right", 8)
    margin.add_theme_constant_override("margin_top", 15)
    margin.add_theme_constant_override("margin_bottom", 15)
    centered.add_child(margin)

    var stack := VBoxContainer.new()
    stack.name = "HangarContent"
    stack.add_theme_constant_override("separation", 11)
    margin.add_child(stack)

    var header := _text("BASTION ZERO", 44, CYAN, true)
    header.name = "HangarTitle"
    stack.add_child(header)
    stack.add_child(_text("THE LAST HORIZON  •  GUARDIAN COMMAND", 16, PALE, true))
    stack.add_child(_rule(CYAN))

    var hero := PanelContainer.new()
    hero.name = "HorizonHero"
    hero.clip_contents = true
    var hero_style := _style(PANEL, BORDER)
    hero_style.content_margin_left = 0
    hero_style.content_margin_right = 0
    hero_style.content_margin_top = 0
    hero_style.content_margin_bottom = 0
    hero.add_theme_stylebox_override("panel", hero_style)
    stack.add_child(hero)
    var art := TextureRect.new()
    art.name = "HorizonArtwork"
    art.texture = load(branded_hero_path()) as Texture2D
    art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    art.custom_minimum_size = Vector2(620, 342)
    art.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hero.add_child(art)

    stack.add_child(_text("HOLD THE LAST DEFENSIVE LINE", 18, PALE, true))
    var showcase_title: String = "PRESSURE TEST • LV12 • FIVE WEAPONS ONLINE" if GameCatalog.STAGE_ONE_SHOWCASE else "SENTINEL AUTOCANNON • BUILD YOUR DEFENSE"
    stack.add_child(_text(showcase_title, 15, PALE, true))

    stack.add_child(_section("MISSION CONTROL"))
    var normal := _button("DEPLOY • NORMAL 01    ›", true, 72.0)
    normal.name = "DeployNormal"
    normal.pressed.connect(func() -> void: deploy_requested.emit(1))
    stack.add_child(normal)

    var elite := _button("DEPLOY • ELITE 01", false, 60.0)
    elite.name = "DeployElite"
    elite.disabled = int(record.get("stage_unlocked", 1)) < 2
    if elite.disabled:
        elite.text = "ELITE 01 • LOCKED — CLEAR NORMAL 01"
    elite.pressed.connect(func() -> void: deploy_requested.emit(2))
    stack.add_child(elite)

    # Dedicated vertically stacked balance/stat lines. The old HBox let
    # RUNS/WINS expand and compressed "ALLOY 0" into a one-letter column.
    var progress := VBoxContainer.new()
    progress.name = "ProgressSummary"
    progress.add_theme_constant_override("separation", 5)
    stack.add_child(progress)
    var balance := _text("ALLOY BANK  •  %d" % int(record.get("bank", 0)), 23, GOLD)
    balance.name = "AlloyBalance"
    balance.autowrap_mode = TextServer.AUTOWRAP_OFF
    progress.add_child(balance)
    var stats := _text("RUNS %d   •   WINS %d   •   BEST STAGE %d" % [
        int(record.get("runs", 0)), int(record.get("wins", 0)),
        int(record.get("best_stage", 0))], 16, PALE)
    stats.name = "ProgressStats"
    stats.autowrap_mode = TextServer.AUTOWRAP_OFF
    progress.add_child(stats)

    stack.add_child(_section("RESEARCH LAB"))
    var research := HBoxContainer.new()
    research.name = "ResearchControls"
    research.add_theme_constant_override("separation", 9)
    stack.add_child(research)
    for kind in ["hull", "damage"]:
        var rank: int = int(record["meta"][kind])
        var cost: int = GameCatalog.meta_cost(kind, rank)
        var label: String = "HULL" if kind == "hull" else "DAMAGE"
        var cost_label: String = "MAX" if cost < 0 else "%d ALLOY" % cost
        var btn := _button("%s  %d/%d\n%s" % [
            label, rank, GameCatalog.META_CAP, cost_label], false, 71.0)
        btn.name = "Research" + kind.capitalize()
        btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        btn.disabled = cost < 0 or int(record.get("bank", 0)) < cost
        btn.pressed.connect(_request_research.bind(kind))
        research.add_child(btn)

    var settings := _button(
        "SYSTEMS  •  VISUAL FX: LOW (J8)" if bool(record.get("low_fx", true)) else
        "SYSTEMS  •  VISUAL FX: FULL",
        false, 54.0)
    settings.name = "VisualFx"
    settings.pressed.connect(func() -> void: fx_requested.emit())
    stack.add_child(settings)

    stack.add_child(_rule(BORDER))
    stack.add_child(_text("OFFLINE   •   NO ADS   •   NO PURCHASES", 15, GREEN, true))
    stack.add_child(_text("BUILD  %s" % GameCatalog.GAME_VERSION, 13, PALE, true))


func _section(title: String) -> HBoxContainer:
    var row := HBoxContainer.new()
    row.name = "MissionControlHeading" if title == "MISSION CONTROL" else "ResearchLabHeading"
    row.add_theme_constant_override("separation", 10)
    var name_label := _text(title, 18, CYAN)
    row.add_child(name_label)
    var rule := _rule(BORDER)
    rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(rule)
    return row


func _rule(tint: Color) -> ColorRect:
    var line := ColorRect.new()
    line.color = Color(tint.r, tint.g, tint.b, 0.48)
    line.custom_minimum_size.y = 1
    line.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return line


func _text(value: String, size: int, tint: Color, centered: bool = false) -> Label:
    var label := Label.new()
    label.text = value
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", tint)
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    if centered:
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    return label


func _button(value: String, primary: bool, height: float) -> Button:
    var button := Button.new()
    button.text = value
    button.custom_minimum_size.y = height
    button.add_theme_font_size_override("font_size", 22 if primary else 17)
    button.add_theme_color_override("font_color", Color("#E9F9FF") if primary else PALE)
    button.add_theme_color_override("font_hover_color", Color.WHITE)
    for state in ["normal", "hover", "pressed", "disabled"]:
        var bg := Color("#104A77") if primary else Color("#071A2D")
        if state == "hover":
            bg = bg.lightened(0.14)
        if state == "pressed":
            bg = bg.lightened(0.22)
        if state == "disabled":
            bg = Color("#071321")
        var line := CYAN if primary else SECONDARY
        if state == "disabled":
            line = Color("#355174")
        var style := _style(bg, line)
        style.set_corner_radius_all(7)
        style.border_width_top = 2
        style.border_width_bottom = 2
        style.border_width_left = 5 if primary else 2
        style.border_width_right = 3 if primary else 2
        style.shadow_color = Color(0.02, 0.61, 1.0, 0.28 if primary else 0.10)
        style.shadow_size = 5 if primary else 2
        style.anti_aliasing = true
        button.add_theme_stylebox_override(state, style)
    return button


func _style(fill: Color, line: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = line
    style.set_border_width_all(2)
    style.set_corner_radius_all(9)
    style.anti_aliasing = true
    style.content_margin_left = 11
    style.content_margin_right = 11
    style.content_margin_top = 7
    style.content_margin_bottom = 7
    return style


func _request_research(kind: String) -> void:
    research_requested.emit(kind)
