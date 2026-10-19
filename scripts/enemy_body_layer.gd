class_name EnemyBodyLayer
extends Node2D

## Stamps every cached enemy body from EnemySpriteCache: one texture and one
## material for the whole swarm, so it batches. The atlas holds premultiplied
## colours (it is rendered onto a transparent viewport), hence the PREMULT
## blend. It sits behind Arena's own _draw (show_behind_parent), above the
## glow layer; Arena draws the per-frame overlays on top.
## Pure presentation: reads Arena state, never writes it.
var arena: Arena
## Script time of this layer's _draw (EMA, µs); Arena adds it to its perf line.
var perf_usec := 0.0


func _init() -> void:
    name = "EnemyBodies"
    show_behind_parent = true
    texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    var premult := CanvasItemMaterial.new()
    premult.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
    material = premult


func _draw() -> void:
    if arena == null or arena.state == "idle" or arena.sprite_cache == null:
        return
    var started: int = Time.get_ticks_usec()
    var cache: EnemySpriteCache = arena.sprite_cache
    var reduced: bool = arena.low_fx
    for enemy in arena.enemies:
        var kind: String = String(enemy["kind"])
        if cache.has_sprite(kind, reduced):
            cache.stamp(self, kind, enemy["pos"], reduced)
        var shield: int = int(enemy.get("shield", 0))
        if shield > 0:
            var mark: String = MechanicVisuals.shield_key(kind, shield)
            if cache.has_sprite(mark, reduced):
                cache.stamp(self, mark, enemy["pos"], reduced)
    perf_usec = lerpf(perf_usec, float(Time.get_ticks_usec() - started), 0.05)
