class_name EnemySpriteCache
extends SubViewport

## Enemy bodies are static shapes, so they are drawn once into one atlas and
## stamped as textured quads every frame. All bodies share one texture and one
## material, so the GL Compatibility renderer batches the whole swarm, instead
## of ~10 antialiased arcs and polylines per enemy per frame.
## Overlays that change per frame stay vector (EnemyRenderer.draw_overlays).
##
## New enemy kinds opt in with register(); kinds nobody registers keep the
## vector path in Arena._draw, so nothing breaks before they do.
const SCALE := 2.0      # baked at 2x, drawn at 1x: smooth edges at subpixel positions
const PADDING := 4.0    # world px per side, so antialiased edges never clip
const BUILTIN_KINDS := ["grunt", "runner", "tank", "elite"]

## key -> {"half": world-px half extent, "paint": Callable(canvas, at)}
static var _painters: Dictionary = {}

var _regions: Dictionary = {}    # key -> Rect2 in atlas pixels
var _painter_node: Node2D
var _layout_size := -1


static func sprite_key(kind: String, reduced_fx: bool) -> String:
    return kind + ("" if reduced_fx else ":full")


## Bake a body for `kind` in both FX modes. `paint` is called as
## paint.call(canvas, at, kind, reduced_fx) and must draw only static shapes
## that fit within `half_extent` world px of `at`.
static func register(kind: String, half_extent: float, paint: Callable) -> void:
    for reduced in [true, false]:
        _painters[sprite_key(kind, reduced)] = {
            "half": half_extent + PADDING, "paint": paint.bind(kind, reduced)}


static func _ensure_builtin() -> void:
    for kind in BUILTIN_KINDS:
        if not _painters.has(sprite_key(kind, true)):
            register(kind, EnemyRenderer.visual_radius(kind, 0.0), EnemyRenderer.draw_body)


func _init() -> void:
    name = "EnemySpriteCache"
    transparent_bg = true
    disable_3d = true
    render_target_update_mode = SubViewport.UPDATE_DISABLED
    _painter_node = Node2D.new()
    _painter_node.draw.connect(_paint)
    add_child(_painter_node)
    _ensure_builtin()
    _layout()


func has_sprite(kind: String, reduced_fx: bool) -> bool:
    if _layout_size != _painters.size():
        _layout()
    return _regions.has(sprite_key(kind, reduced_fx))


## Draws the cached body centred on `at`. Call has_sprite() first.
func stamp(canvas: CanvasItem, kind: String, at: Vector2, reduced_fx: bool) -> void:
    var key := sprite_key(kind, reduced_fx)
    var region: Rect2 = _regions[key]
    var size: Vector2 = region.size / SCALE
    canvas.draw_texture_rect_region(get_texture(), Rect2(at - size * 0.5, size), region)


func region_of(kind: String, reduced_fx: bool) -> Rect2:
    return _regions.get(sprite_key(kind, reduced_fx), Rect2())


## One row of cells, one per key, sized from each painter's extent.
func _layout() -> void:
    _regions.clear()
    var x := 0.0
    var height := 1.0
    var keys: Array = _painters.keys()
    keys.sort()
    for key in keys:
        var cell: float = ceilf(float(_painters[key]["half"]) * 2.0 * SCALE)
        _regions[key] = Rect2(x, 0.0, cell, cell)
        x += cell + 2.0
        height = maxf(height, cell)
    size = Vector2i(int(maxf(1.0, x)), int(height))
    _layout_size = _painters.size()
    _painter_node.queue_redraw()
    render_target_update_mode = SubViewport.UPDATE_ONCE


func _paint() -> void:
    for key in _regions:
        var region: Rect2 = _regions[key]
        _painter_node.draw_set_transform(region.get_center(), 0.0, Vector2.ONE * SCALE)
        _painters[key]["paint"].call(_painter_node, Vector2.ZERO)
    _painter_node.draw_set_transform(Vector2.ZERO)
