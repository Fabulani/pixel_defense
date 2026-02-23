class_name BuildingManager extends Node

signal new_tower_built(tower: Tower)

@export var level_layer: Node2D = null

const IS_BUILDABLE : String = "buildable"
const CELL_SIZE : int = 16
const TOWER_GROUP : String = "tower_group"

var used_tiles : Array[Vector2i] = []

func place_tower(cell_position : Vector2i, tower_packed_scene : PackedScene) -> void:
	if not check_valid_tower_placement(cell_position):
		return
		
	var new_tower : Node2D = tower_packed_scene.instantiate()
	new_tower.position = cell_position * CELL_SIZE + Vector2i(CELL_SIZE/2, CELL_SIZE/2)
	new_tower.add_to_group(TOWER_GROUP) 	
	add_child(new_tower)
	new_tower_built.emit(new_tower) 

func check_valid_tower_placement(cell_position : Vector2i) -> bool:
	if used_tiles.has(cell_position):
		return false
		
	var tile_map_layer = level_layer.get_node("TileMapLayer")
	var is_buildable_tile = tile_map_layer.get_cell_tile_data(cell_position).get_custom_data(IS_BUILDABLE)
	return is_buildable_tile
