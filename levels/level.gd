class_name Level extends Node2D

signal wave_started(wave_index: int)
signal enemy_count_changed(count: int)
signal lost
signal won
signal bullet_fired(data: ProjectileData)
signal bullet_hit(hit_position: Vector2, direction: Vector2, data: ProjectileData)
signal enemy_died(death_position: Vector2, coins: int, color: Color)

@export var player_base: PlayerBase
@export var enemy_spawners: Array[EnemySpawner] = []
@export var wave_manager: WaveManager
@export var projectile_manager: ProjectileManager
@export var pathfinding_preview: Line2D
## Build the map with the generator instead of using the hand-painted one in the scene.
@export var use_generated_map: bool = true
## Settings of the map generator. Only used when `use_generated_map` is on.
@export var map_config: MapGenConfig

const SPAWNER_SCENE: PackedScene = preload("uid://dbkc22ud4e32")

## Seed of the generated map, 0 for the legacy map.
var map_seed: int = 0

## Number of waves started so far.
var waves_survived: int:
	get:
		return wave_manager.wave_index

## One preview line per spawner; the first is the exported template, the others are copies.
var _preview_lines: Array[Line2D] = []

## Set once the game has been won or lost, so only the first outcome is reported.
var _finished: bool = false

@onready var tile_map_layer: TileMapLayer = $TileMapLayer


func _ready() -> void:
	# Starting currency
	CurrencyManager.coins = 5

	if use_generated_map:
		_generate_map()

	PathfindingManager.setup(tile_map_layer)
	if enemy_spawners.is_empty():
		push_error("Level: no enemy spawners assigned.")
	for spawner: EnemySpawner in enemy_spawners:
		spawner.target_position = player_base.global_position
	RenderingServer.set_default_clear_color('dff6f5')

	wave_manager.wave_started.connect(_on_wave_manager_wave_started)
	wave_manager.all_waves_done.connect(_on_wave_manager_all_waves_done)
	wave_manager.alive_count_changed.connect(_on_wave_manager_alive_count_changed)
	for spawner: EnemySpawner in enemy_spawners:
		spawner.enemy_died.connect(_on_enemy_spawner_enemy_died)
	wave_manager.setup(enemy_spawners)
	projectile_manager.bullet_fired.connect(_on_projectile_manager_bullet_fired)
	projectile_manager.bullet_hit.connect(_on_projectile_manager_bullet_hit)
	player_base.destroyed.connect(_on_player_base_destroyed)
	PathfindingManager.grid_changed.connect(_on_pathfinding_manager_grid_changed)

	_create_preview_lines()
	_update_pathfinding_preview()


## Start the first wave.
func start() -> void:
	wave_manager.start_next_wave()


## Register a freshly built tower: block its cell and hook it to the projectile manager.
func register_tower(tower: Tower, cell_position: Vector2i) -> void:
	PathfindingManager.set_cell_solid(cell_position, true)
	projectile_manager.connect_tower(tower)


## Unregister a sold tower: free its cell for pathfinding again.
func unregister_tower(tower: Tower, cell_position: Vector2i) -> void:
	if tower.shot.is_connected(projectile_manager.create_bullet):
		tower.shot.disconnect(projectile_manager.create_bullet)
	PathfindingManager.set_cell_solid(cell_position, false)


## Whether the tile at the cell allows building.
func is_cell_buildable(cell_position: Vector2i) -> bool:
	var tile_data: TileData = tile_map_layer.get_cell_tile_data(cell_position)
	if tile_data == null:
		return false
	return tile_data.get_custom_data("buildable")


## Whether blocking the cell would cut the path from any spawner (open or not) to the base.
func would_block_path(cell_position: Vector2i) -> bool:
	var target_cell: Vector2i = PathfindingManager.world_to_cell(player_base.global_position)
	for spawner: EnemySpawner in enemy_spawners:
		var spawn_cell: Vector2i = PathfindingManager.world_to_cell(spawner.global_position)
		if PathfindingManager.would_block_path(cell_position, spawn_cell, target_cell):
			return true
	return false


## Seed for the next generated map.
func _pick_seed() -> int:
	return randi()


## Replaces the painted map, the base position and the spawners with a generated map.
func _generate_map() -> void:
	map_seed = _pick_seed()
	var config: MapGenConfig = map_config
	if config == null:
		push_error("Level: map_config is not assigned, using default settings.")
		config = MapGenConfig.new()
	var data: MapData = MapGenerator.generate(config, map_seed)
	tile_map_layer.clear()
	MapPainter.paint(tile_map_layer, data)
	player_base.position = tile_map_layer.map_to_local(data.base_cell)

	var insert_at: int = wave_manager.get_index()
	for old_spawner: EnemySpawner in enemy_spawners:
		old_spawner.queue_free()
	enemy_spawners.clear()
	for i: int in data.spawner_cells.size():
		var spawner: EnemySpawner = SPAWNER_SCENE.instantiate() as EnemySpawner
		spawner.first_wave = data.spawner_first_waves[i]
		spawner.position = tile_map_layer.map_to_local(data.spawner_cells[i])
		add_child(spawner)
		move_child(spawner, insert_at + i)
		enemy_spawners.append(spawner)
	print("Map seed: %d" % map_seed)


## Makes one preview line per spawner: copies of the template, placed right after it.
func _create_preview_lines() -> void:
	_preview_lines.clear()
	_preview_lines.append(pathfinding_preview)
	var previous: Line2D = pathfinding_preview
	for i: int in range(1, enemy_spawners.size()):
		var line: Line2D = pathfinding_preview.duplicate() as Line2D
		pathfinding_preview.get_parent().add_child(line)
		pathfinding_preview.get_parent().move_child(line, previous.get_index() + 1)
		_preview_lines.append(line)
		previous = line


## Calculate a path from each spawner to the Player Base.
## Lines of spawners that are not open yet are hidden.
func _update_pathfinding_preview() -> void:
	if enemy_spawners.is_empty():
		pathfinding_preview.visible = false
		return
	for i: int in range(mini(_preview_lines.size(), enemy_spawners.size())):
		var spawner: EnemySpawner = enemy_spawners[i]
		var line: Line2D = _preview_lines[i]
		line.visible = spawner.is_active()
		line.clear_points()
		var path: Array[Vector2i] = PathfindingManager.get_valid_path_world(spawner.global_position, player_base.global_position)
		for point: Vector2i in path:
			line.add_point(Vector2(point))


func _on_wave_manager_wave_started(wave_index: int) -> void:
	_update_pathfinding_preview()
	wave_started.emit(wave_index)


func _on_wave_manager_all_waves_done() -> void:
	# Also guards against the wave being "cleared" by enemies freed during scene teardown.
	if _finished or not is_inside_tree():
		return
	_finished = true
	won.emit()


func _on_wave_manager_alive_count_changed(count: int) -> void:
	enemy_count_changed.emit(count)


func _on_enemy_spawner_enemy_died(death_position: Vector2, coins: int, color: Color) -> void:
	enemy_died.emit(death_position, coins, color)


func _on_projectile_manager_bullet_fired(data: ProjectileData) -> void:
	bullet_fired.emit(data)


func _on_projectile_manager_bullet_hit(hit_position: Vector2, direction: Vector2, data: ProjectileData) -> void:
	bullet_hit.emit(hit_position, direction, data)


func _on_player_base_destroyed() -> void:
	if _finished:
		return
	_finished = true
	lost.emit()


func _on_pathfinding_manager_grid_changed() -> void:
	_update_pathfinding_preview()
