class_name TurretComponent extends Node2D

## Indicate that a projectile should be spawned.
signal shot(origin: Vector2, angle: float)

var _targets: Array[Enemy] = []

@onready var _turret: Sprite2D = %Turret
@onready var _detection_area: Area2D = %DetectionArea
@onready var _detection_shape: CollisionShape2D = %CollisionShape2D
@onready var _reload_timer: Timer = %ReloadTimer

func _ready() -> void:
	_detection_area.body_entered.connect(_on_detection_area_body_entered)
	_detection_area.body_exited.connect(_on_detection_area_body_exited)
	_reload_timer.timeout.connect(_on_reload_timer_timeout)

func _process(_delta: float) -> void:
	if _targets.is_empty():
		return
	var target = _get_priority_target(_targets)
	_aim(target.global_position)

## Update turret stats with the given TowerStats
func configure(stats: TowerStats) -> void:	
	_reload_timer.wait_time = 1.0 / stats.shots_per_second
	_detection_shape.shape.radius = stats.detection_range

## Return the priority target
func _get_priority_target(targets: Array[Enemy]) -> Enemy:
	# TODO: implement filters for different target priorization
	return targets[0]
	
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
	if _targets.is_empty():
		return
	var dir = Vector2.DOWN.rotated(_turret.global_rotation).normalized()
	shot.emit(_turret.global_position + dir, _turret.global_rotation)
