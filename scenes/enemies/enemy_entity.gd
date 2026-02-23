class_name EnemyEntity extends CharacterBody2D

@export var movement_speed : float = 50

var path_array : Array[Vector2i] = []

var pathfinding : PathfindingManager
var target_pos : Vector2


func _ready() -> void:
	path_array = pathfinding.get_valid_path(global_position / 16, target_pos / 16)
	print_debug(path_array)

func _process(_delta: float) -> void:
	get_path_to_position()
	move_and_slide()

func get_path_to_position() -> void:
	if path_array:
		var direction : Vector2 = global_position.direction_to(path_array[0])
		velocity = direction * movement_speed
		
		if global_position.distance_to(path_array[0]) <= 10:
			path_array.remove_at(0)	
	else:
		velocity = Vector2.ZERO

func recalculate_path() -> void:
	path_array = pathfinding.get_valid_path(global_position / 16, target_pos / 16)

# TODO: on_level_changed signal: recalculate_path()
