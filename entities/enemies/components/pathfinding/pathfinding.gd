""" Add Pathfinding capabilities to the owner entity. """

class_name Pathfinding extends Node

var _path: Array[Vector2i] = []
var _path_index := 0
var target_pos := Vector2.ZERO

var _entity: CharacterBody2D

func _ready() -> void:
	_entity = owner as CharacterBody2D
	recalculate_path()

func _follow_path() -> void:
	""" Update the entity velocity and rotation such that it follows the path. """
	if _path and _path_index < _path.size():
		var global_pos: Vector2 = _entity.global_position
		var direction : Vector2 = global_pos.direction_to(_path[_path_index])
		_entity.velocity = direction * _entity.stats.movement_speed
		_entity.rotation = _entity.velocity.angle()

		if global_pos.distance_to(_path[_path_index]) <= 10:
			_path_index += 1
	else:
		_entity.velocity = Vector2.ZERO

func recalculate_path() -> void:
	""" Get a new path from the entity current position to the target position. """
	var global_pos: Vector2 = _entity.global_position
	var grid_size: Vector2 = PathfindingManager.astar_grid.cell_size
	_path = PathfindingManager.get_valid_path(global_pos / PathfindingManager.astar_grid.cell_size, target_pos / grid_size)
	_path_index = 0
	
func move() -> void:
	""" Move entity along the calculated path. """
	_follow_path()
	_entity.move_and_slide()
