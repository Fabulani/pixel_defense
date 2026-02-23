class_name EnemySpawner extends Node2D

signal spawning_phase_complete

@export var wave_data_array: Array[PackedScene] = []
@export var default_spawn_delay : float = 1.0

@onready var enemy_spawn_timer: Timer = $EnemySpawnTimer

var current_spawn_delay : float = 0.0
var current_data_index : int = 0

var pathfinding : PathfindingManager
var target_pos : Vector2

func _ready() -> void:
	current_spawn_delay = default_spawn_delay
	enemy_spawn_timer.wait_time = current_spawn_delay
	enemy_spawn_timer.start()

func spawn_entity() -> void:
	if current_data_index >= wave_data_array.size():
		enemy_spawn_timer.stop()
		spawning_phase_complete.emit()
		return

	var enemy = wave_data_array[current_data_index].instantiate()
	enemy.pathfinding = pathfinding
	enemy.target_pos = target_pos
	add_child(enemy)
	enemy.add_to_group("enemy_group")


func _on_enemy_spawn_timer_timeout() -> void:
	spawn_entity()
	current_data_index += 1
