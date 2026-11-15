class_name VfxManager extends Node2D
## Plays one-shot visual effects in world space. Main wires game signals to these methods.

## Cached 1x1 white texture, created on first use.
static var _pixel_texture: Texture2D = null


## Play the muzzle flash at [param origin], pointing along [param angle] (bullet rotation).
func play_muzzle(_origin: Vector2, _angle: float, _color: Color) -> void:
	pass


## Play the impact burst at [param hit_position]; [param direction] is the bullet travel direction.
func play_impact(_hit_position: Vector2, _direction: Vector2, _color: Color) -> void:
	pass


## Play the death burst at [param death_position].
func play_death(_death_position: Vector2, _color: Color) -> void:
	pass


## Show a floating "+coins" pop-up at [param world_position].
func play_coin_popup(_world_position: Vector2, _coins: int) -> void:
	pass


## Play the effect for a freshly built tower at [param world_position].
func play_tower_built(_world_position: Vector2) -> void:
	pass


## Play the effect for an upgraded tower at [param world_position].
func play_tower_upgraded(_world_position: Vector2) -> void:
	pass


## Create a configured, not yet added particle emitter (1 px particles, no gravity, nearest filtering).
## Callers set direction, spread, velocity, one_shot and emitting afterwards.
## This is the only place in the project that constructs particle nodes,
## so swapping to CPUParticles2D later is a one-function change.
static func make_particles(amount: int, lifetime: float, color: Color, particle_scale: float = 1.0) -> GPUParticles2D:
	if _pixel_texture == null:
		var image: Image = Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		_pixel_texture = ImageTexture.create_from_image(image)
	var material := ParticleProcessMaterial.new()
	material.gravity = Vector3.ZERO
	material.color = color
	material.scale_min = particle_scale
	material.scale_max = particle_scale
	var particles := GPUParticles2D.new()
	particles.amount = amount
	particles.lifetime = lifetime
	particles.process_material = material
	particles.texture = _pixel_texture
	particles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	particles.emitting = false
	particles.one_shot = false
	return particles
