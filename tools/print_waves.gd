extends Node
## Prints the generated waves of a seed (one line per wave plus one per spawner), then a digest.
## Run: godot --headless res://tools/print_waves.tscn -- --seed=N --waves=20 --spawners=3
## Approximation: N spawners are open from banner wave 3 (1 before); the game opens spawners by
## MapGenConfig.spawner_first_waves.
const OPEN_FROM_INDEX: int = 2

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
	var spawners: int = 1
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			wave_seed = arg.trim_prefix("--seed=").to_int()
		elif arg.begins_with("--waves="):
			waves = arg.trim_prefix("--waves=").to_int()
		elif arg.begins_with("--spawners="):
			spawners = maxi(1, arg.trim_prefix("--spawners=").to_int())

	var lines: Array[String] = []
	var total_coins: int = 0
	var last_templates: Array[WaveTemplate] = []
	for index: int in range(waves):
		var open_count: int = spawners if index >= OPEN_FROM_INDEX else 1
		var plan: WavePlan = config.generate(index, WaveConfig.make_rng(wave_seed, index), open_count, last_templates)

		var total_counts: Dictionary[String, int] = {}
		var wave_coins: int = 0
		var enemy_count: int = 0
		var spawner_lines: Array[String] = []
		for k: int in range(plan.spawners.size()):
			var sp: SpawnerPlan = plan.spawners[k]
			var counts: Dictionary[String, int] = {}
			for scene: PackedScene in sp.enemies:
				var type_name: String = scene.resource_path.get_file().get_basename()
				counts[type_name] = counts.get(type_name, 0) + 1
				total_counts[type_name] = total_counts.get(type_name, 0) + 1
				wave_coins += _coins_of(scene, 0)
			enemy_count += sp.enemies.size()
			spawner_lines.append("  spawner %d %s budget %.1f spent %d count %d | %s" % [
				k, sp.template.id if sp.template != null else &"?", sp.budget, sp.spent, sp.enemies.size(), _format_counts(counts)
			])
			# Slots beyond the open count of a later wave keep their entry; new slots start empty.
			if k < last_templates.size():
				last_templates[k] = sp.template
			else:
				last_templates.append(sp.template)
		total_coins += wave_coins

		var line: String = "wave %d budget %.1f spent %d count %d | %s | coins %d total %d" % [
			index + 1, plan.budget, plan.spent, enemy_count, _format_counts(total_counts), wave_coins, total_coins
		]
		lines.append(line)
		print(line)
		for spawner_line: String in spawner_lines:
			lines.append(spawner_line)
			print(spawner_line)

	print("digest %d" % hash("\n".join(lines)))
	get_tree().quit()


func _format_counts(counts: Dictionary[String, int]) -> String:
	var parts: Array[String] = []
	for type_name: String in counts:
		parts.append("%s:%d" % [type_name, counts[type_name]])
	return " ".join(parts)


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
