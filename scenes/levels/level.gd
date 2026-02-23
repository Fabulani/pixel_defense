class_name Level extends Node2D

var bullet_scene = preload("res://scenes/bullets/bullet.tscn")

var pathfinding := PathfindingManager.new()

@onready var enemy_spawner = $EnemySpawner
@onready var target_pos = $PlayerBase.global_position

func _ready() -> void:
	pathfinding.setup($TileMapLayer)
	enemy_spawner.pathfinding = pathfinding
	enemy_spawner.target_pos = target_pos

	RenderingServer.set_default_clear_color('dff6f5')
	for tower in $Towers.get_children():
		tower.connect('shoot', create_bullet)

func create_bullet(pos: Vector2, angle: float, bullet_enum: Data.Bullet):
	var bullet = bullet_scene.instantiate()
	bullet.setup(pos, angle, bullet_enum)
	$Bullets.add_child(bullet)
