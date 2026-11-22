class_name Level extends Node2D

signal wave_started(wave_index: int)
## Next wave planned (countdown start, or right before the first wave).
signal wave_planned(plan: WavePlan)
## Countdown to the next wave: seconds left and current early-call bonus; (0.0, 0) when it ends.
signal countdown_changed(time_left: float, bonus: int)
## The next wave was called early; [param coins] were paid.
signal early_called(coins: int)
signal enemy_count_changed(count: int)
## The player base was hit (also in god mode).
signal base_damaged(amount: int)
signal lost
signal won
signal bullet_fired(data: ProjectileData)
signal bullet_hit(hit_position: Vector2, direction: Vector2, data: ProjectileData)
signal enemy_died(death_position: Vector2, coins: int, color: Color)
signal armor_deflected(hit_position: Vector2)

@export var player_base: PlayerBase
@export var enemy_spawners: Array[EnemySpawner] = []
@export var wave_manager: WaveManager
@export var projectile_manager: ProjectileManager
@export var pathfinding_preview: Line2D
## Settings of the map generator.
@export var map_config: MapGenConfig

const SPAWNER_SCENE: PackedScene = preload("uid://dbkc22ud4e32")
## Rings searched around a debug spawn position for a walkable cell.
const DEBUG_SEARCH_RADIUS: int = 8

## Seed of the generated map (>= 1 once the level is ready).
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

	_generate_map()
	GameData.map_seed = map_seed

	PathfindingManager.setup(tile_map_layer)
	if enemy_spawners.is_empty():
		push_error("Level: no enemy spawners assigned.")
	for spawner: EnemySpawner in enemy_spawners:
		spawner.target_position = player_base.global_position
	RenderingServer.set_default_clear_color('dff6f5')

	wave_manager.wave_started.connect(_on_wave_manager_wave_started)
	wave_manager.wave_planned.connect(_on_wave_manager_wave_planned)
	wave_manager.countdown_changed.connect(_on_wave_manager_countdown_changed)
	wave_manager.early_called.connect(_on_wave_manager_early_called)
	wave_manager.all_waves_done.connect(_on_wave_manager_all_waves_done)
	wave_manager.alive_count_changed.connect(_on_wave_manager_alive_count_changed)
	for spawner: EnemySpawner in enemy_spawners:
		spawner.enemy_died.connect(_on_enemy_spawner_enemy_died)
		spawner.enemy_armor_deflected.connect(_on_enemy_spawner_enemy_armor_deflected)
	wave_manager.setup(enemy_spawners, map_seed)
	projectile_manager.bullet_fired.connect(_on_projectile_manager_bullet_fired)
	projectile_manager.bullet_hit.connect(_on_projectile_manager_bullet_hit)
	player_base.destroyed.connect(_on_player_base_destroyed)
	player_base.damaged.connect(base_damaged.emit)
	PathfindingManager.grid_changed.connect(_on_pathfinding_manager_grid_changed)

	_create_preview_lines()
	_update_pathfinding_preview()


## Start the first wave.
func start() -> void:
	wave_manager.start_next_wave()


## Calls the next wave early while the countdown runs (pays the bonus); no-op otherwise.
func call_next_wave() -> void:
	wave_manager.call_next_wave()


## Debug: the base takes no damage (enemies reaching it are still freed).
func set_god_mode(enabled: bool) -> void:
	player_base.invulnerable = enabled


## Number of waves in a run ([member WaveConfig.max_waves]).
func get_max_waves() -> int:
	return wave_manager.config.max_waves


## Number of spawners, open or not.
func get_spawner_count() -> int:
	return enemy_spawners.size()


## Live enemies (group "enemies", not dying).
func get_enemies() -> Array[Enemy]:
	var result: Array[Enemy] = []
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy: Enemy = node as Enemy
		if enemy != null and not enemy.is_dying():
			result.append(enemy)
	return result


## Debug: spawns [param count] enemies of [param scene] at spawner [param spawner_index].
func debug_spawn_enemies(scene: PackedScene, count: int, spawner_index: int) -> Array[Enemy]:
	if spawner_index < 0 or spawner_index >= enemy_spawners.size():
		push_warning("Level: no spawner with index %d." % spawner_index)
		return []
	var spawner: EnemySpawner = enemy_spawners[spawner_index]
	return _spawn_extra(spawner, scene, count, spawner.global_position)


## Debug: spawns [param count] enemies of [param scene] at the walkable cell nearest to [param world_position].
func debug_spawn_enemies_at(scene: PackedScene, count: int, world_position: Vector2) -> Array[Enemy]:
	var center: Vector2i = PathfindingManager.world_to_cell(world_position)
	var cell_size: Vector2 = Vector2(GameData.grid_cell_size)
	var found: bool = false
	var best_cell: Vector2i = center
	if _is_walkable(center):
		found = true
	else:
		for radius: int in range(1, DEBUG_SEARCH_RADIUS + 1):
			var best_distance: float = INF
			for x: int in range(center.x - radius, center.x + radius + 1):
				for y: int in range(center.y - radius, center.y + radius + 1):
					if maxi(absi(x - center.x), absi(y - center.y)) != radius:
						continue
					var cell := Vector2i(x, y)
					var distance: float = (Vector2(cell) * cell_size + cell_size / 2.0).distance_squared_to(world_position)
					if distance < best_distance and _is_walkable(cell):
						best_distance = distance
						best_cell = cell
						found = true
			if found:
				break
	if not found:
		push_warning("Level: no walkable cell near %s." % world_position)
		return []
	var spawn_position: Vector2 = Vector2(best_cell) * cell_size + cell_size / 2.0
	var owner_spawner: EnemySpawner = null
	var best: float = INF
	for spawner: EnemySpawner in enemy_spawners:
		var distance: float = spawner.global_position.distance_squared_to(spawn_position)
		if distance < best:
			best = distance
			owner_spawner = spawner
	if owner_spawner == null:
		push_warning("Level: no spawner to own the enemies.")
		return []
	return _spawn_extra(owner_spawner, scene, count, spawn_position)


## Debug: spawns the plan of wave [param index] (0-based) as an extra on top of the running flow.
func debug_spawn_wave(index: int) -> void:
	wave_manager.debug_spawn_wave(index)


## Debug: the next wave started or planned is [param index] (0-based).
func debug_jump_to_wave(index: int) -> void:
	wave_manager.debug_jump_to_wave(index)


## Debug: multiplies the budget of waves planned from now on.
func set_budget_scale(budget: float) -> void:
	wave_manager.set_budget_scale(budget)


## Debug: pauses or resumes the next-wave countdown.
func set_countdown_held(held: bool) -> void:
	wave_manager.set_countdown_held(held)


## Debug: spawn delay (s) used instead of the wave's own, also for spawning in progress; <= 0 turns it off.
func set_spawn_delay_override(delay: float) -> void:
	wave_manager.set_spawn_delay_override(delay)


## Global position of the player base.
func get_base_position() -> Vector2:
	return player_base.global_position


## Register a freshly built tower: block its cell and hook it to the projectile manager.
func register_tower(tower: Tower, cell_position: Vector2i) -> void:
	PathfindingManager.set_cell_solid(cell_position, true)
	projectile_manager.connect_tower(tower)


## Unregister a sold tower: free its cell for pathfinding again.
func unregister_tower(tower: Tower, cell_position: Vector2i) -> void:
	if tower.shot.is_connected(projectile_manager.create_bullet):
		tower.shot.disconnect(projectile_manager.create_bullet)
	PathfindingManager.set_cell_solid(cell_position, false)


## Global pixel rect covered by the used cells of the tile layer.
func get_map_rect() -> Rect2:
	var used: Rect2i = tile_map_layer.get_used_rect()
	var tile_size: Vector2 = Vector2(tile_map_layer.tile_set.tile_size)
	var top_left: Vector2 = tile_map_layer.to_global(tile_map_layer.map_to_local(used.position) - tile_size * 0.5)
	return Rect2(top_left, Vector2(used.size) * tile_size * tile_map_layer.global_scale)


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


## Whether the cell has a tile and is not solid for pathfinding.
func _is_walkable(cell: Vector2i) -> bool:
	if not PathfindingManager.astar_grid.is_in_boundsv(cell):
		return false
	if tile_map_layer.get_cell_tile_data(cell) == null:
		return false
	return not PathfindingManager.astar_grid.is_point_solid(cell)


## Spawns [param count] enemies through [param spawner], each jittered a few px around [param world_position].
func _spawn_extra(spawner: EnemySpawner, scene: PackedScene, count: int, world_position: Vector2) -> Array[Enemy]:
	var result: Array[Enemy] = []
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i: int in range(maxi(0, count)):
		var offset: Vector2 = Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.0, 4.0) if i > 0 else Vector2.ZERO
		var enemy: Enemy = spawner.spawn_extra(scene, world_position + offset)
		if enemy != null:
			result.append(enemy)
	return result


## Seed for the next generated map: the requested one, or a random one.
## A seed is never 0.
func _pick_seed() -> int:
	if GameData.requested_seed >= 1:
		return GameData.requested_seed
	return maxi(1, randi())


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


func _on_wave_manager_wave_planned(plan: WavePlan) -> void:
	wave_planned.emit(plan)


func _on_wave_manager_countdown_changed(time_left: float, bonus: int) -> void:
	countdown_changed.emit(time_left, bonus)


func _on_wave_manager_early_called(coins: int) -> void:
	early_called.emit(coins)


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


func _on_enemy_spawner_enemy_armor_deflected(hit_position: Vector2) -> void:
	armor_deflected.emit(hit_position)


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
