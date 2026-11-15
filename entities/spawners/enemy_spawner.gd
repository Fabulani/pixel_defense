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
		# Next time, spawn faster. For fun.
		speedup_spawning()
		return

	var index: int = _spawn_queue_index
	_spawn_queue_index += 1

	var enemy: Enemy = _spawn_queue[index].instantiate() as Enemy
	if enemy == null:
		push_error("EnemySpawner: scene at index %d does not instantiate Enemy." % index)
		return

	enemy.set_target_position(target_position)
	enemy.died.connect(_on_enemy_died)
	enemy.tree_exiting.connect(_on_enemy_tree_exiting)
	add_child(enemy)
	_alive_count += 1
	alive_count_changed.emit(_alive_count)


## Shortens the delay between spawns for the next wave.
func speedup_spawning() -> void:
	_spawn_delay = maxf(0.01, _spawn_delay - 0.1)
	spawn_timer.wait_time = _spawn_delay


func _on_enemy_died(enemy: Enemy) -> void:
	CurrencyManager.earn(enemy.drops.coins)
	enemy_died.emit(enemy.global_position, enemy.drops.coins, enemy.stats.vfx_color)


func _on_enemy_tree_exiting() -> void:
	_alive_count = maxi(0, _alive_count - 1)
	alive_count_changed.emit(_alive_count)
	if _alive_count == 0 and not _is_spawning:
		wave_cleared.emit()


func _on_spawn_timer_timeout() -> void:
	spawn_next()
