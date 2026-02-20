class_name PathfindingManager extends Node

@export var level_layer : Node2D = null


@onready var tile_map_grid : TileMapLayer = level_layer.get_node("TileMapLayer")

var astar_grid : AStarGrid2D = AStarGrid2D.new()
var path_array : Array[Vector2i] = []

func _ready() -> void:
	setup_astar_grid()
	

func setup_astar_grid() -> void:
	astar_grid.region = tile_map_grid.get_used_rect()
	astar_grid.cell_size = tile_map_grid.tile_set.tile_size
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	
	astar_grid.update()

func update_terrain_movement_values() -> void:
	path_array.clear()
	for cell_position in tile_map_grid.get_used_cells():
		if tile_map_grid.get_cell_tile_data(cell_position).get_custom_data_by_layer_id(1) < 10:
			astar_grid.set_point_weight_scale(cell_position, get_cell_movement_cost(cell_position))
		else:
			# Prevent movement through tiles with movement cost of 10 or higher
			astar_grid.set_point_solid(cell_position, true)
			
func get_valid_path(start_position : Vector2i, end_position : Vector2i) -> Array[Vector2i]:
	path_array.clear()
	
	for point in astar_grid.get_point_path(start_position, end_position):
		var current_point : Vector2i = point
		
		# Center the point
		current_point += astar_grid.cell_size / 2 as Vector2i
		
		path_array.append(current_point)
	return path_array

func get_cell_movement_cost(cell_position : Vector2i) -> int:
	return tile_map_grid.get_cell_tile_data(cell_position).get_custom_data_by_layer_id(1)
