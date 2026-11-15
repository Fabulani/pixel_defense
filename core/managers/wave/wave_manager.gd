class_name WaveManager extends Node

signal wave_started(wave_index: int)
signal wave_done(wave_index: int)
signal all_waves_done

@export var wave_delay: int = 3
@export var enemy_spawner: EnemySpawner
@export var config: WaveConfig

var wave_index: int = 0

@onready var wave_timer: Timer = $WaveTimer


func _ready() -> void:
	wave_timer.timeout.connect(_on_wave_timer_timeout)
	enemy_spawner.spawning_complete.connect(_on_enemy_spawner_spawning_complete)
	enemy_spawner.wave_cleared.connect(_on_enemy_spawner_wave_cleared)


## Spawns the next wave, unless the last one was already sent.
func start_next_wave() -> void:
	wave_timer.stop()

	if wave_index >= config.max_waves:
		# Max wave reached. Stop sending waves.
		return

	var wave: Array[PackedScene] = config.generate(wave_index)
	enemy_spawner.start_spawning(wave)
	wave_index += 1
	wave_started.emit(wave_index)


## Ends the current wave and schedules the next one.
func end_current_wave() -> void:
	wave_done.emit(wave_index)
	wave_timer.start(wave_delay)


## The next wave starts at (spawning_complete + timer_timeout).
func _on_wave_timer_timeout() -> void:
	start_next_wave()


## End current wave as soon as spawning is complete.
func _on_enemy_spawner_spawning_complete() -> void:
	end_current_wave()


## Signal game win if all waves are done.
func _on_enemy_spawner_wave_cleared() -> void:
	if wave_index >= config.max_waves:
		all_waves_done.emit()
