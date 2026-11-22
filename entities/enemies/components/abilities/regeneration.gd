## Heals its [Enemy] over time once it went a while without taking damage.
##
## Reads the enemy through [code]owner[/code], or the parent when added at runtime. Stops once the enemy is dying.
class_name Regeneration extends Node

## Hit points restored per second.
@export var hp_per_second: float = 2.0
## Seconds without damage before healing starts.
@export var delay_after_hit: float = 1.5
## Seconds between heal ticks.
@export var tick_interval: float = 0.5
@export var flash_color: Color = Color(0.3, 1.0, 0.4)
@export var flash_duration: float = 0.15
@export_group("Plus particles")
@export var plus_amount: int = 3
@export var plus_lifetime: float = 0.6
@export var plus_speed_min: float = 8.0
@export var plus_speed_max: float = 14.0
@export var plus_spread: float = 30.0
@export var plus_emission_radius: float = 4.0

var _enemy: Enemy
var _timer: Timer
var _quiet_time: float = 0.0
var _plus_emitter: GPUParticles2D


func _ready() -> void:
	_enemy = owner as Enemy
	if _enemy == null:
		_enemy = get_parent() as Enemy
	if _enemy == null:
		push_error("Regeneration: owner and parent are not an Enemy; component disabled.")
		return
	_timer = Timer.new()
	_timer.wait_time = tick_interval
	_timer.one_shot = false
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	_plus_emitter = VfxManager.make_particles(plus_amount, plus_lifetime, flash_color, 1.0,
			VfxManager.plus_texture())
	_plus_emitter.local_coords = true
	_plus_emitter.visibility_rect = Rect2(-32.0, -48.0, 64.0, 64.0)
	var material := _plus_emitter.process_material as ParticleProcessMaterial
	material.direction = Vector3(0.0, -1.0, 0.0)
	material.spread = plus_spread
	material.initial_velocity_min = plus_speed_min
	material.initial_velocity_max = plus_speed_max
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = plus_emission_radius
	_enemy.attach_effect(_plus_emitter)
	_enemy.damaged.connect(_on_enemy_damaged)
	_enemy.health_set.connect(_on_enemy_health_set)
	_enemy.died.connect(_on_enemy_died)
	# Added at runtime to an already damaged enemy: start the heal cycle now. A scene-owned
	# component runs before Enemy._ready (hp not initialised yet), so it is skipped.
	if _enemy.is_node_ready() and _enemy.health.hp < float(_enemy.stats.max_health):
		_timer.start()


func _on_enemy_damaged(_amount: float) -> void:
	if _enemy.is_dying():
		return
	_quiet_time = 0.0
	_set_plus_emitting(false)
	_timer.start()


## hp was set directly (debug): start the heal cycle if below max.
func _on_enemy_health_set() -> void:
	if not _enemy.is_dying() and _enemy.health.hp < float(_enemy.stats.max_health) and _timer.is_stopped():
		_timer.start()


func _on_enemy_died(_enemy_died: Enemy) -> void:
	_timer.stop()
	# The enemy releases the emitter on death; do not touch it any more.
	_plus_emitter = null


func _set_plus_emitting(value: bool) -> void:
	if is_instance_valid(_plus_emitter):
		_plus_emitter.emitting = value


func _on_timer_timeout() -> void:
	if _enemy.is_dying():
		_timer.stop()
		return
	_quiet_time += tick_interval
	if _quiet_time < delay_after_hit:
		return
	var before: float = _enemy.health.hp
	_enemy.heal(hp_per_second * tick_interval)
	if _enemy.health.hp > before:
		_enemy.flash(flash_color, flash_duration)
		_set_plus_emitting(true)
	if _enemy.health.hp >= float(_enemy.stats.max_health):
		_set_plus_emitting(false)
		_timer.stop()
