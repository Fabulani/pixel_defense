## Add Pathfinding capabilities to a CharacterBody2D.
##
## Add A* Pathfinding to a CharacterBody2D.
## Expects a PathfindingManager autoload with the A* implementation.

class_name Pathfinding extends Node

var _entity: CharacterBody2D
var _path: Array[Vector2i] = []
var _path_index := 0
var target_position := Vector2.ZERO:
	set(value):
		if target_position == value:
			return
		target_position = value
		if _entity:
			# Recalculate only if _entity is initialized
			recalculate_path()


func _ready() -> void:
	_entity = owner as CharacterBody2D
	recalculate_path()

## Update the entity velocity and rotation such that it follows the path.
func _follow_path() -> void:
	if _path and _path_index < _path.size():
		var global_pos: Vector2 = _entity.global_position
		var direction : Vector2 = global_pos.direction_to(_path[_path_index])
		_entity.velocity = direction * _entity.stats.speed
		_entity.rotation = _entity.velocity.angle()

		if global_pos.distance_to(_path[_path_index]) <= 10:
			_path_index += 1
	else:
		_entity.velocity = Vector2.ZERO

## Get a new path from the entity current position to the target position.
func recalculate_path() -> void:
	var global_pos: Vector2 = _entity.global_position
	_path = PathfindingManager.get_valid_path_world(global_pos, target_position)
	_path_index = 0

## Move entity along the calculated path.
func move() -> void:
	_follow_path()
	_entity.move_and_slide()
