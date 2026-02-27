class_name Level extends Node2D

@export var enemy_spawner: EnemySpawner
@export var wave_manager: WaveManager
@export var projectile_manager: ProjectileManager

@onready var target_pos: Vector2 = $PlayerBase.global_position

func _ready() -> void:
	# Starting currency
	CurrencyManager.coins = 5
	
	PathfindingManager.setup($TileMapLayer)
	enemy_spawner.target_pos = target_pos
	RenderingServer.set_default_clear_color('dff6f5')
	
	wave_manager.all_waves_done.connect(_on_wave_manager_all_waves_done)

func _on_building_manager_new_tower_built(tower: Tower, cell_position: Vector2i) -> void:
	PathfindingManager.set_cell_solid(cell_position, true)
	for enemy in get_tree().get_nodes_in_group("enemy_group"):
		enemy.recalculate_path()
	
	tower.shoot.connect(projectile_manager.create_bullet)

func _on_wave_manager_all_waves_done():
	print_debug("All waves completed! Nice job!")

func is_cell_buildable(cell_position: Vector2i) -> bool:
	var tile_data: TileData = $TileMapLayer.get_cell_tile_data(cell_position)
	if tile_data == null:
		return false
	return tile_data.get_custom_data("buildable")
