class_name EnemySpawner extends Node2D

signal spawning_complete
signal alive_count_changed(count: int)
## Emitted when an enemy died, with where, its coin drop and its effect colour.
signal enemy_died(death_position: Vector2, coins: int, color: Color)

## The spawner takes part from the wave with this index (0-based; the banner shows index + 1).
@export var first_wave: int = 0

var target_position: Vector2 = Vector2.ZERO

var _spawn_queue: Array[PackedScene] = []
var _spawn_queue_index: int = 0
var _spawn_delay: float = 0.0
var _is_active: bool = true
var _alive_count: int = 0
var _is_spawning: bool = false
## Death children counted as alive but still waiting for their deferred add_child.
var _pending_children: Array[Enemy] = []

## Death spawns deeper than this are refused (guards split loops).
const MAX_SPLIT_DEPTH: int = 3
## Smallest timer delay in seconds (Timer errors on wait_time <= 0).
const MIN_DELAY: float = 0.01
## Alpha of the flag while the spawner is not open yet.
const INACTIVE_ALPHA: float = 0.35

@onready var spawn_timer: Timer = %SpawnTimer
@onready var _sprite: Sprite2D = %Sprite2D


func _ready() -> void:
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)


## Starts spawning [param spawn_list]: the first enemy after [param first_delay] seconds,
## then one every [param spawn_delay] seconds. Pacing is owned by [WaveManager].
## Replaces any queue still running.
func start_spawning(spawn_list: Array[PackedScene], spawn_delay: float, first_delay: float) -> void:
	_spawn_queue.assign(spawn_list)
	_spawn_queue_index = 0
	_spawn_delay = maxf(MIN_DELAY, spawn_delay)
	_is_spawning = true
	# Timer.start(time) overwrites wait_time, so the follow-up delay is set per tick.
	spawn_timer.start(maxf(MIN_DELAY, first_delay))


## Whether a queue is still being spawned.
func is_spawning() -> bool:
	return _is_spawning


## Number of enemies of this spawner that are alive (including pending death children).
func get_alive_count() -> int:
	return _alive_count


## Whether the spawner is open for the current wave (visual state set by [method set_active]).
func is_active() -> bool:
	return _is_active


## Visual only: draws the flag faded while the spawner is not open yet.
func set_active(active: bool) -> void:
	_is_active = active
	_sprite.modulate.a = 1.0 if active else INACTIVE_ALPHA


## Spawns the next enemy in the queue, or finishes spawning when the queue is empty.
func spawn_next() -> void:
	if _spawn_queue_index >= _spawn_queue.size():
		spawn_timer.stop()
		_is_spawning = false
		spawning_complete.emit()
		return

	var index: int = _spawn_queue_index
	_spawn_queue_index += 1

	_create_enemy(_spawn_queue[index], global_position, false)


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


func _on_spawn_timer_timeout() -> void:
	spawn_next()
	if _is_spawning:
		spawn_timer.start(_spawn_delay)
