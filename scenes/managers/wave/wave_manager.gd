class_name WaveManager extends Node

signal wave_started(wave_index: int)
signal wave_done(wave_index: int)
signal all_waves_done

@export var wave_delay : int = 3
@export var enemy_spawner: EnemySpawner
@export var base_enemy_count: int = 3
@export var max_waves: int = 20

var enemy_basic = preload("res://scenes/enemies/enemy_entity.tscn")
var enemy_fast = preload("res://scenes/enemies/fast/enemy_fast.tscn")
var enemy_heavy = preload("res://scenes/enemies/heavy/enemy_heavy.tscn")
var wave_index := 0


@export var fast_enemy_wave: int = 5
@export var heavy_enemy_wave: int = 10

@onready var wave_timer: Timer = $WaveTimer

func _ready():
	wave_timer.timeout.connect(_on_wave_timer_timeout)
	enemy_spawner.spawning_complete.connect(_on_enemy_spawner_spawning_complete)
	enemy_spawner.wave_cleared.connect(_on_enemy_spawner_wave_cleared)

func _generate_wave(index: int) -> Array:
	# Using Fibonacci sequence for enemy count for fun.
	var enemy_count := base_enemy_count + _fibonacci(index) * 3
	var wave: Array = []
	wave.resize(enemy_count)
	wave.fill(enemy_basic)
	
	# After wave 5, ~30% will be fast enemies
	if index >= fast_enemy_wave:
		var fast_count := ceili(enemy_count * 0.3)
		for i in range(fast_count):
			wave[randi() % enemy_count] = enemy_fast
	
	# After wave 10, ~20% will be heavy enemies
	if index >= heavy_enemy_wave:
		var heavy_count := ceili(enemy_count * 0.2)
		for i in range(heavy_count):
			wave[randi() % enemy_count] = enemy_heavy
	
	return wave

func _fibonacci(n: int) -> int:
	""" Calculate the nth Fibonacci number. """
	if n <= 0:
		return 0
	var a := 0
	var b := 1
	for i in range(n - 1):
		var temp := a + b
		a = b
		b = temp
	return b

func start_next_wave() -> void:
	wave_timer.stop()
	
	if wave_index >= max_waves:
		# Max wave reached. Stop sending waves.
		return
	
	var wave := _generate_wave(wave_index)
	enemy_spawner.start_spawning(wave)
	wave_index += 1
	wave_started.emit(wave_index)
	print_debug("Wave %d started (%d enemies)" % [wave_index, wave.size()])
	
func end_current_wave() -> void:
	wave_done.emit(wave_index)
	wave_timer.start(wave_delay)
	
func _on_wave_timer_timeout() -> void:
	""" The next wave starts at (spawning_complete + timer_timeout). """
	start_next_wave()

func _on_enemy_spawner_spawning_complete() -> void:
	""" End current wave as soon as spawning is complete. """
	end_current_wave()

func _on_enemy_spawner_wave_cleared() -> void:
	""" Signal game win if all waves are done. """
	if wave_index >= max_waves:
		all_waves_done.emit()
