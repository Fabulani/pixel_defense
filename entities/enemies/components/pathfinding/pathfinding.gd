## Add A* pathfinding to an [Enemy] (speed comes from [method Enemy.get_speed]).
##
## Expects a PathfindingManager autoload with the A* implementation.
## Recalculates its path whenever [signal PathfindingManager.grid_changed] is emitted.
class_name Pathfinding extends Node

var _entity: Enemy
var _path: Array[Vector2i] = []
var _path_index: int = 0
## When false the entity stops following its path and ignores grid changes.
var active: bool = true
## When true the first computed path snaps the entity to face it. Set to false before
## add_child() for an entity that keeps its own starting rotation (death spawns).
var snap_to_first_path: bool = true
## Velocity computed from the path in the last move, without knockback. ZERO without a path or when inactive.
var path_velocity: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO:
	set(value):
		if target_position == value:
			return
		target_position = value
		if _entity:
			# Recalculate only if _entity is initialized
			recalculate_path()


func _ready() -> void:
	_entity = owner as Enemy
	PathfindingManager.grid_changed.connect(_on_pathfinding_manager_grid_changed)
	recalculate_path()
	if snap_to_first_path:
		_face_first_path_point()


## Get a new path from the entity current position to the target position.
func recalculate_path() -> void:
	var global_pos: Vector2 = _entity.global_position
	_path = PathfindingManager.get_valid_path_world(global_pos, target_position)
	_path_index = 0


## Move entity along the calculated path, turning at most
## [member EnemyStats.turn_speed] degrees per second towards the path direction.
## [param extra_velocity] is added after the path velocity (rotation is not affected).
func move(delta: float, extra_velocity: Vector2 = Vector2.ZERO) -> void:
	if not active:
		path_velocity = Vector2.ZERO
		return
	_follow_path(delta)
	_entity.velocity += extra_velocity
	_entity.move_and_slide()


## Update the entity velocity and rotation such that it follows the path.
func _follow_path(delta: float) -> void:
	if _path and _path_index < _path.size():
		var global_pos: Vector2 = _entity.global_position
		var direction: Vector2 = global_pos.direction_to(Vector2(_path[_path_index]))
		_entity.velocity = direction * _entity.get_speed()
		if _entity.velocity != Vector2.ZERO:
			_entity.rotation = rotate_toward(
				_entity.rotation, _entity.velocity.angle(), deg_to_rad(_entity.stats.turn_speed) * delta
			)

		if global_pos.distance_to(Vector2(_path[_path_index])) <= 10:
			_path_index += 1
	else:
		_entity.velocity = Vector2.ZERO
	path_velocity = _entity.velocity


## Instantly face the first path point that is not at the entity's own position.
func _face_first_path_point() -> void:
	var global_pos: Vector2 = _entity.global_position
	for cell: Vector2i in _path:
		var point: Vector2 = Vector2(cell)
		if not global_pos.is_equal_approx(point):
			_entity.rotation = global_pos.direction_to(point).angle()
			return


func _on_pathfinding_manager_grid_changed() -> void:
	if not active:
		return
	recalculate_path()
