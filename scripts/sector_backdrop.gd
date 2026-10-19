class_name SectorBackdrop
extends ColorRect

## Neon pass: the living background of a sector, drawn by one GPU shader.
## The same node backs the arena, the menus (MENU theme) and the small
## SECTORS previews (a cropped view). Uniforms change only on configure();
## animation comes from the shader's TIME, so GDScript does no per-frame work.
const SHADER: Shader = preload("res://shaders/sector_backdrop.gdshader")
const THEMES := ["horizon", "aurora", "rift", "foundry", "radar", "null", "menu"]
const SHAPES := ["crest", "twin", "shelf", "jagged"]
## SECTORS cards show the lower field: the horizon and the theme's motion.
const PREVIEW_VIEW := Rect2(0.0, 640.0, 720.0, 520.0)
## Menu backdrop: deep navy to violet. Cool by the palette rule.
const MENU := {
    "sky_top": Color("#040a22"), "sky_bottom": Color("#1c1150"),
    "horizon": Color("#3D7CFF"), "horizon_core": Color("#A6E9FF"),
    "accent": Color("#7D5CFF"), "shape": "crest", "backdrop": "menu"
}

var _material := ShaderMaterial.new()


func _init() -> void:
    _material.shader = SHADER
    material = _material
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    color = Color.BLACK
    _material.set_shader_parameter("world", GameCatalog.WORLD_SIZE)
    _material.set_shader_parameter("aura_center", ArenaBackground.AURA_CENTER)
    _material.set_shader_parameter("aura_radius", ArenaBackground.AURA_RADIUS)
    _material.set_shader_parameter("aura_color", VisualProfile.GUARDIAN_AURA)
    set_view(Rect2(Vector2.ZERO, GameCatalog.WORLD_SIZE))


static func theme_index(map: Dictionary) -> int:
    return maxi(0, THEMES.find(String(map.get("backdrop", "horizon"))))


static func shape_index(map: Dictionary) -> int:
    return maxi(0, SHAPES.find(String(map.get("shape", "crest"))))


func configure(map: Dictionary, reduced_fx: bool) -> void:
    _material.set_shader_parameter("sky_top", map.get("sky_top", VisualProfile.BACKDROP))
    _material.set_shader_parameter("sky_bottom", map.get("sky_bottom", VisualProfile.BACKDROP_BOTTOM))
    _material.set_shader_parameter("line_color", map.get("horizon", VisualProfile.HORIZON_BLUE))
    _material.set_shader_parameter("core_color", map.get("horizon_core", VisualProfile.HORIZON_CORE))
    _material.set_shader_parameter("accent", map.get("accent", VisualProfile.HORIZON_BLUE))
    _material.set_shader_parameter("theme", theme_index(map))
    _material.set_shader_parameter("shape", shape_index(map))
    _material.set_shader_parameter("low_fx", reduced_fx)


func configure_stage(stage: int, reduced_fx: bool) -> void:
    configure(SectorCatalog.get_map(stage), reduced_fx)


func configure_menu(reduced_fx: bool) -> void:
    configure(MENU, reduced_fx)


func set_view(world_rect: Rect2) -> void:
    _material.set_shader_parameter("view",
        Vector4(world_rect.position.x, world_rect.position.y, world_rect.size.x, world_rect.size.y))


func set_brightness(value: float) -> void:
    _material.set_shader_parameter("brightness", value)


func uniform(key: String) -> Variant:
    return _material.get_shader_parameter(key)
