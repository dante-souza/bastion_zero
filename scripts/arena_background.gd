class_name ArenaBackground
extends RefCounted

## Phase A horizon + Phase B.1 smoother near-black-to-navy gradient and
## Guardian-centered radial falloff. Pure presentation; no gameplay rules.
const SEGMENTS := 48
const CREST_Y := 990.0
const EDGE_Y := 1120.0
const RADIAL_SECTORS := 32
const AURA_CENTER := Vector2(360.0, 1050.0)
const AURA_RADIUS := Vector2(440.0, 400.0)

## Sparse, fixed-position details for full-FX only. Kept away from the HUD.
const SPECKS := [
    Vector2(84, 241), Vector2(211, 325), Vector2(589, 276),
    Vector2(650, 383), Vector2(133, 468), Vector2(488, 453),
    Vector2(351, 560), Vector2(71, 641), Vector2(628, 611),
    Vector2(224, 744), Vector2(544, 792), Vector2(112, 870)
]

static func horizon_y(x: float) -> float:
    var unit_x: float = clampf(2.0 * x / GameCatalog.WORLD_SIZE.x - 1.0, -1.0, 1.0)
    return lerpf(CREST_Y, EDGE_Y, unit_x * unit_x)

static func horizon_points() -> PackedVector2Array:
    var path := PackedVector2Array()
    for i in range(SEGMENTS + 1):
        var x: float = GameCatalog.WORLD_SIZE.x * float(i) / float(SEGMENTS)
        path.append(Vector2(x, horizon_y(x)))
    return path

static func draw_to(canvas: CanvasItem, reduced_fx: bool, visual_time: float) -> void:
    # Four-vertex interpolated colors: one smooth vertical gradient, not bands.
    var w: float = GameCatalog.WORLD_SIZE.x
    var h: float = GameCatalog.WORLD_SIZE.y
    canvas.draw_polygon(
        PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
        PackedColorArray([
            VisualProfile.BACKDROP, VisualProfile.BACKDROP,
            VisualProfile.BACKDROP_BOTTOM, VisualProfile.BACKDROP_BOTTOM
        ])
    )

    # Small vertex-colored fan makes a smoothly fading blue aura behind the
    # Guardian. At J8 low-FX, 20 triangles; full-FX uses 32. No shader/bloom.
    var sectors: int = 20 if reduced_fx else RADIAL_SECTORS
    var tint: Color = VisualProfile.GUARDIAN_AURA
    if reduced_fx:
        tint.a *= 0.86
    var edge_tint := Color(tint.r, tint.g, tint.b, 0.0)
    for i in range(sectors):
        var a0: float = TAU * float(i) / float(sectors)
        var a1: float = TAU * float(i + 1) / float(sectors)
        var p0 := AURA_CENTER + Vector2(cos(a0) * AURA_RADIUS.x, sin(a0) * AURA_RADIUS.y)
        var p1 := AURA_CENTER + Vector2(cos(a1) * AURA_RADIUS.x, sin(a1) * AURA_RADIUS.y)
        canvas.draw_polygon(
            PackedVector2Array([AURA_CENTER, p0, p1]),
            PackedColorArray([tint, edge_tint, edge_tint])
        )

    if not reduced_fx:
        for speck in SPECKS:
            canvas.draw_circle(speck, 1.25, VisualProfile.BACKGROUND_SPECK)

    var curve := horizon_points()
    if not reduced_fx:
        # Translucent strokes mimic a modest halo without a costly bloom pass.
        var halo := VisualProfile.HORIZON_HALO_OUTER
        halo.a *= 0.92 + 0.08 * sin(visual_time * 1.4)
        canvas.draw_polyline(curve, halo, 22.0, true)
        canvas.draw_polyline(curve, VisualProfile.HORIZON_HALO_INNER, 9.0, true)
    canvas.draw_polyline(curve, VisualProfile.HORIZON_BLUE, 3.0, true)
    canvas.draw_polyline(curve, VisualProfile.HORIZON_CORE, 1.0, true)

    # The simulation's straight breach threshold still exists at BREACH_Y.
    # Tiny boundary ticks signal its position without a red screen-wide bar.
    var marker := VisualProfile.BREACH
    marker.a = 0.50
    var by: float = GameCatalog.BREACH_Y
    var right: float = GameCatalog.WORLD_SIZE.x
    canvas.draw_line(Vector2(12.0, by), Vector2(58.0, by), marker, 2.0, true)
    canvas.draw_line(Vector2(right - 58.0, by), Vector2(right - 12.0, by), marker, 2.0, true)
