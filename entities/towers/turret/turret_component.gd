class_name TurretComponent extends Node2D

signal shot(pos: Vector2, direction: float)
signal target_acquired(pos: Vector2)

var _targets: Array[Enemy] = []

@onready var _turret: Sprite2D = %Turret
@onready var _detection_area: Area2D = %DetectionArea
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
		
func _get_priority_target(targets: Array[Enemy]) -> Enemy:
	# TODO: implement filters for different target priorization
	return targets[0]
	
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
