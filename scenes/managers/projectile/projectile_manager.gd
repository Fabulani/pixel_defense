class_name ProjectileManager extends Node2D

var bullet_scene := preload("res://scenes/projectiles/bullet.tscn")

func create_bullet(pos: Vector2, angle: float) -> void:
	var bullet = bullet_scene.instantiate() as Bullet
	bullet.setup(pos, angle)
	add_child(bullet)
