class_name BuildingManager extends Node

signal tower_built(tower: Tower, cell_position: Vector2i)
signal tower_placement_denied()
signal tower_upgraded(tower: Tower)
signal tower_sold(tower: Tower, cell_position: Vector2i)
signal upgrade_denied()

const _TOWER_SCENE: PackedScene = preload("res://entities/towers/tower.tscn")

@export var level: Level

## Built towers by cell.
var _towers: Dictionary[Vector2i, Tower] = {}


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
	new_tower.total_spent = new_tower.stats.cost
	_towers[cell_position] = new_tower
	tower_built.emit(new_tower, cell_position)


## Tower built on the cell, or null.
func get_tower_at(cell_position: Vector2i) -> Tower:
	return _towers.get(cell_position) as Tower


## Buy the next general upgrade. Emits [signal tower_upgraded] or [signal upgrade_denied].
func upgrade_tower(tower: Tower) -> void:
	if not _is_managed(tower) or tower.is_max_level() or tower.needs_major():
		upgrade_denied.emit()
		return

	var cost: int = tower.next_upgrade_cost()
	if not CurrencyManager.spend(cost):
		upgrade_denied.emit()
		return

	tower.total_spent += cost
	tower.upgrade()
	tower_upgraded.emit(tower)


## Buy a major upgrade (only when [method Tower.needs_major]). Emits [signal tower_upgraded] or [signal upgrade_denied].
func apply_major_upgrade(tower: Tower, major: MajorUpgrade) -> void:
	if not _is_managed(tower) or major == null or not tower.needs_major():
		upgrade_denied.emit()
		return

	var cost: int = tower.next_upgrade_cost()
	if not CurrencyManager.spend(cost):
		upgrade_denied.emit()
		return

	tower.total_spent += cost
	tower.apply_major(major)
	tower_upgraded.emit(tower)


## Remove the tower and refund everything spent on it. Emits [signal tower_sold].
func sell_tower(tower: Tower) -> void:
	if not _is_managed(tower):
		return

	var cell_position: Vector2i = _get_cell_of(tower)
	_towers.erase(cell_position)
	CurrencyManager.earn(tower.total_spent)
	tower_sold.emit(tower, cell_position)
	tower.queue_free()


## A cell is valid when unused, buildable, and not blocking the enemy path.
func check_valid_tower_placement(cell_position: Vector2i) -> bool:
	if _towers.has(cell_position):
		return false
	if not level.is_cell_buildable(cell_position):
		return false
	if level.would_block_path(cell_position):
		return false
	return true


func _is_managed(tower: Tower) -> bool:
	return is_instance_valid(tower) and _towers.find_key(tower) != null


## Cell of a tower known to be managed here (see [method _is_managed]).
func _get_cell_of(tower: Tower) -> Vector2i:
	var key: Variant = _towers.find_key(tower)
	return key as Vector2i
