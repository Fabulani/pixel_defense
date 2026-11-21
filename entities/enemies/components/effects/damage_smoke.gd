## Smoke that rises from a badly damaged [Enemy].
##
## Reads the enemy through [code]owner[/code]. Below [member start_ratio] of max health the smoke
## starts faintly; at [member full_ratio] it is at full density. Polls health every frame, so
## healing (regeneration) fades the smoke away again. The emitter belongs to the enemy
## ([method Enemy.attach_effect]), which releases it on death.
class_name DamageSmoke extends Node

## Health ratio (hp / max hp) below which smoke starts.
@export_range(0.0, 1.0) var start_ratio: float = 0.75
## Health ratio at which the smoke reaches full density.
@export_range(0.0, 1.0) var full_ratio: float = 0.1
@export var max_amount: int = 11
## Share of [member max_amount] that is live right when the smoke starts.
@export_range(0.0, 1.0) var min_amount_ratio: float = 0.15
## Exponent on the intensity; above 1 keeps the smoke faint for longer.
@export var intensity_curve: float = 1.5
@export var lifetime: float = 0.9
@export var color: Color = Color(0.25, 0.25, 0.25, 0.8)
@export var speed_min: float = 4.0
@export var speed_max: float = 10.0
@export var spread_degrees: float = 25.0
@export var particle_scale: float = 1.5
@export var emission_radius: float = 2.0

var _enemy: Enemy
var _emitter: GPUParticles2D
var _active: bool = true


func _ready() -> void:
	_enemy = owner as Enemy
	if _enemy == null:
		push_error("DamageSmoke: owner is not an Enemy; component disabled.")
		return
	_emitter = VfxManager.make_particles(max_amount, lifetime, color, particle_scale)
	_emitter.local_coords = false
	_emitter.visibility_rect = Rect2(-64.0, -64.0, 128.0, 128.0)
	var material := _emitter.process_material as ParticleProcessMaterial
	material.direction = Vector3(0.0, -1.0, 0.0)
	material.spread = spread_degrees
	material.initial_velocity_min = speed_min
	material.initial_velocity_max = speed_max
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = emission_radius
	_enemy.attach_effect(_emitter)
	_enemy.died.connect(_on_enemy_died)


func _process(_delta: float) -> void:
	if not _active or _enemy == null or not is_instance_valid(_emitter):
		return
	if _enemy.is_dying():
		_emitter.emitting = false
		return
	var max_health: float = float(_enemy.stats.max_health)
	var ratio: float = _enemy.health.hp / max_health if max_health > 0.0 else 1.0
	var intensity: float = 0.0
	if not is_equal_approx(start_ratio, full_ratio):
		intensity = clampf(inverse_lerp(start_ratio, full_ratio, ratio), 0.0, 1.0)
	if intensity <= 0.0:
		_emitter.emitting = false
		return
	_emitter.emitting = true
	_emitter.amount_ratio = lerpf(min_amount_ratio, 1.0, pow(intensity, intensity_curve))


func _on_enemy_died(_enemy_died: Enemy) -> void:
	# The enemy now owns the release of the emitter; do not touch it any more.
	_active = false
