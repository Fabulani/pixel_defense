## Periodically multiplies its [Enemy]'s speed for a short burst.
##
## Reads the enemy through [code]owner[/code], or the parent when added at runtime. The first dash comes after a random part of
## [member interval] so groups do not dash in sync. While dashing the sprite is stretched
## along the travel direction. Stops once the enemy is dying.
class_name Dash extends Node

## Seconds between the end of one dash and the start of the next.
@export var interval: float = 2.5
## Seconds a dash lasts.
@export var duration: float = 0.5
## Speed multiplier while dashing.
@export var multiplier: float = 3.0
## Sprite stretch along the travel direction while dashing.
@export var stretch: float = 1.35
@export_group("Trail")
@export var trail_color: Color = Color(1.0, 1.0, 1.0, 0.5)
@export var trail_amount: int = 10
@export var trail_lifetime: float = 0.25

const _SPEED_SOURCE: StringName = &"dash"

var _enemy: Enemy
var _timer: Timer
var _dashing: bool = false
var _trail: GPUParticles2D


func _ready() -> void:
	_enemy = owner as Enemy
	if _enemy == null:
		_enemy = get_parent() as Enemy
	if _enemy == null:
		push_error("Dash: owner and parent are not an Enemy; component disabled.")
		return
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	_trail = VfxManager.make_particles(trail_amount, trail_lifetime, trail_color)
	_trail.local_coords = false
	# Covers the distance travelled while dashing (up to ~180 px/s) over the trail lifetime.
	_trail.visibility_rect = Rect2(-96.0, -96.0, 192.0, 192.0)
	var material := _trail.process_material as ParticleProcessMaterial
	material.spread = 180.0
	material.initial_velocity_min = 0.0
	material.initial_velocity_max = 2.0
	_enemy.attach_effect(_trail)
	_enemy.died.connect(_on_enemy_died)
	# Random phase, and never during the spawn-in tween.
	_timer.start(randf() * interval + _enemy.spawn_duration)


func _on_timer_timeout() -> void:
	if _enemy.is_dying():
		return
	_dashing = not _dashing
	if _dashing:
		_enemy.set_speed_factor(_SPEED_SOURCE, multiplier)
		_enemy.set_stretch(stretch)
		_set_trail_emitting(true)
		_timer.start(duration)
	else:
		_stop_dash()
		_timer.start(interval)


func _on_enemy_died(_enemy_died: Enemy) -> void:
	_timer.stop()
	_stop_dash()
	# The enemy releases the emitter on death; do not touch it any more.
	_trail = null


func _set_trail_emitting(value: bool) -> void:
	if is_instance_valid(_trail):
		_trail.emitting = value


func _stop_dash() -> void:
	_dashing = false
	_set_trail_emitting(false)
	_enemy.clear_speed_factor(_SPEED_SOURCE)
	_enemy.set_stretch(1.0)
