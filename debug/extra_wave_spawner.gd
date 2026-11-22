extends Node
## Spawns the plan of a wave as an extra on top of the running flow, with its own release queue.
## Wave index, countdown and the manager's spawn state are untouched.

const Context = preload("res://debug/debug_context.gd")

var _ctx: Context
## Queues: {spawner, enemies, wait, spawners}; the interval is recomputed per release from the current spawn delay.
var _releases: Array[Dictionary] = []


func setup(ctx: Context) -> void:
	_ctx = ctx


## Queues the plan of wave [param index] (0-based, clamped) for its open spawners.
func spawn_wave(index: int) -> void:
	var wm: WaveManager = _ctx.level.get_wave_manager()
	var clamped: int = clampi(index, 0, maxi(0, wm.config.max_waves - 1))
	var open: Array[EnemySpawner] = wm.get_spawners_open_at(clamped)
	if open.is_empty():
		push_warning("Debug: no open spawners for wave %d." % (clamped + 1))
		return
	var plan: WavePlan = wm.config.generate(clamped, WaveConfig.make_rng(wm.get_wave_seed(), clamped), open.size(), [], wm.difficulty)
	for k: int in range(open.size()):
		var enemies: Array[PackedScene] = plan.spawners[k].enemies.duplicate()
		if enemies.is_empty():
			continue
		_releases.append({
			"spawner": open[k],
			"enemies": enemies,
			"wait": wm.get_spawn_delay() * (k + 1),
			"spawners": open.size(),
		})


## Releases one enemy per queue whenever its wait ran out.
func _process(delta: float) -> void:
	for i: int in range(_releases.size() - 1, -1, -1):
		var release: Dictionary = _releases[i]
		var spawner: EnemySpawner = release["spawner"] as EnemySpawner
		var enemies: Array[PackedScene] = release["enemies"]
		if not is_instance_valid(spawner) or enemies.is_empty():
			_releases.remove_at(i)
			continue
		release["wait"] = float(release["wait"]) - delta
		if float(release["wait"]) > 0.0:
			continue
		release["wait"] = _ctx.level.get_wave_manager().get_spawn_delay() * int(release["spawners"])
		spawner.spawn(enemies.pop_front(), spawner.global_position)
		if enemies.is_empty():
			_releases.remove_at(i)
