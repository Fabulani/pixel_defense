class_name PlayerBase extends Area2D

signal game_over

var _health = 1

func _on_body_entered(body: Enemy) -> void:
	# TODO: decouple by checking if entity has a damage method
	if body is Enemy:
		_health -= 1
		body.queue_free()
		if _health <= 0:
			queue_free()
			game_over.emit()
