class_name ScreenTransition
extends CanvasLayer

## Neon pass: smooth screen changes. Screens are still swapped synchronously
## (tests and the back button see the new screen at once); this layer only
## animates how they appear. Every piece ignores input, so a tap mid-fade
## lands on the new screen, never on the transition.
const REVEAL_SECONDS := 0.22
const REVEAL_RISE := 18.0
const DEPLOY_SECONDS := 0.55
const CARD_HOLD := 1.1
const INK := Color("#E8F6FF")
const CYAN := Color("#5FEFFF")
const VIOLET := Color("#9C84FF")
const PANEL := Color(0.02, 0.05, 0.12, 0.82)

var _veil: ColorRect
var _scan: ColorRect
var _card: PanelContainer
var _card_code: Label
var _card_place: Label
var _card_rule: Label


func _init() -> void:
    name = "ScreenTransition"
    layer = 20


func _ready() -> void:
    _veil = ColorRect.new()
    _veil.name = "Veil"
    _veil.color = Color(0.0, 0.01, 0.03, 0.0)
    _veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(_veil)
    _scan = ColorRect.new()
    _scan.name = "ScanLine"
    _scan.color = Color(CYAN, 0.0)
    _scan.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _scan.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    _scan.offset_bottom = 3.0
    add_child(_scan)
    _build_card()


## Fades a freshly added screen in and lifts it into place.
func reveal(screen: Control) -> void:
    if screen == null:
        return
    screen.modulate.a = 0.0
    var rest_y: float = screen.position.y
    screen.position.y = rest_y + REVEAL_RISE
    var tween := screen.create_tween().set_parallel(true)
    tween.tween_property(screen, "modulate:a", 1.0, REVEAL_SECONDS) \
        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    tween.tween_property(screen, "position:y", rest_y, REVEAL_SECONDS) \
        .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## Deploy: the field fades up from black behind a neon scan line while a
## mission card names the sector and its field rule, then slides away.
func deploy(map: Dictionary) -> void:
    var height: float = get_viewport().get_visible_rect().size.y
    _veil.color.a = 1.0
    var veil := create_tween()
    veil.tween_property(_veil, "color:a", 0.0, DEPLOY_SECONDS) \
        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
    _scan.color.a = 0.9
    _scan.position.y = 0.0
    var scan := create_tween().set_parallel(true)
    scan.tween_property(_scan, "position:y", height, DEPLOY_SECONDS) \
        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
    scan.tween_property(_scan, "color:a", 0.0, DEPLOY_SECONDS).set_delay(DEPLOY_SECONDS * 0.4)

    _card_code.text = String(map.get("code", ""))
    _card_place.text = String(map.get("place", ""))
    var rule_label: String = String(map.get("rule_label", ""))
    _card_rule.text = rule_label if not rule_label.is_empty() else "NO FIELD RULE"
    var width: float = get_viewport().get_visible_rect().size.x
    _card.visible = true
    _card.modulate.a = 0.0
    _card.position.x = -width * 0.35
    var card := _card.create_tween()
    card.tween_property(_card, "position:x", 0.0, 0.32) \
        .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(0.12)
    card.parallel().tween_property(_card, "modulate:a", 1.0, 0.24).set_delay(0.12)
    card.tween_interval(CARD_HOLD)
    card.tween_property(_card, "position:x", width * 0.35, 0.30) \
        .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
    card.parallel().tween_property(_card, "modulate:a", 0.0, 0.30)
    card.tween_callback(_card.hide)


func _build_card() -> void:
    _card = PanelContainer.new()
    _card.name = "MissionCard"
    _card.mouse_filter = Control.MOUSE_FILTER_IGNORE
    # Upper third, below the HUD header: clear of the Guardian and the tray.
    _card.anchor_top = 0.24
    _card.anchor_bottom = 0.24
    _card.anchor_right = 1.0
    _card.offset_bottom = 120.0
    var style := StyleBoxFlat.new()
    style.bg_color = PANEL
    style.border_color = CYAN
    style.border_width_top = 2
    style.border_width_bottom = 2
    style.shadow_color = Color(CYAN, 0.28)
    style.shadow_size = 14
    style.content_margin_top = 14
    style.content_margin_bottom = 14
    _card.add_theme_stylebox_override("panel", style)
    var stack := VBoxContainer.new()
    stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stack.add_theme_constant_override("separation", 2)
    _card.add_child(stack)
    _card_code = _label(15, VIOLET)
    _card_place = _label(40, INK)
    _card_rule = _label(17, CYAN)
    stack.add_child(_card_code)
    stack.add_child(_card_place)
    stack.add_child(_card_rule)
    _card.hide()
    add_child(_card)


func _label(font_size: int, ink: Color) -> Label:
    var label := Label.new()
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", ink)
    label.add_theme_color_override("font_outline_color", Color(ink, 0.25))
    label.add_theme_constant_override("outline_size", 6)
    return label
