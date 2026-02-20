class_name EnemySpawner extends Node2D

signal spawning_phase_complete

@export var wave_data_array : Array = ["Enemy 1", "Enemy 2", "Enemy 3", "Enemy 4"]
@export var default_spawn_delay : float = 1.0

@onready var enemy_spawn_timer: Timer = $EnemySpawnTimer

var current_spawn_delay : float = 0.0
var current_data_index : int = 0

func _ready() -> void:
	current_spawn_delay = default_spawn_delay
	enemy_spawn_timer.wait_time = current_spawn_delay
	enemy_spawn_timer.start()

func spawn_entity() -> void:
	if current_data_index >= wave_data_array.size():
		printerr("Wave index too large")
		enemy_spawn_timer.stop()
		spawning_phase_complete.emit()
		return
		


func _on_enemy_spawn_timer_timeout() -> void:
	spawn_entity()
	current_data_index += 1
