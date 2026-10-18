class_name GuardianRenderer
extends RefCounted

## Phase B.3: the chosen Guardian design deserves a real illustrated chassis.
## This original SVG is rasterized by Godot at import; one cheap textured draw
## is far more faithful than many thin CanvasItem primitive circles.
## B.2's gun simulations remain authoritative for barrel direction and flashes.
const ART: Texture2D = preload("res://assets/guardian_phase_b3.svg")
const DISPLAY_SIZE := 208.0
const OUTER_RADIUS := 82.0
const MODULE_TIP_RADIUS := 82.0
const CORE_RADIUS := 22.0
const RING_SEGMENTS := 4
const MODULE_DIRECTIONS: Array[Vector2] = [
    Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT
]

static func sentinel_barrel_count(gun_rank: int, volley_rank: int) -> int:
    return 1 + (1 if gun_rank >= 3 else 0) + maxi(0, volley_rank)


static func sentinel_muzzle(center: Vector2, barrel_index: int, count: int) -> Vector2:
    var offset: float = (float(barrel_index) - (float(count) - 1.0) * 0.5) * 25.0
    return center + Vector2(offset, -45.0)


static func module_point(center: Vector2, direction: Vector2) -> Vector2:
    return center + direction * MODULE_TIP_RADIUS


static func draw_to(
        canvas: CanvasItem, center: Vector2, low_fx: bool, visual_time: float,
        gun_count: int, gun_lanes: Array[Dictionary], damage_fraction: float) -> void:
    # No background rectangle baked into the asset: preserve the smooth
    # battlefield gradient and electric-blue defensive horizon.
    var half_size := Vector2.ONE * DISPLAY_SIZE * 0.5
    canvas.draw_texture_rect(ART, Rect2(center - half_size, Vector2.ONE * DISPLAY_SIZE), false)

    # Retain physical B.2 muzzle alignment. A barrel tip precisely matches
    # where its real Sentinel round appears, including upgrades.
    for index in range(gun_count):
        var muzzle: Vector2 = sentinel_muzzle(center, index, gun_count)
        var direction := Vector2.UP
        var fired_at := -100.0
        if index < gun_lanes.size():
            var lane: Dictionary = gun_lanes[index]
            if Vector2(lane["muzzle"]).distance_to(muzzle) < 0.1:
                direction = Vector2(lane["direction"]).normalized()
                fired_at = float(lane["fired_at"])
        _draw_barrel(canvas, muzzle, direction, visual_time - fired_at, low_fx)

    var pulse: float = 0.5 + 0.5 * sin(visual_time * 1.7)
    if not low_fx:
        canvas.draw_circle(center, 3.2 + 0.8 * pulse, Color(0.8, 1.0, 1.0, 0.35))

    if damage_fraction > 0.0:
        var warning: Color = VisualProfile.GUARDIAN_DAMAGE
        warning.a = (0.24 if low_fx else 0.46) * damage_fraction
        canvas.draw_arc(center, OUTER_RADIUS + 3.0, 0.0, TAU, 48, warning, 4.0, true)
        if not low_fx:
            canvas.draw_circle(center, 12.0, Color(1.0, 0.24, 0.22, 0.13 * damage_fraction))


static func _draw_barrel(
        canvas: CanvasItem, muzzle: Vector2, direction: Vector2,
        age: float, low_fx: bool) -> void:
    var aim: Vector2 = direction.normalized()
    if aim.length_squared() < 0.8:
        aim = Vector2.UP
    var root: Vector2 = muzzle - aim * 25.0
    canvas.draw_line(root, muzzle, VisualProfile.GUARDIAN_SHADOW, 11.0, true)
    canvas.draw_line(root, muzzle, VisualProfile.GUARDIAN_STEEL, 6.5, true)
    canvas.draw_line(root + aim * 5.0, muzzle, VisualProfile.GUARDIAN_RING_LIGHT, 2.5, true)
    canvas.draw_circle(muzzle, 3.5, VisualProfile.GUARDIAN_SHADOW)
    canvas.draw_arc(muzzle, 4.0, 0.0, TAU, 16, VisualProfile.GUARDIAN_RING_LIGHT, 1.5, true)
    var flash_period: float = 0.08 if low_fx else 0.11
    if age >= 0.0 and age < flash_period:
        var alpha: float = 1.0 - age / flash_period
        canvas.draw_circle(muzzle, (6.0 if low_fx else 9.0) * alpha,
            Color(0.73, 0.99, 1.0, 0.90 * alpha))
        if not low_fx:
            canvas.draw_line(muzzle, muzzle + aim * 14.0 * alpha,
                Color(0.18, 0.88, 1.0, alpha), 3.0, true)
