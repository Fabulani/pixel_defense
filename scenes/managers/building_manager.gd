class_name BuildingManager extends Node

signal new_tower_built(tower: Tower, cell_position: Vector2i)

@export var level_layer: Level

const IS_BUILDABLE : String = "buildable"
const CELL_SIZE : int = 16
const TOWER_GROUP : String = "tower_group"

var used_tiles : Array[Vector2i] = []
var currency : CurrencyManager

func place_tower(cell_position : Vector2i, tower_packed_scene : PackedScene) -> void:
	if not check_valid_tower_placement(cell_position):
		return
	
	# # TODO: Replace with TowerStats resource when implemented
	# For now, instantiate to check
	# In future, check tower stats resource w/o instantiating
	var new_tower : Tower = tower_packed_scene.instantiate()
	
	# Check if player can afford the tower
	if not currency.spend(new_tower.cost):
		new_tower.queue_free()
		print_debug("Not enough coins")
		return
	
	new_tower.position = cell_position * CELL_SIZE + Vector2i(CELL_SIZE/2, CELL_SIZE/2)
	new_tower.add_to_group(TOWER_GROUP)	
	add_child(new_tower)
	used_tiles.append(cell_position)
	new_tower_built.emit(new_tower, cell_position) 

func check_valid_tower_placement(cell_position : Vector2i) -> bool:
	if used_tiles.has(cell_position):
		return false
		
	var tile_map_layer = level_layer.get_node("TileMapLayer")
	var is_buildable_tile = tile_map_layer.get_cell_tile_data(cell_position).get_custom_data(IS_BUILDABLE)
	return is_buildable_tile
