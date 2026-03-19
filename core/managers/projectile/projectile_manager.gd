class_name ProjectileManager extends Node2D

@export var bullet_scene: PackedScene

func create_bullet(pos: Vector2, angle: float) -> void:
	var bullet = bullet_scene.instantiate() as Bullet
	bullet.setup(pos, angle)
	add_child(bullet)

func connect_tower(tower: Tower) -> void:
	tower.shot.connect(create_bullet)
