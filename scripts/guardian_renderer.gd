class_name GuardianRenderer
extends RefCounted

## Phases B.1–B.2: original procedural Guardian and combat-aware gun overlays.
## Art remains distinct from mechanics. The simulation calls sentinel_muzzle()
## so every barrel tip is exactly the projectile origin, not decorative fiction.
const OUTER_RADIUS := 54.0
const MODULE_TIP_RADIUS := 72.0
const CORE_RADIUS := 15.0
const RING_SEGMENTS := 4
const MODULE_DIRECTIONS: Array[Vector2] = [
    Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT
]

## Shared with Arena._fire_gun: keep its original centered 25-unit spacing.
## No changes to shot speed, targeting, collision, damage, or hitboxes.
static func sentinel_barrel_count(gun_rank: int, volley_rank: int) -> int:
    return 1 + (1 if gun_rank >= 3 else 0) + maxi(0, volley_rank)


static func sentinel_muzzle(center: Vector2, barrel_index: int, count: int) -> Vector2:
    var offset: float = (float(barrel_index) - (float(count) - 1.0) * 0.5) * 25.0
    return center + Vector2(offset, -45.0)


static func draw_to(
        canvas: CanvasItem, center: Vector2, low_fx: bool, visual_time: float,
        gun_count: int, gun_lanes: Array[Dictionary], damage_fraction: float) -> void:
    var metal := VisualProfile.GUARDIAN_METAL
    var navy := VisualProfile.GUARDIAN_SHADOW
    var cyan := VisualProfile.GUARDIAN_CORE
    var royal := VisualProfile.GUARDIAN_RING_BLUE

    # B.1: subtle active-reactor breathing, independent of simulation and hit logic.
    var pulse: float = 0.5 + 0.5 * sin(visual_time * 1.7)
    if not low_fx:
        canvas.draw_circle(center, 59.0, Color(0.06, 0.47, 0.90, 0.11 + pulse * 0.025))
        canvas.draw_arc(center, 59.0, 0.0, TAU, 48, Color(0.07, 0.68, 1.0, 0.19), 3.0, true)

    # Pod housings sit behind the circular armor. Left/right are future
    # physical Sentinel gun mounts; they do NOT relocate B.1 projectiles.
    for direction in MODULE_DIRECTIONS:
        _draw_module(canvas, center, direction, low_fx)

    # One bold cyan armor ring, four split blue panels and a dark inset.
    canvas.draw_circle(center, 49.0, navy)
    canvas.draw_arc(center, 45.0, 0.0, TAU, 48, royal, 11.0, true)
    canvas.draw_arc(center, 45.0, 0.0, TAU, 48, cyan, 3.0, true)
    for i in range(RING_SEGMENTS):
        var from_angle: float = TAU * float(i) / float(RING_SEGMENTS) + 0.14
        var to_angle: float = TAU * float(i + 1) / float(RING_SEGMENTS) - 0.14
        canvas.draw_arc(center, OUTER_RADIUS, from_angle, to_angle, 12,
            VisualProfile.GUARDIAN_RING_LIGHT if i % 2 == 0 else royal, 6.5, true)

    # Aim vectors come from the actual last emitted projectile velocity.
    # Drawing from (muzzle - direction * barrel_length) to muzzle guarantees
    # that the visible barrel points along the same line as the flying round.
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

    canvas.draw_circle(center, 35.0, metal)
    canvas.draw_arc(center, 34.0, 0.0, TAU, 40, VisualProfile.GUARDIAN_STEEL, 4.0, true)
    canvas.draw_circle(center, 27.0, navy)
    canvas.draw_arc(center, 23.0, 0.0, TAU, 40, royal, 3.0, true)
    canvas.draw_circle(center, CORE_RADIUS + 4.0, Color("#030d28"))
    canvas.draw_arc(center, CORE_RADIUS + 4.0, 0.0, TAU, 32, cyan, 3.0, true)
    canvas.draw_circle(center, CORE_RADIUS, VisualProfile.GUARDIAN_LENS)
    canvas.draw_circle(center, 8.5, VisualProfile.GUARDIAN_LENS_INNER)
    canvas.draw_circle(center, 3.0 + pulse * (0.8 if not low_fx else 0.2),
        VisualProfile.GUARDIAN_EYE)
    if not low_fx:
        canvas.draw_circle(center + Vector2(-4.7, -5.1), 3.4, Color(0.76, 0.96, 1.0, 0.33))
        canvas.draw_circle(center + Vector2(3.0, 8.0), 1.5, Color(0.3, 0.78, 1.0, 0.50))

    # A breach damages the lower zone, so signal hull loss with a short
    # localized rim flash even on J8 low-FX (no screen-wide overlay).
    if damage_fraction > 0.0:
        var warning: Color = VisualProfile.GUARDIAN_DAMAGE
        warning.a = (0.24 if low_fx else 0.46) * damage_fraction
        canvas.draw_arc(center, 62.0, 0.0, TAU, 40, warning, 4.0, true)
        if not low_fx:
            canvas.draw_circle(center, 13.0, Color(1.0, 0.24, 0.22, 0.12 * damage_fraction))


static func module_point(center: Vector2, direction: Vector2) -> Vector2:
    return center + direction * MODULE_TIP_RADIUS


static func _draw_module(canvas: CanvasItem, center: Vector2, direction: Vector2, low_fx: bool) -> void:
    var across := Vector2(-direction.y, direction.x)
    var root: Vector2 = center + direction * 43.0
    var end: Vector2 = center + direction * 68.0
    var half_width: float = 12.0 if absf(direction.x) > 0.5 else 10.0
    var plate := PackedVector2Array([
        root - across * (half_width + 3.0),
        root + across * (half_width + 3.0),
        end + across * half_width,
        end - across * half_width
    ])
    canvas.draw_colored_polygon(plate, VisualProfile.GUARDIAN_METAL)
    canvas.draw_line(root - across * half_width, end - across * (half_width - 2.0),
        VisualProfile.GUARDIAN_STEEL, 2.0, true)
    canvas.draw_line(root + across * half_width, end + across * (half_width - 2.0),
        VisualProfile.GUARDIAN_STEEL, 2.0, true)
    canvas.draw_line(root + direction * 6.0, end - direction * 3.0,
        VisualProfile.GUARDIAN_RING_LIGHT, 4.0, true)
    if absf(direction.x) > 0.5:
        # Hollow outlet reads as a mechanical gun-port on either side.
        var port: Vector2 = module_point(center, direction)
        canvas.draw_circle(port, 9.0, VisualProfile.GUARDIAN_RING_BLUE)
        canvas.draw_circle(port, 5.5, VisualProfile.GUARDIAN_SHADOW)
        canvas.draw_arc(port, 7.0, 0.0, TAU, 20, VisualProfile.GUARDIAN_RING_LIGHT, 2.0, true)
    elif not low_fx:
        canvas.draw_line(end - across * 8.0, end + across * 8.0,
            VisualProfile.GUARDIAN_RING_BLUE, 3.0, true)

## The visual barrel ends exactly at `muzzle`, so every flash shares the
## bullet's simulation launch point. Low-FX retains the short bright tip flash.
static func _draw_barrel(
        canvas: CanvasItem, muzzle: Vector2, direction: Vector2,
        age: float, low_fx: bool) -> void:
    var direction_ok: Vector2 = direction.normalized()
    if direction_ok.length_squared() < 0.8:
        direction_ok = Vector2.UP
    var root: Vector2 = muzzle - direction_ok * 25.0
    canvas.draw_line(root, muzzle, VisualProfile.GUARDIAN_SHADOW, 12.0, true)
    canvas.draw_line(root, muzzle, VisualProfile.GUARDIAN_STEEL, 7.5, true)
    canvas.draw_line(root + direction_ok * 6.0, muzzle, VisualProfile.GUARDIAN_RING_LIGHT, 2.5, true)
    canvas.draw_circle(muzzle, 4.0, VisualProfile.GUARDIAN_SHADOW)
    canvas.draw_arc(muzzle, 4.5, 0.0, TAU, 16, VisualProfile.GUARDIAN_RING_LIGHT, 1.5, true)
    var flash_period: float = 0.08 if low_fx else 0.11
    if age >= 0.0 and age < flash_period:
        var alpha: float = 1.0 - age / flash_period
        canvas.draw_circle(muzzle, (6.0 if low_fx else 9.0) * alpha,
            Color(0.73, 0.99, 1.0, 0.90 * alpha))
        if not low_fx:
            canvas.draw_line(muzzle, muzzle + direction_ok * 14.0 * alpha,
                Color(0.18, 0.88, 1.0, alpha), 3.0, true)
