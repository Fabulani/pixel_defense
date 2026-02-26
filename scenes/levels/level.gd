class_name Level extends Node2D

var pathfinding := PathfindingManager.new()
var currency := CurrencyManager.new()

@export var enemy_spawner: EnemySpawner
@export var wave_manager: WaveManager
@export var projectile_manager: ProjectileManager

@onready var target_pos: Vector2 = $PlayerBase.global_position

func _ready() -> void:
	# Starting currency
	currency.coins = 3
	
	pathfinding.setup($TileMapLayer)
	enemy_spawner.pathfinding = pathfinding
	enemy_spawner.target_pos = target_pos
	enemy_spawner.currency = currency
	RenderingServer.set_default_clear_color('dff6f5')
	
	wave_manager.all_waves_done.connect(_on_wave_manager_all_waves_done)
	
	# Starts the waves
	wave_manager.start_next_wave()

func _on_building_manager_new_tower_built(tower: Tower, cell_position: Vector2i) -> void:
	pathfinding.set_cell_solid(cell_position, true)
	for enemy in get_tree().get_nodes_in_group("enemy_group"):
		enemy.recalculate_path()
	
	tower.shoot.connect(projectile_manager.create_bullet)

func _on_wave_manager_all_waves_done():
	pass
