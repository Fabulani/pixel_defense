## Add A* pathfinding to a CharacterBody2D.
##
## Expects a PathfindingManager autoload with the A* implementation.
## Recalculates its path whenever [signal PathfindingManager.grid_changed] is emitted.
class_name Pathfinding extends Node

var _entity: CharacterBody2D
var _path: Array[Vector2i] = []
var _path_index: int = 0
## When false the entity stops following its path and ignores grid changes.
var active: bool = true
var target_position: Vector2 = Vector2.ZERO:
	set(value):
		if target_position == value:
			return
		target_position = value
		if _entity:
			# Recalculate only if _entity is initialized
			recalculate_path()


func _ready() -> void:
	_entity = owner as CharacterBody2D
	PathfindingManager.grid_changed.connect(_on_pathfinding_manager_grid_changed)
	recalculate_path()


## Get a new path from the entity current position to the target position.
func recalculate_path() -> void:
	var global_pos: Vector2 = _entity.global_position
	_path = PathfindingManager.get_valid_path_world(global_pos, target_position)
	_path_index = 0


## Move entity along the calculated path.
## [param extra_velocity] is added after the path velocity (rotation is not affected).
func move(extra_velocity: Vector2 = Vector2.ZERO) -> void:
	if not active:
		return
	_follow_path()
	_entity.velocity += extra_velocity
	_entity.move_and_slide()


## Update the entity velocity and rotation such that it follows the path.
func _follow_path() -> void:
	if _path and _path_index < _path.size():
		var global_pos: Vector2 = _entity.global_position
		var direction: Vector2 = global_pos.direction_to(Vector2(_path[_path_index]))
		_entity.velocity = direction * _entity.stats.speed
		_entity.rotation = _entity.velocity.angle()

		if global_pos.distance_to(Vector2(_path[_path_index])) <= 10:
			_path_index += 1
	else:
		_entity.velocity = Vector2.ZERO


func _on_pathfinding_manager_grid_changed() -> void:
	if not active:
		return
	recalculate_path()
