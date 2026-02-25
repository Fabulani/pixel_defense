class_name WaveManager extends Node

signal wave_done(wave_index: int)
signal all_waves_done

@export var wave_delay : int = 3
@export var enemy_spawner: EnemySpawner

@onready var wave_timer: Timer = $WaveTimer

var enemy_basic = preload("res://scenes/enemies/enemy_entity.tscn")

var waves: Array[Array] = [
	[enemy_basic, enemy_basic, enemy_basic],
	[enemy_basic, enemy_basic, enemy_basic, enemy_basic],
	[enemy_basic, enemy_basic, enemy_basic, enemy_basic, enemy_basic],
]
var wave_index := 0

func _ready():
	wave_timer.timeout.connect(_on_wave_timer_timeout)
	enemy_spawner.spawning_complete.connect(_on_enemy_spawner_spawning_complete)

func start_next_wave() -> void:
	wave_timer.stop()
	
	if wave_index >= waves.size():
		all_waves_done.emit()
		return
			
	enemy_spawner.start_spawning(waves[wave_index])
	wave_index += 1	
	print_debug("Wave %d started" % wave_index)
	
func end_current_wave() -> void:
	wave_done.emit(wave_index)
	wave_timer.start(wave_delay)
	
func _on_wave_timer_timeout() -> void:
	start_next_wave()

func _on_enemy_spawner_spawning_complete() -> void:
	end_current_wave()
