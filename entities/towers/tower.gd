class_name Tower extends Node2D

signal shoot(pos: Vector2, direction: float)

@export var stats: TowerStats
@export var turret: Sprite2D

var enemies: Array[Node2D] = []

func _process(_delta: float) -> void:
	if enemies.size() > 0:
		turret.look_at(enemies[0].global_position)
		turret.rotation -= PI/2

func _on_enemy_detection_area_body_entered(body: Node2D) -> void:
	if body not in enemies:
		enemies.append(body)

func _on_enemy_detection_area_body_exited(body: Node2D) -> void:
	if body in enemies:
		enemies.erase(body)

func _on_reload_timer_timeout() -> void:
	if enemies:
		var dir = Vector2.DOWN.rotated(turret.rotation).normalized()
		shoot.emit(position + dir * 8, turret.rotation)
