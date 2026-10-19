class_name UpgradeEmblem
extends Control

## Simple geometry-based weapon/support icons, no raster textures or frame loop.
## Phase I.6: every upgrade has its own silhouette. Color alone no longer
## separates Sentinel from Prism ("shape says what it is" also on cards).
var kind := ""
var tint := Color("#6DC09A")

const SHAPES := {
    "gun": "tracers",
    "gun_payload": "heavy_round",
    "gun_pierce": "pierce",
    "gun_ricochet": "bounce",
    "gun_volley": "fan",
    "beam": "prism",
    "volley": "comets",
    "arc": "lightning",
    "nova": "field",
    "hull": "shield",
    "rate": "chevrons",
    "power": "amplify",
    "reach": "range",
}


static func shape_for(key: String) -> String:
    return String(SHAPES.get(key, "generic"))


func _draw() -> void:
    var m := size * 0.5
    draw_rect(Rect2(Vector2.ZERO, size), Color("#0C2630"), true)
    draw_arc(m, minf(size.x, size.y) * 0.37, 0.0, TAU, 32, tint.darkened(0.25), 2.0, true)
    match shape_for(kind):
        "tracers":
            # Three cyan tracer rounds climbing: the Sentinel's own shot.
            for i in range(3):
                var x := m.x + float(i - 1) * 10.0
                var y := m.y + (6.0 if i != 1 else -4.0)
                draw_line(Vector2(x, y + 8.0), Vector2(x, y - 8.0), tint, 4.0, true)
                draw_circle(Vector2(x, y - 9.0), 2.6, tint)
        "heavy_round":
            draw_line(m + Vector2(0, 16), m + Vector2(0, -2), tint, 6.0, true)
            draw_circle(m + Vector2(0, -8), 8.0, tint)
        "pierce":
            draw_arc(m, 9.0, 0.0, TAU, 20, tint, 3.0, true)
            draw_line(m + Vector2(0, 20), m + Vector2(0, -20), tint, 4.0, true)
            draw_line(m + Vector2(0, -20), m + Vector2(-6, -13), tint, 3.0, true)
            draw_line(m + Vector2(0, -20), m + Vector2(6, -13), tint, 3.0, true)
        "bounce":
            draw_polyline(PackedVector2Array([
                m + Vector2(-16, 16), m + Vector2(-4, -12), m + Vector2(8, 6),
                m + Vector2(17, -14)]), tint, 4.0, true)
            draw_circle(m + Vector2(17, -14), 3.5, tint)
        "fan":
            for angle in [-0.45, 0.0, 0.45]:
                var dir := Vector2.UP.rotated(angle)
                draw_line(m + Vector2(0, 14), m + Vector2(0, 14) + dir * 28.0, tint, 3.0, true)
        "prism":
            # A prism splitting one ray: visibly not a Sentinel round.
            var tri := PackedVector2Array([
                m + Vector2(-13, 12), m + Vector2(13, 12), m + Vector2(0, -11),
                m + Vector2(-13, 12)])
            draw_polyline(tri, tint, 3.0, true)
            draw_line(m + Vector2(0, -11), m + Vector2(0, -22), tint, 4.0, true)
            draw_line(m + Vector2(-20, 4), m + Vector2(-6, 2), tint.darkened(0.2), 2.0, true)
        "comets":
            for offset in [-11, 0, 11]:
                var head := m + Vector2(offset + 6, -12)
                draw_line(m + Vector2(offset - 2, 14), head, tint.darkened(0.25), 2.5, true)
                draw_circle(head, 3.6, tint)
        "lightning":
            draw_polyline(PackedVector2Array([
                m + Vector2(-19, -4), m + Vector2(-3, -13),
                m + Vector2(2, 0), m + Vector2(17, -7),
                m + Vector2(5, 16)]), tint, 4.0, true)
        "field":
            draw_circle(m, 9, tint)
            draw_arc(m, 19, 0.0, TAU, 24, tint, 3.0, true)
        "shield":
            var points := PackedVector2Array([
                m + Vector2(0, -19), m + Vector2(17, -10),
                m + Vector2(14, 10), m + Vector2(0, 20),
                m + Vector2(-14, 10), m + Vector2(-17, -10), m + Vector2(0, -19)])
            draw_polyline(points, tint, 3.0, true)
            draw_line(m + Vector2(0, -9), m + Vector2(0, 9), tint, 3.0, true)
            draw_line(m + Vector2(-8, 0), m + Vector2(8, 0), tint, 3.0, true)
        "chevrons":
            for dx in [-8.0, 6.0]:
                draw_polyline(PackedVector2Array([
                    m + Vector2(dx - 6, -12), m + Vector2(dx + 6, 0),
                    m + Vector2(dx - 6, 12)]), tint, 4.0, true)
        "amplify":
            draw_line(m + Vector2(0, 14), m + Vector2(0, -14), tint, 4.0, true)
            draw_line(m + Vector2(0, -14), m + Vector2(-9, -4), tint, 4.0, true)
            draw_line(m + Vector2(0, -14), m + Vector2(9, -4), tint, 4.0, true)
            draw_line(m + Vector2(-12, 16), m + Vector2(12, 16), tint, 3.0, true)
        "range":
            for r in [7.0, 13.0, 19.0]:
                draw_arc(m + Vector2(0, 10), r, -PI * 0.85, -PI * 0.15, 14, tint, 2.6, true)
            draw_circle(m + Vector2(0, 10), 3.0, tint)
        _:
            draw_circle(m, 6.0, tint)
