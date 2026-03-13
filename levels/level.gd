class_name Level extends Node2D

@export var enemy_spawner: EnemySpawner
@export var wave_manager: WaveManager
@export var projectile_manager: ProjectileManager

@onready var target_pos: Vector2 = $PlayerBase.global_position
@onready var pathfinding_preview: Line2D = $PathfindingPreview

func _ready() -> void:
	# Starting currency
	CurrencyManager.coins = 5
	
	PathfindingManager.setup($TileMapLayer)
	enemy_spawner.target_pos = target_pos
	RenderingServer.set_default_clear_color('dff6f5')
	
	_update_pathfinding_preview()

func _on_building_manager_new_tower_built(tower: Tower, cell_position: Vector2i) -> void:
	PathfindingManager.set_cell_solid(cell_position, true)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.pathfinding.recalculate_path()
	
	tower.shoot.connect(projectile_manager.create_bullet)
	_update_pathfinding_preview()

func _update_pathfinding_preview() -> void:
	var spawn_pos := enemy_spawner.global_position
	@warning_ignore("integer_division")
	var path := PathfindingManager.get_valid_path(
		Vector2i(spawn_pos) / 16, Vector2i(target_pos) / 16
	)
	pathfinding_preview.clear_points()
	for point in path:
		pathfinding_preview.add_point(Vector2(point))

func is_cell_buildable(cell_position: Vector2i) -> bool:
	var tile_data: TileData = $TileMapLayer.get_cell_tile_data(cell_position)
	if tile_data == null:
		return false
	return tile_data.get_custom_data("buildable")
