class_name ThreatGuideView
extends ColorRect

## Real offline threat/codex screen, based on user's "Threat language" panel.
## All meanings reflect existing Arena/EnemyRenderer/WeaponEffects behavior.
signal return_requested

const BG := Color("#020911")
const PANEL := Color("#091722")
const OUTLINE := Color("#1D3343")
const WARM := Color("#EFC187")
const INK := Color("#DEEAF3")
const MUTED := Color("#93A7B9")
const MINT := Color("#6BBD98")


func _ready() -> void:
    color = BG
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _build()


func _build() -> void:
    var scroller := ScrollContainer.new()
    scroller.name = "ThreatGuideScroll"
    scroller.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    add_child(scroller)

    var safe := MarginContainer.new()
    safe.name = "ThreatGuideSafeMargins"
    safe.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    for side in ["left", "right"]:
        safe.add_theme_constant_override("margin_" + side, 26)
    safe.add_theme_constant_override("margin_top", 50)
    safe.add_theme_constant_override("margin_bottom", 40)
    scroller.add_child(safe)

    var content := VBoxContainer.new()
    content.name = "ThreatGuideContent"
    content.add_theme_constant_override("separation", 16)
    safe.add_child(content)

    content.add_child(_label("THREAT LANGUAGE", 39, WARM))
    var intro := _label("Shape tells you what it is. Color tells you how to react.", 17, MUTED)
    intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    content.add_child(intro)
    var caution := _label("GREEN CIRCLES ARE HOSTILE — XP IS AWARDED AUTOMATICALLY.", 16, VisualProfile.GRUNT)
    caution.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    content.add_child(caution)

    for group in ["YOURS", "HOSTILE", "SIGNALS"]:
        var heading := _label(group, 18, MINT if group == "YOURS" else WARM)
        heading.name = group + "Heading"
        content.add_child(heading)
        var grid := GridContainer.new()
        grid.name = group + "Grid"
        grid.columns = 2
        grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        grid.add_theme_constant_override("h_separation", 10)
        grid.add_theme_constant_override("v_separation", 10)
        content.add_child(grid)
        for entry in ThreatLanguage.descriptions():
            if String(entry["group"]) == group:
                grid.add_child(_entry(entry))

    var back := Button.new()
    back.name = "ThreatGuideBack"
    back.text = "RETURN"
    back.custom_minimum_size.y = 63
    back.add_theme_font_size_override("font_size", 20)
    back.add_theme_color_override("font_color", INK)
    var box := StyleBoxFlat.new()
    box.bg_color = Color("#102B37")
    box.border_color = MINT
    box.set_border_width_all(2)
    box.set_corner_radius_all(9)
    back.add_theme_stylebox_override("normal", box)
    back.pressed.connect(func() -> void: return_requested.emit())
    content.add_child(back)
    content.add_child(_label("OFFLINE  •  NO ADS  •  NO PURCHASES", 14, MINT))


func _entry(entry: Dictionary) -> PanelContainer:
    var panel := PanelContainer.new()
    panel.name = String(entry["id"]).capitalize() + "Legend"
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.size_flags_stretch_ratio = 1.0
    panel.custom_minimum_size.y = 174
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var style := StyleBoxFlat.new()
    style.bg_color = PANEL
    style.border_color = OUTLINE
    style.set_border_width_all(1)
    style.set_corner_radius_all(10)
    style.content_margin_left = 9
    style.content_margin_right = 9
    style.content_margin_top = 9
    style.content_margin_bottom = 9
    panel.add_theme_stylebox_override("panel", style)

    var stack := VBoxContainer.new()
    stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stack.add_theme_constant_override("separation", 5)
    panel.add_child(stack)
    var head := HBoxContainer.new()
    head.mouse_filter = Control.MOUSE_FILTER_IGNORE
    head.add_theme_constant_override("separation", 7)
    stack.add_child(head)
    var symbol := ThreatGlyph.new()
    symbol.kind = String(entry["id"])
    symbol.tint = entry["color"]
    symbol.name = "ThreatSymbol"
    head.add_child(symbol)
    var name := _label(String(entry["title"]), 18, WARM)
    name.name = "LegendTitle"
    name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    head.add_child(name)
    var detail := _label(String(entry["desc"]), 16, MUTED)
    detail.name = "LegendDescription"
    detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(detail)
    return panel


func _label(value: String, font: int, tint: Color) -> Label:
    var label := Label.new()
    label.text = value
    label.add_theme_font_size_override("font_size", font)
    label.add_theme_color_override("font_color", tint)
    label.autowrap_mode = TextServer.AUTOWRAP_OFF
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return label
