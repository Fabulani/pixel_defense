extends Node

var astar_grid : AStarGrid2D = AStarGrid2D.new()

const OBSTACLE_COST := 255

## Initialize and configure the A* grid from a TileMapLayer.
func setup(tile_map: TileMapLayer) -> void:
	astar_grid.region = tile_map.get_used_rect()
	astar_grid.cell_size = tile_map.tile_set.tile_size
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar_grid.update()
	astar_grid.fill_solid_region(astar_grid.region, false)
	
	# Update pathing weights
	for cell_position in tile_map.get_used_cells():
		var cost = tile_map.get_cell_tile_data(cell_position).get_custom_data_by_layer_id(1)
		if cost == OBSTACLE_COST:
			astar_grid.set_point_solid(cell_position, true)
		else:
			astar_grid.set_point_weight_scale(cell_position, cost)
			
			
## Return a centered world-space path from grid start/end cells.
func get_valid_path(start_position : Vector2i, end_position : Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var cell_offset: Vector2i = astar_grid.cell_size / 2 as Vector2i

	# Offset points to cell centers
	for point in astar_grid.get_point_path(start_position, end_position):
		var current_point : Vector2i = point
		current_point += cell_offset
		path.append(current_point)
	return path

## Return a centered world-space path from world-space start/end positions.
func get_valid_path_world(start_position: Vector2, end_position: Vector2) -> Array[Vector2i]:
	var start_cell := Vector2i(start_position / astar_grid.cell_size)
	var end_cell := Vector2i(end_position / astar_grid.cell_size)
	return get_valid_path(start_cell, end_cell)

## Disables or enables the specified point for pathfinding. For cells, the point is the cell center.
func set_cell_solid(point: Vector2i, solid: bool) -> void:
	astar_grid.set_point_solid(point, solid)

## Check whether disabling a cell would prevent valid paths.
func would_block_path(cell_position: Vector2i, start_position: Vector2i, end_position: Vector2i) -> bool:
	# Temporarily mark cell as solid and check if a path still exists
	var was_solid := astar_grid.is_point_solid(cell_position)
	astar_grid.set_point_solid(cell_position, true)
	var path := astar_grid.get_point_path(start_position, end_position)
	astar_grid.set_point_solid(cell_position, was_solid)
	return path.is_empty()
