class_name Tower extends Node2D

@warning_ignore("unused_signal")
signal shoot(pos: Vector2, direction: float)

@export var stats: TowerStats

var enemies: Array[Node2D] = []

func _on_enemy_detection_area_body_entered(body: Node2D) -> void:
	if body not in enemies:
		enemies.append(body)

func _on_enemy_detection_area_body_exited(body: Node2D):
	if body in enemies:
		enemies.erase(body)
