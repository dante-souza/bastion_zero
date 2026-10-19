class_name MechanicVisuals
extends RefCounted

## 0.9.7 mechanic visuals: Warden, shield marks, Overdrive strike and the
## Moving Line. Kept apart from EnemyRenderer/WeaponEffects so a later
## restyle can swap this one file. Drawing only; no gameplay state here.
## Colors follow the rule: Warden and shields are warm (hostile), Overdrive
## and the Line are cool (yours).
const WARDEN_VISUAL_MIN := 21.0


static func hexagon(at: Vector2, size: float, turn: float = 0.0) -> PackedVector2Array:
    var points := PackedVector2Array()
    for i in range(7):
        points.append(at + Vector2.from_angle(turn + float(i % 6) * TAU / 6.0) * size)
    return points


static func draw_warden_aura(canvas: CanvasItem, at: Vector2, reduced_fx: bool, visual_time: float) -> void:
    # Dashed, slowly turning ring at near-full opacity: a low-alpha warm fill
    # over navy reads as a brown hazard blot (the I.6 kill-pop lesson).
    var tint: Color = VisualProfile.WARDEN
    var reach: float = GameCatalog.WARDEN_AURA
    var turn: float = visual_time * 0.6
    var dashes := 12
    var pulse: float = 0.5 + 0.5 * sin(visual_time * 3.0)
    var stroke := Color(tint.r, tint.g, tint.b, 0.55 + 0.25 * pulse)
    for i in range(dashes):
        var start: float = turn + float(i) * TAU / float(dashes)
        canvas.draw_arc(at, reach, start, start + TAU / float(dashes) * 0.55, 6, stroke, 2.0, not reduced_fx)


static func draw_warden(canvas: CanvasItem, enemy: Dictionary, reduced_fx: bool,
        visual_time: float, is_focused: bool) -> void:
    var at: Vector2 = enemy["pos"]
    var radius: float = maxf(WARDEN_VISUAL_MIN, float(enemy["radius"]))
    var tint: Color = VisualProfile.WARDEN
    var turn: float = visual_time * 0.8
    var body := hexagon(at, radius, turn)
    canvas.draw_colored_polygon(body.slice(0, 6), VisualProfile.ENEMY_INTERIOR)
    canvas.draw_polyline(body, tint, 4.0, true)
    canvas.draw_polyline(hexagon(at, radius * 0.52, -turn), Color(tint.r, tint.g, tint.b, 0.70), 2.0, true)
    canvas.draw_circle(at, 3.2, VisualProfile.ENEMY_CENTER)
    if float(enemy["slow"]) > 0.0:
        canvas.draw_arc(at, radius + 8.0, 0.0, TAU, 20, VisualProfile.ENEMY_SLOWED, 2.0, true)
    if float(enemy["flash"]) > 0.0:
        canvas.draw_arc(at, radius + 4.0, 0.0, TAU, 24, Color(1.0, 1.0, 1.0, 0.92), 2.5, true)
    if is_focused:
        canvas.draw_arc(at, radius + 11.0, 0.0, TAU, 28, VisualProfile.TARGET_LOCK, 2.5, true)
    # HP is a decision on a Warden, so it always carries a bar.
    var fraction: float = clampf(float(enemy["hp"]) / maxf(1.0, float(enemy["max_hp"])), 0.0, 1.0)
    var upper: Vector2 = at + Vector2(-radius, -radius - 16.0)
    canvas.draw_rect(Rect2(upper, Vector2(radius * 2.0, EnemyRenderer.HEALTH_BAR_WIDTH)), VisualProfile.HEALTH_TRACK, true)
    canvas.draw_rect(Rect2(upper, Vector2(radius * 2.0 * fraction, EnemyRenderer.HEALTH_BAR_WIDTH)), VisualProfile.HEALTH_FILL, true)


## Hex outline around a protected hostile, in the color of what protects it:
## salmon for a Warden aura, tank yellow for an escort.
static func draw_shield_mark(canvas: CanvasItem, enemy: Dictionary, reduced_fx: bool) -> void:
    var at: Vector2 = enemy["pos"]
    var radius: float = EnemyRenderer.visual_radius(String(enemy["kind"]), float(enemy["radius"])) + 6.0
    var tint: Color = VisualProfile.WARDEN if int(enemy["shield"]) == 1 else VisualProfile.TANK_SHIELD
    canvas.draw_polyline(hexagon(at, radius, PI / 6.0), Color(tint.r, tint.g, tint.b, 0.85), 2.0, not reduced_fx)


## Overdrive: a lance from the Guardian to the strike point and a closing ring.
static func draw_overdrive(canvas: CanvasItem, effect: Dictionary, reduced_fx: bool) -> void:
    var alpha: float = clampf(float(effect["ttl"]) / maxf(0.001, float(effect["duration"])), 0.0, 1.0)
    var from: Vector2 = effect["a"]
    var at: Vector2 = effect["b"]
    var radius: float = float(effect["radius"])
    var tint: Color = effect["color"]
    var core: Color = VisualProfile.OVERDRIVE_CORE
    if not reduced_fx:
        canvas.draw_line(from, at, Color(tint.r, tint.g, tint.b, 0.25 * alpha), 22.0 * alpha, true)
        canvas.draw_circle(at, radius * (1.0 - 0.4 * alpha), Color(tint.r, tint.g, tint.b, 0.08 * alpha))
    canvas.draw_line(from, at, Color(tint.r, tint.g, tint.b, alpha), 6.0 * alpha + 1.0, true)
    canvas.draw_line(from, at, Color(core.r, core.g, core.b, alpha), 2.0, true)
    canvas.draw_arc(at, radius * (1.0 - 0.4 * alpha), 0.0, TAU, 40, Color(tint.r, tint.g, tint.b, alpha), 5.0 * alpha + 1.0, true)
    canvas.draw_arc(at, radius * 0.45, 0.0, TAU, 28, Color(core.r, core.g, core.b, 0.8 * alpha), 2.5, true)


## Moving Line prototype: a cool bar across the field. Brighter when high
## (bonus zone), dimmer and thinner when low (range penalty).
static func draw_line_marker(canvas: CanvasItem, y: float, value: float, reduced_fx: bool, visual_time: float) -> void:
    var tint: Color = VisualProfile.LINE
    var strength: float = 0.35 + 0.65 * value
    if not reduced_fx:
        canvas.draw_rect(Rect2(Vector2(0.0, y - 10.0), Vector2(GameCatalog.WORLD_SIZE.x, 20.0)),
            Color(tint.r, tint.g, tint.b, 0.06 * strength), true)
    var width: float = 4.0 if value >= GameCatalog.LINE_HIGH else (2.0 if value <= GameCatalog.LINE_LOW else 3.0)
    canvas.draw_line(Vector2(0.0, y), Vector2(GameCatalog.WORLD_SIZE.x, y),
        Color(tint.r, tint.g, tint.b, 0.55 + 0.35 * strength), width, true)
    if value <= GameCatalog.LINE_LOW:
        # Low line: travelling ticks warn that range is cut.
        var shift: float = fmod(visual_time * 60.0, 48.0)
        for i in range(16):
            var x: float = float(i) * 48.0 + shift
            canvas.draw_line(Vector2(x, y - 6.0), Vector2(x + 14.0, y - 6.0), Color(tint.r, tint.g, tint.b, 0.5), 2.0)
