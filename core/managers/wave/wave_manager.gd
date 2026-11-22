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
## Debug: multiplies the budget of waves planned from now on.
var budget_scale: float = 1.0

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
## Debug releases of [method debug_spawn_wave]: {spawner, enemies, wait, interval}, independent of the wave queue.
var _debug_releases: Array[Dictionary] = []
## Debug spawn delay override in seconds; 0 = off.
var _spawn_delay_override: float = 0.0

@onready var wave_timer: Timer = $WaveTimer


func _ready() -> void:
	_current_spawn_delay = maxf(min_spawn_delay, spawn_delay)
	wave_timer.one_shot = true
	wave_timer.timeout.connect(_on_wave_timer_timeout)


func _process(delta: float) -> void:
	_process_debug_releases(delta)
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
		spawner.start_spawning(sp.enemies, _effective_spawn_delay() * count * delay_multiplier, _effective_spawn_delay() * (k + 1))

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


## Debug: multiplies the budget of waves planned from now on; re-plans a plan already made.
func set_budget_scale(scale: float) -> void:
	budget_scale = maxf(0.0, scale)
	_replan_next()


## Debug: pauses or resumes the next-wave countdown.
func set_countdown_held(held: bool) -> void:
	wave_timer.paused = held


## Debug: spawn delay (s) used instead of [member spawn_delay] and its per-wave steps; <= 0 turns it
## off. Spawners still spawning pick it up from their next enemy. The normal delay keeps stepping down.
func set_spawn_delay_override(delay: float) -> void:
	_spawn_delay_override = delay
	var count: int = _get_active_spawners().size()
	for spawner: EnemySpawner in _spawners:
		if not is_instance_valid(spawner) or not spawner.is_spawning():
			continue
		var template: WaveTemplate = _last_templates.get(spawner)
		var multiplier: float = template.spawn_delay_multiplier if template != null else 1.0
		spawner.set_spawn_delay(_effective_spawn_delay() * count * multiplier)
	for release: Dictionary in _debug_releases:
		release["interval"] = _effective_spawn_delay() * maxi(1, count)


## Spawn delay for new spawning: the debug override when set, else the current stepped delay.
func _effective_spawn_delay() -> float:
	return _spawn_delay_override if _spawn_delay_override > 0.0 else _current_spawn_delay


## Debug: the next wave started or planned is [param index] (0-based, clamped to the valid waves).
## A running wave is not touched; a stored plan is re-made.
func debug_jump_to_wave(index: int) -> void:
	var was_finished: bool = wave_index >= config.max_waves
	wave_index = clampi(index, 0, maxi(0, config.max_waves - 1))
	_replan_next()
	# After the last wave no plan or countdown exists: restart the flow from the new index.
	if was_finished and _spawning_count == 0:
		end_current_wave()


## Debug: spawns the plan of wave [param index] (0-based) as an extra, on top of the normal flow.
## Uses its own release queue: wave index, countdown, spawn delay and templates are untouched.
func debug_spawn_wave(index: int) -> void:
	if _spawners.is_empty():
		push_warning("WaveManager: no spawners; call setup() first.")
		return
	var clamped: int = clampi(index, 0, maxi(0, config.max_waves - 1))
	var open: Array[EnemySpawner] = _get_active_spawners_for(clamped)
	var plan: WavePlan = config.generate(clamped, WaveConfig.make_rng(_wave_seed, clamped), open.size(), [], budget_scale)
	var interval: float = _effective_spawn_delay() * open.size()
	for k: int in range(open.size()):
		var enemies: Array[PackedScene] = plan.spawners[k].enemies.duplicate()
		if enemies.is_empty():
			continue
		_debug_releases.append({
			"spawner": open[k],
			"enemies": enemies,
			"wait": _effective_spawn_delay() * (k + 1),
			"interval": interval,
		})


## Re-makes the stored plan (if any) for the current wave index and budget scale.
func _replan_next() -> void:
	if _next_plan == null:
		return
	_next_plan = _plan_next_wave()
	wave_planned.emit(_next_plan)


## Releases one enemy per debug queue whenever its wait ran out.
func _process_debug_releases(delta: float) -> void:
	for i: int in range(_debug_releases.size() - 1, -1, -1):
		var release: Dictionary = _debug_releases[i]
		var spawner: EnemySpawner = release["spawner"] as EnemySpawner
		var enemies: Array[PackedScene] = release["enemies"]
		if not is_instance_valid(spawner) or enemies.is_empty():
			_debug_releases.remove_at(i)
			continue
		release["wait"] = float(release["wait"]) - delta
		if float(release["wait"]) > 0.0:
			continue
		release["wait"] = float(release["interval"])
		spawner.spawn_extra(enemies.pop_front(), spawner.global_position)
		if enemies.is_empty():
			_debug_releases.remove_at(i)


## Generates the plan of the upcoming wave for its open spawners.
func _plan_next_wave() -> WavePlan:
	var active: Array[EnemySpawner] = _get_active_spawners()
	var last_templates: Array[WaveTemplate] = []
	for spawner: EnemySpawner in active:
		last_templates.append(_last_templates.get(spawner))
	return config.generate(wave_index, WaveConfig.make_rng(_wave_seed, wave_index), active.size(), last_templates, budget_scale)


func _get_active_spawners() -> Array[EnemySpawner]:
	return _get_active_spawners_for(wave_index)


## Spawners open at wave [param index]; all of them if none is.
func _get_active_spawners_for(index: int) -> Array[EnemySpawner]:
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
