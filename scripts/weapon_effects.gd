class_name WeaponEffects
extends RefCounted

## Phase D — weapon identities with cheap, CanvasItem-only rendering.
## All endpoints/velocities are obtained from actual combat simulation events.
## The damage model stays in Arena; these helpers never deal damage.
const ARC_SEGMENTS_LOW := 6
const ARC_SEGMENTS_FULL := 10

static func draw_projectile(canvas: CanvasItem, bullet: Dictionary, reduced_fx: bool) -> void:
    var pos: Vector2 = bullet["pos"]
    var motion: Vector2 = Vector2(bullet["velocity"]).normalized()
    var kind: String = String(bullet["kind"])
    match kind:
        "gun":
            canvas.draw_line(pos, pos - motion * 18.0, VisualProfile.GUN_TRACER, 2.8, true)
            canvas.draw_circle(pos, 2.8, VisualProfile.HIT)
        "rocket":
            # Amber nose / orange exhaust are recognizably different from
            # cyan Sentinel rounds even in crowded J8 low-FX screenshots.
            canvas.draw_line(pos, pos - motion * (20.0 if reduced_fx else 27.0),
                VisualProfile.COMET_TRAIL, 3.0 if reduced_fx else 4.2, true)
            canvas.draw_circle(pos, 7.0, VisualProfile.COMET_BODY)
            canvas.draw_circle(pos, 2.5, VisualProfile.COMET_HOT)
        _:
            canvas.draw_line(pos, pos - motion * 13.0, VisualProfile.COMET_TRAIL, 2.4, true)
            canvas.draw_circle(pos, 3.4, VisualProfile.COMET_BODY)


static func draw_effect(canvas: CanvasItem, effect: Dictionary, reduced_fx: bool, visual_time: float) -> void:
    var duration: float = maxf(0.001, float(effect["duration"]))
    var alpha: float = clampf(float(effect["ttl"]) / duration, 0.0, 1.0)
    var color: Color = effect["color"]
    color.a *= alpha
    var at: Vector2 = effect["a"]
    var destination: Vector2 = effect["b"]
    var radius: float = float(effect["radius"])
    match String(effect["kind"]):
        "beam":
            # Prism stays exactly on the ray used by Arena._fire_beam().
            if not reduced_fx:
                canvas.draw_line(at, destination,
                    Color(color.r, color.g, color.b, color.a * 0.16),
                    radius + 11.0 * alpha, true)
            canvas.draw_line(at, destination, color, radius + 1.0 * alpha, true)
            canvas.draw_line(at, destination, Color(1, 0.88, 1, 0.72 * alpha),
                1.3, true)
        "arc":
            # Jagged lightning decorates the same collision-resolved chain
            # endpoints; faint straight centerline explains its actual path.
            var points: PackedVector2Array = lightning_points(at, destination, reduced_fx)
            if not reduced_fx:
                canvas.draw_polyline(points, Color(color.r, color.g, color.b, color.a * 0.30), 8.0 * alpha, true)
            canvas.draw_line(at, destination,
                Color(color.r, color.g, color.b, color.a * 0.26), 1.0, true)
            canvas.draw_polyline(points, color, 2.8 if reduced_fx else 3.6, true)
            if not reduced_fx:
                canvas.draw_circle(destination, 4.0 * alpha, VisualProfile.ARC_HOT)
        "nova":
            var expanding: float = radius * (0.82 + (1.0 - alpha) * 0.18)
            if not reduced_fx:
                canvas.draw_circle(at, expanding, Color(color.r, color.g, color.b, 0.035 * alpha))
                canvas.draw_arc(at, expanding * 0.73, 0.0, TAU, 34,
                    Color(color.r, color.g, color.b, 0.22 * alpha), 2.0, true)
            canvas.draw_arc(at, expanding, 0.0, TAU, 44, color, 3.2, true)
        "impact":
            # Rocket burst / fragments: short, warm, non-opaque sparks.
            var grow: float = radius * (1.0 - 0.35 * alpha)
            canvas.draw_arc(at, grow, 0.0, TAU, 20, color, 2.8 * alpha, true)
            canvas.draw_circle(at, 5.0 * alpha, VisualProfile.COMET_HOT)
            if not reduced_fx:
                for i in range(4):
                    var dir: Vector2 = Vector2.from_angle(float(i) * TAU / 4.0 + 0.39)
                    canvas.draw_line(at + dir * 6.0, at + dir * (10.0 + 8.0 * (1.0 - alpha)),
                        color, 2.1 * alpha, true)
        "ring":
            canvas.draw_arc(at, radius * (1.0 - 0.35 * alpha), 0.0, TAU, 28, color, 3.5, true)
        "flash":
            canvas.draw_circle(at, radius * alpha, color)
        "number":
            if not reduced_fx:
                canvas.draw_string(ThemeDB.fallback_font,
                    at + Vector2(0.0, -20.0 * (1.0 - alpha)),
                    "%d" % ceili(radius), HORIZONTAL_ALIGNMENT_CENTER, -1, 19, color)


static func lightning_points(start: Vector2, finish: Vector2, reduced_fx: bool) -> PackedVector2Array:
    var points := PackedVector2Array()
    var vector: Vector2 = finish - start
    var distance: float = vector.length()
    var tangent: Vector2 = vector / maxf(distance, 0.001)
    var across := Vector2(-tangent.y, tangent.x)
    var sections: int = ARC_SEGMENTS_LOW if reduced_fx else ARC_SEGMENTS_FULL
    var width: float = minf(7.0 if reduced_fx else 10.0, distance * 0.035)
    points.append(start)
    for i in range(1, sections):
        var t: float = float(i) / float(sections)
        # Fixed phases: stable across frames, no RNG or texture allocation.
        var alternating := -1.0 if i % 2 == 0 else 1.0
        points.append(start + vector * t + across * width * alternating)
    points.append(finish)
    return points
