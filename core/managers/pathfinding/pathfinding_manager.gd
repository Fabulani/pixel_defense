extends Node

## Emitted when a cell's solidity changes and existing paths may be stale.
signal grid_changed

const OBSTACLE_COST: int = 255

var astar_grid: AStarGrid2D = AStarGrid2D.new()


## Initialize and configure the A* grid from a TileMapLayer.
## Builds a fresh grid, so no state leaks across scene reloads.
func setup(tile_map: TileMapLayer) -> void:
	astar_grid = AStarGrid2D.new()
	astar_grid.region = tile_map.get_used_rect()
	astar_grid.cell_size = tile_map.tile_set.tile_size
	GameData.grid_cell_size = tile_map.tile_set.tile_size
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar_grid.update()

	# Mark obstacles solid
	for cell_position: Vector2i in tile_map.get_used_cells():
		var tile_data: TileData = tile_map.get_cell_tile_data(cell_position)
		if tile_data == null:
			continue
		var cost: int = tile_data.get_custom_data("movement_cost")
		# Only obstacles are special; all walkable cells cost the same (no weight scale).
		if cost == OBSTACLE_COST:
			astar_grid.set_point_solid(cell_position, true)


## Convert a world-space position to a grid cell.
func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i((world_position / astar_grid.cell_size).floor())


## Return a centered world-space path from grid start/end cells.
func get_valid_path(start_position: Vector2i, end_position: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var cell_offset: Vector2i = Vector2i(astar_grid.cell_size / 2.0)

	# Offset points to cell centers
	for point: Vector2 in astar_grid.get_point_path(start_position, end_position):
		path.append(Vector2i(point) + cell_offset)
	return path


## Return a centered world-space path from world-space start/end positions.
func get_valid_path_world(start_position: Vector2, end_position: Vector2) -> Array[Vector2i]:
	return get_valid_path(world_to_cell(start_position), world_to_cell(end_position))


## Disables or enables the specified point for pathfinding. For cells, the point is the cell center.
func set_cell_solid(point: Vector2i, solid: bool) -> void:
	astar_grid.set_point_solid(point, solid)
	grid_changed.emit()


## Check whether disabling a cell would prevent valid paths.
func would_block_path(cell_position: Vector2i, start_position: Vector2i, end_position: Vector2i) -> bool:
	# Temporarily mark cell as solid and check if a path still exists
	var was_solid: bool = astar_grid.is_point_solid(cell_position)
	astar_grid.set_point_solid(cell_position, true)
	var path: PackedVector2Array = astar_grid.get_point_path(start_position, end_position)
	astar_grid.set_point_solid(cell_position, was_solid)
	return path.is_empty()
