class_name Level extends Node2D

@export var player_base: PlayerBase
@export var enemy_spawner: EnemySpawner
@export var wave_manager: WaveManager
@export var projectile_manager: ProjectileManager
@export var pathfinding_preview: Line2D

func _ready() -> void:
	# Starting currency
	CurrencyManager.coins = 5
	
	PathfindingManager.setup($TileMapLayer)
	enemy_spawner.target_position = player_base.global_position
	RenderingServer.set_default_clear_color('dff6f5')
	
	_update_pathfinding_preview()

func _on_building_manager_tower_built(tower: Tower, cell_position: Vector2i) -> void:
	# TODO: move this to PathfindingManager
	PathfindingManager.set_cell_solid(cell_position, true)
	# TODO: research if there is a better way to handle groups other than get_tree()...
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.pathfinding.recalculate_path()
	
	projectile_manager.connect_tower(tower)
	_update_pathfinding_preview()

func _update_pathfinding_preview() -> void:
	""" Calculate a path from the Spawner to the Player Base. """
	var path := PathfindingManager.get_valid_path_world(enemy_spawner.global_position, player_base.global_position)
	pathfinding_preview.clear_points()
	for point in path: 
		pathfinding_preview.add_point(Vector2(point))

func is_cell_buildable(cell_position: Vector2i) -> bool:
	var tile_data: TileData = $TileMapLayer.get_cell_tile_data(cell_position)
	if tile_data == null:
		return false
	return tile_data.get_custom_data("buildable")
