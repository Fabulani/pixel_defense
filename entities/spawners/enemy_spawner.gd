class_name EnemySpawner extends Node2D

signal spawning_complete
signal wave_cleared
signal alive_count_changed(count: int)
## Emitted when an enemy died, with where, its coin drop and its effect colour.
signal enemy_died(death_position: Vector2, coins: int, color: Color)

@export var default_spawn_delay: float = 1.0

var target_position: Vector2 = Vector2.ZERO

var _spawn_queue: Array[PackedScene] = []
var _spawn_queue_index: int = 0
var _spawn_delay: float = 0.0
var _alive_count: int = 0
var _is_spawning: bool = false
## Death children counted as alive but still waiting for their deferred add_child.
var _pending_children: Array[Enemy] = []

## Death spawns deeper than this are refused (guards split loops).
const MAX_SPLIT_DEPTH: int = 3

@onready var spawn_timer: Timer = %SpawnTimer


func _ready() -> void:
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	_spawn_delay = default_spawn_delay
	spawn_timer.wait_time = _spawn_delay


## Starts spawning [param spawn_list] one enemy per timer tick.
## Note: this works for a single wave, but can't spawn
## multiple waves concurrently (a la Dungeon Warfare style).
func start_spawning(spawn_list: Array[PackedScene]) -> void:
	_spawn_queue.assign(spawn_list)
	_spawn_queue_index = 0
	_is_spawning = true
	spawn_timer.start()


## Spawns the next enemy in the queue, or finishes spawning when the queue is empty.
func spawn_next() -> void:
	if _spawn_queue_index >= _spawn_queue.size():
		spawn_timer.stop()
		_is_spawning = false
		spawning_complete.emit()
		if _alive_count == 0:
			wave_cleared.emit()
		# Next time, spawn faster. For fun.
		speedup_spawning()
		return

	var index: int = _spawn_queue_index
	_spawn_queue_index += 1

	_create_enemy(_spawn_queue[index], global_position, false)


## Shortens the delay between spawns for the next wave.
func speedup_spawning() -> void:
	_spawn_delay = maxf(0.01, _spawn_delay - 0.1)
	spawn_timer.wait_time = _spawn_delay


## Instantiates [param scene] at [param world_position] and counts it as alive.
## The position is set before add_child so the enemy paths from where it appears.
## With [param deferred] the child is added at the end of the frame; use it when called from a
## physics callback (a bullet hit), where adding a physics body is an error. It is counted at once.
func _create_enemy(scene: PackedScene, world_position: Vector2, deferred: bool, generation: int = 0) -> Enemy:
	var enemy: Enemy = scene.instantiate() as Enemy
	if enemy == null:
		push_error("EnemySpawner: scene %s does not instantiate Enemy." % scene.resource_path)
		return null
	enemy.position = to_local(world_position)
	enemy.split_generation = generation
	enemy.set_target_position(target_position)
	enemy.died.connect(_on_enemy_died)
	enemy.tree_exiting.connect(_on_enemy_tree_exiting)
	_alive_count += 1
	if deferred:
		_pending_children.append(enemy)
		enemy.tree_entered.connect(_pending_children.erase.bind(enemy), CONNECT_ONE_SHOT)
		add_child.call_deferred(enemy)
	else:
		add_child(enemy)
	alive_count_changed.emit(_alive_count)
	return enemy


## Spawns the death children of [param enemy] around its position, if its stats ask for it.
## The children are counted immediately and added deferred (death happens inside bullet physics
## callbacks), still before the dying parent is freed, so the alive count never reaches zero.
func _spawn_death_children(enemy: Enemy) -> void:
	var scene: PackedScene = enemy.stats.death_spawn_scene
	if scene == null or enemy.stats.death_spawn_count <= 0:
		return
	if enemy.split_generation >= MAX_SPLIT_DEPTH:
		push_warning("EnemySpawner: split depth limit (%d) reached at %s; not spawning." % [MAX_SPLIT_DEPTH, enemy.scene_file_path])
		return
	if scene.resource_path == enemy.scene_file_path:
		push_error("EnemySpawner: %s would spawn itself on death; ignored." % enemy.scene_file_path)
		return
	for i: int in range(enemy.stats.death_spawn_count):
		var offset: Vector2 = Vector2.from_angle(randf() * TAU) * randf_range(2.0, 6.0)
		_create_enemy(scene, enemy.global_position + offset, true, enemy.split_generation + 1)


func _exit_tree() -> void:
	# Children whose deferred add never ran would leak; they are not in the tree, so free them.
	for pending: Enemy in _pending_children:
		if is_instance_valid(pending) and not pending.is_inside_tree():
			pending.free()
			_alive_count = maxi(0, _alive_count - 1)
	_pending_children.clear()


func _on_enemy_died(enemy: Enemy) -> void:
	CurrencyManager.earn(enemy.drops.coins)
	enemy_died.emit(enemy.global_position, enemy.drops.coins, enemy.stats.vfx_color)
	_spawn_death_children(enemy)


func _on_enemy_tree_exiting() -> void:
	_alive_count = maxi(0, _alive_count - 1)
	alive_count_changed.emit(_alive_count)
	if _alive_count == 0 and not _is_spawning:
		wave_cleared.emit()


func _on_spawn_timer_timeout() -> void:
	spawn_next()
