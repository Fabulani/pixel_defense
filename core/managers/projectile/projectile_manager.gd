class_name ProjectileManager extends Node2D

@export var bullet_scene: PackedScene

func create_bullet(data: ProjectileData) -> void:
	var bullet = bullet_scene.instantiate() as Bullet
	bullet.setup(data)
	add_child(bullet)

func connect_tower(tower: Tower) -> void:
	tower.shot.connect(create_bullet)
