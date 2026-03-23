class_name BuildingManager extends Node

signal tower_built(tower: Tower, cell_position: Vector2i)
signal tower_placement_denied()

@export var level_layer: Level

var used_tiles : Array[Vector2i] = []

func place_tower(cell_position : Vector2i, tower_packed_scene : PackedScene) -> void:
	if not check_valid_tower_placement(cell_position):
		tower_placement_denied.emit()
		return
	
	var new_tower : Tower = tower_packed_scene.instantiate()
	
	# Check if player can afford the tower
	if not CurrencyManager.spend(new_tower.stats.cost):
		new_tower.queue_free()
		tower_placement_denied.emit()
		return
	
	var cell_size: float = PathfindingManager.astar_grid.cell_size[0]
	var cell_offset := Vector2(cell_size / 2, cell_size / 2)
	new_tower.position = cell_position * cell_size + cell_offset
	add_child(new_tower)
	used_tiles.append(cell_position)
	tower_built.emit(new_tower, cell_position) 

func check_valid_tower_placement(cell_position : Vector2i) -> bool:
	if used_tiles.has(cell_position):
		return false

	if not level_layer.is_cell_buildable(cell_position):
		return false
	
	# Prevent placement if it would block all paths from enemy spawn to base
	# TODO: this should support multiple spawn points and bases
	# TODO: this should be a function. BuildingManager shouldn't need to know about
	# spawners and bases
	var cell_size := PathfindingManager.astar_grid.cell_size[0]
	var spawn_cell := Vector2i(level_layer.enemy_spawner.global_position / cell_size)
	var target_cell := Vector2i(level_layer.player_base.global_position / cell_size)
	if PathfindingManager.would_block_path(cell_position, spawn_cell, target_cell):
		return false
	
	return true
