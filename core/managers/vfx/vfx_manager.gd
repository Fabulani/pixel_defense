class_name VfxManager extends Node2D
## Plays one-shot visual effects in world space. Main wires game signals to these methods.

const _FONT: FontFile = preload("res://ui/themes/default/Kenney Mini.ttf")
## Extra seconds after the particle lifetime before the safety free kicks in.
const _SAFETY_MARGIN: float = 0.5
## Same label scale as the tower level number.
const _POPUP_SCALE: float = 0.2

@export_group("Limits")
@export var max_live_bursts: int = 64
@export var max_live_popups: int = 24

@export_group("Muzzle")
@export var muzzle_amount: int = 4
@export var muzzle_lifetime: float = 0.1
@export var muzzle_cone_degrees: float = 35.0
@export var muzzle_speed_min: float = 40.0
@export var muzzle_speed_max: float = 80.0

@export_group("Impact")
@export var impact_amount: int = 5
@export var impact_lifetime: float = 0.2
@export var impact_cone_degrees: float = 120.0
@export var impact_speed_min: float = 30.0
@export var impact_speed_max: float = 70.0

@export_group("Death")
@export var death_amount: int = 10
@export var death_lifetime: float = 0.35
@export var death_speed_min: float = 25.0
@export var death_speed_max: float = 60.0
@export var death_damping: float = 40.0
@export var death_particle_scale: float = 2.0

@export_group("Tower built")
@export var built_amount: int = 8
@export var built_lifetime: float = 0.3
@export var built_speed_min: float = 15.0
@export var built_speed_max: float = 35.0
@export var built_damping: float = 30.0
@export var built_particle_scale: float = 2.0
@export var built_color: Color = Color(0.85, 0.75, 0.55)

@export_group("Tower upgraded")
@export var upgraded_amount: int = 8
@export var upgraded_lifetime: float = 0.45
@export var upgraded_cone_degrees: float = 60.0
@export var upgraded_speed_min: float = 20.0
@export var upgraded_speed_max: float = 45.0
@export var upgraded_color: Color = Color(1.0, 0.95, 0.6)

@export_group("Coin pop-up")
@export var popup_rise: float = 10.0
@export var popup_duration: float = 0.6
@export var popup_start_offset: float = 3.0
@export var popup_color: Color = Color(1.0, 0.85, 0.2)

## Cached 1x1 white texture, created on first use.
static var _pixel_texture: Texture2D = null
## Cached white-to-transparent ramp applied to every emitter.
static var _fade_ramp: GradientTexture1D = null

var _live_bursts: int = 0
var _live_popups: int = 0


func _ready() -> void:
	# Bursts and pop-ups keep playing behind the pause-time end screen.
	process_mode = Node.PROCESS_MODE_ALWAYS


## Play the muzzle flash at [param origin], pointing along [param angle] (bullet rotation).
func play_muzzle(origin: Vector2, angle: float, color: Color) -> void:
	_spawn_burst(origin, muzzle_amount, muzzle_lifetime, color, 1.0, Vector2.DOWN.rotated(angle),
			muzzle_cone_degrees, muzzle_speed_min, muzzle_speed_max, 0.0)


## Play the impact burst at [param hit_position]; [param direction] is the bullet travel direction.
func play_impact(hit_position: Vector2, direction: Vector2, color: Color) -> void:
	_spawn_burst(hit_position, impact_amount, impact_lifetime, color, 1.0, -direction,
			impact_cone_degrees, impact_speed_min, impact_speed_max, 0.0)


## Play the death burst at [param death_position].
func play_death(death_position: Vector2, color: Color) -> void:
	_spawn_burst(death_position, death_amount, death_lifetime, color, death_particle_scale, Vector2.UP,
			180.0, death_speed_min, death_speed_max, death_damping)


## Show a floating "+coins" pop-up at [param world_position].
func play_coin_popup(world_position: Vector2, coins: int) -> void:
	if coins <= 0 or _live_popups >= max_live_popups:
		return
	var label := Label.new()
	label.text = "+%d" % coins
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.scale = Vector2(_POPUP_SCALE, _POPUP_SCALE)
	label.add_theme_font_override("font", _FONT)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", popup_color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.size = label.get_minimum_size()
	var start: Vector2 = world_position - Vector2(label.size.x * _POPUP_SCALE * 0.5,
			popup_start_offset + label.size.y * _POPUP_SCALE)
	label.position = start
	_live_popups += 1
	label.tree_exited.connect(_on_popup_tree_exited)
	add_child(label)
	var tween: Tween = label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", start.y - popup_rise, popup_duration)
	tween.tween_property(label, "modulate:a", 0.0, popup_duration)
	tween.chain().tween_callback(label.queue_free)


## Play the effect for a freshly built tower at [param world_position].
func play_tower_built(world_position: Vector2) -> void:
	_spawn_burst(world_position, built_amount, built_lifetime, built_color, built_particle_scale, Vector2.UP,
			180.0, built_speed_min, built_speed_max, built_damping)


## Play the effect for an upgraded tower at [param world_position].
func play_tower_upgraded(world_position: Vector2) -> void:
	_spawn_burst(world_position, upgraded_amount, upgraded_lifetime, upgraded_color, 1.0, Vector2.UP,
			upgraded_cone_degrees * 0.5, upgraded_speed_min, upgraded_speed_max, 0.0)


## Spawn a one-shot burst. [param cone_degrees] is the half-angle ([code]spread[/code]) around [param direction].
## Silently dropped when [member max_live_bursts] is reached.
func _spawn_burst(burst_position: Vector2, amount: int, lifetime: float, color: Color, particle_scale: float,
		direction: Vector2, spread_degrees: float, speed_min: float, speed_max: float, damping: float) -> void:
	if _live_bursts >= max_live_bursts or not is_inside_tree():
		return
	var particles: GPUParticles2D = make_particles(amount, lifetime, color, particle_scale)
	var material := particles.process_material as ParticleProcessMaterial
	material.direction = Vector3(direction.x, direction.y, 0.0)
	material.spread = spread_degrees
	material.initial_velocity_min = speed_min
	material.initial_velocity_max = speed_max
	material.damping_min = damping
	material.damping_max = damping
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.position = burst_position
	_live_bursts += 1
	particles.tree_exited.connect(_on_burst_tree_exited)
	particles.finished.connect(particles.queue_free)
	add_child(particles)
	particles.emitting = true
	# Safety net in case `finished` never fires; keeps running while the tree is paused.
	get_tree().create_timer(lifetime + _SAFETY_MARGIN, true).timeout.connect(_free_if_valid.bind(particles))


## Untyped on purpose: a typed Node parameter errors when the bound node is already freed.
func _free_if_valid(node: Variant) -> void:
	if is_instance_valid(node) and not (node as Node).is_queued_for_deletion():
		(node as Node).queue_free()


func _on_burst_tree_exited() -> void:
	_live_bursts = maxi(_live_bursts - 1, 0)


func _on_popup_tree_exited() -> void:
	_live_popups = maxi(_live_popups - 1, 0)


## Create a configured, not yet added particle emitter (1 px particles, no gravity, nearest filtering).
## Callers set direction, spread, velocity, one_shot and emitting afterwards.
## This is the only place in the project that constructs particle nodes,
## so swapping to CPUParticles2D later is a one-function change.
static func make_particles(amount: int, lifetime: float, color: Color, particle_scale: float = 1.0) -> GPUParticles2D:
	if _pixel_texture == null:
		var image: Image = Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		_pixel_texture = ImageTexture.create_from_image(image)
	if _fade_ramp == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
		gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
		_fade_ramp = GradientTexture1D.new()
		_fade_ramp.gradient = gradient
	var material := ParticleProcessMaterial.new()
	material.color_ramp = _fade_ramp
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
