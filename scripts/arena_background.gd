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

## Sector backdrops reshape the horizon; every shape keeps its lowest point
## near the Guardian so breach logic (a straight BREACH_Y) is unchanged.
static func horizon_y(x: float, shape: String = "crest") -> float:
    var unit_x: float = clampf(2.0 * x / GameCatalog.WORLD_SIZE.x - 1.0, -1.0, 1.0)
    var cx: float = clampf(x, 0.0, GameCatalog.WORLD_SIZE.x)
    match shape:
        "twin":
            var left_hump: float = exp(-pow((cx - 190.0) / 135.0, 2.0))
            var right_hump: float = exp(-pow((cx - 530.0) / 135.0, 2.0))
            return 1118.0 - 112.0 * maxf(left_hump, right_hump)
        "shelf":
            return 1032.0 + 88.0 * smoothstep(0.72, 1.0, absf(unit_x))
        "jagged":
            var saw: float = absf(fposmod(cx, 60.0) - 30.0) / 30.0
            return lerpf(CREST_Y + 8.0, EDGE_Y, unit_x * unit_x) - 16.0 * saw
    return lerpf(CREST_Y, EDGE_Y, unit_x * unit_x)

static func horizon_points(shape: String = "crest") -> PackedVector2Array:
    var path := PackedVector2Array()
    for i in range(SEGMENTS + 1):
        var x: float = GameCatalog.WORLD_SIZE.x * float(i) / float(SEGMENTS)
        path.append(Vector2(x, horizon_y(x, shape)))
    return path

static func draw_to(canvas: CanvasItem, reduced_fx: bool, visual_time: float, stage: int = 1) -> void:
    var sector: Dictionary = SectorCatalog.get_map(stage)
    var top: Color = sector.get("sky_top", VisualProfile.BACKDROP)
    var bottom: Color = sector.get("sky_bottom", VisualProfile.BACKDROP_BOTTOM)
    var line: Color = sector.get("horizon", VisualProfile.HORIZON_BLUE)
    var core: Color = sector.get("horizon_core", VisualProfile.HORIZON_CORE)
    var shape: String = String(sector.get("shape", "crest"))
    # Four-vertex interpolated colors: one smooth vertical gradient, not bands.
    var w: float = GameCatalog.WORLD_SIZE.x
    var h: float = GameCatalog.WORLD_SIZE.y
    canvas.draw_polygon(
        PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
        PackedColorArray([
            top, top, bottom, bottom
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

    if SectorCatalog.rule(stage) == "fog":
        # Null fog: three soft bands over the upper field, cheap on J8.
        for band in range(3):
            var y0: float = 170.0 + band * 120.0 + sin(visual_time * 0.35 + band) * 18.0
            var mist := Color(0.62, 0.70, 0.85, 0.08)
            var clear := Color(mist.r, mist.g, mist.b, 0.0)
            # Vertex-colored quads: soft fade in and out, no hard band edges.
            canvas.draw_polygon(PackedVector2Array([Vector2(0, y0), Vector2(w, y0),
                Vector2(w, y0 + 45.0), Vector2(0, y0 + 45.0)]), PackedColorArray([clear, clear, mist, mist]))
            canvas.draw_polygon(PackedVector2Array([Vector2(0, y0 + 45.0), Vector2(w, y0 + 45.0),
                Vector2(w, y0 + 90.0), Vector2(0, y0 + 90.0)]), PackedColorArray([mist, mist, clear, clear]))
    if shape == "shelf":
        # Iron Shelf struts: faint vertical ribs below the flat horizon.
        var rib := Color(line.r, line.g, line.b, 0.10)
        for i in range(1, 8):
            var rx: float = w * float(i) / 8.0
            canvas.draw_line(Vector2(rx, horizon_y(rx, shape) + 6.0), Vector2(rx, h), rib, 2.0)

    var curve := horizon_points(shape)
    if not reduced_fx:
        # Translucent strokes mimic a modest halo without a costly bloom pass.
        var halo := Color(line.r, line.g, line.b, VisualProfile.HORIZON_HALO_OUTER.a)
        halo.a *= 0.92 + 0.08 * sin(visual_time * 1.4)
        canvas.draw_polyline(curve, halo, 22.0, true)
        canvas.draw_polyline(curve, Color(line.r, line.g, line.b, VisualProfile.HORIZON_HALO_INNER.a), 9.0, true)
    canvas.draw_polyline(curve, line, 3.0, true)
    canvas.draw_polyline(curve, core, 1.0, true)

    # The simulation's straight breach threshold still exists at BREACH_Y.
    # Tiny boundary ticks signal its position without a red screen-wide bar.
    var marker := VisualProfile.BREACH
    marker.a = 0.50
    var by: float = GameCatalog.BREACH_Y
    var right: float = GameCatalog.WORLD_SIZE.x
    canvas.draw_line(Vector2(12.0, by), Vector2(58.0, by), marker, 2.0, true)
    canvas.draw_line(Vector2(right - 58.0, by), Vector2(right - 12.0, by), marker, 2.0, true)
