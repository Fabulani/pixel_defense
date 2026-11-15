class_name BuildingManager extends Node

signal tower_built(tower: Tower, cell_position: Vector2i)
signal tower_placement_denied()

const _TOWER_SCENE: PackedScene = preload("res://entities/towers/tower.tscn")

@export var level: Level

var used_tiles: Array[Vector2i] = []


## Try to build a tower on the cell. Emits [signal tower_built] or [signal tower_placement_denied].
func place_tower(cell_position: Vector2i) -> void:
	if not check_valid_tower_placement(cell_position):
		tower_placement_denied.emit()
		return

	var new_tower: Tower = _TOWER_SCENE.instantiate() as Tower

	if not CurrencyManager.spend(new_tower.stats.cost):
		new_tower.queue_free()
		tower_placement_denied.emit()
		return

	var cell_size: Vector2 = Vector2(GameData.grid_cell_size)
	new_tower.position = Vector2(cell_position) * cell_size + cell_size / 2.0
	add_child(new_tower)
	used_tiles.append(cell_position)
	tower_built.emit(new_tower, cell_position)


## A cell is valid when unused, buildable, and not blocking the enemy path.
func check_valid_tower_placement(cell_position: Vector2i) -> bool:
	if used_tiles.has(cell_position):
		return false
	if not level.is_cell_buildable(cell_position):
		return false
	if level.would_block_path(cell_position):
		return false
	return true
