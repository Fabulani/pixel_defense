class_name PlayerBase extends Area2D

var _health = 1

func _on_body_entered(body: EnemyEntity) -> void:
	if body is EnemyEntity:
		_health -= 1
		body.queue_free()
		if _health <= 0:
			queue_free()
			print("Game Over")
