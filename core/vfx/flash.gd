class_name Flash extends RefCounted
## Brief flash for sprites (white unless a colour is given), driven by the `flash` and `flash_color` shader uniforms.

const _HIT_FLASH_SHADER: Shader = preload("res://core/vfx/hit_flash.gdshader")
const _TWEEN_META: StringName = &"_flash_tween"
const _TEMP_MATERIAL_META: StringName = &"_flash_temp_material"


## Flash [param sprite] with [param color] (white by default) and fade back over [param duration] seconds.
## Uses the sprite's own ShaderMaterial when it has one (it must expose `flash` and `flash_color` uniforms);
## otherwise a temporary hit_flash material is applied and removed again afterwards.
## Repeated calls restart the flash instead of stacking.
static func play(sprite: CanvasItem, duration: float, color: Color = Color.WHITE) -> void:
	if not is_instance_valid(sprite):
		return

	if sprite.has_meta(_TWEEN_META):
		var running: Variant = sprite.get_meta(_TWEEN_META)
		if running is Tween and (running as Tween).is_valid():
			(running as Tween).kill()

	var temp_material: ShaderMaterial = null
	if sprite.has_meta(_TEMP_MATERIAL_META):
		var existing: Variant = sprite.get_meta(_TEMP_MATERIAL_META)
		if existing is ShaderMaterial and sprite.material == existing:
			temp_material = existing as ShaderMaterial

	var flash_material: ShaderMaterial = null
	if temp_material != null:
		flash_material = temp_material
	elif sprite.material is ShaderMaterial:
		flash_material = sprite.material as ShaderMaterial
	elif sprite.material == null:
		temp_material = ShaderMaterial.new()
		temp_material.shader = _HIT_FLASH_SHADER
		sprite.material = temp_material
		sprite.set_meta(_TEMP_MATERIAL_META, temp_material)
		flash_material = temp_material
	else:
		return

	flash_material.set_shader_parameter("flash_color", color)
	flash_material.set_shader_parameter("flash", 1.0)
	var tween: Tween = sprite.create_tween()
	sprite.set_meta(_TWEEN_META, tween)
	tween.tween_property(flash_material, "shader_parameter/flash", 0.0, duration)
	tween.finished.connect(_on_tween_finished.bind(sprite, temp_material))


static func _on_tween_finished(sprite: CanvasItem, temp_material: ShaderMaterial) -> void:
	if not is_instance_valid(sprite):
		return
	sprite.remove_meta(_TWEEN_META)
	if temp_material != null and sprite.material == temp_material:
		sprite.material = null
		sprite.remove_meta(_TEMP_MATERIAL_META)
