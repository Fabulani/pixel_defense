class_name TurretComponent extends Node2D

## Indicate that a projectile should be spawned.
signal shot(origin: Vector2, angle: float)

@export var recoil_return_time: float = 0.1  ## Seconds the cannon takes to slide back after a shot
@export var idle_delay: float = 1.0  ## Seconds without a target before the cannon starts sweeping
@export var idle_sweep_angle: float = 45.0  ## Degrees the idle sweep swings to each side of the last aim angle
@export var idle_sweep_speed: float = 31.5  ## Idle sweep turn speed in degrees per second, same for every tower

var _targets: Array[Enemy] = []
var _recoil_distance: float = 0.0
var _recoil_tween: Tween = null
var _squash_tween: Tween = null
var _turret_scale: Vector2 = Vector2.ONE  ## Scale the cannon sprite is meant to have
var _bullet_speed: float = 500.0  ## Projectile speed in px/s, used to lead targets
var _idle_time: float = 0.0  ## Seconds since the last live target
var _sweep_anchor: float = 0.0  ## Cannon rotation the idle sweep swings around
var _sweep_dir: float = 1.0  ## Current sweep direction, 1 or -1
var _turn_speed: float = 360.0  ## Cannon turn speed in degrees per second
var _aim_tolerance: float = 5.0  ## Max angle in degrees between cannon and a target to fire
var _loaded: bool = false  ## True once the reload timer ran out; the next shot may fire as soon as aimed

@onready var _turret: Sprite2D = %Turret
@onready var _detection_area: Area2D = %DetectionArea
@onready var _detection_shape: CollisionShape2D = %CollisionShape2D
@onready var _reload_timer: Timer = %ReloadTimer

func _ready() -> void:
	_turret_scale = _turret.scale
	_detection_area.body_entered.connect(_on_detection_area_body_entered)
	_detection_area.body_exited.connect(_on_detection_area_body_exited)
	_reload_timer.timeout.connect(_on_reload_timer_timeout)

func _process(delta: float) -> void:
	var target: Enemy = _get_priority_target(_targets)
	if target == null:
		_idle(delta)
		return
	_idle_time = 0.0
	_aim(_lead_point(target), delta)
	if _loaded and _has_target_in_cone():
		_fire()

## Update turret stats with the given TowerStats
func configure(stats: TowerStats) -> void:
	var period: float = 1.0 / stats.shots_per_second
	_turn_speed = stats.turn_speed
	_bullet_speed = stats.bullet_speed
	_aim_tolerance = stats.aim_tolerance
	_reload_timer.wait_time = period
	if not _reload_timer.is_stopped():
		# An upgrade never delays the pending shot. start(time) overwrites wait_time,
		# so restore the period right after; it only applies from the next cycle on.
		_reload_timer.start(minf(_reload_timer.time_left, period))
		_reload_timer.wait_time = period
	_detection_shape.shape.radius = stats.detection_range

## Set the cannon recoil distance in px.
func set_recoil(distance: float) -> void:
	_recoil_distance = distance

## Squash the cannon sprite and let it spring back to its normal scale over [param duration] seconds.
func play_squash(duration: float) -> void:
	if _squash_tween != null:
		_squash_tween.kill()
	_turret.scale = _turret_scale * Vector2(1.3, 0.7)
	_squash_tween = create_tween()
	_squash_tween.tween_property(_turret, "scale", _turret_scale, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Flash the cannon sprite white for [param duration] seconds.
func flash(duration: float) -> void:
	Flash.play(_turret, duration)

## Swap the cannon sprite, its material and its scale. A null texture keeps the current one; a null material clears it.
func set_appearance(texture: Texture2D, sprite_material: Material, sprite_scale: float = 1.0) -> void:
	if texture != null:
		_turret.texture = texture
	_turret.material = sprite_material
	if _squash_tween != null:
		_squash_tween.kill()
	_turret_scale = Vector2(sprite_scale, sprite_scale)
	_turret.scale = _turret_scale

## Return the priority target, or null when no living target is in range. Dying enemies are skipped.
func _get_priority_target(targets: Array[Enemy]) -> Enemy:
	# TODO: implement filters for different target priorization
	for candidate: Variant in targets:
		if not is_instance_valid(candidate):
			continue
		var enemy: Enemy = candidate as Enemy
		if enemy != null and not enemy.is_dying():
			return enemy
	return null

## Count idle time and, after [member idle_delay], swing the cannon around the last aim angle.
func _idle(delta: float) -> void:
	if _idle_time < idle_delay:
		_idle_time += delta
		if _idle_time >= idle_delay:
			_sweep_anchor = _turret.rotation
			_sweep_dir = 1.0
		return
	var goal: float = _sweep_anchor + _sweep_dir * deg_to_rad(idle_sweep_angle)
	_turret.rotation = move_toward(_turret.rotation, goal, deg_to_rad(idle_sweep_speed) * delta)
	if is_equal_approx(_turret.rotation, goal):
		_sweep_dir = -_sweep_dir

## Return where to aim at [param enemy]: its position plus its path velocity times the bullet flight time.
func _lead_point(enemy: Enemy) -> Vector2:
	var pos: Vector2 = enemy.global_position
	if _bullet_speed <= 0.0:
		return pos
	var flight_time: float = _turret.global_position.distance_to(pos) / _bullet_speed
	return pos + enemy.get_path_velocity() * flight_time

## Turn the cannon towards [param pos], at most the configured turn speed times [param delta].
func _aim(pos: Vector2, delta: float) -> void:
	var to_pos: Vector2 = pos - _turret.global_position
	if to_pos.length_squared() < 1.0:
		return
	var desired: float = to_pos.angle() - PI / 2.0 - _turret.get_parent().global_rotation
	_turret.rotation = rotate_toward(_turret.rotation, desired, deg_to_rad(_turn_speed) * delta)

## Return true when any living target lies within the aim tolerance of the cannon's shot direction.
func _has_target_in_cone() -> bool:
	var dir: Vector2 = Vector2.DOWN.rotated(_turret.global_rotation)
	var tolerance: float = deg_to_rad(_aim_tolerance)
	for candidate: Variant in _targets:
		if not is_instance_valid(candidate):
			continue
		var enemy: Enemy = candidate as Enemy
		if enemy == null or enemy.is_dying():
			continue
		var to_enemy: Vector2 = _lead_point(enemy) - _turret.global_position
		if to_enemy.length_squared() < 1.0:
			continue
		if absf(dir.angle_to(to_enemy)) <= tolerance:
			return true
	return false

## Emit [signal shot] along the cannon, kick it, and start reloading.
func _fire() -> void:
	var dir: Vector2 = Vector2.DOWN.rotated(_turret.global_rotation).normalized()
	shot.emit(_turret.global_position + dir, _turret.global_rotation)
	_kick()
	_loaded = false
	_reload_timer.start()

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body is Enemy and body not in _targets:
		_targets.append(body)

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body is Enemy and body in _targets:
		_targets.erase(body)

func _on_reload_timer_timeout() -> void:
	_loaded = true

## Push the cannon back along its local -Y and slide it home. Only the sprite offset changes.
func _kick() -> void:
	if _recoil_tween != null:
		_recoil_tween.kill()
	# Sprite offset is in unscaled sprite space; divide by the cannon scale so the recoil is in real px.
	var scale_y: float = _turret_scale.y if absf(_turret_scale.y) > 0.001 else 1.0
	_turret.offset = Vector2(0.0, -_recoil_distance / scale_y)
	_recoil_tween = create_tween()
	_recoil_tween.tween_property(_turret, "offset", Vector2.ZERO, recoil_return_time) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
