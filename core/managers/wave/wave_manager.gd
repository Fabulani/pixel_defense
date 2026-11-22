class_name WaveManager extends Node

signal wave_started(wave_index: int)
## Emitted when the next wave was planned (countdown start, or right before the first wave).
signal wave_planned(plan: WavePlan)
## Countdown to the next wave: seconds left and the current early-call bonus in coins.
## Emitted at countdown start, then at most every 0.1 s, and as (0.0, 0) when it ends or is skipped.
signal countdown_changed(time_left: float, bonus: int)
## Emitted when the player called the next wave early, with the coins paid.
signal early_called(coins: int)
signal all_waves_done
## Emitted when any spawner's alive count changed, with the total over all spawners.
signal alive_count_changed(count: int)

## Seconds between the end of spawning and the next wave (placeholder).
@export var wave_delay: float = 12.0
## Coins per remaining countdown second when calling the next wave early (placeholder).
@export var early_bonus_per_second: float = 0.5
@export var config: WaveConfig
## Seconds between two spawns of the whole wave (first wave).
@export var spawn_delay: float = 1.0
## Subtracted from the spawn delay after each wave whose spawning completed.
@export var spawn_delay_step: float = 0.1
@export var min_spawn_delay: float = 0.3

const COUNTDOWN_EMIT_INTERVAL: float = 0.1

var wave_index: int = 0
## Multiplies the budget of waves planned from now on (1.0 = normal).
var difficulty: float = 1.0
## Multiplies the spawn delay (1.0 = normal); see [method set_spawn_delay_multiplier].
var spawn_delay_multiplier: float = 1.0

var _spawners: Array[EnemySpawner] = []
var _current_spawn_delay: float = 0.0
## Spawners of the running wave that have not finished spawning yet.
var _spawning_count: int = 0
var _is_exiting: bool = false
## Base of the per-wave seeds (the map seed).
var _wave_seed: int = 1
## Template each spawner used in its previous wave (no-repeat rule for special templates).
var _last_templates: Dictionary[EnemySpawner, WaveTemplate] = {}
## Plan of the next wave; spawned as is by [method start_next_wave].
var _next_plan: WavePlan = null
## Seconds until the next [signal countdown_changed] from [method _process].
var _countdown_emit_in: float = 0.0

@onready var wave_timer: Timer = $WaveTimer


func _ready() -> void:
	_current_spawn_delay = maxf(min_spawn_delay, spawn_delay)
	wave_timer.one_shot = true
	wave_timer.timeout.connect(_on_wave_timer_timeout)


func _process(delta: float) -> void:
	if wave_timer.is_stopped() or wave_timer.paused:
		return
	_countdown_emit_in -= delta
	if _countdown_emit_in <= 0.0:
		_countdown_emit_in = COUNTDOWN_EMIT_INTERVAL
		countdown_changed.emit(wave_timer.time_left, get_early_bonus())


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
## Every open spawner spawns its own [SpawnerPlan]; the spawners alternate (staggered first delay).
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

	if _next_plan == null:
		_next_plan = _plan_next_wave()
		wave_planned.emit(_next_plan)
	var plan: WavePlan = _next_plan
	_next_plan = null
	var active: Array[EnemySpawner] = _get_active_spawners()
	var count: int = active.size()
	if plan.index != wave_index or plan.spawners.size() != count:
		push_warning("WaveManager: stored plan does not match wave %d; re-planning." % wave_index)
		plan = _plan_next_wave()
		wave_planned.emit(plan)

	_spawning_count = 0
	for k: int in range(count):
		var spawner: EnemySpawner = active[k]
		spawner.set_active(true)
		var sp: SpawnerPlan = plan.spawners[k]
		_last_templates[spawner] = sp.template
		if sp.enemies.is_empty():
			continue
		_spawning_count += 1
		var delay_multiplier: float = sp.template.spawn_delay_multiplier if sp.template != null else 1.0
		spawner.start_spawning(sp.enemies, get_spawn_delay() * count * delay_multiplier, get_spawn_delay() * (k + 1))

	wave_index += 1
	wave_started.emit(wave_index)

	if _spawning_count == 0:
		_on_all_spawning_complete()


## Whether [method call_next_wave] would start a wave now (only while the countdown runs).
func can_call_next_wave() -> bool:
	return not wave_timer.is_stopped() and _spawning_count == 0 and wave_index < config.max_waves and not _is_exiting


## Coins paid for calling the next wave now; 0 when no countdown runs.
func get_early_bonus() -> int:
	if wave_timer.is_stopped():
		return 0
	return floori(wave_timer.time_left * early_bonus_per_second)


## Starts the next wave now and pays the early bonus. No-op unless [method can_call_next_wave].
func call_next_wave() -> void:
	if not can_call_next_wave():
		return
	var bonus: int = get_early_bonus()
	wave_timer.stop()
	if bonus > 0:
		CurrencyManager.earn(bonus)
	early_called.emit(bonus)
	countdown_changed.emit(0.0, 0)
	start_next_wave()


## Ends the current wave: plans the next one and starts the countdown (none after the last wave).
func end_current_wave() -> void:
	if wave_index >= config.max_waves:
		countdown_changed.emit(0.0, 0)
		return
	_next_plan = _plan_next_wave()
	wave_planned.emit(_next_plan)
	wave_timer.start(wave_delay)
	_countdown_emit_in = COUNTDOWN_EMIT_INTERVAL
	countdown_changed.emit(wave_timer.time_left, get_early_bonus())


## Sets [member difficulty]; re-plans a plan already made.
func set_difficulty(value: float) -> void:
	difficulty = maxf(0.0, value)
	_replan_next()


## Pauses or resumes the next-wave countdown.
func set_countdown_paused(paused: bool) -> void:
	wave_timer.paused = paused


## Sets [member spawn_delay_multiplier] (clamped to > 0). Spawners still spawning pick it up from
## their next enemy.
func set_spawn_delay_multiplier(m: float) -> void:
	spawn_delay_multiplier = maxf(0.001, m)
	var count: int = _get_active_spawners().size()
	for spawner: EnemySpawner in _spawners:
		if not is_instance_valid(spawner) or not spawner.is_spawning():
			continue
		var template: WaveTemplate = _last_templates.get(spawner)
		var multiplier: float = template.spawn_delay_multiplier if template != null else 1.0
		spawner.set_spawn_delay(get_spawn_delay() * count * multiplier)


## Spawn delay for new spawning: the stepped delay times [member spawn_delay_multiplier].
func get_spawn_delay() -> float:
	return _current_spawn_delay * spawn_delay_multiplier


## Base of the per-wave seeds (the map seed).
func get_wave_seed() -> int:
	return _wave_seed


## The next wave started or planned is [param index] (0-based, clamped to the valid waves).
## A running wave is not touched; a stored plan is re-made.
func skip_to_wave(index: int) -> void:
	var was_finished: bool = wave_index >= config.max_waves
	wave_index = clampi(index, 0, maxi(0, config.max_waves - 1))
	_replan_next()
	# After the last wave no plan or countdown exists: restart the flow from the new index.
	if was_finished and _spawning_count == 0:
		end_current_wave()


## Re-makes the stored plan (if any) for the current wave index and difficulty.
func _replan_next() -> void:
	if _next_plan == null:
		return
	_next_plan = _plan_next_wave()
	wave_planned.emit(_next_plan)


## Generates the plan of the upcoming wave for its open spawners.
func _plan_next_wave() -> WavePlan:
	var active: Array[EnemySpawner] = _get_active_spawners()
	var last_templates: Array[WaveTemplate] = []
	for spawner: EnemySpawner in active:
		last_templates.append(_last_templates.get(spawner))
	return config.generate(wave_index, WaveConfig.make_rng(_wave_seed, wave_index), active.size(), last_templates, difficulty)


func _get_active_spawners() -> Array[EnemySpawner]:
	return get_spawners_open_at(wave_index)


## Spawners open at wave [param index]; all of them if none is.
func get_spawners_open_at(index: int) -> Array[EnemySpawner]:
	var active: Array[EnemySpawner] = []
	for spawner: EnemySpawner in _spawners:
		if spawner.first_wave <= index:
			active.append(spawner)
	if active.is_empty() and not _spawners.is_empty():
		push_warning("WaveManager: no spawner is open for wave %d; using all." % index)
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
	countdown_changed.emit(0.0, 0)
	start_next_wave()


## End current wave as soon as every spawner is done spawning.
func _on_enemy_spawner_spawning_complete() -> void:
	_spawning_count = maxi(0, _spawning_count - 1)
	if _spawning_count == 0:
		_on_all_spawning_complete()


func _on_enemy_spawner_alive_count_changed(_count: int) -> void:
	alive_count_changed.emit(_get_alive_total())
	_check_cleared()
