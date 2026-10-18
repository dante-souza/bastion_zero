class_name GuardianRenderer
extends RefCounted

## Visual Phase B.1: original procedural approximation of the selected
## four-cardinal-module / circular eye Guardian. Pure drawing, no game rules.
## All coordinates are logical canvas units, centered at GameCatalog.GUARDIAN.
## Static orientation is intentional; Phase B.2 will link actual muzzle/aim vectors.
const OUTER_RADIUS := 54.0
const MODULE_TIP_RADIUS := 72.0
const CORE_RADIUS := 15.0
const RING_SEGMENTS := 4
const MODULE_DIRECTIONS: Array[Vector2] = [
    Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT
]

static func draw_to(canvas: CanvasItem, center: Vector2, low_fx: bool, visual_time: float) -> void:
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
