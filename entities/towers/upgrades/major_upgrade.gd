class_name MajorUpgrade extends Resource
## Specialisation a tower picks as its final upgrade.

const _HUE_SWAP_SHADER: Shader = preload("res://entities/towers/hue_swap.gdshader")

@export var icon: Texture2D  ## Icon for the upgrade button
@export var caption: String = ""  ## Short caption shown on the upgrade button
@export var icon_tint: Color = Color(1, 1, 1, 0)  ## Hue for the icon; alpha 0 means no tint
@export var damage_multiplier: float = 1.0
@export var fire_rate_multiplier: float = 1.0
@export var range_multiplier: float = 1.0
@export var turret_texture: Texture2D  ## Replaces the cannon sprite
@export var turret_scale: float = 0.8  ## Scale of the replaced cannon sprite
@export var base_tint: Color = Color(1, 1, 1, 0)  ## Hue for the tower base; alpha 0 means no tint
@export var turret_tint: Color = Color(1, 1, 1, 0)  ## Hue for the cannon; alpha 0 means no tint
@export var bullet_texture: Texture2D  ## Replaces the bullet sprite; null keeps the default
@export var bullet_tint: Color = Color(1, 1, 1, 0)  ## Hue for the bullet; alpha 0 means no tint


## Build a hue-swap material for [param tint], or null when the tint is disabled (alpha 0).
static func make_tint_material(tint: Color) -> ShaderMaterial:
	if tint.a <= 0.0:
		return null
	var material := ShaderMaterial.new()
	material.shader = _HUE_SWAP_SHADER
	material.set_shader_parameter("target_color", tint)
	return material
