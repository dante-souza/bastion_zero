class_name ThreatGlyph
extends Control

## Static geometric legends aligned with actual EnemyRenderer silhouettes.
## Drawing occurs once on layout, not every combat frame.
var kind := "grunt"
var tint := Color("#5FEFFF")

func _ready() -> void:
    custom_minimum_size = Vector2(62, 68)
    mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
    var center := Vector2(31.0, 33.0)
    var dark := Color("#07121E")
    draw_rect(Rect2(Vector2.ZERO, Vector2(62, 68)), dark, true)
    match kind:
        "grunt":
            draw_arc(center, 18.0, 0.0, TAU, 30, tint, 5.0, true)
            draw_circle(center, 4, Color("#C8FFFF"))
        "runner":
            var tri := EnemyRenderer.triangle_vertices(center, 21.0)
            tri.append(tri[0])
            draw_polyline(tri, tint, 4.0, true)
            draw_circle(center, 2.5, Color("#C8FFFF"))
        "tank":
            draw_rect(Rect2(center - Vector2(20, 20), Vector2(40, 40)), tint, false, 4.0, true)
            draw_polyline(PackedVector2Array([
                center + Vector2(0,-15), center + Vector2(15,0),
                center + Vector2(0,15), center + Vector2(-15,0),
                center + Vector2(0,-15)
            ]), VisualProfile.TANK_SHIELD, 2.5, true)
        "elite":
            draw_arc(center, 23, 0, TAU, 30, VisualProfile.ELITE_RIM, 3, true)
            for i in range(4):
                var angle := float(i) * TAU / 4.0 + 0.11
                draw_arc(center, 18, angle, angle + 1.22, 8, tint, 4, true)
            draw_circle(center, 5, VisualProfile.ELITE_RIM)
        "warden":
            draw_polyline(MechanicVisuals.hexagon(center, 21.0), tint, 4.0, true)
            draw_polyline(MechanicVisuals.hexagon(center, 11.0), tint, 2.0, true)
            draw_circle(center, 3, Color("#C8FFFF"))
        "shield":
            draw_arc(center, 11, 0, TAU, 24, VisualProfile.GRUNT, 4, true)
            draw_polyline(MechanicVisuals.hexagon(center, 21.0, PI / 6.0), tint, 2.5, true)
        "overdrive":
            draw_line(center + Vector2(-16, 20), center + Vector2(8, -6), tint, 4, true)
            draw_arc(center + Vector2(8, -6), 14, 0, TAU, 26, tint, 3, true)
            draw_circle(center + Vector2(8, -6), 4, VisualProfile.OVERDRIVE_CORE)
        "guardian":
            draw_circle(center, 23, Color("#092845"))
            draw_arc(center, 20, 0, TAU, 32, VisualProfile.GUARDIAN_RING_LIGHT, 5, true)
            draw_arc(center, 12, 0, TAU, 28, VisualProfile.GUARDIAN_RING_BLUE, 3, true)
            draw_circle(center, 5, VisualProfile.GUARDIAN_EYE)
        "weapon":
            draw_line(center + Vector2(-19, 18), center + Vector2(18,-20), tint, 4, true)
            draw_circle(center + Vector2(18,-20), 4, VisualProfile.HIT)
        "focus":
            # Same geometry EnemyRenderer uses: an outline ring around a target.
            draw_arc(center, 13, 0, TAU, 26, VisualProfile.GRUNT, 4, true)
            draw_arc(center, 22, 0, TAU, 30, tint, 2.5, true)
        "slow":
            draw_arc(center, 13, 0, TAU, 26, VisualProfile.RUNNER, 4, true)
            draw_arc(center, 21, 0, TAU, 30, tint, 2.0, true)
            for i in range(3):
                var y := 20.0 + float(i) * 6.0
                draw_line(Vector2(6, y), Vector2(13, y), tint, 1.6, true)
        "health":
            draw_rect(Rect2(Vector2(8,31), Vector2(46,7)), VisualProfile.HEALTH_TRACK)
            draw_rect(Rect2(Vector2(8,31), Vector2(33,7)), tint)
        "xp":
            draw_circle(center, 12, tint)
            draw_circle(center, 6, dark)
        "formation":
            for dx in [-14,0,14]:
                draw_circle(center + Vector2(dx, 0), 3.8, tint)
            draw_line(center + Vector2(-19,16), center + Vector2(19,16), tint, 2, true)
        "breach":
            draw_line(center + Vector2(-22, 8), center + Vector2(22,8), tint, 3, true)
            draw_line(center + Vector2(-8,-10), center + Vector2(8,14), tint, 3, true)
        _:
            draw_arc(center, 19, 0, TAU, 30, tint, 2.5, true)
            draw_circle(center, 4, tint)
