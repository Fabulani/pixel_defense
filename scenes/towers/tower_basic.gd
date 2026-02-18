extends Tower

func _process(_delta: float) -> void:
	if enemies.size() > 0:
		self.look_at(enemies[0].global_position)
		self.rotation -= PI/2


func _on_reload_timer_timeout() -> void:
	if enemies:
		var dir = Vector2.DOWN.rotated(self.rotation).normalized()
		shoot.emit(position + dir * 8, self.rotation, Data.Bullet.SINGLE)
