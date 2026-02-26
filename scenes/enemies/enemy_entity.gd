class_name EnemyEntity extends CharacterBody2D

signal died(enemy: EnemyEntity)

@export var stats: EnemyStats

var path_array : Array[Vector2i] = []
var path_index := 0
var target_pos : Vector2

var health: int


func _ready() -> void:
	health = stats.max_health
	path_array = PathfindingManager.get_valid_path(global_position / 16, target_pos / 16)

func _process(_delta: float) -> void:
	get_path_to_position()
	move_and_slide()

func get_path_to_position() -> void:
	if path_array and path_index < path_array.size():
		var direction : Vector2 = global_position.direction_to(path_array[path_index])
		velocity = direction * stats.movement_speed
		rotation = velocity.angle()
		
		if global_position.distance_to(path_array[path_index]) <= 10:
			path_index += 1
	else:
		velocity = Vector2.ZERO

func recalculate_path() -> void:
	path_array = PathfindingManager.get_valid_path(global_position / 16, target_pos / 16)
	path_index = 0

func hit(damage: int):
	health -= damage
	if health <= 0:
		death()
		
func death() -> void:
	died.emit(self)
	queue_free()
