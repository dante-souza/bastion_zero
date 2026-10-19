class_name SectorCard
extends Button

## Neon pass: a SECTORS list entry is a map card, with a live, cropped
## preview of the sector's own animated backdrop, its name, brief and rule.
## Still a single Button, so taps, disabled state and tests are unchanged.
const HEIGHT := 150.0
const PREVIEW_WIDTH := 210.0
const INK := Color("#E8F6FF")
const PALE := Color("#A9BDD6")
const LOCKED_INK := Color("#5D7088")

var preview: SectorBackdrop


func setup(stage: int, open: bool, reduced_fx: bool, locked_caption: String) -> void:
    var map: Dictionary = SectorCatalog.get_map(stage)
    var accent: Color = map.get("horizon_core", Color.WHITE)
    custom_minimum_size.y = HEIGHT
    clip_contents = true
    disabled = not open
    for variant in ["normal", "hover", "pressed", "disabled", "focus"]:
        var style := StyleBoxFlat.new()
        style.bg_color = Color(0.03, 0.07, 0.14, 0.90)
        style.border_color = Color(accent, 0.75)
        if variant == "hover" or variant == "pressed":
            style.bg_color = style.bg_color.lightened(0.10)
            style.border_color = accent
        if variant == "disabled":
            style.border_color = Color("#24384d")
        if variant == "focus":
            style.draw_center = false
        style.set_border_width_all(2)
        style.set_corner_radius_all(10)
        if open and variant != "focus":
            style.shadow_color = Color(accent, 0.16)
            style.shadow_size = 6
        add_theme_stylebox_override(variant, style)

    preview = SectorBackdrop.new()
    preview.name = "Preview"
    preview.configure(map, reduced_fx)
    preview.set_view(SectorBackdrop.PREVIEW_VIEW)
    preview.set_brightness(1.0 if open else 0.35)
    preview.position = Vector2(4, 4)
    preview.size = Vector2(PREVIEW_WIDTH, HEIGHT - 8.0)
    add_child(preview)

    var info := VBoxContainer.new()
    info.name = "Info"
    info.mouse_filter = Control.MOUSE_FILTER_IGNORE
    info.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    info.offset_left = PREVIEW_WIDTH + 18.0
    info.offset_right = -12.0
    info.offset_top = 10.0
    info.offset_bottom = -8.0
    info.add_theme_constant_override("separation", 1)
    add_child(info)
    info.add_child(_text(String(map["code"]), 14, accent if open else LOCKED_INK))
    info.add_child(_text(String(map["place"]), 25, INK if open else LOCKED_INK))
    var rule_label: String = String(map.get("rule_label", "NO FIELD RULE"))
    info.add_child(_text(rule_label, 13, Color(accent, 0.85) if open else LOCKED_INK))
    var brief := _text(locked_caption if not open else String(map["brief"]), 13, PALE if open else LOCKED_INK)
    brief.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    info.add_child(brief)


func _text(value: String, font_size: int, ink: Color) -> Label:
    var label := Label.new()
    label.text = value
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", ink)
    return label
