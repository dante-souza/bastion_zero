class_name UpgradeEmblem
extends Control

## Simple geometry-based weapon/support icons, no raster textures or frame loop.
var kind := ""
var tint := Color("#6DC09A")


func _draw() -> void:
    var middle := size * 0.5
    draw_rect(Rect2(Vector2.ZERO, size), Color("#0C2630"), true)
    draw_arc(middle, minf(size.x, size.y) * 0.37, 0.0, TAU, 32, tint.darkened(0.25), 2.0, true)
    var a := Vector2(size.x * 0.26, size.y * 0.74)
    var b := Vector2(size.x * 0.74, size.y * 0.26)
    if kind == "hull":
        var points := PackedVector2Array([
            middle + Vector2(0, -19), middle + Vector2(17, -10),
            middle + Vector2(14, 10), middle + Vector2(0, 20),
            middle + Vector2(-14, 10), middle + Vector2(-17, -10)])
        draw_polyline(points, tint, 3.0, true)
        draw_line(middle + Vector2(0, -9), middle + Vector2(0, 9), tint, 3.0, true)
        draw_line(middle + Vector2(-8, 0), middle + Vector2(8, 0), tint, 3.0, true)
    elif kind == "beam" or kind == "reach" or kind == "gun_pierce":
        draw_line(a, b, tint, 5.0, true)
        draw_circle(b, 5, tint)
        draw_line(b, b + Vector2(-10, 0), tint, 2.0, true)
    elif kind == "arc" or kind == "rate" or kind == "gun_ricochet":
        var p := PackedVector2Array([
            middle + Vector2(-19, -4), middle + Vector2(-3, -13),
            middle + Vector2(2, 0), middle + Vector2(17, -7),
            middle + Vector2(5, 16)])
        draw_polyline(p, tint, 4.0, true)
    elif kind == "nova" or kind == "power":
        draw_circle(middle, 9, tint)
        draw_arc(middle, 19, 0.0, TAU, 24, tint, 3.0, true)
    elif kind == "volley" or kind == "gun_volley":
        for offset in [-11, 0, 11]:
            draw_line(middle + Vector2(offset, 12), middle + Vector2(offset + 7, -15), tint, 3.0, true)
    else:
        draw_line(a, b, tint, 5.0, true)
        draw_circle(b, 4.0, tint)
