class_name ArenaBackground
extends RefCounted

## Phase A horizon geometry. Since the neon pass the sky, aura, horizon glow
## and each sector's animated scene are drawn on the GPU by SectorBackdrop;
## this keeps the horizon math (tests, breach framing) and the breach ticks.
const SEGMENTS := 48
const CREST_Y := 990.0
const EDGE_Y := 1120.0
const AURA_CENTER := Vector2(360.0, 1050.0)
const AURA_RADIUS := Vector2(440.0, 400.0)

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

static func draw_to(canvas: CanvasItem) -> void:
    # The simulation's straight breach threshold still exists at BREACH_Y.
    # Tiny boundary ticks signal its position without a red screen-wide bar.
    var marker := VisualProfile.BREACH
    marker.a = 0.50
    var by: float = GameCatalog.BREACH_Y
    var right: float = GameCatalog.WORLD_SIZE.x
    canvas.draw_line(Vector2(12.0, by), Vector2(58.0, by), marker, 2.0, true)
    canvas.draw_line(Vector2(right - 58.0, by), Vector2(right - 12.0, by), marker, 2.0, true)
