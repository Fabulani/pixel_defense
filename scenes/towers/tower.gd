class_name Tower extends Node2D

signal shoot(pos: Vector2, direction: float, bullet_enum: Data.Bullet)

var enemies: Array[Node2D] = []

# TODO: Replace with TowerStats resource when implemented
var cost: int = 3

func _on_enemy_detection_area_body_entered(body: Node2D) -> void:
	if body not in enemies:
		enemies.append(body)

func _on_enemy_detection_area_body_exited(body: Node2D):
	if body in enemies:
		enemies.erase(body)
