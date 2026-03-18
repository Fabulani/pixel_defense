class_name EnemySpawner extends Node2D

signal spawning_complete
signal wave_cleared
signal alive_count_changed(count: int)

@export var default_spawn_delay : float = 1.0

var _spawn_queue: Array[PackedScene] = []
var _spawn_queue_index : int = 0
var _spawn_delay : float = 0.0
var _alive_count : int = 0
var _is_spawning : bool = false

var target_position : Vector2 = Vector2.ZERO

@onready var spawn_timer: Timer = %SpawnTimer

func _ready() -> void:
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	_spawn_delay = default_spawn_delay
	spawn_timer.wait_time = _spawn_delay
	
func start_spawning(spawn_list: Array[PackedScene]) -> void:
	# Note: this works for a single wave, but can't spawn
	# multiples waves concurrently (a la Dungeon Warfare style)
	_spawn_queue.assign(spawn_list)
	_spawn_queue_index = 0
	_is_spawning = true
	spawn_timer.start()

func spawn_next() -> void:
	if _spawn_queue_index >= _spawn_queue.size():
		spawn_timer.stop()
		_is_spawning = false
		spawning_complete.emit()
		# Next time, spawn faster. For fun.
		speedup_spawning()
		return

	var enemy: Enemy = _spawn_queue[_spawn_queue_index].instantiate() as Enemy
	if enemy == null:
		push_error("EnemySpawner: scene at index %d does not instantiate Enemy." % _spawn_queue_index)
		return

	enemy.set_target_position(target_position)
	enemy.died.connect(_on_enemy_died)
	enemy.tree_exiting.connect(_on_enemy_removed)
	add_child(enemy)
	_alive_count += 1
	alive_count_changed.emit(_alive_count)

func speedup_spawning() -> void:
	_spawn_delay = max(0.01, _spawn_delay - 0.1)
	spawn_timer.wait_time = _spawn_delay

func _on_enemy_died(enemy: Enemy) -> void:
	CurrencyManager.earn(enemy.drops.coins)

func _on_enemy_removed() -> void:
	_alive_count = maxi(0, _alive_count - 1)
	alive_count_changed.emit(_alive_count)
	if _alive_count == 0 and not _is_spawning:
		wave_cleared.emit()

func _on_spawn_timer_timeout() -> void:
	spawn_next()
	_spawn_queue_index += 1
