extends Node
## Prints the generated waves of a seed, one line per wave, then a digest.
## Run: godot --headless res://tools/print_waves.tscn -- --seed=N --waves=20

const CONFIG_PATH: String = "res://core/managers/wave/default_waves.tres"

var _coin_cache: Dictionary[PackedScene, int] = {}


func _ready() -> void:
	var config: WaveConfig = load(CONFIG_PATH) as WaveConfig
	if config == null:
		push_error("print_waves: cannot load %s" % CONFIG_PATH)
		get_tree().quit(1)
		return
	var wave_seed: int = 1
	var waves: int = config.max_waves
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			wave_seed = arg.trim_prefix("--seed=").to_int()
		elif arg.begins_with("--waves="):
			waves = arg.trim_prefix("--waves=").to_int()

	var lines: Array[String] = []
	var total_coins: int = 0
	for index: int in range(waves):
		var plan: WavePlan = config.generate(index, WaveConfig.make_rng(wave_seed, index))

		var counts: Dictionary[String, int] = {}
		var wave_coins: int = 0
		for scene: PackedScene in plan.enemies:
			var type_name: String = scene.resource_path.get_file().get_basename()
			counts[type_name] = counts.get(type_name, 0) + 1
			wave_coins += _coins_of(scene, 0)
		total_coins += wave_coins

		var parts: Array[String] = []
		for type_name: String in counts:
			parts.append("%s:%d" % [type_name, counts[type_name]])
		var line: String = "wave %d budget %.1f spent %d count %d | %s | coins %d total %d" % [
			index + 1, plan.budget, plan.spent, plan.enemies.size(), " ".join(parts), wave_coins, total_coins
		]
		lines.append(line)
		print(line)

	print("digest %d" % hash("\n".join(lines)))
	get_tree().quit()


## Coins paid for one [param scene], including the enemies it spawns on death.
func _coins_of(scene: PackedScene, depth: int) -> int:
	if depth == 0 and _coin_cache.has(scene):
		return _coin_cache[scene]
	var node: Node = scene.instantiate()
	var enemy: Enemy = node as Enemy
	var coins: int = 0
	if enemy != null:
		if enemy.drops != null:
			coins += enemy.drops.coins
		var child: PackedScene = enemy.stats.death_spawn_scene if enemy.stats != null else null
		# Mirror the game: no self-spawning scene, depth limited.
		if child != null and child.resource_path != scene.resource_path and depth < EnemySpawner.MAX_SPLIT_DEPTH:
			coins += enemy.stats.death_spawn_count * _coins_of(child, depth + 1)
	node.free()
	if depth == 0:
		_coin_cache[scene] = coins
	return coins
