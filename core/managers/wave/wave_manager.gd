class_name WaveManager extends Node

signal wave_started(wave_index: int)
signal wave_done(wave_index: int)
signal all_waves_done
## Emitted when any spawner's alive count changed, with the total over all spawners.
signal alive_count_changed(count: int)

@export var wave_delay: int = 3
@export var config: WaveConfig
## Seconds between two spawns of the whole wave (first wave).
@export var spawn_delay: float = 1.0
## Subtracted from the spawn delay after each wave whose spawning completed.
@export var spawn_delay_step: float = 0.1
@export var min_spawn_delay: float = 0.3

var wave_index: int = 0

var _spawners: Array[EnemySpawner] = []
var _current_spawn_delay: float = 0.0
## Spawners of the running wave that have not finished spawning yet.
var _spawning_count: int = 0
var _is_exiting: bool = false
## Base of the per-wave seeds (the map seed).
var _wave_seed: int = 1

@onready var wave_timer: Timer = $WaveTimer


func _ready() -> void:
	_current_spawn_delay = maxf(min_spawn_delay, spawn_delay)
	wave_timer.timeout.connect(_on_wave_timer_timeout)


func _exit_tree() -> void:
	_is_exiting = true


## Takes over the spawners (called by [Level], after this node's [method Node._ready]).
## [param wave_seed] seeds the wave generation together with the wave index.
func setup(spawners: Array[EnemySpawner], wave_seed: int) -> void:
	_spawners = spawners
	_wave_seed = wave_seed
	for spawner: EnemySpawner in _spawners:
		spawner.set_active(spawner.first_wave <= 0)
		spawner.spawning_complete.connect(_on_enemy_spawner_spawning_complete)
		spawner.alive_count_changed.connect(_on_enemy_spawner_alive_count_changed)


## Spawns the next wave, unless the last one was already sent.
## The enemies are dealt round-robin to the spawners that are open for this wave; the spawners
## alternate, so the whole wave spawns at the pace of one spawner.
func start_next_wave() -> void:
	wave_timer.stop()

	if _spawning_count > 0:
		# A wave is still spawning.
		return

	if wave_index >= config.max_waves:
		# Max wave reached. Stop sending waves.
		return

	if _spawners.is_empty():
		push_error("WaveManager: no spawners; call setup() first.")
		return

	var wave: Array[PackedScene] = config.generate(wave_index, WaveConfig.make_rng(_wave_seed, wave_index)).enemies
	var active: Array[EnemySpawner] = _get_active_spawners()
	var count: int = active.size()

	var shares: Array[Array] = []
	for k: int in range(count):
		shares.append([])
	for i: int in range(wave.size()):
		shares[(i + wave_index) % count].append(wave[i])

	_spawning_count = 0
	for k: int in range(count):
		var spawner: EnemySpawner = active[k]
		spawner.set_active(true)
		var share: Array[PackedScene] = []
		share.assign(shares[k])
		if share.is_empty():
			continue
		_spawning_count += 1
		spawner.start_spawning(share, _current_spawn_delay * count, _current_spawn_delay * (k + 1))

	wave_index += 1
	wave_started.emit(wave_index)

	if _spawning_count == 0:
		_on_all_spawning_complete()


## Ends the current wave and schedules the next one.
func end_current_wave() -> void:
	wave_done.emit(wave_index)
	wave_timer.start(wave_delay)


func _get_active_spawners() -> Array[EnemySpawner]:
	var active: Array[EnemySpawner] = []
	for spawner: EnemySpawner in _spawners:
		if spawner.first_wave <= wave_index:
			active.append(spawner)
	if active.is_empty() and not _spawners.is_empty():
		push_warning("WaveManager: no spawner is open for wave %d; using all." % wave_index)
		active.assign(_spawners)
	return active


func _get_alive_total() -> int:
	var total: int = 0
	for spawner: EnemySpawner in _spawners:
		total += spawner.get_alive_count()
	return total


## Signal game win once the last wave was sent and every enemy is gone.
func _check_cleared() -> void:
	# Enemies leaving the tree during scene teardown must not count as a win.
	if _is_exiting or not is_inside_tree():
		return
	if _spawning_count == 0 and _get_alive_total() == 0 and wave_index >= config.max_waves:
		all_waves_done.emit()


func _on_all_spawning_complete() -> void:
	# Next time, spawn faster. For fun.
	_current_spawn_delay = maxf(min_spawn_delay, _current_spawn_delay - spawn_delay_step)
	end_current_wave()
	_check_cleared()


## The next wave starts at (all spawning complete + timer_timeout).
func _on_wave_timer_timeout() -> void:
	start_next_wave()


## End current wave as soon as every spawner is done spawning.
func _on_enemy_spawner_spawning_complete() -> void:
	_spawning_count = maxi(0, _spawning_count - 1)
	if _spawning_count == 0:
		_on_all_spawning_complete()


func _on_enemy_spawner_alive_count_changed(_count: int) -> void:
	alive_count_changed.emit(_get_alive_total())
	_check_cleared()
