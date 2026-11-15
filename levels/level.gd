class_name Level extends Node2D

signal wave_started(wave_index: int)
signal enemy_count_changed(count: int)
signal lost
signal won

@export var player_base: PlayerBase
@export var enemy_spawner: EnemySpawner
@export var wave_manager: WaveManager
@export var projectile_manager: ProjectileManager
@export var pathfinding_preview: Line2D

## Number of waves started so far.
var waves_survived: int:
	get:
		return wave_manager.wave_index

## Set once the game has been won or lost, so only the first outcome is reported.
var _finished: bool = false

@onready var tile_map_layer: TileMapLayer = $TileMapLayer


func _ready() -> void:
	# Starting currency
	CurrencyManager.coins = 5

	PathfindingManager.setup(tile_map_layer)
	enemy_spawner.target_position = player_base.global_position
	RenderingServer.set_default_clear_color('dff6f5')

	wave_manager.wave_started.connect(_on_wave_manager_wave_started)
	wave_manager.all_waves_done.connect(_on_wave_manager_all_waves_done)
	enemy_spawner.alive_count_changed.connect(_on_enemy_spawner_alive_count_changed)
	player_base.destroyed.connect(_on_player_base_destroyed)
	PathfindingManager.grid_changed.connect(_on_pathfinding_manager_grid_changed)

	_update_pathfinding_preview()


## Start the first wave.
func start() -> void:
	wave_manager.start_next_wave()


## Register a freshly built tower: block its cell and hook it to the projectile manager.
func register_tower(tower: Tower, cell_position: Vector2i) -> void:
	PathfindingManager.set_cell_solid(cell_position, true)
	projectile_manager.connect_tower(tower)


## Whether the tile at the cell allows building.
func is_cell_buildable(cell_position: Vector2i) -> bool:
	var tile_data: TileData = tile_map_layer.get_cell_tile_data(cell_position)
	if tile_data == null:
		return false
	return tile_data.get_custom_data("buildable")


## Whether blocking the cell would cut the path from the spawner to the base.
func would_block_path(cell_position: Vector2i) -> bool:
	var spawn_cell: Vector2i = PathfindingManager.world_to_cell(enemy_spawner.global_position)
	var target_cell: Vector2i = PathfindingManager.world_to_cell(player_base.global_position)
	return PathfindingManager.would_block_path(cell_position, spawn_cell, target_cell)


## Calculate a path from the Spawner to the Player Base.
func _update_pathfinding_preview() -> void:
	var path: Array[Vector2i] = PathfindingManager.get_valid_path_world(enemy_spawner.global_position, player_base.global_position)
	pathfinding_preview.clear_points()
	for point: Vector2i in path:
		pathfinding_preview.add_point(Vector2(point))


func _on_wave_manager_wave_started(wave_index: int) -> void:
	wave_started.emit(wave_index)


func _on_wave_manager_all_waves_done() -> void:
	# Also guards against the wave being "cleared" by enemies freed during scene teardown.
	if _finished or not is_inside_tree():
		return
	_finished = true
	won.emit()


func _on_enemy_spawner_alive_count_changed(count: int) -> void:
	enemy_count_changed.emit(count)


func _on_player_base_destroyed() -> void:
	if _finished:
		return
	_finished = true
	lost.emit()


func _on_pathfinding_manager_grid_changed() -> void:
	_update_pathfinding_preview()
