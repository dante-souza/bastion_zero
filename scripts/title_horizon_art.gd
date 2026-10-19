class_name TitleHorizonArt
extends Control

## Phase I.3 title illustration: same original Guardian used in gameplay,
## a restrained defensive arc and a sparse tactical enemy silhouette field.
## Static _draw only; the animated sky behind it is the menu backdrop.

const GUARDIAN: Texture2D = preload("res://assets/guardian_phase_b3.svg")
const CYAN := Color("#31D7EF")
const MINT := Color("#68B994")
const WEDGE := Color("#FF923D")
const BLOCK := Color("#E3A846")
const DRIFTER := Color("#E36B9C")

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    custom_minimum_size.y = 400.0
    size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var guardian := TextureRect.new()
    guardian.name = "TitleGuardian"
    guardian.texture = GUARDIAN
    guardian.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    guardian.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    guardian.mouse_filter = Control.MOUSE_FILTER_IGNORE
    guardian.anchor_left = 0.5
    guardian.anchor_right = 0.5
    guardian.offset_left = -105.0
    guardian.offset_right = 105.0
    guardian.offset_top = 191.0
    guardian.offset_bottom = 401.0
    add_child(guardian)


func _draw() -> void:
    var w: float = size.x
    var h: float = size.y
    # Enemy identity is shape + color, independent of the reference image.
    draw_arc(Vector2(w * 0.19, h * 0.17), 10.0, 0.0, TAU, 28, DRIFTER, 3.0, true)
    draw_rect(Rect2(Vector2(w * 0.52 - 9, h * 0.10), Vector2(18, 18)),
        BLOCK, false, 2.5, true)
    _wedge(Vector2(w * 0.82, h * 0.29), 12.0)
    _wedge(Vector2(w * 0.08, h * 0.48), 10.0)
    draw_arc(Vector2(w * 0.91, h * 0.56), 8.0, 0.0, TAU, 28, DRIFTER, 2.5, true)
    # Quiet shield boundary behind the centrally anchored Guardian.
    var horizon := PackedVector2Array()
    for i in range(61):
        var x: float = w * float(i) / 60.0
        var relative: float = (x - w * 0.5) / maxf(w * 0.5, 1.0)
        var y: float = h * 0.76 + 57.0 * relative * relative
        horizon.append(Vector2(x, y))
    # Neon tube: wide faint halo, mid glow, bright core.
    draw_polyline(horizon, Color(CYAN, 0.10), 22.0, true)
    draw_polyline(horizon, Color(CYAN, 0.28), 8.0, true)
    draw_polyline(horizon, CYAN, 2.4, true)
    draw_polyline(horizon, Color("#D8FBFF"), 1.0, true)


func _wedge(center: Vector2, radius: float) -> void:
    draw_polyline(PackedVector2Array([
        center + Vector2(-radius, -radius * 0.65),
        center + Vector2(radius, -radius * 0.65),
        center + Vector2(0.0, radius),
        center + Vector2(-radius, -radius * 0.65)
    ]), WEDGE, 2.8, true)
