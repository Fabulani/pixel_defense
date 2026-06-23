class_name BuildingManager extends Node

signal tower_built(tower: Tower, cell_position: Vector2i)
signal tower_placement_denied()

@export var level_layer: Level

const _TOWER_SCENE: PackedScene = preload("res://entities/towers/tower.tscn")

var used_tiles: Array[Vector2i] = []


func place_tower(cell_position: Vector2i) -> void:
	if not check_valid_tower_placement(cell_position):
		tower_placement_denied.emit()
		return

	var new_tower: Tower = _TOWER_SCENE.instantiate() as Tower

	if not CurrencyManager.spend(new_tower.stats.cost):
		new_tower.queue_free()
		tower_placement_denied.emit()
		return

	var grid_cell_size: Vector2i = GameData.grid_cell_size
	var cell_size: float = grid_cell_size.x
	var cell_offset: Vector2 = Vector2(cell_size / 2, cell_size / 2)
	new_tower.position = cell_position * cell_size + cell_offset
	add_child(new_tower)
	used_tiles.append(cell_position)
	tower_built.emit(new_tower, cell_position)


func check_valid_tower_placement(cell_position: Vector2i) -> bool:
	if used_tiles.has(cell_position):
		return false

	if not level_layer.is_cell_buildable(cell_position):
		return false

	var grid_cell_size: Vector2i = GameData.grid_cell_size
	var cell_size: float = grid_cell_size.x
	var spawn_cell: Vector2i = Vector2i(level_layer.enemy_spawner.global_position / cell_size)
	var target_cell: Vector2i = Vector2i(level_layer.player_base.global_position / cell_size)
	if PathfindingManager.would_block_path(cell_position, spawn_cell, target_cell):
		return false

	return true
