class_name BuildingManager extends Node

signal new_tower_built(tower: Tower, cell_position: Vector2i)

@export var level_layer: Level

const CELL_SIZE : int = 16
@warning_ignore("integer_division")
const CELL_OFFSET := Vector2i(CELL_SIZE / 2, CELL_SIZE / 2)
const TOWER_GROUP : String = "tower_group"

var used_tiles : Array[Vector2i] = []

func place_tower(cell_position : Vector2i, tower_packed_scene : PackedScene) -> void:
	if not check_valid_tower_placement(cell_position):
		return
	
	var new_tower : Tower = tower_packed_scene.instantiate()
	
	# Check if player can afford the tower
	if not CurrencyManager.spend(new_tower.stats.cost):
		new_tower.queue_free()
		print_debug("Not enough coins")
		return
	
	new_tower.position = cell_position * CELL_SIZE + CELL_OFFSET
	new_tower.add_to_group(TOWER_GROUP)	
	add_child(new_tower)
	used_tiles.append(cell_position)
	new_tower_built.emit(new_tower, cell_position) 

func check_valid_tower_placement(cell_position : Vector2i) -> bool:
	if used_tiles.has(cell_position):
		return false
	if not level_layer.is_cell_buildable(cell_position):
		return false
	
	# Prevent placement if it would block all paths from enemy spawn to base
	# TODO: this should support multiple spawn points and bases
	var spawn_cell := Vector2i(level_layer.enemy_spawner.global_position) / CELL_SIZE
	var target_cell := Vector2i(level_layer.target_pos) / CELL_SIZE
	if PathfindingManager.would_block_path(cell_position, spawn_cell, target_cell):
		print_debug("Cannot build here: would block enemy path")
		return false
	
	return true
