extends "res://debug/sections/debug_section.gd"
## Enemies: spawn, freeze, invulnerable, HP, hit, kill, attach effect components.

const ENEMY_DIR: String = "res://entities/enemies/"
const HP_RATIOS: Array[float] = [1.0, 0.75, 0.5, 0.25, 0.1]
## Ring search radius (cells) for a walkable cell around the view centre.
const SEARCH_RADIUS: int = 8
## Largest random offset (px) of the 2nd and later enemies of one spawn.
const SPAWN_JITTER: float = 4.0

var _ctx: Context
var _enemy_scenes: Array[PackedScene] = []
var _enemy_option: OptionButton
var _location_option: OptionButton
var _count_spin: SpinBox


func build(ctx: Context) -> void:
	_ctx = ctx
	_enemy_option = Ui.add_option(content)
	var names: Array[String] = []
	_scan_enemy_scenes(names)
	for i: int in _enemy_scenes.size():
		_enemy_option.add_item(names[i])
	var selected: int = maxi(names.find(State.enemy_name), 0)
	if not names.is_empty():
		_enemy_option.select(selected)
	_enemy_option.item_selected.connect(_on_enemy_option_item_selected)

	_count_spin = Ui.add_spin(content, 1, 50, State.enemy_count)
	_count_spin.value_changed.connect(_on_count_spin_value_changed)

	_location_option = Ui.add_option(content)
	for i: int in ctx.level.get_spawners().size():
		_location_option.add_item("Spawner %d" % (i + 1))
	_location_option.add_item("View centre")
	_location_option.select(clampi(State.spawn_location, 0, _location_option.item_count - 1))
	_location_option.item_selected.connect(_on_location_option_item_selected)

	Ui.add_button(content, "Spawn", _on_spawn_pressed)
	Ui.add_toggle(content, "Freeze", State.freeze_enemies, _on_freeze_toggled)
	Ui.add_toggle(content, "Invulnerable", State.invulnerable_enemies, _on_invulnerable_toggled)
	var hp_flow: HFlowContainer = Ui.add_flow(content)
	for ratio: float in HP_RATIOS:
		Ui.add_button(hp_flow, "HP %d%%" % roundi(ratio * 100.0), _on_hp_pressed.bind(ratio))
	var action_flow: HFlowContainer = Ui.add_flow(content)
	Ui.add_button(action_flow, "Hit 1", _on_hit_pressed)
	Ui.add_button(action_flow, "Kill all", _on_kill_all_pressed)
	var attach_flow: HFlowContainer = Ui.add_flow(content)
	Ui.add_button(attach_flow, "Smoke", _on_attach_pressed.bind(DamageSmoke))
	Ui.add_button(attach_flow, "Regen", _on_attach_pressed.bind(Regeneration))
	Ui.add_button(attach_flow, "Dash", _on_attach_pressed.bind(Dash))


## Fill [member _enemy_scenes] and [param names] (parallel, sorted by name) from the enemy folders.
func _scan_enemy_scenes(names: Array[String]) -> void:
	var found: Dictionary[String, PackedScene] = {}
	for entry: String in ResourceLoader.list_directory(ENEMY_DIR):
		if not entry.ends_with("/") or entry == "components/":
			continue
		var folder: String = ENEMY_DIR + entry
		for file: String in ResourceLoader.list_directory(folder):
			if file.ends_with("/"):
				continue
			var file_name: String = file.trim_suffix(".remap")
			if not file_name.ends_with(".tscn"):
				continue
			var scene: PackedScene = load(folder + file_name) as PackedScene
			if scene == null:
				continue
			var probe: Node = scene.instantiate()
			var is_enemy: bool = probe is Enemy
			probe.free()
			if is_enemy:
				found[entry.trim_suffix("/")] = scene
	var keys: Array[String] = found.keys()
	keys.sort()
	for key: String in keys:
		names.append(key)
		_enemy_scenes.append(found[key])


## Spawns [param count] enemies through [param spawner], each jittered a few px around [param world_position].
func _spawn_at(spawner: EnemySpawner, scene: PackedScene, count: int, world_position: Vector2) -> Array[Enemy]:
	var result: Array[Enemy] = []
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	for i: int in range(maxi(0, count)):
		var offset: Vector2 = Vector2.ZERO
		if i > 0:
			offset = Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.0, SPAWN_JITTER)
		var enemy: Enemy = spawner.spawn(scene, world_position + offset)
		if enemy != null:
			result.append(enemy)
	return result


## Spawns at the walkable cell nearest to [param world_position], owned by the nearest spawner.
func _spawn_near(scene: PackedScene, count: int, world_position: Vector2) -> Array[Enemy]:
	var level: Level = _ctx.level
	var center: Vector2i = PathfindingManager.world_to_cell(world_position)
	var cell_size: Vector2 = Vector2(GameData.grid_cell_size)
	var found: bool = false
	var best_cell: Vector2i = center
	if level.is_cell_walkable(center):
		found = true
	else:
		for radius: int in range(1, SEARCH_RADIUS + 1):
			var best_distance: float = INF
			for x: int in range(center.x - radius, center.x + radius + 1):
				for y: int in range(center.y - radius, center.y + radius + 1):
					if maxi(absi(x - center.x), absi(y - center.y)) != radius:
						continue
					var cell: Vector2i = Vector2i(x, y)
					var distance: float = (Vector2(cell) * cell_size + cell_size / 2.0).distance_squared_to(world_position)
					if distance < best_distance and level.is_cell_walkable(cell):
						best_distance = distance
						best_cell = cell
						found = true
			if found:
				break
	if not found:
		push_warning("Debug: no walkable cell near %s." % world_position)
		return []
	var spawn_position: Vector2 = Vector2(best_cell) * cell_size + cell_size / 2.0
	var owner_spawner: EnemySpawner = null
	var best: float = INF
	for spawner: EnemySpawner in level.get_spawners():
		var distance: float = spawner.global_position.distance_squared_to(spawn_position)
		if distance < best:
			best = distance
			owner_spawner = spawner
	if owner_spawner == null:
		push_warning("Debug: no spawner to own the enemies.")
		return []
	return _spawn_at(owner_spawner, scene, count, spawn_position)


func _apply_flags(enemy: Enemy) -> void:
	_set_invulnerable(enemy, State.invulnerable_enemies)
	if State.freeze_enemies:
		enemy.set_speed_factor(&"debug", 0.0)


func _set_invulnerable(enemy: Enemy, on: bool) -> void:
	if on:
		enemy.set_damage_factor(&"debug", 0.0)
	else:
		enemy.clear_damage_factor(&"debug")


func _on_enemy_option_item_selected(index: int) -> void:
	State.enemy_name = _enemy_option.get_item_text(index)


func _on_count_spin_value_changed(value: float) -> void:
	State.enemy_count = int(value)


func _on_location_option_item_selected(index: int) -> void:
	State.spawn_location = index


func _on_spawn_pressed() -> void:
	var index: int = _enemy_option.selected
	if index < 0 or index >= _enemy_scenes.size():
		return
	var spawners: Array[EnemySpawner] = _ctx.level.get_spawners()
	var spawned: Array[Enemy]
	if State.spawn_location >= spawners.size():
		spawned = _spawn_near(_enemy_scenes[index], State.enemy_count, _ctx.camera.get_screen_center_position())
	else:
		var spawner: EnemySpawner = spawners[State.spawn_location]
		spawned = _spawn_at(spawner, _enemy_scenes[index], State.enemy_count, spawner.global_position)
	for enemy: Enemy in spawned:
		_apply_flags(enemy)


func _on_freeze_toggled(on: bool) -> void:
	State.freeze_enemies = on
	for enemy: Enemy in _ctx.level.get_enemies():
		if on:
			enemy.set_speed_factor(&"debug", 0.0)
		else:
			enemy.clear_speed_factor(&"debug")


func _on_invulnerable_toggled(on: bool) -> void:
	State.invulnerable_enemies = on
	for enemy: Enemy in _ctx.level.get_enemies():
		_set_invulnerable(enemy, on)


func _on_hp_pressed(ratio: float) -> void:
	for enemy: Enemy in _ctx.level.get_enemies():
		enemy.set_health_ratio(ratio)


func _on_hit_pressed() -> void:
	for enemy: Enemy in _ctx.level.get_enemies():
		enemy.take_damage(1.0)


func _on_kill_all_pressed() -> void:
	for enemy: Enemy in _ctx.level.get_enemies():
		enemy.die()


func _on_attach_pressed(component: GDScript) -> void:
	for enemy: Enemy in _ctx.level.get_enemies():
		var present: bool = false
		for child: Node in enemy.get_children():
			if is_instance_of(child, component):
				present = true
				break
		if not present:
			enemy.add_child(component.new() as Node)
