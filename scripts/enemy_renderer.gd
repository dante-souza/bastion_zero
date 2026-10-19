class_name EnemyRenderer
extends RefCounted

## Phase C: original geometric enemies; no enemy gameplay logic lives here.
## radius is the *existing collision radius*; geometry can be modestly larger
## for small-screen readability without changing hits, targeting, or damage.
const GRUNT_VISUAL_MIN := 19.0
const RUNNER_VISUAL_MIN := 19.0
const TANK_VISUAL_MIN := 27.0
const ELITE_VISUAL_MIN := 48.0
const HEALTH_BAR_WIDTH := 5.0

static func visual_radius(kind: String, collision_radius: float) -> float:
    match kind:
        "runner": return maxf(RUNNER_VISUAL_MIN, collision_radius)
        "tank": return maxf(TANK_VISUAL_MIN, collision_radius)
        "elite": return maxf(ELITE_VISUAL_MIN, collision_radius)
    return maxf(GRUNT_VISUAL_MIN, collision_radius)


static func show_health(kind: String, fraction: float, focused: bool) -> bool:
    # Phase I.6: bars only where HP is a decision (multi-hit Tanks and Elites)
    # or on the target the player picked. Damaged swarm units no longer each
    # grow a bar, which put an ivory dash over nearly every enemy mid-fight.
    return kind == "tank" or kind == "elite" or focused


static func triangle_vertices(at: Vector2, size: float) -> PackedVector2Array:
    # Fast units move downward; their points face downward too.
    return PackedVector2Array([
        at + Vector2(0.0, size),
        at + Vector2(-size * 0.78, -size * 0.68),
        at + Vector2(size * 0.78, -size * 0.68)
    ])


static func draw_to(
        canvas: CanvasItem, enemy: Dictionary, reduced_fx: bool,
        visual_time: float, is_focused: bool, elite_enraged: bool) -> void:
    var kind: String = String(enemy["kind"])
    var at: Vector2 = enemy["pos"]
    var collision_radius: float = float(enemy["radius"])
    var radius: float = visual_radius(kind, collision_radius)
    var tint: Color = VisualProfile.enemy_tint(kind)
    var interior: Color = VisualProfile.ENEMY_INTERIOR

    if float(enemy["slow"]) > 0.0:
        canvas.draw_arc(at, radius + 8.0, 0.0, TAU, 20, VisualProfile.ENEMY_SLOWED, 2.0, true)

    match kind:
        "runner":
            var vertices := triangle_vertices(at, radius)
            if not reduced_fx:
                canvas.draw_colored_polygon(vertices, Color(tint.r, tint.g, tint.b, 0.18))
            canvas.draw_polyline(_closed(vertices), tint, 3.5, true)
            var inner := triangle_vertices(at + Vector2(0, 1), radius * 0.45)
            canvas.draw_polyline(_closed(inner), Color(tint.r, tint.g, tint.b, 0.62), 1.4, true)
            canvas.draw_circle(at + Vector2(0, 1), 2.3, VisualProfile.ENEMY_CENTER)
        "tank":
            var side: float = radius * 0.87
            canvas.draw_rect(Rect2(at - Vector2.ONE * side, Vector2.ONE * side * 2.0),
                interior, true)
            canvas.draw_rect(Rect2(at - Vector2.ONE * side, Vector2.ONE * side * 2.0),
                tint, false, 4.0, true)
            var diamond := PackedVector2Array([
                at + Vector2(0, -radius * 0.64),
                at + Vector2(radius * 0.64, 0),
                at + Vector2(0, radius * 0.64),
                at + Vector2(-radius * 0.64, 0)
            ])
            canvas.draw_polyline(_closed(diamond), VisualProfile.TANK_SHIELD, 2.5, true)
            canvas.draw_line(at + Vector2(-radius * 0.39, 0), at + Vector2(radius * 0.39, 0),
                tint, 2.0, true)
            canvas.draw_circle(at, 3.4, VisualProfile.ENEMY_CENTER)
        "elite":
            _draw_elite(canvas, at, radius, visual_time, elite_enraged, reduced_fx)
        _:
            canvas.draw_circle(at, radius, interior)
            canvas.draw_arc(at, radius - 1.5, 0.0, TAU, 26, tint, 5.0, true)
            canvas.draw_circle(at, radius * 0.38, Color(tint.r, tint.g, tint.b, 0.23))
            canvas.draw_circle(at, 3.0, VisualProfile.ENEMY_CENTER)

    if float(enemy["flash"]) > 0.0:
        canvas.draw_arc(at, radius + 4.0, 0.0, TAU, 24,
            Color(1.0, 1.0, 1.0, 0.92), 2.5, true)

    if is_focused:
        canvas.draw_arc(at, radius + 11.0, 0.0, TAU, 28,
            VisualProfile.TARGET_LOCK, 2.5, true)

    var fraction: float = clampf(float(enemy["hp"]) / maxf(1.0, float(enemy["max_hp"])), 0.0, 1.0)
    if show_health(kind, fraction, is_focused):
        var bar_width: float = radius * 2.0
        var upper: Vector2 = at + Vector2(-radius, -radius - 16.0)
        canvas.draw_rect(Rect2(upper, Vector2(bar_width, HEALTH_BAR_WIDTH)),
            VisualProfile.HEALTH_TRACK, true)
        canvas.draw_rect(Rect2(upper, Vector2(bar_width * fraction, HEALTH_BAR_WIDTH)),
            VisualProfile.HEALTH_FILL, true)


static func _draw_elite(
        canvas: CanvasItem, at: Vector2, radius: float,
        visual_time: float, enraged: bool, reduced_fx: bool) -> void:
    var pink: Color = VisualProfile.ELITE
    var ember: Color = VisualProfile.ELITE_RIM
    canvas.draw_circle(at, radius, VisualProfile.ENEMY_INTERIOR)
    canvas.draw_arc(at, radius, 0.0, TAU, 42, ember, 3.0, true)
    # Quarter arcs are distinctive even at thumbnail size; no particle shower.
    for i in range(4):
        var angle: float = float(i) * TAU / 4.0 + 0.11
        var first: float = angle + 0.07
        var last: float = angle + TAU / 4.0 - 0.20
        canvas.draw_arc(at, radius * 0.82, first, last, 10, pink, 6.0, true)

    var pulse: float = 0.5 + 0.5 * sin(visual_time * 2.0)
    canvas.draw_arc(at, radius * 0.47, 0.0, TAU, 26, pink, 3.0, true)
    canvas.draw_circle(at, radius * 0.23, ember)
    canvas.draw_circle(at, 5.0, VisualProfile.ENEMY_INTERIOR)
    if not reduced_fx:
        canvas.draw_arc(at, radius + 7.0 + 1.5 * pulse,
            0.0, TAU, 32, Color(pink.r, pink.g, pink.b, 0.26), 2.5, true)
    if enraged:
        canvas.draw_arc(at, radius + 11.0, 0.0, TAU, 36, VisualProfile.ENEMY_ENRAGED, 4.0, true)
        canvas.draw_circle(at, 4.0, VisualProfile.ENEMY_CENTER)


static func _closed(vertices: PackedVector2Array) -> PackedVector2Array:
    var result: PackedVector2Array = vertices.duplicate()
    result.append(vertices[0])
    return result


## Drop pod telegraph (AMBUSH sector): a warm ring that closes in on the
## landing point as the pod falls. Warm, because it marks a hostile arrival.
static func draw_drop_marker(canvas: CanvasItem, drop: Dictionary, visual_time: float) -> void:
    var at: Vector2 = drop["pos"]
    var left: float = clampf(float(drop["t"]) / maxf(0.01, float(drop["duration"])), 0.0, 1.0)
    var warn: Color = ThreatLanguage.WARNING
    var blink: float = 0.55 + 0.45 * sin(visual_time * 14.0)
    canvas.draw_arc(at, 30.0 + 60.0 * left, 0.0, TAU, 28, Color(warn.r, warn.g, warn.b, 0.75 * blink), 3.0, true)
    canvas.draw_arc(at, 26.0, 0.0, TAU, 20, Color(warn.r, warn.g, warn.b, 0.35), 2.0, true)
    canvas.draw_line(at + Vector2(-12.0, 0.0), at + Vector2(12.0, 0.0), warn, 2.0, true)
    canvas.draw_line(at + Vector2(0.0, -12.0), at + Vector2(0.0, 12.0), warn, 2.0, true)
