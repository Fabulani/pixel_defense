class_name PlayerBase extends Area2D

var _health = 1

func _on_area_entered(enemy: Enemy) -> void:
	_health -= 1
	enemy.queue_free()
	if _health <= 0:
		queue_free()
		print("Game Over")
