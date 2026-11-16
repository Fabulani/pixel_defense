class_name TurretComponent extends Node2D

## Indicate that a projectile should be spawned.
signal shot(origin: Vector2, angle: float)

@export var recoil_return_time: float = 0.1  ## Seconds the cannon takes to slide back after a shot

var _targets: Array[Enemy] = []
var _recoil_distance: float = 0.0
var _recoil_tween: Tween = null
var _squash_tween: Tween = null
var _turret_scale: Vector2 = Vector2.ONE  ## Scale the cannon sprite is meant to have

@onready var _turret: Sprite2D = %Turret
@onready var _detection_area: Area2D = %DetectionArea
@onready var _detection_shape: CollisionShape2D = %CollisionShape2D
@onready var _reload_timer: Timer = %ReloadTimer

func _ready() -> void:
	_turret_scale = _turret.scale
	_detection_area.body_entered.connect(_on_detection_area_body_entered)
	_detection_area.body_exited.connect(_on_detection_area_body_exited)
	_reload_timer.timeout.connect(_on_reload_timer_timeout)

func _process(_delta: float) -> void:
	if _targets.is_empty():
		return
	var target: Enemy = _get_priority_target(_targets)
	if target == null:
		return
	_aim(target.global_position)

## Update turret stats with the given TowerStats
func configure(stats: TowerStats) -> void:
	var period: float = 1.0 / stats.shots_per_second
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

## Rotate turret sprite so it points to given position
func _aim(pos: Vector2) -> void:
	_turret.look_at(pos)
	_turret.rotation -= PI/2

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body is Enemy and body not in _targets:
		_targets.append(body)

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body is Enemy and body in _targets:
		_targets.erase(body)

func _on_reload_timer_timeout() -> void:
	if _get_priority_target(_targets) == null:
		return
	var dir: Vector2 = Vector2.DOWN.rotated(_turret.global_rotation).normalized()
	shot.emit(_turret.global_position + dir, _turret.global_rotation)
	_kick()

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
