class_name NeonGlowLayer
extends Node2D

## Neon pass: a soft additive bloom under every unit, the Guardian and the
## brightest shots. No post-processing: each glow is one textured quad that
## shares a single 64 px radial texture, so the GL Compatibility renderer
## batches the whole layer. It sits between the backdrop and Arena's own
## drawing (show_behind_parent), so shapes stay crisp on top of their halo.
## Pure presentation: reads Arena state, never writes it.
const TEXTURE_SIZE := 64
## Halo diameter as a multiple of the unit's visual radius.
const UNIT_SPREAD := 5.6
const UNIT_ALPHA := 0.55
const GUARDIAN_GLOW := Color(0.10, 0.55, 1.0, 0.55)
const GUARDIAN_SPREAD := 440.0

static var _texture: Texture2D

var arena: Arena


static func glow_texture() -> Texture2D:
    if _texture == null:
        var gradient := Gradient.new()
        gradient.offsets = PackedFloat32Array([0.0, 0.3, 0.65, 1.0])
        gradient.colors = PackedColorArray([
            Color(1, 1, 1, 1.0), Color(1, 1, 1, 0.62), Color(1, 1, 1, 0.20), Color(1, 1, 1, 0.0)])
        var texture := GradientTexture2D.new()
        texture.gradient = gradient
        texture.fill = GradientTexture2D.FILL_RADIAL
        texture.fill_from = Vector2(0.5, 0.5)
        texture.fill_to = Vector2(1.0, 0.5)
        texture.width = TEXTURE_SIZE
        texture.height = TEXTURE_SIZE
        _texture = texture
    return _texture


func _init() -> void:
    name = "NeonGlow"
    show_behind_parent = true
    var additive := CanvasItemMaterial.new()
    additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
    material = additive


func _draw() -> void:
    if arena == null or arena.state == "idle":
        return
    var texture := glow_texture()
    var pulse: float = 0.9 + 0.1 * sin(arena.visual_clock() * 2.2)
    var guardian := GUARDIAN_GLOW
    guardian.a *= pulse
    _glow(texture, GameCatalog.GUARDIAN, GUARDIAN_SPREAD, guardian)
    for enemy in arena.enemies:
        var kind: String = String(enemy["kind"])
        var radius: float = EnemyRenderer.visual_radius(kind, float(enemy["radius"]))
        var tint: Color = VisualProfile.enemy_tint(kind)
        tint.a = UNIT_ALPHA * (1.6 if float(enemy["flash"]) > 0.0 else 1.0)
        _glow(texture, enemy["pos"], radius * UNIT_SPREAD, tint)
    if arena.low_fx:
        return
    for bullet in arena.projectiles:
        if String(bullet["kind"]) == "rocket":
            _glow(texture, bullet["pos"], 70.0, Color(VisualProfile.COMET_TRAIL, 0.45))
    for fx in arena.effects:
        var kind: String = String(fx["kind"])
        if kind == "nova" or kind == "pop" or kind == "impact" or kind == "flash":
            var life: float = clampf(float(fx["ttl"]) / maxf(0.001, float(fx["duration"])), 0.0, 1.0)
            var color: Color = fx["color"]
            color.a = 0.40 * life
            _glow(texture, fx["a"], maxf(40.0, float(fx["radius"]) * 2.6), color)


func _glow(texture: Texture2D, at: Vector2, diameter: float, tint: Color) -> void:
    var half := Vector2.ONE * diameter * 0.5
    draw_texture_rect(texture, Rect2(at - half, half * 2.0), false, tint)
